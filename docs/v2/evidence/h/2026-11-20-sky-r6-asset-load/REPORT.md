# Round 6 sky asset-load evidence — 2026-11-20

Status: `SEEN-IN-STUDIO` for the asset load and face-ID read only. This is **not** a visual verdict;
no screenshot was graded and no candidate was approved.

The six real free Creator Store models listed in `docs/v2/plan/WORK_QUEUE.md` section J item 44 were
loaded with `InsertService:LoadAsset(assetId)` in the **Server** datamodel of the open Studio place
(Edit-mode `LoadAsset` returned `User is not authorized to access Asset`, so the Play-Solo Server VM
was used). The Studio instance was `Development-Juragan-Desa (placeId: 132087524375529)`. All six
loads succeeded. For each model, the first descendant of class `Sky` was read for the six exact Roblox
face properties; no inserted script was executed, and the models were not parented into the saved
place. Play was stopped and the temporary Edit-mode `R6Probe_*` folders were destroyed. The place was
**not saved or published**.

Creator Store names, creators and URLs were confirmed with `search_asset` (`scope=creator_store`,
`priceFilter=free`, `assetType=Model`) in the same Studio session. All six results report
`isFree=true` and `priceCents=0`.

| Candidate | Model ID | Creator Store name / creator | URL | Internal Sky name |
|---|---|---|---|---|
| `sky_r6_a` | 4607457995 | Realistic Sky / Xeksworld08 | https://create.roblox.com/store/asset/4607457995 | Realistic Sky |
| `sky_r6_b` | 10256505900 | Sky-Realistic / Dev_Flowey | https://create.roblox.com/store/asset/10256505900 | Sky |
| `sky_r6_c` | 9589448285 | Realistic Clear Sky / HeyItzDaredevil | https://create.roblox.com/store/asset/9589448285 | Clear Noon Sky |
| `sky_r6_d` | 11219565245 | Realistic Clear Skies (SKYBOX) / TrainMaker6 | https://create.roblox.com/store/asset/11219565245 | Realistic Skybox |
| `sky_r6_e` | 71778157196658 | Blue Sky W Scattered Clouds Daytime Skybox Light / Rozosere48 | https://create.roblox.com/store/asset/71778157196658 | 1970s Skybox |
| `sky_r6_f` | 79778158338852 | Sunless blue sky skybox realistic clouds / f0xz08 | https://create.roblox.com/store/asset/79778158338852 | Sky |

The `sky_r6_e` Store result description is `Blue Sky w/ Scattered Clouds ... cumulus clouds, summer
sky`; the model's internal `Sky` instance is named `1970s Skybox`. That is the loaded content of the
real ID above, not a substitute ID.

## Exact face IDs read from the loaded Sky instances

Legacy `http://www.roblox.com/asset/?id=N` values are normalised to the integer `N` in
`src/shared/SkyMapR6.luau`; the client applier adds the `rbxassetid://` prefix at apply time. The
`rbxassetid://N` values are already in that form.

| Candidate | SkyboxBk | SkyboxDn | SkyboxFt | SkyboxLf | SkyboxRt | SkyboxUp |
|---|---:|---:|---:|---:|---:|---:|
| `sky_r6_a` | 150335574 | 150335585 | 150335628 | 150335620 | 150335610 | 150335642 |
| `sky_r6_b` | 144933338 | 144931530 | 144933262 | 144933244 | 144933299 | 144931564 |
| `sky_r6_c` | 9544505500 | 9544547905 | 9544504852 | 9544547694 | 9544547542 | 9544547398 |
| `sky_r6_d` | 91458002 | 91457980 | 91458024 | 91458024 | 91458024 | 91458002 |
| `sky_r6_e` | 2835173905 | 2493829793 | 2835177931 | 2835174704 | 2835177433 | 2835175409 |
| `sky_r6_f` | 591058823 | 591059876 | 591058104 | 591057861 | 591057625 | 591059642 |

`sky_r6_d` really does use the same front/left/right image on three faces in the loaded model; it is
recorded exactly as read, not "fixed" by guessing another ID.

## Scripts present in loaded models (not executed, not copied)

- `sky_r6_e`: `BloomEffect.Runtime` and a nested `RuntimeInputContext` input-binding script.
- `sky_r6_f`: `SkyLink (Dont Remove).qPerfectionWeld`.

The round-6 applier copies only the six face IDs into a fresh `Sky`; it never copies scripts or any
other part of the loaded model, satisfying the queue note "strip any scripts on insert".
