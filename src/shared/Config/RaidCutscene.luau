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

function RaidCutscene.totalDuration(): number
	local total = 0
	for _, shot in RaidCutscene.shots do
		total += shot.duration
	end
	return total
end

return RaidCutscene
