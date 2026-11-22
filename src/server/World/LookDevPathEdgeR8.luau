--!strict
-- LookDevPathEdgeR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "pathedge_r8" candidate
-- (WORK_QUEUE section M item 75, redone in section O item 142). Dirt-path edge dressing: real
-- baked alang-alang grass clumps (clone-first, procedural thin-blade fallback), pebbles and flat
-- puddles along BOTH edges of every road arm, ring segment and continuation.
--
-- NO INVENTED ASSET IDS. The only model ID is read from Shared.ModelMapVegetationR6.ids.alang_alang
-- (verified free Creator Store grass clump, 361802126, recorded in the round-6 shortlist); the
-- applier fetches it clone-first via LookDevAssetLoader (bake -> LoadAsset fallback inside the
-- loader) and scales its footprint to <= Data.CLUMP_MAX_WIDTH studs using CFrame + Size corner math
-- (this Studio has no Part.GetBoundingBox). If the model cannot be loaded or placed, a procedural
-- clump of thin blades (also <= CLUMP_MAX_WIDTH wide) is staged instead. Terrain, road slabs,
-- RoadEdge strips, RingRoad pieces, buildings and the ford are never edited: every piece is an
-- anchored, non-collidable, tagged Part removed by restore() (which reattaches any prior folder).
-- Enable from the Studio Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("pathedge_r8", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevPathEdgeR8] missing service " .. name)
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
	warn("[LookDevPathEdgeR8] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, LookDevAssetLoader, VegR6, TierThin = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapPathEdgeR8),
		require(script.Parent.LookDevAssetLoader),
		require((Shared :: any).ModelMapVegetationR6),
		require((Shared :: any).TierThin)
end)
if not okModules or not LookDev or not Data or not LookDevAssetLoader or not VegR6 or not TierThin then
	warn(
		"[LookDevPathEdgeR8] could not require LookDev / ModelMapPathEdgeR8 / asset loader / vegetation map / TierThin"
	)
	return {}
end

local MapSpec: any? = nil
local okSpec, specValue = pcall(function()
	return require(script.Parent.MapSpec)
end)
if okSpec and specValue and type(specValue.roadArms) == "function" and type(specValue.ROAD) == "table" then
	MapSpec = specValue
else
	warn("[LookDevPathEdgeR8] could not require MapSpec")
end

local LookDevPathEdgeR8 = {}

local FAMILY_ID = Data.id
local GRASS_ASSET_ID = VegR6.ids.alang_alang
local activeFolder: any? = nil
local savedFolder: any? = nil
local failures = 0

local function publishFailures()
	pcall(function()
		require(game.ReplicatedStorage.Shared.LookDevFailures).set(FAMILY_ID, failures)
	end)
end

local function fail(message: string)
	failures += 1
	warn("[LookDevPathEdgeR8] " .. message)
end

local function taggedFolder(name: string, parent: any): any?
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
		folder:SetAttribute("LookDevPathEdgeR8", FAMILY_ID)
		folder.Parent = parent
	end)
	return folder
end

-- One tagged Part per piece. The item-142 attributes are the harness contract: Lateral is signed,
-- HalfWidth is the path's half-width, CentreX/CentreZ is the nearest centreline point.
local function taggedPart(piece: any, name: string, parent: any): any?
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
		part:SetAttribute("LookDevPathEdgeR8", FAMILY_ID)
		part:SetAttribute("PathEdgePart", true)
		part:SetAttribute("Kind", piece.kind)
		part:SetAttribute("Path", piece.path)
		part:SetAttribute("Side", piece.side)
		part:SetAttribute("Lateral", piece.lateral)
		part:SetAttribute("HalfWidth", piece.halfWidth)
		part:SetAttribute("CentreX", piece.centre[1])
		part:SetAttribute("CentreZ", piece.centre[2])
		part.Parent = parent
	end)
	return part
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

-- Scale the baked clump so its footprint is at most maxWidth studs in X and Z, then sit its bbox
-- bottom on bottomY at (x, z). The pivot of a baked asset can be far from its geometry, so carry
-- the bbox-centre offset like the other LookDev appliers do.
local function placeClumpModel(model: any, x: number, bottomY: number, z: number, maxWidth: number): boolean
	local _, size = bounds(model)
	local extent = size and math.max(size.X, size.Z) or 0
	if extent <= 0 then
		return false
	end
	local factor = math.min(1, maxWidth / extent)
	local okScale = false
	local okKind, isModel, isPart = pcall(function()
		return model:IsA("Model"), model:IsA("BasePart")
	end)
	if okKind and isModel then
		okScale = pcall(function()
			model:ScaleTo(factor)
		end)
	elseif okKind and isPart then
		okScale = pcall(function()
			model.Size = model.Size * factor
		end)
	end
	if not okScale then
		return false
	end
	local okDesc, descendants = pcall(function()
		return model:GetDescendants()
	end)
	if okDesc and descendants then
		for _, inst in ipairs(descendants) do
			pcall(function()
				if inst:IsA("BasePart") then
					inst.Anchored = true
					inst.CanCollide = false
				end
			end)
		end
	end
	local centre, scaled = bounds(model)
	local okPivot, pivot = pcall(function()
		return model:GetPivot()
	end)
	if not centre or not scaled or not okPivot or not pivot then
		return false
	end
	local offset = centre - pivot.Position
	local target = Vector3.new(x, bottomY + scaled.Y / 2, z) - offset
	return pcall(function()
		model:PivotTo(CFrame.new(target.X, target.Y, target.Z))
	end)
end

-- Procedural fallback: 4 thin blades, all inside a CLUMP_MAX_WIDTH square. Blades are children of
-- the tagged Part but carry no family tag, so the harness counts one piece per clump.
local BLADE_OFFSETS = {
	{ 0, 0 },
	{ -0.34, 0.26 },
	{ 0.34, -0.26 },
	{ -0.18, -0.34 },
}

local function addBladeFallback(part: any, x: number, z: number, bottomY: number, index: number)
	for bladeIndex, offset in ipairs(BLADE_OFFSETS) do
		local blade: any? = nil
		local ok, created = pcall(function()
			return Instance.new("Part")
		end)
		if ok and created then
			blade = created
		end
		if not blade then
			continue
		end
		pcall(function()
			blade.Name = "GrassBlade_" .. index .. "_" .. bladeIndex
			blade.Anchored = true
			blade.CanCollide = false
			blade.Material = Enum.Material.Grass
			blade.Color = Color3.fromRGB(118 + bladeIndex * 5, 146 + bladeIndex * 3, 62)
			blade.Size = Vector3.new(0.09, 0.8 + (index + bladeIndex) % 3 * 0.2, 0.09)
			local height = blade.Size.Y
			blade.CFrame = CFrame.new(
				x + offset[1],
				bottomY + height / 2 - 0.05,
				z + offset[2],
				-- small deterministic lean; the footprint stays inside 1.5 studs
				math.cos(index + bladeIndex) * 0.12,
				0,
				-math.sin(index + bladeIndex) * 0.12,
				0,
				1,
				0,
				math.sin(index + bladeIndex) * 0.12,
				0,
				math.cos(index + bladeIndex) * 0.12
			)
			blade.Parent = part
		end)
	end
end

local PLANT_BLADE_OFFSETS = {
	{ -0.16, 0.12 },
	{ 0.16, -0.12 },
	{ 0, 0.2 },
}

local function flowerColour(rgb: any?): any
	if type(rgb) == "table" and #rgb == 3 then
		return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
	end
	return Color3.fromRGB(246, 240, 214)
end

-- Item 177: a 1..2-stud stem plus 3 thin blades; flowers get 3 coloured petals at the tip. The
-- tagged part is the stem itself, so a ray aimed at the plant centre hits its own part.
local function addTallPlant(part: any?, piece: any, roadY: number, index: number)
	if not part then
		return
	end
	local height = piece.height
	pcall(function()
		part:SetAttribute("PathEdgePlant", true)
		part:SetAttribute("PlantHeight", height)
		part:SetAttribute("Along", piece.along)
		if piece.kind == "flower" then
			part:SetAttribute("FlowerColour", piece.flowerColour)
		end
		part.Material = Enum.Material.Grass
		part.Color = Color3.fromRGB(104, 136, 58)
	end)
	if not place(part, { piece.x, roadY + height / 2, piece.z }, { 0.3, height, 0.3 }) then
		fail("could not place tall plant " .. index)
		return
	end
	for bladeIndex, offset in ipairs(PLANT_BLADE_OFFSETS) do
		local blade: any? = nil
		local ok, created = pcall(function()
			return Instance.new("Part")
		end)
		if ok and created then
			blade = created
		end
		if not blade then
			continue
		end
		pcall(function()
			local bladeHeight = height * (0.72 + bladeIndex * 0.08)
			blade.Name = "TallBlade_" .. index .. "_" .. bladeIndex
			blade.Anchored = true
			blade.CanCollide = false
			blade.Material = Enum.Material.Grass
			blade.Color = Color3.fromRGB(112 + bladeIndex * 4, 142 + bladeIndex * 3, 62)
			blade.Size = Vector3.new(0.12, bladeHeight, 0.12)
			blade.CFrame = CFrame.new(
				piece.x + offset[1],
				roadY + bladeHeight / 2,
				piece.z + offset[2],
				math.cos(index + bladeIndex) * 0.1,
				0,
				-math.sin(index + bladeIndex) * 0.1,
				0,
				1,
				0,
				math.sin(index + bladeIndex) * 0.1,
				0,
				math.cos(index + bladeIndex) * 0.1
			)
			blade.Parent = part
		end)
	end
	if piece.kind ~= "flower" then
		return
	end
	local petals = flowerColour(piece.flowerRgb)
	for petalIndex = 1, 3 do
		local petal: any? = nil
		local ok, created = pcall(function()
			return Instance.new("Part")
		end)
		if ok and created then
			petal = created
		end
		if not petal then
			continue
		end
		pcall(function()
			local angle = (petalIndex - 1) * math.pi * 2 / 3
			petal.Name = "FlowerPetal_" .. index .. "_" .. petalIndex
			petal.Anchored = true
			petal.CanCollide = false
			petal.Material = Enum.Material.SmoothPlastic
			petal.Color = petals
			petal.Size = Vector3.new(0.26, 0.14, 0.26)
			petal.CFrame =
				CFrame.new(piece.x + math.cos(angle) * 0.16, roadY + height + 0.02, piece.z + math.sin(angle) * 0.16)
			petal.Parent = part
		end)
	end
end

-- ponytail: Rendah halves the decorative edge pieces (cap <=50%); the >=120 target still holds at
-- the default tier, where every piece is staged. Item-177 plants are structural for EDGE_VISIBLE
-- and are never thinned.
local function apply(plan)
	local tier = plan and plan.tier
	failures = 0
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
			folder:SetAttribute("LookDevPathEdgeR8", FAMILY_ID)
			folder.Parent = Workspace
		end)
	end
	if not folder then
		fail("could not create staging folder")
		publishFailures()
		return
	end
	activeFolder = folder

	if not MapSpec then
		fail("missing MapSpec road geometry")
		publishFailures()
		return
	end

	local arms = MapSpec.roadArms()
	local ring = MapSpec.ringSegments()
	local continuations = MapSpec.roadContinuations()
	local pieces = Data.allPieces(arms, ring, continuations, MapSpec.ROAD)
	if #pieces < Data.MIN_EDGE_PIECES then
		fail("only " .. #pieces .. " edge pieces")
	end

	local roadY = MapSpec.ROAD.y
	local pathFolders: { [string]: any } = {}
	local grassModels = taggedFolder("GrassModels_pathedge_r8", folder)
	for index, piece in ipairs(pieces) do
		if not TierThin.shouldKeep(tier, index) then
			continue
		end
		local pathFolder = pathFolders[piece.path]
		if not pathFolder then
			pathFolder = taggedFolder(piece.path, folder)
			pathFolders[piece.path] = pathFolder
		end
		local part = taggedPart(piece, piece.kind .. "_" .. piece.path .. "_" .. index, pathFolder or folder)
		if part then
			pcall(function()
				if piece.kind == "puddle" then
					part.Material = Enum.Material.SmoothPlastic
					part.Transparency = Data.PUDDLE_TRANSPARENCY
					part.Color = Color3.fromRGB(72, 112, 138)
				elseif piece.kind == "pebble" then
					part.Material = Enum.Material.Rock
					part.Color = Color3.fromRGB(136, 132, 122)
				else
					part.Material = Enum.Material.Grass
					part.Color = Color3.fromRGB(106, 138, 62)
				end
			end)
		end
		local centre, size
		if piece.kind == "puddle" then
			centre = { piece.x, roadY + 0.06, piece.z }
			size = { 2, 0.05, 1.2 }
		elseif piece.kind == "pebble" then
			centre = { piece.x, roadY + 0.15, piece.z }
			size = { 0.4, 0.3, 0.4 }
		else
			centre = { piece.x, roadY + 0.04, piece.z }
			size = { 0.6, 0.08, 0.6 }
		end
		if not place(part, centre, size) then
			fail("could not place edge piece " .. index)
		end

		if piece.kind == "grass_tuft" then
			local okLoad, model = pcall(function()
				return LookDevAssetLoader.get(GRASS_ASSET_ID, FAMILY_ID)
			end)
			local staged = false
			if okLoad and model then
				pcall(function()
					model.Name = "GrassClump_" .. index
					model:SetAttribute("LookDevPathEdgeR8", FAMILY_ID)
					model:SetAttribute("Kind", "grass_clump_model")
					model.Parent = grassModels or folder
				end)
				staged = placeClumpModel(model, piece.x, roadY + 0.04, piece.z, Data.CLUMP_MAX_WIDTH)
			end
			if staged then
				pcall(function()
					part:SetAttribute("GrassSource", "baked")
				end)
			else
				pcall(function()
					part:SetAttribute("GrassSource", "procedural")
				end)
				addBladeFallback(part, piece.x, piece.z, roadY + 0.04, index)
				fail("baked grass clump unavailable for piece " .. index .. "; used thin-blade fallback")
			end
		end
	end

	-- Item 177: one plant every PLANT_SPACING studs on each side of every road edge.
	local plantFolder = taggedFolder("TallPlants_pathedge_r8", folder)
	for index, piece in ipairs(Data.plantPieces(arms, ring, continuations, MapSpec.ROAD)) do
		local part = taggedPart(piece, "EdgePlant_" .. piece.kind .. "_" .. index, plantFolder or folder)
		addTallPlant(part, piece, roadY, index)
	end

	publishFailures()
end

local function restore()
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

LookDevPathEdgeR8.apply = apply
LookDevPathEdgeR8.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevPathEdgeR8
