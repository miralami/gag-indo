# Asset manifest

Master Plan §5: every asset has a row, no row means no merge. IDs here were returned by the Studio
MCP `search_asset` (Creator Store, free filter) and each was loaded in a Play Solo session
(`Sound.IsLoaded` true, `TimeLength` read) on 2026-11-14. None were invented.

| Slot | Asset ID | Name | Creator (as listed) | Length | Source | Licence note | Approved by |
|---|---|---|---|---|---|---|---|
| `music_desa` | 83077123902599 | Gamelan Resonance Field | DistrokidOfficial | 152.2 s | Creator Store, free | Creator Store audio for use in Roblox experiences; terms are Roblox's, not re-read here | designer to confirm |
| `music_pasar` | 135973738646382 | Golden Gamelan | DistrokidOfficial | 178.8 s | Creator Store, free | same | designer to confirm |
| `ambience_cerah` | 9112748018 | Birds And Cicadas 2 (SFX) | ProSoundEffects ("Courtesy of Pro Sound Effects") | 46.3 s | Creator Store, free | same | designer to confirm |

## Candidates found, not yet wired

| Use | Asset ID | Name | Loaded in Studio |
|---|---|---|---|
| Night ambience (rooster, crickets, distant dog) | 9112826489 | Malaysian Forest 2 (SFX), 36 s | search only |
| Pasar crowd ambience | 9112841064 | Outdoor Walla 2 (SFX), 71.5 s | yes (71.5 s) |
| Music alternative | 1840694476 | The Spirit Of Gamelan (e), APMOfficial | yes (120.3 s) |
| Music, no pulse | 122341055760449 | Gamelan Without Pulse | search only |

## Open points

- Rain, storm and fog ambience, UI clicks and stings are still `0` (silent by design until sourced).
- Licence terms of Creator Store audio were not read in full; confirm on the Creator Store terms
  before launch (Master Plan §6 phase 4).
- Third-party Creator Store audio can be removed or moderated later; re-check the IDs load before each release.
