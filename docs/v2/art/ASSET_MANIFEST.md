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
