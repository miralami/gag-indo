# Art candidates — designer yes/no gallery

Round 2, branch `track/c-world-look`. **Every row is a CANDIDATE awaiting a designer yes. None is
approved, none is shipped on by default.** LookDev is a Studio-only, off-by-default opt-in:
`require(game.ReplicatedStorage.Shared.LookDev):enable("<toggle>")` shows a candidate,
`:disable()` restores the shipping look. A published server can never enable it.

The designer's yes/no belongs in the last column. A blank cell means *not yet decided*; it is never
filled by an agent. Asset IDs come from real Open Cloud operations and are recorded in
`docs/v2/visual/art/ASSET_MANIFEST.md` — none are invented.

## Candidate groups

| Candidate | What it is | Toggle | Render / screenshot | Cost (instances / fps) | Designer yes/no |
|---|---|---|---|---|---|
| `plaza_lighting` | Alternative Pasar material + lighting grade (round 1) | `LookDev:enable("plaza_lighting")` | `docs/v2/evidence/h/2026-11-19-lookdev-candidates/` | ~9 material swaps, 0 new instances, no measurable fps cost | |
| `police_walkin` | Police NPC walk-in timed to the raid cutscene (round 1) | `LookDev:enable("police_walkin")` | `docs/v2/evidence/h/2026-11-19-lookdev-candidates/` | reuses 1 existing NPC, 0 new instances, no measurable fps cost | |
| `icons` | 27 agent-made painted icons for every IconMap slot (round 2 item 4) | `LookDev:enable("icons")` | `docs/v2/visual/art/icons/render/contact_sheet.png` | 0 new instances; swaps `ImageLabel.Image` on existing icon slots only, no measurable fps cost | |

## `icons` — per-asset renders and IDs

All 27 PNGs are 256x256 transparent, deterministic output of
`docs/v2/visual/art/icons/src/generate_icons.py`. Every ID below was returned by
`POST /assets/v1/assets` and confirmed `Approved` in the completed operation. The contact sheet is
the single render to review first; individual PNGs are listed for a closer look. The generator
script's validity check passed (all files 256x256 RGBA with non-empty alpha). This session had no
image-input support, so no agent visually graded the icons — the render is provided for the
designer's yes/no, not claimed as agent-verified.

| Slot | Render | Asset ID | Designer yes/no |
|---|---|---|---|
| `crop_padi` | `render/crop_padi.png` | 114251482326552 | |
| `crop_singkong` | `render/crop_singkong.png` | 125071570354841 | |
| `crop_jagung` | `render/crop_jagung.png` | 77336087458478 | |
| `crop_bawang` | `render/crop_bawang.png` | 104903641478136 | |
| `crop_cabai` | `render/crop_cabai.png` | 84310027204694 | |
| `crop_tembakau` | `render/crop_tembakau.png` | 80640549300472 | |
| `crop_kopi` | `render/crop_kopi.png` | 87432090737677 | |
| `crop_tebu` | `render/crop_tebu.png` | 126828358791382 | |
| `crop_kakao` | `render/crop_kakao.png` | 105395581171156 | |
| `crop_cengkeh` | `render/crop_cengkeh.png` | 101021953955568 | |
| `crop_durian` | `render/crop_durian.png` | 94589075400460 | |
| `crop_sawit` | `render/crop_sawit.png` | 127561041299274 | |
| `tier_biasa` | `render/tier_biasa.png` | 89039660400929 | |
| `tier_bagus` | `render/tier_bagus.png` | 81110221353868 | |
| `tier_super` | `render/tier_super.png` | 111608597881986 | |
| `tier_langka` | `render/tier_langka.png` | 121577229795943 | |
| `tier_sultan` | `render/tier_sultan.png` | 124401414397944 | |
| `currency_rupiah` | `render/currency_rupiah.png` | 76189327817658 | |
| `cash` | `render/cash.png` | 84649047415515 | |
| `phone` | `render/phone.png` | 135874869613602 | |
| `garden` | `render/garden.png` | 124397872915480 | |
| `debt` | `render/debt.png` | 83485200694555 | |
| `quest` | `render/quest.png` | 86819230917965 | |
| `cheat` | `render/cheat.png` | 135587262954164 | |
| `hat` | `render/hat.png` | 109619793807014 | |
| `shop` | `render/shop.png` | 133120999661934 | |
| `trophy` | `render/trophy.png` | 130034112081024 | |

`render/*` above is relative to `docs/v2/visual/art/icons/`. The `_upload_probe.png` disc
(`106680734829483`) is a pipeline probe recorded in the manifest, not a candidate for review.

## Wiring / proof

- `src/shared/IconMap.luau` keeps every entry `id = 0` (letter fallback is the default). Uploaded
  IDs live in `IconMap.candidateIds` and are applied only by
  `src/client/UI/LookDevIcons.luau` while the `icons` candidate is enabled; `disable()` restores
  id 0. The LookDev gate and applier are spec-locked in `tests/specs/lookdev_candidates_spec.luau`
  and `tests/specs/iconmap_spec.luau`.
- Enable/disable round-trip and Studio-only refusal are proven by specs; an in-Studio visual check
  of the enabled icons is part of the round-2 Studio sweep (item 27) and will be recorded there.
