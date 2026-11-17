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

-- Real world anchors for the cutscene's focus labels (Track F). Values are the MapSpec hub
-- centres (src/server/World/MapSpec.luau HUBS) plus the road cross, in world studs, as plain
-- {x, y, z} tables so this stays pure and Lune-testable (no Vector3 here). A shot's `focus` names
-- one of these; the client looks at it instead of framing the local player. `nil` means "no real
-- anchor yet" and the client keeps its player-relative fallback. The kades ("kepala desa") sits at
-- Rumah Pak RT; the police chief at Pos Polisi; the "road" focus aims down the plaza road cross.
-- Framing quality is a designer judgement (visual plan §8) — these are starting coordinates.
RaidCutscene.focusAnchors = {
	kades = { x = 68, y = 3.4, z = 68 }, -- Rumah Pak RT table hub (MapSpec HUBS.pakrt)
	police_chief = { x = -68, y = 3.4, z = 68 }, -- Pos Polisi desk hub (MapSpec HUBS.polisi)
	road = { x = 0, y = 2, z = -28 }, -- plaza road cross, just north of the UKUR board
}

-- Pure resolver: the anchor for a focus label, or nil (no anchor -> caller's fallback).
function RaidCutscene.anchorFor(focus: any): { x: number, y: number, z: number }?
	if type(focus) ~= "string" then
		return nil
	end
	return RaidCutscene.focusAnchors[focus]
end

function RaidCutscene.totalDuration(): number
	local total = 0
	for _, shot in RaidCutscene.shots do
		total += shot.duration
	end
	return total
end

return RaidCutscene
