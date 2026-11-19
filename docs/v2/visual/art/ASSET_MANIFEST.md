# Asset manifest

Master Plan §5: every asset has a row, no row means no merge. IDs here were returned by the Studio
MCP `search_asset` (Creator Store, free filter) and each was loaded in a Play Solo session
(`Sound.IsLoaded` true, `TimeLength` read) on 2026-11-14. None were invented.

| Slot | Asset ID | Name | Creator (as listed) | Length | Source | Licence note | Approved by |
|---|---|---|---|---|---|---|---|
| `music_desa` | 83077123902599 | Gamelan Resonance Field | DistrokidOfficial | 152.2 s | Creator Store, free | Creator Store audio for use in Roblox experiences; terms are Roblox's, not re-read here | designer to confirm |
| `music_pasar` | 135973738646382 | Golden Gamelan | DistrokidOfficial | 178.8 s | Creator Store, free | same | designer to confirm |
| `music_sawah` | 9042889348 | Close Your Eyes - 60 - No Melody | APMOfficial | 58.59 s | Creator Store, free | Creator Store audio for use in Roblox experiences; terms are Roblox's, not re-read here | designer to confirm |
| `music_hutan` | 9048807207 | Cavernous Wonders 60 A | APMOfficial | 60.97 s | Creator Store, free | same (verified `IsLoaded = true`, len 60.97 s in Play VM on 2026-11-19) | designer to confirm |
| `ambience_cerah` | 9112748018 | Birds And Cicadas 2 (SFX) | ProSoundEffects ("Courtesy of Pro Sound Effects") | 46.3 s | Creator Store, free | same | designer to confirm |
| `ambience_hujan` | 9112853422 | Rain Heavy Rainfall Grass Wooden Roof 1 | ProSoundEffects | 46.0 s | Creator Store, free | same (verified `IsLoaded = true` on 2026-11-14) | designer to confirm |
| `ambience_badai` | 9112853563 | Rain Heavy Rainfall Grass Wooden Roof 2 | ProSoundEffects | 63.9 s | Creator Store, free | same (verified `IsLoaded = true` on 2026-11-14) | designer to confirm |
| `ambience_kabut` | 9112826489 | Malaysian Forest 2 | ProSoundEffects | 36.0 s | Creator Store, free | same (verified `IsLoaded = true` on 2026-11-14) | designer to confirm |
| `ui_click` | 88442833509532 | ui-simple-button-click | AmbientSorcery | 0.034 s | Creator Store, free | same (verified `IsLoaded = true` on 2026-11-14) | designer to confirm |
| `ui_open` | 17779566040 | minimal-pop-click-ui | Mister_Myrder | 1.03 s | Creator Store, free | same (verified `IsLoaded = true` on 2026-11-14) | designer to confirm |
| `ui_close` | 72264591133889 | ui-pop-sound-316482 | BIushney | 1.36 s | Creator Store, free | same (verified `IsLoaded = true` on 2026-11-14) | designer to confirm |
| `ui_buy` | 133570405319995 | Coin Clinking Sound | smashman65 | 1.0 s | Creator Store, free | same (verified `IsLoaded = true` on 2026-11-14) | designer to confirm |
| `ui_sell` | 135483737426662 | Coin Collect | G00byBBQSauce | 0.87 s | Creator Store, free | same (verified `IsLoaded = true` on 2026-11-14) | designer to confirm |
| `sting_rare` | 4612374393 | bling_diamond_pickup_2 | thienbao2109 | 1.51 s | Creator Store, free | same (verified `IsLoaded = true` on 2026-11-14) | designer to confirm |
| `sting_sultan` | 103516326607012 | mixkit-achievement-bell-600 | vincenzo145374 | 2.4 s | Creator Store, free | same (verified `IsLoaded = true` on 2026-11-14) | designer to confirm |
| `sting_almanak` | 4612374495 | bling_diamond_pickup_3 | thienbao2109 | 1.50 s | Creator Store, free | same (verified `IsLoaded = true` on 2026-11-14) | designer to confirm |
| `sting_rankup` | 3120909354 | Level_up | thienbao2109 | 2.38 s | Creator Store, free | same (verified `IsLoaded = true` on 2026-11-14) | designer to confirm |
| `sting_raid` | 127714289075929 | Police Siren Sound Effect | FusionFire97 | 4.46 s | Creator Store, free | same (verified `IsLoaded = true` on 2026-11-14) | designer to confirm |
| `sting_jail` | 127714289075929 | Police Siren Sound Effect | FusionFire97 | 4.46 s | Creator Store, free | same (verified `IsLoaded = true` on 2026-11-14) | designer to confirm |

`music_sawah` and `music_hutan` were added in round 2 item 9 (2026-11-19) after a fresh Creator Store
free-audio search. Both were verified loading in a Play VM (`IsLoaded = true`, lengths read) before
being recorded. **Both are LookDev candidates awaiting designer yes/no** — the shipping
`Config/Audio.sounds` slots stay `id = 0`; the IDs live in `src/shared/SoundMap.luau` and are applied
only by the off-by-default `sounds` candidate (`src/client/World/LookDevSounds.luau`). The other 17
audio rows above shipped in round 1. Evidence `docs/v2/evidence/h/2026-11-19-sound-candidates/`.

## Skybox (golden hour sunset)

| Slot | Asset ID | Name | Creator (as listed) | Type | Source | Licence note | Approved by |
|---|---|---|---|---|---|---|---|
| `sky_sunset_bk` | 156042307 | Sunset Skybox (Bk) | Roblox | Texture | Creator Store, free | Roblox classic sunset skybox texture | designer |
| `sky_sunset_dn` | 155440478 | Sunset Skybox (Dn) | Roblox | Texture | Creator Store, free | Roblox classic sunset skybox texture | designer |
| `sky_sunset_ft` | 156042328 | Sunset Skybox (Ft) | Roblox | Texture | Creator Store, free | Roblox classic sunset skybox texture | designer |
| `sky_sunset_lf` | 156042348 | Sunset Skybox (Lf) | Roblox | Texture | Creator Store, free | Roblox classic sunset skybox texture | designer |
| `sky_sunset_rt` | 156042292 | Sunset Skybox (Rt) | Roblox | Texture | Creator Store, free | Roblox classic sunset skybox texture | designer |
| `sky_sunset_up` | 156042384 | Sunset Skybox (Up) | Roblox | Texture | Creator Store, free | Roblox classic sunset skybox texture | designer |

## Foliage (background forest)

| Slot | Asset ID | Name | Creator (as listed) | Type | Source | Licence note | Approved by |
|---|---|---|---|---|---|---|---|
| `foliage_pine_tree` | 5392132809 | Realistic Pine Tree | GabeQZ | Model / MeshPart | Creator Store, free | Clean realistic pine tree meshes (Trunk `739614116`, Leaves `739619496`, `2312874610`) | designer |

## Candidates found, not yet wired

| Use | Asset ID | Name | Loaded in Studio |
|---|---|---|---|
| Pasar crowd ambience | 9112841064 | Outdoor Walla 2 (SFX), 71.5 s | yes (71.5 s) |
| Music alternative | 1840694476 | The Spirit Of Gamelan (e), APMOfficial | yes (120.3 s) |
| Music, no pulse | 122341055760449 | Gamelan Without Pulse | search only |

## Open points

- Licence terms of Creator Store audio were not read in full; confirm on the Creator Store terms
  before launch (Master Plan §6 phase 4).
- Third-party Creator Store audio can be removed or moderated later; re-check the IDs load before each release.

## 3D models (Poly Pizza CC0, via Blender MCP)

FBX in `docs/v2/visual/art/models/`: path mode Copy, Embed Textures, FBX Unit Scale, no leaf bones, no bake animation. Origin at base centre, bottom on Z=0, transforms applied. Columns follow `plan/TOOLS.md` §6. Each FBX embeds a tiny palette PNG (one swatch per original material, UVs point at the swatch) so colours survive the Roblox importer; the first import (plain material colours) came in grey.

```
slot,class,source,source_ref,licence,attribution,id,approved_by,status
model.pasar.stall,model,polypizza,https://poly.pizza/m/DGIM5HGISb,CC0,,0,,UNVERIFIED
model.prop.gerobak,model,polypizza,https://poly.pizza/m/l7bDe7ak6j,CC0,,0,,UNVERIFIED
model.prop.sumur,model,polypizza,https://poly.pizza/m/QlqncKYxXb,CC0,,0,,UNVERIFIED
model.prop.barrel,model,polypizza,https://poly.pizza/m/ONdghDBByN,CC0,,0,,UNVERIFIED
model.prop.crate,model,polypizza,https://poly.pizza/m/3VGWnZPXmG,CC0,,0,,UNVERIFIED
model.prop.karung,model,polypizza,https://poly.pizza/m/gzvyAQ797z,CC0,,0,,UNVERIFIED
model.prop.motor,model,polypizza,https://poly.pizza/m/j20srJUjpB,CC0,,0,,UNVERIFIED
model.kit.hut,model,polypizza,https://poly.pizza/m/wxi3kAu5ey,CC0,,0,,UNVERIFIED
model.kit.wall,model,polypizza,https://poly.pizza/m/8C9NBoi9cA,CC0,,0,,UNVERIFIED
model.kit.fence,model,polypizza,https://poly.pizza/m/e02PFKKhbr,CC0,,0,,UNVERIFIED
```

Authors: Quaternius (all except motor: AliceCassie). Triangles: stall 1548, gerobak 2659, sumur 1870, barrel 1384, crate 784, karung 912, motor 1500, hut 1724, wall 404, fence 188.

### Uploaded 2026-11-15 (Open Cloud, creator account, all moderation Approved)

Appended rows; the `id=0` rows above are the pre-upload history. Inserted into Workspace as `<slot>_v2`, scaled by 1/0.28 (FBX arrives at 1 m = 1 stud), anchored, laid out in a row near (-111, 0, -58). Evidence: `docs/v2/evidence/models/2026-11-15-models-in-studio.jpg` (stall, cart, well, barrel, crate, karung, motor, hut visible with colours; wall and fence not in frame).

```
slot,class,source,source_ref,licence,attribution,id,approved_by,status
model.pasar.stall,model,polypizza,https://poly.pizza/m/DGIM5HGISb,CC0,,129607759321192,,SEEN-IN-STUDIO
model.prop.gerobak,model,polypizza,https://poly.pizza/m/l7bDe7ak6j,CC0,,121540426548169,,SEEN-IN-STUDIO
model.prop.sumur,model,polypizza,https://poly.pizza/m/QlqncKYxXb,CC0,,80611793347029,,SEEN-IN-STUDIO
model.prop.barrel,model,polypizza,https://poly.pizza/m/ONdghDBByN,CC0,,97786595529501,,SEEN-IN-STUDIO
model.prop.crate,model,polypizza,https://poly.pizza/m/3VGWnZPXmG,CC0,,70770369223840,,SEEN-IN-STUDIO
model.prop.karung,model,polypizza,https://poly.pizza/m/gzvyAQ797z,CC0,,133136389632701,,SEEN-IN-STUDIO
model.prop.motor,model,polypizza,https://poly.pizza/m/j20srJUjpB,CC0,,106061905410704,,SEEN-IN-STUDIO
model.kit.hut,model,polypizza,https://poly.pizza/m/wxi3kAu5ey,CC0,,95225115736749,,SEEN-IN-STUDIO
model.kit.wall,model,polypizza,https://poly.pizza/m/8C9NBoi9cA,CC0,,83895031629944,,UNVERIFIED
model.kit.fence,model,polypizza,https://poly.pizza/m/e02PFKKhbr,CC0,,92903548535675,,UNVERIFIED
```

### Uploaded 2026-11-19 (round 2 item 4 — agent-made icon CANDIDATES, Open Cloud)

Every ID below was returned by `POST /assets/v1/assets` then read from the completed
`GET /assets/v1/operations/{id}` — none invented. All `moderationState=Approved`, creator user
`172146044`, `assetType=Image`. Source renders are the deterministic Pillow output of
`docs/v2/visual/art/icons/src/generate_icons.py`; contact sheet `docs/v2/visual/art/icons/render/contact_sheet.png`.
**All are LookDev candidates awaiting designer yes/no — none approved, none shipped on by
default.** Uploads used the Studio MCP `open_cloud_invoke` token (asset:read/asset:write), not the
`ROBLOX_API_KEY` env var; no key was printed, logged or committed.

```
slot,class,source,source_ref,licence,attribution,id,approved_by,status
icon.crop_padi,image,agent-generated,docs/v2/visual/art/icons/render/crop_padi.png,agent-made no third-party licence,,114251482326552,,UNVERIFIED
icon.crop_singkong,image,agent-generated,docs/v2/visual/art/icons/render/crop_singkong.png,agent-made no third-party licence,,125071570354841,,UNVERIFIED
icon.crop_jagung,image,agent-generated,docs/v2/visual/art/icons/render/crop_jagung.png,agent-made no third-party licence,,77336087458478,,UNVERIFIED
icon.crop_bawang,image,agent-generated,docs/v2/visual/art/icons/render/crop_bawang.png,agent-made no third-party licence,,104903641478136,,UNVERIFIED
icon.crop_cabai,image,agent-generated,docs/v2/visual/art/icons/render/crop_cabai.png,agent-made no third-party licence,,84310027204694,,UNVERIFIED
icon.crop_tembakau,image,agent-generated,docs/v2/visual/art/icons/render/crop_tembakau.png,agent-made no third-party licence,,80640549300472,,UNVERIFIED
icon.crop_kopi,image,agent-generated,docs/v2/visual/art/icons/render/crop_kopi.png,agent-made no third-party licence,,87432090737677,,UNVERIFIED
icon.crop_tebu,image,agent-generated,docs/v2/visual/art/icons/render/crop_tebu.png,agent-made no third-party licence,,126828358791382,,UNVERIFIED
icon.crop_kakao,image,agent-generated,docs/v2/visual/art/icons/render/crop_kakao.png,agent-made no third-party licence,,105395581171156,,UNVERIFIED
icon.crop_cengkeh,image,agent-generated,docs/v2/visual/art/icons/render/crop_cengkeh.png,agent-made no third-party licence,,101021953955568,,UNVERIFIED
icon.crop_durian,image,agent-generated,docs/v2/visual/art/icons/render/crop_durian.png,agent-made no third-party licence,,94589075400460,,UNVERIFIED
icon.crop_sawit,image,agent-generated,docs/v2/visual/art/icons/render/crop_sawit.png,agent-made no third-party licence,,127561041299274,,UNVERIFIED
icon.tier_biasa,image,agent-generated,docs/v2/visual/art/icons/render/tier_biasa.png,agent-made no third-party licence,,89039660400929,,UNVERIFIED
icon.tier_bagus,image,agent-generated,docs/v2/visual/art/icons/render/tier_bagus.png,agent-made no third-party licence,,81110221353868,,UNVERIFIED
icon.tier_super,image,agent-generated,docs/v2/visual/art/icons/render/tier_super.png,agent-made no third-party licence,,111608597881986,,UNVERIFIED
icon.tier_langka,image,agent-generated,docs/v2/visual/art/icons/render/tier_langka.png,agent-made no third-party licence,,121577229795943,,UNVERIFIED
icon.tier_sultan,image,agent-generated,docs/v2/visual/art/icons/render/tier_sultan.png,agent-made no third-party licence,,124401414397944,,UNVERIFIED
icon.currency_rupiah,image,agent-generated,docs/v2/visual/art/icons/render/currency_rupiah.png,agent-made no third-party licence,,76189327817658,,UNVERIFIED
icon.cash,image,agent-generated,docs/v2/visual/art/icons/render/cash.png,agent-made no third-party licence,,84649047415515,,UNVERIFIED
icon.phone,image,agent-generated,docs/v2/visual/art/icons/render/phone.png,agent-made no third-party licence,,135874869613602,,UNVERIFIED
icon.garden,image,agent-generated,docs/v2/visual/art/icons/render/garden.png,agent-made no third-party licence,,124397872915480,,UNVERIFIED
icon.debt,image,agent-generated,docs/v2/visual/art/icons/render/debt.png,agent-made no third-party licence,,83485200694555,,UNVERIFIED
icon.quest,image,agent-generated,docs/v2/visual/art/icons/render/quest.png,agent-made no third-party licence,,86819230917965,,UNVERIFIED
icon.cheat,image,agent-generated,docs/v2/visual/art/icons/render/cheat.png,agent-made no third-party licence,,135587262954164,,UNVERIFIED
icon.hat,image,agent-generated,docs/v2/visual/art/icons/render/hat.png,agent-made no third-party licence,,109619793807014,,UNVERIFIED
icon.shop,image,agent-generated,docs/v2/visual/art/icons/render/shop.png,agent-made no third-party licence,,133120999661934,,UNVERIFIED
icon.trophy,image,agent-generated,docs/v2/visual/art/icons/render/trophy.png,agent-made no third-party licence,,130034112081024,,UNVERIFIED
icon._upload_probe,image,agent-generated,docs/v2/visual/art/icons/render/_upload_probe.png,pipeline probe plain disc not for use,,106680734829483,,UNVERIFIED
```

### Uploaded 2026-11-19 (round 2 item 5 — agent-made texture CANDIDATES, Open Cloud)

Seven seamless 512x512 RGBA tiles, deterministic output of
`docs/v2/visual/art/textures/src/generate_textures.py`; contact sheet
`docs/v2/visual/art/textures/render/contact_sheet.png`. Every ID below came from
`POST /assets/v1/assets` then `GET /assets/v1/operations/{id}` — none invented. All
`moderationState=Approved` when last polled (`texture_sawah` was briefly `Reviewing` then
Approved), creator User `172146044`, `assetType=Image`. **All are LookDev candidates awaiting
designer yes/no — none approved, none shipped on by default.** Uploads used the Studio MCP
`open_cloud_invoke` token (asset:read/asset:write), not the `ROBLOX_API_KEY` env var; no key was
printed, logged or committed.

```
slot,class,source,source_ref,licence,attribution,id,approved_by,status
texture_bambu,image,agent-generated,docs/v2/visual/art/textures/render/texture_bambu.png,agent-made no third-party licence,,86020876968095,,UNVERIFIED
texture_genteng,image,agent-generated,docs/v2/visual/art/textures/render/texture_genteng.png,agent-made no third-party licence,,121899778984239,,UNVERIFIED
texture_seng,image,agent-generated,docs/v2/visual/art/textures/render/texture_seng.png,agent-made no third-party licence,,116077927961929,,UNVERIFIED
texture_paving,image,agent-generated,docs/v2/visual/art/textures/render/texture_paving.png,agent-made no third-party licence,,70537329110423,,UNVERIFIED
texture_sawah,image,agent-generated,docs/v2/visual/art/textures/render/texture_sawah.png,agent-made no third-party licence,,121312141770783,,UNVERIFIED
texture_kertas,image,agent-generated,docs/v2/visual/art/textures/render/texture_kertas.png,agent-made no third-party licence,,102834761172815,,UNVERIFIED
texture_tanah,image,agent-generated,docs/v2/visual/art/textures/render/texture_tanah.png,agent-made no third-party licence,,95694392312399,,UNVERIFIED
```

### Uploaded 2026-11-20 (round 3 items 20/21 — real CC0 Poly Haven PBR candidates, Open Cloud)

The `ROBLOX_API_KEY` route check succeeded: the first real texture upload returned HTTP 200 and its
completed operation yielded the first ID below. Section G uses this route. Every ID in this section
was read from a completed `GET /assets/v1/operations/{id}`; none was invented. The key was never
printed, logged or committed. All maps are 1024x1024; the normal maps are `nor_gl` (Roblox expects
OpenGL tangent space). Per-file URL, author, MD5 and operation ID are in
`docs/v2/visual/art/textures_r3/upload_manifest.json`; the review aid is
`docs/v2/visual/art/textures_r3/render/contact_sheet.png`. **All are LookDev candidates behind
`textures_r3`, off by default, awaiting a designer yes/no — none shipped on.**

```
slot,class,source,source_ref,licence,attribution,id,approved_by,status
texture_r3.cobblestone_floor_01.diff,image,polyhaven,https://polyhaven.com/a/cobblestone_floor_01,CC0,Rob Tuytel,74744016196476,,UNVERIFIED
texture_r3.cobblestone_floor_01.nor,image,polyhaven,https://polyhaven.com/a/cobblestone_floor_01,CC0,Rob Tuytel,110226485663162,,UNVERIFIED
texture_r3.cobblestone_floor_01.rough,image,polyhaven,https://polyhaven.com/a/cobblestone_floor_01,CC0,Rob Tuytel,138531745001215,,UNVERIFIED
texture_r3.stony_dirt_path.diff,image,polyhaven,https://polyhaven.com/a/stony_dirt_path,CC0,eye-candy.xyz,80034871262278,,UNVERIFIED
texture_r3.stony_dirt_path.nor,image,polyhaven,https://polyhaven.com/a/stony_dirt_path,CC0,eye-candy.xyz,78151682245075,,UNVERIFIED
texture_r3.stony_dirt_path.rough,image,polyhaven,https://polyhaven.com/a/stony_dirt_path,CC0,eye-candy.xyz,136294167944729,,UNVERIFIED
texture_r3.brown_mud_03.diff,image,polyhaven,https://polyhaven.com/a/brown_mud_03,CC0,Rob Tuytel,118458951573479,,UNVERIFIED
texture_r3.brown_mud_03.nor,image,polyhaven,https://polyhaven.com/a/brown_mud_03,CC0,Rob Tuytel,114355009654625,,UNVERIFIED
texture_r3.brown_mud_03.rough,image,polyhaven,https://polyhaven.com/a/brown_mud_03,CC0,Rob Tuytel,128285016910005,,UNVERIFIED
texture_r3.farm_furrows.diff,image,polyhaven,https://polyhaven.com/a/farm_furrows,CC0,Amal Kumar,73024027131833,,UNVERIFIED
texture_r3.farm_furrows.nor,image,polyhaven,https://polyhaven.com/a/farm_furrows,CC0,Amal Kumar,83316497417973,,UNVERIFIED
texture_r3.farm_furrows.rough,image,polyhaven,https://polyhaven.com/a/farm_furrows,CC0,Amal Kumar,70948754520311,,UNVERIFIED
texture_r3.river_small_rocks.diff,image,polyhaven,https://polyhaven.com/a/river_small_rocks,CC0,Rob Tuytel; Rico Cilliers,71705724488696,,UNVERIFIED
texture_r3.river_small_rocks.nor,image,polyhaven,https://polyhaven.com/a/river_small_rocks,CC0,Rob Tuytel; Rico Cilliers,131394824179214,,UNVERIFIED
texture_r3.river_small_rocks.rough,image,polyhaven,https://polyhaven.com/a/river_small_rocks,CC0,Rob Tuytel; Rico Cilliers,121037425917541,,UNVERIFIED
texture_r3.bamboo_wall.diff,image,polyhaven,https://polyhaven.com/a/bamboo_wall,CC0,Amal Kumar,129038060876960,,UNVERIFIED
texture_r3.bamboo_wall.nor,image,polyhaven,https://polyhaven.com/a/bamboo_wall,CC0,Amal Kumar,136304309254898,,UNVERIFIED
texture_r3.bamboo_wall.rough,image,polyhaven,https://polyhaven.com/a/bamboo_wall,CC0,Amal Kumar,138535778061241,,UNVERIFIED
texture_r3.clay_roof_tiles_02.diff,image,polyhaven,https://polyhaven.com/a/clay_roof_tiles_02,CC0,Amal Kumar,83414482593923,,UNVERIFIED
texture_r3.clay_roof_tiles_02.nor,image,polyhaven,https://polyhaven.com/a/clay_roof_tiles_02,CC0,Amal Kumar,109796656706355,,UNVERIFIED
texture_r3.clay_roof_tiles_02.rough,image,polyhaven,https://polyhaven.com/a/clay_roof_tiles_02,CC0,Amal Kumar,105143056428348,,UNVERIFIED
texture_r3.corrugated_iron.diff,image,polyhaven,https://polyhaven.com/a/corrugated_iron,CC0,Dimitrios Savva; Jenelle van Heerden,92821229855906,,UNVERIFIED
texture_r3.corrugated_iron.nor,image,polyhaven,https://polyhaven.com/a/corrugated_iron,CC0,Dimitrios Savva; Jenelle van Heerden,126844497648318,,UNVERIFIED
texture_r3.corrugated_iron.rough,image,polyhaven,https://polyhaven.com/a/corrugated_iron,CC0,Dimitrios Savva; Jenelle van Heerden,113205619789050,,UNVERIFIED
texture_r3.wood_planks.diff,image,polyhaven,https://polyhaven.com/a/wood_planks,CC0,Amal Kumar,71303695104901,,UNVERIFIED
texture_r3.wood_planks.nor,image,polyhaven,https://polyhaven.com/a/wood_planks,CC0,Amal Kumar,116521049280771,,UNVERIFIED
texture_r3.wood_planks.rough,image,polyhaven,https://polyhaven.com/a/wood_planks,CC0,Amal Kumar,107767666486100,,UNVERIFIED
```

### Uploaded 2026-11-20 (round 3 item 22 — revised original icon CANDIDATES, Open Cloud)

All 27 IDs were returned by completed `GET /assets/v1/operations/{id}` calls using the
`ROBLOX_API_KEY` route; none was invented and the key was never printed, logged or committed.
Renders are the deterministic Pillow output of `icons/src/generate_icons_r3.py`; before/after
contact sheets are in `icons/render_r3/`. **All are LookDev candidates behind `icons_r3`, off
by default, awaiting a designer yes/no — none shipped on.**

```
slot,class,source,source_ref,licence,attribution,id,approved_by,status
icon_r3.cash,image,agent-generated,docs/v2/visual/art/icons/render_r3/cash.png,original artwork no third-party licence,,138087600730726,,UNVERIFIED
icon_r3.cheat,image,agent-generated,docs/v2/visual/art/icons/render_r3/cheat.png,original artwork no third-party licence,,125589296242506,,UNVERIFIED
icon_r3.crop_bawang,image,agent-generated,docs/v2/visual/art/icons/render_r3/crop_bawang.png,original artwork no third-party licence,,135178455685153,,UNVERIFIED
icon_r3.crop_cabai,image,agent-generated,docs/v2/visual/art/icons/render_r3/crop_cabai.png,original artwork no third-party licence,,79919705592702,,UNVERIFIED
icon_r3.crop_cengkeh,image,agent-generated,docs/v2/visual/art/icons/render_r3/crop_cengkeh.png,original artwork no third-party licence,,78132241141166,,UNVERIFIED
icon_r3.crop_durian,image,agent-generated,docs/v2/visual/art/icons/render_r3/crop_durian.png,original artwork no third-party licence,,101370699215855,,UNVERIFIED
icon_r3.crop_jagung,image,agent-generated,docs/v2/visual/art/icons/render_r3/crop_jagung.png,original artwork no third-party licence,,90649184401740,,UNVERIFIED
icon_r3.crop_kakao,image,agent-generated,docs/v2/visual/art/icons/render_r3/crop_kakao.png,original artwork no third-party licence,,125498435667984,,UNVERIFIED
icon_r3.crop_kopi,image,agent-generated,docs/v2/visual/art/icons/render_r3/crop_kopi.png,original artwork no third-party licence,,138083843465081,,UNVERIFIED
icon_r3.crop_padi,image,agent-generated,docs/v2/visual/art/icons/render_r3/crop_padi.png,original artwork no third-party licence,,134033339407480,,UNVERIFIED
icon_r3.crop_sawit,image,agent-generated,docs/v2/visual/art/icons/render_r3/crop_sawit.png,original artwork no third-party licence,,117040564851934,,UNVERIFIED
icon_r3.crop_singkong,image,agent-generated,docs/v2/visual/art/icons/render_r3/crop_singkong.png,original artwork no third-party licence,,127244634432547,,UNVERIFIED
icon_r3.crop_tebu,image,agent-generated,docs/v2/visual/art/icons/render_r3/crop_tebu.png,original artwork no third-party licence,,127292228714627,,UNVERIFIED
icon_r3.crop_tembakau,image,agent-generated,docs/v2/visual/art/icons/render_r3/crop_tembakau.png,original artwork no third-party licence,,78677113924306,,UNVERIFIED
icon_r3.currency_rupiah,image,agent-generated,docs/v2/visual/art/icons/render_r3/currency_rupiah.png,original artwork no third-party licence,,99150976838662,,UNVERIFIED
icon_r3.debt,image,agent-generated,docs/v2/visual/art/icons/render_r3/debt.png,original artwork no third-party licence,,123701882589428,,UNVERIFIED
icon_r3.garden,image,agent-generated,docs/v2/visual/art/icons/render_r3/garden.png,original artwork no third-party licence,,116123519007302,,UNVERIFIED
icon_r3.hat,image,agent-generated,docs/v2/visual/art/icons/render_r3/hat.png,original artwork no third-party licence,,94710589109478,,UNVERIFIED
icon_r3.phone,image,agent-generated,docs/v2/visual/art/icons/render_r3/phone.png,original artwork no third-party licence,,136621488738903,,UNVERIFIED
icon_r3.quest,image,agent-generated,docs/v2/visual/art/icons/render_r3/quest.png,original artwork no third-party licence,,112252209152765,,UNVERIFIED
icon_r3.shop,image,agent-generated,docs/v2/visual/art/icons/render_r3/shop.png,original artwork no third-party licence,,100422070142864,,UNVERIFIED
icon_r3.tier_bagus,image,agent-generated,docs/v2/visual/art/icons/render_r3/tier_bagus.png,original artwork no third-party licence,,112466562604884,,UNVERIFIED
icon_r3.tier_biasa,image,agent-generated,docs/v2/visual/art/icons/render_r3/tier_biasa.png,original artwork no third-party licence,,90695650673648,,UNVERIFIED
icon_r3.tier_langka,image,agent-generated,docs/v2/visual/art/icons/render_r3/tier_langka.png,original artwork no third-party licence,,101704450642324,,UNVERIFIED
icon_r3.tier_sultan,image,agent-generated,docs/v2/visual/art/icons/render_r3/tier_sultan.png,original artwork no third-party licence,,104739847459422,,UNVERIFIED
icon_r3.tier_super,image,agent-generated,docs/v2/visual/art/icons/render_r3/tier_super.png,original artwork no third-party licence,,86600499251030,,UNVERIFIED
icon_r3.trophy,image,agent-generated,docs/v2/visual/art/icons/render_r3/trophy.png,original artwork no third-party licence,,105377004669039,,UNVERIFIED
```


### Uploaded 2026-11-20 (round 3 item 23 — CC0 + agent-generated model CANDIDATES, Open Cloud)

All 20 IDs were returned by completed `GET /assets/v1/operations/{id}` calls using the
`ROBLOX_API_KEY` route with `assetType=Model`; none was invented. Four are real CC0 Quaternius
downloads via Poly Pizza; sixteen are original deterministic low-poly geometry converted to GLB
by `models_r3/src/obj_to_glb.py`. Exact source URLs, authors, licences, triangle counts, MD5s and
operation IDs are in `models_r3/MANIFEST.md` and `models_r3/upload_manifest.json`. **All are
LookDev candidates behind the four family toggles, off by default, verdicts blank.**

```
slot,class,source,source_ref,licence,attribution,id,approved_by,status
model_r3.vegetation_r3/kelapa_cc0,model,cc0_download,docs/v2/visual/art/models_r3/raw/vegetation_r3/palm_quaternius.ply.glb,CC0 1.0 (Quaternius),Quaternius via poly.pizza,110335398915554,,UNVERIFIED
model_r3.vegetation_r3/bambu_cc0,model,cc0_download,docs/v2/visual/art/models_r3/raw/vegetation_r3/bamboo_quaternius.ply.glb,CC0 1.0 (Quaternius),Quaternius via poly.pizza,118009659509388,,UNVERIFIED
model_r3.npcs_r3/farmer_cc0,model,cc0_download,docs/v2/visual/art/models_r3/raw/npcs_r3/farmer_quaternius.ply.glb,CC0 1.0 (Quaternius),Quaternius via poly.pizza,109551357778200,,UNVERIFIED
model_r3.npcs_r3/polisi_cc0,model,cc0_download,docs/v2/visual/art/models_r3/raw/npcs_r3/swat_quaternius.ply.glb,CC0 1.0 (Quaternius),Quaternius via poly.pizza,95267863359958,,UNVERIFIED
model_r3.buildings_r3/rumah,model,agent_generated,docs/v2/visual/art/models_r3/export/buildings_r3/rumah_panggung.glb,original, CC0-equivalent,original deterministic generator,85063409548405,,UNVERIFIED
model_r3.buildings_r3/kandang,model,agent_generated,docs/v2/visual/art/models_r3/export/buildings_r3/kandang_ayam.glb,original, CC0-equivalent,original deterministic generator,119940478952704,,UNVERIFIED
model_r3.buildings_r3/gudang,model,agent_generated,docs/v2/visual/art/models_r3/export/buildings_r3/gudang_sawmill.glb,original, CC0-equivalent,original deterministic generator,111256303923528,,UNVERIFIED
model_r3.vegetation_r3/kelapa_alt,model,agent_generated,docs/v2/visual/art/models_r3/export/vegetation_r3/palm_tropical.glb,original, CC0-equivalent,original deterministic generator,109494105307245,,UNVERIFIED
model_r3.vegetation_r3/pisang,model,agent_generated,docs/v2/visual/art/models_r3/export/vegetation_r3/banana_tropical.glb,original, CC0-equivalent,original deterministic generator,101217327819812,,UNVERIFIED
model_r3.vegetation_r3/mangga,model,agent_generated,docs/v2/visual/art/models_r3/export/vegetation_r3/mango_tropical.glb,original, CC0-equivalent,original deterministic generator,121015860286403,,UNVERIFIED
model_r3.vegetation_r3/shrubs,model,agent_generated,docs/v2/visual/art/models_r3/export/vegetation_r3/shrubs_tropical.glb,original, CC0-equivalent,original deterministic generator,130954290306373,,UNVERIFIED
model_r3.props_r3/cart,model,agent_generated,docs/v2/visual/art/models_r3/export/props_r3/cart_gerobak.glb,original, CC0-equivalent,original deterministic generator,123070528502160,,UNVERIFIED
model_r3.props_r3/well,model,agent_generated,docs/v2/visual/art/models_r3/export/props_r3/well_sumur.glb,original, CC0-equivalent,original deterministic generator,108779169207130,,UNVERIFIED
model_r3.props_r3/stall,model,agent_generated,docs/v2/visual/art/models_r3/export/props_r3/market_stall.glb,original, CC0-equivalent,original deterministic generator,119525167329493,,UNVERIFIED
model_r3.props_r3/fence,model,agent_generated,docs/v2/visual/art/models_r3/export/props_r3/fencing_bambu.glb,original, CC0-equivalent,original deterministic generator,85094565897097,,UNVERIFIED
model_r3.props_r3/tools,model,agent_generated,docs/v2/visual/art/models_r3/export/props_r3/tools_set.glb,original, CC0-equivalent,original deterministic generator,110400413362502,,UNVERIFIED
model_r3.npcs_r3/villager_a,model,agent_generated,docs/v2/visual/art/models_r3/export/npcs_r3/npc_petani_caping.glb,original, CC0-equivalent,original deterministic generator,75743269173481,,UNVERIFIED
model_r3.npcs_r3/villager_b,model,agent_generated,docs/v2/visual/art/models_r3/export/npcs_r3/npc_pedagang.glb,original, CC0-equivalent,original deterministic generator,100304009103314,,UNVERIFIED
model_r3.npcs_r3/villager_c,model,agent_generated,docs/v2/visual/art/models_r3/export/npcs_r3/npc_petani_wanita.glb,original, CC0-equivalent,original deterministic generator,75017945133929,,UNVERIFIED
model_r3.npcs_r3/villager_d,model,agent_generated,docs/v2/visual/art/models_r3/export/npcs_r3/npc_tukang_peci.glb,original, CC0-equivalent,original deterministic generator,128549093376717,,UNVERIFIED
```


### Uploaded 2026-11-20 (round 3 item 24 — CC0 HDRI sky cube faces, Open Cloud)

All six IDs were returned by completed `GET /assets/v1/operations/{id}` calls using the
`ROBLOX_API_KEY` route with `assetType=Image`; none was invented. Source is the CC0 Poly Haven
HDRI `fish_hoek_beach` (Greg Zaal, Rico Cilliers), converted to six cube faces by
`sky_r3/src/make_cube_faces.py`. Source licence evidence and checksums are in
`sky_r3/MANIFEST.md`. **All are LookDev candidates behind `sky_r3`, off by default.**

```
slot,class,source,source_ref,licence,attribution,id,approved_by,status
sky_r3.SkyboxImageBack,image,polyhaven,docs/v2/visual/art/sky_r3/faces/SkyboxImageBack.png,CC0 1.0,Greg Zaal; Rico Cilliers,102550480946849,,UNVERIFIED
sky_r3.SkyboxImageBottom,image,polyhaven,docs/v2/visual/art/sky_r3/faces/SkyboxImageBottom.png,CC0 1.0,Greg Zaal; Rico Cilliers,129220381103008,,UNVERIFIED
sky_r3.SkyboxImageFront,image,polyhaven,docs/v2/visual/art/sky_r3/faces/SkyboxImageFront.png,CC0 1.0,Greg Zaal; Rico Cilliers,133281364333444,,UNVERIFIED
sky_r3.SkyboxImageLeft,image,polyhaven,docs/v2/visual/art/sky_r3/faces/SkyboxImageLeft.png,CC0 1.0,Greg Zaal; Rico Cilliers,138405045926458,,UNVERIFIED
sky_r3.SkyboxImageRight,image,polyhaven,docs/v2/visual/art/sky_r3/faces/SkyboxImageRight.png,CC0 1.0,Greg Zaal; Rico Cilliers,102997698570968,,UNVERIFIED
sky_r3.SkyboxImageTop,image,polyhaven,docs/v2/visual/art/sky_r3/faces/SkyboxImageTop.png,CC0 1.0,Greg Zaal; Rico Cilliers,119387111356535,,UNVERIFIED
```
