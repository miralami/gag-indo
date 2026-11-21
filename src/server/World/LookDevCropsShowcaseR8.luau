--!strict
-- LookDevCropsShowcaseR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "crops_showcase_r8" candidate
-- (WORK_QUEUE section N item 118). Stages one folder under Workspace with three stage plots
-- (bibit, tumbuh, siap), each holding all 12 crops in a row. Every crop Model is built from the
-- shared CropModelCandidates.partsFor recipes using original Parts, plain RGB colours and built-in
-- material/shape tokens. Anchored, non-collidable, no asset IDs, no decals, no Terrain read or write
-- and NO DataStore/player/crop-state write: staged geometry only. The prior same-named folder is
-- detached and restored exactly on disable. Enable from the Studio Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("crops_showcase_r8", game, { studio = true })

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevCropsShowcaseR8] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Workspace = service("Workspace")
local ServerScriptService = service("ServerScriptService")

local Shared: any? = nil
if ReplicatedStorage then
	local ok, folder = pcall(function()
		return (ReplicatedStorage :: any):WaitForChild("Shared")
	end)
	if ok and folder then
		Shared = folder
	else
		warn("[LookDevCropsShowcaseR8] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, Data, Candidates, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapCropsShowcaseR8),
		require((Shared :: any).CropModelCandidates),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not Candidates or not LookDevFailures then
	warn(
		"[LookDevCropsShowcaseR8] could not require LookDev / ModelMapCropsShowcaseR8 / CropModelCandidates / LookDevFailures"
	)
	return {}
end

-- MapSpec lives under ServerScriptService.Server.World, so this is a SERVER-ONLY applier.
local MapSpec: any? = nil
if ServerScriptService then
	local okMap, map = pcall(function()
		local server = (ServerScriptService :: any):WaitForChild("Server")
		return require(server:WaitForChild("World"):WaitForChild("MapSpec"))
	end)
	if okMap and map then
		MapSpec = map
	end
end

local LookDevCropsShowcaseR8 = {}

local failures = 0
local activeFolder: any? = nil
local savedFolder: any? = nil
local plotList: { any } = {}
local cropList: { any } = {}
local partList: { any } = {}
local baseParts = 0
local applied = false

local function fail(message: string)
	failures += 1
	warn("[LookDevCropsShowcaseR8] " .. message)
end

local function publishFailures()
	pcall(function()
		LookDevFailures.set(Data.familyId, failures)
	end)
end

local function track(instance: any?)
	if instance then
		partList[#partList + 1] = instance
	end
end

local function clearActive()
	for index = #partList, 1, -1 do
		pcall(function()
			partList[index]:Destroy()
		end)
	end
	table.clear(partList)
	baseParts = 0
	local folder = activeFolder
	if folder then
		pcall(function()
			folder:Destroy()
		end)
	end
	activeFolder = nil
	plotList = {}
	cropList = {}
end

local function shapeOf(name: string): any?
	local ok, shape = pcall(function()
		return ((Enum :: any).PartType)[Data.SHAPES[name] or "Block"]
	end)
	return if ok then shape else nil
end

local function materialOf(token: string): any?
	local ok, material = pcall(function()
		return ((Enum :: any).Material)[Data.MATERIALS[token] or Data.MATERIALS.fallback]
	end)
	if ok and material then
		return material
	end
	local okFallback, fallback = pcall(function()
		return Enum.Material.SmoothPlastic
	end)
	return if okFallback then fallback else nil
end

local function colourOf(cropId: string, token: string): any?
	local rgb = if token == "crop" then Data.CROP_COLOURS[cropId] else Data.PALETTE[token]
	rgb = rgb or Data.PALETTE.tinta
	local ok, colour = pcall(function()
		return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
	end)
	return if ok then colour else nil
end

local function roleOf(name: string): string
	if string.sub(name, 1, 6) == "Accent" then
		return "accent"
	end
	if string.sub(name, 1, 4) == "Leaf" then
		return "leaf"
	end
	if string.sub(name, 1, 5) == "Fruit" then
		return "fruit"
	end
	return "stem"
end

local function tag(instance: any, kind: string)
	pcall(function()
		instance:SetAttribute(Data.stageAttribute, Data.familyId)
		instance:SetAttribute(Data.kindAttribute, kind)
	end)
end

local function newFolder(): any?
	local okNew, folder = pcall(function()
		return Instance.new("Folder")
	end)
	if not okNew or not folder then
		return nil
	end
	pcall(function()
		folder.Name = Data.folderName
		folder.Parent = Workspace
	end)
	tag(folder, "root")
	track(folder)
	return folder
end

local function addPlot(root: any, plot: any, lapangan: any, groundY: number): any?
	local plateMaterial = materialOf(Data.MATERIALS.plate)
	local okPlot, container = pcall(function()
		local model = Instance.new("Model")
		model.Name = "Plot_" .. plot.stage
		return model
	end)
	if not okPlot or not container then
		fail("could not create plot model for " .. tostring(plot.stage))
		return nil
	end

	local okPlate, plate = pcall(function()
		local part = Instance.new("Part")
		part.Name = "PlotPlate_" .. plot.stage
		local blockShape = shapeOf("Block")
		if blockShape then
			part.Shape = blockShape
		end
		part.Size = Vector3.new(Data.PLOT.plateSize[1], Data.PLOT.plateSize[2], Data.PLOT.plateSize[3])
		part.CFrame = CFrame.new(lapangan.x, groundY + Data.PLOT.plateSize[2] / 2, lapangan.z + plot.zOffset)
		part.Color = Color3.fromRGB(Data.PALETTE.bambu[1], Data.PALETTE.bambu[2], Data.PALETTE.bambu[3])
		if plateMaterial then
			part.Material = plateMaterial
		end
		part.Anchored = true
		part.CanCollide = false
		return part
	end)
	if not okPlate or not plate then
		fail("could not create plot plate for " .. tostring(plot.stage))
		pcall(function()
			container:Destroy()
		end)
		return nil
	end
	tag(plate, Data.PLATE_KIND)
	track(plate)
	baseParts += 1
	pcall(function()
		plate.Parent = container
	end)

	tag(container, Data.PLOT_KIND)
	pcall(function()
		container:SetAttribute("Stage", plot.stage)
		container.Parent = root
	end)
	track(container)
	plotList[#plotList + 1] = container
	return container
end

local function addCrop(container: any, cropId: string, stage: string, origin: any): any?
	local okModel, model = pcall(function()
		local m = Instance.new("Model")
		m.Name = Data.modelName(cropId, stage)
		return m
	end)
	if not okModel or not model then
		fail("could not create crop model " .. cropId .. "/" .. stage)
		return nil
	end
	tag(model, Data.CROP_KIND)
	pcall(function()
		model:SetAttribute("CropId", cropId)
		model:SetAttribute("Stage", stage)
	end)

	local recipes = Candidates.partsFor(cropId, stage)
	if type(recipes) ~= "table" then
		fail("missing part recipe for " .. cropId .. "/" .. stage)
		return nil
	end

	local built = 0
	for _, detail in ipairs(recipes) do
		local role = roleOf(detail.name)
		local colour = colourOf(cropId, detail.color)
		local shape = shapeOf(detail.shape)
		local material = materialOf(role)
		local okPart, part = pcall(function()
			local p = Instance.new("Part")
			p.Name = detail.name
			if shape then
				p.Shape = shape
			end
			p.Size = Vector3.new(detail.size[1], detail.size[2], detail.size[3])
			p.CFrame = CFrame.new(origin) * CFrame.new(detail.offset[1], detail.offset[2], detail.offset[3])
			if colour then
				p.Color = colour
			end
			if material then
				p.Material = material
			end
			p.Anchored = true
			p.CanCollide = false
			return p
		end)
		if okPart and part then
			tag(part, role)
			track(part)
			baseParts += 1
			pcall(function()
				part.Parent = model
			end)
			built += 1
		end
	end
	if built ~= #recipes then
		fail("built " .. built .. "/" .. #recipes .. " parts for " .. cropId .. "/" .. stage)
	end

	pcall(function()
		model.Parent = container
	end)
	track(model)
	cropList[#cropList + 1] = model
	return model
end

local function apply(_plan: any)
	if applied then
		return
	end
	clearActive()
	failures = 0
	pcall(function()
		LookDevFailures.reset(Data.familyId)
	end)
	if not Workspace or not MapSpec or type(MapSpec.LAPANGAN) ~= "table" then
		fail("missing Workspace or MapSpec.LAPANGAN")
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

	local folder = newFolder()
	if not folder then
		fail("could not create staging folder")
		publishFailures()
		return
	end
	activeFolder = folder

	local lapangan = MapSpec.LAPANGAN
	local groundY = MapSpec.GROUND_Y
	for _, plot in ipairs(Data.PLOTS) do
		local container = addPlot(folder, plot, lapangan, groundY)
		if container then
			local plotZ = lapangan.z + plot.zOffset
			local cropY = groundY + Data.PLOT.plateSize[2] + Data.PLOT.cropLift
			for index, cropId in ipairs(Data.CROPS) do
				local okOrigin, origin = pcall(function()
					return Vector3.new(lapangan.x + Data.cropX(index), cropY, plotZ)
				end)
				if okOrigin and origin then
					addCrop(container, cropId, plot.stage, origin)
				else
					fail("could not position " .. cropId .. "/" .. plot.stage)
				end
			end
		end
	end

	if #plotList ~= Data.COUNTS.plots or #cropList ~= Data.COUNTS.models then
		fail("staged " .. #plotList .. " plots / " .. #cropList .. " crop models")
	end
	applied = true
	publishFailures()
end

local function restore()
	if not applied then
		return
	end
	applied = false
	clearActive()
	local previous = savedFolder
	if previous then
		pcall(function()
			previous.Parent = Workspace
		end)
		savedFolder = nil
	end
	publishFailures()
end

-- Diagnostics ---------------------------------------------------------------------------------
function LookDevCropsShowcaseR8.plotModels(): { any }
	return plotList
end

function LookDevCropsShowcaseR8.cropModels(): { any }
	return cropList
end

function LookDevCropsShowcaseR8.isApplied(): boolean
	return applied
end

function LookDevCropsShowcaseR8.counts(): { [string]: number }
	return {
		plots = #plotList,
		crops = #cropList,
		models = #cropList,
		parts = baseParts,
	}
end

function LookDevCropsShowcaseR8.partCount(): number
	return baseParts
end

LookDevCropsShowcaseR8.apply = apply
LookDevCropsShowcaseR8.restore = restore

LookDev.register(Data.familyId, { apply = apply, restore = restore })

return LookDevCropsShowcaseR8
