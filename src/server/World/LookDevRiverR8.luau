--!strict
-- LookDevRiverR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "river_r8" candidate
-- (WORK_QUEUE section M item 73). River-bank vegetation, a second pair of bridge rails/posts that
-- keeps the central 8 studs of the deck clear, and six stepping stones on the banks.
--
-- PROCEDURAL PARTS, NO ASSET IDS. Terrain, greybox, the existing BridgeDeck/BridgePost/BridgeRail,
-- padi rows and the ford are never touched: every piece is a plain Part built from pure data in
-- Shared.ModelMapRiverR8, using the real MapSpec.riverCentreZ for the bank positions. All Parts are
-- anchored, non-collidable, tagged, and removed by restore() (which reattaches any prior folder).
-- Enable from the Studio Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("river_r8", game)

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

local okModules, LookDev, Data = pcall(function()
	return require((Shared :: any).LookDev), require((Shared :: any).ModelMapRiverR8)
end)
if not okModules or not LookDev or not Data then
	warn("[LookDevRiverR8] could not require LookDev / ModelMapRiverR8")
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

-- Procedural parts only: a clean apply publishes 0. The counter moves only when staging fails.
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
	local railFolder = taggedFolder("BridgeRails_river_r8", folder)
	local stoneFolder = taggedFolder("SteppingStones_river_r8", folder)

	-- Bank vegetation follows the real centreline. Positions under the 10-wide deck are skipped so
	-- nothing is staged on the bridge itself.
	local nearBridge = 0
	local placedVeg = 0
	if MapSpec then
		for index, veg in ipairs(Data.bankVeg(MapSpec.riverCentreZ, -48, 48, 2)) do
			if math.abs(veg.x) <= Data.BRIDGE_WIDTH / 2 + 1 then
				continue
			end
			local part = taggedPart("bank_veg", "BankVeg_" .. index, vegFolder or folder)
			if part then
				pcall(function()
					part:SetAttribute("Side", veg.Side)
					part:SetAttribute("Species", veg.Species)
					part:SetAttribute("VegX", veg.VegX)
					part:SetAttribute("VegZ", veg.VegZ)
					part.Material = Enum.Material.Grass
					part.Color = if veg.Species == "alang-alang"
						then Color3.fromRGB(150, 142, 74)
						elseif veg.Species == "bambu" then Color3.fromRGB(74, 132, 62)
						else Color3.fromRGB(92, 132, 58)
				end)
			end
			if not place(part, { veg.x, 0.8, veg.z }, { 0.18, 1.6, 0.18 }) then
				fail("could not place bank veg " .. index)
			end
			placedVeg += 1
			local dz = veg.z - Data.BRIDGE_CENTRE_Z
			if math.sqrt(veg.x * veg.x + dz * dz) <= 40 then
				nearBridge += 1
			end
		end
	else
		fail("missing MapSpec river centreline")
	end
	if nearBridge < Data.MIN_BANK_VEG then
		fail("only " .. nearBridge .. " bank veg near the bridge (" .. placedVeg .. " total)")
	end

	-- A second rail on each side, inboard of the greybox rails. A 1-stud rail centred at x = +/-4.5
	-- puts the inner face at |x| = 4, leaving exactly 8 studs of walkable deck between the sides.
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
