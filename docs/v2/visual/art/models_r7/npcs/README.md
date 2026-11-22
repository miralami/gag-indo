# R7 NPC costumes — source templates (WORK_QUEUE item 56)

Four new 585×559 classic-clothing PNGs plus a 2×2 contact sheet. Pure code,
deterministic, no upload, no Studio, **no visual grade**: the assets await
designer review. Main session uploads the PNGs as Images and patches the real
IDs into `src/shared/ModelMapNpcsR7.luau`.

## Files

| PNG | Role / slot | Motif and colours |
| --- | --- | --- |
| `templates/shirt_pak_rt.png` | Pak RT shirt | Parang: 45° diagonal S-curved bands filling torso **and both sleeves**. Sogan brown `#5C3A1E`, cream `#E8D9B5`, indigo `#2B3A55`. |
| `templates/shirt_polisi.png` | Polisi shirt | Brown `#6B4A2B`, seams `#4E3520`; two chest pockets with flaps, shoulder epaulettes, name tag on right chest, badge on left chest. |
| `templates/pants_polisi.png` | Polisi pants | Same brown `#6B4A2B`, black `#151515` belt with gold buckle. |
| `templates/shirt_petani.png` | Petani shirt | Green `#5C7A4E` with cream `#E8D9B5` bands and a V collar. Plain utility shirt, no batik claim. |
| `COSTUMES_SHEET.png` | 2×2 contact sheet | Labelled: Pak RT batik, Polisi shirt, Polisi pants, Petani shirt. |

The batik is drawn as local transparent layers clipped to each UV panel, so it
covers the torso and sleeves without bleeding into neighbouring faces. Dots on a
plain field are not used.

## Generate

```
python docs/v2/visual/art/models_r7/npcs/src/generate_templates.py
```

Needs Pillow. The script asserts every template is exactly 585×559 and writes
`COSTUMES_SHEET.png`. Deterministic: rerunning reproduces the same bytes.

## Uploaded costume IDs (2026-11-20)

The four new R7 PNGs were uploaded as Images via Open Cloud; every ID below came
from a completed operation and is recorded in `upload_manifest.json` and
`ASSET_MANIFEST.md`. These replace the R6 placeholders in
`ModelMapNpcsR7.costumeUploads` / `COSTUMES`:

| Field | R6 ID replaced | R7 Image ID |
| --- | --- | --- |
| `pak_rt.shirt` | `117485364703264` | `92996938301042` |
| `polisi.shirt` | `113212316103784` | `133590758790821` |
| `polisi.pants` | `98102154190902` | `98235919851901` |
| `petani.shirt` | `112086829394587` | `81581201405716` |

The remaining six fields (`petani.pants`, `pak_rt.pants`, `pedagang.*`,
`petani_wanita.*`) keep their R6 IDs unchanged. No ID is invented here.

## Handoff — completed 2026-11-20

Uploaded the four PNGs, recorded the returned IDs in `ASSET_MANIFEST.md`, wired
them into `ModelMapNpcsR7.COSTUMES`, registered `npcs_r7` in `Shared.LookDev`, and
ran the real Studio HATS check (`CHECK_56.txt`: PASS 4 4). The designer reviewed
the actual PNGs and the contact sheet: batik motif, police uniform and the
name-tag/badge sides all PASS. No place was saved or published.
