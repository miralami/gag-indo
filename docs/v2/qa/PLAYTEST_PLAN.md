# Juragan Desa v2 — Studio Playtest Plan

For an executor (human or AI) with Roblox Studio access. Plan only; nothing here has been run.
Unit tests (`lune run tests/run`, 481 passing) already cover logic against fakes. This plan covers what they cannot: real engine, UI, remotes, DataStore, multi-client.

## 0. Rules for the executor
- Record every result as PASS / FAIL / BLOCKED in `docs/testing/runs/<date>_playtest.md`. For each FAIL: step ID, expected, actual, Output-window error text, screenshot.
- Do not edit source. Report only.
- Studio Output window open the whole time. Any red error or `warn` not listed as expected is a finding, even if the step passes.
- Mobile checks: Studio Device Emulator (phone portrait, e.g. 375x812) plus Touch input.

## 1. Setup
1. `rojo serve`, connect the Rojo plugin in Studio, open `JuraganDesa.rbxl`. Confirm the sync is clean (no missing-module errors on start).
2. Use a Studio place with API Services enabled (DataStore, MessagingService).
3. Add the test account's UserId to `src/server/Live/Admins.luau` if not already in the allowlist. In Studio, admin is granted automatically (`IsStudio`).
4. Test modes: Play Solo (S1), Local Server with 2 players (S2), Play Solo with Device Emulator (S3).
5. Fresh save: use a new test UserId or wipe the profile so the FTUE runs.

## 2. Smoke (S0) — blocking
| ID | Step | Expected |
|---|---|---|
| S0.1 | Press Play | No red errors; server prints boot of all services in `Main.server.luau` |
| S0.2 | Wait 10s | HUD shows cash, rank, season; sky visible; no nil-index warnings |
| S0.3 | Open Output filter "Warn" | Only expected warnings (note each) |

If S0 fails, stop and report.

## 3. Scenarios

### A. FTUE (fresh save, phone emulation)
- A1 Guided first harvest prompts appear in order and can be completed with touch only.
- A2 Reach first harvest within ~3 minutes with no prior knowledge. Note any dead end or unclear text.
- A3 Minigames (Mencangkul, Babat): playable by touch; cannot be skipped to instant completion.
- A4 Text is readable and nothing is cut off at 375x812 and 360x640.

### B. Core farm loop (v1 parity)
- B1 Select seed, plant on a tile; the tile shows the crop stage.
- B2 Wait for growth; the stage changes bibit → tumbuh → siap; harvest it; cash/sack update.
- B3 Rarity: harvest 20+ crops; confirm a mix of biasa/bagus/super and at least one tinted reveal toast.
- B4 Plant one palawija, one kebun (regrows after harvest), one perkebunan; the seed bar scrolls and the shop lists all 12.
- B5 Family completion triggers the Almanak toast with its cosmetic reward.
- B6 Season risks: force the season/weather via the admin panel; check banjir (rain), hama (pancaroba), drought outcomes.

### C. Economy
- C1 Sell on Pasar: price falls as a large stack is sold; the phone board shows it; it recovers over time.
- C2 Sell on Pasar Gelap: payout and risk differ from Pasar; hot-produce refusal on Pasar works.
- C3 Shop: restock countdown visible; the same shelves after rejoining (no refresh exploit); rank/stock/cash refusals show a message.
- C4 Tools: buying changes grow time or sack size.
- C5 Gudang: refuses oplosan produce, returns it unchanged; preserves quality; capacity limit enforced.
- C6 Buruh: hire; harvests into the gudang; wage paid per item; stops when full, out of cash, or the shift ends; only one shift at a time.

### D. Pinjol, quests, progression
- D1 Borrow: the admin fee is deducted immediately; the debt ceiling is 3x principal; repay works; overdue triggers DebtCollector.
- D2 Daily quest and task claims pay once only; a second claim is refused.
- D3 Login streak: change the system date or use the admin tool; the streak increments and resets as designed.
- D4 Badges award once; rank-up unlocks the expected tiles/items.

### E. Law and raids
- E1 Cheat apply, bribe, and evidence record/offer/report flows work.
- E2 A raid starts: the overlay, the banner and the skip button all work. Choices (Raid_Choose) resolve to the right outcome.
- E3 Jail state locks the correct actions and releases on time.
- E4 Raid with a second client observing: only the intended player is affected.

### F. Persistence
- F1 Stop and rejoin: cash, rank, tiles, planted crops, sack, gudang, debt, quest state, streak, Almanak survive.
- F2 Load a legacy v1/v2 save, if one is available, and confirm migration with no loss.
- F3 Leave mid-minigame and mid-growth; rejoin sanity.
- F4 Studio "Stop" during a save: no error spam, no data rollback.

### G. Multiplayer (Local Server, 2 clients)
- G1 Season/event change from admin on client 1 shows on client 2's HUD.
- G2 Market pressure is shared; selling on client 1 moves the price seen on client 2.
- G3 Neighbor watering (`Water_Neighbor`) works and cannot target an invalid or absent player.
- G4 Leaderboard (richest / sultan harvests / most raided) renders on both; the tabs switch; empty state is graceful.
- G5 Chat tags show correctly.

### H. Admin and LiveConfig
- H1 Press F2 as admin: the panel opens. A non-admin account (or admin removed from the allowlist) gets no panel and the server ignores `Admin_Command`.
- H2 Change the season, force the cabai event on/off; the attributes and HUD follow.
- H3 Temporarily malformed LiveConfig (wrong field types): one warning, defaults kept, server keeps running.

### I. Monetization (test mode only)
- I1 Prompt each pass/product in Studio; cancel flow leaves state unchanged.
- I2 Simulated purchase grants the item once; replaying the receipt does not double-grant (`Receipts`).
- I3 Cosmetic buy/equip works and persists.
- Real product IDs are still placeholders; mark BLOCKED where they gate this.

### J. Security spot checks (client-side exploit simulation)
Using the command bar or a local script as a client, fire each remote in `Remotes.luau` with bad input:
- J1 Wrong types, nil, NaN, huge/negative numbers, strings with weird characters, unknown crop keys.
- J2 Burst of 50+ calls in 1s (rate limiter should throttle; the server must not lag).
- J3 Call a remote out of order (Farm_Complete without Minigame_Start, Raid_Choose with no raid, Debt_Borrow over the limit, Worker_Hire while one is active).
- J4 Expected: server rejects every one, with no cash/items gained and no server errors.

### K. Performance and stability
- K1 Phone emulation FPS stays steady during the busiest view (farm with all tiles planted + phone open).
- K2 Run 15 minutes; Studio memory (Stats panel) does not climb steadily; no duplicated UI after respawn or rejoin.
- K3 Reset the character several times: HUD and handlers are not duplicated, with no leaked connection warnings.
- K4 Sound: every registered sound plays at a sane volume; no overlaps or stuck loops.

### L. Visual / presentation (from a user screenshot, desktop, fresh Studio session)
Observed: world is still greybox (outlined, untextured blocks); HUD and Village Guide banner have a dark rectangle offset behind them; Board button has a dark backing strip; the hotbar's dark backing is wider than its slots; overlapping billboard labels ("PASAR" over "PAK RT", with a ghost duplicate); labels mix Indonesian ("Pos Polisi", "Lahan Kosong") with English UI ("Smoothholder", "Bring your harvest to the Market"); cash shows RP 999,985 (test grant?).
- L1 Compare the HUD, Village Guide, Board and hotbar against `docs/v2/visual/mockups/index.html`. Screenshot each at desktop, tablet and phone sizes; note the dark backing offset.
- L2 Check whether the stray dark rectangles are a missing/misanchored background frame or a UI stroke/shadow bug (inspect the instances in the Explorer during play; report names and sizes).
- L3 Walk the village: list every billboard label that overlaps another or shows a duplicate ghost. Record the camera positions.
- L4 Language: switch language if the picker exists. Confirm every visible string follows the chosen language, with no ID/EN mix (building names, tile labels, quest text, toasts).
- L5 Cash 999,985 is from the owner's deliberate cash cheat (confirmed working), not a bug. Still confirm a fresh-profile start of 50 (`Game.startCash`), and that the cheat is only reachable by admins.
- L6 Greybox vs art pass: list which map parts still lack final art or textures (the `VillageWorld` tag fallback), so that known gaps are not logged as new bugs.

## 4. Known static findings to confirm in play
- Leaderboard tab click calls `LeaderboardUI.render` (typed late-bound): confirm the tabs switch (G4).
- FarmService reads `PlantedAt`/`GrowSeconds` attributes without a nil guard: look for errors on tiles in odd states (B2, F3).
- Analytics passes optional numbers: watch Output for errors around events (all scenarios).

## 5. Exit criteria
- All S0 pass; no FAIL in A–F; no J3/J4 failure; G/H pass; I and K may carry documented BLOCKED items.
- Deliverable: the run report, a prioritized bug list (blocker / major / minor), and a list of anything BLOCKED with the reason.
