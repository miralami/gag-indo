# Juragan Desa v2 — Full Playtest Cases

Companion to [PLAYTEST_PLAN.md](PLAYTEST_PLAN.md). The plan is scenarios; this file is executable cases.
Expected values come from `src/shared/Config/*` as of commit 76c0c23 plus the uncommitted working tree. Where a value comes from a file not listed here, the expected result says "per config".

## How to run (multiple passes)
The suite is meant to be run more than once. Each pass has a different purpose:

| Pass | Setup | Cases to run | Purpose |
|---|---|---|---|
| R1 Fresh | New UserId / wiped save, Studio Play Solo, desktop | All | Baseline, FTUE, first-time flows |
| R2 Returning | Same account as R1 after Stop and Play | PER, then all REG-flagged cases | Persistence and migration |
| R3 Phone | Device Emulator 375x812 and 360x640, touch | UI, FTUE, MG, HUD cases | Layout and touch |
| R4 Multi | Local Server, 2 players (A admin, B normal) | MP, ADM, SEC, LAW | Replication, authority |
| R5 Soak | Play Solo 30 min, no admin shortcuts after setup | PERF, DEBT, MKT | Time-based and leak behavior |
| R6 Regression | After each fix, rerun the failed case plus its neighbors | Failed IDs | Confirm fixes |

Result codes: PASS / FAIL / BLOCKED (reason) / N/A. Every FAIL needs: case ID, pass (R1..R6), actual, Output text, screenshot.

## Admin shortcuts (use only where a case says "ADMIN")
F2 opens the admin panel (Studio always counts as admin). Use it to set season/event or grant state. Record which command you used. Note: the screenshot session showed RP 999,985. The owner confirmed it was a deliberate cash cheat (so the cheat works), not a bug. `Game.startCash = 50` is the real start, so FLOW cases must use a fresh save without the cheat.

## Reference numbers
Start: cash 50, 5 padi seeds, 6 tiles, sack 40, gudang 40 (120 with pass). Tile N price = 100 x 2^(owned-6), max 12 (16 with pass). Rank to Petani: 1000 lifetime earned. Rank to Juragan: 10000 earned and 12 tiles. Padi: seed 10, grows 60 s, sells 18. Singkong: 16 / 90 s / 30. Jagung: 25 / 120 s / 50. Bawang: 35 / 150 s / 72. Cabai: 60 / 240 s / 140. Minigame accepted window: 0.8 s to 30 s. Cabai event: first at 240 s, every 600 s, lasts 300 s, x3.

---

## SMK — Smoke (blocking)
| ID | Pass | Steps | Expected |
|---|---|---|---|
| SMK-01 | R1 | Open place via Rojo, press Play | No red errors; all services start |
| SMK-02 | R1 | Wait 15 s | HUD shows cash, rank, sack, Sus, reputation; hotbar; Seeds/Phone/Board buttons |
| SMK-03 | R1 | Output with Warn on | Only warnings you record; none repeat every frame |
| SMK-04 | R1 | Walk 30 s around village | No nil/index errors from Sky, Tiles, Hud |

## FLOW — First-time experience (FTUE)
| ID | Pass | Precondition | Steps | Expected |
|---|---|---|---|---|
| FLOW-01 | R1 | Fresh save | Read the cash on the HUD at first spawn | Cash = 50. If not, note the source (the owner's cash cheat is a known cause; start from a save without it) |
| FLOW-02 | R1 | Fresh save | Read the starting hotbar | Padi x5 present; other slots empty |
| FLOW-03 | R1 | Fresh save | Read the Village Guide banner | A step 1 prompt ("plant") appears; language is consistent |
| FLOW-04 | R1,R3 | FLOW-03 | Plant on a tile | Guide advances to "harvest"; the tile shows a growing stage |
| FLOW-05 | R1 | FLOW-04 | Harvest after 60 s | Minigame runs; the sack changes; the guide advances to "sell" |
| FLOW-06 | R1 | FLOW-05 | Sell at Pasar | Cash rises; the guide advances to "buy" |
| FLOW-07 | R1 | FLOW-06 | Buy seeds in the shop | Guide completes; no further tutorial prompts; funnel events logged (Output) |
| FLOW-08 | R1 | Fresh save | Complete FLOW-03 to 07 without any admin or help; note the time | Under 5 min; no dead end; no unclear text |
| FLOW-09 | R2 | After FLOW-07, Stop/Play | Rejoin | The tutorial does not restart |
| FLOW-10 | R3 | Fresh phone-size save | Run FLOW-03 to 07 with touch only | All steps are reachable; nothing is hidden behind other UI |

## FARM — Planting, growing, harvesting
| ID | Pass | Steps | Expected |
|---|---|---|---|
| FARM-01 | R1 | Plant padi at a tile within 16 studs | Seed count -1; the tile shows a crop |
| FARM-02 | R1 | Try to plant from 40+ studs | Refused; no seed spent |
| FARM-03 | R1 | Try to plant on an occupied tile | Refused; no seed spent |
| FARM-04 | R1 | Try to plant with 0 seeds of that crop | Refused with a clear message |
| FARM-05 | R1 | Watch a padi tile for 60 s | Stages bibit, tumbuh, siap, with a timer or visual cue |
| FARM-06 | R1 | Harvest before it is ready | Refused; the crop is unaffected |
| FARM-07 | R1 | Harvest when ready | Sack count +1 (or more if traits); tile empties (or regrows for kebun) |
| FARM-08 | R1 | Plant and harvest 6 tiles in sequence | No desync between tile visuals and state |
| FARM-09 | R1 | Fill the sack to 40/40 | The next harvest is refused with a clear message; nothing is lost |
| FARM-10 | R1 | Buy tile #7 (owned 6) | Price 100; a new tile unlocks; cash -100 |
| FARM-11 | R1 | Buy tile #8 | Price 200 (doubles each purchase) |
| FARM-12 | R1 | Own 12 tiles, try tile #13 | Refused (cap 12 without the pass) |
| FARM-13 | R1 | Tile buy with insufficient cash | Refused; cash unchanged |
| FARM-14 | R1 | Plant singkong, jagung, bawang | Grow times 90 s, 120 s, 150 s; rank-locked ones refuse at the wrong rank |
| FARM-15 | R1 | Plant a kebun-family crop | It regrows after harvest up to `maxHarvests`, then clears |
| FARM-16 | R1 | Plant a perkebunan-family crop | Long grow time; a rare tier is possible |
| FARM-17 | R1 | Harvest 20+ crops | A rarity mix of biasa/bagus/super (and above if it occurs); at least one tinted reveal toast |
| FARM-18 | R1 | Leave and rejoin while crops grow | Growth time continues based on the real elapsed time (no restart or free finish) |
| FARM-19 | R1 | Tile in a malformed state (admin or test only, if possible) | No red error from the nil `PlantedAt`/`GrowSeconds` reads in FarmService |

## MG — Minigames
| ID | Pass | Steps | Expected |
|---|---|---|---|
| MG-01 | R1,R3 | Start Mencangkul | Playable with mouse and touch; a result is submitted |
| MG-02 | R1,R3 | Start Babat | Same |
| MG-03 | R1 | Complete in under 0.8 s (e.g. spam) | Result ignored or minimal, not instant success |
| MG-04 | R1 | Leave a minigame idle past 30 s | Times out cleanly; the tile is not stuck |
| MG-05 | R1 | Cancel a minigame midway (`Minigame_Cancel`) | The tile returns to a usable state |
| MG-06 | R1 | Reset the character mid-minigame | The overlay closes; no stuck input or camera |
| MG-07 | R1 | Auto harvest (if owned) | Quality 0.9; slower rate (2 per second) |

## SHOP — Shop and seeds
| ID | Pass | Steps | Expected |
|---|---|---|---|
| SHOP-01 | R1 | Open the shop | Shelves listed; padi always present (stock x1.4 range); restock countdown visible |
| SHOP-02 | R1 | Buy 1 padi seed | Cash -10; seeds +1 |
| SHOP-03 | R1 | Buy the max per click (50) | Allowed only if cash and stock allow; otherwise a clear refusal |
| SHOP-04 | R1 | Buy more than the stock | Refused or clamped; stock never negative |
| SHOP-05 | R1 | Buy a crop above your rank | Refused with a message |
| SHOP-06 | R1,R2 | Note the shelves, Stop/Play within the same 3-min window | The same shelves (no rejoin refresh) |
| SHOP-07 | R5 | Wait past 180 s | A new shelf; the countdown resets |
| SHOP-08 | R1 | Season change via ADMIN | Shelf odds change by season on the next restock (per config) |
| SHOP-09 | R1 | Rare items (durian, sawit, cengkeh, kakao) | Appear rarely and in low amounts |

## MKT — Selling and market
| ID | Pass | Steps | Expected |
|---|---|---|---|
| MKT-01 | R1 | Sell 1 padi at Pasar | About 18 x market multiplier x reputation bonus; cash updates |
| MKT-02 | R1 | Sell a large stack (30+) | The price falls per item (0.3% per item sold, floor 0.6x) |
| MKT-03 | R1,R5 | Check the price after 10 min | The pressure decays toward 1.0 |
| MKT-04 | R1 | Check the phone price board | Matches the real sell price |
| MKT-05 | R1 | Reputation 0 vs 100 | Pasar price -5% / +5% vs 50 (baseline) |
| MKT-06 | R1 | The multiplier never exceeds 1.25x or goes below 0.6x | Verify at the extremes |
| MKT-07 | R1 | Sell with an empty sack | Refused or a no-op; no error |
| MKT-08 | R1 | Pasar Gelap sell | The price is x1.3; Sus +20; evidence value logged |
| MKT-09 | R1 | Sell "hot" produce at Pasar | Refused (it must go through Gelap) |
| MKT-10 | R1 | Cabai event on (ADMIN or wait 240 s) | Cabai x3 for 300 s; the HUD/toast announces; it ends on time |
| MKT-11 | R4 | A sells a large stack | B sees the changed price on the board |
| MKT-12 | R1 | Sell while far from Pasar (over `npcDistance` 18) | Refused |

## STO — Gudang and storage
| ID | Pass | Steps | Expected |
|---|---|---|---|
| STO-01 | R1 | Deposit clean produce | Moves from the sack to the gudang; the quality is preserved |
| STO-02 | R1 | Deposit oplosan produce | Refused; returned unchanged |
| STO-03 | R1 | Fill to the capacity of 40 | The next deposit refused; no loss |
| STO-04 | R1 | Withdraw | Back into the sack; refused if the sack is full |
| STO-05 | R1 | Withdraw/deposit rapidly (20 clicks) | No duplication; counts match |
| STO-06 | R2 | Rejoin | The gudang contents survive |

## TOOL — Tools
| ID | Pass | Steps | Expected |
|---|---|---|---|
| TOOL-01 | R1 | Buy cangkul bambu (60) | Cash -60; plant bonus +5% |
| TOOL-02 | R1 | Buy cangkul baja (350) | Only after bambu; +12% |
| TOOL-03 | R1 | Try to skip a tier | Refused |
| TOOL-04 | R1 | Gembor (150, x1.10 grow) needs Petani | Refused at Gurem |
| TOOL-05 | R1 | Karung besar (200, +20 sack) | The sack cap goes from 40 to 60 |
| TOOL-06 | R1 | Karung gerobak (800, +60) | Cap 100 |
| TOOL-07 | R1 | Traktor (1500, Juragan) | Refused below Juragan |
| TOOL-08 | R1 | Buy with insufficient cash | Refused; unchanged |
| TOOL-09 | R2 | Rejoin | The tools persist |

## WRK — Buruh (worker)
| ID | Pass | Steps | Expected |
|---|---|---|---|
| WRK-01 | R1 | Hire with cash >= 150 | Cash -150; a shift starts (300 s) |
| WRK-02 | R1 | Hire with cash < 150 | Refused |
| WRK-03 | R1 | Hire while already on a shift | Refused (one at a time) |
| WRK-04 | R1 | Watch a pass (every 20 s) | At most 5 items per pass; into the gudang; wage 2/item deducted |
| WRK-05 | R1 | The gudang is full | The worker stops and goes home |
| WRK-06 | R1 | Cash can't cover the wage | The worker stops |
| WRK-07 | R1 | The shift ends at 300 s | The worker goes home; can hire again |
| WRK-08 | R1 | The worker harvest rarity/traits/Almanak | Follows the same path as the manual harvest |

## DEBT — Pinjol
| ID | Pass | Steps | Expected |
|---|---|---|---|
| DEBT-01 | R1 | Gurem, rep 50: borrow 500 | Limit 500; fee 10% added to the debt (debt 550); cash +500 |
| DEBT-02 | R1 | Borrow above the limit | Refused |
| DEBT-03 | R1 | Rep 100 vs 0 | Limit x1.5 vs x0.5 |
| DEBT-04 | R1,R5 | Wait 1 hour of play (or ADMIN time) | Interest +5%/h online; the total never exceeds 3x principal |
| DEBT-05 | R2 | Leave, return after a known offline time | Offline interest 2%/h applied once |
| DEBT-06 | R1 | Repay part | Debt decreases; cash decreases |
| DEBT-07 | R1 | Repay more than the debt or more than the cash | Clamped or refused; no negative values |
| DEBT-08 | R1 | Repay in full on time | The debt_free badge awards once |
| DEBT-09 | R5 | Let the debt go 10 min overdue | Stage 1 warning |
| DEBT-10 | R5 | 3 min overdue | The shame callout; Nama Baik -5 |
| DEBT-11 | R5 | 6 min overdue | DebtCollector seizes the gudang crops; the message is clear |
| DEBT-12 | R1 | Borrow while in debt | Per rules (limit applies to the total); no exploit to exceed the limit |
| DEBT-13 | R4 | Borrow, rejoin on a different server | The debt persists |

## QST — Quests, streak, badges
| ID | Pass | Steps | Expected |
|---|---|---|---|
| QST-01 | R1 | Open the quests | 3 daily tasks from the pool; progress 0 |
| QST-02 | R1 | Do a task (e.g. harvest 10) | Progress updates live; claiming pays the cash and Nama Baik per config |
| QST-03 | R1 | Claim twice | The second is refused |
| QST-04 | R1 | Claim before done | Refused |
| QST-05 | R2 | Rejoin the same day | The same tasks and progress |
| QST-06 | R2 | The next UTC day (ADMIN/date change) | A new roll; the old ones reset |
| QST-07 | R2 | Login streak day 1 | 100 cash |
| QST-08 | R2 | Days 2 to 7 | 5 padi, 250, amplop premium, 4 cabai, 600, jaminan kilat |
| QST-09 | R2 | Skip a day | Streak resets (per design) |
| QST-10 | R2 | Claim the daily streak twice in a day | Refused |
| BDG-01 | R1 | Get raided for the first time | first_raid badge once |
| BDG-02 | R1 | Harvest a Sultan-tier crop | first_sultan once |
| BDG-03 | R2 | The badges persist and do not re-award | No duplicate toast |

## RANK — Progression
| ID | Pass | Steps | Expected |
|---|---|---|---|
| RANK-01 | R1 | Earn 1000 lifetime | Rank-up to Petani, toast; Petani crops and tools unlock |
| RANK-02 | R1 | Earn 10000 with 12 tiles | Juragan; with fewer tiles, it does not rank up |
| RANK-03 | R1 | Spend cash | Lifetime earned does not drop |
| RANK-04 | R2 | Rejoin | The rank persists |
| RANK-05 | R1 | Loans do not count as earned | Borrowing does not raise the lifetime total |

## ALM — Almanak and cosmetics
| ID | Pass | Steps | Expected |
|---|---|---|---|
| ALM-01 | R1 | Harvest all palawija crops | The page toast; the caping reward |
| ALM-02 | R1 | Kebun family complete | The batik reward |
| ALM-03 | R1 | Perkebunan family complete | The peci reward |
| ALM-04 | R1 | Buy caping 250, peci 750, batik 1200 | Cash deducted; refused if short |
| ALM-05 | R1 | Equip/unequip | The avatar updates; there is one hat and one shirt |
| ALM-06 | R2 | Rejoin | Owned and equipped persist |
| ALM-07 | R1 | Equip an un-owned cosmetic (SEC) | Refused |

## LAW — Sus, cheats, bribe, raids, evidence
| ID | Pass | Steps | Expected |
|---|---|---|---|
| LAW-01 | R1 | Use oplosan (cost 20) | Cash -20; Sus +15; 40% of the remaining time removed |
| LAW-02 | R1 | Gelap sale | Sus +20; x1.3 price |
| LAW-03 | R1,R4 | Curi air from a neighbor | Sus +10; the victim's timer -30 s; a 5 min cooldown per victim |
| LAW-04 | R1 | Sus decay | -1 per 20 s |
| LAW-05 | R1 | Sus 30 | Pak RT gossip begins |
| LAW-06 | R1 | Sus 60 | The Surat Panggilan warning |
| LAW-07 | R5 | Sus 80+ | A raid rolls at 10% per 20 s tick |
| LAW-08 | R1 | Raid starts | The overlay and the banner; the skip button works; the choice prompt |
| LAW-09 | R1 | Choose pay the fine | 20% of cash, min 50, max 5000 |
| LAW-10 | R1 | Choose amplop | 10% of cash; 75% success; on failure 1.5x |
| LAW-11 | R1 | No choice in 20 s | The auto fine |
| LAW-12 | R1 | After the raid | Sus resets to 30; 180 s immunity |
| LAW-13 | R1 | Jail | 45 s; the correct actions are locked; it releases on time |
| LAW-14 | R1 | Bribe | Base 100; x1.5 per repeat in the 10 min window; the 3 min cooldown; Sus -10 |
| LAW-15 | R1 | Amplop premium | Sus -20; 10 min cooldown |
| LAW-16 | R4 | B records evidence on A within 40 studs | A token exists for 180 s |
| LAW-17 | R4 | B reports A | A's Sus +25; B gets 50% of the cheat value from A; a 60 s report cooldown |
| LAW-18 | R4 | 2 distinct reporters in 5 min | VIRAL: Nama Baik -20 for A |
| LAW-19 | R4 | Report spam | The daily cap of 10 Nama Baik |
| LAW-20 | R4 | B reports without evidence or far away | Refused |
| LAW-21 | R4 | A raid on A | B is not affected |
| LAW-22 | R1 | Caught | Nama Baik -10 |

## MP — Multiplayer and social
| ID | Pass | Steps | Expected |
|---|---|---|---|
| MP-01 | R4 | A changes the season (ADMIN) | B's HUD and sky follow |
| MP-02 | R4 | A forces the cabai event | B sees the event |
| MP-03 | R4 | A waters B's crop | +Nama Baik 1 (cap 10/day); the crop speeds up |
| MP-04 | R4 | Water an invalid or offline target | Refused; no error |
| MP-05 | R4 | The leaderboard tabs on both clients | Render; switching works; the same data; an empty state is graceful |
| MP-06 | R4 | Chat tags | Correct for admin and normal |
| MP-07 | R4 | B leaves mid-action | No server error; A is unaffected |

## ADM — Admin and LiveConfig
| ID | Pass | Steps | Expected |
|---|---|---|---|
| ADM-01 | R4 | A presses F2 | The panel opens |
| ADM-02 | R4 | B (non-admin, with the Studio shortcut off if possible) | No panel; `Admin_Command` ignored |
| ADM-03 | R4 | Change the season | Applies to all |
| ADM-04 | R1 | Malformed LiveConfig | One warning; defaults kept; the server continues |
| ADM-05 | R1 | The admin allowlist | Contains only the expected IDs |

## PAY — Monetization (placeholder IDs = 0)
| ID | Pass | Steps | Expected |
|---|---|---|---|
| PAY-01 | R1 | Prompt each pass/product | With id = 0 it is gracefully disabled or marked unavailable; no crash |
| PAY-02 | R1 | Studio test purchase, if an ID is set | Granted once |
| PAY-03 | R1 | Replay the same receipt | No double grant |
| PAY-04 | R1 | Extra Plot pass | Max tiles 16 |
| PAY-05 | R1 | Gudang pass | Capacity 120 |
| PAY-06 | R2 | Rejoin | The pass effects persist |

## PER — Persistence
| ID | Pass | Steps | Expected |
|---|---|---|---|
| PER-01 | R2 | Stop and Play | Cash, rank, tiles, planted crops, sack, gudang, debt, tools, quests, streak, badges, Almanak, cosmetics all match |
| PER-02 | R2 | Legacy v1/v2 save (if available) | Migrates with no loss |
| PER-03 | R2 | Stop during an action | No rollback, no errors |
| PER-04 | R4 | Two sessions of the same account | The session lock behaves; no duplicated data |
| PER-05 | R2 | DataStore failure (Studio API off) | Graceful message or retry; no crash |

## UI — Layout and language (from your screenshot)
| ID | Pass | Steps | Expected |
|---|---|---|---|
| UI-01 | R1,R3 | HUD panel | No offset dark rectangle behind it; content is not cut off |
| UI-02 | R1,R3 | Village Guide banner | The same; the text fits |
| UI-03 | R1,R3 | The Board button | No dark backing strip |
| UI-04 | R1,R3 | The hotbar | The backing matches the slots; slots are selectable by touch |
| UI-05 | R1 | Billboard labels | None overlap; no ghost duplicates (Pasar / Rumah Pak RT) |
| UI-06 | R1 | Language | All visible strings follow one language; or the mix is intentional and documented |
| UI-07 | R1,R3 | Compare with `mockups/index.html` | Note the gaps; the greybox is known |
| UI-08 | R3 | 360x640 | No UI overlap or off-screen elements |
| UI-09 | R3 | The phone menu | Opens/closes; tabs reachable |
| UI-10 | R1 | The Seeds panel | Scrolls; 12 crops listed; locked ones marked |
| UI-11 | R1 | Toasts stack | None stuck; they dismiss |
| UI-12 | R1 | Sound | Every sound plays at a sane volume; no stuck loops |

## SEC — Exploit probes (R4, run as a client; a script in the command bar is fine)
| ID | Remote | Probe | Expected |
|---|---|---|---|
| SEC-01 | Farm_SelectSeed, Shop_BuySeed | Wrong types, nil, NaN, negative, huge, unknown crop key | Rejected; no state change |
| SEC-02 | Farm_Complete | Without a Minigame_Start; faster than 0.8 s | Ignored |
| SEC-03 | Market_Sell | A fake item list or quantity | Server-side authority; no gain |
| SEC-04 | Debt_Borrow / Debt_Repay | Over the limit; a negative amount | Refused |
| SEC-05 | Tool_Buy / Worker_Hire | Out of order; double hire | Refused |
| SEC-06 | Raid_Choose | With no raid active | Ignored |
| SEC-07 | Evidence_* | A fake token, expired, far away | Refused |
| SEC-08 | Cosmetic_Buy/Equip | An unknown ID; an un-owned one | Refused |
| SEC-09 | Quest_Claim* | A repeat; before done | Refused |
| SEC-10 | Admin_Command | As a non-admin | Ignored; no response data |
| SEC-11 | All | 50+ calls in 1 s per remote | Throttled; the server stays responsive |
| SEC-12 | State_Request | Spam | Rate-limited |
| SEC-13 | Item_Use | An item not owned | Refused |

## PERF — Performance and stability (R5)
| ID | Steps | Expected |
|---|---|---|
| PERF-01 | A phone emulator on a full farm with the phone UI open | FPS steady (note the numbers) |
| PERF-02 | 30 min soak | Memory does not climb steadily; no growing Output spam |
| PERF-03 | Reset the character 10 times | The HUD and handlers are not duplicated; no leaked connections |
| PERF-04 | Rapid tab-switching between the Seeds/Phone/Board | No lag spikes |
| PERF-05 | 6 players or more (if possible) | The server heartbeat stays healthy |

## Exit criteria
- R1 and R2: zero FAIL in SMK, FLOW, FARM, MKT, PER, SEC.
- R3: zero FAIL in FLOW-10 and UI-01 to UI-09, or each is logged with a screenshot.
- R4: zero FAIL in SEC and ADM; MP and LAW pass.
- R5: no memory growth trend and no repeated error.
- Deliverable: one run report per pass in `docs/testing/runs/`, a prioritized bug list (blocker / major / minor), and the list of BLOCKED items with their reasons.
