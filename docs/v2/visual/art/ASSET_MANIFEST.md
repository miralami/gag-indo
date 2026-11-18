# Asset manifest

Master Plan §5: every asset has a row, no row means no merge. IDs here were returned by the Studio
MCP `search_asset` (Creator Store, free filter) and each was loaded in a Play Solo session
(`Sound.IsLoaded` true, `TimeLength` read) on 2026-11-14. None were invented.

| Slot | Asset ID | Name | Creator (as listed) | Length | Source | Licence note | Approved by |
|---|---|---|---|---|---|---|---|
| `music_desa` | 83077123902599 | Gamelan Resonance Field | DistrokidOfficial | 152.2 s | Creator Store, free | Creator Store audio for use in Roblox experiences; terms are Roblox's, not re-read here | designer to confirm |
| `music_pasar` | 135973738646382 | Golden Gamelan | DistrokidOfficial | 178.8 s | Creator Store, free | same | designer to confirm |
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
