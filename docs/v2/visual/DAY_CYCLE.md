# Day cycle — eight phases of an Indonesian village day

Source: the designer's notes (2026-11-19), mapped onto the game. This implements V-D2: the clock
moves slowly, and golden hour is guaranteed at spawn. It's a visual and sound layer only. Phases
that change gameplay (shop hours, ronda) are parked until after Gate 1.

The cycle sits on top of the existing season × weather presets in `Config/Seasons.luau` /
`client/World/Sky.luau`. The phase decides the time, the sun and the lamps; the season and weather
still tint the sky, fog and rain. Every value below is a starting point, to be tuned with
screenshots in the look-dev corner.

## Timing (proposal, waiting for designer answer Q1)

- One in-game hour = 2 real minutes, so a full day takes 48 real minutes.
- A new server starts at 16:00 (Ashar golden hour), so the first session opens in golden hour.
- The scripted first raid at ~5:30 real minutes lands at ~18:45, right after maghrib. The
  BREAKING NEWS cutscene then plays at dusk, with lamps coming on.

## The eight phases

| # | Phase | Game hours | Light (Lighting / Atmosphere) | Lamps | Sound bed | What the player should feel |
|---|---|---|---|---|---|---|
| 1 | Dini hari | 01:00–03:30 | Very dark blue; `Brightness` low; moon; thin fog | Few: dim orange and pale-white street lamps | Crickets, a far motorbike, kentongan ronda, wall clock | Quiet, lonely, a little eerie |
| 2 | Subuh | 04:00–05:30 | Blue-purple blue hour; a thin orange line in the east; dew haze | Lamps fading out | Roosters, a sapu lidi sweeping, kitchen sounds (adzan: see Q2) | Calm, fresh, hopeful |
| 3 | Pagi | 06:00–09:30 | Warm low sun through the trees; long soft shadows; light haze | Off | Motorbikes, kids on the way to school, a bubur cart bell | Busy, alive, the day starting |
| 4 | Dhuha | 10:00–11:30 | High white sun; short shadows; crisp | Off | Tukang sayur calling, quieter streets | Calm, getting hot |
| 5 | Siang bolong | 12:00–14:30 | Sun overhead; the brightest point; slight heat-haze bloom; low saturation | Off | Fans, ice clinking in es teh, cicadas (adzan: see Q2) | Hot, lazy, nap time |
| 6 | Sore (Ashar) | 15:00–17:30 | **Golden hour**: warm, long sideways shadows, SunRays on | Off | Wind, kids playing, gorengan cart | Warm, nostalgic: **the hero look and the spawn look** |
| 7 | Maghrib | 17:45–18:30 | Fast orange → deep red → purple; Atmosphere warm-to-violet | Porch lamps turn on one by one | Traffic goes quiet; mosquito coil (adzan: see Q2) | Sacred, still, a hint of the mystical |
| 8 | Malam (Isya) | 19:00–23:30 | Dark sky, readable ground (see Q3); pools of warm lamp light | All on: warung neon, petromax, TV glow in houses | Wok on a nasi goreng cart, warkop chatter, crickets | Cozy, social, busy at the food spots |

Gaps between phases (03:30–04:00, 09:30–10:00 and so on) blend between their neighbours.

## Fit with the hook moments (`VISUAL_MASTER_PLAN.md` §4)

- **Spawn / first screenshot:** phase 6, golden hour, always.
- **Raid (M5):** the first raid lands at maghrib (phase 7), where red and blue police lights read
  best against a purple sky.
- **Rain (M6):** any phase. Rain plus maghrib or malam is the strongest clip.
- **Night pasar** (phase 8) is the natural setting for a future night-market moment, after
  Gate 1.

## Performance

- Lamps are the cost. Only lamps near the camera cast real `PointLight` shadows. Far lamps use a
  glow sprite (Billboard or Neon), with no light.
- At FidelityTier Rendah: no shadows from lamps, and at most 6 active lights.
- Phase changes tween over 20–40 real seconds, never snap. FidelityTier stays frozen during a
  phase tween, the same as during hook moments.

## Open questions for the designer

- **Q1 — Day length:** 48 real minutes (recommended), 24 or 96.
- **Q2 — Adzan audio:** see the chat answer; recommended *no adzan recording for now*.
- **Q3 — Night darkness:** readable night (recommended for phones) or realistic dark.
- **Q4 — Time changes gameplay** (warung closing at night, pasar pagi prices, ronda): park until
  after Gate 1 (recommended).
