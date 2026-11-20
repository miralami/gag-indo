--!strict
-- LookDevModelsPropsR7: SERVER-ONLY applier for the OFF-BY-DEFAULT "props_r7" candidate
-- (WORK_QUEUE item 57). Main.session wires the candidate in Shared.LookDev; this file only
-- registers it. InsertService is never called here: every asset comes through
-- LookDevAssetLoader.get(id, "props_r7") (baked clone first, LoadAsset only as its fallback).
--
-- apply() scans workspace for tree/pine models, picks the 40x40 open yard nearest spawn, stages
-- the six props in one row 6 studs apart at their real R6 sizes, and paints a Ground voxel pad
-- under each footprint. Every staged model carries LookDevR7="props_r7" and a PropSlot; the folder
-- LookDevModelsPropsR7_props_r7 carries ReviewCameraPos/ReviewLookAt. Every failure is counted and warned, then published to
-- Shared.LookDevFailures.set("props_r7", failures) at the END of apply().
-- restore() detaches the exact previous folder and puts it back. Terrain pads are LookDev-only
-- voxels and are deliberately left in place: restoring per-cell material would need a snapshot
-- and could clobber the independent item-55 bed paint.

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevModelsPropsR7] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Workspace = service("Workspace")

local Shared: any? = nil
if ReplicatedStorage then
	local ok, folder = pcall(function()
		return (ReplicatedStorage :: any):WaitForChild("Shared")
	end)
	if ok and folder then
		Shared = folder
	else
		warn("[LookDevModelsPropsR7] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, ModelMapPropsR7, LookDevAssetLoader, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev), require((Shared :: any).ModelMapPropsR7), require(script.Parent.LookDevAssetLoader), require(
		(Shared :: any).LookDevFailures
	)
end)
if not okModules or not LookDev or not ModelMapPropsR7 or not LookDevAssetLoader or not LookDevFailures then
	warn("[LookDevModelsPropsR7] could not require LookDev / ModelMapPropsR7 / LookDevAssetLoader / LookDevFailures")
	return {}
end

local okSpec, loadedSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if not okSpec or not loadedSpec then
	warn("[LookDevModelsPropsR7] could not require MapSpec; voxel pads will be skipped")
end
local MapSpec: any? = if okSpec then loadedSpec else nil

local LookDevModelsPropsR7 = {}

local FAMILY_ID: string = ModelMapPropsR7.familyId
local failures = 0
local activeFolder: any? = nil
local savedFolder: any? = nil
local cameraPos: Vector3? = nil
local cameraLook: Vector3? = nil
local lastCentre: { x: number, z: number }? = nil

local function fail(message: string)
	failures += 1
	warn("[LookDevModelsPropsR7] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set("props_r7", failures)
	end)
end

local function clearActive()
	local folder = activeFolder
	if folder then
		pcall(function()
			folder:Destroy()
		end)
	end
	activeFolder = nil
end

local function findPrevious(): any?
	if not Workspace then
		return nil
	end
	local ok, previous = pcall(function()
		return (Workspace :: any):FindFirstChild(ModelMapPropsR7.folderName)
	end)
	return if ok then previous else nil
end

local function newFolder(): any?
	if not Workspace then
		return nil
	end
	local ok, folder = pcall(function()
		return Instance.new("Folder")
	end)
	if not ok or not folder then
		fail("could not create staging folder")
		return nil
	end
	pcall(function()
		folder.Name = ModelMapPropsR7.folderName
		folder.Parent = Workspace
	end)
	return folder
end

-- Name match first (Tree_N, Pine_<angle>_<layer>, pohon/cemara imports); otherwise any Model with
-- four or more Part descendants is treated as a tree so a renamed trunk still blocks the yard.
local function looksLikeTree(model: any): boolean
	local okName, name = pcall(function()
		return string.lower(model.Name)
	end)
	if okName and type(name) == "string" then
		for _, keyword in ipairs({ "pine", "tree", "pohon", "cemara" }) do
			if string.find(name, keyword, 1, true) then
				return true
			end
		end
	end
	local okParts, parts = pcall(function()
		return model:GetDescendants()
	end)
	if not okParts or not parts then
		return false
	end
	local count = 0
	for _, descendant in ipairs(parts) do
		if descendant:IsA("BasePart") then
			count += 1
			if count >= 4 then
				return true
			end
		end
	end
	return false
end

-- Prefer an explicit trunk/batang part; fall back to the model bounding-box centre. Only X/Z
-- matter: the clearance rule is a horizontal distance.
local function trunkXZ(model: any): (number?, number?)
	local okParts, parts = pcall(function()
		return model:GetDescendants()
	end)
	if okParts and parts then
		for _, part in ipairs(parts) do
			if part:IsA("BasePart") then
				local okName, name = pcall(function()
					return string.lower(part.Name)
				end)
				if okName and type(name) == "string" and (string.find(name, "trunk", 1, true) or string.find(name, "batang", 1, true)) then
					local okPos, position = pcall(function()
						return part.Position
					end)
					if okPos and position then
						return position.X, position.Z
					end
				end
			end
		end
	end
	local okBox, boxCFrame = pcall(function()
		return (model:GetBoundingBox())
	end)
	if okBox and boxCFrame then
		return boxCFrame.Position.X, boxCFrame.Position.Z
	end
	return nil, nil
end

local function treeTrunks(): { { number } }
	local trunks = {}
	if not Workspace then
		return trunks
	end
	local okAll, all = pcall(function()
		return (Workspace :: any):GetDescendants()
	end)
	if not okAll or not all then
		fail("workspace descendant scan failed")
		return trunks
	end
	for _, instance in ipairs(all) do
		local okModel = pcall(function()
			return instance:IsA("Model")
		end)
		if okModel and instance:IsA("Model") and looksLikeTree(instance) then
			local x, z = trunkXZ(instance)
			if type(x) == "number" and type(z) == "number" then
				trunks[#trunks + 1] = { x, z }
			end
		end
	end
	return trunks
end

-- A 40x40 yard is clear when no trunk is within 15 studs of ANY edge, and the footprint misses
-- every MapSpec keep-out rect (plaza, lapangan, hubs, future slots). Candidates are walked outward
-- from spawn on a 10-stud grid, so the first clear one is the nearest open yard.
local function yardClear(x: number, z: number, trunks: { { number } }, keepOut: { { number } }): boolean
	local half = ModelMapPropsR7.yardSize / 2
	local margin = half + ModelMapPropsR7.trunkClearance
	for _, trunk in ipairs(trunks) do
		if math.abs(trunk[1] - x) < margin and math.abs(trunk[2] - z) < margin then
			return false
		end
	end
	for _, rect in ipairs(keepOut) do
		if math.abs(x - rect[1]) < half + rect[3] and math.abs(z - rect[2]) < half + rect[4] then
			return false
		end
	end
	return true
end

local function pickYard(trunks: { { number } }): (number, number)
	local spawnX, spawnZ = 0, 28
	local limit = 400
	local keepOut = {} :: { { number } }
	if MapSpec then
		if MapSpec.SPAWN then
			spawnX, spawnZ = MapSpec.SPAWN.x, MapSpec.SPAWN.z
		end
		if type(MapSpec.TERRAIN_HALF) == "number" then
			limit = MapSpec.TERRAIN_HALF
		end
		local okRects, rects = pcall(function()
			return MapSpec.keepOutRects()
		end)
		if okRects and type(rects) == "table" then
			keepOut = rects
		end
	end
	local half = ModelMapPropsR7.yardSize / 2
	local candidates = {}
	for dx = -240, 240, 10 do
		for dz = -240, 240, 10 do
			local x, z = spawnX + dx, spawnZ + dz
			if math.abs(x) <= limit - half and math.abs(z) <= limit - half then
				candidates[#candidates + 1] = { x = x, z = z, d = dx * dx + dz * dz }
			end
		end
	end
	table.sort(candidates, function(a, b)
		return a.d < b.d
	end)
	for _, candidate in ipairs(candidates) do
		if yardClear(candidate.x, candidate.z, trunks, keepOut) then
			return candidate.x, candidate.z
		end
	end
	fail("no clear 40x40 yard found; falling back to spawn")
	return spawnX, spawnZ
end

local function paintGroundPad(boxCFrame: any, boxSize: any)
	if not MapSpec or not Workspace then
		fail("missing MapSpec/Workspace; Ground pad skipped")
		return
	end
	local terrain = (Workspace :: any).Terrain
	if not terrain then
		fail("missing Terrain; Ground pad skipped")
		return
	end
	local bottom = MapSpec.GROUND_Y - MapSpec.TERRAIN_VOXEL
	local cy, sy = MapSpec.volumeForTop(bottom, MapSpec.GROUND_Y)
	local margin = ModelMapPropsR7.padMargin
	local cap = MapSpec.MAX_FILL_SPAN or 40
	local sx = math.min(boxSize.X + margin, cap)
	local sz = math.min(boxSize.Z + margin, cap)
	local ok = pcall(function()
		terrain:FillBlock(CFrame.new(boxCFrame.Position.X, cy, boxCFrame.Position.Z), Vector3.new(sx, sy, sz), Enum.Material.Ground)
	end)
	if not ok then
		fail("Ground pad FillBlock failed")
	end
end

local function stage(model: any, entry: any, x: number, z: number): boolean
	local pivotOk, pivot = pcall(function()
		return model:GetPivot()
	end)
	if not pivotOk or not pivot then
		fail("could not read pivot for " .. tostring(entry.slot))
		return false
	end
	if not pcall(function()
		model:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(entry.rotX or 0, entry.ry, 0))
	end) then
		fail("could not orient " .. tostring(entry.slot))
	end
	local okBox, boxCFrame, size = pcall(function()
		return model:GetBoundingBox()
	end)
	if not okBox or not boxCFrame or not size or size.Y <= 0.01 or size.Y ~= size.Y then
		fail("invalid bounding box for " .. tostring(entry.slot))
		return false
	end
	local target = entry.height
	if type(target) ~= "number" or target <= 0.01 or target ~= target then
		fail("invalid target height for " .. tostring(entry.slot))
		return false
	end
	if not pcall(function()
		model:ScaleTo(target / size.Y)
	end) then
		fail("ScaleTo failed for " .. tostring(entry.slot))
		return false
	end
	local okScaled, scaledBox, scaledSize = pcall(function()
		return model:GetBoundingBox()
	end)
	if not okScaled or not scaledBox or not scaledSize then
		fail("post-scale bounding box failed for " .. tostring(entry.slot))
		return false
	end
	local okParts, parts = pcall(function()
		return model:GetDescendants()
	end)
	if okParts and parts then
		for _, part in ipairs(parts) do
			pcall(function()
				if part:IsA("BasePart") then
					part.Anchored = true
					part.CanCollide = false
				end
			end)
		end
	end
	local y = 0
	if pivotOk and pivot then
		y = pivot.Y - scaledBox.Y + scaledSize.Y * 0.5
	end
	if not pcall(function()
		model:PivotTo(CFrame.new(x, y, z) * CFrame.Angles(entry.rotX or 0, entry.ry, 0))
	end) then
		fail("could not place " .. tostring(entry.slot))
		return false
	end
	if not pcall(function()
		model:SetAttribute(ModelMapPropsR7.tagAttribute, FAMILY_ID)
		model:SetAttribute(ModelMapPropsR7.slotAttribute, entry.slot)
	end) then
		fail("could not tag " .. tostring(entry.slot))
	end
	local okPadBox, padBox, padSize = pcall(function()
		return model:GetBoundingBox()
	end)
	if okPadBox and padBox and padSize then
		paintGroundPad(padBox, padSize)
	else
		fail("could not measure pad footprint for " .. tostring(entry.slot))
	end
	return true
end

local function setCameraAttributes(folder: any, centreX: number, centreZ: number)
	local rule = ModelMapPropsR7.cameraFor(centreX, centreZ)
	local ok, position, target = pcall(function()
		return Vector3.new(rule.position.x, rule.position.y, rule.position.z),
			Vector3.new(rule.target.x, rule.target.y, rule.target.z)
	end)
	if not ok or not position or not target then
		fail("could not build ReviewCamera vectors")
		return
	end
	cameraPos, cameraLook = position, target
	if not pcall(function()
		folder:SetAttribute(ModelMapPropsR7.cameraPosAttribute, position)
		folder:SetAttribute(ModelMapPropsR7.cameraLookAttribute, target)
	end) then
		fail("could not set camera attributes on staging folder")
	end
end

local applier = {
	apply = function()
		failures = 0
		clearActive()
		local family = ModelMapPropsR7.families[FAMILY_ID]
		if type(family) ~= "table" or type(family.slots) ~= "table" or type(family.ids) ~= "table" then
			fail("missing family map for " .. FAMILY_ID)
			publishFailures()
			return
		end
		local previous = findPrevious()
		if previous then
			pcall(function()
				previous.Parent = nil
			end)
			savedFolder = previous
		end
		local folder = newFolder()
		if not folder then
			publishFailures()
			return
		end
		activeFolder = folder

		local centreX, centreZ = pickYard(treeTrunks())
		lastCentre = { x = centreX, z = centreZ }
		setCameraAttributes(folder, centreX, centreZ)

		for index, entry in ipairs(family.slots) do
			local id = family.ids[entry.slot]
			if type(id) ~= "number" or id <= 0 or id % 1 ~= 0 then
				fail("missing or invalid asset ID for " .. FAMILY_ID .. "/" .. tostring(entry.slot))
				continue
			end
			local model = LookDevAssetLoader.get(id, "props_r7")
			if not model then
				fail("asset load failed for " .. FAMILY_ID .. "/" .. tostring(entry.slot))
				continue
			end
			stage(model, entry, centreX + ModelMapPropsR7.rowOffset(index), centreZ)
			if not pcall(function()
				model.Name = "R7_" .. entry.slot .. "_" .. index
				model.Parent = folder
			end) then
				fail("could not parent " .. tostring(entry.slot))
			end
		end
		publishFailures()
	end,

	restore = function()
		clearActive()
		local previous = savedFolder
		if previous then
			pcall(function()
				previous.Parent = Workspace
			end)
			savedFolder = nil
		end
		cameraPos, cameraLook, lastCentre = nil, nil, nil
	end,
}

-- Handoff: the saved camera for the last apply(), or the pure rule at the origin before one.
function LookDevModelsPropsR7.camera(): (Vector3?, Vector3?)
	if cameraPos and cameraLook then
		return cameraPos, cameraLook
	end
	local ok, position, target = pcall(function()
		local rule = ModelMapPropsR7.cameraRule
		return Vector3.new(0, rule.up, rule.front), Vector3.new(0, rule.lookY, 0)
	end)
	if ok then
		return position, target
	end
	return nil, nil
end

function LookDevModelsPropsR7.yard(): { x: number, z: number }?
	return lastCentre
end

LookDev.register("props_r7", applier)

return LookDevModelsPropsR7
