--!strict
-- LookDevSawahR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "sawah_r8" candidate
-- (WORK_QUEUE section M item 72, rebuilt in section O item 140). Terrace dressing: one muddy water
-- sheet per terrace, dense padi rows of small clumps (3-5 thin blades each), a grassy bund, one
-- small field hut on terrace 2 and stepping stones between terraces.
--
-- PROCEDURAL PARTS, NO ASSET IDS. Terrain, greybox, padi rows and terrace tops are never touched:
-- every piece is a plain Part built from Shared.ModelMapSawahR8 and MapSpec.paddyWater(). All Parts
-- are anchored, non-collidable, tagged, and removed by restore() (which reattaches any prior
-- folder). Padi clumps are Models carrying PadiPart / TerraceIndex / PadiClump / PadiRow; every
-- blade and every bund tuft is also a PadiPart. Enable from the Studio Server command bar:
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

local okModules, LookDev, Data = pcall(function()
	return require((Shared :: any).LookDev), require((Shared :: any).ModelMapSawahR8)
end)
if not okModules or not LookDev or not Data then
	warn("[LookDevSawahR8] could not require LookDev / ModelMapSawahR8")
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
local failures = 0

-- Procedural parts, no asset IDs: a clean apply publishes 0. The counter only moves if staging
-- itself fails, and is published on every exit path for the Studio reads.
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

local function apply()
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

	-- Padi rows: one clump column every ROW_SPACING studs along each water pane, clumps spaced the
	-- same distance across the pane. Each clump is a Model holding 3-5 thin blades (clump width
	-- <= 1.5 studs, blade <= 2.5 studs); the 0.5-stud gap keeps the water sheet visible.
	local clumpFolders = {}
	for _, terrace in Data.terraceIndices() do
		local terraceFolder = folder:FindFirstChild("Terrace_" .. terrace .. "_sawah_r8")
		clumpFolders[terrace] = taggedFolder("Padi_" .. terrace, terrace, terraceFolder or folder)
	end
	local clumps = Data.padiClumps(panes)
	for _, clump in clumps do
		local clumpModel = taggedClump(clump, clumpFolders[clump.terrace] or folder)
		for bladeIndex = 1, math.min(clump.blades, #Data.PADI_BLADES) do
			local blade = Data.PADI_BLADES[bladeIndex]
			local part = taggedPart(
				"padi_blade",
				`Padi_{clump.terrace}_{clump.side}_{clump.id}_{bladeIndex}`,
				clump.terrace,
				clumpModel or folder
			)
			local centre = { clump.x + blade.dx, clump.y + blade.dy + blade.height / 2, clump.z + blade.dz }
			if not place(part, centre, { Data.PADI_BLADE_WIDTH, blade.height, Data.PADI_BLADE_WIDTH }) then
				fail("could not place padi blade " .. clump.id .. "/" .. bladeIndex)
			end
			if part then
				pcall(function()
					local red, green = 96, 168
					if bladeIndex % 2 == 0 then
						red, green = 76, 142
					end
					part.Material = Enum.Material.Grass
					part.Color = Color3.fromRGB(red, green, 52)
					part:SetAttribute("PadiPart", true)
					part:SetAttribute("TerraceIndex", clump.terrace)
					part:SetAttribute("PadiClump", clump.id)
					part:SetAttribute("PadiRow", clump.row)
					part:SetAttribute("Blade", bladeIndex)
				end)
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
			local part = taggedPart(
				"verge",
				`Verge_{tuft.terrace}_{tuft.side}_{tuftIndex}_{blade}`,
				tuft.terrace,
				terraceFolder or folder
			)
			local height = Data.BLADE_HEIGHTS[blade]
			local centre = { tuft.x + offset[1], tuft.y + height / 2 + offset[2], tuft.z + offset[3] }
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

	for index, stone in ipairs(Data.steppingStones()) do
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

LookDevSawahR8.apply = apply
LookDevSawahR8.restore = restore

LookDev.register(FAMILY_ID, { apply = apply, restore = restore })

return LookDevSawahR8
