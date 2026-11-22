--!strict
-- LookDevRiverR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "river_r8" candidate
-- (WORK_QUEUE section M item 73, redone in section O item 141). River-bank PLANTS cloned from
-- verified baked assets, twelve half-buried procedural boulder stand-ins, a second pair of bridge
-- rails/posts keeping the central 8 studs of the deck clear, and six stepping stones on the banks.
--
-- NO INVENTED ASSET IDS. Every plant resolves to an ID already recorded in Shared.ModelMapVegetationR4
-- / Shared.ModelMapVegetationR6 and is fetched clone-first via LookDevAssetLoader (bake -> LoadAsset
-- fallback inside the loader). talas/keladi use the documented R4 shrub stand-in; alang-alang uses
-- R6's real ID; bambu and kelapa use their real R4 IDs. No verified rock MODEL id exists in any
-- shared ModelMap* module, so the two boulder shapes (Ball, squashed Wedge) are procedural
-- stand-ins, not invented assets. Terrain, greybox, the existing BridgeDeck/BridgePost/BridgeRail,
-- padi rows and the ford are never touched: every piece is staged, anchored, non-collidable, tagged,
-- and removed by restore() (which reattaches any prior folder).
-- Enable from the Studio Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("river_r8", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevRiverR8] missing service " .. name)
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
	warn("[LookDevRiverR8] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, LookDevAssetLoader, VegR4, VegR6, TierThin = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapRiverR8),
		require(script.Parent.LookDevAssetLoader),
		require((Shared :: any).ModelMapVegetationR4),
		require((Shared :: any).ModelMapVegetationR6),
		require((Shared :: any).TierThin)
end)
if not okModules or not LookDev or not Data or not LookDevAssetLoader or not VegR4 or not VegR6 or not TierThin then
	warn(
		"[LookDevRiverR8] could not require LookDev / ModelMapRiverR8 / LookDevAssetLoader / vegetation maps / TierThin"
	)
	return {}
end

local MapSpec: any? = nil
local okSpec, specValue = pcall(function()
	return require(script.Parent.MapSpec)
end)
if okSpec and specValue and type(specValue.riverCentreZ) == "function" then
	MapSpec = specValue
else
	warn("[LookDevRiverR8] could not require MapSpec")
end

local LookDevRiverR8 = {}

local FAMILY_ID = Data.id
local activeFolder: any? = nil
local savedFolder: any? = nil
local failures = 0
local groundY = 0.5
if MapSpec and type(MapSpec.GROUND_Y) == "number" then
	groundY = MapSpec.GROUND_Y
end

-- All IDs come from the verified shared maps; none is written here as a literal.
local R4_IDS = VegR4.families.vegetation_r4.ids
local PLANT_ASSETS = {
	talas = R4_IDS.shrubs, -- R4 shrub as the wet-edge taro stand-in (R7 documented mapping)
	keladi = R4_IDS.shrubs, -- same documented stand-in
	["alang-alang"] = VegR6.ids.alang_alang,
	bambu = R4_IDS.bambu,
	kelapa = R4_IDS.kelapa,
}

-- Procedural parts only publish 0; a failed baked-plant load or placement moves the counter.
local function publishFailures()
	pcall(function()
		require(game.ReplicatedStorage.Shared.LookDevFailures).set(FAMILY_ID, failures)
	end)
end

local function fail(message: string)
	failures += 1
	warn("[LookDevRiverR8] " .. message)
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
		folder:SetAttribute("LookDevRiverR8", FAMILY_ID)
		folder.Parent = parent
	end)
	return folder
end

local function taggedPart(kind: string, name: string, parent: any): any?
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
		part:SetAttribute("LookDevRiverR8", FAMILY_ID)
		part:SetAttribute("Kind", kind)
		part.Parent = parent
	end)
	return part
end

local function place(part: any?, centre: { number }, size: { number }, yaw: number?): boolean
	if not part then
		return false
	end
	local ok = pcall(function()
		part.Size = Vector3.new(size[1], size[2], size[3])
		part.CFrame = CFrame.new(centre[1], centre[2], centre[3])
			* (yaw and yaw ~= 0 and CFrame.Angles(0, yaw, 0) or CFrame.new())
	end)
	return ok
end

-- A baked asset may be a Model OR a single BasePart/MeshPart. GetBoundingBox exists only on Model,
-- so both bounds and scaling branch (a Part uses its own CFrame + Size).
local function bounds(root: any): (CFrame?, Vector3?)
	local ok, centre, size = pcall(function()
		if root:IsA("Model") then
			return root:GetBoundingBox()
		end
		if root:IsA("BasePart") then
			return root.CFrame, root.Size
		end
		return nil, nil
	end)
	if ok then
		return centre, size
	end
	return nil, nil
end

-- Scale to the requested height and sit the model's bbox bottom on bottomY at (x, z). The pivot of
-- a baked asset can be far from its geometry, so carry the bbox-centre offset like the hub-veg
-- applier does. Returns false on any failed scale/pivot write.
local function placeModel(model: any, x: number, bottomY: number, z: number, targetHeight: number): boolean
	local _, boxSize = bounds(model)
	local bodyY = if boxSize and boxSize.Y > 0 then boxSize.Y else 1
	local factor = targetHeight / bodyY
	local scaled = false
	if model:IsA("Model") then
		scaled = pcall(function()
			model:ScaleTo(factor)
		end)
	elseif model:IsA("BasePart") then
		scaled = pcall(function()
			model.Size = model.Size * factor
		end)
	end
	if not scaled then
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
	local bboxCF, scaledSize = bounds(model)
	local okPivot, pivot = pcall(function()
		return model:GetPivot()
	end)
	if bboxCF and scaledSize and okPivot and pivot then
		local offset = bboxCF.Position - pivot.Position
		local centre = Vector3.new(x, bottomY + scaledSize.Y * 0.5, z)
		return pcall(function()
			model:PivotTo(CFrame.new(centre - offset))
		end)
	end
	if okPivot and pivot then
		local height = scaledSize and scaledSize.Y or targetHeight
		return pcall(function()
			model:PivotTo(CFrame.new(x, bottomY + height * 0.5, z))
		end)
	end
	return false
end

-- ponytail: Rendah thins decorative veg/rocks/stones to <=50% of instances; bridge rails/posts are
-- structural and never thinned. Default tiers keep every instance byte-for-byte.
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
			folder:SetAttribute("LookDevRiverR8", FAMILY_ID)
			folder.Parent = Workspace
		end)
	end
	if not folder then
		fail("could not create staging folder")
		publishFailures()
		return
	end
	activeFolder = folder

	local vegFolder = taggedFolder("BankVeg_river_r8", folder)
	local plantModelFolder = taggedFolder("BankPlantModels_river_r8", folder)
	local rockFolder = taggedFolder("BankRocks_river_r8", folder)
	local railFolder = taggedFolder("BridgeRails_river_r8", folder)
	local stoneFolder = taggedFolder("SteppingStones_river_r8", folder)

	-- Bank plants use the real centreline. The tagged base Parts carry BankPlant/PlantSpecies/
	-- PlantTall (and the legacy bank_veg attributes the harness reads); the baked model grows out
	-- of them. Item 174: their geometry comes from the pure-data Recipe — squashed Ball mounds for
	-- taro/shrubs, three fanned Wedge blades for reeds/bamboo. No Block hedge base is ever staged.
	local centreFn = MapSpec and MapSpec.riverCentreZ or Data.RIVER_CENTRE
	-- MIN_BANK_VEG is a data-integrity invariant of ModelMapRiverR8.bankPlants, not a render count:
	-- measure it on the full unthinned data so intentional Rendah thinning cannot publish a failure.
	local dataNearBridge = 0
	local placedVeg = 0
	for index, veg in ipairs(Data.bankPlants(centreFn)) do
		local dataDz = veg.z - Data.BRIDGE_CENTRE_Z
		if math.sqrt(veg.x * veg.x + dataDz * dataDz) <= 40 then
			dataNearBridge += 1
		end
		if not TierThin.shouldKeep(tier, index) then
			continue
		end
		if math.abs(veg.x) <= Data.BRIDGE_WIDTH / 2 + 1 then
			continue
		end
		local recipe = veg.Recipe
		if type(recipe) ~= "table" or type(recipe.size) ~= "table" or type(recipe.offsets) ~= "table" then
			fail("missing organic plant recipe " .. index)
			continue
		end
		local bladeCluster = recipe.Form == "blades"
		for partIndex, offset in ipairs(recipe.offsets) do
			local part = taggedPart(
				"bank_veg",
				"BankPlant_" .. index .. (bladeCluster and "_blade" .. partIndex or ""),
				vegFolder or folder
			)
			if part then
				pcall(function()
					part:SetAttribute("Side", veg.Side)
					part:SetAttribute("Species", veg.Species)
					part:SetAttribute("VegX", veg.VegX)
					part:SetAttribute("VegZ", veg.VegZ)
					part:SetAttribute("BankPlant", true)
					part:SetAttribute("PlantSpecies", veg.Species)
					part:SetAttribute("PlantTall", veg.Tall)
					part.Shape = Enum.Shape[recipe.Shape] -- Ball or Wedge; never the Block hedge
					part.Material = Enum.Material.Grass
					part.Color = if veg.Species == "alang-alang"
						then Color3.fromRGB(150, 142, 74)
						elseif veg.Species == "bambu" or veg.Species == "kelapa" then Color3.fromRGB(74, 132, 62)
						else Color3.fromRGB(92, 132, 58)
				end)
			end
			local yaw = if bladeCluster then (partIndex - 1) * (2 * math.pi / 3) else 0
			if
				not place(
					part,
					{ veg.x + offset[1], groundY + recipe.size[2] * 0.5 - 0.15, veg.z + offset[2] },
					recipe.size,
					yaw
				)
			then
				fail("could not place bank plant " .. index .. "/" .. partIndex)
			end
		end

		local assetId = PLANT_ASSETS[veg.Species]
		if type(assetId) == "number" then
			local okLoad, model = pcall(function()
				return LookDevAssetLoader.get(assetId, FAMILY_ID)
			end)
			if okLoad and model then
				pcall(function()
					model.Name = "BankPlantModel_" .. index
					model:SetAttribute("LookDevRiverR8", FAMILY_ID)
					model:SetAttribute("Kind", "bank_veg_model")
					model:SetAttribute("Species", veg.Species)
					model.Parent = plantModelFolder or folder
				end)
				if not placeModel(model, veg.x, groundY + recipe.size[2] - 0.15, veg.z, veg.Height) then
					fail("could not scale/place bank plant model " .. index)
				end
			end
		end
		placedVeg += 1
	end
	if dataNearBridge < Data.MIN_BANK_VEG then
		fail("only " .. dataNearBridge .. " bank plants near the bridge (" .. placedVeg .. " total)")
	end

	-- Twelve half-buried boulders: two procedural shapes (Ball, squashed Wedge) stand in for the
	-- two rock models because no verified rock MODEL id exists in the shared asset maps.
	for index, rock in ipairs(Data.bankRocks(centreFn)) do
		if not TierThin.shouldKeep(tier, index) then
			continue
		end
		local part = taggedPart("bank_rock", "BankRock_" .. index, rockFolder or folder)
		if part then
			pcall(function()
				part:SetAttribute("Side", rock.Side)
				part:SetAttribute("Shape", rock.Shape)
				part:SetAttribute("BankRock", true)
				-- Dynamic key: the two stand-in shapes are Ball and squashed Wedge.
				part.Shape = Enum.Shape[if rock.Shape == "ball" then "Ball" else "Wedge"]
				part.Material = Enum.Material.Rock
				part.Color = if rock.Shape == "ball"
					then Color3.fromRGB(126, 122, 108)
					else Color3.fromRGB(110, 106, 96)
			end)
		end
		if not place(part, { rock.x, groundY - rock.size[2] * 0.1, rock.z }, rock.size) then
			fail("could not place bank rock " .. index)
		end
	end

	-- A second rail on each side, inboard of the greybox rails. A 1-stud rail centred at x = +/-4.5
	-- puts the inner face at |x| = 4, leaving exactly 8 studs of walkable deck between the sides.
	-- Structural: rails and posts are never thinned at any tier.
	local bridge = MapSpec and MapSpec.BRIDGE or nil
	for _, rail in ipairs(Data.railLayout()) do
		local railPart = taggedPart("bridge_rail", "BridgeRail_" .. rail.Side .. "_river_r8", railFolder or folder)
		if railPart then
			pcall(function()
				railPart:SetAttribute("Side", rail.Side)
				railPart.Material = Enum.Material.Wood
			end)
		end
		if
			not place(railPart, { rail.x, bridge and bridge.railTop or 3.2, (rail.z0 + rail.z1) / 2 }, {
				rail.thickness,
				0.3,
				rail.z1 - rail.z0,
			})
		then
			fail("could not place bridge rail " .. rail.Side)
		end
		for postIndex, z in ipairs(rail.postZs) do
			local post = taggedPart(
				"bridge_post",
				"BridgePost_" .. rail.Side .. "_" .. postIndex .. "_river_r8",
				railFolder or folder
			)
			if post then
				pcall(function()
					post:SetAttribute("Side", rail.Side)
					post.Material = Enum.Material.Wood
				end)
			end
			local top = bridge and bridge.top or 1.5
			local railTop = bridge and bridge.railTop or 3.2
			if not place(post, { rail.x, (top + railTop) / 2, z }, { 0.6, railTop - top, 0.6 }) then
				fail("could not place bridge post " .. rail.Side .. "/" .. postIndex)
			end
		end
	end

	-- Six flat stones, three per bank, clear of the deck and the channel interior.
	for index, stone in ipairs(Data.steppingStones()) do
		if not TierThin.shouldKeep(tier, index) then
			continue
		end
		local part = taggedPart("stepping_stone", "SteppingStone_" .. index .. "_river_r8", stoneFolder or folder)
		if part then
			pcall(function()
				part:SetAttribute("Side", stone.Side)
				part.Material = Enum.Material.Rock
				part.Color = Color3.fromRGB(126, 122, 108)
			end)
		end
		if not place(part, { stone.x, stone.y, stone.z }, stone.size) then
			fail("could not place stepping stone " .. index)
		end
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

LookDevRiverR8.apply = apply
LookDevRiverR8.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevRiverR8
