# Textures r4 — source, licence and ID manifest

WORK_QUEUE item 29. CC0 only, from Poly Haven and ambientCG. Eleven Poly Haven
sets were fetched through `https://api.polyhaven.com/files/<code>` with every
MD5 checked against the API; ambientCG `Ground026` came from the public
`https://ambientcg.com/api/v2/full_json?id=Ground026` API (1K-JPG zip), whose API
does not publish per-file MD5s, so those three MD5s were computed locally and
are labelled as such. All 36 assets were uploaded as Roblox **Image** assets via
`ROBLOX_API_KEY` -> Open Cloud `POST /assets/v1/assets`; every ID below came from
a completed operation (`upload_manifest.json` has the operation IDs). No ID was
invented, no Creator Store / CC BY / NC / ND / QAL asset was used.

## Licence evidence (verbatim source text)

- Poly Haven, [Asset License](https://polyhaven.com/license):
  > Our assets are all licensed as CC0, which is effectively Public Domain even in jurisdictions that do not support the Public Domain.
  >
  > "You can use our assets for any purpose, including commercial work."
  > "You do not need to give credit or attribution when using them (although it is appreciated)."
- ambientCG, [License](https://docs.ambientcg.com/license/):
  > All ambientCG assets are provided under the Creative Commons CC0 1.0 Universal License. This applies to the downloadable asset files and the material preview renders shown for each asset on the site.
  >
  > "You can copy, modify, distribute and perform the assets, even for commercial purposes, all without asking permission."
  > "You can include the raw files in your project, for example a video game."

Poly Haven author strings are taken from `https://api.polyhaven.com/assets?t=textures`
and stored per file in `download_manifest.json` (`author_api`). The ambientCG API
exposes no per-asset author field; the site credits the publisher as ambientCG
and its suggested credit is "Created using <asset name> from ambientCG.com,
licensed under the Creative Commons CC0 1.0 Universal License."

## Sets and real IDs

ID column order: diffuse / normal (`nor_gl` or `NormalGL`) / roughness.

| Surface | Slot | Variant | Base material | Studs per tile | Source page | Provider | Author | Licence | Asset IDs |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| dry / withered grass | `dry_grass` | `R4_DryGrass` | Grass | 10 | [withered_grass](https://polyhaven.com/a/withered_grass) | Poly Haven | Charlotte Baglioni | CC0 | 99291006551629 / 94138101324824 / 99517618599796 |
| laterite red dirt | `laterite` | `R4_Laterite` | Ground | 10 | [red_laterite_soil_stones](https://polyhaven.com/a/red_laterite_soil_stones) | Poly Haven | Amal Kumar | CC0 | 118381151358037 / 80566522516796 / 121928219739643 |
| rice-paddy mud / wet clay | `paddy_mud` | `R4_PaddyMud` | Mud | 8 | [Ground026](https://ambientcg.com/a/Ground026) | ambientCG | ambientCG | CC0 | 140414409206785 / 134530197365596 / 138244821682090 |
| cobblestone path | `cobblestone` | `R4_Cobblestone` | Cobblestone | 6 | [cobblestone_floor_04](https://polyhaven.com/a/cobblestone_floor_04) | Poly Haven | Rob Tuytel | CC0 | 116548637306757 / 114728267211735 / 126631905530342 |
| weathered planks | `weathered_planks` | `R4_WeatheredPlanks` | WoodPlanks | 8 | [weathered_planks](https://polyhaven.com/a/weathered_planks) | Poly Haven | Dimitrios Savva (photography), Dario Barresi (processing) | CC0 | 86925714541020 / 139064505550988 / 79209250273792 |
| woven bamboo / bilik | `bilik` | `R4_Bilik` | Wood | 6 | [bamboo_wall_02](https://polyhaven.com/a/bamboo_wall_02) | Poly Haven | Amal Kumar | CC0 | 104761377140093 / 75163422713451 / 137065390077687 |
| weathered brick wall | `brick` | `R4_BrickWall` | Brick | 6 | [worn_brick_wall](https://polyhaven.com/a/worn_brick_wall) | Poly Haven | Amal Kumar | CC0 | 101964656212261 / 74037970278315 / 79001558852046 |
| weathered plaster wall | `plaster` | `R4_PlasterWall` | Concrete | 8 | [blue_plaster_weathered](https://polyhaven.com/a/blue_plaster_weathered) | Poly Haven | Amal Kumar | CC0 | 139342078063430 / 111912632127012 / 125017038971785 |
| clay roof tile | `clay_tile` | `R4_ClayTile` | Slate | 8 | [clay_roof_tiles_03](https://polyhaven.com/a/clay_roof_tiles_03) | Poly Haven | Amal Kumar | CC0 | 103194041286294 / 139690368710650 / 128237078059309 |
| corrugated seng | `corrugated_metal` | `R4_CorrugatedMetal` | Metal | 8 | [worn_corrugated_iron](https://polyhaven.com/a/worn_corrugated_iron) | Poly Haven | Dimitrios Savva (photography), Jenelle van Heerden (processing) | CC0 | 107744112435438 / 75878137977040 / 134767952365897 |
| riverbank stones | `riverbank` | `R4_RiverBank` | Rock | 12 | [river_small_rocks](https://polyhaven.com/a/river_small_rocks) | Poly Haven | Rob Tuytel, Rico Cilliers | CC0 | 71678382965592 / 114207741022691 / 95462609294102 |
| sandy dirt path | `sand_path` | `R4_SandPath` | Sand | 8 | [stony_dirt_path](https://polyhaven.com/a/stony_dirt_path) | Poly Haven | eye-candy.xyz | CC0 | 103913932243276 / 117613154248787 / 86757243435143 |

## Integrity

- `download_manifest.json`: 36 rows, each with `source`, `source_page`, `url`,
  `author`, `licence`, verbatim `licence_text`, `md5` and `md5_source`.
- `upload_manifest.json`: 36 rows, each with `asset_id`, `asset_type = "Image"`,
  `operation_id` and `upload_route = "ROBLOX_API_KEY"`.
- The API key was never printed, logged or written to disk.

No visual grading, screenshot claim, place save or publish is recorded here.
