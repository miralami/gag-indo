--!strict
-- LookDevRainR8: CLIENT-ONLY applier for the OFF-BY-DEFAULT "rain_r8" candidate (WORK_QUEUE
-- section N item 120). Pure values come from Shared.ModelMapRainR8: two camera-following ring
-- rain emitters, one ground splash at the documented SPLASH_Y, and a bounded bump on the existing
-- Atmosphere.Density. Emitters are Enabled only when the live weather is "hujan"; "cerah" (and a
-- missing attribute) leaves them all disabled.
--
-- The weather check reads the Cuaca attribute on ReplicatedStorage but never writes it: the client
-- must not race the server's LiveConfig poll or retrigger the Sky tween. setCuacaForCheck is a
-- deterministic override for harness checks, mirroring LookDevNightR8.setClockForCheck; it is
-- cleared by clearCuacaForCheck, by restore and by any later disable.
--
-- One Heartbeat connection follows CurrentCamera and calls the same pump(dt) the cost check times.
-- No Terrain write, no DataStore/player/crop state, no ColorCorrection/Bloom/SunRays/ClockTime,
-- no asset ID and no Texture on the emitters. Every engine call is pcall-guarded.

local function service(name: string): any?
	local ok, value = pcall(function()
		return (game :: any):GetService(name)
	end)
	if ok then
		return value
	end
	warn("[LookDevRainR8] missing service " .. name)
	return nil
end

local ReplicatedStorage = service("ReplicatedStorage")
local RunService = service("RunService")
local Lighting = service("Lighting")
local Workspace = service("Workspace")
if not ReplicatedStorage or not RunService or not Lighting or not Workspace then
	return {}
end

local okShared, Shared = pcall(function()
	return (ReplicatedStorage :: any):WaitForChild("Shared")
end)
if not okShared or not Shared then
	warn("[LookDevRainR8] missing Shared folder")
	return {}
end

local okModules, LookDev, Data = pcall(function()
	return require((Shared :: any).LookDev), require((Shared :: any).ModelMapRainR8)
end)
if not okModules or not LookDev or not Data then
	warn("[LookDevRainR8] could not require LookDev / ModelMapRainR8")
	return {}
end

local LookDevRainR8 = {}

local applied = false
local folder: any = nil
local entries: { { name: string, part: any, emitter: any, spec: any } } = {}
local atmosphere: any = nil
local savedDensity: number? = nil
local heartbeatConnection: any = nil
local cuacaOverride: string? = nil
local lastCostMs = 0

-- Override first, then the live server attribute, then the safe clear default. A missing or
-- non-string attribute is "cerah": rain must never turn itself on by accident.
local function currentCuaca(): string
	if cuacaOverride ~= nil then
		return cuacaOverride
	end
	local ok, value = pcall(function()
		return (ReplicatedStorage :: any):GetAttribute("Cuaca")
	end)
	if ok and type(value) == "string" then
		return value
	end
	return Data.WEATHER_CLEAR
end

local function gateEmitters()
	if not applied then
		return
	end
	local on = Data.weatherIsRain(currentCuaca())
	for _, entry in ipairs(entries) do
		pcall(function()
			entry.emitter.Enabled = on
		end)
	end
end

local function buildEmitter(spec: any, parent: any): (any?, any?)
	local okPart, part = pcall(function()
		return (Instance :: any).new("Part")
	end)
	if not okPart or not part then
		warn("[LookDevRainR8] could not create Part " .. tostring(spec.id))
		return nil
	end
	pcall(function()
		part.Name = "Rain_" .. spec.id
		part.Size = (Vector3 :: any).new(0.5, 0.5, 0.5)
		part.Anchored = true
		part.CanCollide = false
		part.CastShadow = false
		part.Transparency = 1
		part.Parent = parent
	end)
	local okEmitter, emitter = pcall(function()
		local pe = (Instance :: any).new("ParticleEmitter")
		pe.Name = "Rate"
		pe.Rate = spec.rate
		pe.Lifetime = (NumberRange :: any).new(spec.lifetime[1], spec.lifetime[2])
		pe.Speed = (NumberRange :: any).new(spec.speed[1], spec.speed[2])
		pe.SpreadAngle = (Vector2 :: any).new(spec.spread.x, spec.spread.y)
		pe.Size = (NumberSequence :: any).new({
			(NumberSequenceKeypoint :: any).new(0, spec.size[1]),
			(NumberSequenceKeypoint :: any).new(1, spec.size[2]),
		})
		pe.Color = (ColorSequence :: any).new((Color3 :: any).fromRGB(spec.color.r, spec.color.g, spec.color.b))
		pe.Enabled = false -- gateEmitters applies the live weather rule at the end of apply()
		-- No Texture: a textureless emitter needs no asset ID and no decal.
		pe.Parent = part
		return pe
	end)
	if not okEmitter or not emitter then
		warn("[LookDevRainR8] could not create emitter " .. tostring(spec.id) .. ": " .. tostring(emitter))
		pcall(function()
			part:Destroy()
		end)
		return nil
	end
	return emitter, part
end

-- The per-frame update the Heartbeat calls. The harness times THIS function, so the measured cost
-- is the real camera-follow + weather-gate cost, not a separate simulation.
local function pump(dt: number)
	if not applied then
		return
	end
	local started = os.clock()
	local step = type(dt) == "number" and math.clamp(dt, 0, 0.25) or 0
	local okCamera, camera = pcall(function()
		return (Workspace :: any).CurrentCamera
	end)
	local frame = nil
	if okCamera and camera then
		local okFrame, value = pcall(function()
			return camera.CFrame
		end)
		if okFrame then
			frame = value
		end
	end
	local position = nil
	if frame then
		local okPosition, value = pcall(function()
			return frame.Position
		end)
		if okPosition then
			position = value
		end
	end
	if position then
		for _, entry in ipairs(entries) do
			local spec = entry.spec
			pcall(function()
				if spec.kind == "splash" then
					entry.part.CFrame = (CFrame :: any).new(
						position.X + spec.offset.x,
						Data.SPLASH_Y,
						position.Z + spec.offset.z
					)
				else
					entry.part.CFrame = frame * (CFrame :: any).new(spec.offset.x, spec.offset.y, spec.offset.z)
				end
			end)
		end
	end
	if step >= 0 then
		gateEmitters()
	end
	lastCostMs = (os.clock() - started) * 1000
end

local function tick(dt: number)
	pump(dt)
end

local function clearFolder()
	if folder then
		pcall(function()
			folder:Destroy()
		end)
	end
	folder = nil
	entries = {}
end

local function apply(_plan: any?)
	if applied then
		return
	end
	if Data.emitterCount() > Data.MAX_EMITTERS or Data.maxRate() > Data.MAX_RATE then
		warn("[LookDevRainR8] recipe exceeds the item-120 emitter or rate budget")
		return
	end

	local okFolder, created = pcall(function()
		local existing = (Workspace :: any):FindFirstChild(Data.FOLDER)
		if existing then
			existing:Destroy()
		end
		local f = (Instance :: any).new("Folder")
		f.Name = Data.FOLDER
		f.Parent = Workspace
		return f
	end)
	if not okFolder or not created then
		warn("[LookDevRainR8] could not create " .. Data.FOLDER .. ": " .. tostring(created))
		return
	end
	folder = created
	applied = true
	entries = {}
	lastCostMs = 0

	for _, spec in ipairs(Data.EMITTERS) do
		local emitter, part = buildEmitter(spec, folder)
		if emitter and part then
			entries[#entries + 1] = { name = spec.id, part = part, emitter = emitter, spec = spec }
		end
	end

	local okFind, effect = pcall(function()
		return (Lighting :: any):FindFirstChildOfClass("Atmosphere")
	end)
	if okFind and effect then
		local okDensity, original = pcall(function()
			return effect.Density
		end)
		if okDensity and type(original) == "number" and original == original then
			atmosphere = effect
			savedDensity = original
			pcall(function()
				effect.Density = math.min(original + Data.MIST_DELTA, Data.MIST_MAX)
			end)
		end
	end

	gateEmitters()
	pump(0)

	local okHeartbeat, heartbeat = pcall(function()
		return (RunService :: any).Heartbeat
	end)
	if okHeartbeat and heartbeat and type(heartbeat.Connect) == "function" then
		local okConnect, connection = pcall(function()
			return heartbeat:Connect(tick)
		end)
		if okConnect then
			heartbeatConnection = connection
		else
			warn("[LookDevRainR8] Heartbeat connect failed: " .. tostring(connection))
		end
	end
end

local function restore()
	if not applied and not folder and savedDensity == nil and cuacaOverride == nil and not heartbeatConnection then
		return
	end
	if heartbeatConnection then
		pcall(function()
			heartbeatConnection:Disconnect()
		end)
	end
	heartbeatConnection = nil
	cuacaOverride = nil -- no check override may leak into the next candidate
	applied = false
	if savedDensity ~= nil and atmosphere then
		local saved = savedDensity
		pcall(function()
			atmosphere.Density = saved
		end)
	end
	savedDensity = nil -- LIFO exact restore of the one overwritten scalar
	atmosphere = nil
	clearFolder()
	lastCostMs = 0
end

function LookDevRainR8.emitterCount(): number
	local count = 0
	for _ in ipairs(entries) do
		count += 1
	end
	return count
end

function LookDevRainR8.isApplied(): boolean
	return applied
end

function LookDevRainR8.currentWeather(): string
	return currentCuaca()
end

function LookDevRainR8.pump(dt: number)
	pump(dt)
end

function LookDevRainR8.lastCostMs(): number
	return lastCostMs
end

function LookDevRainR8.setCuacaForCheck(value: any): boolean
	if value ~= Data.WEATHER_CLEAR and value ~= Data.WEATHER_RAIN then
		return false
	end
	cuacaOverride = value
	gateEmitters()
	return true
end

function LookDevRainR8.clearCuacaForCheck(): boolean
	cuacaOverride = nil
	gateEmitters()
	return true
end

LookDev.register(Data.id, { apply = apply, restore = restore })

return LookDevRainR8
