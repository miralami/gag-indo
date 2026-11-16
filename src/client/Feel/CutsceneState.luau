-- CutsceneState: the pure decisions behind the raid cutscene wiring (RaidOverlay can't load under
-- Lune, so everything that is a decision rather than an Instance call lives here and is specced).
--
--   CutsceneState.uiFor(kind, previous)  which overlay pieces follow which shot
--   CutsceneState.nextSeen(current)      the RaidCutsceneSeen value after one more full viewing
--   CutsceneState.newCameraRestore()     remembers the camera as it was before the first shot
--   CutsceneState.focusOffset(focus)     deterministic yaw (degrees) so shots read differently

local CutsceneState = {}

-- UI flags for the shot that just started. `previous` is the flags from the shot before (or nil at
-- the start). Lower third ("BREAKING NEWS"): off for establish, on from the first zoom through the
-- walk-in, off again when the letter lands. The letter card shows from the letter shot onward.
function CutsceneState.uiFor(kind: any, previous: any?)
	local before = if type(previous) == "table" then previous else {}
	local lowerThird = before.lowerThird == true
	local letter = before.letter == true
	if kind == "zoom" then
		lowerThird = true
	elseif kind == "letter" then
		lowerThird = false
		letter = true
	end
	return { lowerThird = lowerThird, letter = letter }
end

-- UI flags once the cutscene is over (finished, skipped or cancelled): no lower third, letter card
-- and choices own the screen.
function CutsceneState.endedUi()
	return { lowerThird = false, letter = true }
end

-- Value for the RaidCutsceneSeen attribute after one more completed viewing. `true` counts as one
-- viewing already; nil, negatives, NaN, infinity and junk start from zero.
function CutsceneState.nextSeen(current: any): number
	if current == true then
		return 2
	end
	if type(current) == "number" and current == current and current >= 0 and current < math.huge then
		return math.floor(current) + 1
	end
	return 1
end

-- Camera restore bookkeeping. capture() keeps only the FIRST capture until release(), so a second
-- raid event or a re-entrant start can never overwrite the real pre-cutscene camera with the
-- Scriptable one. release() hands the saved state back once and forgets it.
function CutsceneState.newCameraRestore()
	local saved: { cameraType: any, fov: any }? = nil
	local restore = {}

	function restore.capture(cameraType: any, fov: any): boolean
		if saved then
			return false
		end
		saved = { cameraType = cameraType, fov = fov }
		return true
	end

	function restore.isCaptured(): boolean
		return saved ~= nil
	end

	function restore.release(): { cameraType: any, fov: any }?
		local out = saved
		saved = nil
		return out
	end

	return restore
end

local FOCUS_YAW = { plot = 0, player = 0, kades = -18, police_chief = 18, road = 0 }

function CutsceneState.focusOffset(focus: any): number
	return FOCUS_YAW[focus] or 0
end

return CutsceneState
