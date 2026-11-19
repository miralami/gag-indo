# Review round 3 — designer handoff

Purpose: one ordered handoff for the round-3 visual review (WORK_QUEUE item 13). It lists every
LookDev candidate, its exact toggle, its saved camera where one exists, and the order to review.
No agent grades visuals. Verdict cells are blank; the designer (or a vision-capable observer with
screenshots) fills yes/no in `docs/v2/visual/CANDIDATES.md`.

Rules, from `docs/v2/visual/CANDIDATES.md` and `src/shared/LookDev.luau`:

- Toggle from the Studio command bar:
  `require(game.ReplicatedStorage.Shared.LookDev):enable("<id>")`
- Restore the shipping look:
  `require(game.ReplicatedStorage.Shared.LookDev):disable()`
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
- Enable one row, inspect or audition it, then call `:disable()` before the next row. Enabling a
  second candidate restores the first automatically.
- "none saved — use render/contact sheet" means no Studio camera was saved for that candidate.
  Do not invent a camera position.
- Renders under `docs/v2/visual/art/` are review aids. `docs/v2/visual/CANDIDATES.md` records that
  several are dumped from recipe source, not Studio screenshots; no agent visually graded them.
- Audio has no image render. Use the in-Studio enable/disable proof under
  `docs/v2/evidence/h/2026-11-19-sound-candidates/` and audition it.
- Asset IDs for icon, texture and sound candidates live in candidate tables, not shipping slots;
  `docs/v2/visual/CANDIDATES.md` records the shipping IDs as 0.
- Blocked lanes have no toggle and no visual verdict. Reading their sourcing docs is not an
  approval step.
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
4. **Blocked asset lanes.** Read `docs/v2/visual/art/SOURCING_BUILDINGS_VEG.md`,
   `docs/v2/visual/art/SOURCING_TEXTURES_NPC_ANIM.md` and
   `docs/v2/visual/art/PROP_AUDIT.md`. No toggle and no visual verdict: buildings, vegetation,
   props, textures, NPCs and animations are not yet integrated.
5. **Moments (after the frame is approved).** WORK_QUEUE items 14–15: harvest/reveal/sale VFX,
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
| `plaza_lighting` | Alternative Pasar material + lighting grade (round 1) | `require(game.ReplicatedStorage.Shared.LookDev):enable("plaza_lighting")`; `require(game.ReplicatedStorage.Shared.LookDev):disable()` | `docs/v2/evidence/h/2026-11-19-lookdev-candidates/` · none saved — use render/contact sheet |  |
| `police_walkin` | Police NPC walk-in timed to the raid cutscene (round 1) | `require(game.ReplicatedStorage.Shared.LookDev):enable("police_walkin")`; `require(game.ReplicatedStorage.Shared.LookDev):disable()` | `docs/v2/evidence/h/2026-11-19-lookdev-candidates/` · none saved — use render/contact sheet |  |
| `icons` | 27 agent-made painted icons for every IconMap slot (round 2 item 4) | `require(game.ReplicatedStorage.Shared.LookDev):enable("icons")`; `require(game.ReplicatedStorage.Shared.LookDev):disable()` | `docs/v2/visual/art/icons/render/contact_sheet.png` · none saved — use render/contact sheet |  |
| `textures` | 7 agent-made seamless painted textures for the Pasar surface preset (round 2 item 5) | `require(game.ReplicatedStorage.Shared.LookDev):enable("textures")`; `require(game.ReplicatedStorage.Shared.LookDev):disable()` | `docs/v2/visual/art/textures/render/contact_sheet.png` · none saved — use render/contact sheet |  |
| `npcs` | Procedural caricature detail parts for the box NPCs — Pak RT, Tengkulak, Polisi, debt collector (round 2 item 6) | `require(game.ReplicatedStorage.Shared.LookDev):enable("npcs")`; `require(game.ReplicatedStorage.Shared.LookDev):disable()` | `docs/v2/visual/art/npcs/render/contact_sheet.png` · none saved — use render/contact sheet |  |
| `crops` | Low-poly growth-stage models (bibit/tumbuh/siap) for all 12 crops (round 2 item 7) | `require(game.ReplicatedStorage.Shared.LookDev):enable("crops")`; `require(game.ReplicatedStorage.Shared.LookDev):disable()` | `docs/v2/visual/art/crops/render/contact_sheet.png` · none saved — use render/contact sheet |  |
| `hubprops` | Hero-prop details on the four shop hubs — stall/counter/desk/table, lantern, accent sign (round 2 item 8) | `require(game.ReplicatedStorage.Shared.LookDev):enable("hubprops")`; `require(game.ReplicatedStorage.Shared.LookDev):disable()` | `docs/v2/visual/art/hubprops/render/contact_sheet.png` · none saved — use render/contact sheet |  |
| `sounds` | Two free Creator Store music beds for the sawah/hutan zones (round 2 item 9) | `require(game.ReplicatedStorage.Shared.LookDev):enable("sounds")`; `require(game.ReplicatedStorage.Shared.LookDev):disable()` | `docs/v2/evidence/h/2026-11-19-sound-candidates/REPORT.md` · none saved — use render/contact sheet |  |
| `corner` | 60x60 warung / road bend / sawah edge corner at golden hour (round 3 item 2) | `require(game.ReplicatedStorage.Shared.LookDev):enable("corner")`; `require(game.ReplicatedStorage.Shared.LookDev):disable()` | `docs/v2/visual/art/corner/README.md` · `docs/v2/evidence/h/2026-11-20-lookdev-corner/REPORT.md` · saved cameras below |  |
| `reference board` | 15 images; designer adds 3–5 (V-D5) | none — reference only | `docs/v2/visual/art/reference/README.md` |  |
| `blocked: buildings` | WORK_QUEUE 4 — rumah panggung, warung, pos polisi, rumah Pak RT, pasar stalls, gubuk sawah | none — no LookDev candidate yet | `docs/v2/visual/art/SOURCING_BUILDINGS_VEG.md` · not yet integrated — blocked on Open Cloud IDs, Studio Importer session (D-G2) and designer/vision verdict |  |
| `blocked: vegetation` | WORK_QUEUE 5 — kelapa, pisang, bambu clumps, shrubs, padi at three stages, dense grass (V-D4) | none — no LookDev candidate yet | `docs/v2/visual/art/SOURCING_BUILDINGS_VEG.md` · not yet integrated — blocked on Open Cloud IDs, Studio Importer session (D-G2) and designer/vision verdict |  |
| `blocked: props` | WORK_QUEUE 6 — fences (bambu), lanterns, crates, karung, sepeda, gerobak, jemuran, signs, motor | none — no LookDev candidate yet | `docs/v2/visual/art/PROP_AUDIT.md` · not yet integrated — blocked on Open Cloud IDs, Studio Importer session (D-G2) and designer/vision verdict |  |
| `blocked: textures` | WORK_QUEUE 7 — nine CC0 PBR sets (D18); round-2 painted textures remain rejected | none — no LookDev candidate yet | `docs/v2/visual/art/SOURCING_TEXTURES_NPC_ANIM.md` · not yet integrated — blocked on Open Cloud IDs, Studio Importer session (D-G2) and designer/vision verdict |  |
| `blocked: NPCs` | WORK_QUEUE 8 — CC0 rigged base, peci hat, Creator Store caping routes | none — no LookDev candidate yet | `docs/v2/visual/art/SOURCING_TEXTURES_NPC_ANIM.md` · not yet integrated — blocked on Open Cloud IDs, Studio Importer session (D-G2) and designer/vision verdict |  |
| `blocked: animations` | WORK_QUEUE 9 — R15 walk/idle routes, authored / `generate_animation` cangkul and panen (V-D6) | none — no LookDev candidate yet | `docs/v2/visual/art/SOURCING_TEXTURES_NPC_ANIM.md` · not yet integrated — blocked on Open Cloud IDs, Studio Importer session (D-G2) and designer/vision verdict |  |

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

## Designer actions still required

- Add 3–5 own reference images under `docs/v2/visual/art/reference/` with source, licence and
  author, per V-D5.
- Icon revision, WORK_QUEUE 9b: keep the round-2 set as base; redraw `tier_biasa` (empty box) and
  `debt` (unclear), polish the rest for readability at 48 px, ship as a new candidate revision
  with before/after contact sheets.
- Live day-cycle wiring and time-of-day sound beds, WORK_QUEUE 10b: `presetFor` into
  `client/World/Sky.luau`, 20–40 s phase tweens, ayam/bedug/kentongan/jangkrik/soft adzan with
  the adzan setting, lanterns that emit light at night, and a FidelityTier check at Rendah in
  Studio.
- Real asset ingestion via the D15/D18 ladder and `docs/v2/visual/art/ASSET_MANIFEST.md`:
  download, verify licence, get real Open Cloud IDs, use the Studio Importer session (D-G2),
  integrate as off-by-default LookDev candidates, then leave the yes/no to a vision pass.
- Close the designer and hardware Gate 1 rows in `docs/testing/GATE1.md`: G2/Q1 phone-size
  re-check, G4, G4b, G6, G7, Q5, Q6, Q7. G1 closes last once every `Q#` row passes. Save every
  result as evidence under `docs/v2/evidence/`.
