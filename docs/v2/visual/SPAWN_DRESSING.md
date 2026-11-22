# Spawn dressing — plan only (WORK_QUEUE section H item 32)

Status: **planning deliverable, 2026-11-20. Nothing here is approved, graded or shipped.** Dressing
happens only after item 31's `*_r4` model families pass designer review. No visual verdict is claimed
by this document; no asset ID, product ID or UserId is invented or recorded here. Real IDs belong in
`docs/v2/visual/art/ASSET_MANIFEST.md` after ingest.

This note covers the prop clusters around the spawn view, the r4 candidate (or **Designer builds**
brief) that fills each one, a per-fidelity-tier instance / triangle budget, and three ambient-life
ideas that all need a later design verdict.

## 1. Real geometry (code authority, not the old map image)

Numeric authority: `src/server/World/MapSpec.luau`. Design intent: `docs/v2/visual/art/MAP_SPEC.md`
(section 0 supersedes sections 1–11 with scale **S = 2**). Conventions: studs, X = east, **-Z = north**,
ground plane Y = 0.5.

| Thing | Real value | Source |
|---|---|---|
| Spawn | `(0, GROUND_Y = 0.5, 28)`, `size = 8`, `lookZ = -1` (faces north / -Z) | `MapSpec.luau:203` (`MapSpec.SPAWN`) |
| Central plaza | centre `(0, 0)`, footprint `96 x 84` → `x -48..48`, `z -42..42` | `MapSpec.luau:192` (`MapSpec.PLAZA`) |
| Pasar | centre `(-64, -64)`, `64 x 52`, `yaw 0` → `x -96..-32`, `z -90..-38` | `MapSpec.luau:84–89` |
| Warung | centre `(68, -68)`, `52 x 44`, `yaw 0` → `x 42..94`, `z -90..-46` | `MapSpec.luau:98–105` |
| Pos Polisi | centre `(-68, 68)`, `48 x 44`, `yaw 180` → `x -92..-44`, `z 46..90` | `MapSpec.luau:113–117` |
| Rumah Pak RT | centre `(68, 68)`, `48 x 34`, `yaw 180` → `x 44..92`, `z 51..85` | `MapSpec.luau:119–124` |
| Pos Ronda | centre `(-108, 0)`, `44 x 40`, `yaw 90`; watchtower `(-112, -34)`, 36 tall | `MapSpec.luau:107–111`, `:211` |
| Lapangan Warga | centre `(0, 96)`, `72 x 56` | `MapSpec.luau:193` |
| North road | 28 wide (`x -14..14`) from plaza edge `z -42` out to `r = 136` | `MapSpec.luau:223–246`, `:250–257` |
| Sawah terraces | `z -312..-376`, tops `4.5 / 8.5 / 12.5 / 16.5` | `MapSpec.luau:409–415` |
| Cabai-price board | `(-28, -44)`, already built | `MapSpec.luau:189` (`MapSpec.UKUR_BOARD`) |

Spawn frame: standing at `(0, 0.5, 28)` facing -Z, the player looks across the plaza centre
`(0, 0)`, down the 28-wide north road, with the **Pasar roof on the left** and the **Warung on the
right** (`MAP_SPEC.md` §6). Both front hubs are about 118 studs diagonally from spawn, i.e. midground.
Pos Polisi and Rumah Pak RT sit at `z = 68` — **behind** the spawn camera; their dressing is a
turn-around/secondary cluster, not part of the first frame. `MAP_SPEC.md` §6 also says "never a tree
trunk" in the first frame, so keep the `x -14..14` north-road corridor clear.

## 2. Prop clusters and their r4 filler

The r4 family lists are WORK_QUEUE item 31: `buildings_r4` (rumah panggung, kandang ayam, gudang,
warung), `vegetation_r4` (kelapa, pisang, bambu, mangga, shrubs, padi three stages), `props_r4`
(gerobak, sumur, lapak, pagar bambu, alat tani, karung, jemuran), `npcs_r4` (petani caping,
pedagang, petani wanita, tukang peci, polisi). "Designer builds" means ladder step 3: a short brief
per the WORK_QUEUE "Designer builds" list; no script-built primitive placeholders (round-3 verdict).

| # | Cluster (real footprint / anchor) | What lives there | r4 filler | Gap → **Designer builds** brief |
|---|---|---|---|---|
| A | **Spawn apron / plaza edge**, plaza `x -48..48, z -42..42`; spawn at `(0, 28)` | Low clutter on plaza edges only; keep the north-road corridor `x -14..14` and the sightline to Balai/terraces clear | `props_r4`: `pagar bambu` short runs, `jemuran`, `karung`; `vegetation_r4`: `shrubs` | Potted plants (`pot`), and a notice-board/small-tree treatment — `MAP_SPEC.md` §3 already names "notice board, small tree" for the plaza, so **do not duplicate**; brief only the pots |
| B | **Warung frontage**, `x 42..94, z -90..-46`, door south toward plaza | Gerobak by the door, karung stack, jemuran, a well, stall goods; story gag "motor without plate behind the Warung" (`MAP_SPEC.md` §8) | `buildings_r4`: `warung`; `props_r4`: `gerobak`, `karung`, `jemuran`, `sumur`, `lapak`; `npcs_r4`: `pedagang`, `tukang peci` | Lantern prop (the r3 `day_cycle` lamps are light sources, not a dressed lantern model); the plate-less motor; loose "warung clutter" (galon, kursi plastik) — all from `MAP_SPEC.md` §8, none in the item-31 family lists |
| C | **Pasar frontage**, `x -96..-32, z -90..-38`, door SE into plaza | Lapak row, sacks, tools, villagers; the `UKUR_BOARD` at `(-28, -44)` already exists | `props_r4`: `lapak`, `karung`, `alat tani`, `pagar bambu`; `npcs_r4`: `pedagang`, `petani wanita`; `vegetation_r4`: `pisang` at the edge | The Pasar stalls themselves: `pasar` is **not** in item 31's `buildings_r4` list — brief a stall/lapak-row building or reuse `props_r4.lapak` as the stand-in; spanduk and kabel/galon dressing from `MAP_SPEC.md` §8 |
| D | **North-road / pematang edge**, road `x -14..14` to `z -136`; terraces `z -312..-376` | Distant padi and bund edges at the end of the view corridor — mood, not touchable foreground | `vegetation_r4`: `padi` bibit/tumbuh/siap and `shrubs`; `props_r4`: `pagar bambu` at the road shoulder | `pematang` bund edge: terrain/bund geometry, **not** an r4 model family — brief a low bund-edge module only if the designer wants it near the plaza; see mismatch M4 |
| E | **Secondary flank (behind spawn)**, Polisi `x -92..-44, z 46..90`, Pak RT `x 44..92, z 51..85`, Ronda `(-108, 0)` + tower `(-112, -34)` | Dress only when the camera turns; do not charge it to the spawn-view budget | `npcs_r4`: `polisi`, `petani caping`; `props_r4`: `sumur`; `vegetation_r4`: `kelapa`, `mangga`, `bambu`, `pisang` | None for the models; houses here are existing hubs, not r4 buildings |
| F | **Ambient props (no fixed slot)** — warung/pasar margins | `ayam` (chickens), `sepeda`, swaying `jemuran` | `props_r4`: `jemuran`; `npcs_r4` are people, not animals | `ayam` and `sepeda` are **not** in any item-31 family — separate **Designer builds** briefs; smoke/laundry motion is an ambient-life verdict, not a model |

Rule for every cluster: r4 candidates are **off by default** and stay so until a designer says yes
(section 5). A "Designer builds" row is a brief, not an approved asset, and still enters through the
D15 ladder before any shipping change.

## 3. Instance / triangle budget per fidelity tier

Source numbers, cited not invented:

- `VISUAL_MASTER_PLAN.md` §6 "Budgets": **under ~500 draw calls and ~500k triangles in the spawn
  view at Sedang**; textures **512 by default, 1024 only for terrain-scale and landmark surfaces**;
  **at most one live `Highlight`**; every particle emitter pooled with a hard cap per tier. These are
  flagged in that file as "project numbers until measured; replace with measurements in V0" — the
  V0.2 phone fps cost table is still a designer task, and item 16 is the budget/soak gate.
- `VISUAL_MASTER_PLAN.md` L3.5: **~2,000 triangles per kit piece, up to 8,000 per landmark**, shared
  material set and shared mesh IDs for batching.
- `MAP_SPEC.md` §8 / `CANDIDATES.md` `hubprops` row: **8–12 props per hub**. `MAP_SPEC.md` §9:
  instancing and shared textures, 60 fps on mid-range Android.
- `VISUAL_MASTER_PLAN.md` §6 tier table: ambient life "smoke and wind only / most, half counts /
  all"; particles 40% / 70% / 100%; local lights none (emissive only) / key lights, no shadows /
  all with hero shadows; small-part shadows off / off beyond 60 studs / on; foliage sway 25 / 50 /
  80 studs.

Provisional allocation (a planning slice of the Sedang cap, **not** a measurement): three in-frame
dressing zones — plaza apron (A), Warung (B), Pasar (C). Cluster D is distant backdrop; E is outside
the first frame; F is ambient life. At 8–12 props/hub, A+B+C ≈ **24–36 props**; add two landmarks
(Warung, Pasar) at ≤8,000 tris each.

| Tier | Dressing instances in spawn view | Dressing triangles | Kept from the clusters | Tier rules applied (all from `VISUAL_MASTER_PLAN.md` §6) |
|---|---|---|---|---|
| **Rendah** | **≤ 50** (~half the Sedang set) | **≤ 50k** (~10% of the 500k cap): ~12–16 kit pieces × 2,000 = 24–32k + ≤2 landmarks × 8,000 = 16k → 40–48k, headroom to 50k | Silhouette props only: `warung`, `gerobak`, `pagar bambu`, `karung`. No chickens or laundry motion | Ambient = smoke + wind only; no local lights (emissive only); particles 40%; sway 25 studs; small-part shadows off |
| **Sedang** | **≤ 100** (20% of the ~500 draw-call cap): 3 zones × 8–12 props = 24–36, plus plaza clutter and 2 landmarks, each ideally one instanced mesh | **≤ 100k** (20% of the 500k cap): 24–36 × 2,000 = 48–72k + 16k landmarks = 64–88k, headroom to 100k | Full 8–12 props/hub plus plaza-edge dressing; no duplicate notice board/tree | Ambient = most, half counts; key lights, no shadows; particles 70%; sway 50 studs; small-part shadows off beyond 60 studs |
| **Tinggi** | **≤ 150** (full 3 zones at 12/hub plus a few secondary flank props) | **≤ 150k** (30% of the 500k cap): 36 × 2,000 = 72k + landmarks + extra dressing | All A–D props plus ambient life from section 4 | Ambient = all; all lights, shadows on heroes; particles 100%; sway 80 studs; small-part shadows on |

Every tier stays below the global ~500 draw / ~500k triangle cap; that cap still governs, including
Terrain, the existing hubs and the r4 families themselves. Textures stay 512 unless a terrain-scale
or landmark surface needs 1024. No more than one live `Highlight` (V-D1 retires the world contour;
do not plan ink outlines around realistic r4 props). This table is replaced by live numbers from the
item-16 budget/soak at each tier on designer hardware — this document performs no measurement.

## 4. Ambient-life ideas (need later design / verdict)

All three follow `VISUAL_MASTER_PLAN.md` V-L5.5: client-side, pooled, range-culled and scaled by
fidelity tier. None is approved here; each needs the designer's yes/no after the models pass review.

1. **Chickens (`ayam`) wandering the Warung and Pasar margins.** Idle peck and a scatter when the
   player runs at them (`V-L5.2`). Needs a **Designer builds** brief — `ayam` is not in any item-31
   r4 family, and no chicken asset ID exists in the repo. Rendah drops the motion (ambient =
   smoke and wind only); Sedang/Tinggi pool and range-cull them. Motion curve and scatter radius are
   a design/verdict call.
2. **Smoke from the Warung.** A thin sun-lit column off the Warung at `(68, -68)` — `V-L5.1`
   "kitchen smoke", and M1's spawn shot explicitly needs "smoke from the warung"
   (`VISUAL_MASTER_PLAN.md` §4). Depends on L7.1's authored particle texture atlas (item 14 is
   blocked) and on the `day_cycle` 16:00 grade the designer marked "yes, tune". No particle asset is
   approved; smoke colour, density and drift need a later design/verdict.
3. **Swaying laundry (`jemuran`).** Hang `props_r4.jemuran` near the Warung and Pasar frontages and
   drive the cloth with `Wind.luau` (`V-L4.6`, `V-L5.1`), at the tier sway ranges 25 / 50 / 80
   studs. Needs the designer's yes on the `props_r4` jemuran model and a separate motion verdict.
   Cloth amplitude and flip direction are a design call.

## 5. Gating — off by default, no shipping change without a yes

- Every r4 candidate — `buildings_r4`, `vegetation_r4`, `props_r4`, `npcs_r4`, `textures_r4`,
  `sky_r4_a`, `sky_r4_b`, `sky_r4_c` — is **off by default** and needs a **designer yes** before any
  shipping change. Blank verdicts stay blank; no agent fills them.
- Toggle with **dot syntax**: `LookDev.enable("buildings_r4")` / `LookDev.enable("props_r4")` etc.,
  restored with `LookDev.disable()`. The colon form `LookDev:enable("id")` returns "unknown
  candidate" (round-3 REPORT bug 1; WORK_QUEUE section H "Toggle syntax"). Model families load from
  the **Server** datamodel, as recorded in `CANDIDATES.md` for the r3 families.
- Round-3 verdicts are inputs, not approvals for this plan: `icons_r3` yes; `day_cycle` yes but
  needs 16:00 tuning and a night test; `corner` and the four r3 model families **no** (tiny,
  untextured grey, script-built placeholders); `textures_r3` and `sky_r3` retest
  (`CANDIDATES.md`, round-3 `REPORT.md`). No r4 family has been reviewed yet.
- Real source, licence, author and ID go to `ASSET_MANIFEST.md` on ingest; CC BY needs attribution.
  No ID is invented here.

## 6. Mismatches between the brief and the source docs

1. **ART.md path.** The brief says `docs/v2/visual/art/ART.md`; the file is
   `docs/v2/visual/ART.md` (the `art/` folder holds `MAP_SPEC.md`, `SOURCING_BUILDINGS_VEG.md`,
   `ASSET_MANIFEST.md` and the asset subfolders). Used the actual path.
2. **Spawn coordinate.** Item 32 gives none. `MAP_SPEC.md` §6 still shows the old S=1 spawn
   `(0, 0.5, 14)`, while §0's S=2 table says `(0, 28)`. Used the code authority
   `MapSpec.luau:203`: `(0, 0.5, 28)`, facing -Z.
3. **Footprints.** `MAP_SPEC.md` §3 lists S=1 footprints (plaza 48×42, Warung 26×22, etc.); the
   built world is S=2. Used `MapSpec.luau` footprints (plaza 96×84, Warung 52×44) as required.
4. **`pematang` edges.** Item 32 lists them as spawn dressing, but the pematang/sawah terraces are
   at `z -312..-376` — over 300 studs north of spawn, only a distant backdrop — and no pematang
   model exists in item 31's r4 family lists. Treated as a distant `vegetation_r4` padi/shrub edge
   plus an optional **Designer builds** bund module; the designer must decide whether "lived-in
   spawn" needs a bund near the plaza at all.
5. **Props named in the brief but absent from item 31.** `sepeda`, `ayam`, lanterns, potted plants,
   "warung clutter" and the existing `MAP_SPEC.md` §8 list (`kabel`, `galon`, `kursi plastik`,
   motor) are not in any `*_r4` family. They are written as **Designer builds** briefs or deferred
   ambient ideas here, not assumed to be covered by r4.
6. **Pasar stalls.** Item 31's `buildings_r4` list omits the Pasar, even though the Pasar roof is a
   named spawn-frame landmark. Flagged in cluster C as a brief / `props_r4.lapak` stand-in.
7. **Contour.** `MAP_SPEC.md` §8 asks for ink contour on hubs/NPCs/interactables within 60 studs;
   V-D1 (retire the world contour) and the round-3 "no" on `corner` are in force. No contour is
   planned for the r4 dressing; at most one focus `Highlight` per `VISUAL_MASTER_PLAN.md` §6.
