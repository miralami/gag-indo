-- LookDevSounds: client applier for the OFF-BY-DEFAULT "sounds" look-dev candidate (WORK_QUEUE
-- round 2 item 9). The two free Creator Store music beds are CANDIDATES awaiting a designer
-- yes/no — never shipped on by default.
--
-- On enable, this creates one Sound per Shared.SoundMap candidate id, assigns it into the
-- round-1 JD_<group> SoundGroup (find-or-create, matching client/Audio.makeGroups), and takes
-- Looped / Volume from Config/Audio.sounds. Loop state follows the round-1 AudioPolicy: at most
-- one active loop per looping role (music / ambience). On disable it stops and destroys every
-- created Sound and its container, leaving the shipping audio untouched.
--
-- No numeric IDs and no asset-URL literal live here: SoundMap owns both, so the LookDev no-ID
-- guard still passes. The LookDev gate keeps this Studio-only and never persisted.

local SoundService = game:GetService("SoundService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LookDev = require(Shared.LookDev)
local SoundMap = require(Shared.SoundMap)
local AudioConfig = require(Shared.Config.Audio)
local AudioPolicy = require(script.Parent.Parent.AudioPolicy)

local LookDevSounds = {}

local CONTAINER = "LookDevSoundCandidates"
local created: { Sound } = {}
local policy: any = nil

-- Reuse the round-1 "JD_<group>" SoundGroup if Audio.start() already made it; otherwise make it.
local function ensureGroup(name: string): SoundGroup?
	if type(name) ~= "string" then
		return nil
	end
	local group = SoundService:FindFirstChild("JD_" .. name)
	if not group or not group:IsA("SoundGroup") then
		group = Instance.new("SoundGroup")
		group.Name = "JD_" .. name
		group.Volume = if type(AudioConfig.groups[name]) == "number" then AudioConfig.groups[name] else 1
		group.Parent = SoundService
	end
	return if group:IsA("SoundGroup") then group else nil
end

local function apply(_plan)
	if #created > 0 then
		return
	end
	local container = SoundService:FindFirstChild(CONTAINER)
	if not container then
		container = Instance.new("Folder")
		container.Name = CONTAINER
		container.Parent = SoundService
	end

	policy = AudioPolicy.new(SoundMap.playable())
	for _, key in SoundMap.candidateOrder do
		local def = AudioConfig.sounds[key]
		local url = SoundMap.assetUrl(key)
		if def and url then
			local sound = Instance.new("Sound")
			sound.Name = key
			sound.SoundId = url
			sound.Looped = def.looped == true
			sound.Volume = if type(def.volume) == "number" then def.volume else 0.5
			local group = ensureGroup(def.group)
			if group then
				sound.SoundGroup = group
			end
			sound.Parent = container
			created[#created + 1] = sound
			-- Follow the round-1 loop policy: one active loop per looping role.
			if def.looped == true and (def.group == "music" or def.group == "ambience") then
				policy:transition(def.group, key)
			end
		end
	end

	-- Audition only the policy's active loops (never every candidate at once).
	for key in policy:activeLoops() do
		for _, sound in created do
			if sound.Name == key then
				sound:Play()
				break
			end
		end
	end
	SoundMap.applyCandidates(true)
end

local function restore()
	for _, sound in created do
		sound:Stop()
		sound:Destroy()
	end
	table.clear(created)
	local container = SoundService:FindFirstChild(CONTAINER)
	if container then
		container:Destroy()
	end
	SoundMap.applyCandidates(false)
	policy = nil
end

LookDev.register("sounds", { apply = apply, restore = restore })

LookDevSounds.apply = apply
LookDevSounds.restore = restore
LookDevSounds.activeLoops = function()
	return if policy then policy:activeLoops() else {}
end

return LookDevSounds
