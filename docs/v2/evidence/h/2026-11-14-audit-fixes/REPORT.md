# audit fixes — 2026-11-14

Source: `docs/improvements/SINTESIS.md`. Haiku lanes, reviewed and run by the main session. Suite: `All 581 tests passed`.
- BUG-008 hub signs: name painted on the board (SurfaceGui `SignFront`/`SignBack`), floating BillboardGui removed. 6/6 signs, 0 billboards; "WARUNG" readable on its board — SEEN-IN-STUDIO (`after-spawn-desktop.jpg`, desktop).
- Next-goal card after the tutorial (`src/shared/NextGoal.luau`, `Hud.luau`): "Next Goal / Own 6 / 12 plots to reach Juragan" — SEEN-IN-STUDIO (desktop).
- Seed bar shows only owned or selected seeds ("Rice x0", selected) — SEEN-IN-STUDIO (desktop).
- Cabai banner gold plus countdown (`CabaiEventEndsAt`): LUNE-ONLY, the event was not active during the run.
- Materials: a SmoothPlastic pass was tried and rejected by the designer (D11 refined to "cartoonish realism"). Textured materials are restored (foliage reads Grass 76 / Slate 8); only the deterministic colour jitter stays — SEEN-IN-STUDIO.
- Output: only the 3 known BUG-003 lines (excluded by D-G4).
Before: `before-spawn-desktop.jpg`. Not checked: phone size, the Pasar close up, the Indonesian locale.

## Round 2 — scale and phone (designer feedback, same day). Suite: `All 584 tests passed`.
- Hub headroom: every roof/awning/trim bottom >= GROUND_Y + 9.5 in all six hubs (spec in `greybox_spec`); signs moved onto the fascia; Pos Ronda watchtower moved off the hut roof. Warung reads in proportion to the player — SEEN-IN-STUDIO (`after-scale-warung-desktop.jpg`, desktop). Other five hubs: LUNE-ONLY (not photographed).
- Phone as the single control panel: Seeds and Board HUD buttons removed; Seed Shop and Leaderboard are phone apps; portrait device with bezel, clock, status glyphs, 3-column app grid, home bar — SEEN-IN-STUDIO (`after-phone-desktop.jpg`, desktop). An app-icon 0x0 collapse (aspect constraint on a 0-height frame) was found in Studio and fixed by the main session (`SizeConstraint = RelativeXX`).
Not checked: phone size (844x390; lane estimates a ~156x311 px device there), touch, opening Seed Shop/Leaderboard from the phone by tap, back/close buttons are 40x30 (< 44 px). App icons are letter placeholders until icon IDs exist (D-G1).

## Round 3 — phone size (iPhone 14 emulator, viewport 749x388). Suite: `All 584 tests passed`.
- Before (`before-phone-iphone14.jpg`): portrait device clamped to 150x300, icons 20 px, grid cut off, HUD goal card undimmed, title wrapped, back/close 40x30, seed bar over the thumbstick.
- After (`after-phone-iphone14.jpg`): short landscape screens get a landscape device 698x349, 4-column grid, icons 60x60, back/close 44x44, title one line — SEEN-IN-STUDIO. Scrim now covers the top-bar strip (`IgnoreGuiInset = true`, main session fix). The phone button visible in that frame is an artefact of opening the phone by script; the real handler hides it (`Phone.luau` toggle).
- Seed shop at phone size scrolls and fits (`after-shop-iphone14.jpg`); seed bar centred, clear of the thumbstick — SEEN-IN-STUDIO.
Not checked: real touch taps (Seed Shop / Leaderboard tiles, home bar), the pages inside apps at phone size, a real device.
