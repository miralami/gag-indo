--!strict
-- LookDevSubuhR8: CLIENT-ONLY applier for the OFF-BY-DEFAULT "subuh_r8" candidate (WORK_QUEUE
-- section N item 121). Pure values come from Shared.ModelMapSubuhR8. It follows the DayCycle
-- tween rules: 20-40 s Sine/Out TweenInfo, every touched property saved before the first write,
-- pcall-guarded TweenService with a direct setProps fallback, and an exact LIFO restore.
--
-- The harness does NOT wait 30 s per phase. setClockForCheck(clock) and
-- applyPhaseNowForCheck(clock) cancel tweens and write through setProps directly, mirroring the
-- clock override in LookDevNightR8 and the override-first read in LookDevRainR8. currentClock()
-- reads the override first, then Lighting.ClockTime, then a safe day default.
--
-- Scope: Lighting, the existing effects, Clouds.Cover and at most six own PointLights in one
-- Folder. No Sound is staged, so the off-by-default sounds bed cannot fill the pre-06:00 silence.
-- No Terrain voxel, DataStore, player or crop state write, no asset ID, no player-facing text.

local function service(name: string): any?
	local ok, value = pcall(function()
		return (game :: any):GetService(name)
	end)
	if ok then
		return value
	end
	return nil
end

local ReplicatedStorage = service("ReplicatedStorage")
local Lighting = service("Lighting")
local Workspace = service("Workspace")
local TweenService = service("TweenService")
if not ReplicatedStorage or not Lighting or not Workspace then
	return {}
end

local okShared, Shared = pcall(function()
	return (ReplicatedStorage :: any):WaitForChild("Shared")
end)
if not okShared or not Shared then
	return {}
end

local okModules, LookDev, Data, DayCycleLive = pcall(function()
	return require((Shared :: any).LookDev),
		require((Shared :: any).ModelMapSubuhR8),
		require((Shared :: any).World.DayCycleLive)
end)
if not okModules or not LookDev or not Data or not DayCycleLive then
	return {}
end

local LookDevSubuhR8 = {}

local applied = false
local clockOverride: number? = nil
local appliedPhase: string? = nil
local originals: { { target: any, prop: string, value: any } } = {}
local savedKeys: { [string]: boolean } = {}
local created: { any } = {}
local tweens: { any } = {}
local lamps: { any } = {}
local folder: any = nil

local function numberOr(value: any, fallback: number): number
	if type(value) == "number" and value == value and value > -math.huge and value < math.huge then
		return value
	end
	return fallback
end

-- Enum lookups are pcall'd because the restricted Studio VM cannot always resolve them.
local function tweenInfo(seconds: number): any?
	local okStyle, style = pcall(function()
		return ((Enum :: any).EasingStyle).Sine
	end)
	local okDirection, direction = pcall(function()
		return ((Enum :: any).EasingDirection).Out
	end)
	if not okStyle or not okDirection or style == nil or direction == nil then
		return nil
	end
	local ok, info = pcall(function()
		return (TweenInfo :: any).new(seconds, style, direction)
	end)
	return if ok then info else nil
end

local function saveProp(target: any, prop: string)
	local key = tostring(target) .. ":" .. prop
	if savedKeys[key] then
		return
	end
	local ok, value = pcall(function()
		return target[prop]
	end)
	if ok then
		savedKeys[key] = true
		table.insert(originals, { target = target, prop = prop, value = value })
	end
end

-- Roblox colour properties need a real Color3 value, never a plain table. Byte props arrive as
-- 0..255 triples; TintColor arrives already normalized. All conversion goes through this one
-- function so BOTH the tween and the direct diagnostic path build the same engine value.
local function engineColor(prop: string, value: any): any?
	if not Data.BYTE_COLOR_PROPS[prop] and not Data.FRACTION_COLOR_PROPS[prop] then
		return value
	end
	local normalized = Data.normalizedColor(prop, value)
	if normalized == nil then
		return nil
	end
	local ok, color = pcall(function()
		return (Color3 :: any).new(normalized.r, normalized.g, normalized.b)
	end)
	return if ok then color else nil
end

local function setProps(target: any, props: { [string]: any })
	for prop, value in props do
		if value ~= nil then
			saveProp(target, prop) -- direct writes must be snapshotted for the exact LIFO restore
			pcall(function()
				target[prop] = value
			end)
		end
	end
end

local function cancelTweens()
	for _, tween in ipairs(tweens) do
		pcall(function()
			tween:Cancel()
		end)
	end
	table.clear(tweens)
end

local function tweenProps(target: any, props: { [string]: any }, seconds: number)
	local goals: { [string]: any } = {}
	for prop, value in props do
		saveProp(target, prop) -- snapshot BEFORE conversion and before the first write
		if value ~= nil then
			goals[prop] = value
		end
	end
	local info = tweenInfo(seconds)
	if info and TweenService then
		local ok, tween = pcall(function()
			return (TweenService :: any):Create(target, info, goals)
		end)
		if ok and tween then
			table.insert(tweens, tween)
			pcall(function()
				tween:Play()
			end)
			return
		end
	end
	-- No TweenInfo in this VM: the grade still lands, just without the phase-long ease.
	setProps(target, goals)
end

local function effect(className: string): any?
	local found = nil
	local okFind, existing = pcall(function()
		return (Lighting :: any):FindFirstChildOfClass(className)
	end)
	if okFind then
		found = existing
	end
	if not found then
		local okNew, instance = pcall(function()
			return (Instance :: any).new(className)
		end)
		if not okNew or not instance then
			return nil
		end
		local okParent, parented = pcall(function()
			instance.Parent = Lighting
			return instance.Parent
		end)
		if not okParent or not parented then
			return nil
		end
		found = instance
		table.insert(created, found)
	end
	return found
end

local function findClouds(): any?
	local found = nil
	local okTerrain, terrain = pcall(function()
		return (Workspace :: any):FindFirstChildOfClass("Terrain")
	end)
	if okTerrain and terrain then
		local okCloud, clouds = pcall(function()
			return terrain:FindFirstChildOfClass("Clouds")
		end)
		if okCloud then
			found = clouds
		end
	end
	return found
end

local function buildLamps()
	local okFolder, made = pcall(function()
		local existing = (Workspace :: any):FindFirstChild(Data.FOLDER)
		if existing then
			existing:Destroy()
		end
		local f = (Instance :: any).new("Folder")
		f.Name = Data.FOLDER
		f.Parent = Workspace
		return f
	end)
	if not okFolder or not made then
		return
	end
	folder = made
	table.insert(created, folder)

	local positions = DayCycleLive.lampPositions()
	local count = math.min(#positions, Data.LAMP.maxLights)
	for index = 1, count do
		local position = positions[index]
		local okBuild, part, light = pcall(function()
			local lampPart = (Instance :: any).new("Part")
			lampPart.Name = "LookDevSubuhR8Lamp_" .. index
			lampPart.Size = (Vector3 :: any).new(0.6, 0.6, 0.6)
			lampPart.CFrame = (CFrame :: any).new(position[1], position[2], position[3])
			lampPart.Anchored = true
			lampPart.CanCollide = false
			lampPart.Parent = folder
			local pointLight = (Instance :: any).new("PointLight")
			pointLight.Name = "LampLight"
			pointLight.Shadows = Data.LAMP.shadows
			pointLight.Range = Data.LAMP.range
			pointLight.Brightness = 0
			pointLight.Parent = lampPart
			return lampPart, pointLight
		end)
		if okBuild and part and light then
			table.insert(created, part)
			table.insert(created, light)
			table.insert(lamps, light)
		end
	end
end

local function updateLamps(brightness: number)
	local level = math.clamp(numberOr(brightness, 0), 0, Data.LAMP.brightnessMax)
	for _, light in ipairs(lamps) do
		pcall(function()
			light.Brightness = level
		end)
	end
end

local function applyAt(clock: any, useTween: boolean)
	cancelTweens()
	local preset = Data.presetFor(clock)
	local seconds = math.clamp(Data.TWEEN_SECONDS, DayCycleLive.MIN_TWEEN_SECONDS, DayCycleLive.MAX_TWEEN_SECONDS)
	local write = if useTween then tweenProps else setProps

	write(Lighting, {
		ClockTime = preset.clockTime,
		Brightness = preset.brightness,
		FogEnd = preset.fogEnd,
		FogColor = engineColor("FogColor", preset.fogColor),
		Ambient = engineColor("Ambient", preset.ambient),
		OutdoorAmbient = engineColor("OutdoorAmbient", preset.outdoorAmbient),
		ColorShift_Top = engineColor("ColorShift_Top", preset.colorShiftTop),
		ColorShift_Bottom = engineColor("ColorShift_Bottom", preset.colorShiftBottom),
		ShadowSoftness = Data.SHADOW_SOFTNESS,
	}, seconds)

	local atmo = effect("Atmosphere")
	if atmo then
		write(atmo, {
			Density = preset.atmosphereDensity,
			Haze = preset.atmosphereHaze,
			Color = engineColor("Color", preset.atmosphereColor),
			Decay = engineColor("Decay", Data.ATMOSPHERE_DECAY),
			Glare = Data.ATMOSPHERE_GLARE,
		}, seconds)
	end
	local correction = effect("ColorCorrectionEffect")
	if correction then
		write(correction, {
			TintColor = engineColor("TintColor", preset.tintColor),
			Saturation = preset.saturation,
			Contrast = preset.contrast,
		}, seconds)
	end
	local bloom = effect("BloomEffect")
	if bloom then
		write(bloom, { Intensity = preset.bloom }, seconds)
	end
	local sunRays = effect("SunRaysEffect")
	if sunRays then
		write(sunRays, { Intensity = preset.sunRays }, seconds)
	end
	local clouds = findClouds()
	if clouds then
		write(clouds, { Cover = preset.cloudCover }, seconds)
	end

	updateLamps(preset.lampBrightness)
	appliedPhase = preset.phaseId
end

-- Override first, then the live client Lighting clock, then a safe day default.
local function currentClock(): number
	if clockOverride ~= nil then
		return clockOverride
	end
	local ok, value = pcall(function()
		return (Lighting :: any).ClockTime
	end)
	if ok and type(value) == "number" and value == value then
		return value
	end
	return 12
end

local function apply(_plan: any?)
	if applied then
		return
	end
	originals = {}
	savedKeys = {}
	created = {}
	tweens = {}
	lamps = {}
	folder = nil
	clockOverride = nil
	appliedPhase = nil

	buildLamps()
	applyAt(currentClock(), true)
	applied = true
end

local function restore()
	if not applied and clockOverride == nil and #created == 0 and #originals == 0 then
		return
	end
	applied = false
	clockOverride = nil -- no check override may leak into the next candidate
	cancelTweens()

	for index = #originals, 1, -1 do
		local entry = originals[index]
		pcall(function()
			entry.target[entry.prop] = entry.value
		end)
	end
	table.clear(originals)
	table.clear(savedKeys)

	for _, instance in ipairs(created) do
		pcall(function()
			if instance.Parent then
				instance:Destroy()
			end
		end)
	end
	table.clear(created)
	table.clear(lamps)
	folder = nil
	appliedPhase = nil
end

local function read(target: any, prop: string): any?
	if not target then
		return nil
	end
	local ok, value = pcall(function()
		return target[prop]
	end)
	return if ok then value else nil
end

function LookDevSubuhR8.currentClock(): number
	return currentClock()
end

function LookDevSubuhR8.setClockForCheck(clock: any): boolean
	if type(clock) ~= "number" or clock ~= clock or clock == math.huge or clock == -math.huge then
		return false
	end
	clockOverride = clock
	if applied then
		applyAt(clock, false)
	end
	return true
end

function LookDevSubuhR8.applyPhaseNowForCheck(clock: any): boolean
	if type(clock) ~= "number" or clock ~= clock or clock == math.huge or clock == -math.huge then
		return false
	end
	clockOverride = clock
	if applied then
		applyAt(clock, false) -- cancel tweens; write through setProps, never a 30 s tween
	end
	return true
end

function LookDevSubuhR8.clearClockForCheck(): boolean
	clockOverride = nil
	return true
end

function LookDevSubuhR8.isApplied(): boolean
	return applied
end

function LookDevSubuhR8.phaseCount(): number
	return Data.phaseCount()
end

function LookDevSubuhR8.appliedPhase(): string?
	return appliedPhase
end

-- Live readings shaped exactly like Data.safeRanges, for Data.checkReadings in the harness.
function LookDevSubuhR8.safeReadings(): any
	local atmo = nil
	local correction = nil
	local bloom = nil
	local sunRays = nil
	local okFind, found = pcall(function()
		return (Lighting :: any):FindFirstChildOfClass("Atmosphere")
	end)
	if okFind then
		atmo = found
	end
	local okCorrection, foundCorrection = pcall(function()
		return (Lighting :: any):FindFirstChildOfClass("ColorCorrectionEffect")
	end)
	if okCorrection then
		correction = foundCorrection
	end
	local okBloom, foundBloom = pcall(function()
		return (Lighting :: any):FindFirstChildOfClass("BloomEffect")
	end)
	if okBloom then
		bloom = foundBloom
	end
	local okRays, foundRays = pcall(function()
		return (Lighting :: any):FindFirstChildOfClass("SunRaysEffect")
	end)
	if okRays then
		sunRays = foundRays
	end
	local firstLight = lamps[1]
	local lampShadows, lampRange, lampBrightness = nil, nil, nil
	if firstLight then
		lampShadows = read(firstLight, "Shadows")
		lampRange = read(firstLight, "Range")
		lampBrightness = read(firstLight, "Brightness")
	end
	return {
		Lighting = {
			Brightness = read(Lighting, "Brightness"),
			FogEnd = read(Lighting, "FogEnd"),
			FogColor = read(Lighting, "FogColor"),
			Ambient = read(Lighting, "Ambient"),
			OutdoorAmbient = read(Lighting, "OutdoorAmbient"),
			ColorShift_Top = read(Lighting, "ColorShift_Top"),
			ColorShift_Bottom = read(Lighting, "ColorShift_Bottom"),
		},
		Atmosphere = {
			Density = read(atmo, "Density"),
			Haze = read(atmo, "Haze"),
			Color = read(atmo, "Color"),
			Decay = read(atmo, "Decay"),
			Glare = read(atmo, "Glare"),
		},
		Clouds = { Cover = read(findClouds(), "Cover") },
		ColorCorrectionEffect = {
			Saturation = read(correction, "Saturation"),
			Contrast = read(correction, "Contrast"),
			TintColor = read(correction, "TintColor"),
		},
		BloomEffect = { Intensity = read(bloom, "Intensity") },
		SunRaysEffect = { Intensity = read(sunRays, "Intensity") },
		Lamps = { Shadows = lampShadows, Range = lampRange, Brightness = lampBrightness },
	}
end

LookDev.register(Data.id, { apply = apply, restore = restore })

LookDevSubuhR8.apply = apply
LookDevSubuhR8.restore = restore

return LookDevSubuhR8
