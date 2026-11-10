# Manual Test Cases

The things a script cannot judge: does it *feel* right, does the UI show up, does the world look right.
Everything else lives in the automated suite (see [README.md](README.md)).

**How to use this file**

1. Copy [runs/TEMPLATE.md](runs/TEMPLATE.md) to `runs/<version>.md` (for example `runs/2026-11-10-3690fb9.md`).
2. Play the build in Studio and work through the cases below, top to bottom.
3. Mark each case **Pass / Fail / Blocked / Skip** in the run sheet, with a note for anything that is not Pass.
4. A version is **verified** when every **P0** case passes and every Fail has a written decision (fix now, or accepted).

**Priorities**

| Priority | Meaning | When to run |
|---|---|---|
| **P0** | Smoke. If this breaks, the game is unplayable or money/data is at risk. | Every version, before publishing |
| **P1** | Core feature. Breaks a main mechanic. | Every version that touches that area |
| **P2** | Polish, edge cases, visuals. | Before a public update |

**Conventions**

- **Setup A** = one Studio Play session, 1 player. **Setup B** = Test → Server with **2 clients** (two players).
- "Wait" times can be shortened in `src/shared/Config/*.luau` while testing. Put them back afterwards.
- Cash is shown as `Rp`. Starting state for a new profile: Rp 50, 5 Padi seeds, 6 tiles, rank Petani Gurem.
- To start from a clean profile, rejoin with a different test account, or clear the Studio data store (`PlayerData_v1_Studio`).
- Each case lists **Auto** when part of it is already checked by the automated suite. The manual case covers what the script cannot see.

---

## 1. Smoke and persistence

### SMK-01 · Game boots without errors · P0 · Setup A
**Steps**
1. Run `rojo serve`, connect the Rojo plugin, press **Play**.
2. Open the Output window.

**Expected**
- You spawn at your own plot.
- Output has **no red lines**. A yellow "Roblox API services unavailable" line is fine only if Studio API access is off on purpose.

### SMK-02 · New player starts with the right stuff · P0 · Setup A
**Preconditions** Fresh profile.
**Expected** HUD shows Rp 50. Seed list shows 5 Padi. Six tiles are usable, the rest are locked (grey). Rank badge says Petani Gurem.
**Auto** `config_spec` (start values), `economy_spec`.

### SMK-03 · Progress survives rejoin · P0 · Setup A
**Steps**
1. Plant a crop, buy a seed, then stop Play.
2. Press Play again.

**Expected** Cash, seeds, tiles, rank and the planted crop are all still there. The crop kept growing while you were away.
**Auto** `playerdata_spec` (old-save migration only; real saving needs Studio).

### SMK-04 · No two players share a plot · P1 · Setup B
**Expected** Each client spawns at a different plot. Neither can plant on the other's tiles.

---

## 2. Farming

### FARM-01 · Plant with the Mencangkul minigame · P0 · Setup A
**Steps**
1. Walk to a brown tile, press **E** (or tap).
2. Tap when the needle is in the green zone, three times.

**Expected**
- The bar opens and the needle moves.
- A "Kualitas" value between 0.8 and 1.3 appears. More green hits means a higher value.
- The crop appears on the tile and starts growing. One seed is gone from the seed list.

### FARM-02 · Auto skips the minigame · P1 · Setup A
**Steps** Tap **Auto** instead of playing the minigame.
**Expected** Quality is exactly **0.90**. The crop is planted.

### FARM-03 · Harvest with the Babat minigame · P0 · Setup A
**Preconditions** A fully grown crop.
**Steps** Walk to the tile, press **E**, hold and release in the sweet spot.
**Expected** The crop disappears, the sack count on the HUD goes up. Releasing too early or too late gives lower quality, not an error.

### FARM-04 · Cannot harvest early · P1 · Setup A
**Steps** Try to harvest a crop that is still growing.
**Expected** Nothing is harvested. The tile shows the remaining time.

### FARM-05 · Interaction needs distance · P1 · Setup A
**Steps** Stand far from a tile and try to use it.
**Expected** It does not open. Walking closer makes it work.

### FARM-06 · Buy seeds · P0 · Setup A
**Steps** Open **🌱 Bibit**, buy 2 Padi.
**Expected** Cash drops by 2 × Rp 10, the seed count goes up by 2. With too little cash you get a "not enough cash" toast and nothing changes.
**Auto** `economy_spec` (spend rules).

### FARM-07 · Crops are rank-locked · P1 · Setup A
**Steps** As Petani Gurem, try to buy Jagung or Cabai.
**Expected** Refused with a rank-locked toast naming the required rank.

### FARM-08 · Buy a new tile · P1 · Setup A
**Steps** Walk to the first grey tile and buy it.
**Expected** Price is on the tile (Rp 100 for the 7th tile) and the next one costs double. The tile becomes usable. Cash drops by the price.
**Auto** `config_spec` (tile price formula).

### FARM-09 · Tile cap · P2 · Setup A
**Expected** Without the Extra Plot pass the last buyable tile is the 12th. Tiles 13 to 16 are not for sale.

---

## 3. Market and economy

### MKT-01 · Sell at the Pasar · P0 · Setup A
**Preconditions** At least one clean harvested crop in the sack.
**Steps** Walk to the blue **PASAR** stall and sell.
**Expected** Cash goes up by about *base price × quality*. The sack is empty. A "sold" toast shows the amount.
**Auto** `economy_spec`.

### MKT-02 · Selling from too far away fails · P1 · Setup A
**Expected** "Too far" toast. Cash and sack unchanged.
**Auto** `economy_spec`.

### MKT-03 · Hot produce is refused at the Pasar · P0 · Setup A
**Preconditions** A harvest grown with Pupuk Oplosan, and also some clean produce.
**Steps** Sell at the Pasar.
**Expected** Only the clean produce is paid. The hot items **stay in the sack** and the sack count matches (no phantom clean items left behind).
**Auto** `economy_spec` (regression of the "Pasar sale leaving clean produce" bug).

### MKT-04 · Sell at the Tengkulak Gelap · P1 · Setup A
**Steps** Walk to the stall behind the Pasar and sell a mixed sack.
**Expected** Pays about 30% more than the Pasar, sells hot produce too, empties the whole sack, and Sus goes up by 20.
**Auto** `economy_spec` (price and handler), `sus_spec`.

### MKT-05 · Harga Cabai Meroket event · P1 · Setup A
**Preconditions** A sack with cabai. Wait for the event (first one about 4 minutes after server start, or shorten `cabaiEventFirstDelay`).
**Expected**
- A toast announces the event and a red chip appears under the stats card.
- Cabai sells for 3× while the chip shows. Other crops are unchanged.
- After the duration the chip disappears and cabai is back to normal.

### MKT-06 · Rank-up on income · P1 · Setup A
**Steps** Earn Rp 1,000 lifetime.
**Expected** "Rank up" toast, badge says Petani, Jagung and Cabai are now buyable.
**Auto** `rank_spec`.

### MKT-07 · Juragan rank · P2 · Setup A
**Steps** Reach Rp 10,000 lifetime and own 12 tiles.
**Expected** Rank Juragan, Durian unlocked, chat lines start with **[Juragan]**.

---

## 4. Cheats and Sus

### LAW-01 · Pupuk Oplosan · P0 · Setup A
**Steps** Phone → **Curang** → oplos a growing tile.
**Expected** Costs Rp 20. The crop ripens faster (about 40% less time left), glows green, tile label shows ⚠. Sus rises by 15 on the HUD 👀.

### LAW-02 · Sus colour and thresholds · P1 · Setup A
**Expected** The 👀 goes green → yellow → red as Sus rises. At 30+ Pak RT's speech bubbles gossip about you. At 60 a **Surat Panggilan** toast appears (once, not repeatedly).
**Auto** `sus_spec` (the letter fires once per crossing).

### LAW-03 · Sus decays over time · P1 · Setup A
**Expected** Sus drops by 1 about every 20 seconds while online, and the value is saved across a rejoin.

### LAW-04 · Cheat while broke · P2 · Setup A
**Steps** Try Pupuk Oplosan with less than Rp 20.
**Expected** Refused with a "not enough cash" toast. No Sus is added.

### LAW-05 · Curi Air · P1 · Setup B
**Steps** Player A steals water from neighbour B (Phone → Curang → 💧 Curi).
**Expected** A's growing tiles finish about 30 s sooner, B's take 30 s longer. A second steal from the same victim within 5 minutes is refused. A gets +10 Sus. B always gets a bukti token.

---

## 5. Pak RT and raids

### BRB-01 · Bribe Pak RT · P0 · Setup A
**Preconditions** Sus above 10 and at least Rp 100.
**Steps** Walk to Pak RT and pay uang rokok.
**Expected** Cash drops by Rp 100, Sus drops by 10. The price shown for the next bribe is Rp 150. A cooldown (3 minutes) blocks an immediate repeat.

### BRB-02 · Bribe price window · P1 · Setup A
**Expected** Price keeps rising ×1.5 per bribe inside 10 minutes and falls back to Rp 100 after the window passes.

### RAID-01 · Raid sequence · P0 · Setup A
**Preconditions** Push Sus to 100 (repeat cheats).
**Expected**
- Siren and the **BREAKING NEWS** banner, camera zoom on your face.
- Police NPCs walk to your plot. Hot crops are confiscated.
- You get two choices: **Bayar Denda** and **Kasih Amplop**, with a countdown.
- Afterwards Sus is 30 and you are safe from raids for 3 minutes.

### RAID-02 · Pay the fine · P0 · Setup A
**Expected** You lose 20% of your cash (minimum Rp 50, maximum Rp 5,000). Nama Baik drops by 10.

### RAID-03 · Amplop (bribe) · P1 · Setup A
**Expected** Costs 10% of cash. About 3 out of 4 tries the raid ends. On failure you see "Amplop kurang tebal, Pak!" and pay the fine ×1.5. (Repeat a few times to see both outcomes.)

### RAID-04 · Cannot pay → Pos Ronda · P1 · Setup A
**Preconditions** Almost no cash.
**Expected** All your cash goes, you are placed in the **Pos Ronda** with a 45 s countdown and an orange vest, and you can still chat. After the countdown you are released.

### RAID-05 · Choice timeout · P2 · Setup A
**Steps** Do not pick anything for 20 seconds.
**Expected** The fine is applied automatically.

### RAID-06 · Leaving mid-raid · P1 · Setup A
**Steps** Stop Play while the raid choice is open, then rejoin.
**Expected** The fine was applied. No free escape.

---

## 6. Lapor (needs two players)

### LAP-01 · Record evidence · P0 · Setup B
**Steps** A cheats within 40 studs of B.
**Expected** B sees "📱 Rekam bukti?". Tapping **Rekam** plays the camera animation and a bukti token with a countdown appears in B's phone.

### LAP-02 · Report at Pos Polisi · P0 · Setup B
**Steps** B walks to **POS POLISI** and taps **Lapor**.
**Expected** B receives cash (half the cheat's value, taken from A) and +2 Nama Baik. A gets +25 Sus. Total money in the server did not increase.

### LAP-03 · Token expires · P1 · Setup B
**Steps** Wait longer than 3 minutes before reporting.
**Expected** Token disappears, the report is refused.

### LAP-04 · Only the first reporter is paid · P1 · Setup B (+ third player if possible)
**Expected** A second report for the same cheat event gives no cash but still counts toward VIRAL.

### LAP-05 · VIRAL · P0 · Setup B
**Steps** Two different players report A within 5 minutes.
**Expected** A is raided immediately. The **amplop button is greyed out** ("Udah viral, Pak. Gak bisa."). Nama Baik drops by 20.

### LAP-06 · Report cooldown · P2 · Setup B
**Expected** A reporter cannot report again within 60 seconds.

---

## 7. Phone, items and cosmetics

### UI-01 · Phone tabs · P1 · Setup A
**Expected** 📱 HP opens with the **HP**, **Curang** and **Dekorasi** tabs. Items and bukti show on the HP tab. Nothing overflows the screen.

### UI-02 · Phone layout on small screens · P1 · Setup A
**Steps** In Studio, Test → Device Emulator, pick a small phone (about 5").
**Expected** HUD, minigame card, raid overlay and phone are fully visible and tappable. No text is cut off.

### UI-03 · Language · P2 · Setup A
**Expected** All visible text comes from the string table (ID and EN). No raw keys like `n_sold` appear on screen.

### ITM-01 · Amplop Premium · P1 · Setup A
**Preconditions** Item in inventory (grant it with a test purchase or edit data in Studio).
**Expected** Used from the phone: Sus −20. A second use within 10 minutes is refused. It cannot be used during a raid.

### ITM-02 · Jaminan Kilat · P1 · Setup A
**Expected** Only usable while in the Pos Ronda. It ends the timer but the fine is still paid.

### COS-01 · Buy and wear a cosmetic · P1 · Setup A
**Steps** Phone → Dekorasi → buy Caping (Rp 250).
**Expected** Cash drops, the hat appears on your character, and it is still there after respawn and after rejoin.

### NBR-01 · Water a neighbour · P2 · Setup B
**Steps** Phone → Curang → 🚿 Siram on an adjacent plot.
**Expected** +1 Nama Baik, capped at 10 per day.

---

## 8. Monetization (only with real IDs in `Config/Products.luau`)

### PAY-01 · IDs at 0 are inert · P0 · Setup A
**Expected** With all IDs at `0`: no purchase buttons prompt anything, and Output has no errors.

### PAY-02 · Developer product grants exactly once · P0 · Setup A
**Steps** Buy a developer product, then rejoin quickly.
**Expected** The item appears **once**, even after the rejoin and any Roblox retry.
**Auto** `receipts_spec` (idempotent grants, unconfirmed save is retried).

### PAY-03 · Game pass · P1 · Setup A
**Expected** Passes apply on join: **Extra Plot** = 16 tiles allowed, **Ordal** = +10% sale price and an **[Ordal]** chat tag. A pass never protects from a raid.

---

## 9. Exploratory notes (free-form)

After the scripted cases, spend 10 minutes just playing and note anything odd: stuck states, ugly camera, confusing text, missing sounds. Write each in the run sheet under **Findings**, and turn anything that was a real bug into a new test case here or an automated test.
