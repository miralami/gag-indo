# Round-8 check harness — REVIEW_ROUND8.md (WORK_QUEUE section L)

Session: `Development-Juragan-Desa`, placeId `132087524375529`. All checks below verified in real Studio Play on 2026-11-21.

## 1. Edit-mode bake (item 54 procedure, re-run for round 8)

Stop Play. Run `tools/studio/bake_lookdev_assets.luau` in the EDIT datamodel via Studio MCP `execute_luau`.

Result this run: `baked=3`, `failures=0`, `total_folders=34`.

Three new round-8 IDs, each with `props_r8_children=1`:

- `4951145641` — "Cangkul"
- `10506531785` — "Gerobak"
- `85094565897097` — bamboo fence

All three recorded in `docs/v2/visual/art/ASSET_MANIFEST.md`. Never read an API key.

## 2. Process fix (item 65): the bake must NOT be saved

After the Edit-mode bake, DO NOT save the place (no Ctrl+S, no `save_place` tool). The bake is a runtime-only Edit-datamodel edit. Verify it was not saved:

1. Before the bake, note whether `ServerStorage.LookDevAssets` already has children.
2. After the bake, close/reopen Studio WITHOUT saving and confirm the bake folders are gone.
3. The place's version history must show no new version from the review session.

Background: the round-7 review found `LookDevAssets` survived a Studio restart, which means the place was probably saved after a bake — that is the bug this step prevents.

Note: this round did not save the place.

## 3. Staging / toggles

Start a fresh real Play session. In the SERVER datamodel run the enable sequence from `REVIEW_ROUND7.md`:

- `require(...LookDevModelsVegetationR7).apply()`
- `require(...LookDevModelsNpcsR7).apply()`
- `require(...LookDevModelsPropsR7)`
- `require(Shared.LookDev).enable("props_r7")`

This run: `LookDevFailures {props_r7=0, npcs_r7=0, vegetation_r7=0}`; workspace folder children `vegetation_r7=120`, `npcs_r7=5`, `props_r7=6`.

## 4. Datamodels

`tools/studio/review_check_r7.luau` prints `CHECK <name> PASS|FAIL <measured> <target>` lines and returns a results table.

- SERVER datamodel: family checks `LOAD_FAILURES`, `SKY_DEFAULT`, `GRASS_ON_BEDS`, `HATS`, `PROPS_VISIBLE`, `PROPS_ON_GRASS`, `VEG_COUNT`, `VEG_SPECIES`, `BED_FLUSH`, `VEG_NEAR`, `PROP_SIZE`.
- CLIENT datamodel: `CLOUD_COVER` only. The client Sky LocalScript owns `Terrain.Clouds.Cover`, which the Server cannot observe.

For `CLOUD_COVER` use a FRESH Play with no enable call. The daily weather roll was hujan/badai (`Cover=1`), so set `ReplicatedStorage Musim=kemarau`, `Cuaca=cerah` and `Lighting.ClockTime=13` in the client (temporary review state, NOT saved/committed) before running. LiveConfig's 60 s poll resets weather, so set the clear state and run the harness in the SAME `execute_luau` call.

## 5. Evidence paths

- docs/v2/evidence/h/2026-11-21-round8/CHECK_61.txt (CLOUD_COVER PASS 0.500@ct13.00, Client)
- docs/v2/evidence/h/2026-11-21-round8/CHECK_62.txt (GRASS_ON_BEDS + BED_FLUSH, Server)
- docs/v2/evidence/h/2026-11-21-round8/CHECK_63.txt (VEG_COUNT + VEG_SPECIES + VEG_NEAR, Server)
- docs/v2/evidence/h/2026-11-21-round8/CHECK_64.txt (PROPS_VISIBLE + PROPS_ON_GRASS + PROP_SIZE, Server)

## 6. Final harness lines (all PASS)

Server:

```text
CHECK LOAD_FAILURES PASS 0 0
CHECK SKY_DEFAULT PASS rbxassetid://2835177931 rbxassetid://2835177931
CHECK GRASS_ON_BEDS PASS 0 0
CHECK HATS PASS 4 4
CHECK PROPS_VISIBLE PASS 6 6
CHECK PROPS_ON_GRASS PASS 0 0
CHECK VEG_COUNT PASS 94 60
CHECK VEG_SPECIES PASS 10 8
CHECK BED_FLUSH PASS 0 0.5
CHECK VEG_NEAR PASS 27 inst/7 sp/0 small >=25 inst/>=6 sp/0 small
CHECK PROP_SIZE PASS g=4.99 c=4.00 p=8.54 g[4-6] c[3.5-4.5] p[>=8]
```

Client:

```text
CHECK CLOUD_COVER PASS 0.500@ct13.00 0.4-0.6
```

## 7. VEG_NEAR first attempt FAILED

First attempt measured 21 inst vs `>=25`: real baked-model bbox centres drift outward from nominal data slots.

Fix: six well-behaved near slots (bambu/mangga/pisang at `|x|>=16`, `z=116/122`) added to `NEAR_PLAN` in `src/shared/ModelMapVegetationR7.luau`; a fresh Play re-staged 120 vegetation models; second/final harness attempt measured 27/7/0. The check itself was not weakened and the Sedang budget stayed 120/120.

## 8. Review cameras (main session takes the shots; none are graded from file contents)

Record these exact camera positions, to be shot by a vision-capable observer/designer:

- Spawn / near vegetation / sky E (clear day): eye `[0,20,150]`, look `[0,8,96]`
- Sky-up (sky E framing): eye `[0,20,150]`, look `[0,45,96]`
- Flower bed flush: eye `[30,20,74]`, look `[30,4,52]`
- Props staged: eye `[0,7,-34]`, look `[0,2,-62]`

This session's main model could not persist screenshot image data and the Studio `screen_capture` subagent timed out, so no shot files were produced; visual grading of these four views remains OPEN for the designer. The objective `CHECK_*` evidence above is complete and is not a visual verdict.

## 9. Non-fatal console noise (do not treat as failure)

- Three `ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type` lines.
- `ShippingLookR7: no PlotAnchor parts within 10 s; only flower beds painted`.

## 10. Visual verdicts carried in

Designer approved sky E, ground, and catalog outfits (commit `4408a04`); NPC outfits were not touched.

Route A Open Cloud delivery remains unavailable (HTTP 403 Scope not authorized); Route B Edit-mode bake is active.
