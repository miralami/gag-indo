--!strict
-- LookDevStreetFurnR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "streetfurn_r8" candidate
-- (WORK_QUEUE section M item 80). Builds ring-road lampu/obor posts, three papan petunjuk, one
-- gapura at the bridge approach, one tiang listrik line with a sagging cable and two bale-bale
-- shelters from original Parts under `LookDevStreetFurnR8_streetfurn_r8`. No asset IDs, no brand.
--
-- All anchors come from MapSpec geometry through Shared.ModelMapStreetFurnR8; no world-coordinate
-- literals. Sign boards read their text from Shared.Strings by KEY with the fixed server locale
-- ("id"), so no player-facing text literal is written to a Text property in src/.
--
-- Posts, gapura and the pole line stand on the verge and carry a VergePost attribute: the harness
-- exempts exactly those designed verge fixtures from the 6-stud centreline clearance. Every part
-- is anchored and non-collidable; apply is idempotent and restore returns any prior folder exactly.
-- Engine calls are pcall-guarded; failures are published through LookDevFailures.
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("streetfurn_r8", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevStreetFurnR8] missing service " .. name)
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
		warn("[LookDevStreetFurnR8] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, Data, Strings, LookDevFailures, TierThin = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapStreetFurnR8),
		require((Shared :: any).Strings),
		require((Shared :: any).LookDevFailures),
		require((Shared :: any).TierThin)
end)
if not okModules or not LookDev or not Data or not Strings or not LookDevFailures or not TierThin then
	warn(
		"[LookDevStreetFurnR8] could not require LookDev / ModelMapStreetFurnR8 / Strings / LookDevFailures / TierThin"
	)
	return {}
end

local okSpec, loadedSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if not okSpec or not loadedSpec then
	warn("[LookDevStreetFurnR8] could not require MapSpec")
end
local MapSpec: any? = if okSpec then loadedSpec else nil

local LookDevStreetFurnR8 = {}

local SIGN_LANG = "id" -- server has no client locale; Indonesian is the canonical sign text

local failures = 0
local activeFolder: any? = nil
local savedFolder: any? = nil
local staged: { any } = {}

local function fail(message: string)
	failures += 1
	warn("[LookDevStreetFurnR8] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set(Data.familyId, failures)
	end)
end

local function track(instance: any?)
	if instance then
		staged[#staged + 1] = instance
	end
end

local function clearActive()
	for index = #staged, 1, -1 do
		pcall(function()
			staged[index]:Destroy()
		end)
	end
	table.clear(staged)
	local folder = activeFolder
	if folder then
		pcall(function()
			folder:Destroy()
		end)
	end
	activeFolder = nil
end

local function newFolder(name: string, parent: any): any?
	local okNew, folder = pcall(function()
		return Instance.new("Folder")
	end)
	if not okNew or not folder then
		return nil
	end
	pcall(function()
		folder.Name = name
		folder.Parent = parent
	end)
	return folder
end

local function newModel(name: string, kind: string, verge: boolean, folder: any): any?
	local ok, model = pcall(function()
		return Instance.new("Model")
	end)
	if not ok or not model then
		fail("could not create model for " .. name)
		return nil
	end
	track(model)
	local okSet = pcall(function()
		model.Name = name
		model:SetAttribute(Data.stageAttribute, Data.familyId)
		model:SetAttribute(Data.kindAttribute, kind)
		if verge then
			-- VergePost is the harness exemption: posts / gapura / pole line only.
			model:SetAttribute(Data.vergeAttribute, true)
		end
		model.Parent = folder
	end)
	if not okSet then
		fail("could not configure model for " .. name)
	end
	return model
end

local function placePart(
	model: any,
	descriptor: any,
	base: any,
	kind: string,
	verge: boolean,
	colour: { number }?,
	size: { number }?,
	offset: { number }?
): any?
	local ok, part = pcall(function()
		return Instance.new("Part")
	end)
	if not ok or not part then
		fail("could not create part " .. descriptor.name .. " for " .. kind)
		return nil
	end
	track(part)
	local shapeName = descriptor.shape == "Cylinder" and "Cylinder" or "Block"
	local finalSize = size or descriptor.size
	local finalOffset = offset or descriptor.offset
	local finalColour = colour or descriptor.colour
	local okSet = pcall(function()
		local okShape, shape = pcall(function()
			return (Enum :: any).PartType[shapeName]
		end)
		part.Name = descriptor.name
		part.Shape = if okShape and shape then shape else Enum.PartType.Block
		part.Size = Vector3.new(finalSize[1], finalSize[2], finalSize[3])
		part.CFrame = base * CFrame.new(finalOffset[1], finalOffset[2], finalOffset[3])
		part.Color = Color3.fromRGB(finalColour[1], finalColour[2], finalColour[3])
		part.Material = (Enum :: any).Material[descriptor.material] or Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		part:SetAttribute(Data.stageAttribute, Data.familyId)
		part:SetAttribute(Data.kindAttribute, kind)
		if verge then
			part:SetAttribute(Data.vergeAttribute, true)
		end
		part.Parent = model
	end)
	if not okSet then
		fail("could not configure part " .. descriptor.name .. " for " .. kind)
	end
	return part
end

local function baseCFrame(x: number, z: number, yaw: number, groundY: number): any?
	local ok, base = pcall(function()
		return CFrame.new(x, groundY, z) * CFrame.Angles(0, math.rad(yaw), 0)
	end)
	if not ok or not base then
		fail("could not build base CFrame")
		return nil
	end
	return base
end

-- A sign board carries its Strings KEY and renders Strings.get(lang, key) on a SurfaceGui label.
local function addSignText(board: any, key: string)
	local ok = pcall(function()
		board:SetAttribute(Data.keyAttribute, key)
		local gui = Instance.new("SurfaceGui")
		gui.Name = "SignFace"
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(48, 34, 24)
		label.Text = Strings.get(SIGN_LANG, key)
		label.Parent = gui
		gui.Parent = board
		track(label)
		track(gui)
	end)
	if not ok then
		fail("could not write sign text for " .. key)
	end
end

local function stagePosts(groundY: number, folder: any)
	local road = MapSpec.ROAD
	local posts = Data.ringPosts(
		road.ringCentre,
		Data.POST_SPACING,
		road.gapStart,
		road.gapEnd,
		road.ringWidth,
		Data.VERGE_OFFSET
	)
	for index, recipe in ipairs(posts) do
		local kind = recipe.kind
		local model = newModel(string.format("StreetFurn_%s_%02d", kind, index), kind, true, folder)
		if model then
			local base = baseCFrame(recipe.x, recipe.z, recipe.yaw, groundY)
			if base then
				for _, descriptor in ipairs(Data.RECIPES[kind]) do
					placePart(model, descriptor, base, kind, true)
				end
			end
		end
	end
end

local function stageSigns(groundY: number, folder: any)
	for index, recipe in ipairs(Data.signs(MapSpec.PLAZA)) do
		local model = newModel(string.format("StreetFurn_sign_%02d", index), "sign", false, folder)
		if model then
			local base = baseCFrame(recipe.x, recipe.z, recipe.yaw, groundY)
			if base then
				for _, descriptor in ipairs(Data.RECIPES.sign) do
					local board = placePart(model, descriptor, base, "sign", false)
					if board and descriptor.name == "Board" then
						addSignText(board, recipe.key)
					end
				end
			end
		end
	end
end

local function stageGapura(groundY: number, folder: any)
	local bridge = nil
	for _, continuation in ipairs(MapSpec.roadContinuations()) do
		if continuation.name == "RoadToBridge" then
			bridge = continuation
			break
		end
	end
	if not bridge then
		fail("no MapSpec bridge-approach continuation")
		return
	end
	for index, recipe in ipairs(Data.gapura(bridge, MapSpec.ROAD.linkHalfWidth)) do
		local model = newModel(string.format("StreetFurn_gapura_%02d", index), "gapura", true, folder)
		if model then
			local base = baseCFrame(recipe.x, recipe.z, recipe.yaw, groundY)
			if base then
				for _, descriptor in ipairs(Data.RECIPES.gapura) do
					local size, offset = descriptor.size, descriptor.offset
					if descriptor.name == "LegL" then
						offset = { -recipe.halfSpan, offset[2], 0 }
					elseif descriptor.name == "LegR" then
						offset = { recipe.halfSpan, offset[2], 0 }
					elseif descriptor.name == "Lintel" then
						size = { recipe.halfSpan * 2 + 1.2, size[2], size[3] }
					elseif descriptor.name == "Roof" then
						size = { recipe.halfSpan * 2 + 3, size[2], size[3] }
					end
					placePart(model, descriptor, base, "gapura", true, nil, size, offset)
				end
			end
		end
	end
end

local function stagePoles(groundY: number, folder: any)
	local arm = nil
	for _, candidate in ipairs(MapSpec.roadArms()) do
		if candidate.name == "RoadEast" then
			arm = candidate
			break
		end
	end
	if not arm then
		fail("no MapSpec east road arm")
		return
	end
	local poles = Data.poles(arm)
	for index, recipe in ipairs(poles) do
		local model = newModel(string.format("StreetFurn_pole_%02d", index), "pole", true, folder)
		if model then
			local base = baseCFrame(recipe.x, recipe.z, 0, groundY)
			if base then
				for _, descriptor in ipairs(Data.RECIPES.pole) do
					placePart(model, descriptor, base, "pole", true)
				end
			end
		end
	end
	for index = 1, #poles - 1 do
		local a = { x = poles[index].x, z = poles[index].z, y = poles[index].height + 0.2 }
		local b = { x = poles[index + 1].x, z = poles[index + 1].z, y = poles[index + 1].height + 0.2 }
		local points = Data.cablePoints(a, b)
		local model = newModel(string.format("StreetFurn_cable_%02d", index), "cable", true, folder)
		if model then
			for point = 1, #points - 1 do
				local from, to = points[point], points[point + 1]
				local ok = pcall(function()
					local start = Vector3.new(from.x, groundY + from.y, from.z)
					local finish = Vector3.new(to.x, groundY + to.y, to.z)
					local middle = (start + finish) / 2
					local wire = Instance.new("Part")
					wire.Name = string.format("Cable_%02d", point)
					wire.Size = Vector3.new(0.18, 0.18, (finish - start).Magnitude + 0.1)
					wire.CFrame = CFrame.lookAt(middle, finish)
					wire.Color = Color3.fromRGB(46, 42, 38)
					wire.Material = Enum.Material.SmoothPlastic
					wire.Anchored = true
					wire.CanCollide = false
					wire:SetAttribute(Data.stageAttribute, Data.familyId)
					wire:SetAttribute(Data.kindAttribute, "cable")
					wire:SetAttribute(Data.vergeAttribute, true)
					wire.Parent = model
					track(wire)
				end)
				if not ok then
					fail("could not stage cable segment " .. tostring(point))
				end
			end
		end
	end
end

-- ponytail: Rendah halves the two surplus decorative bale-bale shelters. Posts, signs, gapura,
-- poles and cable are structural / Strings-bearing and never thin (CHECK_080: >=18 posts + all kinds).
local function stageBales(groundY: number, folder: any, tier: any?)
	for index, recipe in ipairs(Data.bales(MapSpec.PLAZA)) do
		if not TierThin.shouldKeep(tier, index) then
			continue
		end
		local model = newModel(string.format("StreetFurn_bale_%02d", index), "bale", false, folder)
		if model then
			local base = baseCFrame(recipe.x, recipe.z, recipe.yaw, groundY)
			if base then
				for _, descriptor in ipairs(Data.RECIPES.bale) do
					placePart(model, descriptor, base, "bale", false)
				end
				for _, corner in ipairs({ { -4, -2.6 }, { 4, -2.6 }, { -4, 2.6 }, { 4, 2.6 } }) do
					placePart(
						model,
						{ name = "BambooPost", shape = "Cylinder", material = "Wood" },
						base,
						"bale",
						false,
						{ 146, 112, 66 },
						{ 0.5, 8, 0.5 },
						{ corner[1], 4, corner[2] }
					)
				end
			end
		end
	end
end

local applier = {
	apply = function(plan)
		local tier = plan and plan.tier
		failures = 0
		pcall(function()
			LookDevFailures.reset(Data.familyId)
		end)
		clearActive()
		if not Workspace or not MapSpec then
			fail("missing Workspace/MapSpec")
			publishFailures()
			return
		end
		local previous = nil
		pcall(function()
			previous = (Workspace :: any):FindFirstChild(Data.folderName)
		end)
		if previous then
			pcall(function()
				previous.Parent = nil
			end)
			savedFolder = previous
		end
		local folder = newFolder(Data.folderName, Workspace)
		if not folder then
			fail("could not create staging folder")
			publishFailures()
			return
		end
		activeFolder = folder
		track(folder)
		stagePosts(MapSpec.GROUND_Y, folder)
		stageSigns(MapSpec.GROUND_Y, folder)
		stageGapura(MapSpec.GROUND_Y, folder)
		stagePoles(MapSpec.GROUND_Y, folder)
		stageBales(MapSpec.GROUND_Y, folder, tier)
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
		publishFailures()
	end,
}

LookDevStreetFurnR8.apply = applier.apply
LookDevStreetFurnR8.restore = applier.restore

LookDev.register(Data.familyId, applier)

return LookDevStreetFurnR8
