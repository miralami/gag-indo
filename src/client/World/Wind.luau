-- Wind: a gentle sway for foliage tagged WindShake (ART.md section 9; research tracker "wind on
-- foliage via a tag, near the camera only"). Client only.
-- Only tagged parts within the fidelity tier's foliageSwayRange of the camera move, fading out toward its edge. Each one stores its original CFrame on
-- first sight and is written as original * offset, so nothing drifts. Parts that leave range, or
-- that are no longer in the game, are put back. Anchored parts only. No tweens, no new instances.
-- The loop runs at about 20 Hz and touches at most MAX_PER_TICK parts per tick.

local TierScale = require(script.Parent.Parent.Feel.TierScale)

local Wind = {}

local TICK = 0.05 -- about 20 Hz
local MAX_PER_TICK = 40
local MAX_ROTATION = 3 -- degrees, about the Z axis
local MAX_OFFSET = 0.25 -- studs, along X
local SWAY_SPEED = 0.9 -- radians per second for the main sway
local FLUTTER_SPEED = 0.37 -- a slower second sine so the motion never looks mechanical
local WIND_TAG = "WindShake"

-- FidelityRuntime is a singleton ModuleScript, so resolve it once at start() instead of building a
-- fresh pcall closure + require() on every 20 Hz tick. settings() is still read every tick below,
-- so a tier change made after start (including one made before FidelityRuntime itself started)
-- still lands on the next tick. resolveCount is a diagnostic the perf spec uses to prove the
-- resolution happens once per start, not once per frame.
local fidelityRuntime = nil :: any
local resolveCount = 0

local function resolveFidelityRuntime(): any
	resolveCount += 1
	local ok, mod = pcall(function()
		return require(script.Parent.Parent.Feel.FidelityRuntime)
	end)
	return if ok then mod else nil
end

-- Diagnostic: how many times FidelityRuntime has been resolved since this module loaded.
function Wind.resolveCount(): number
	return resolveCount
end

local function tierSettings(): any
	if not fidelityRuntime then
		return nil
	end
	local ok, settings = pcall(fidelityRuntime.settings)
	return if ok then settings else nil
end

-- Pure helper: the sway for one part at time t. Returns rotation in degrees and offset in studs,
-- both inside the limits above. The part's WindSeed sets the phase, so neighbours do not move in step.
-- The offset carries the visible motion (a Ball turning about its own centre barely shows), so it
-- rides the main sine; the slower sine only turns the part a little.
function Wind.offsetFor(seed: number, t: number): (number, number)
	local sway = math.sin(t * SWAY_SPEED + seed)
	local flutter = math.sin(t * FLUTTER_SPEED + seed * 1.7 + 1.3)
	local offset = math.clamp(sway * MAX_OFFSET, -MAX_OFFSET, MAX_OFFSET)
	local rotation = math.clamp(flutter * MAX_ROTATION, -MAX_ROTATION, MAX_ROTATION)
	return rotation, offset
end

local started = false
local accumulator = 0
local cursor = 0
local heartbeatConnection = nil
local tagRemovedConnection = nil
-- Original CFrame per part. Weak keys, so a destroyed part does not stay in memory.
local originals: { [BasePart]: CFrame } = setmetatable({}, { __mode = "k" })

-- Sways one part if it is in range, otherwise puts it back if it was moved earlier.
local function step(part: BasePart, origin: Vector3, now: number, settings: any)
	if part.Parent == nil then
		originals[part] = nil
		return
	end
	local original = originals[part]
	-- Weight fades the sway toward the edge of the tier's range; 0 means out of range.
	local weight = if part.Anchored then TierScale.swayWeight((part.Position - origin).Magnitude, settings) else 0
	if weight <= 0 then
		if original then
			part.CFrame = original
			originals[part] = nil
		end
		return
	end
	if not original then
		original = part.CFrame
		originals[part] = original
	end
	local seed = part:GetAttribute("WindSeed")
	if type(seed) ~= "number" then
		seed = 0
	end
	local rotation, offset = Wind.offsetFor(seed, now)
	part.CFrame = original * CFrame.new(offset * weight, 0, 0) * CFrame.Angles(0, 0, math.rad(rotation * weight))
end

-- Starts the sway loop once. Safe to call twice.
function Wind.start()
	if started then
		return
	end
	started = true

	local RunService = game:GetService("RunService")
	local CollectionService = game:GetService("CollectionService")
	fidelityRuntime = resolveFidelityRuntime()

	-- A part that loses its tag stops being visited, so put it back here.
	tagRemovedConnection = CollectionService:GetInstanceRemovedSignal(WIND_TAG):Connect(function(part: Instance)
		if part:IsA("BasePart") then
			local original = originals[part]
			if original and part.Parent then
				part.CFrame = original
			end
		end
		originals[part] = nil
	end)

	heartbeatConnection = RunService.Heartbeat:Connect(function(dt: number)
		accumulator += dt
		if accumulator < TICK then
			return
		end
		accumulator = 0

		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local tagged = CollectionService:GetTagged(WIND_TAG)
		local count = #tagged
		if count == 0 then
			return
		end

		local origin = camera.CFrame.Position
		local now = os.clock()
		-- Read each tick so a tier change (including one made before FidelityRuntime started) lands
		-- on the next tick; this is a table lookup, not a scan.
		local settings = tierSettings()
		for _ = 1, math.min(count, MAX_PER_TICK) do
			cursor = cursor % count + 1
			local part = tagged[cursor]
			if part:IsA("BasePart") then
				step(part, origin, now, settings)
			end
		end
	end)
end

-- Tears the loop down: disconnects both signals, restores every swayed part and resets the cursor so
-- a restart begins cleanly. A test/hot-reload helper; a normal client runs it for its whole life.
function Wind.stop()
	if tagRemovedConnection then
		tagRemovedConnection:Disconnect()
		tagRemovedConnection = nil
	end
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end
	for part, original in pairs(originals) do
		if part.Parent then
			part.CFrame = original
		end
	end
	originals = setmetatable({}, { __mode = "k" })
	started = false
	accumulator = 0
	cursor = 0
	fidelityRuntime = nil
end

function Wind.isStarted(): boolean
	return started
end

return Wind
