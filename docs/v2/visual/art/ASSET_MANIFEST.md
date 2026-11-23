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
| `sfx_jangkrik` | 9114894498 | Jungle Insects 1 (SFX) | ProSoundEffects | 46.016 s | Creator Store, free | Creator Store audio for use in Roblox experiences; terms are Roblox's, not re-read here; verified `IsLoaded = true`, len 46.016 s in Client Play VM on 2026-11-21 | designer to confirm |
| `sfx_ayam` | 9114370190 | Farm Animals Dog Barking Rooster Crows 2 (SFX) | ProSoundEffects | 51.604 s | Creator Store, free | same (verified `IsLoaded = true`, len 51.604 s in Client Play VM on 2026-11-21) | designer to confirm |
| `sfx_birds` | 9112750044 | Birds Quiet And Tranquil 1 (SFX) | ProSoundEffects | 36.009 s | Creator Store, free | same (verified `IsLoaded = true`, len 36.009 s in Client Play VM on 2026-11-21) | designer to confirm |
| `sfx_river` | 9118187543 | River Water 1 (SFX) | ProSoundEffects | 27.019 s | Creator Store, free | same (verified `IsLoaded = true`, len 27.019 s in Client Play VM on 2026-11-21) | designer to confirm |
| `sfx_wind` | 116565742544806 | The Wind (Ambience Version) | APMOfficial | 96.752 s | Creator Store, free | same (verified `IsLoaded = true`, len 96.752 s in Client Play VM on 2026-11-21) | designer to confirm |
| `sfx_kentongan` | 9046655769 | Oriental Gong 4 - Remastered | APMOfficial | 21.107 s | Creator Store, free | same (verified `IsLoaded = true`, len 21.107 s in Client Play VM on 2026-11-21) | designer to confirm |

The six `sfx_*` rows were added in round 9 item 92 (2026-11-21) after a fresh Creator Store free-audio
`search_asset` (Studio MCP, `scope=creator_store`, `assetType=Audio`, `priceFilter=free`). Each ID was
verified loading in a fresh Client Play VM (`Sound.IsLoaded = true`, `TimeLength` read, no
`not authorized`) before being recorded here. **All six are LookDev candidates awaiting designer
yes/no** — they are applied only by the off-by-default `sounds_r8` candidate; no shipping
`Config/Audio.sounds` slot was changed. No ID was invented. Evidence
`docs/v2/evidence/h/2026-11-21-round9/CHECK_092.txt`.

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
model_r3.props_r3/fence,model,agent_generated,docs/v2/visual/art/models_r3/export/props_r3/fencing_bambu.glb,original, CC0-equivalent,original deterministic generator; reused for R7 pagar_bambu in round 8 (WORK_QUEUE item 64),85094565897097,,UNVERIFIED
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

## Round 4 (2026-11-20)

WORK_QUEUE items 29–31. Eight LookDev candidates; all are OFF BY DEFAULT and nothing here is shipped on. Every ID below was read from a completed Open Cloud upload manifest; none was invented. All sources are CC0 or CC BY 3.0 with attribution recorded in the per-family manifests. No Creator Store, QAL/Quaternius, NC/ND, Free Standard or unknown licence was used. The `ROBLOX_API_KEY` was read from the environment only; it was never printed, logged or committed. Fields absent from a source manifest are marked `not recorded in source manifest`; CC0 rows with no mandatory credit are marked `not applicable (CC0)`.

Shared maps cross-checked: `src/shared/TextureMapR4.luau`, `SkyMapR4.luau`, `ModelMapBuildingsR4.luau`, `ModelMapVegetationR4.luau`, `ModelMapPropsR4.luau`, `ModelMapNpcsR4.luau`. Review order and saved cameras: `docs/v2/visual/REVIEW_ROUND4.md`. No visual verdict, screenshot, place save or publish is claimed here.

### `textures_r4` — 36 Image IDs, 12 CC0 PBR sets (CLIENT datamodel)

Source: `docs/v2/visual/art/textures_r4/{MANIFEST.md,upload_manifest.json,download_manifest.json}`. Licence URL per row: Poly Haven `https://polyhaven.com/license`, ambientCG `https://docs.ambientcg.com/license/`. The ambientCG API exposes no per-asset author field; the manifest records publisher `ambientCG`. Map key is the exact `TextureMapR4.ids` key.

| Slot / map key | Asset ID | Source URL | Author | Licence | CC BY attribution |
|---|---|---|---|---|---|
| withered_grass_diff (dry_grass) | 99291006551629 | https://polyhaven.com/a/withered_grass | Charlotte Baglioni | CC0 | not applicable (CC0) |
| withered_grass_nor (dry_grass) | 94138101324824 | https://polyhaven.com/a/withered_grass | Charlotte Baglioni | CC0 | not applicable (CC0) |
| withered_grass_rough (dry_grass) | 99517618599796 | https://polyhaven.com/a/withered_grass | Charlotte Baglioni | CC0 | not applicable (CC0) |
| red_laterite_soil_stones_diff (laterite) | 118381151358037 | https://polyhaven.com/a/red_laterite_soil_stones | Amal Kumar | CC0 | not applicable (CC0) |
| red_laterite_soil_stones_nor (laterite) | 80566522516796 | https://polyhaven.com/a/red_laterite_soil_stones | Amal Kumar | CC0 | not applicable (CC0) |
| red_laterite_soil_stones_rough (laterite) | 121928219739643 | https://polyhaven.com/a/red_laterite_soil_stones | Amal Kumar | CC0 | not applicable (CC0) |
| stony_dirt_path_diff (sand_path) | 103913932243276 | https://polyhaven.com/a/stony_dirt_path | eye-candy.xyz | CC0 | not applicable (CC0) |
| stony_dirt_path_nor (sand_path) | 117613154248787 | https://polyhaven.com/a/stony_dirt_path | eye-candy.xyz | CC0 | not applicable (CC0) |
| stony_dirt_path_rough (sand_path) | 86757243435143 | https://polyhaven.com/a/stony_dirt_path | eye-candy.xyz | CC0 | not applicable (CC0) |
| cobblestone_floor_04_diff (cobblestone) | 116548637306757 | https://polyhaven.com/a/cobblestone_floor_04 | Rob Tuytel | CC0 | not applicable (CC0) |
| cobblestone_floor_04_nor (cobblestone) | 114728267211735 | https://polyhaven.com/a/cobblestone_floor_04 | Rob Tuytel | CC0 | not applicable (CC0) |
| cobblestone_floor_04_rough (cobblestone) | 126631905530342 | https://polyhaven.com/a/cobblestone_floor_04 | Rob Tuytel | CC0 | not applicable (CC0) |
| weathered_planks_diff (weathered_planks) | 86925714541020 | https://polyhaven.com/a/weathered_planks | Dimitrios Savva (photography), Dario Barresi (processing) | CC0 | not applicable (CC0) |
| weathered_planks_nor (weathered_planks) | 139064505550988 | https://polyhaven.com/a/weathered_planks | Dimitrios Savva (photography), Dario Barresi (processing) | CC0 | not applicable (CC0) |
| weathered_planks_rough (weathered_planks) | 79209250273792 | https://polyhaven.com/a/weathered_planks | Dimitrios Savva (photography), Dario Barresi (processing) | CC0 | not applicable (CC0) |
| worn_brick_wall_diff (brick) | 101964656212261 | https://polyhaven.com/a/worn_brick_wall | Amal Kumar | CC0 | not applicable (CC0) |
| worn_brick_wall_nor (brick) | 74037970278315 | https://polyhaven.com/a/worn_brick_wall | Amal Kumar | CC0 | not applicable (CC0) |
| worn_brick_wall_rough (brick) | 79001558852046 | https://polyhaven.com/a/worn_brick_wall | Amal Kumar | CC0 | not applicable (CC0) |
| blue_plaster_weathered_diff (plaster) | 139342078063430 | https://polyhaven.com/a/blue_plaster_weathered | Amal Kumar | CC0 | not applicable (CC0) |
| blue_plaster_weathered_nor (plaster) | 111912632127012 | https://polyhaven.com/a/blue_plaster_weathered | Amal Kumar | CC0 | not applicable (CC0) |
| blue_plaster_weathered_rough (plaster) | 125017038971785 | https://polyhaven.com/a/blue_plaster_weathered | Amal Kumar | CC0 | not applicable (CC0) |
| clay_roof_tiles_03_diff (clay_tile) | 103194041286294 | https://polyhaven.com/a/clay_roof_tiles_03 | Amal Kumar | CC0 | not applicable (CC0) |
| clay_roof_tiles_03_nor (clay_tile) | 139690368710650 | https://polyhaven.com/a/clay_roof_tiles_03 | Amal Kumar | CC0 | not applicable (CC0) |
| clay_roof_tiles_03_rough (clay_tile) | 128237078059309 | https://polyhaven.com/a/clay_roof_tiles_03 | Amal Kumar | CC0 | not applicable (CC0) |
| worn_corrugated_iron_diff (corrugated_metal) | 107744112435438 | https://polyhaven.com/a/worn_corrugated_iron | Dimitrios Savva (photography), Jenelle van Heerden (processing) | CC0 | not applicable (CC0) |
| worn_corrugated_iron_nor (corrugated_metal) | 75878137977040 | https://polyhaven.com/a/worn_corrugated_iron | Dimitrios Savva (photography), Jenelle van Heerden (processing) | CC0 | not applicable (CC0) |
| worn_corrugated_iron_rough (corrugated_metal) | 134767952365897 | https://polyhaven.com/a/worn_corrugated_iron | Dimitrios Savva (photography), Jenelle van Heerden (processing) | CC0 | not applicable (CC0) |
| bamboo_wall_02_diff (bilik) | 104761377140093 | https://polyhaven.com/a/bamboo_wall_02 | Amal Kumar | CC0 | not applicable (CC0) |
| bamboo_wall_02_nor (bilik) | 75163422713451 | https://polyhaven.com/a/bamboo_wall_02 | Amal Kumar | CC0 | not applicable (CC0) |
| bamboo_wall_02_rough (bilik) | 137065390077687 | https://polyhaven.com/a/bamboo_wall_02 | Amal Kumar | CC0 | not applicable (CC0) |
| river_small_rocks_diff (riverbank) | 71678382965592 | https://polyhaven.com/a/river_small_rocks | Rob Tuytel, Rico Cilliers | CC0 | not applicable (CC0) |
| river_small_rocks_nor (riverbank) | 114207741022691 | https://polyhaven.com/a/river_small_rocks | Rob Tuytel, Rico Cilliers | CC0 | not applicable (CC0) |
| river_small_rocks_rough (riverbank) | 95462609294102 | https://polyhaven.com/a/river_small_rocks | Rob Tuytel, Rico Cilliers | CC0 | not applicable (CC0) |
| Ground026_diff (paddy_mud) | 140414409206785 | https://ambientcg.com/a/Ground026 | ambientCG | CC0 | not applicable (CC0) |
| Ground026_nor (paddy_mud) | 134530197365596 | https://ambientcg.com/a/Ground026 | ambientCG | CC0 | not applicable (CC0) |
| Ground026_rough (paddy_mud) | 138244821682090 | https://ambientcg.com/a/Ground026 | ambientCG | CC0 | not applicable (CC0) |


### `sky_r4_a` / `sky_r4_b` / `sky_r4_c` — 18 Image IDs, six faces each (CLIENT datamodel)

Source: `docs/v2/visual/art/sky_r4/{MANIFEST.md,upload_manifest.json}`. Source URL and author per option are from `MANIFEST.md` source tables; the six faces per option are the real Roblox `SkyboxBk/Dn/Ft/Lf/Rt/Up` properties from `SkyMapR4.sets`.

| Slot / map key | Asset ID | Source URL | Author | Licence | CC BY attribution |
|---|---|---|---|---|---|
| sky_r4_a / SkyboxBk | 97940752286667 | https://polyhaven.com/a/spiaggia_di_mondello | Andreas Mischok (All) | CC0 1.0 (Andreas Mischok) | not applicable (CC0) |
| sky_r4_a / SkyboxDn | 109773465243137 | https://polyhaven.com/a/spiaggia_di_mondello | Andreas Mischok (All) | CC0 1.0 (Andreas Mischok) | not applicable (CC0) |
| sky_r4_a / SkyboxFt | 114018733428334 | https://polyhaven.com/a/spiaggia_di_mondello | Andreas Mischok (All) | CC0 1.0 (Andreas Mischok) | not applicable (CC0) |
| sky_r4_a / SkyboxLf | 86909076207815 | https://polyhaven.com/a/spiaggia_di_mondello | Andreas Mischok (All) | CC0 1.0 (Andreas Mischok) | not applicable (CC0) |
| sky_r4_a / SkyboxRt | 134258485393561 | https://polyhaven.com/a/spiaggia_di_mondello | Andreas Mischok (All) | CC0 1.0 (Andreas Mischok) | not applicable (CC0) |
| sky_r4_a / SkyboxUp | 70901206015036 | https://polyhaven.com/a/spiaggia_di_mondello | Andreas Mischok (All) | CC0 1.0 (Andreas Mischok) | not applicable (CC0) |
| sky_r4_b / SkyboxBk | 71419208335886 | https://polyhaven.com/a/umhlanga_sunrise | Greg Zaal (All) | CC0 1.0 (Greg Zaal) | not applicable (CC0) |
| sky_r4_b / SkyboxDn | 103770664996498 | https://polyhaven.com/a/umhlanga_sunrise | Greg Zaal (All) | CC0 1.0 (Greg Zaal) | not applicable (CC0) |
| sky_r4_b / SkyboxFt | 100700369015271 | https://polyhaven.com/a/umhlanga_sunrise | Greg Zaal (All) | CC0 1.0 (Greg Zaal) | not applicable (CC0) |
| sky_r4_b / SkyboxLf | 130530246140479 | https://polyhaven.com/a/umhlanga_sunrise | Greg Zaal (All) | CC0 1.0 (Greg Zaal) | not applicable (CC0) |
| sky_r4_b / SkyboxRt | 93833019968519 | https://polyhaven.com/a/umhlanga_sunrise | Greg Zaal (All) | CC0 1.0 (Greg Zaal) | not applicable (CC0) |
| sky_r4_b / SkyboxUp | 74514704981621 | https://polyhaven.com/a/umhlanga_sunrise | Greg Zaal (All) | CC0 1.0 (Greg Zaal) | not applicable (CC0) |
| sky_r4_c / SkyboxBk | 115782120788932 | https://polyhaven.com/a/overcast_soil_puresky | Jarod Guest (Sky Edits), Sergej Majboroda (Original) | CC0 1.0 (Jarod Guest, Sergej Majboroda) | not applicable (CC0) |
| sky_r4_c / SkyboxDn | 115250718234620 | https://polyhaven.com/a/overcast_soil_puresky | Jarod Guest (Sky Edits), Sergej Majboroda (Original) | CC0 1.0 (Jarod Guest, Sergej Majboroda) | not applicable (CC0) |
| sky_r4_c / SkyboxFt | 130580645341750 | https://polyhaven.com/a/overcast_soil_puresky | Jarod Guest (Sky Edits), Sergej Majboroda (Original) | CC0 1.0 (Jarod Guest, Sergej Majboroda) | not applicable (CC0) |
| sky_r4_c / SkyboxLf | 90062986253718 | https://polyhaven.com/a/overcast_soil_puresky | Jarod Guest (Sky Edits), Sergej Majboroda (Original) | CC0 1.0 (Jarod Guest, Sergej Majboroda) | not applicable (CC0) |
| sky_r4_c / SkyboxRt | 71301261657357 | https://polyhaven.com/a/overcast_soil_puresky | Jarod Guest (Sky Edits), Sergej Majboroda (Original) | CC0 1.0 (Jarod Guest, Sergej Majboroda) | not applicable (CC0) |
| sky_r4_c / SkyboxUp | 124131521861721 | https://polyhaven.com/a/overcast_soil_puresky | Jarod Guest (Sky Edits), Sergej Majboroda (Original) | CC0 1.0 (Jarod Guest, Sergej Majboroda) | not applicable (CC0) |


### `buildings_r4` — 4 Model IDs, CC0 textured buildings (SERVER datamodel)

Source: `docs/v2/visual/art/models_r4/buildings/{SOURCE_LICENCES.md,upload_manifest.json}` (`MANIFEST.md` does not exist for this family). Licence and source URL per row are from `upload_manifest.json`; author is Grab3D. CC0 needs no credit; the source manifest records an optional provenance credit string, reproduced verbatim.

| Slot / map key | Asset ID | Source URL | Author | Licence | CC BY attribution |
|---|---|---|---|---|---|
| rumah | 134692206104779 | https://grab3d.com/models/buildings/stilt-house/ | Grab3D | CC0 1.0 Universal (public-domain dedication) | not applicable (CC0); optional provenance credit: "Models from Grab3D, CC0 1.0 Universal." |
| kandang | 102638587410748 | https://grab3d.com/models/buildings/chicken-coop/ | Grab3D | CC0 1.0 Universal (public-domain dedication) | not applicable (CC0); optional provenance credit: "Models from Grab3D, CC0 1.0 Universal." |
| gudang | 108444766706310 | https://grab3d.com/models/buildings/garden-shed/ | Grab3D | CC0 1.0 Universal (public-domain dedication) | not applicable (CC0); optional provenance credit: "Models from Grab3D, CC0 1.0 Universal." |
| warung | 123167704485524 | https://grab3d.com/models/buildings/market-stall/ | Grab3D | CC0 1.0 Universal (public-domain dedication) | not applicable (CC0); optional provenance credit: "Models from Grab3D, CC0 1.0 Universal." |


### `vegetation_r4` — 5 Model IDs, CC BY 3.0 textured vegetation (SERVER datamodel)

Source: `docs/v2/visual/art/models_r4/vegetation/{MANIFEST.md,upload_manifest.json}`. `mangga` is a Balsa-tree stand-in, not a verified mango tree; no ID was invented for the unavailable true-manga slot. Exact credit strings are from the upload manifest.

| Slot / map key | Asset ID | Source URL | Author | Licence | CC BY attribution |
|---|---|---|---|---|---|
| kelapa | 95769944522207 | https://poly.pizza/m/bXUTyfiwqBb | Poly by Google | CC BY 3.0 (Creative Commons Attribution) | "Coconut palm tree" by Poly by Google, CC BY 3.0, via Poly Pizza (https://poly.pizza/m/bXUTyfiwqBb) |
| pisang | 119293239911242 | https://poly.pizza/m/d0WJSiuOz6o | Poly by Google | CC BY 3.0 (Creative Commons Attribution) | "Banana Tree" by Poly by Google, CC BY 3.0, via Poly Pizza (https://poly.pizza/m/d0WJSiuOz6o) |
| bambu | 130965811347980 | https://poly.pizza/m/eixDUxUDkTK | Poly by Google | CC BY 3.0 (Creative Commons Attribution) | "Bamboo" by Poly by Google, CC BY 3.0, via Poly Pizza (https://poly.pizza/m/eixDUxUDkTK) |
| mangga | 103132734600778 | https://poly.pizza/m/ekCgu7iLrz2 | Poly by Google | CC BY 3.0 (Creative Commons Attribution) | "Balsa tree" by Poly by Google, CC BY 3.0, via Poly Pizza (https://poly.pizza/m/ekCgu7iLrz2) |
| shrubs | 116666781655827 | https://poly.pizza/m/aMGUklRjpyo | Poly by Google | CC BY 3.0 (Creative Commons Attribution) | "Shrub" by Poly by Google, CC BY 3.0, via Poly Pizza (https://poly.pizza/m/aMGUklRjpyo) |

#### Default tropical forest (WORK_QUEUE item 138)

The shipping `BackgroundForest` reuses exactly four verified `vegetation_r4` IDs above — `kelapa`
95769944522207, `pisang` 119293239911242, `bambu` 130965811347980 and `mangga` 103132734600778 —
through `Shared.ModelMapForestR9`. No new asset IDs, no new licences and no new attributions: the
CC BY 3.0 credits in the table apply unchanged. `shrubs` is not used by the forest; the procedural
fallback uses original parts only.


### `props_r4` — 7 Model IDs, CC0 / CC BY 3.0 textured props (SERVER datamodel)

Source: `docs/v2/visual/art/models_r4/props/{SOURCE_LICENSES.md,upload_manifest.json}`. The upload manifest records IDs and operation IDs only; source URL, author, licence and exact attribution strings below are from the "Per-slot source and exact attribution" table in `SOURCE_LICENSES.md`. CC0 rows carry the source manifest's recorded provenance string; no credit is mandatory for them.

| Slot / map key | Asset ID | Source URL | Author | Licence | CC BY attribution |
|---|---|---|---|---|---|
| gerobak | 119426685469058 | https://poly.pizza/m/f_LuAcP2_Yh | Alan Zimmerman | Creative Commons Attribution (CC BY 3.0) — https://creativecommons.org/licenses/by/3.0/ | "Street Vendor Cart" by Alan Zimmerman — Poly Pizza, CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/), source https://poly.pizza/m/f_LuAcP2_Yh |
| sumur | 95025959179405 | https://poly.pizza/m/1lK9mD0zDZw | Jarlan Perez | Creative Commons Attribution (CC BY 3.0) — https://creativecommons.org/licenses/by/3.0/ | "Well" by Jarlan Perez — Poly Pizza, CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/), source https://poly.pizza/m/1lK9mD0zDZw |
| lapak | 115924626989907 | https://poly.pizza/m/bwgNq3z2SQs | Peter Simcoe | Creative Commons Attribution (CC BY 3.0) — https://creativecommons.org/licenses/by/3.0/ | "Small stand with Wheels" by Peter Simcoe — Poly Pizza, CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/), source https://poly.pizza/m/bwgNq3z2SQs |
| pagar_bambu | 103341007913673 | https://poly.pizza/m/dVwByrifEmj | Jarlan Perez | Creative Commons Attribution (CC BY 3.0) — https://creativecommons.org/licenses/by/3.0/ | "Bamboo Fence Panel" by Jarlan Perez — Poly Pizza, CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/), source https://poly.pizza/m/dVwByrifEmj |
| alat_tani | 109848917287023 | https://polyhaven.com/a/wooden_axe | Ulan Cabanilla | CC0 1.0 — https://polyhaven.com/license | "Wooden Axe" by Ulan Cabanilla — Poly Haven, CC0 1.0 (https://polyhaven.com/license), source https://polyhaven.com/a/wooden_axe |
| karung | 87487192428396 | https://polyhaven.com/a/cement_bag | PierreB3D | CC0 1.0 — https://polyhaven.com/license | "Cement Bag" by PierreB3D — Poly Haven, CC0 1.0 (https://polyhaven.com/license), source https://polyhaven.com/a/cement_bag |
| jemuran | 138444489439223 | https://grab3d.com/models/props/clothesline/ | Grab3D | CC0 1.0 Universal — https://creativecommons.org/publicdomain/zero/1.0/legalcode | "Clothesline" by Grab3D — CC0 1.0 Universal, no attribution required (https://creativecommons.org/publicdomain/zero/1.0/legalcode), source https://grab3d.com/models/props/clothesline/, licence text https://grab3d.com/dl/clothesline/LICENSE.txt |


### props_r8 — round-8 prop replacements (R7 look only, SERVER datamodel)

WORK_QUEUE item 64. These three IDs replace the weak R4 props **only in `props_r7`**;
R4/R5/R6 maps and their IDs are unchanged. The two Creator Store models are free and were
loaded in Edit mode with `game:GetObjects("rbxassetid://<id>")` (each returned a valid Model).
All three were measured in Studio on 2026-11-21. No licence is claimed beyond what is recorded
here: Creator Store terms apply to the two store models. No visual verdict, place save or
publish is claimed.

| Slot / map key | Asset ID | Source URL | Creator | Notes |
|---|---|---|---|---|
| alat_tani | 4951145641 | https://create.roblox.com/store/asset/4951145641 | Creator Store listing (creator not verified) | "Cangkul"; replaces wooden axe 109848917287023. Native bbox 2.7 x 5.2 x 2 studs, upright. Final staged height 4.0 studs (band 3.5-4.5). Creator Store terms apply. |
| gerobak | 10506531785 | https://create.roblox.com/store/asset/10506531785 | Creator Store listing (creator not verified) | "Gerobak"; replaces modern wheelbarrow 119426685469058. Native bbox 5.5 x 9 x 13.5 studs, long axis Z. Final staged height 3.33 studs, giving a 4.995-stud long axis (band 4-6). Creator Store terms apply. |
| pagar_bambu | 85094565897097 | docs/v2/visual/art/models_r3/export/props_r3/fencing_bambu.glb | agent-generated | Reused `model_r3.props_r3/fence`; replaces barely visible 103341007913673. Native bbox 4.1 x 1.5 x 0.1 studs, long axis X. Final staged height 3.05 studs gives ~8.34 studs long; `ry = 0`. |


### `npcs_r4` — 5 Model IDs, CC0 / CC BY 3.0 textured villagers (SERVER datamodel)

Source: `docs/v2/visual/art/models_r4/npcs/{MANIFEST.md,upload_manifest.json}`. Exact attribution strings are from the upload manifest and match `MANIFEST.md`; CC0 rows still carry the recorded provenance string but need no credit. None of these models ships an R15 rig; they are review dummies only.

| Slot / map key | Asset ID | Source URL | Author | Licence | CC BY attribution |
|---|---|---|---|---|---|
| petani_caping | 119484467697394 | https://poly.pizza/m/f-ePrCSeNjW | Remy Tauziac | CC-BY 3.0 | "Pleasant peasant" by Remy Tauziac — CC-BY 3.0 (https://creativecommons.org/licenses/by/3.0/); source: https://poly.pizza/m/f-ePrCSeNjW |
| pedagang | 77509780044045 | https://poly.pizza/m/kpw4fiF8St | J-Toastie | CC-BY 3.0 | "Retail Worker" by J-Toastie — CC-BY 3.0 (https://creativecommons.org/licenses/by/3.0/); source: https://poly.pizza/m/kpw4fiF8St |
| petani_wanita | 123174857731098 | https://poly.pizza/m/usAZvwbH0Y | Polygonal Mind | CC0 1.0 | "Woman" by Polygonal Mind — CC0 1.0 (https://creativecommons.org/publicdomain/zero/1.0/); source: https://poly.pizza/m/usAZvwbH0Y |
| tukang_peci | 115389644627447 | https://poly.pizza/m/IE7rk47BHn | prathm | CC0 1.0 | "Character_Man" by prathm — CC0 1.0 (https://creativecommons.org/publicdomain/zero/1.0/); source: https://poly.pizza/m/IE7rk47BHn |
| polisi | 105455683512183 | https://poly.pizza/m/ipEgtSYI8u | J-Toastie | CC-BY 3.0 | "Male Officer" by J-Toastie — CC-BY 3.0 (https://creativecommons.org/licenses/by/3.0/); source: https://poly.pizza/m/ipEgtSYI8u |

## Round 6 (2026-11-20) — `sky_r6_a`..`sky_r6_f` Creator Store skies (CLIENT datamodel)

Source: six real free Creator Store Models loaded with `InsertService:LoadAsset` in the Server
datamodel of a Play-Solo Studio VM; exact face IDs read from the first `Sky` descendant of each.
Provenance: `docs/v2/evidence/h/2026-11-20-sky-r6-asset-load/REPORT.md` (`SEEN-IN-STUDIO` for the
asset load and face-ID read only). Pure data: `src/shared/SkyMapR6.luau`; applier:
`src/client/World/LookDevSkyR6.luau`. Licence per row: Creator Store free model (`isFree=true`,
`priceCents=0` at `search_asset` time). Models `e`/`f` contain scripts; the applier copies only the
six Sky faces, never any script. All are LookDev candidates behind `sky_r6_*`, off by default. **No
visual was graded; every verdict / approved-by cell is blank.** `sky_r5` is the unchanged baseline.

### Models

| Model ID | Creator Store name | Creator | Store URL | Licence | Source evidence | Approved by |
|---|---|---|---|---|---|---|
| 4607457995 | Realistic Sky | Xeksworld08 | https://create.roblox.com/store/asset/4607457995 | Creator Store free model | `h/2026-11-20-sky-r6-asset-load/REPORT.md` |  |
| 10256505900 | Sky-Realistic | Dev_Flowey | https://create.roblox.com/store/asset/10256505900 | Creator Store free model | `h/2026-11-20-sky-r6-asset-load/REPORT.md` |  |
| 9589448285 | Realistic Clear Sky | HeyItzDaredevil | https://create.roblox.com/store/asset/9589448285 | Creator Store free model | `h/2026-11-20-sky-r6-asset-load/REPORT.md` |  |
| 11219565245 | Realistic Clear Skies (SKYBOX) | TrainMaker6 | https://create.roblox.com/store/asset/11219565245 | Creator Store free model | `h/2026-11-20-sky-r6-asset-load/REPORT.md` |  |
| 71778157196658 | Blue Sky W Scattered Clouds Daytime Skybox Light | Rozosere48 | https://create.roblox.com/store/asset/71778157196658 | Creator Store free model | `h/2026-11-20-sky-r6-asset-load/REPORT.md` |  |
| 79778158338852 | Sunless blue sky skybox realistic clouds | f0xz08 | https://create.roblox.com/store/asset/79778158338852 | Creator Store free model | `h/2026-11-20-sky-r6-asset-load/REPORT.md` |  |

### Sky face IDs — 36 rows

Source URL per row is the owning model's Store URL above. Legacy `http://www.roblox.com/asset/?id=N`
was normalised to the integer `N`; `sky_r6_d` repeats Ft/Lf/Rt exactly as the loaded model does.

| Slot / map key | Asset ID | Source URL | Creator | Licence | Approved by |
|---|---:|---|---|---|---|
| sky_r6_a / SkyboxBk | 150335574 | https://create.roblox.com/store/asset/4607457995 | Xeksworld08 | Creator Store free model |  |
| sky_r6_a / SkyboxDn | 150335585 | https://create.roblox.com/store/asset/4607457995 | Xeksworld08 | Creator Store free model |  |
| sky_r6_a / SkyboxFt | 150335628 | https://create.roblox.com/store/asset/4607457995 | Xeksworld08 | Creator Store free model |  |
| sky_r6_a / SkyboxLf | 150335620 | https://create.roblox.com/store/asset/4607457995 | Xeksworld08 | Creator Store free model |  |
| sky_r6_a / SkyboxRt | 150335610 | https://create.roblox.com/store/asset/4607457995 | Xeksworld08 | Creator Store free model |  |
| sky_r6_a / SkyboxUp | 150335642 | https://create.roblox.com/store/asset/4607457995 | Xeksworld08 | Creator Store free model |  |
| sky_r6_b / SkyboxBk | 144933338 | https://create.roblox.com/store/asset/10256505900 | Dev_Flowey | Creator Store free model |  |
| sky_r6_b / SkyboxDn | 144931530 | https://create.roblox.com/store/asset/10256505900 | Dev_Flowey | Creator Store free model |  |
| sky_r6_b / SkyboxFt | 144933262 | https://create.roblox.com/store/asset/10256505900 | Dev_Flowey | Creator Store free model |  |
| sky_r6_b / SkyboxLf | 144933244 | https://create.roblox.com/store/asset/10256505900 | Dev_Flowey | Creator Store free model |  |
| sky_r6_b / SkyboxRt | 144933299 | https://create.roblox.com/store/asset/10256505900 | Dev_Flowey | Creator Store free model |  |
| sky_r6_b / SkyboxUp | 144931564 | https://create.roblox.com/store/asset/10256505900 | Dev_Flowey | Creator Store free model |  |
| sky_r6_c / SkyboxBk | 9544505500 | https://create.roblox.com/store/asset/9589448285 | HeyItzDaredevil | Creator Store free model |  |
| sky_r6_c / SkyboxDn | 9544547905 | https://create.roblox.com/store/asset/9589448285 | HeyItzDaredevil | Creator Store free model |  |
| sky_r6_c / SkyboxFt | 9544504852 | https://create.roblox.com/store/asset/9589448285 | HeyItzDaredevil | Creator Store free model |  |
| sky_r6_c / SkyboxLf | 9544547694 | https://create.roblox.com/store/asset/9589448285 | HeyItzDaredevil | Creator Store free model |  |
| sky_r6_c / SkyboxRt | 9544547542 | https://create.roblox.com/store/asset/9589448285 | HeyItzDaredevil | Creator Store free model |  |
| sky_r6_c / SkyboxUp | 9544547398 | https://create.roblox.com/store/asset/9589448285 | HeyItzDaredevil | Creator Store free model |  |
| sky_r6_d / SkyboxBk | 91458002 | https://create.roblox.com/store/asset/11219565245 | TrainMaker6 | Creator Store free model |  |
| sky_r6_d / SkyboxDn | 91457980 | https://create.roblox.com/store/asset/11219565245 | TrainMaker6 | Creator Store free model |  |
| sky_r6_d / SkyboxFt | 91458024 | https://create.roblox.com/store/asset/11219565245 | TrainMaker6 | Creator Store free model |  |
| sky_r6_d / SkyboxLf | 91458024 | https://create.roblox.com/store/asset/11219565245 | TrainMaker6 | Creator Store free model |  |
| sky_r6_d / SkyboxRt | 91458024 | https://create.roblox.com/store/asset/11219565245 | TrainMaker6 | Creator Store free model |  |
| sky_r6_d / SkyboxUp | 91458002 | https://create.roblox.com/store/asset/11219565245 | TrainMaker6 | Creator Store free model |  |
| sky_r6_e / SkyboxBk | 2835173905 | https://create.roblox.com/store/asset/71778157196658 | Rozosere48 | Creator Store free model |  |
| sky_r6_e / SkyboxDn | 2493829793 | https://create.roblox.com/store/asset/71778157196658 | Rozosere48 | Creator Store free model |  |
| sky_r6_e / SkyboxFt | 2835177931 | https://create.roblox.com/store/asset/71778157196658 | Rozosere48 | Creator Store free model |  |
| sky_r6_e / SkyboxLf | 2835174704 | https://create.roblox.com/store/asset/71778157196658 | Rozosere48 | Creator Store free model |  |
| sky_r6_e / SkyboxRt | 2835177433 | https://create.roblox.com/store/asset/71778157196658 | Rozosere48 | Creator Store free model |  |
| sky_r6_e / SkyboxUp | 2835175409 | https://create.roblox.com/store/asset/71778157196658 | Rozosere48 | Creator Store free model |  |
| sky_r6_f / SkyboxBk | 591058823 | https://create.roblox.com/store/asset/79778158338852 | f0xz08 | Creator Store free model |  |
| sky_r6_f / SkyboxDn | 591059876 | https://create.roblox.com/store/asset/79778158338852 | f0xz08 | Creator Store free model |  |
| sky_r6_f / SkyboxFt | 591058104 | https://create.roblox.com/store/asset/79778158338852 | f0xz08 | Creator Store free model |  |
| sky_r6_f / SkyboxLf | 591057861 | https://create.roblox.com/store/asset/79778158338852 | f0xz08 | Creator Store free model |  |
| sky_r6_f / SkyboxRt | 591057625 | https://create.roblox.com/store/asset/79778158338852 | f0xz08 | Creator Store free model |  |
| sky_r6_f / SkyboxUp | 591059642 | https://create.roblox.com/store/asset/79778158338852 | f0xz08 | Creator Store free model |  |

## Round 6 (2026-11-20) — `npcs_r6` villager costumes (Image assets, SERVER datamodel)

Source: ten original classic-clothing Shirt/Pants templates (585×559, one per role) drawn by
`docs/v2/visual/art/models_r6/npcs/src/generate_templates.py` and uploaded as **Image** assets through
the verified `ROBLOX_API_KEY` Open Cloud `POST /assets/v1/assets` route by
`docs/v2/visual/art/models_r6/npcs/src/upload.py`. Every ID below comes from a COMPLETED operation and
is recorded in `docs/v2/visual/art/models_r6/npcs/upload_manifest.json`; none was invented. Open Cloud
cannot create Shirt/Pants asset types, so these are Image IDs set directly on
`Shirt.ShirtTemplate` / `Pants.PantsTemplate` of a `Shirt`/`Pants` sibling of each R15 Humanoid (not via
`HumanoidDescription`). Layout and constraints: `docs/v2/evidence/h/2026-11-20-r6-costume-template-layout/REPORT.md`.
Moderation state at upload time is recorded honestly — nine were `Reviewing`, one `Approved`; the
candidate is off by default and no visual was graded. **Every approved-by cell is blank.**

| Slot | Asset ID | Type | Role / kind | Moderation at upload | Source evidence | Approved by |
|---|---:|---|---|---|---|---|
| `shirt_polisi` | 113212316103784 | Image | polisi / shirt | Reviewing | `models_r6/npcs/upload_manifest.json` |  |
| `pants_polisi` | 98102154190902 | Image | polisi / pants | Reviewing | `models_r6/npcs/upload_manifest.json` |  |
| `shirt_pak_rt` | 117485364703264 | Image | pak_rt / shirt | Reviewing | `models_r6/npcs/upload_manifest.json` |  |
| `pants_pak_rt` | 127593796770640 | Image | pak_rt / pants | Reviewing | `models_r6/npcs/upload_manifest.json` |  |
| `shirt_petani` | 112086829394587 | Image | petani / shirt | Reviewing | `models_r6/npcs/upload_manifest.json` |  |
| `pants_petani` | 130876277340560 | Image | petani / pants | Reviewing | `models_r6/npcs/upload_manifest.json` |  |
| `shirt_pedagang` | 71100897124673 | Image | pedagang / shirt | Reviewing | `models_r6/npcs/upload_manifest.json` |  |
| `pants_pedagang` | 139244403929211 | Image | pedagang / pants | Approved | `models_r6/npcs/upload_manifest.json` |  |
| `shirt_petani_wanita` | 105653588811968 | Image | petani_wanita / shirt | Reviewing | `models_r6/npcs/upload_manifest.json` |  |
| `pants_petani_wanita` | 76370296974052 | Image | petani_wanita / pants | Reviewing | `models_r6/npcs/upload_manifest.json` |  |

### Round-7 villager clothing templates (`npcs_r7`)

Original 585×559 classic Shirt/Pants templates regenerated for round 7. Uploaded 2026-11-20 as
Images via Open Cloud (`ROBLOX_API_KEY`, creator userId 172146044); every ID is from a completed
operation in `models_r7/npcs/upload_manifest.json`. The designer reviewed the actual PNGs and the
2×2 contact sheet (`models_r7/npcs/COSTUMES_SHEET.png`) and gave PASS on 2026-11-20. These four IDs
replace their R6 counterparts in `ModelMapNpcsR7.COSTUMES`; the other six costume fields stay R6.
The candidate is off by default and no place was saved or published.

| Slot | Asset ID | Type | Role / kind | Moderation at upload | Source evidence | Approved by |
|---|---:|---|---|---|---|---|
| `shirt_pak_rt` | 92996938301042 | Image | pak_rt / shirt | Reviewing | `models_r7/npcs/upload_manifest.json` | designer (PNG + sheet PASS 2026-11-20) |
| `shirt_polisi` | 133590758790821 | Image | polisi / shirt | Reviewing | `models_r7/npcs/upload_manifest.json` | designer (PNG + sheet PASS 2026-11-20) |
| `pants_polisi` | 98235919851901 | Image | polisi / pants | Reviewing | `models_r7/npcs/upload_manifest.json` | designer (PNG + sheet PASS 2026-11-20) |
| `shirt_petani` | 81581201405716 | Image | petani / shirt | Reviewing | `models_r7/npcs/upload_manifest.json` | designer (PNG + sheet PASS 2026-11-20) |

### Catalog outfits (`npcs_r7`, designer-picked 2026-11-21)

These are real avatar-catalog items found with the catalog search API. NPCs wear them through `HumanoidDescription`, which needs no ownership. They replace the drawn Image templates and the built peci.

| Role | Asset ID | Catalog type | Name (creator) |
|---|---:|---|---|
| petani | 109842878942326 | Shirt | Petani (Trocadero Clothing) |
| petani | 96146120958106 | Pants | Petani (Trocadero Clothing) |
| petani | 90801645168902 | Hat | Rice Farmer Hat (Rey x Noob) |
| petani_wanita | 107918452722296 | Shirt | Petani (Trocadero Clothing) |
| petani_wanita, pedagang | 72201288248343 | Pants | Petani (Trocadero Clothing) |
| petani_wanita | 129076562650877 | Hat | Hijab (Our Deen) |
| pedagang | 3604934784 | Shirt | Merchant Shirt (Blotnik) |
| pak_rt | 18903905363 | ShirtAccessory (layered) | Batik (Yellow) (Asosiasi Komunitas Roblox Indonesia) |
| pak_rt, polisi | 73000190682589 | Pants | Polisi (Trocadero Clothing) |
| pak_rt | 73748899536912 | Hat | Songkok (Ketupat's Clothing) |
| polisi | 134524039208416 | Shirt | Polisi (Trocadero Clothing) |
| polisi | 122271821782451 | Hat | Police Cap (FIREBRAND!) |

Approved by the designer on 2026-11-21: row A for all roles and batik B2 for Pak RT. Evidence: `h/2026-11-21-catalog-outfits/`.

### Catalog outfits (`npcs_r8`, WORK_QUEUE section M item 86, 2026-11-21)

Five new villager roles. Every ID is a real avatar-catalog asset: found with the catalog search API
(`catalog.roblox.com/v1/search/items?keyword=...&limit=10`, 4 s between calls) and its Name,
AssetTypeId and Creator re-read from `economy.roblox.com/v2/assets/<id>/details`. No ID was invented.
NPCs wear them through `HumanoidDescription` (no ownership needed). All five shirt+pants pairs are
distinct and every role has a hat. Pure data: `src/shared/ModelMapNpcsR8.luau`.

| Role | Asset ID | Catalog type | Name (creator) |
|---|---:|---|---|
| tengkulak | 11755115818 | Shirt (11) | [+] Merchant (SinTLORii Clothing) |
| tengkulak | 121010548089939 | Pants (12) | Petani (Trocadero Clothing) |
| tengkulak | 76392482317942 | Hat (8) | Young Entrepreneur (acid souljah) |
| debt_collector | 5601091452 | Shirt (11) | Uniform (?INSIDE?) |
| debt_collector | 104437888647181 | Pants (12) | uniform (wauf) |
| debt_collector | 122870229188390 | Hat (8) | Police Balaclava [Blood Debt] (The Place 3) |
| ibu_warung | 135555867890569 | ShirtAccessory / layered (65) | Batik modern Jawa Wanita V2 (TriangleStudioo) |
| ibu_warung | 94473038627675 | Pants (12) | Petani (Trocadero Clothing) |
| ibu_warung | 99279983172002 | Hat (8) | Hijab (Our Deen) |
| anak_anak | 17550183186 | Shirt (11) | uniform (nekowo) |
| anak_anak | 14798718772 | Pants (12) | basic pants (VloyL) |
| anak_anak | 90295258026402 | Hat (8) | Kid (ufotabIe) |
| bapak_ojek | 129826976931984 | Shirt (11) | Petani (Trocadero Clothing) |
| bapak_ojek | 79151443926768 | Pants (12) | Petani (Trocadero Clothing) |
| bapak_ojek | 16100797199 | Hat (8) | Classic Taxi Hat (rblx?) |

`anak_anak` also sets `HumanoidDescription.BodyHeightScale` 0.8 and `HeadScale` 1.2 for the kid
proportions — these are scale properties, not asset IDs. Catalogue licence not re-read here; Roblox
catalog terms apply. Visual yes/no is the designer's; this manifest only records provenance.

### Idle animation (`npcs_idle_r8`, WORK_QUEUE section M item 87, 2026-11-21)

| Role | Asset ID | Catalog type | Name (creator) |
|---|---:|---|---|
| villager idle | 71483261700852 | Animation (61) | Standing Idle (unhoIygraiI) |

Found with the catalog search API (`keyword=standing+idle&limit=10`), Name/AssetTypeId/Creator
re-read from `economy.roblox.com/v2/assets/71483261700852/details`. No ID was invented. Applied via
`Animator:LoadAnimation(Animation)` with `rbxassetid://71483261700852`, `Looped = true`, `Play()`.
Empirically proven to load and report `track.IsPlaying == true` on R15 rigs in the Studio Server VM
on 2026-11-21 (before wiring). Catalogue licence not re-read here; Roblox catalog terms apply.

### buildings_r8 — six free Creator Store buildings (round 9, item 77, SERVER datamodel)

WORK_QUEUE section M item 77. All six IDs came from real Creator Store `search_asset` (free-filter)
results; none was invented. They are already baked live in
`ServerStorage.LookDevAssets.<id>` (scripts stripped, one Model child each) by
`tools/studio/bake_lookdev_assets.luau`; the applier uses clone-first loading. No place was saved and
nothing was published. Asset `10019841237` was rejected (no clear ground-floor opening) and is not
listed. Pure data: `src/shared/ModelMapBuildingsR8.luau`; applier:
`src/server/World/LookDevBuildingsR8.luau`. Licence was not re-read here — Creator Store terms apply.
All are LookDev candidates behind `buildings_r8`, off by default; look grading is pending.

| Slot | Asset ID | Name | Creator | Source | Licence note | Approved by |
|---|---|---|---|---|---|---|
| indonesian_house | 81909711760416 | indonesian_house | Dagelan_Smg | Creator Store, free | Creator Store free model; Roblox Creator Store terms; licence not re-read here | designer to confirm |
| rumah_4 | 140621903274156 | rumah_4 | Dagelan_Smg | Creator Store, free | Creator Store free model; Roblox Creator Store terms; licence not re-read here | designer to confirm |
| rumah_joglo | 4820552419 | rumah_joglo | Annovaire | Creator Store, free | Creator Store free model; Roblox Creator Store terms; licence not re-read here | designer to confirm |
| pendopo_jawa | 136417251697510 | pendopo_jawa | Pramadhita_wira | Creator Store, free | Creator Store free model; Roblox Creator Store terms; licence not re-read here | designer to confirm |
| warung_penyetan | 118767493095408 | warung_penyetan | Voltcho1354 | Creator Store, free | Creator Store free model; Roblox Creator Store terms; licence not re-read here | designer to confirm |
| nipa_hut | 167594119 | nipa_hut | SanchettaSam ("Nipa Hut Set") | Creator Store, free | Creator Store free model; Roblox Creator Store terms; licence not re-read here | designer to confirm |

### hubprops_r8 — per-hub props (round 9, item 79, SERVER datamodel)

Item 79 reuses only assets already recorded above with real IDs and licences: `karung`
87487192428396 (CC0, line 416), `pagar_bambu` 85094565897097 (agent-generated CC0-equivalent,
line 277) and 103341007913673 (CC BY 3.0, line 414), `jemuran` 138444489439223 (CC0, line 417),
`lapak` 115924626989907 (CC BY 3.0, line 413), `gerobak` 119426685469058 (CC BY 3.0, line 411)
and 10506531785 (Creator Store, line 432), `sumur` 95025959179405 (CC BY 3.0, line 412), and the
real Poly Pizza CC0 motor `106061905410704` (line 99). The motor was newly baked this run from its
verified ID into `ServerStorage.LookDevAssets.106061905410704` (scripts stripped); no place was
saved. Kinds with no verified free asset were made from primitives as step 4 of D15 and are pure
data in `src/shared/ModelMapHubPropsR8.luau` — no ID was invented for them.

Step-2 ladder asset (D15): the Studio MCP `generate_procedural_model` tool produced a low-poly
`BambooBasket` (generationId `14b48661-4c08-425f-ab3f-c641c1a885fd`, tag
`PrimitiveGen_14b48661-4c08-425f-ab3f-c641c1a885fd`, 18 primitive parts, native bbox ~4.24 x 4.24
x 2.6 studs). This is an agent-generated original work, CC0-equivalent, not a Roblox asset ID. All
scripts on the generated `ProceduralModel` were stripped and the static geometry was baked
runtime-only into `ServerStorage.LookDevAssets.generated_bamboo_basket`. It ships only inside the
OFF-by-default `hubprops_r8` LookDev candidate; look grading is pending the designer.

## Manifest coverage (WORK_QUEUE item 127, 2026-11-22)

Every 7–15-digit asset ID in `src/shared/*Map*.luau` must appear in this manifest. The
`ASSET_MANIFEST_COVERAGE` spec scans those modules and the whole of `src/`: an unmarked manifest ID
must have a code reference; one with no code reference must carry an `unused` row below. The two
`2147483646`/`2147483647` literals in the pure-data modules are RNG moduli, not asset IDs, and are
excluded from the scan. Nothing was deleted from code to make this section pass.

### Previously uncovered map IDs — added 2026-11-22

| Slot | Asset ID | Source module | Provenance | Status |
|---|---|---|---|---|
| `lidah_mertua` | 184362803 | `src/shared/ModelMapVegetationR6.luau` | free Creator Store Model; `docs/v2/evidence/h/2026-11-20-r6-vegetation-ids/REPORT.md` | recorded here |
| `alang_alang` | 361802126 | `src/shared/ModelMapVegetationR6.luau` | free Creator Store Model; same REPORT | recorded here |
| `lidah_mertua` (alternate) | 5445549227 | `src/shared/ModelMapVegetationR6.luau` | free Creator Store Model shortlist; same REPORT | recorded here, not loaded |
| `teh_tehan` | 8864962424 | `src/shared/ModelMapVegetationR6.luau` | Bush / Shrub, Zoriontsu716; same REPORT | recorded here |
| `bunga` | 9639782964 | `src/shared/ModelMapVegetationR6.luau` | FlowerBush, EmeraldKingExtabyte; same REPORT | recorded here |
| `kembang_sepatu` (alternate) | 115462020907259 | `src/shared/ModelMapVegetationR6.luau` | free Creator Store Model shortlist; same REPORT | recorded here, not loaded |
| `kembang_sepatu` | 15344074131 | `src/shared/ModelMapVegetationR6.luau` | free Creator Store Model; same REPORT | recorded here |
| `caping_backup` | 14769019514 | `src/shared/ModelMapNpcsR5.luau` | Oriental Bamboo Conical Hat, RZKU; Creator Store FREE, Model | recorded here |
| `caping` | 71002247087415 | `src/shared/ModelMapNpcsR5.luau` | Chinese Straw Hat Asian Conical Rice Farmer Hats, Zephban5961; Creator Store FREE, Model | recorded here |
| `polisi_cap` | 126970096704856 | `src/shared/ModelMapNpcsR5.luau` | Police Hat Cap Cop Officer Headwear Hats Accessory, Mukamato101; Creator Store FREE, Model | recorded here |

The three hat IDs above were already present in code (`ModelMapNpcsR5.accessories`) with creator,
name and store URL; the seven vegetation IDs were already present in `ModelMapVegetationR6.ids` /
`.alternates` with a shortlist REPORT. This section only closes the manifest gap.

### section Q — sourced 3D models (Creator Store, free)

WORK_QUEUE section Q, round 11. IDs from real Creator Store `search_asset` free-filter results,
baked live into `ServerStorage.LookDevAssets.<id>` (scripts stripped, no place saved, nothing
published). None invented. The baked copy is verified in a fresh Play/Server VM with
`tools/studio/check_q187.luau` (evidence `docs/v2/evidence/h/2026-11-22-round11/CHECK_187.txt`).

| Slot | Asset ID | Name | Creator | Type | Source | Baked size (studs) | Approved by |
|---|---|---|---|---|---|---|---|
| `padi_model` | 13286158859 | Meshes/rice2 | Polyslayer1 | MeshPart | Creator Store, free | 1.07 x 3.52 x 1.51 (widest 1.51 <= 2) | designer to confirm (LookDev candidate; wired by item 191) |
| `fountain_model` | 93434732057582 | Fountain | Sonisn1810 | Model (7 parts) | Creator Store, free | 15.24 x 17.36 x 17.35 (scaled to 16-stud basin in `plaza_r9`) | designer to confirm (LookDev candidate) |
| `rock_round` | 16098456067 | Low-Poly Rock | Jajkopko_XD | MeshPart (1 part) | Creator Store, free | 5.00 x 5.04 x 5.24 | designer to confirm (LookDev candidate; wired by item 189) |
| `rock_flat` | 5644862709 | Rock | Tman_TheNoobKing | MeshPart (1 part) | Creator Store, free | 2.11 x 1.05 x 2.26 | designer to confirm (LookDev candidate; wired by item 189) |
| `rock_tall` | 53370997 | Rock Pillar | EmperorZenith | Model (2 parts) | Creator Store, free | 16 x 28.8 x 17 | designer to confirm (LookDev candidate; wired by item 189) |
| `path_grass` | 806579390 | Grass tuft | a61766 | Model (6 parts) | Creator Store, free | 2.12 x 1.32 x 1.49 | designer to confirm (LookDev candidate; wired by item 190) |
| `path_flower` | 25454256 | Orange Flower | tenchynox | Model (10 parts) | Creator Store, free | 2.71 x 1.40 x 2.70 | designer to confirm (LookDev candidate; wired by item 190) |
| `path_stone` | 1769612183 | small stone | MandarinBoy | Part (1 part) | Creator Store, free | 1.86 x 1.86 x 1.86 | designer to confirm (LookDev candidate; wired by item 190) |
| `bank_taro` | 8466298000 | Taro | CreeperProGamer90 | Model (10 parts) | Creator Store, free | 6.94 x 11.55 x 5.46 (scaled to ~2.5-stud plant) | designer to confirm (LookDev candidate; wired by item 192) |
| `bank_reed` | 13261235137 | Cattail | ablimity | MeshPart | Creator Store, free | 2.33 x 5.47 x 2.47 | designer to confirm (LookDev candidate; wired by item 192) |
| `bank_fern` | 5661660655 | fern plant | 11FlanT | Model (4 parts) | Creator Store, free | 6.08 x 5.70 x 6.08 | designer to confirm (LookDev candidate; wired by item 192) |
| `bank_shrub` | 9953859659 | Shrub/Bush | Purified142 | MeshPart | Creator Store, free | 82.16 x 20.25 x 102.78 (scaled to ~2-stud accent) | designer to confirm (LookDev candidate; wired by item 192) |
| `water_lily` | 5044238410 | Lilypad | Exp_p | MeshPart | Creator Store, free | 3.32 x 0.08 x 3.29 | designer to confirm (LookDev candidate; wired by item 192) |
| `meadow_flower_a` | 7974911801 | Wildflower02 | Oneshot7577 | Model (1 MeshPart) | Creator Store, free | 3.47 x 2.59 x 2.90 | designer to confirm (LookDev candidate; wired by item 194) |
| `meadow_flower_b` | 13032768586 | WildFlower04 | realOmlet | Model (1 MeshPart) | Creator Store, free | 1.17 x 2.59 x 1.21 | designer to confirm (LookDev candidate; wired by item 194) |
| `meadow_daisy` | 70509679878841 | Daisy Flower | [HL] Creative Team | Model (1 MeshPart) | Creator Store, free | 0.32 x 1.04 x 0.36 | designer to confirm (LookDev candidate; wired by item 194) |
| `meadow_tall_grass` | 128368650541272 | TallGrass | Reneniza981 | Model (4 parts) | Creator Store, free | 1.41 x 4 x 1.41 (2 scripts stripped on bake) | designer to confirm (LookDev candidate; wired by item 194) |
| `meadow_wild_grass` | 8715139325 | Wild Grass | wooful67 | Model (16 MeshParts) | Creator Store, free | 13.17 x 1.01 x 2.63 | designer to confirm (LookDev candidate; wired by item 194) |

Licence not re-read here — Creator Store terms apply. The padi ID is wired into `src/` by item 191
(`sawah_r8` 3D padi, `src/shared/ModelMapSawahR8.luau`) and needs no `unused` marker. The fountain ID
is wired in item 188 (`plaza_r9`, `src/shared/ModelMapPlazaR9.luau`) and needs no `unused` marker.
The three rock IDs are wired in item 189 (`rocks_r9`, `src/shared/ModelMapRocksR9.luau`) and need no
`unused` marker. The five meadow IDs are wired in item 194 (`meadow_r10`,
`src/shared/ModelMapMeadowR10.luau`) and need no `unused` marker. All candidates stay OFF by default
until item 226. No ID invented; all from real Creator Store free-filter `search_asset` results, baked
scripts-stripped into `LookDevAssets` (evidence `docs/v2/evidence/h/2026-11-22-round11/CHECK_187.txt`,
`CHECK_188.txt`, `CHECK_189.txt` and `CHECK_193.txt`).

### Unused manifest IDs

## Marketplace model picks (sprint 4 rework, pending designer)

Picked from Creator Store (free) per `docs/v2/visual/refs/REFERENCES.md`. Inserted in Studio for inspection; sanitize (remove Scripts/LocalScripts/ModuleScripts, drop light cones, anchor, CanCollide off where needed) before staging. No ID invented.

| Slot | Asset ID | Name | Creator (as listed) | Source | Notes | Approved by |
|---|---|---|---|---|---|---|
| `lamps_r10_model` | 13869743481 | Realistic Streetlamp (pick 2) | Creator Store | Creator Store, free, inserted in Studio Edit 2026-11-23 | 9 descendants, MeshPart pole+bulb+glass+Beam+SpotLight; drop Beam/Glass/SpotLight attachments, replace with warm PointLight <=16 range night-only. Pick 1 (vintage mercury vapor, 132 descendants, heavier) inspected, not chosen. | designer to confirm |
| `signposts_r10_model` | 71310674426033 | Village signpost (pick 2, restyled) | Creator Store | Creator Store, free, baked via LookDevAssetLoader | Item 257: four baked blank signposts restyled with six green arrow plates, id/en text from Strings.luau. | numeric checks pass; observer look FAIL (plates clipped / primitive) |
| `bamboo_bridge_r10_model` | 8029943234 | Indonesia Concrete Bridge (pick 1) | Creator Store | Creator Store, free, baked via LookDevAssetLoader | Item 258: concrete deck slab with striped curb, yellow posts, black pipe rails; replaces the greybox default bridge. | numeric checks pass; observer look FAIL (rails not visible from hero angle) |
| `road_fence_r10_model` | 1158365955 | Chicao's Small Bamboo Fence (pick 2) | Creator Store | Creator Store, free, baked via LookDevAssetLoader | Item 262: tan Union panels + dark posts on road shoulders. Pick 1 `118708423521045` baked as an all-red `OOF!` placeholder, rejected. | numeric checks pass; observer look FAIL (<30% frame fill at road level) |
| `kampung_r10_model` | 18239791051 | Rumah Kampung Simple Indonesia (pick 1) | Creator Store | Creator Store, free, baked via LookDevAssetLoader | Item 261: replacement for blocked malicious pick 2 `128627541097148`. Raw bbox 94.39x18x33.03 cannot fit BODY_SIZE {16,9,12} within 20% by uniform scale. | BLOCKED — HOUSE_SCALE 0/12; needs designer asset/scale decision |

Convention: `unused` means the ID appears in this manifest for provenance but has no reference in
`src/` at the time of the check. These rows are not deletions; a later code use simply removes the
marker. All other manifest IDs are required by the coverage spec to resolve in `src/`.

| Asset ID | Why it is here | Status |
|---|---|---|
| 155440478 | legacy classic sunset skybox face, superseded by round-6 skies | unused |
| 156042292 | legacy classic sunset skybox face, superseded by round-6 skies | unused |
| 156042307 | legacy classic sunset skybox face, superseded by round-6 skies | unused |
| 156042328 | legacy classic sunset skybox face, superseded by round-6 skies | unused |
| 156042348 | legacy classic sunset skybox face, superseded by round-6 skies | unused |
| 156042384 | legacy classic sunset skybox face, superseded by round-6 skies | unused |
| 739614116 | Trunk mesh of the legacy pine tree; licence note only | unused |
| 739619496 | Leaves mesh of the legacy pine tree; licence note only | unused |
| 1840694476 | search-only music alternative, never wired | unused |
| 2312874610 | Leaves mesh of the legacy pine tree; licence note only | unused |
| 5392132809 | legacy pine tree model; default wall is the tropical forest (item 138) | unused |
| 9112841064 | search-only Pasar crowd ambience, never wired | unused |
| 10019841237 | rejected building (no clear ground-floor opening), never loaded | unused |
| 70770369223840 | Poly Pizza crate upload, no current map slot | unused |
| 80611793347029 | Poly Pizza sumur upload, superseded by the real CC BY sumur ID | unused |
| 83895031629944 | Poly Pizza kit wall upload, no current map slot | unused |
| 92903548535675 | Poly Pizza kit fence upload, no current map slot | unused |
| 95225115736749 | Poly Pizza kit hut upload, no current map slot | unused |
| 97786595529501 | Poly Pizza barrel upload, no current map slot | unused |
| 106680734829483 | icon pipeline upload probe, marked "not for use" at source | unused |
| 121540426548169 | Poly Pizza gerobak upload, superseded by the real CC BY gerobak ID | unused |
| 122341055760449 | search-only Gamelan Without Pulse, never wired | unused |
| 129607759321192 | Poly Pizza pasar stall upload, superseded by the lapak asset | unused |
| 133136389632701 | Poly Pizza karung upload, superseded by the real CC0 karung ID | unused |

## Own-work Blender models: pos ronda (generated by script, not uploaded)

Built from scratch by a Blender script in the repo: geometry, UVs and textures are generated, so
there is no third-party source or licence. `id` stays `0` until someone uploads it; never invent one.

```
slot,class,source,source_ref,licence,attribution,id,approved_by,status
model.kit.pos_ronda,model,own-blender,assets/pos_ronda/build_pos_ronda.py,own work,,0,,UNVERIFIED
```

`pos_ronda`: night-watch post, 1,532 tris in 11 meshes (one texture each), 29.9 x 15.7 x 19.6 studs.
Blank sign panel for a `Strings.jail_title` SurfaceGui. Details and renders in `assets/pos_ronda/README.md`.

## Blocked assets (never load, bake or insert)

Enforced by `src/shared/AssetBlocklist.luau` and `LookDevAssetLoader` (both paths refuse these IDs).

| ID | What | Found |
|---|---|---|
| 128627541097148 | "Rumah Warga Indonesia 2" (was kampung pick 2). A Script at `Bagian Utama.Part.Runner` clones a fake "Roblox Studio / Disconnected / Error 0x89AF2 / Optimize" dialog into every PlayerGui, blurs the screen and anchors the player. "Optimize" opens a fake panel asking the developer to paste a Command Bar snippet that enables HttpService and inserts the `Connector` of 78922956693900 into ServerScriptService. | 2026-11-23, sprint 4. Removed from the open Studio session (not saved); HttpService was still off and no `Connector` existed. |
| 78922956693900 | The backdoor payload that snippet fetches. Never fetch. | 2026-11-23 |
