--!strict
-- LookDevPlazaR9: SERVER-ONLY applier for the OFF-BY-DEFAULT "plaza_r9" candidate
-- (WORK_QUEUE section O item 149, rebuilt by section P item 175). Builds the central Lapangan
-- dressing from original Parts under one folder: a two-tier fountain with water discs and a thin
-- water column, a paved ring, four inward-facing benches, four striped umbrellas, a bunting line
-- with flat red-over-white flag pairs and one procedural shade tree at the plaza edge.
--
-- Every recipe comes from Shared.ModelMapPlazaR9 and every position is resolved from
-- MapSpec.PLAZA centre plus a plaza-local offset; no world-coordinate literals and no asset IDs.
-- The plaza is already Ground terrain, so no voxel pads are painted and no grass check is graded.
-- All parts are anchored and non-collidable, tagged per kind, and destroyed on restore together
-- with the staging folder; the exact prior folder (if any) is re-parented. Game APIs are pcall
-- guarded and any failure pads the published LookDevFailures counter. Enable from the Server
-- command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("plaza_r9", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevPlazaR9] missing service " .. name)
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
		warn("[LookDevPlazaR9] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, Data, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapPlazaR9),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not LookDevFailures then
	warn("[LookDevPlazaR9] could not require LookDev / ModelMapPlazaR9 / LookDevFailures")
	return {}
end

local okSpec, loadedSpec = pcall(function()
	return require(script.Parent.MapSpec)
end)
if not okSpec or not loadedSpec then
	warn("[LookDevPlazaR9] could not require MapSpec")
end
local MapSpec: any? = if okSpec then loadedSpec else nil

local LookDevPlazaR9 = {}

local failures = 0
local activeFolder: any? = nil
local savedFolder: any? = nil
local staged: { any } = {}

local SHAPE_NAMES = { Block = "Block", Cylinder = "Cylinder", Ball = "Ball" }

local function fail(message: string)
	failures += 1
	warn("[LookDevPlazaR9] " .. message)
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

-- Resolve a plaza-local offset into a world position from MapSpec.PLAZA (never a world literal).
local function plazaPoint(localX: number, localZ: number): (number?, number?)
	if not MapSpec or type(MapSpec.PLAZA) ~= "table" then
		fail("missing MapSpec.PLAZA")
		return nil, nil
	end
	return MapSpec.PLAZA.x + localX, MapSpec.PLAZA.z + localZ
end

local function groundY(): number
	return if MapSpec and type(MapSpec.GROUND_Y) == "number" then MapSpec.GROUND_Y else 0.5
end

-- One anchored, non-collidable original Part. Colour is a plain {r,g,b} array from the pure map.
local function addPart(
	parent: any,
	name: string,
	size: { number },
	cframe: any,
	colourKey: string,
	materialKey: string,
	label: string,
	shapeKey: string?
): any?
	local ok, created = pcall(function()
		local part = Instance.new("Part")
		part.Name = name
		local shapeName = shapeKey or SHAPE_NAMES.Block
		local shape = (Enum :: any).PartType[shapeName]
		part.Shape = shape
		part.Size = Vector3.new(size[1], size[2], size[3])
		part.CFrame = cframe
		local colour = Data.COLOURS[colourKey] or Data.COLOURS.stone
		part.Color = Color3.fromRGB(colour[1], colour[2], colour[3])
		part.Material = (Enum :: any).Material[Data.MATERIALS[materialKey] or "SmoothPlastic"]
			or Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		part:SetAttribute(Data.stageAttribute, Data.familyId)
		part.Parent = parent
		return part
	end)
	if not ok or not created then
		fail("could not stage part " .. name .. " for " .. label)
		return nil
	end
	track(created)
	return created
end

local function newModel(name: string, attribute: string, value: any, folder: any, label: string): any?
	local ok, model = pcall(function()
		return Instance.new("Model")
	end)
	if not ok or not model then
		fail("could not create model for " .. label)
		return nil
	end
	track(model)
	local okSet = pcall(function()
		model.Name = name
		model:SetAttribute(attribute, value)
		model:SetAttribute(Data.stageAttribute, Data.familyId)
		model.Parent = folder
	end)
	if not okSet then
		fail("could not configure model for " .. label)
		return nil
	end
	return model
end

local function stageFountain(folder: any): boolean
	local recipe = Data.FOUNTAIN
	local x, z = plazaPoint(recipe.x, recipe.z)
	if x == nil or z == nil then
		return false
	end
	local model = newModel("PlazaFountain", Data.fountainAttribute, Data.familyId, folder, "fountain")
	if not model then
		return false
	end
	local base = CFrame.new(x, groundY(), z)
	for _, tier in ipairs(Data.fountainTiers()) do
		local basin = addPart(
			model,
			tier.name,
			tier.size,
			base * CFrame.new(0, tier.y, 0),
			"stone",
			"stone",
			"fountain",
			SHAPE_NAMES.Cylinder
		)
		if basin then
			pcall(function()
				basin:SetAttribute(Data.fountainTierAttribute, tier.index)
			end)
		end
		local disc = addPart(
			model,
			"FountainWater_" .. tier.index,
			tier.waterSize,
			base * CFrame.new(0, tier.waterY, 0),
			recipe.waterColour,
			"water",
			"fountain",
			SHAPE_NAMES.Cylinder
		)
		if disc then
			pcall(function()
				disc:SetAttribute(Data.waterAttribute, true)
				disc:SetAttribute(Data.waterColourAttribute, recipe.waterColour)
			end)
		end
	end
	local spout = addPart(
		model,
		"FountainSpout",
		recipe.spoutSize,
		base * CFrame.new(0, recipe.spoutY, 0),
		recipe.waterColour,
		recipe.spoutMaterial,
		"fountain",
		SHAPE_NAMES.Cylinder
	)
	if spout then
		pcall(function()
			spout:SetAttribute(Data.waterAttribute, true)
			spout:SetAttribute(Data.waterColourAttribute, recipe.waterColour)
		end)
	end
	return true
end

local function stagePaving(folder: any): boolean
	local x, z = plazaPoint(0, 0)
	if x == nil or z == nil then
		return false
	end
	for _, tile in ipairs(Data.paving()) do
		local part = addPart(
			folder,
			"PlazaPaving_" .. tile.name,
			tile.size,
			CFrame.new(x + tile.x, groundY() + Data.PAVING.y, z + tile.z),
			"stoneDark",
			"stone",
			"paving"
		)
		if part then
			pcall(function()
				part:SetAttribute(Data.pavingAttribute, true)
			end)
		end
	end
	return true
end

local function stageBench(recipe: any, folder: any): boolean
	local x, z = plazaPoint(recipe.x, recipe.z)
	if x == nil or z == nil then
		return false
	end
	local label = "bench/" .. recipe.name
	local model = newModel("PlazaBench_" .. recipe.name, Data.benchAttribute, true, folder, label)
	if not model then
		return false
	end
	local base = CFrame.new(x, groundY(), z) * CFrame.Angles(0, math.rad(recipe.yaw), 0)
	local bench = Data.BENCH
	addPart(model, "BenchSeat", bench.seatSize, base * CFrame.new(0, bench.seatY, 0), "wood", "wood", label)
	addPart(
		model,
		"BenchBack",
		bench.backSize,
		base * CFrame.new(0, bench.backY, bench.backZOffset),
		"wood",
		"wood",
		label
	)
	for _, lx in ipairs(bench.legXOffsets) do
		for _, lz in ipairs(bench.legZOffsets) do
			addPart(model, "BenchLeg", bench.legSize, base * CFrame.new(lx, bench.legY, lz), "wood", "wood", label)
		end
	end
	return true
end

local function stageUmbrella(recipe: any, folder: any): boolean
	local x, z = plazaPoint(recipe.x, recipe.z)
	if x == nil or z == nil then
		return false
	end
	local label = "umbrella/" .. recipe.name
	local model = newModel("PlazaUmbrella_" .. recipe.name, Data.umbrellaAttribute, true, folder, label)
	if not model then
		return false
	end
	local base = CFrame.new(x, groundY(), z) * CFrame.Angles(0, math.rad(recipe.yaw), 0)
	local umbrella = Data.UMBRELLA
	addPart(model, "UmbrellaPole", umbrella.poleSize, base * CFrame.new(0, umbrella.poleY, 0), "wood", "wood", label)
	for index = 1, recipe.stripeCount do
		local colour = Data.stripeColour(index)
		local angle = math.rad((index - 1) * (360 / recipe.stripeCount))
		local stripe = addPart(
			model,
			string.format("UmbrellaStripe_%02d", index),
			umbrella.stripeSize,
			base
				* CFrame.new(
					math.cos(angle) * umbrella.stripeOffset,
					umbrella.canopyY,
					math.sin(angle) * umbrella.stripeOffset
				)
				* CFrame.Angles(0, -angle, 0),
			colour,
			"fabric",
			label
		)
		if stripe then
			pcall(function()
				stripe:SetAttribute(Data.stripeAttribute, true)
				stripe:SetAttribute(Data.stripeColourAttribute, colour)
			end)
		end
	end
	return true
end

local function stageBunting(folder: any): boolean
	local bunting = Data.BUNTING
	local a, b = bunting.poles[1], bunting.poles[2]
	local ax, az = plazaPoint(a.x, a.z)
	local bx, bz = plazaPoint(b.x, b.z)
	if ax == nil or az == nil or bx == nil or bz == nil then
		return false
	end
	local model = newModel("PlazaBunting", Data.buntingAttribute, true, folder, "bunting")
	if not model then
		return false
	end
	for index, pole in ipairs({ a, b }) do
		local px, pz = plazaPoint(pole.x, pole.z)
		if px == nil or pz == nil then
			return false
		end
		local part = addPart(
			model,
			string.format("BuntingPole_%02d", index),
			bunting.poleSize,
			CFrame.new(px, groundY() + bunting.poleY, pz),
			"wood",
			"wood",
			"bunting"
		)
		if part then
			pcall(function()
				part:SetAttribute(Data.buntingPoleAttribute, true)
			end)
		end
	end
	local midX, midZ = (ax + bx) / 2, (az + bz) / 2
	local span = math.sqrt((bx - ax) ^ 2 + (bz - az) ^ 2)
	local line = addPart(
		model,
		"BuntingLine",
		{ span, bunting.lineSize[1], bunting.lineSize[2] },
		CFrame.new(midX, groundY() + bunting.lineY, midZ) * CFrame.Angles(0, -math.atan2(bz - az, bx - ax), 0),
		"rope",
		"rope",
		"bunting"
	)
	if line then
		pcall(function()
			line:SetAttribute(Data.buntingLineAttribute, true)
		end)
	end
	local panelSize = Data.flagPanelSize()
	for _, flag in ipairs(Data.bunting().flags) do
		local fx, fz = plazaPoint(flag.x, flag.z)
		if fx == nil or fz == nil then
			return false
		end
		for _, panel in ipairs(Data.flagPanels(flag)) do
			local part = addPart(
				model,
				panel.name,
				panelSize,
				CFrame.new(fx, groundY() + bunting.flagY + panel.yOffset, fz),
				panel.colour,
				"fabric",
				"bunting"
			)
			if part then
				pcall(function()
					part:SetAttribute(Data.buntingFlagAttribute, true)
					part:SetAttribute(Data.flagPairAttribute, flag.name)
					part:SetAttribute(Data.flagPanelAttribute, panel.colour)
				end)
			end
		end
	end
	return true
end

local function stageShadeTree(folder: any): boolean
	local tree = Data.shadeTree()
	local x, z = plazaPoint(tree.x, tree.z)
	if x == nil or z == nil then
		return false
	end
	local model = newModel("PlazaShadeTree", Data.treeAttribute, true, folder, "shade tree")
	if not model then
		return false
	end
	pcall(function()
		model:SetAttribute(Data.treeHeightAttribute, tree.height)
	end)
	local recipe = Data.SHADE_TREE
	addPart(
		model,
		"TreeTrunk",
		recipe.trunkSize,
		CFrame.new(x, groundY() + recipe.trunkY, z),
		"trunk",
		"trunk",
		"shade tree"
	)
	for index, blob in ipairs(recipe.canopyBlobs) do
		local ok, canopy = pcall(function()
			local part = Instance.new("Part")
			part.Name = string.format("TreeCanopy_%02d", index)
			part.Shape = (Enum :: any).PartType[SHAPE_NAMES.Ball]
			part.Size = Vector3.new(blob[4], blob[4], blob[4])
			part.CFrame = CFrame.new(x + blob[1], groundY() + blob[2], z + blob[3])
			part.Color = Color3.fromRGB(Data.COLOURS.leaf[1], Data.COLOURS.leaf[2], Data.COLOURS.leaf[3])
			part.Material = (Enum :: any).Material.Leaf
			part.Anchored = true
			part.CanCollide = false
			part:SetAttribute(Data.stageAttribute, Data.familyId)
			part.Parent = model
			return part
		end)
		if not ok or not canopy then
			fail("could not stage canopy " .. tostring(index) .. " for shade tree")
		else
			track(canopy)
		end
	end
	return true
end

local applier = {
	apply = function()
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
		pcall(function()
			folder:SetAttribute(Data.stageAttribute, Data.familyId)
		end)
		stageFountain(folder)
		stagePaving(folder)
		for _, bench in ipairs(Data.benches()) do
			stageBench(bench, folder)
		end
		for _, umbrella in ipairs(Data.umbrellas()) do
			stageUmbrella(umbrella, folder)
		end
		stageBunting(folder)
		stageShadeTree(folder)
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

LookDevPlazaR9.apply = applier.apply
LookDevPlazaR9.restore = applier.restore

LookDev.register(Data.familyId, applier)

return LookDevPlazaR9
