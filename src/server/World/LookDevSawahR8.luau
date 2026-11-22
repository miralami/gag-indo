--!strict
-- LookDevSawahR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "sawah_r8" candidate
-- (WORK_QUEUE section M item 72, rebuilt in section O item 140; padi rebuilt in section Q item 191).
-- Terrace dressing: one muddy water sheet per terrace, dense padi rows, a grassy bund, one small
-- field hut on terrace 2 and stepping stones between terraces.
--
-- BAKED PADI MODEL, NO PROCEDURAL BLADES. Water, bunds, verge, hut and stones are plain Parts from
-- Shared.ModelMapSawahR8 and MapSpec.paddyWater(); padi clumps stage the real baked Creator Store
-- rice model fetched clone-first via LookDevAssetLoader (numeric ID in Shared.ModelMapSawahR8).
-- A failed baked load fails loudly and leaves the tagged clump Model empty: no fake geometry.
-- Terrain, greybox and terrace tops are never touched. All Parts are anchored, non-collidable,
-- tagged, and removed by restore() (which reattaches any prior folder). Padi clumps are Models
-- carrying PadiPart / TerraceIndex / PadiClump / PadiRow; each baked BasePart and every bund tuft
-- is also a PadiPart. Enable from the Studio Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("sawah_r8", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevSawahR8] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Workspace = service("Workspace")
if not ReplicatedStorage or not Workspace then
	return {}
end

local Shared: any? = nil
local okShared, sharedValue = pcall(function()
	return (ReplicatedStorage :: any):WaitForChild("Shared")
end)
if okShared and sharedValue then
	Shared = sharedValue
else
	warn("[LookDevSawahR8] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, LookDevAssetLoader, TierThin = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapSawahR8),
		require(script.Parent.LookDevAssetLoader),
		require((Shared :: any).TierThin)
end)
if not okModules or not LookDev or not Data or not LookDevAssetLoader or not TierThin then
	warn("[LookDevSawahR8] could not require LookDev / ModelMapSawahR8 / asset loader / TierThin")
	return {}
end

local GROUND_Y = 0.5
local okSpec, MapSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if okSpec and type(MapSpec) == "table" and type(MapSpec.GROUND_Y) == "number" then
	GROUND_Y = MapSpec.GROUND_Y
end

local LookDevSawahR8 = {}

local FAMILY_ID = Data.id
local activeFolder: any? = nil
local savedFolder: any? = nil
local loadedPadiModels: { any } = {}
local failures = 0

-- Baked padi: a clean apply publishes 0. The counter only moves if staging itself fails, and is
-- published on every exit path for the Studio reads.
local function publishFailures()
	pcall(function()
		require(game.ReplicatedStorage.Shared.LookDevFailures).set(FAMILY_ID, failures)
	end)
end

local function fail(message: string)
	failures += 1
	warn("[LookDevSawahR8] " .. message)
end

local function taggedFolder(name: string, terrace: number?, parent: any): any?
	local folder: any? = nil
	local ok, created = pcall(function()
		return Instance.new("Folder")
	end)
	if ok and created then
		folder = created
	end
	if not folder then
		return nil
	end
	pcall(function()
		folder.Name = name
		folder:SetAttribute("LookDevSawahR8", FAMILY_ID)
		if terrace then
			folder:SetAttribute("Terrace", terrace)
		end
		folder.Parent = parent
	end)
	return folder
end

local function taggedPart(kind: string, name: string, terrace: number, parent: any): any?
	local part: any? = nil
	local ok, created = pcall(function()
		return Instance.new("Part")
	end)
	if ok and created then
		part = created
	end
	if not part then
		return nil
	end
	pcall(function()
		part.Name = name
		part.Anchored = true
		part.CanCollide = false
		part.Material = Enum.Material.Wood
		part:SetAttribute("LookDevSawahR8", FAMILY_ID)
		part:SetAttribute("Terrace", terrace)
		part:SetAttribute("Kind", kind)
		part.Parent = parent
	end)
	return part
end

-- One clump Model per deterministic padi clump. Its numeric PadiClump id is shared by its blades,
-- so a harness counting DISTINCT ids never counts a blade as a second clump.
local function taggedClump(clump: any, parent: any): any?
	local model: any? = nil
	local ok, created = pcall(function()
		return Instance.new("Model")
	end)
	if ok and created then
		model = created
	end
	if not model then
		return nil
	end
	pcall(function()
		model.Name = "PadiClump_" .. clump.terrace .. "_" .. clump.id
		model:SetAttribute("LookDevSawahR8", FAMILY_ID)
		model:SetAttribute("Terrace", clump.terrace)
		model:SetAttribute("TerraceIndex", clump.terrace)
		model:SetAttribute("Kind", "padi_clump")
		model:SetAttribute("PadiPart", true)
		model:SetAttribute("PadiClump", clump.id)
		model:SetAttribute("PadiRow", clump.row)
		model:SetAttribute("PadiSide", clump.side)
		model.Parent = parent
	end)
	return model
end

local function place(part: any?, centre: { number }, size: { number }): boolean
	if not part then
		return false
	end
	local ok = pcall(function()
		part.Size = Vector3.new(size[1], size[2], size[3])
		part.CFrame = CFrame.new(centre[1], centre[2], centre[3])
	end)
	return ok
end

-- World AABB from every descendant BasePart's CFrame + Size corners. No GetBoundingBox on Part.
local function bounds(root: any): (Vector3?, Vector3?)
	local mins: Vector3? = nil
	local maxs: Vector3? = nil
	local function account(part: any)
		local ok, cf, sz = pcall(function()
			return part.CFrame, part.Size
		end)
		if not ok or not cf or not sz then
			return
		end
		for _, sx in ipairs({ -1, 1 }) do
			for _, sy in ipairs({ -1, 1 }) do
				for _, sz2 in ipairs({ -1, 1 }) do
					local okCorner, corner = pcall(function()
						return cf * Vector3.new(sx * sz.X / 2, sy * sz.Y / 2, sz2 * sz.Z / 2)
					end)
					if okCorner and corner then
						if not mins then
							mins, maxs = corner, corner
						else
							mins = Vector3.new(
								math.min(mins.X, corner.X),
								math.min(mins.Y, corner.Y),
								math.min(mins.Z, corner.Z)
							)
							maxs = Vector3.new(
								math.max(maxs.X, corner.X),
								math.max(maxs.Y, corner.Y),
								math.max(maxs.Z, corner.Z)
							)
						end
					end
				end
			end
		end
	end
	local okRoot, isPart = pcall(function()
		return root:IsA("BasePart")
	end)
	if okRoot and isPart then
		account(root)
	end
	local okDesc, descendants = pcall(function()
		return root:GetDescendants()
	end)
	if okDesc and descendants then
		for _, inst in ipairs(descendants) do
			local okPart, part = pcall(function()
				return inst:IsA("BasePart")
			end)
			if okPart and part then
				account(inst)
			end
		end
	end
	if not mins or not maxs then
		return nil, nil
	end
	return (mins + maxs) / 2, maxs - mins
end

-- Item 191: real baked BaseParts (asset itself if a BasePart, plus descendants), scripts stripped.
local function padiBaseParts(root: any): { any }
	local out = {}
	local okRoot, isPart = pcall(function()
		return root:IsA("BasePart")
	end)
	if okRoot and isPart then
		out[#out + 1] = root
	end
	local okDesc, descendants = pcall(function()
		return root:GetDescendants()
	end)
	if okDesc and descendants then
		for _, instance in ipairs(descendants) do
			pcall(function()
				if instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript") then
					instance:Destroy()
				elseif instance:IsA("BasePart") then
					out[#out + 1] = instance
				end
			end)
		end
	end
	return out
end

-- ponytail: Rendah keeps <=50% of decorative padi clumps and stepping stones; water sheets,
-- terrace bunds and the gubuk are structural. Clumps keep all their blades when kept.
local function apply(plan: any?)
	failures = 0
	loadedPadiModels = {}
	local tier: any? = if plan then plan.tier else nil
	local instanceIndex = 0
	if activeFolder then
		publishFailures()
		return
	end

	local previous: any? = nil
	pcall(function()
		previous = (Workspace :: any):FindFirstChild(Data.folderName)
	end)
	if previous then
		pcall(function()
			previous.Parent = nil
		end)
		savedFolder = previous
	end

	local folder: any? = nil
	local okNew, created = pcall(function()
		return Instance.new("Folder")
	end)
	if okNew and created then
		folder = created
		pcall(function()
			folder.Name = Data.folderName
			folder:SetAttribute("LookDevSawahR8", FAMILY_ID)
			folder.Parent = Workspace
		end)
	end
	if not folder then
		fail("could not create staging folder")
		publishFailures()
		return
	end
	activeFolder = folder

	local panes: any = nil
	local okPanes, value = pcall(function()
		return MapSpec.paddyWater()
	end)
	if okPanes and type(value) == "table" and #value >= #Data.TERRACE_TOPS * 2 then
		panes = value
	else
		fail("could not read MapSpec water panes")
	end

	for _, terrace in Data.terraceIndices() do
		local terraceFolder = taggedFolder("Terrace_" .. terrace .. "_sawah_r8", terrace, folder)
		if not terraceFolder then
			fail("could not create folder for terrace " .. terrace)
			continue
		end

		if panes then
			local pair = Data.waterPanes(panes, terrace)
			local water = taggedFolder("SawahWater_" .. terrace, terrace, terraceFolder)
			if water then
				pcall(function()
					water:SetAttribute("Kind", "water_sheet")
				end)
			end
			for sideIndex, pane in ipairs(pair) do
				if type(pane) ~= "table" or type(pane.centre) ~= "table" or type(pane.size) ~= "table" then
					fail("missing pane for terrace " .. terrace .. " " .. Data.SIDES[sideIndex])
					continue
				end
				if not water then
					fail("missing water folder for terrace " .. terrace)
					continue
				end
				if TierThin.shouldKeep(tier, instanceIndex + 1, true) then
					local part =
						taggedPart("water_pane", "Pane_" .. terrace .. "_" .. Data.SIDES[sideIndex], terrace, water)
					if part then
						pcall(function()
							part:SetAttribute("Side", Data.SIDES[sideIndex])
							part.Material = Enum.Material.Glass
							part.Transparency = Data.WATER_TRANSPARENCY
							part.Color = Color3.fromRGB(Data.WATER_COLOR[1], Data.WATER_COLOR[2], Data.WATER_COLOR[3])
							part.CastShadow = false
						end)
					end
					if not place(part, pane.centre, pane.size) then
						fail("could not place pane for terrace " .. terrace .. " " .. Data.SIDES[sideIndex])
					end
				end
			end
		end
	end

	-- Item 178: rounded, grass-green bunds replace the flat lime terrace edges. Cylinders lie along
	-- X (local Y rotated 90 degrees about Z); the curved crest is below 1.5 studs wide. Bund parts
	-- carry no PadiPart tag, so TUFT_SHAPE / SAWAH_GREEN keep counting only padi and tuft geometry.
	local bundFolder = taggedFolder("Bunds_sawah_r8", nil, folder)
	for index, bund in ipairs(Data.bunds(panes)) do
		local terraceFolder = folder:FindFirstChild("Terrace_" .. bund.terrace .. "_sawah_r8")
		local part = taggedPart(
			"grass_bund",
			`Bund_{bund.terrace}_{bund.side}_{bund.edge}_{index}`,
			bund.terrace,
			terraceFolder or bundFolder or folder
		)
		if part then
			pcall(function()
				part:SetAttribute("Bund", true)
				part.Shape = Enum.PartType.Cylinder
				part.Material = Enum.Material.Grass
				part.Color = Color3.fromRGB(Data.BUND_COLOR[1], Data.BUND_COLOR[2], Data.BUND_COLOR[3])
			end)
		end
		local okPlace = false
		if part then
			okPlace = pcall(function()
				part.Size = Vector3.new(bund.radius * 2, bund.length, bund.radius * 2)
				part.CFrame = CFrame.new(bund.x, bund.y, bund.z) * CFrame.Angles(0, 0, math.pi / 2)
			end)
		end
		if not okPlace then
			fail("could not place grass bund " .. index)
		end
	end

	-- Padi rows: one clump column every ROW_SPACING studs along each water pane, clumps spaced the
	-- same distance across the pane. Each clump is a tagged Model holding the real baked rice model,
	-- scaled to PADI_FOOTPRINT_X x PADI_FOOTPRINT_Z and PADI_HEIGHT_MIN..MAX (all axes <= 2.5).
	local clumpFolders = {}
	for _, terrace in Data.terraceIndices() do
		local terraceFolder = folder:FindFirstChild("Terrace_" .. terrace .. "_sawah_r8")
		clumpFolders[terrace] = taggedFolder("Padi_" .. terrace, terrace, terraceFolder or folder)
	end
	local clumps = Data.padiClumps(panes)
	for _, clump in clumps do
		instanceIndex += 1
		if TierThin.shouldKeep(tier, instanceIndex) then
			local clumpModel = taggedClump(clump, clumpFolders[clump.terrace] or folder)
			local stage = Data.padiStage(clump.terrace)
			local okLoad, asset = pcall(function()
				return LookDevAssetLoader.get(Data.PADI_ASSET_ID, FAMILY_ID)
			end)
			if not okLoad or not asset then
				fail("baked padi unavailable for clump " .. clump.id .. " asset " .. tostring(Data.PADI_ASSET_ID))
				continue
			end
			loadedPadiModels[#loadedPadiModels + 1] = asset
			local centre, size = bounds(asset)
			if not centre or not size or size.Y <= 0 then
				fail("invalid baked padi bounds for clump " .. clump.id)
				continue
			end
			local height = Data.padiHeight(clump.id)
			local sx = Data.PADI_FOOTPRINT_X / size.X
			local sy = height / size.Y
			local sz = Data.PADI_FOOTPRINT_Z / size.Z
			local yawCF = CFrame.Angles(0, Data.padiYaw(clump.id), 0)
			local target = Vector3.new(clump.x, clump.y + height / 2, clump.z)
			local colour = Data.PADI_STAGE_COLOURS[stage]
			-- Item 191: stamp PadiAssetId and GrowthStage via the Data attribute constants.
			local bakedParts = padiBaseParts(asset)
			if #bakedParts == 0 then
				fail("baked padi has no BasePart for clump " .. clump.id)
				continue
			end
			local okStage = pcall(function()
				for _, baked in ipairs(bakedParts) do
					local cf, partSize = baked.CFrame, baked.Size
					local offset = cf.Position - centre
					local scaled = Vector3.new(offset.X * sx, offset.Y * sy, offset.Z * sz)
					baked.Size = Vector3.new(partSize.X * sx, partSize.Y * sy, partSize.Z * sz)
					baked.CFrame = CFrame.new(target + yawCF * scaled) * yawCF * cf.Rotation
					baked.Anchored = true
					baked.CanCollide = false
					baked.Color = Color3.fromRGB(colour[1], colour[2], colour[3])
					baked:SetAttribute("PadiPart", true)
					baked:SetAttribute("TerraceIndex", clump.terrace)
					baked:SetAttribute("PadiClump", clump.id)
					baked:SetAttribute("PadiRow", clump.row)
					baked:SetAttribute("PadiSide", clump.side)
					baked:SetAttribute(Data.PADI_ASSET_ID_ATTRIBUTE, Data.PADI_ASSET_ID)
					baked:SetAttribute(Data.PADI_STAGE_ATTRIBUTE, stage)
					baked.Parent = clumpModel or folder
				end
			end)
			if not okStage then
				fail("could not stage baked padi for clump " .. clump.id)
			end
		end
	end
	local clumpsByTerrace = {}
	for _, clump in clumps do
		clumpsByTerrace[clump.terrace] = (clumpsByTerrace[clump.terrace] or 0) + 1
	end
	for _, terrace in Data.terraceIndices() do
		if (clumpsByTerrace[terrace] or 0) < Data.PADI_CLUMPS_MIN then
			fail("only " .. (clumpsByTerrace[terrace] or 0) .. " padi clumps on terrace " .. terrace)
		end
	end

	-- Grassy bund: short alang-alang blades just outside each pane's water rectangle.
	local tuftIndex = 0
	for _, tuft in Data.vergeTufts(panes) do
		tuftIndex += 1
		local terraceFolder = folder:FindFirstChild("Terrace_" .. tuft.terrace .. "_sawah_r8")
		for blade, offset in ipairs(tuft.blades) do
			if TierThin.shouldKeep(tier, instanceIndex + 1, true) then
				local part = taggedPart(
					"verge",
					`Verge_{tuft.terrace}_{tuft.side}_{tuftIndex}_{blade}`,
					tuft.terrace,
					terraceFolder or folder
				)
				local height = Data.BLADE_HEIGHTS[blade]
				local centre = {
					tuft.x + offset[1],
					tuft.y + Data.BUND_TUFT_RISE + height / 2 + offset[2],
					tuft.z + offset[3],
				}
				if not place(part, centre, { 0.14, height, 0.14 }) then
					fail("could not place verge blade " .. tuftIndex .. "/" .. blade)
				end
				if part then
					pcall(function()
						part.Material = Enum.Material.Grass
						part.Color = Color3.fromRGB(92, 132, 58)
						part:SetAttribute("Tuft", tuftIndex)
						part:SetAttribute("Blade", blade)
						part:SetAttribute("PadiPart", true)
						part:SetAttribute("TerraceIndex", tuft.terrace)
					end)
				end
			end
		end
	end
	if tuftIndex < Data.MIN_VERGE_TUFTS then
		fail("only " .. tuftIndex .. " verge tufts")
	end

	-- Exactly one hut, on terrace 2's bund, clear of the water panes and the central ramp.
	local hut = Data.gubukPosition(panes, 2)
	local hutFolder = taggedFolder("Gubuk_2_sawah_r8", 2, folder)
	if hutFolder then
		pcall(function()
			hutFolder:SetAttribute("Gubuk", 1)
		end)
	end
	for index, piece in ipairs(Data.gubukParts()) do
		if TierThin.shouldKeep(tier, instanceIndex + 1, true) then
			local part = taggedPart(piece.kind, "Gubuk_" .. piece.kind .. "_" .. index, 2, hutFolder or folder)
			if part then
				pcall(function()
					part:SetAttribute("Gubuk", 1)
					part.Material = if piece.kind == "gubuk_roof" then Enum.Material.Fabric else Enum.Material.Wood
					part.Color = if piece.kind == "gubuk_roof"
						then Color3.fromRGB(146, 118, 58)
						else Color3.fromRGB(110, 86, 48)
				end)
			end
			local centre = { hut.x + piece.lx, (hut.y or GROUND_Y) + piece.ly, hut.z + piece.lz }
			if not place(part, centre, piece.size) then
				fail("could not place gubuk part " .. index)
			end
		end
	end

	for index, stone in ipairs(Data.steppingStones()) do
		instanceIndex += 1
		if TierThin.shouldKeep(tier, instanceIndex) then
			local part = taggedPart("stepping_stone", "SteppingStone_" .. index, stone.terrace, folder)
			if part then
				pcall(function()
					part.Material = Enum.Material.Rock
					part.Color = Color3.fromRGB(126, 122, 108)
				end)
			end
			if not place(part, { stone.x, stone.y, stone.z }, stone.size) then
				fail("could not place stepping stone " .. index)
			end
		end
	end

	publishFailures()
end

local function restore()
	for _, model in ipairs(loadedPadiModels) do
		pcall(function()
			model:Destroy()
		end)
	end
	loadedPadiModels = {}
	if activeFolder then
		pcall(function()
			activeFolder:Destroy()
		end)
		activeFolder = nil
	end
	if savedFolder then
		pcall(function()
			savedFolder.Parent = Workspace
		end)
		savedFolder = nil
	end
end

LookDevSawahR8.apply = apply
LookDevSawahR8.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevSawahR8
