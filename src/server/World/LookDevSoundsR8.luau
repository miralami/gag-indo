--!strict
-- LookDevSoundsR8: SERVER-ONLY applier for the OFF-BY-DEFAULT "sounds_r8" candidate
-- (WORK_QUEUE section M item 92). Six real free Creator Store audio beds from the pure
-- Shared.ModelMapSoundsR8 data: jangkrik at night, ayam + birds by day, river + wind always,
-- kentongan as an occasional event. They are positional (each Sound is parented to a tiny
-- invisible anchored Part), capped at Volume <= 0.5 and RollOffMaxDistance <= 80, and all share
-- one find-or-created JD_sounds_r8 SoundGroup. Nothing plays until the Studio-only enable call.
--
-- Every engine call is pcall-guarded; SETUP errors are published through Shared.LookDevFailures.
-- IsLoaded timing is NOT published here: "not authorized" has no Luau signal, so the harness owns
-- the bounded 10 s IsLoaded poll. restore() stops and destroys every Sound/Part/folder and destroys
-- the group only when this applier created it, restoring any prior folder exactly. Idempotent.
-- No numeric asset id and no full asset URL live in this file: SoundId is built from the pure id.
--
--   require(game.ReplicatedStorage.Shared.LookDevReview).enable("sounds_r8", game)

local function service(name: string): any?
	local ok, value = pcall(function()
		return game:GetService(name)
	end)
	if ok then
		return value
	end
	warn("[LookDevSoundsR8] missing service " .. name)
	return nil
end

local ReplicatedStorage = service("ReplicatedStorage")
local SoundService = service("SoundService")
local Workspace = service("Workspace")
if not ReplicatedStorage or not SoundService or not Workspace then
	return {}
end

local okShared, Shared = pcall(function()
	return (ReplicatedStorage :: any):WaitForChild("Shared")
end)
if not okShared or not Shared then
	warn("[LookDevSoundsR8] missing Shared folder")
	return {}
end

local okModules, LookDev, Data, Failures = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapSoundsR8),
		require((Shared :: any).LookDevFailures)
end)
if not okModules or not LookDev or not Data or not Failures then
	warn("[LookDevSoundsR8] could not require LookDev / ModelMapSoundsR8 / LookDevFailures")
	return {}
end

local LookDevSoundsR8 = {}

local ASSET_PREFIX = "rbxassetid://"

local applied = false
local folder: any? = nil
local savedFolder: any? = nil
local group: any? = nil
local createdGroup = false
local staged: { { bed: any, sound: any?, part: any? } } = {}
local failures = 0

local function fail(message: string)
	failures += 1
	warn("[LookDevSoundsR8] " .. Data.id .. ": " .. message)
end

local function publishFailures()
	pcall(function()
		Failures.set(Data.id, failures)
	end)
end

local function clearActive()
	for index = #staged, 1, -1 do
		local entry = staged[index]
		if entry.sound then
			pcall(function()
				entry.sound:Stop()
			end)
			pcall(function()
				entry.sound:Destroy()
			end)
		end
		if entry.part then
			pcall(function()
				entry.part:Destroy()
			end)
		end
		staged[index] = nil
	end
	if folder then
		pcall(function()
			folder:Destroy()
		end)
		folder = nil
	end
end

local function findGroup(): any?
	local okFind, found = pcall(function()
		return (SoundService :: any):FindFirstChild(Data.groupName)
	end)
	if not okFind then
		fail("could not look up SoundGroup")
		return nil
	end
	if found then
		local okGroup, isGroup = pcall(function()
			return found:IsA("SoundGroup")
		end)
		if okGroup and isGroup then
			return found
		end
		fail("existing " .. Data.groupName .. " is not a SoundGroup")
		return nil
	end
	local okNew, created = pcall(function()
		return (Instance :: any).new("SoundGroup")
	end)
	if not okNew or not created then
		fail("could not create SoundGroup")
		return nil
	end
	local okParent, parentErr = pcall(function()
		created.Name = Data.groupName
		created.Parent = SoundService
	end)
	if not okParent then
		pcall(function()
			created:Destroy()
		end)
		fail("could not parent SoundGroup: " .. tostring(parentErr))
		return nil
	end
	createdGroup = true
	return created
end

local function stageBed(bed: any, parent: any, soundGroup: any?)
	local okPart, part = pcall(function()
		return (Instance :: any).new("Part")
	end)
	if not okPart or not part then
		fail("could not create Part for " .. bed.key)
		return
	end
	staged[#staged + 1] = { bed = bed, sound = nil, part = part }
	local okPartSet, partErr = pcall(function()
		part.Name = "LookDevSoundsR8_" .. bed.key
		part.Size = Vector3.new(1, 1, 1)
		part.CFrame = CFrame.new(bed.position.x, bed.position.y, bed.position.z)
		part.Anchored = true
		part.CanCollide = false
		part.Transparency = 1
		part:SetAttribute("LookDevSoundsR8", Data.id)
		part:SetAttribute("BedKey", bed.key)
		part:SetAttribute("BedTimeSlot", bed.timeSlot)
		part.Parent = parent
	end)
	if not okPartSet then
		fail("could not configure Part " .. bed.key .. ": " .. tostring(partErr))
		return
	end

	local okSound, sound = pcall(function()
		return (Instance :: any).new("Sound")
	end)
	if not okSound or not sound then
		fail("could not create Sound for " .. bed.key)
		return
	end
	staged[#staged].sound = sound
	local okSoundSet, soundErr = pcall(function()
		sound.Name = bed.key
		sound.SoundId = ASSET_PREFIX .. tostring(bed.id)
		sound.Volume = math.min(bed.volume, Data.MAX_VOLUME)
		sound.RollOffMaxDistance = math.min(bed.rollOffMax, Data.MAX_ROLLOFF)
		sound.RollOffMinDistance = Data.ROLLOFF_MIN
		sound.Looped = bed.looped == true
		if soundGroup then
			sound.SoundGroup = soundGroup
		end
		-- Parenting to a BasePart makes the bed positional.
		sound.Parent = part
	end)
	if not okSoundSet then
		fail("could not configure Sound " .. bed.key .. ": " .. tostring(soundErr))
		return
	end
	if bed.looped == true then
		local okPlay, playErr = pcall(function()
			sound:Play()
		end)
		if not okPlay then
			fail("could not play " .. bed.key .. ": " .. tostring(playErr))
		end
	end
end

local function apply(_plan: any)
	if applied then
		return
	end
	clearActive()
	failures = 0
	createdGroup = false

	local okFind, previous = pcall(function()
		return (Workspace :: any):FindFirstChild(Data.folder)
	end)
	if okFind and previous then
		pcall(function()
			previous.Parent = nil
		end)
		savedFolder = previous
	end

	local okFolder, newFolder = pcall(function()
		return (Instance :: any).new("Folder")
	end)
	if not okFolder or not newFolder then
		fail("could not create staging folder")
		publishFailures()
		return
	end
	folder = newFolder
	local okParent, parentErr = pcall(function()
		newFolder.Name = Data.folder
		newFolder.Parent = Workspace
		newFolder:SetAttribute("LookDevSoundsR8", Data.id)
	end)
	if not okParent then
		fail("could not parent staging folder: " .. tostring(parentErr))
		pcall(function()
			newFolder:Destroy()
		end)
		folder = nil
		publishFailures()
		return
	end

	group = findGroup()
	for _, bed in ipairs(Data.BEDS) do
		stageBed(bed, newFolder, group)
	end
	applied = true
	publishFailures()
end

local function restore()
	if not applied and folder == nil and savedFolder == nil and group == nil and #staged == 0 then
		return
	end
	applied = false
	clearActive()
	if createdGroup and group then
		pcall(function()
			group:Destroy()
		end)
	end
	group = nil
	createdGroup = false
	if savedFolder then
		pcall(function()
			savedFolder.Parent = Workspace
		end)
		savedFolder = nil
	end
	publishFailures()
end

function LookDevSoundsR8.diagnostics(): any
	local playing = 0
	local stagedParts = 0
	for _, entry in ipairs(staged) do
		if entry.part then
			stagedParts += 1
		end
		if entry.sound then
			local ok, isPlaying = pcall(function()
				return entry.sound.IsPlaying
			end)
			if ok and isPlaying == true then
				playing += 1
			end
		end
	end
	return {
		beds = #Data.BEDS,
		stagedParts = stagedParts,
		sounds = #staged,
		groupName = Data.groupName,
		playing = playing,
		folderPresent = folder ~= nil,
		createdGroup = createdGroup,
		failures = failures,
	}
end

function LookDevSoundsR8.bedSpecs(): any
	return Data.BEDS
end

LookDevSoundsR8.apply = apply
LookDevSoundsR8.restore = restore

LookDev.register(Data.id, { apply = apply, restore = restore })

return LookDevSoundsR8
