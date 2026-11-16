-- CutsceneSequencer: a pure, clock-injected timeline player for scripted cutscenes (the sinetron raid,
-- v2 PLAN section 4). No Roblox services: it only decides WHICH shot is current and how far into it we
-- are; the camera/overlay wiring subscribes with onShot and reads current() each frame.
--
--   local seq = CutsceneSequencer.new(shots, { clock = os.clock, skippable = false })
--   seq.onShot(function(shot, index) ... end)       -- once per shot, in order, including zero-length
--   seq.onFinished(function(skipped) ... end)       -- exactly once: natural end or skip
--   seq.play()                                      -- subscribe BEFORE play (an empty list finishes inside play)
--   every frame: seq.update(clock()) or seq.step(dt)
--
-- A shot is { id = string, duration = seconds, kind = "establish"|"zoom"|"walkin"|"letter", ...params }.
-- Bad input never throws: non-table shots are dropped, a bad id becomes "shot<N>", a bad kind becomes
-- "establish", NaN/negative/infinite/non-number durations become 0, a bad dt becomes 0.
-- cancel() tears down silently: it does NOT fire onFinished (the cutscene did not complete, so the
-- "seen" flag must not be set). Listener errors are caught and warned, never break the timeline.

local CutsceneSequencer = {}

CutsceneSequencer.KINDS = { establish = true, zoom = true, walkin = true, letter = true }

local function cleanNumber(value: any): number
	if type(value) ~= "number" or value ~= value or value < 0 or value == math.huge then
		return 0
	end
	return value
end

local function cleanShots(shots: any): { any }
	local out = {}
	if type(shots) ~= "table" then
		return out
	end
	for _, raw in shots do
		if type(raw) == "table" then
			local shot = {}
			for key, value in raw do
				shot[key] = value
			end
			local index = #out + 1
			if type(shot.id) ~= "string" or shot.id == "" then
				shot.id = "shot" .. index
			end
			if type(shot.kind) ~= "string" or not CutsceneSequencer.KINDS[shot.kind] then
				shot.kind = "establish"
			end
			shot.duration = cleanNumber(shot.duration)
			table.insert(out, shot)
		end
	end
	return out
end

-- Skippable only after the first full viewing. `seen` is the client attribute RaidCutsceneSeen
-- (a completed-viewings count, or true); nil, false, 0, NaN, negatives and junk mean "not seen".
function CutsceneSequencer.skippableAfter(seen: any): boolean
	if seen == true then
		return true
	end
	return type(seen) == "number" and seen == seen and seen >= 1
end

function CutsceneSequencer.new(shots: any, opts: any?)
	local options = if type(opts) == "table" then opts else {}
	local list = cleanShots(shots)
	local skippable = options.skippable == true
	local clock = if type(options.clock) == "function" then options.clock else os.clock

	local state = "idle" -- idle | playing | finished | cancelled
	local index = 0
	local elapsed = 0
	local wasSkipped = false
	local lastNow: number? = nil
	local stepping = false
	local shotListeners: { (any, number) -> () } = {}
	local finishListeners: { (boolean) -> () } = {}

	local seq = {}

	local function fire(listeners: { any }, ...)
		local snapshot = table.clone(listeners)
		for _, listener in snapshot do
			local ok, err = pcall(listener, ...)
			if not ok then
				warn("CutsceneSequencer listener failed: " .. tostring(err))
			end
		end
	end

	local function finish(skipped: boolean)
		if state ~= "playing" then
			return
		end
		state = "finished"
		wasSkipped = skipped
		fire(finishListeners, skipped)
	end

	local function enter(newIndex: number)
		index = newIndex
		elapsed = 0
		fire(shotListeners, list[newIndex], newIndex)
	end

	local function advance(dt: number)
		if stepping then
			return
		end
		stepping = true
		elapsed += dt
		while state == "playing" do
			local shot = list[index]
			if elapsed < shot.duration then
				break
			end
			local carry = elapsed - shot.duration
			if index >= #list then
				elapsed = shot.duration
				finish(false)
				break
			end
			enter(index + 1)
			if state == "playing" then
				elapsed = carry
			end
		end
		stepping = false
	end

	function seq.play()
		if state ~= "idle" then
			return
		end
		state = "playing"
		lastNow = cleanNumber(clock())
		if #list == 0 then
			finish(false)
			return
		end
		stepping = true -- a listener calling step() during the first onShot must not advance
		enter(1)
		stepping = false
		if state == "playing" then
			advance(0) -- lets leading zero-length shots pass at once
		end
	end

	function seq.step(dt: any)
		if state ~= "playing" then
			return
		end
		advance(cleanNumber(dt))
	end

	-- Clock-driven variant: dt is the gap since the previous update (or since play). A clock that
	-- runs backwards counts as no time passing.
	function seq.update(now: any?)
		if state ~= "playing" then
			return
		end
		local value = if now == nil then clock() else now
		if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
			return
		end
		local previous = lastNow or value
		lastNow = value
		advance(cleanNumber(value - previous))
	end

	-- Returns the current (cleaned) shot and its progress 0..1. Before play: nil, 0. After finish: nil, 1.
	function seq.current(): (any?, number)
		if state == "playing" then
			local shot = list[index]
			local progress = 1
			if shot.duration > 0 then
				progress = math.clamp(elapsed / shot.duration, 0, 1)
			end
			return shot, progress
		end
		if state == "finished" then
			return nil, 1
		end
		return nil, 0
	end

	function seq.skip(): boolean
		if not skippable or state ~= "playing" then
			return false
		end
		finish(true)
		return true
	end

	function seq.cancel()
		if state == "idle" or state == "playing" then
			state = "cancelled"
		end
	end

	function seq.onShot(callback: (any, number) -> ())
		table.insert(shotListeners, callback)
		return function()
			local at = table.find(shotListeners, callback)
			if at then
				table.remove(shotListeners, at)
			end
		end
	end

	function seq.onFinished(callback: (boolean) -> ())
		table.insert(finishListeners, callback)
		return function()
			local at = table.find(finishListeners, callback)
			if at then
				table.remove(finishListeners, at)
			end
		end
	end

	function seq.isPlaying(): boolean
		return state == "playing"
	end

	function seq.isFinished(): boolean
		return state == "finished"
	end

	function seq.wasSkipped(): boolean
		return wasSkipped
	end

	function seq.isSkippable(): boolean
		return skippable
	end

	function seq.shotCount(): number
		return #list
	end

	function seq.totalDuration(): number
		local total = 0
		for _, shot in list do
			total += shot.duration
		end
		return total
	end

	return seq
end

return CutsceneSequencer
