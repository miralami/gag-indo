-- NpcWalk: the shared walk loop for anchored, PivotTo-driven world movers (police NPCs and the
-- debt-collector marker). Dependency-free on purpose: neither NpcFactory (which pulls in Map/Props)
-- nor DebtCollector (which pulls in PlotService/Props) should have to require the other just to
-- move something. Work-queue item 18 adds the three robustness guarantees on top of a plain walk:
--
--   * stuck detection  — if the mover stops advancing for STUCK_LIMIT steps, stop walking early;
--   * timeout          — cap total travel at TIMEOUT_FACTOR x expected duration (+ a floor);
--   * teleport fallback — on stuck OR timeout, pivot straight to the goal so the mover ALWAYS
--                         reaches the plot.
--
-- A cancelled walk (walkToken changed) or an unparented mover returns false WITHOUT teleporting.
-- Yields via task.wait. Only needs the `Vector3`, `CFrame` and `task` globals, so it runs the same
-- in Studio and in the Lune harness.

local NpcWalk = {}

local STEP_SECONDS = 0.05
local STUCK_EPSILON = 0.05   -- less than this much progress in one step counts as stalled
local STUCK_LIMIT = 12       -- consecutive stalled steps (~0.6 s) before the fallback
local TIMEOUT_FACTOR = 2
local TIMEOUT_FLOOR = 3      -- seconds
local ARRIVE_EPSILON = 0.5
local DEFAULT_SPEED = 14

local function positionOf(pivot)
	local p = pivot and pivot.Position
	if p == nil then
		return nil
	end
	-- A Studio position is a native `vector` (type() == "vector", not "table"/"userdata"); the
	-- Lune harness uses a plain table. Reading X/Y/Z inside pcall accepts every representation.
	local ok, x, y, z = pcall(function()
		return p.X, p.Y, p.Z
	end)
	if not ok or type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
		return nil
	end
	return { X = x, Y = y, Z = z }
end

local function dist(a, b)
	local dx, dy, dz = b.X - a.X, b.Y - a.Y, b.Z - a.Z
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function goalCFrame(x, y, z, face)
	return CFrame.new(Vector3.new(x, y, z)) * face
end

-- Yields. `host` is anything exposing GetPivot()/PivotTo() (a Model or a Part).
-- `isCancelled` is an optional callback; when it returns true the walk aborts without teleporting.
-- Returns true on arrival or fallback, false when cancelled/unparented/unusable.
function NpcWalk.walkTo(host, target, speed, isCancelled)
	if type(host) ~= "table" and type(host) ~= "userdata" then
		return false
	end
	if type(host.GetPivot) ~= "function" or type(host.PivotTo) ~= "function" then
		-- Fake parts (e.g. the debt-collector failure spec) have no pivot API: degrade quietly.
		return false
	end
	if target == nil or type(target.X) ~= "number" or type(target.Z) ~= "number" then
		return false
	end

	local start = positionOf(host:GetPivot())
	if not start then
		return false
	end
	local gx, gz = target.X, target.Z
	local gy = start.Y
	local total = dist(start, { X = gx, Y = gy, Z = gz })
	if total < ARRIVE_EPSILON then
		return true
	end

	local speedValue = (type(speed) == "number" and speed > 0) and speed or DEFAULT_SPEED
	local steps = math.max(1, math.ceil((total / speedValue) / STEP_SECONDS))
	local budget = math.max(steps * TIMEOUT_FACTOR, math.ceil(TIMEOUT_FLOOR / STEP_SECONDS))

	local dx, dz = gx - start.X, gz - start.Z
	local face = CFrame.lookAt(Vector3.new(0, 0, 0), Vector3.new(dx, 0, dz))
	local last = start
	local stalled = 0

	for i = 1, budget do
		if (isCancelled and isCancelled()) or host.Parent == nil then
			return false
		end
		local alpha = math.min(1, i / steps)
		local bob = math.abs(math.sin(i * 0.9)) * 0.18
		host:PivotTo(goalCFrame(start.X + dx * alpha, gy + bob, start.Z + dz * alpha, face))
		task.wait(STEP_SECONDS)

		local now = positionOf(host:GetPivot())
		if now and dist(now, { X = gx, Y = gy, Z = gz }) < ARRIVE_EPSILON then
			-- Snap exactly onto the goal so every success path ends at the same point.
			host:PivotTo(goalCFrame(gx, gy, gz, face))
			return true
		end
		if now and dist(now, last) < STUCK_EPSILON then
			stalled += 1
		else
			stalled = 0
		end
		last = now or last
		if stalled >= STUCK_LIMIT or i >= budget then
			-- Teleport fallback: force the mover onto the goal so it always reaches the plot.
			host:PivotTo(goalCFrame(gx, gy, gz, face))
			return true
		end
	end
	return true
end

return NpcWalk
