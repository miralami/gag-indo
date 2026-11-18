-- Sinetron raid cutscene timeline (v2 PLAN sections 2 and 4: establishing shot, three zooms, police
-- walk-in, a letter slapped on screen with the choices). Pure data, played by
-- client/Feel/CutsceneSequencer. No player-facing text here: the "BREAKING NEWS" lower third and the
-- letter copy live in Strings and RaidOverlay.
--
-- Shot kinds: "establish" | "zoom" | "walkin" | "letter". Everything besides id/kind/duration is a
-- free parameter for the camera/overlay wiring (seconds, studs, degrees). Starting points for the
-- designer to tune. Total is about 7 s; the letter shot ends where the RaidOverlay choice UI takes
-- over, so its `holdsChoices` flag means "leave the choices up when this shot ends".

local RaidCutscene = {}

-- Client attribute set on the local Player once the cutscene has finished playing to the end.
-- The value is the number of completed viewings. Not saved: it resets each session.
RaidCutscene.seenAttribute = "RaidCutsceneSeen"

RaidCutscene.shots = {
	{ id = "establish", kind = "establish", duration = 1.6, fov = 70, focus = "plot", dolly = -6 },
	{ id = "zoom1", kind = "zoom", duration = 0.8, fov = 42, focus = "player" },
	{ id = "zoom2", kind = "zoom", duration = 0.8, fov = 34, focus = "kades" },
	{ id = "zoom3", kind = "zoom", duration = 0.8, fov = 26, focus = "police_chief" },
	{ id = "walkin", kind = "walkin", duration = 1.8, fov = 60, focus = "road", lights = true },
	{ id = "letter", kind = "letter", duration = 1.2, slam = true, holdsChoices = true },
}

RaidCutscene.kinds = { "establish", "zoom", "walkin", "letter" }

-- Real world anchors for the cutscene's focus labels (Track F). Values are the NPC front spots
-- (src/server/World/MapSpec.luau NPC_SPOTS) plus the road cross, in world studs, as plain
-- {x, y, z} tables so this stays pure and Lune-testable (no Vector3 here). A shot's `focus` names
-- one of these; the client looks at it instead of framing the local player. `nil` means "no real
-- anchor yet" and the client keeps its player-relative fallback. The NPCs stand on the -z front of
-- their buildings (Pak RT 68/47, Polisi -68/42); the anchor is at head height (~5.7 above the feet,
-- NpcFactory) so the camera frames the person, not the building roof behind them. The "road" focus
-- aims down the plaza road cross. Framing quality is a designer judgement (visual plan §8).
RaidCutscene.focusAnchors = {
	kades = { x = 68, y = 5.7, z = 47 }, -- Pak RT NPC front spot (MapSpec.NPC_SPOTS pakrt), head height
	police_chief = { x = -68, y = 5.7, z = 42 }, -- Polisi NPC front spot (MapSpec.NPC_SPOTS polisi), head height
	road = { x = 0, y = 2, z = -28 }, -- plaza road cross, just north of the UKUR board
}

-- Pure resolver: the anchor for a focus label, or nil (no anchor -> caller's fallback).
function RaidCutscene.anchorFor(focus: any): { x: number, y: number, z: number }?
	if type(focus) ~= "string" then
		return nil
	end
	return RaidCutscene.focusAnchors[focus]
end

-- Pure camera geometry for an anchored shot: returns { eye, target } as plain {x,y,z} tables so it
-- is Lune-testable (no Vector3/CFrame). The client converts them to Vector3 and assigns
-- CFrame.lookAt(eye, target). The eye stands `standOff` studs toward -z from the anchor (the same
-- side the NPC fronts) and yaws around the anchor by `yawDegrees` — matching the client's old
-- `yaw * Vector3.new(0, 0, -standOff)`. Target is the anchor itself (head height).
-- Returns nil when the focus has no anchor, the shot kind has no camera ("letter", "establish"),
-- or the shot is not a table, so the caller keeps its player-relative fallback.
function RaidCutscene.cameraFor(shot: any, progress: number?, yawDegrees: number?): { eye: { x: number, y: number, z: number }, target: { x: number, y: number, z: number } }?
	if type(shot) ~= "table" then
		return nil
	end
	local anchor = RaidCutscene.anchorFor(shot.focus)
	if not anchor then
		return nil
	end
	local standOff: number
	local lift: number
	if shot.kind == "zoom" then
		-- 14, not 18: a Studio raycast against the built world (2026-11-19) found that at standOff
		-- 16+ the police_chief shot's eye→head line passes through Tree_12.Canopy_2 (near -68/28),
		-- while 10/12/14 are clear. The kades shot is clear at every standoff. 14 keeps the most
		-- distance while giving both NPC shots an unobstructed line of sight.
		standOff, lift = 14, 5
	elseif shot.kind == "walkin" then
		local p = if type(progress) == "number" then progress else 0
		if p < 0 then
			p = 0
		elseif p > 1 then
			p = 1
		end
		standOff, lift = 40 - 22 * p, 4
	else
		return nil
	end
	local yaw = math.rad(if type(yawDegrees) == "number" then yawDegrees else 0)
	-- Roblox Y-rotation of (0, 0, -standOff): x' = -d*sin(yaw), z' = -d*cos(yaw).
	local dx = -standOff * math.sin(yaw)
	local dz = -standOff * math.cos(yaw)
	return {
		eye = { x = anchor.x + dx, y = anchor.y + lift, z = anchor.z + dz },
		target = { x = anchor.x, y = anchor.y, z = anchor.z },
	}
end

function RaidCutscene.totalDuration(): number
	local total = 0
	for _, shot in RaidCutscene.shots do
		total += shot.duration
	end
	return total
end

return RaidCutscene
