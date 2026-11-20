# R6 NPC costume templates — asset generation (item 48, Route B)

Ten 585×559 classic-clothing PNGs for five villager roles: one `shirt_<role>.png`
and one `pants_<role>.png` each. Flat colours, deterministic simple patterns, full
canvas covered (no default white). These are source PNGs for **Image** uploads;
`Shirt.ShirtTemplate` / `Pants.PantsTemplate` accept Image IDs directly, not Decal
or clothing IDs. No visual verdict is claimed — the designer owns the yes/no.

## Role → outfit palette

| Role | Shirt | Shirt cue | Pants | Pants cue |
| --- | --- | --- | --- | --- |
| `polisi` | `#6B4A2F` brown | darker `#4E3522` placket on Front | `#4A3524` brown | plain |
| `pak_rt` | `#E8D8B0` batik cream | `#3A2A1A` dots/diamonds on Front + Back | `#3A2A1A` dark brown | plain |
| `petani` | `#9AAF9A` pale blue-grey | `#B4C4B4` horizontal fade bands | `#8A7A55` khaki | `#5F5338` cuff band at leg bottom |
| `pedagang` | `#3E7C74` muted teal kaos | `#C9B79A` apron rectangle on Front only | `#3A4A55` dark slate | plain |
| `petani_wanita` | `#D98A9A` soft pink kebaya | `#F2BFC9` vertical light stripes | `#6A4A5A` muted plum | plain |

## Generate (no key, no network)

```
python docs/v2/visual/art/models_r6/npcs/src/generate_templates.py
```

Writes `templates/*.png` and `download_manifest.json` (relative file paths, `code`,
`role`, `kind`, `size`). Needs Pillow. The script asserts every file is 585×559.

## Upload (main session only)

```
python docs/v2/visual/art/models_r6/npcs/src/upload.py
```

Reads `ROBLOX_API_KEY` from the environment (never printed or committed), posts
each manifest file as `assetType: "Image"` to `POST https://apis.roblox.com/assets/v1/assets`,
polls the operation, and writes `upload_manifest.json` with real IDs from COMPLETED
operations only. Creator: `172146044`. No ID is invented here.
