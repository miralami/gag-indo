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

local player = Players.LocalPlayer

local Audio = {}

local FADE_SECONDS = 0.4
local ZONE_POLL = 1

local groups: { [string]: SoundGroup } = {}
local sounds: { [string]: Sound } = {}
local baseVolume: { [string]: number } = {}
local musicKey: string? = nil
local ambienceKey: string? = nil
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

local function makeSounds()
	for key, def in AudioConfig.sounds do
		baseVolume[key] = if type(def.volume) == "number" then def.volume else 0.5
		if type(def.id) == "number" and def.id > 0 then
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

local function stopMusic()
	if not musicKey then
		return
	end
	local old = sounds[musicKey]
	musicKey = nil
	if not old then
		return
	end
	local tween = fadeTo(old, 0, FADE_SECONDS)
	tween.Completed:Once(function()
		old:Stop()
	end)
end

-- Switches the looping music bed. `nil` (or a key with no asset) stops it.
function Audio.setMusic(key: string?)
	if not mounted or key == musicKey then
		return
	end
	stopMusic()
	if not key then
		return
	end
	local sound = sounds[key]
	if not sound then
		return
	end
	musicKey = key
	sound.Volume = 0
	sound:Play()
	fadeTo(sound, baseVolume[key] or 0.35, FADE_SECONDS)
end

function Audio.setWeather(cuaca: string?)
	local key = if type(cuaca) == "string" then AudioConfig.weather[cuaca] else nil
	if key == ambienceKey then
		return
	end
	if ambienceKey and sounds[ambienceKey] then
		local old = sounds[ambienceKey]
		local tween = fadeTo(old, 0, FADE_SECONDS)
		tween.Completed:Once(function()
			old:Stop()
		end)
	end
	ambienceKey = key
	local sound = if key then sounds[key] else nil
	if not sound then
		return
	end
	sound.Volume = 0
	sound:Play()
	fadeTo(sound, baseVolume[key] or 0.25, FADE_SECONDS)
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
