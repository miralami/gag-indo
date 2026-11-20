# Round-5 final report (2026-11-20)

End of long-run `WORK_QUEUE` section I (round 5, items 35–43). Every item is done or `BLOCKED`;
nothing agent-closable is left. Branch `track/c-world-look`; all commits pushed.

## What was done (commits, oldest first)

| Commit | Item | Shipped |
|---|---|---|
| `fe254fc` | 35 | `textures_r4` darkening fix — bright warm-neutral `Terrain:SetMaterialColor` tint only while the CC0 base-material override is live, exact prior colours restored on disable; live before/during/after reads in `h/2026-11-20-textures-r4-fix/REPORT.md`. |
| `0467d4b` | 36–39 | Four off-by-default candidates: `spawn_ground_r5` (feathered tanah paths, `buildRoads` default untouched), `vegetation_r5` (pisang + dense bamboo, no kelapa/pines, exclusion zones), `sky_r5` (two reused real CC0 HDRIs, `Clouds.Cover` 0.4, no ridge, top-face seam fix), `props_r5` (per-slot rescale, contextual 4-sack karung stack, jemuran unchanged). |
| `746214c` | 40 | `npcs_r5` — five upright R15 villagers from body-colour `HumanoidDescription`s plus three real free Creator Store hat Models (creators/URLs in `art/models_r5/npcs/MANIFEST.md`); no ID invented. |
| `1d6bb08` | 41 | `spawn_r5` off-by-default dressing pass — composes only approved/temporary assets from the R4/R5 source maps, tier budgets 50/100/150 instances and 50k/100k/150k tris (Sedang ~23 / 58k est.), north-road corridor kept clear, saved camera `{0,20,72}->{0,5,14}`. |
| `8df2455` | 42 | Round-5 review handoff — `h/2026-11-20-review-round5/REVIEW_ROUND5.md` + `REVIEW_ROUND5.html` and `docs/v2/visual/REVIEW_ROUND5.md`: dot-syntax toggles, datamodels, saved cameras, blank verdict cells, live Studio enable sweep and camera sightline checks. |
| (this commit) | 43 | Refill re-check, tracker close, final report. |

`LookDev.IDS` grew 25 → 31. Every candidate is off by default and every verdict cell stays blank.
Validation before each commit: `lune run tests/run.luau` (final: **2248 passing**), `selene src`
(0 errors / 0 warnings / 0 parse errors), focused `stylua --check` and `git diff --check` clean.
No place was saved or published, no `JuraganDesa.rbxl` written, no ID/product/UserId invented,
`ROBLOX_API_KEY` neither printed nor used.

## What remains blocked

All blockers are designer/hardware/asset gates, not agent work:

- **Assets/IDs:** WORK_QUEUE items 4–9b (buildings, vegetation, props, textures, NPCs, animations,
  icons) need real licensed IDs and Open Cloud/Studio Importer uploads; no agent may invent an ID.
- **Visual verdicts:** `REVIEW_ROUND3/4/5.md`, `CANDIDATES.md` and the handoff sheets have blank
  verdict cells. Round-5 candidate screenshots could not be retained this session
  (`screen_capture` returned `null`; a video probe showed HUD over a flat dark world), so any visual
  claim is `UNVERIFIED` until a designer or retained-screenshot pass supplies it.
- **Frame/close:** items 10b, 11, 12, 14, 15, 16 need licensed sound IDs, a settings UI, an approved
  look, VFX assets, a `police_walkin` verdict, phone-emulator fps and a multi-client soak.
- **Gate 1:** 2 `BLOCKED` (G4 placeholders, Q5 ten-player), 1 `LUNE-ONLY` (Q8), 8 `UNVERIFIED`
  (G1, G2, G4b, G6, G7, Q1, Q6, Q7). Each needs the designer, a real device, five humans, a
  published place or a Local Server — see `docs/testing/GATE1.md` "Designer actions".
- **No open bug:** `BUGS.md` has no open `blocker`/`major` defect; BUG-008/009 phone-size re-check
  remains the one acceptance caveat behind G2/Q1.

Stale blocker facts corrected in the item-43 re-check: Rojo is running again (item 10b); real CC0
HDRI IDs now exist in `SkyMapR4`/`SkyMapR5` (item 11); the registry is 31 candidates, not 25
(item 16); item 40 supplied three real free hat Model IDs, but peci/batik/sarong still need builds
(item 8). The blocker in each case still stands.

## Decisions for the designer

Carried forward, no agent decision was made on look or balance:

1. **Round-5 candidate verdicts** — yes/no per row in `h/2026-11-20-review-round5/REVIEW_ROUND5.html`
   (`textures_r4` after the fix, `sky_r5`, `buildings_r4`, `vegetation_r5`, `props_r5`, `npcs_r5`,
   `spawn_r5`, `spawn_ground_r5`). Round-4 feedback is the input, not an approval:
   `textures_r4` no until darkening fixed; `sky_r4_a` best after slab/cloud/seam fixes;
   `buildings_r4` temporary yes; `vegetation_r4` yes (bamboo too thin, pisang good); `props_r4`
   no except `jemuran`; `npcs_r4` no.
2. **Camera caveats to accept or re-shoot** — `props_r5` saved camera is partially screened by pines
   (round-4 caveat); `vegetation_r5` reuses the round-4 camera that frames z≈96 while the main
   pisang/bambu clusters sit at z=34–63; `sky_r5` looks up so off-axis grass does not block it.
3. **Designer builds still needed** — rumah panggung, kandang ayam, gudang, pisang, **mango**
   (R5 uses a Balsa stand-in), shrubs, gerobak, sumur, pasar stall, pagar bambu, tools, and four
   villagers (petani caping, pedagang, petani wanita, tukang peci). Peci, batik and sarong had no
   reliable free source; item 40 used body colours only. Briefs in `models_r3/MANIFEST.md`.
4. **Sky scope** — overcast is reserved for a future rain/season event and is deliberately not built
   in `sky_r5`; the newly researched Poly Haven HDRIs in `art/sky_r5/README.md` are documented only,
   not uploaded.
5. **Indonesian copy (round 3 item 19)** — proposed `id` wording edits in WORK_QUEUE
   "Decisions for designer" are proposals only; `Strings.luau` was not changed. One `en` note in
   `raid_lower_third` should be dropped before English players see it.
6. **Icons (9b)** — the base verdict is "yes, improve"; `tier_biasa` and `debt` need redraws through
   the approved Open Cloud route with before/after contact sheets.

## Status words

- All round-5 code and registry facts: `LUNE-ONLY` (spec-locked) plus the live Play enable sweep,
  which is a factual `SEEN-IN-STUDIO` measurement, not a visual grade.
- Every visual verdict and any screenshot-based claim: `UNVERIFIED` until a retained-screenshot or
  designer pass supplies it. Blocker rows remain `BLOCKED`.
