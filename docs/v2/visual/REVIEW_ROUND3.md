# Review round 3 — designer handoff

Purpose: one ordered handoff for the round-3 visual review (WORK_QUEUE item 13, extended by item
26 after the section-G unblock pass). It lists every LookDev candidate, its exact toggle, its saved
camera where one exists, and the order to review. No agent grades visuals. Verdict cells are blank;
the designer (or a vision-capable observer with screenshots) fills yes/no in
`docs/v2/visual/CANDIDATES.md`.

Section G rule: a missing visual verdict never blocks integration. Every new candidate below is
integrated off by default with a saved review camera and a blank verdict. The verdict is this
review pass's job, not a precondition.

Rules, from `docs/v2/visual/CANDIDATES.md` and `src/shared/LookDev.luau`:

- Toggle from the Studio command bar:
  `require(game.ReplicatedStorage.Shared.LookDev).enable("<id>")`
- The four model families (`buildings_r3`, `vegetation_r3`, `props_r3`, `npcs_r3`) MUST be enabled
  from the **Server** datamodel: `InsertService:LoadAsset` is blocked on the client. All other
  candidates can be enabled from the Client or Server datamodel.
- Restore the shipping look:
  `require(game.ReplicatedStorage.Shared.LookDev).disable()`
- Only one candidate is active at a time; enabling another restores the first.
- The gate is Studio-only. A published server can never enable it.
- Every candidate is off by default. Nothing here is approved or shipped by this document.
- No asset ID, product ID or UserId is invented. Real IDs belong in
  `docs/v2/visual/art/ASSET_MANIFEST.md`.
- Status words remain `SEEN-IN-STUDIO`, `LUNE-ONLY`, `UNVERIFIED`, `BLOCKED`.

## How to use the table

- Use synced code. `docs/v2/evidence/h/2026-11-20-lookdev-corner/REPORT.md` records a stale
  Studio instance where the registry still had only eight candidates and `corner` had to be
  injected before the gate accepted it.
- Enable one row, inspect or audition it, then call `.disable()` before the next row. Enabling a
  second candidate restores the first automatically.
- "none saved — use render/contact sheet" means no Studio camera was saved for that candidate.
  Do not invent a camera position.
- Renders under `docs/v2/visual/art/` are review aids. `docs/v2/visual/CANDIDATES.md` records that
  several are dumped from recipe source, not Studio screenshots; no agent visually graded them.
- Audio has no image render. Use the in-Studio enable/disable proof under
  `docs/v2/evidence/h/2026-11-19-sound-candidates/` and audition it.
- Asset IDs for icon, texture, model, sky and sound candidates live in candidate tables, not
  shipping slots; `docs/v2/visual/CANDIDATES.md` records the shipping IDs as 0.
- Section-G additions are off by default with blank verdicts. Reading their source/render docs is
  not an approval step. The historical "blocked" rows are kept only for traceability and are
  marked superseded by the integrated candidates above.
- Record yes/no in `docs/v2/visual/CANDIDATES.md`, with evidence under `docs/v2/evidence/`.

## Scope boundaries

- This is a handoff, not a review result. No visual claim is made here.
- No candidate is approved, rejected or shipped by this file.
- No place is saved or published; no imported model or Open Cloud operation is performed.
- No asset ID, product ID or UserId is created here.
- This is not a Gate 1 pass; the designer/hardware rows stay in `docs/testing/GATE1.md`.

## Review order

1. **Foundation / reference.** Read `docs/v2/visual/art/reference/README.md` (15 images; the
   designer still adds 3–5 under V-D5). No toggle, no candidate, no verdict. This is shared mood
   and form reference only, not asset source material.
2. **Corner + lighting / frame.** Enable `corner`; use the three saved absolute cameras below.
   `screen_capture` timed out this session: no screenshots were produced. Capture the three corner
   shots in the designer's own Studio. Compare the grade with `plaza_lighting` if the Pasar frame
   is in scope.
3. **Round-1/2 candidate gallery.** Review `police_walkin`, `icons`, `textures`, `npcs`, `crops`,
   `hubprops`, `sounds` after the corner/frame pass. Use the render or contact sheet named in the
   master table; no other candidate has a saved Studio camera. Audio has no image render — its
   review artifact is the in-Studio enable/disable proof.
4. **Section-G additions (item 26), in this order.** Enable one at a time, capture from the saved
   camera, `.disable()`, then move on:
   1. `textures_r3` — nine real CC0 PBR MaterialVariants; contact sheet plus the `pasar_material_row`
      camera in `textures_r3/README.md`.
   2. `icons_r3` — the 27 redraws; compare `contact_before.png` with `contact_after.png` under
      `icons/render_r3/`. No Studio camera (icon sheets are the review aid).
   3. `buildings_r3`, `vegetation_r3`, `props_r3`, `npcs_r3` — **Server datamodel**; one saved
      corner camera per family in `models_r3/MANIFEST.md` and `models_r3/INTEGRATION.md`.
   4. `sky_r3` — the CC0 HDRI cube sky; saved camera `{500,9,554}` → `{500,16,500}`.
   5. `day_cycle` — live 20–40 s phase tweens, Rendah night lamps and five silent sound beds; saved
      camera `{0,12,52}` → `{0,3,-20}`. Audition the phase changes in Studio; no screenshot yet.
   None of these has an agent verdict; every verdict cell is blank.
5. **Blocked asset lanes (historical).** `docs/v2/visual/art/SOURCING_BUILDINGS_VEG.md`,
   `docs/v2/visual/art/SOURCING_TEXTURES_NPC_ANIM.md` and `docs/v2/visual/art/PROP_AUDIT.md`
   were the pre-section-G sourcing plans. Buildings, vegetation, props, textures and NPCs now have
   integrated candidates above; animations remain un-integrated. The old "blocked" rows in the
   master table are kept for traceability and are marked superseded.
6. **Moments (after the frame is approved).** WORK_QUEUE items 14–15: harvest/reveal/sale VFX,
   then raid lights and the police walk-in using `police_walkin` only if approved. These are not
   LookDev candidates yet; do not fill a verdict from this pass.

## Prior designer verdicts — carried verbatim, not re-graded

These are copied from `docs/v2/visual/CANDIDATES.md` so the review does not lose accepted decisions.
They are not agent judgments and are not written into the blank verdict cells below.

- `icons` — **yes, improve** (base is fine; fix `tier_biasa`, `debt`, polish the rest) — 2026-11-19
- `textures` — **no** — use downloaded CC0 PBR textures as MaterialVariants (D18)
- `npcs` — **no** — real 3D models via the D15 ladder
- `crops` — **no** — real 3D models via the D15 ladder
- `hubprops` — **no** — keep the idea, rebuild mostly as 3D models, case by case
- `plaza_lighting`, `police_walkin`, `corner` — pending — review in Studio
- `sounds` — pending — listen in Studio

## Master table

Verdict cells stay blank. Evidence paths and "What it is" strings are from
`docs/v2/visual/CANDIDATES.md`; blocked-lane descriptions are from `docs/v2/plan/WORK_QUEUE.md`.

| Candidate | What it is | Toggle | Evidence / saved camera | Verdict (blank/pending) |
|---|---|---|---|---|
| `plaza_lighting` | Alternative Pasar material + lighting grade (round 1) | `require(game.ReplicatedStorage.Shared.LookDev).enable("plaza_lighting")`; `require(game.ReplicatedStorage.Shared.LookDev).disable()` | `docs/v2/evidence/h/2026-11-19-lookdev-candidates/` · none saved — use render/contact sheet |  |
| `police_walkin` | Police NPC walk-in timed to the raid cutscene (round 1) | `require(game.ReplicatedStorage.Shared.LookDev).enable("police_walkin")`; `require(game.ReplicatedStorage.Shared.LookDev).disable()` | `docs/v2/evidence/h/2026-11-19-lookdev-candidates/` · none saved — use render/contact sheet |  |
| `icons` | 27 agent-made painted icons for every IconMap slot (round 2 item 4) | `require(game.ReplicatedStorage.Shared.LookDev).enable("icons")`; `require(game.ReplicatedStorage.Shared.LookDev).disable()` | `docs/v2/visual/art/icons/render/contact_sheet.png` · none saved — use render/contact sheet |  |
| `textures` | 7 agent-made seamless painted textures for the Pasar surface preset (round 2 item 5) | `require(game.ReplicatedStorage.Shared.LookDev).enable("textures")`; `require(game.ReplicatedStorage.Shared.LookDev).disable()` | `docs/v2/visual/art/textures/render/contact_sheet.png` · none saved — use render/contact sheet |  |
| `npcs` | Procedural caricature detail parts for the box NPCs — Pak RT, Tengkulak, Polisi, debt collector (round 2 item 6) | `require(game.ReplicatedStorage.Shared.LookDev).enable("npcs")`; `require(game.ReplicatedStorage.Shared.LookDev).disable()` | `docs/v2/visual/art/npcs/render/contact_sheet.png` · none saved — use render/contact sheet |  |
| `crops` | Low-poly growth-stage models (bibit/tumbuh/siap) for all 12 crops (round 2 item 7) | `require(game.ReplicatedStorage.Shared.LookDev).enable("crops")`; `require(game.ReplicatedStorage.Shared.LookDev).disable()` | `docs/v2/visual/art/crops/render/contact_sheet.png` · none saved — use render/contact sheet |  |
| `hubprops` | Hero-prop details on the four shop hubs — stall/counter/desk/table, lantern, accent sign (round 2 item 8) | `require(game.ReplicatedStorage.Shared.LookDev).enable("hubprops")`; `require(game.ReplicatedStorage.Shared.LookDev).disable()` | `docs/v2/visual/art/hubprops/render/contact_sheet.png` · none saved — use render/contact sheet |  |
| `sounds` | Two free Creator Store music beds for the sawah/hutan zones (round 2 item 9) | `require(game.ReplicatedStorage.Shared.LookDev).enable("sounds")`; `require(game.ReplicatedStorage.Shared.LookDev).disable()` | `docs/v2/evidence/h/2026-11-19-sound-candidates/REPORT.md` · none saved — use render/contact sheet |  |
| `corner` | 60x60 warung / road bend / sawah edge corner at golden hour (round 3 item 2) | `require(game.ReplicatedStorage.Shared.LookDev).enable("corner")`; `require(game.ReplicatedStorage.Shared.LookDev).disable()` | `docs/v2/visual/art/corner/README.md` · `docs/v2/evidence/h/2026-11-20-lookdev-corner/REPORT.md` · saved cameras below |  |
| `textures_r3` | Nine real CC0 Poly Haven PBR MaterialVariants (round 3 items 20/21) | `require(game.ReplicatedStorage.Shared.LookDev).enable("textures_r3")`; `require(game.ReplicatedStorage.Shared.LookDev).disable()` | `docs/v2/visual/art/textures_r3/render/contact_sheet.png` · camera `{ -70, 12, -30 }` → `{ -70, 3, -58 }` |  |
| `day_cycle` | Live phase tweens, Rendah night lamps, five silent sound beds (round 3 item 25) | `require(game.ReplicatedStorage.Shared.LookDev).enable("day_cycle")`; `require(game.ReplicatedStorage.Shared.LookDev).disable()` | `docs/v2/visual/art/daycycle/README.md` · camera `{0,12,52}` → `{0,3,-20}` |  |
| `icons_r3` | 27 revised original icon CANDIDATES with before/after sheets (round 3 item 22) | `require(game.ReplicatedStorage.Shared.LookDev).enable("icons_r3")`; `require(game.ReplicatedStorage.Shared.LookDev).disable()` | `docs/v2/visual/art/icons/render_r3/contact_after.png` · none saved — use contact sheets |  |
| `buildings_r3` | Stilt house, coop, sawmill shed in the 60x60 corner (round 3 item 23) | **Server** datamodel: `require(game.ReplicatedStorage.Shared.LookDev).enable("buildings_r3")`; `.disable()` | `docs/v2/visual/art/models_r3/INTEGRATION.md` · camera `{500,16,542}` → `{500,4,490}` |  |
| `vegetation_r3` | Tropical palm/bamboo plus banana, mango, shrubs (round 3 item 23) | **Server** datamodel: `require(game.ReplicatedStorage.Shared.LookDev).enable("vegetation_r3")`; `.disable()` | `docs/v2/visual/art/models_r3/INTEGRATION.md` · camera `{468,12,520}` → `{500,4,500}` |  |
| `props_r3` | Gerobak, well, market stall, bamboo fence, tools (round 3 item 23) | **Server** datamodel: `require(game.ReplicatedStorage.Shared.LookDev).enable("props_r3")`; `.disable()` | `docs/v2/visual/art/models_r3/INTEGRATION.md` · camera `{532,11,500}` → `{498,2,500}` |  |
| `npcs_r3` | Two CC0 rigged bodies plus four original villagers (round 3 item 23) | **Server** datamodel: `require(game.ReplicatedStorage.Shared.LookDev).enable("npcs_r3")`; `.disable()` | `docs/v2/visual/art/models_r3/INTEGRATION.md` · camera `{500,7,524}` → `{500,2,500}` |  |
| `sky_r3` | CC0 overcast tropical sunrise HDRI cube sky + ridge + haze (round 3 item 24) | `require(game.ReplicatedStorage.Shared.LookDev).enable("sky_r3")`; `require(game.ReplicatedStorage.Shared.LookDev).disable()` | `docs/v2/visual/art/sky_r3/README.md` · camera `{500,9,554}` → `{500,16,500}` |  |
| `reference board` | 15 images; designer adds 3–5 (V-D5) | none — reference only | `docs/v2/visual/art/reference/README.md` |  |
| `blocked: buildings` | WORK_QUEUE 4 — rumah panggung, warung, pos polisi, rumah Pak RT, pasar stalls, gubuk sawah | **SUPERSEDED** — use `buildings_r3` | `docs/v2/visual/art/SOURCING_BUILDINGS_VEG.md` · historical plan only; three real CC0 / designer-build models are now integrated above |  |
| `blocked: vegetation` | WORK_QUEUE 5 — kelapa, pisang, bambu clumps, shrubs, padi at three stages, dense grass (V-D4) | **SUPERSEDED** — use `vegetation_r3` | `docs/v2/visual/art/SOURCING_BUILDINGS_VEG.md` · historical plan only; six real CC0 / designer-build models are now integrated above |  |
| `blocked: props` | WORK_QUEUE 6 — fences (bambu), lanterns, crates, karung, sepeda, gerobak, jemuran, signs, motor | **SUPERSEDED** — use `props_r3` | `docs/v2/visual/art/PROP_AUDIT.md` · historical audit only; five real designer-build models are now integrated above |  |
| `blocked: textures` | WORK_QUEUE 7 — nine CC0 PBR sets (D18); round-2 painted textures remain rejected | **SUPERSEDED** — use `textures_r3` | `docs/v2/visual/art/SOURCING_TEXTURES_NPC_ANIM.md` · historical plan only; nine real CC0 PBR sets are now integrated above |  |
| `blocked: NPCs` | WORK_QUEUE 8 — CC0 rigged base, peci hat, Creator Store caping routes | **SUPERSEDED** — use `npcs_r3` | `docs/v2/visual/art/SOURCING_TEXTURES_NPC_ANIM.md` · historical plan only; six real CC0 / designer-build models are now integrated above |  |
| `blocked: animations` | WORK_QUEUE 9 — R15 walk/idle routes, authored / `generate_animation` cangkul and panen (V-D6) | none — still outstanding | `docs/v2/visual/art/SOURCING_TEXTURES_NPC_ANIM.md` · no animation assets integrated; needs the shared Studio session / designer builds |  |

## Saved `corner` cameras — capture in the designer's Studio

Verbatim from `docs/v2/visual/art/corner/README.md`; paste into Studio `screen_capture` as
`camera_position` / `look_at_position`. All three are absolute world coordinates.

- `warung` — `camera_position { 480, 12, 500 }`, `look_at_position { 486, 4, 486 }`
- `road_bend` — `camera_position { 512, 10, 522 }`, `look_at_position { 512, 1, 503 }`
- `sawah_edge` — `camera_position { 500, 8, 528 }`, `look_at_position { 486, 1, 518 }`

`screen_capture` timed out this session: no screenshots were produced. No visual judgement was
made. The designer must capture the three shots above in their own Studio and record the result
under `docs/v2/evidence/`, then fill the `corner` verdict in
`docs/v2/visual/CANDIDATES.md`.

### Saved section-G cameras

Absolute world coordinates, one per candidate. Paste into Studio `screen_capture` as
`camera_position` / `look_at_position`; all are already in the master table above.

- `textures_r3` — `{ -70, 12, -30 }` → `{ -70, 3, -58 }` (`textures_r3/README.md`)
- `buildings_r3` — `{500,16,542}` → `{500,4,490}` (`models_r3/INTEGRATION.md`)
- `vegetation_r3` — `{468,12,520}` → `{500,4,500}` (`models_r3/INTEGRATION.md`)
- `props_r3` — `{532,11,500}` → `{498,2,500}` (`models_r3/INTEGRATION.md`)
- `npcs_r3` — `{500,7,524}` → `{500,2,500}` (`models_r3/INTEGRATION.md`)
- `sky_r3` — `{500,9,554}` → `{500,16,500}` (`sky_r3/README.md`)
- `day_cycle` — `{0,12,52}` → `{0,3,-20}` (`daycycle/README.md`)
- `icons_r3` — none saved; compare the two contact sheets instead.

No Studio screenshots were captured for any section-G candidate. No agent graded them.

## Designer actions still required

- Add 3–5 own reference images under `docs/v2/visual/art/reference/` with source, licence and
  author, per V-D5.
- Review the section-G candidates in the order above from the saved cameras (model families from
  the **Server** datamodel), capture screenshots under `docs/v2/evidence/`, and fill the blank
  verdict cells in `docs/v2/visual/CANDIDATES.md`. These integrations are complete; only the
  designer/vision yes-no remains.
- Animation sourcing (WORK_QUEUE 9) is still outstanding: R15 walk/idle and cangkul/panen routes
  need the shared Studio session / designer builds. No animation candidate exists yet.
- If a later revision is wanted: the r3 icons, PBR sets, models and sky already have real Open
  Cloud IDs in `docs/v2/visual/art/ASSET_MANIFEST.md`; further revisions repeat the D15/D18 ladder
  (licence check → real ID → off-by-default LookDev candidate → vision verdict) rather than editing
  shipping slots.
- Close the designer and hardware Gate 1 rows in `docs/testing/GATE1.md`: G2/Q1 phone-size
  re-check, G4, G4b, G6, G7, Q5, Q6, Q7. G1 closes last once every `Q#` row passes. Save every
  result as evidence under `docs/v2/evidence/`.
