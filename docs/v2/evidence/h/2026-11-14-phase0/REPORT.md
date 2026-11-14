# h — phase0 — 2026-11-14

Build: 125e480 + two fixes now committed as 71df11b (src/server/Analytics/Analytics.luau, tests/specs/analytics_spec.luau)  Place: JuraganDesa.rbxl (not saved)  Devices: iPhone 14 + Desktop
- Bridge smoke check + enable: SEEN-IN-STUDIO (`Harness is off. Enable it from a Studio admin first.` → `Harness on.`, admin 172146044 isAdmin true)
- Plant tile 1 padi: SEEN-IN-STUDIO (padi 5 → 4, tutorial plant → harvest)
- Ready: SEEN-IN-STUDIO (shifted, no state change)
- Harvest tile 1: SEEN-IN-STUDIO (sack 0 → 1, tutorial harvest → sell)
- Sell pasar: SEEN-IN-STUDIO (cash 50 → 68, sack 1 → 0, tutorial sell → buy)
- Buy padi x2: SEEN-IN-STUDIO (cash 68 → 48, padi 4 → 6, tutorial completed)
- Save, stop, play, enable, status: SEEN-IN-STUDIO (cash 48, padi 6, tilesOwned 6; real Studio DataStores, not a published place)
- Second session full loop: SEEN-IN-STUDIO (sell 48 → 75, buy 75 → 65, padi 6)
- BUG-001 Clouds under Terrain: SEEN-IN-STUDIO (Cover 0.55, none under Lighting, no warning)
- BUG-002 Greybox rebuild: SEEN-IN-STUDIO (river water voxels 2700 / 2700 / 2700 after build 1 and 2)
- BUG-003 rbxassetid://203785492: UNVERIFIED (still 3× per play start; not in DataModel, place bytes, scripts, the only installed plugin or any Studio `content` folder)
- BUG-005 Analytics transactionType: SEEN-IN-STUDIO (error gone, `LogEconomyEvent event fired.` twice)
- Death / reset: SEEN-IN-STUDIO (killed from the server, respawned in 5.5 s at the plot 68, 4.69, 0; cash 65, padi 6, tiles 6 unchanged; no minigame node visible)
- Login-reward recovery: SEEN-IN-STUDIO (`quest` login reward cash 65 → 165, then buy 165 → 155, padi 6 → 7)
- Output: 3× the BUG-003 asset line only; no Clouds warning, no Analytics error
- Not checked: minigame feel, frame rate, 10-player, published-place DataStore
Decisions needed: D-G3 (broke-player recovery), D-G1 (asset upload route), D-G2 (Studio sessions)
