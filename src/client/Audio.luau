-- Audio: turns `shared/Config/Audio.luau` into Sound instances and plays them.
--
-- Nothing here plays until the registry has real ids, so the game is silent-but-safe with the
-- shipped config. Music follows `MusicZone`-tagged parts (a `Music` attribute names the key) and
-- falls back to `Audio.areas.desa`; ambience follows the `Cuaca` attribute that SeasonService
-- publishes. UI clicks and gameplay stings are fire-and-forget.
--
-- The server never touches this module; it is presentation only.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AudioConfig = require(Shared.Config.Audio)
local AudioPolicy = require(script.Parent.AudioPolicy)

local player = Players.LocalPlayer

local Audio = {}

local FADE_SECONDS = 0.4
local ZONE_POLL = 1

local groups: { [string]: SoundGroup } = {}
local sounds: { [string]: Sound } = {}
local baseVolume: { [string]: number } = {}
local policy = AudioPolicy.new({}) -- loop-state decision maker; rebuilt in start()
local fades: { [Sound]: Tween? } = {} -- in-flight fade per Sound, cancelled before any replay/stop
local stopTokens: { [Sound]: number } = {} -- per-Sound token: invalidates a scheduled Stop on replay
local mounted = false

local function makeGroups()
	for name, volume in AudioConfig.groups do
		local group = SoundService:FindFirstChild("JD_" .. name)
		if not group or not group:IsA("SoundGroup") then
			group = Instance.new("SoundGroup")
			group.Name = "JD_" .. name
			group.Parent = SoundService
		end
		group.Volume = volume
		groups[name] = group
	end
end

-- A real Roblox asset id: positive whole number. Guards 0, fractions, NaN and infinity so
-- a bad config entry never reaches Sound.SoundId.
local function validId(id: any): boolean
	return type(id) == "number" and id % 1 == 0 and id > 0
end

local function makeSounds()
	for key, def in AudioConfig.sounds do
		baseVolume[key] = if type(def.volume) == "number" then def.volume else 0.5
		if validId(def.id) then
			local sound = Instance.new("Sound")
			sound.Name = key
			sound.SoundId = "rbxassetid://" .. def.id
			sound.Looped = def.looped == true
			sound.Volume = baseVolume[key]
			sound.SoundGroup = groups[def.group]
			sound.Parent = SoundService
			sounds[key] = sound
		end
	end
end

-- Fire-and-forget one-shot (UI or sting). Missing/zero-id sounds are silent on purpose.
function Audio.play(key: any)
	if not AudioConfig.exists(key) then
		return
	end
	local sound = sounds[key]
	if not sound then
		return
	end
	sound.TimePosition = 0
	sound:Play()
end

local function fadeTo(sound: Sound, target: number, duration: number)
	local tween = TweenService:Create(sound, TweenInfo.new(duration), { Volume = target })
	tween:Play()
	return tween
end

-- Cancel a Sound's in-flight fade and invalidate any scheduled Stop. Called on both a replay
-- (switch-back) and a newer fade, so a stale timer can never Stop the live loop (WORK_QUEUE 22).
local function cancelFade(sound: Sound)
	local tween = fades[sound]
	if tween then
		fades[sound] = nil
		tween:Destroy()
	end
	stopTokens[sound] = (stopTokens[sound] or 0) + 1
end

local function fadeOut(change: any)
	local sound = if change.from then sounds[change.from] else nil
	if not sound then
		return
	end
	cancelFade(sound)
	local tween = fadeTo(sound, 0, FADE_SECONDS)
	fades[sound] = tween
	local token = stopTokens[sound]
	-- The tween is cosmetic (audible fade); the Stop is authoritative on an explicit timer.
	-- Tween.Completed is not a reliable cleanup hook - e.g. the Studio MCP environment does not
	-- step tweens at all - and a role-generation guard would skip intermediate outgoing loops and
	-- leak them. A per-Sound token survives both cases: cancelled on replay, otherwise Stops once.
	task.delay(FADE_SECONDS, function()
		if stopTokens[sound] == token then
			fades[sound] = nil
			sound:Stop()
		end
	end)
end

local function fadeIn(change: any, target: number)
	local sound = if change.to then sounds[change.to] else nil
	if not sound then
		return
	end
	cancelFade(sound) -- a switch-back may still have a pending fade-out on this Sound
	sound.Volume = 0
	sound:Play()
	local tween = fadeTo(sound, target, FADE_SECONDS)
	fades[sound] = tween
	tween.Completed:Once(function()
		if fades[sound] == tween then
			fades[sound] = nil
		end
	end)
end

-- Switches the looping music bed. `nil` (or a key with no asset) stops it. The pure policy decides
-- the transition; the bridge owns the fades so a state change never leaks a stale loop.
function Audio.setMusic(key: string?)
	if not mounted then
		return
	end
	local change = policy:transition("music", key)
	if not change then
		return
	end
	fadeOut(change)
	fadeIn(change, baseVolume[change.to] or 0.35)
end

function Audio.setWeather(cuaca: string?)
	local key = if type(cuaca) == "string" then AudioConfig.weather[cuaca] else nil
	local change = policy:transition("ambience", key)
	if not change then
		return
	end
	fadeOut(change)
	fadeIn(change, baseVolume[change.to] or 0.25)
end

-- The innermost MusicZone the character stands in, or the town theme.
local function musicAt(position: Vector3): string?
	local best: BasePart? = nil
	local bestVolume = math.huge
	for _, part in CollectionService:GetTagged("MusicZone") do
		if part:IsA("BasePart") then
			local localPoint = part.CFrame:PointToObjectSpace(position)
			local half = part.Size / 2
			if math.abs(localPoint.X) <= half.X
				and math.abs(localPoint.Y) <= half.Y + 4
				and math.abs(localPoint.Z) <= half.Z
			then
				local volume = part.Size.X * part.Size.Y * part.Size.Z
				if volume < bestVolume then
					bestVolume = volume
					best = part
				end
			end
		end
	end
	if not best then
		return AudioConfig.defaultMusic
	end
	local key = best:GetAttribute("Music")
	if type(key) == "string" and AudioConfig.exists(key) then
		return key
	end
	return AudioConfig.defaultMusic
end

local function followZones()
	task.spawn(function()
		while mounted do
			task.wait(ZONE_POLL)
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				Audio.setMusic(musicAt(root.Position))
			end
		end
	end)
end

function Audio.start()
	if mounted then
		return
	end
	mounted = true
	makeGroups()
	makeSounds()
	policy = AudioPolicy.new(AudioPolicy.playable(AudioConfig.sounds))

	Audio.setWeather(ReplicatedStorage:GetAttribute("Cuaca"))
	ReplicatedStorage.AttributeChanged:Connect(function(name)
		if name == "Cuaca" then
			Audio.setWeather(ReplicatedStorage:GetAttribute("Cuaca"))
		end
	end)

	Audio.setMusic(AudioConfig.defaultMusic)
	followZones()
end

return Audio
