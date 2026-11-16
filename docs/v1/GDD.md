# Juragan Desa — Game Design Document

> **v1 baseline (frozen).** This describes the game as built before v2. Current direction: [v2/PLAN.md](../v2/PLAN.md).

> Working title. Satirical Indonesian village farming game on Roblox.
> Version 0.1 · 2026-11-09 · Status: pre-production

---

## 0. Assumptions & open items

Decisions already made with the designer:

| Topic | Decision |
|---|---|
| Officials & police | NPCs only (no player cops) |
| Cheating / law | Sus meter → raids; players can report each other with proof. Keep simple. |
| Long-term goal | Petani → **Juragan** (v1) → **Kepala Desa** (update after v1) |
| Monetization | Cosmetics + passes **and** paid shortcuts (with guardrails, §9) |
| Art | Exaggerated caricature characters in a semi-realistic village |
| Team | Solo, new to Luau |
| v1 scope | Small MVP, target 4–6 weeks |

Assumed (change any of these freely):

- **Language:** Indonesian-first, English localization at launch.
- **Platform:** mobile-first (most Indonesian Roblox players are on phones); PC/console supported.
- **Server size:** 8–10 players, one plot each.
- **Audience:** 13+ tone, comfortable for 16+. One report (industry.co.id, unverified single source) says Indonesia deactivated under-16 Roblox accounts in March 2026, so design for global players too.
- **Name:** "Juragan Desa" is a placeholder.

Open items (must resolve before publishing):

1. **Roblox Maturity & Compliance questionnaire** — the game depicts bribery and minor crime (comedic, non-violent). Answer honestly; expected rating Mild/Moderate. Verify before launch.
2. Final Robux prices (§9).
3. Paid random items: v1 has **none**. If seed crates are added later, check `PolicyService` rules first.

---

## 1. Pitch

You're a broke farmer in **Desa Sukasogok** (*sogok* = bribe), an obviously fictional village where the rules are strict and enforcement is… flexible. Grow crops, sell at the pasar, and climb from *petani gurem* to **Juragan**.

You can do it honestly, but it's faster to cut corners: dodgy fertilizer, black-market price-gouging, stealing your neighbor's irrigation water. Every shortcut raises your **Sus** meter. Too sus and the **Polisi Desa** raid your farm, sinetron-style, with dramatic zooms. Pay the fine, or slip them an *amplop*.

Your neighbors can catch you in the act, record **bukti** on their phone, and report you for a reward. If enough people report you, your case goes **VIRAL** and no amplop can save you.

**Pillars**

1. **Cheating pays, and getting caught is funny.** Each shortcut must be clearly profitable, and the punishment should be a comedy scene, not a grind.
2. **Neighbors are the real police.** The most interesting multiplayer is player against player (who snitches on whom), not the NPCs.
3. **Satire of systems, not people.** We mock bureaucracy, pungli (petty extortion) and "no viral, no justice". We never target real officials, parties, ethnic groups or religions.

**Reference games (studied for mechanics, not copied)**

- *Grow a Garden*: plant → wait → sell loop, with crops that keep growing while you're offline.
- *Papers, Please* / *3rd World Farmer*: bureaucracy and corrupt officials as mechanics.
- *Murder Mystery 2*: social suspicion between players.
- *Coffee Talk* / sinetron TV drama: comic tone and character writing.

---

## 2. Core loop

```
 ┌──────────────► PLANT (timing minigame → quality)
 │                     │
 │                 GROW (real-time timer, continues offline)
 │                     │      ▲
 │                     │      └── CHEAT? (oplosan / curi air) → +Sus
 │                 HARVEST (minigame → quality)
 │                     │
 │                 SELL at Pasar (legal)  or  Tengkulak Gelap (+price, +Sus)
 │                     │
 └──── BUY seeds / plots / cosmetics ◄─┘

 Running alongside the loop:
   Sus meter → Pak RT gossip → Surat Panggilan → RAID (pay a fine / slip an amplop / go to jail)
   Neighbors → witness → bukti → LAPOR → reward for the reporter, +Sus for the cheater
```

**Session target:** 15–25 minutes. First raid should be possible within ~10 minutes for a player who cheats.

---

## 3. Farming

### 3.1 Plot

- Each player is assigned a plot on join (8–10 plots around the village).
- The plot starts with **6 tiles**. Buy more tiles up to **12** (the Extra Plot pass adds 4 more, for 16).
- Crops keep growing while the player is offline, based on server timestamps.

### 3.2 Crops (v1)

| Crop | Seed (Rp) | Grow time | Base sell (Rp) | Notes |
|---|---|---|---|---|
| Padi | 10 | 60 s | 18 | Starter crop |
| Jagung | 25 | 2 min | 50 | Unlocked at Petani rank |
| Cabai | 60 | 4 min | 140 | Hit by the **Harga Cabai Meroket** event (sells ×3 for 5 min) |
| Durian | 300 | 15 min | 900 | Running gag: the smell triggers NPC complaints. Unlocked at Juragan rank |

Sale price = base × quality (0.8–1.3) × any event multiplier.

### 3.3 Interaction minigames

Planting and harvesting each open a short minigame (2–5 s). The result sets **quality** from 0.8 to 1.3.

1. **Mencangkul (hoeing, on plant):** a needle swings across a bar; tap when it's inside the green zone. Three taps. More hits means higher quality.
2. **Babat (cutting, on harvest):** hold to fill a gauge and release in the sweet spot. Releasing too early gives a weak cut, too late fumbles the cut. *(First thing to cut if behind schedule: harvest becomes a simple hold button with quality 1.0.)*

Players can skip either minigame with **Auto** for a flat quality of 0.9. Auto exists for convenience; skill gives a small bonus.

---

## 4. Cheats (shortcuts)

Every cheat must be clearly worth it, or nobody cheats and the law systems never trigger.

| Cheat | Gain | Sus | Evidence (what neighbors can witness) |
|---|---|---|---|
| **Pupuk Oplosan** (dodgy fertilizer, Rp 20/tile) | −40% grow time | +15 | The crop glows a sickly green until harvest |
| **Jual ke Tengkulak Gelap** (selling above the HET, the government price ceiling) | +30% sale price | +20 | The sale happens at a shady stall behind the pasar |
| **Curi Air** (diverting a neighbor's irrigation water) | One-time: your growing tiles finish 30 s sooner and the victim's growing tiles take 30 s longer. One steal per victim every 5 min | +10 | A visible pipe to the victim's plot |

Rules:

- Sus goes up when the cheat is done. Confiscation only happens during a raid.
- Crops grown with oplosan stay "hot" until sold. In a raid they're confiscated.

---

## 5. Law & order

### 5.1 Sus meter (0–100)

- Shown on the HUD as an 👀 eye icon that changes color: green → yellow → red.
- Decays by 1 point every 20 seconds while online. Saved between sessions, so logging out doesn't clear it.

| Sus | What happens |
|---|---|
| 0–29 | Nothing |
| 30–59 | **Pak RT gossips**: NPC speech bubbles about you ("Kok cepet banget panennya ya…", "how is the harvest so fast…") |
| 60–79 | **Surat Panggilan**: a warning letter pops up. Pak RT offers to "handle it" for an amplop |
| 80–99 | Every 20 s there's a 10% chance of a raid |
| 100 | Immediate raid |

### 5.2 Pak RT (bribe NPC)

- Pay **uang rokok** ("cigarette money") to lower Sus by 10.
- Price starts at Rp 100 and goes up ×1.5 for each repeat bribe within 10 minutes (Pak RT gets greedy).
- 3-minute cooldown.
- **Bribes are the economy's main money sink.** They keep a Grow a Garden-style economy from inflating, so tune them on purpose.

### 5.3 Raid (Operasi Sapu Bersih)

1. A siren plays and a "BREAKING NEWS" banner appears. The camera does a sinetron zoom on your face, three times.
2. 2–3 Polisi Desa NPCs walk to your plot. Hot (oplosan) crops are confiscated.
3. You choose:
   - **Bayar Denda (pay the fine):** 20% of cash (min Rp 50, max Rp 5,000).
   - **Kasih Amplop (bribe):** costs 10% of cash. 75% chance it works and the raid ends. 25% chance: *"Amplop kurang tebal, Pak!"* ("the envelope's too thin!"), and you pay the fine ×1.5.
   - **Can't pay?** All your cash goes, plus 45 seconds in the **Pos Ronda** (village guard post, used as a jail). You can still chat there, wearing an orange vest.
4. After a raid, Sus resets to 30 and you're safe from raids for 3 minutes.

**VIRAL raid:** triggered by reports (§6). The amplop option is greyed out: *"Udah viral, Pak. Gak bisa."* ("It's gone viral, sir. Can't help you.")

---

## 6. Lapor: players reporting players

Players can't upload real screenshots, because the server can't read them. Instead, the server decides what counts as proof:

1. Whenever a player cheats, the server logs the act with its position and time.
2. Every other player within **40 studs** gets a **Bukti** notice, a phone pop-up: *"📱 Rekam?"* ("Record?"). Tapping it plays a fake phone-camera animation and stores a **bukti token** in their HP (phone).
3. The token expires after **3 minutes**. Turn it in at the **Pos Polisi**:
   - The **first** reporter of a cheat event gets a reward **paid out of the cheater's cash**: 50% of the cheat's value (the oplosan cost, the extra profit from a black-market sale, or a flat Rp 20 for Curi Air), up to the cash they have. Money moves between players; none is created.
   - +2 Nama Baik for the reporter (max +10 per day from reports).
   - Cheater gets +25 Sus.
4. **VIRAL:** if 2 different players report you within 5 minutes, you get an immediate VIRAL raid. Later reporters earn no cash but still count toward VIRAL.

Anti-grief / anti-farming rules:

- Only server-logged acts can be reported, so a report can't be fake.
- One report per cheat event per witness; only the first one pays.
- 60 s cooldown between reports for each reporter.
- The reward is only ever half of what the cheat cost or earned, taken from the cheater, so two friends can't farm money by "cheating" and reporting each other.
- Victims of Curi Air always get a bukti token, even when farther than 40 studs.

*Later (not v1): **Uang tutup mulut** (hush money), where the cheater pays a witness before they report.*

---

## 7. Progression

### 7.1 Ranks

| Rank | Requirement | Unlocks |
|---|---|---|
| Petani Gurem | Start | Padi |
| Petani | Rp 1,000 earned lifetime | Jagung, Cabai, tile purchases |
| **Juragan** | Rp 10,000 earned lifetime + 12 tiles owned | Durian, gold peci, "Juragan" chat tag, can hire 1 NPC **buruh** (auto-waters) *(buruh optional for v1)* |
| *Calon Kades* (update) | Juragan + Nama Baik ≥ 60 | Can run for Kepala Desa |
| *Kepala Desa* (update) | Wins the server election | See §7.3 |

### 7.2 Nama Baik (reputation, 0–100, starts at 50)

| Action | Change |
|---|---|
| Caught in a raid | −10 |
| VIRAL raid | −20 |
| Successful report | +2, max 10 per day |
| Watering a neighbor's crops (gotong royong) | +1, max 10 per day |

Nama Baik doesn't affect v1 gameplay beyond being displayed. It exists now so the Kepala Desa update doesn't need a data migration.

### 7.3 Kepala Desa (post-v1 update, designed now)

- Election every 20 minutes per server, open to Juragans with enough Nama Baik. The campaign phase lasts 3 minutes.
- **Serangan fajar** ("dawn attack", handing out cash for votes) is the election cheat: buy NPC votes, with heavy Sus.
- The winner sets a sales tax from 0–10% and collects it.
- The winner can call **Kerja Bakti**: a 2-minute server-wide event where everyone's crops grow +20%.
- If the Kepala Desa is raided, they're impeached on the spot.
- Lifetime stat: times elected.

---

## 8. World & tone

- **Map:** one village. Areas: plots around the sawah (rice fields), Pasar, Tengkulak Gelap stall, Pak RT's house, Pos Polisi, Pos Ronda, warung (hangout spot).
- **Art:** semi-realistic environment (Creator Store assets, warm lighting, sunset). **Caricature NPCs**: R15 rigs with big heads, exaggerated proportions, expressive faces and over-the-top animations. No custom-modeled characters in v1.
- **Writing:** short, punchy Indonesian lines in sinetron/meme style with English translations.
- **Audio:** dangdut-style loops, a cartoon siren, a sinetron "JENG JENG JENG" sting on raids.
- **Fictional authority:** "Polisi Desa" wear a **made-up** uniform: a non-Polri color and an invented badge. Use generic titles only (Pak RT, Lurah, Kepala Desa). No real people, parties, logos or slogans.

---

## 9. Monetization

Designer's choice: cosmetics + passes **and** paid shortcuts.

⚠️ **Risk, accepted by the designer:** paid shortcuts could let paying players ignore the law, which would break the satire and the reporting loop. The guardrails below exist to prevent that.

### 9.1 Game passes

| Pass | Benefit | Guardrail |
|---|---|---|
| **Ordal** ("orang dalam", insider connections) | +10% legal sale price, "Ordal" chat tag | Never protects against raids |
| **Extra Plot** | +4 tiles (16 max) | — |
| **VIP Warung** | Cosmetic hangout corner + a dangdut radio | — |

### 9.2 Developer products (consumables)

Each purchase adds a **stored item** to the player's inventory. It's used later with a separate action, so a purchase is never wasted when it can't be used right now.

| Product | Effect when used | Guardrails (server-enforced) |
|---|---|---|
| **Amplop Premium** | −20 Sus | 10-minute cooldown. Can't be used during an active raid or VIRAL case. Never grants immunity. |
| **Jaminan Kilat** (express bail) | Skips the rest of the Pos Ronda jail timer | Only skips the timer; the fine is still paid |
| **Karung Bibit** (seed sack) | A fixed bundle of seeds (no randomness) | — |

### 9.3 Cosmetics

Peci, batik, sarung and caping (straw farmer hat) outfits; gerobak (cart) and plot decorations; raid "entrance" stings (funny, cosmetic only).

---

## 10. UI (mobile-first)

- **HUD:** cash (Rp), Sus eye, Nama Baik, rank badge, HP (phone) button.
- **Minigame panel:** a centered card with one big tap area, readable on a 5" phone.
- **HP (phone):** bukti tokens, Lapor button, inventory (amplop, bail), notifications ("Pak RT mau ngobrol…", "Pak RT wants a word…").
- **Raid screen:** full-screen sinetron overlay with 2 big choice buttons.
- All text comes from one string table (ID + EN).

---

## 11. v1 scope (MVP)

**In:** 1 village, 4 crops, plot + tile purchase, Mencangkul minigame, Babat minigame (cuttable), 3 cheats, Sus meter, Pak RT bribe, raids (fine/amplop/jail), Lapor + VIRAL, ranks up to Juragan, Nama Baik (stored and shown), 3 passes, 3 dev products, cosmetics shop (small), ID + EN.

**Out (updates):** Kepala Desa election, hush money, livestock, Pak Lurah, buruh NPC (unless time allows), Harga Cabai event (cheap; add if time allows), leaderboards, trading.

## 12. Success metrics (first 2 weeks live)

| Metric | Target |
|---|---|
| D1 retention | ≥ 15% |
| Avg session | ≥ 12 min |
| Players who cheat at least once | ≥ 60% (otherwise cheats aren't worth it) |
| Raids per cheating player per session | ~1 (too many = frustrating, 0 = no tension) |
| Reports per session | > 0.5 (shows the neighbor-conflict loop is used) |
