# Round 2 — agent-made icon candidates, upload + LookDev wiring (2026-11-19)

WORK_QUEUE round 2 item 4. Status `SEEN-IN-STUDIO` for the upload result and the LookDev
enable/disable round-trip (this file + `results.json` + the manifest/spec files). The icons are
**CANDIDATES awaiting designer yes/no — none approved, none shipped on by default.**

## Generation

`docs/v2/visual/art/icons/src/generate_icons.py` (deterministic Pillow, no randomness) produced
27 transparent 256x256 RGBA PNGs in `docs/v2/visual/art/icons/render/`, one per `IconMap.luau`
slot: 12 crops, 5 tiers, 2 currency (`currency_rupiah`, `cash`), 8 phone apps (`phone`, `garden`,
`debt`, `quest`, `cheat`, `hat`, `shop`, `trophy`). Style follows `art/ICONS.md`: three-quarter
read, warm top-left highlight, bold `tinta` contour, no letters inside the icons. A labelled
`contact_sheet.png` was also generated (labels below thumbnails only). The generator's validity
assertion passed: all 27 files are 256x256 RGBA with a non-empty alpha channel. This session has
no image-input support, so no agent visually graded the art — the render is provided for the
designer's yes/no, not claimed as agent-verified.

## Upload (real IDs, none invented)

Creator `172146044` (User), universe `10776530981` — probed via `execute_luau` and
`GET /cloud/v2/universes/10776530981` (200 OK with `asset:read`/`asset:write` scopes granted).
Each `POST /assets/v1/assets` (`assetType=Image`, multipart `fileContent`) returned an operation;
`GET /assets/v1/operations/{id}` returned `done=true`, a concrete `assetId` and
`moderationState=Approved` for all 27. Every ID is recorded immediately in
`docs/v2/visual/art/ASSET_MANIFEST.md` under "Uploaded 2026-11-19 (round 2 item 4)". One extra
plain-disc `_upload_probe` asset (`106680734829483`) established the pipeline; it is recorded as
a probe, not a review candidate.

Auth note: `open_cloud_invoke` uses Studio's MCP token (Assistant Settings → MCP Permissions), not
the `ROBLOX_API_KEY` env var. No API key was printed, logged or committed — this satisfies the
repo's key-safety rule more strictly than a manual header would.

## LookDev wiring (live Studio readback)

- `src/shared/IconMap.luau`: entry `id` stays 0 (letter/palette fallback is the default). Uploaded
  IDs live in `IconMap.candidateIds`; `IconMap.applyCandidates(visuals, on)` swaps `Visuals.icons`
  IDs on and restores 0 off. Guard helper `IconMap.usingCandidates()`.
- `src/shared/LookDev.luau`: third candidate `icons` added to `IDS`/`candidates`/`plan` with pure
  data only (an `idsSource` pointer, no numeric literals) so the spec's ID guard still holds.
- `src/client/UI/LookDevIcons.luau`: registers an applier that calls `IconMap.applyCandidates` on
  enable and off on disable. `src/client/Main.client.luau` requires it behind `pcall` at boot.

Rojo `localhost:34872` served the updated modules (Studio readback of `LookDev.IDS` already had
`icons`; the synced Main LocalScript tail contains `pcall(require, script.Parent.UI.LookDevIcons)`
and the adapter's source contains `LookDev.register`). Live command-bar check in the Edit VM:

| read | before enable | after `LookDev:enable("icons")` | after `LookDev:disable()` |
|---|---|---|---|
| `Visuals.icons.crop_padi.id` | 0 | 114251482326552 | 0 |
| `Visuals.icons.tier_sultan.id` | 0 | 124401414397944 | 0 |
| `Visuals.icons.phone.id` | 0 | 135874869613602 | 0 |
| `LookDev.hasApplier("icons")` | true | true | true |
| `LookDev.current()` | nil | `icons` | nil |

`enable`/`disable` returned `true`. The candidate is off by default and only enableable in Studio
(the `LookDev.canEnable` gate). Note: the `execute_luau` "Client" context is a separate VM from
LocalScripts, so boot-time applier registration cannot be observed there; the command-bar (Edit
VM) round-trip above plus the spec are the proof of the applier wiring.

## Validation

- New specs: `lookdev_candidates_spec.luau` (3 candidates, new adapter in the no-ID scan, icons
  plan + applier assertions, Main bootstrap) and `iconmap_spec.luau` (27 candidate IDs, on/off
  round-trip restoring letters). `lune run tests/run.luau`: **All 1933 tests passed** (up from
  1929 — 4 new tests); `selene src`: 0 errors / 0 warnings / 0 parse errors.
- `docs/v2/visual/CANDIDATES.md` created with one group row per candidate and a per-icon render /
  ID / blank yes-no table. `docs/testing/BUGS.md` unaffected (no defect found).
- Place not saved, not published; no `JuraganDesa.rbxl` write.
