# Day cycle — eight phases of an Indonesian village day

Source: the designer's notes (2026-11-19), mapped onto the game. This implements V-D2: the clock
moves slowly, and golden hour is guaranteed at spawn. It's a visual and sound layer only. Phases
that change gameplay (shop hours, ronda) are parked until after Gate 1.

The cycle sits on top of the existing season × weather presets in `Config/Seasons.luau` /
`client/World/Sky.luau`. The phase decides the time, the sun and the lamps; the season and weather
still tint the sky, fog and rain. Every value below is a starting point, to be tuned with
screenshots in the look-dev corner.

## Timing (designer, 2026-11-19)

- One in-game hour = 1 real minute, so a full day takes 24 real minutes (Q1).
- A new server starts at 16:00 (Ashar golden hour), so the first session opens in golden hour.
- Maghrib arrives about 2 real minutes in, and night by about 3 minutes. The scripted first raid
  at ~5:30 real minutes therefore lands at night (~21:30): police lights and lit warungs against
  a dark sky. Golden hour at spawn wins over a maghrib raid, by V-D2.

## The eight phases

| # | Phase | Game hours | Light (Lighting / Atmosphere) | Lamps | Sound bed | What the player should feel |
|---|---|---|---|---|---|---|
| 1 | Dini hari | 01:00–03:30 | Very dark blue; `Brightness` low; moon; thin fog | Few: dim orange and pale-white street lamps | Crickets, a far motorbike, kentongan ronda, wall clock | Quiet, lonely, a little eerie |
| 2 | Subuh | 04:00–05:30 | Blue-purple blue hour; a thin orange line in the east; dew haze | Lamps fading out | Roosters, a sapu lidi sweeping, kitchen sounds (soft adzan, see Q2) | Calm, fresh, hopeful |
| 3 | Pagi | 06:00–09:30 | Warm low sun through the trees; long soft shadows; light haze | Off | Motorbikes, kids on the way to school, a bubur cart bell | Busy, alive, the day starting |
| 4 | Dhuha | 10:00–11:30 | High white sun; short shadows; crisp | Off | Tukang sayur calling, quieter streets | Calm, getting hot |
| 5 | Siang bolong | 12:00–14:30 | Sun overhead; the brightest point; slight heat-haze bloom; low saturation | Off | Fans, ice clinking in es teh, cicadas (soft adzan, see Q2) | Hot, lazy, nap time |
| 6 | Sore (Ashar) | 15:00–17:30 | **Golden hour**: warm, long sideways shadows, SunRays on | Off | Wind, kids playing, gorengan cart | Warm, nostalgic: **the hero look and the spawn look** |
| 7 | Maghrib | 17:45–18:30 | Fast orange → deep red → purple; Atmosphere warm-to-violet | Porch lamps turn on one by one | Traffic goes quiet; mosquito coil (soft adzan, see Q2) | Sacred, still, a hint of the mystical |
| 8 | Malam (Isya) | 19:00–23:30 | Dark sky, readable ground (see Q3); pools of warm lamp light | All on: warung neon, petromax, TV glow in houses | Wok on a nasi goreng cart, warkop chatter, crickets | Cozy, social, busy at the food spots |

Gaps between phases (03:30–04:00, 09:30–10:00 and so on) blend between their neighbours.

## Documented numeric limits (item 89)

Established for the OFF-BY-DEFAULT `day_cycle_r8` candidate (`Shared.ModelMapDayCycleR8`); the
shipping table and these limits are unchanged by the candidate.

- **Luminance** = Rec.709 `0.2126*R + 0.7152*G + 0.0722*B` on 0–255 channel values. Phase colours
  are `Color3` (0–1 channels); multiply by 255 first.
- **Sun-vs-ambient ratio** = `luminance(colorShiftTop) / luminance(ambient)`. At 16:00 the spawn
  sits inside Sore at alpha 0, so the pure phase values are used. The tuned 16:00 ratio must be at
  least **20% higher** than the original table's; Lune baseline: base 2.160825, tuned 2.705297
  (+25.20%).
- **Documented phase-jump limit** = `PHASE_JUMP_FACTOR` (1.25) × the ORIGINAL table's own largest
  adjacent-channel jump. A jump is the max absolute delta over colour channels (ambient,
  outdoorAmbient, colorShiftTop, colorShiftBottom, tint, each channel /255) and scalars
  (brightnessMultiplier, fogEndMultiplier, saturationDelta, sunRaysDelta, lampLevel), comparing
  each adjacent phase pair in clock order including the malam → dini_hari wrap. Original max
  0.623529; documented limit 0.779412. The tuned table must stay at or under this limit — 25%
  headroom over the original, so a real snap is caught without weakening the check.
- Tone changes still tween over **20–40 real seconds, never snap** (see Performance below).
- **Maghrib values are fixed** and must remain field-for-field identical to the original table;
  `DAY_MAGHRIB_UNCHANGED` checks this.
- **ShadowSoftness** ships at 0.3 (`client/World/Sky.luau`); the tuned Sore phase sets 0.45, other
  phases keep 0.3. The tuned Sore also lowers the sun cue by 0.75 game hours (`sunClockOffset`
  -0.75: 16:00 reads as 15:15) for a lower, more directional sun.

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

## Designer answers (2026-11-19)

- **Q1 — Day length:** 24 real minutes.
- **Q2 — Adzan:** yes, soft and distant, with a player setting to turn it on or off. Default on,
  at low volume, in the music/ambience SoundGroup. Ayam, bedug, kentongan and jangkrik play as
  normal. Two guards keep it respectful:
  - Never play adzan during a satire moment (raid cutscene, cheat, debt collector); duck it or
    skip it.
  - Use only a licensed recording whose ID and licence are in `ASSET_MANIFEST.md`.
  The setting's label goes in `Strings.luau` (id + en).
- **Q3 — Night:** readable night: dark blue, with the ground and paths still clear on a phone.
- **Q4 — Gameplay effects of time** (shop hours, pasar pagi, ronda): after Gate 1.
