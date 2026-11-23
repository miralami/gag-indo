# Sprint 4: main-session notes (2026-11-23)

Sprint 4 did not reach S4-STOP. There is no review pack and no verdict sheet.

## Status per item

| Item | State |
|---|---|
| 264 capture from the review camera | Done (`CHECK_264.txt`, `CAPTURE_POSE` PASS) |
| 255 hero cameras and grass clearing | BLOCKED: 28 `hero_*` cameras exist, `SUBJECT_COVERAGE` 15/28, `HERO_CLEAR` 10/28 |
| 256 lamps from a model | BLOCKED: model wired, visual fail (see below) |
| 257-263 | Code written but uncommitted in the worker checkout, not seen in Studio; `kampung_r10_spec` fails because the WIP wires the blocked asset |
| S4-STOP | Not reached |

## Why it stopped: malicious store model

Kampung pick 2 `128627541097148` hid a Script that, about 7 seconds into Play, puts a fake
"Roblox Studio / Disconnected / Error 0x89AF2 / Optimize" dialog over the game, blurs the screen and
anchors the player. "Optimize" opens a fake panel that asks the developer to paste a Command Bar
snippet. The snippet enables HttpService and inserts the `Connector` of asset `78922956693900` into
ServerScriptService, which is a backdoor. The worker had inserted the raw store models into Workspace as
previews, so the script ran on Play. The worker then took the dialog for a real Studio error and asked
the designer to click Optimize.

Done in the open Studio session (not saved):
- Removed the model from Workspace and `LookDevAssets`, and removed the blur.
- Deleted the other raw `Pick*` previews; baked copies remain.
- Stripped 3 leftover ModuleScripts from `LookDevAssets/118708423521045`.

Checked afterwards: HttpService was still off, no `Connector` existed anywhere, and no suspicious
script was found in the other services.

Fixed in the repo:
- `AssetBlocklist.luau`.
- `LookDevAssetLoader` now refuses blocked IDs and strips every script on both paths.
- Added `asset_blocklist_spec`.
- Added the AGENTS.md rule "Store models are untrusted code".
- Pick 2 is marked malicious in REFERENCES and `ASSET_MANIFEST`.

## Blunt read of the shots that exist

- **Lamps, day and night (`S4_256_lamps_*_r2`): no.** The lamp is a needle-thin pole in the middle of
  a dirt road, unreadable at this distance. At night it gives an orange glow on the road but no lamp
  shape. Tall grass covers the right edge of the frame.
- **Meadow (`S4_257_meadow`): no.** There is no subject, just a crossroads. Tall grass at mid-frame
  blocks the plots, and black specks line the horizon.
- **Every shot:** the HUD is visible although the rule says HUD hidden. The horizon still has the
  round green "melon" domes and a row of dark specks. These are the same problems the designer
  rejected in sprint 3.
