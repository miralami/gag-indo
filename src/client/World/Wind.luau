-- Wind: a gentle sway for foliage tagged WindShake (ART.md section 9; research tracker "wind on
-- foliage via a tag, near the camera only"). Client only.
-- Only tagged parts within the fidelity tier's foliageSwayRange of the camera move, fading out toward its edge. Each one stores its original CFrame on
-- first sight and is written as original * offset, so nothing drifts. Parts that leave range, or
-- that are no longer in the game, are put back. Anchored parts only. No tweens, no new instances.
-- The loop runs at about 20 Hz and touches at most MAX_PER_TICK parts per tick.

local TierScale = require(script.Parent.Parent.Feel.TierScale)

local Wind = {}

local TICK = 0.05 -- about 20 Hz
local RANGE = 50 -- fallback only; the live range is the fidelity tier's foliageSwayRange
local MAX_PER_TICK = 40
local MAX_ROTATION = 3 -- degrees, about the Z axis
local MAX_OFFSET = 0.25 -- studs, along X
local SWAY_SPEED = 0.9 -- radians per second for the main sway
local FLUTTER_SPEED = 0.37 -- a slower second sine so the motion never looks mechanical
local WIND_TAG = "WindShake"

local function tierSettings(): any
	local ok, settings = pcall(function()
		return require(script.Parent.Parent.Feel.FidelityRuntime).settings()
	end)
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

	-- A part that loses its tag stops being visited, so put it back here.
	CollectionService:GetInstanceRemovedSignal(WIND_TAG):Connect(function(part: Instance)
		if part:IsA("BasePart") then
			local original = originals[part]
			if original and part.Parent then
				part.CFrame = original
			end
		end
		originals[part] = nil
	end)

	RunService.Heartbeat:Connect(function(dt: number)
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

return Wind
