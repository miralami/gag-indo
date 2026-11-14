# HUD and label pass, 2026-11-14

Shots by the designer from Studio Play, desktop-size "Current device" viewport (not a phone emulation).

- `hud-before-designer.webp`: cash hidden under the Roblox menu icons, empty dark boxes, dim hotbar.
- `hud-after-designer.webp`: after the HUD pass. Cash `RP 90,278` readable below the top bar, no empty dark boxes, Board and hotbar readable. World labels were still oversized and one was clipped by a roof beam in this shot.

| Item | Status |
|---|---|
| BUG-009 HUD legibility | SEEN-IN-STUDIO (`hud-after-designer.webp`) |
| BUG-010 duplicate NPC billboards | SEEN-IN-STUDIO structure (2 billboards per NPC, measured); not visible as a separate shot |
| BUG-008 world labels | LUNE-ONLY: fixed text size 22 px and signs raised to 7 studs after this shot; no shot of the result yet |

Not checked: phone-size emulation, real device, the `Board` button's own look, the Pasar and plot labels after the final change.
