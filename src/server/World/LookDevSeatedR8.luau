--!strict
-- LookDevSeatedR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "seated_r8" candidate
-- (WORK_QUEUE section N item 117). Stages one folder of four real R15 rigs from the verified
-- ModelMapNpcsR7 catalog outfits, four anchored Seat Parts on the Warung benches (two per bench,
-- above the 1.95-stud bench top), and four glasses / four plates on the Warung table. Each rig is
-- parented before seat:Sit(humanoid), then a single bounded 0.2 s re-assert keeps Sit set. Rig parts
-- stay UNANCHORED and collidable so the engine owns the seated pose. No asset IDs, no brand, no
-- decals, no Terrain read or write. Game APIs are pcall guarded; failures pad LookDevFailures.
-- Enable from the Studio Server command bar:
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("seated_r8", game, { studio = true })

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if not ok or not value then
		warn("[LookDevSeatedR8] missing service " .. name)
		return nil
	end
	return value
end

local ReplicatedStorage = service("ReplicatedStorage")
local Players = service("Players")
local Workspace = service("Workspace")

local Shared: any? = nil
if ReplicatedStorage then
	local ok, folder = pcall(function()
		return (ReplicatedStorage :: any):WaitForChild("Shared")
	end)
	if ok and folder then
		Shared = folder
	else
		warn("[LookDevSeatedR8] missing Shared folder")
	end
end
if not Shared then
	return {}
end

local okModules, LookDev, Data, NpcData, LookDevFailures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapSeatedR8),
		require((Shared :: any).ModelMapNpcsR7),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not NpcData or not LookDevFailures then
	warn("[LookDevSeatedR8] could not require LookDev / ModelMapSeatedR8 / ModelMapNpcsR7 / LookDevFailures")
	return {}
end

local LookDevSeatedR8 = {}

local failures = 0
local activeFolder: any? = nil
local savedFolder: any? = nil
local staged: { any } = {}
local seatsList: { any } = {}
local propsList: { any } = {}
local rigsList: { any } = {}
local applied = false

local function fail(message: string)
	failures += 1
	warn("[LookDevSeatedR8] " .. message)
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
	seatsList = {}
	propsList = {}
	rigsList = {}
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
		folder:SetAttribute(Data.stageAttribute, Data.familyId)
	end)
	return folder
end

-- Exact R7 HumanoidDescription recipe: only Shirt/Pants plus Hat/Shirt accessories, never a
-- BodyHeightScale or any other property this Studio does not support.
local function buildDescription(roleName: string): any?
	local role = (NpcData.roles :: any)[roleName]
	if type(role) ~= "table" or type(role.catalog) ~= "table" then
		fail("missing R7 catalog role " .. roleName)
		return nil
	end
	local ok, description = pcall(function()
		local hd = Instance.new("HumanoidDescription")
		local skin = Color3.fromRGB(role.skin.r, role.skin.g, role.skin.b)
		hd.HeadColor = skin
		hd.TorsoColor = skin
		hd.LeftArmColor = skin
		hd.RightArmColor = skin
		hd.LeftLegColor = skin
		hd.RightLegColor = Color3.fromRGB(role.skin.r, role.skin.g, role.skin.b)
		local catalog = role.catalog
		if catalog.shirt then
			hd.Shirt = catalog.shirt
		end
		if catalog.pants then
			hd.Pants = catalog.pants
		end
		local accessories = {}
		for _, hatId in ipairs(catalog.hats or {}) do
			table.insert(accessories, { AccessoryType = Enum.AccessoryType.Hat, AssetId = hatId, IsLayered = false })
		end
		if catalog.layeredShirt then
			table.insert(accessories, {
				AccessoryType = Enum.AccessoryType.Shirt,
				AssetId = catalog.layeredShirt,
				IsLayered = true,
				Order = 1,
			})
		end
		hd:SetAccessories(accessories, true)
		return hd
	end)
	if not ok or not description then
		fail("HumanoidDescription failed for " .. roleName .. ": " .. tostring(description))
		return nil
	end
	return description
end

-- Same sync/async fallback as LookDevModelsNpcsR7: this Studio supports the async call.
local function buildRig(roleName: string): any?
	local description = buildDescription(roleName)
	if not description then
		return nil
	end
	local okAsync, asyncRig = pcall(function()
		local create = (Players :: any).CreateHumanoidModelFromDescriptionAsync
		if type(create) ~= "function" then
			error("CreateHumanoidModelFromDescriptionAsync unavailable")
		end
		return create(Players, description, Enum.HumanoidRigType.R15)
	end)
	if okAsync and asyncRig then
		return asyncRig
	end
	local okSync, syncRig = pcall(function()
		local create = (Players :: any).CreateHumanoidModelFromDescription
		if type(create) ~= "function" then
			error("CreateHumanoidModelFromDescription unavailable")
		end
		return create(Players, description, Enum.HumanoidRigType.R15)
	end)
	if okSync and syncRig then
		return syncRig
	end
	fail("R15 rig unavailable for " .. roleName .. ": " .. tostring(syncRig))
	return nil
end

local function findHumanoid(rig: any): any?
	local ok, humanoid = pcall(function()
		return rig:FindFirstChildOfClass("Humanoid")
	end)
	if ok and humanoid then
		return humanoid
	end
	local okNamed, named = pcall(function()
		return rig:FindFirstChild("Humanoid")
	end)
	if okNamed and named then
		return named
	end
	return nil
end

local function addSeat(folder: any, site: any): any?
	local ok, seat = pcall(function()
		local part = Instance.new("Seat")
		part.Name = "Seated_Seat_" .. site.key
		part.Size = Vector3.new(Data.SEAT.size[1], Data.SEAT.size[2], Data.SEAT.size[3])
		part.CFrame = CFrame.new(site.x, site.y, site.z) * CFrame.Angles(0, math.rad(site.ry), 0)
		local colour = Data.COLOURS.seat
		part.Color = Color3.fromRGB(colour[1], colour[2], colour[3])
		part.Material = (Enum :: any).Material[Data.MATERIALS.seat] or Enum.Material.Wood
		part.Anchored = true
		part.CanCollide = true
		part:SetAttribute(Data.stageAttribute, Data.familyId)
		part:SetAttribute(Data.kindAttribute, Data.SEAT_KIND)
		part.Parent = folder
		return part
	end)
	if not ok or not seat then
		fail("could not stage seat " .. tostring(site.key) .. ": " .. tostring(seat))
		return nil
	end
	track(seat)
	return seat
end

local function addProp(folder: any, recipe: any): any?
	local ok, prop = pcall(function()
		local part = Instance.new("Part")
		part.Name = "Seated_" .. recipe.name
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(recipe.size[1], recipe.size[2], recipe.size[3])
		part.CFrame = CFrame.new(Data.WARUNG.x + recipe.lx, recipe.ly, Data.WARUNG.z + recipe.lz)
		local colour = Data.COLOURS[recipe.colour]
		part.Color = Color3.fromRGB(colour[1], colour[2], colour[3])
		part.Material = (Enum :: any).Material[Data.MATERIALS[recipe.material]] or Enum.Material.SmoothPlastic
		part.Transparency = Data.TRANSPARENCY[recipe.material] or 0
		part.Anchored = true
		part.CanCollide = true
		part:SetAttribute(Data.stageAttribute, Data.familyId)
		part:SetAttribute(Data.kindAttribute, recipe.kind)
		part.Parent = folder
		return part
	end)
	if not ok or not prop then
		fail("could not stage table prop " .. tostring(recipe.name) .. ": " .. tostring(prop))
		return nil
	end
	track(prop)
	return prop
end

-- Feet-on-seat placement before Sit: the seated pose itself is engine-owned. The HumanoidRootPart
-- and every other BasePart stay unanchored with CanCollide true, so the probe in SEATED_ON_BENCH
-- measures the real rig geometry.
local function placeRig(rig: any, site: any, roleName: string): boolean
	local okBox, boxCFrame, boxSize = pcall(function()
		return rig:GetBoundingBox()
	end)
	local okPivot, pivot = pcall(function()
		return rig:GetPivot()
	end)
	if not okBox or not boxCFrame or not boxSize or not okPivot or not pivot then
		fail("could not measure rig bounds for " .. roleName)
		return false
	end
	local bottomOffset = boxCFrame.Y - boxSize.Y * 0.5 - pivot.Y
	local okTarget, target = pcall(function()
		return CFrame.new(site.x, site.y - bottomOffset, site.z) * CFrame.Angles(0, math.rad(site.ry), 0)
	end)
	if not okTarget or not target then
		fail("could not build seat CFrame for " .. roleName)
		return false
	end
	if not pcall(function()
		rig:PivotTo(target)
	end) then
		if not pcall(function()
			rig:SetPrimaryPartCFrame(target)
		end) then
			fail("could not place rig " .. roleName)
			return false
		end
	end
	local okParts, descendants = pcall(function()
		return rig:GetDescendants()
	end)
	if okParts and descendants then
		for _, descendant in ipairs(descendants) do
			pcall(function()
				if (descendant :: any):IsA("BasePart") then
					descendant.Anchored = false
					descendant.CanCollide = true
				end
			end)
		end
	end
	return true
end

local function seatRig(folder: any, seat: any, site: any, roleName: string, index: number): any?
	local rig = buildRig(roleName)
	if not rig then
		return nil
	end
	pcall(function()
		rig.Name = "Seated_R15_" .. roleName .. "_" .. index
		rig:SetAttribute(Data.stageAttribute, Data.familyId)
		rig:SetAttribute(Data.kindAttribute, "npc")
		rig.Parent = folder
	end)
	track(rig)
	if not placeRig(rig, site, roleName) then
		return nil
	end
	local humanoid = findHumanoid(rig)
	if not humanoid then
		fail("no Humanoid on rig " .. roleName)
		return nil
	end
	local okSit, sitError = pcall(function()
		seat:Sit(humanoid)
	end)
	local okState, sitting = pcall(function()
		return humanoid.Sit
	end)
	if not okSit or not okState or sitting ~= true then
		local okFallback, fallbackError = pcall(function()
			humanoid.Sit = true
		end)
		if not okFallback then
			fail("Sit failed for " .. roleName .. ": " .. tostring(sitError or fallbackError))
		end
	end
	return { model = rig, humanoid = humanoid, seat = seat }
end

local function apply()
	if applied then
		return
	end
	clearActive()
	failures = 0
	pcall(function()
		LookDevFailures.reset(Data.familyId)
	end)
	if not Workspace or not Players then
		fail("missing Workspace or Players")
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
	track(folder)

	local sites = Data.sites()
	for _, site in ipairs(sites) do
		local seat = addSeat(folder, site)
		if seat then
			seatsList[#seatsList + 1] = seat
		end
	end
	for index, site in ipairs(sites) do
		local roleName = Data.OUTFITS[index]
		if type(roleName) ~= "string" then
			fail("missing outfit key at site " .. index)
		else
			local seat = seatsList[index]
			if seat then
				local entry = seatRig(folder, seat, site, roleName, index)
				if entry then
					rigsList[#rigsList + 1] = entry
				end
			end
		end
	end
	for _, recipe in ipairs(Data.props()) do
		local prop = addProp(folder, recipe)
		if prop then
			propsList[#propsList + 1] = prop
		end
	end
	if #seatsList ~= 4 or #rigsList ~= 4 or #propsList ~= Data.MIN_PROPS then
		fail("staged " .. #rigsList .. " rigs / " .. #seatsList .. " seats / " .. #propsList .. " props")
	end
	applied = true
	publishFailures()

	-- One bounded re-assert: the engine can briefly clear Sit while the freshly created rig settles.
	-- No Heartbeat, no polling loop; the review harness itself waits 3 s before reading Sit.
	pcall(function()
		task.spawn(function()
			task.wait(0.2)
			if not applied then
				return
			end
			for _, entry in ipairs(rigsList) do
				pcall(function()
					entry.humanoid.Sit = true
				end)
			end
		end)
	end)
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
function LookDevSeatedR8.rigs(): { any }
	return rigsList
end

function LookDevSeatedR8.seatCount(): number
	return #seatsList
end

function LookDevSeatedR8.isApplied(): boolean
	return applied
end

function LookDevSeatedR8.sitStates(): { boolean }
	local states: { boolean } = {}
	for _, entry in ipairs(rigsList) do
		local ok, sitting = pcall(function()
			return entry.humanoid.Sit
		end)
		states[#states + 1] = ok and sitting == true
	end
	return states
end

function LookDevSeatedR8.props(): { any }
	return propsList
end

LookDevSeatedR8.apply = apply
LookDevSeatedR8.restore = restore

LookDev.register(Data.familyId, { apply = apply, restore = restore })

return LookDevSeatedR8
