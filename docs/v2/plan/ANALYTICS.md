# Analytics — events, triggers, and the questions they answer

> One owner: `server/Analytics/Analytics.luau`. Nothing else calls `AnalyticsService` directly.
> Every call is server-side, happens after the authoritative mutation, and is wrapped so a
> failure can never break gameplay. The platform dashboard is the only reader of this data.

Status: implemented for M4 (A3). Checked by `tests/specs/analytics_spec.luau` under Lune.
The live Roblox dashboard has **not** been verified in Studio yet (`belum diverifikasi di Studio`).

---

## 1. Contract

| Rule | How it is enforced |
|---|---|
| Server only | The wrapper lives in `ServerScriptService`; no client module requires it. |
| Never fatal | Every `AnalyticsService` call runs inside `pcall`; failures are dropped silently. |
| Respect the platform rate limit | Our own budget is `120 + 20 * #Players` calls per 60 seconds. Past it, events are dropped before they reach the service. |
| No duplicates | `Analytics.once(player, name, ...)` remembers per player; funnel steps and economy events only fire after one committed mutation. |
| No personal data | Events carry numbers and short config ids only. Display names, UserIds, chat and free text never go into an event or a custom field. |
| Fields are stable | At most three custom fields (`CustomField01..03`), chosen in code from config ids. |

Entry points:

```lua
Analytics.track(player, "harvest", 1, { "padi", "sultan", "sack" })
Analytics.once(player, "first_harvest", 1)
Analytics.economy(player, "Source", 50, 150, "IAP", "rupiahKecil")
Analytics.onboarding(player, 2, "harvest")
Analytics.funnel(player, "ShopPurchase", sessionId, 1, "OpenedShop")
```

`Analytics.log` is kept as an alias for `track` so older call sites keep working.

---

## 2. Custom events

| Event | Value | Custom fields | Sent when | Question answered |
|---|---|---|---|---|
| `harvest` | `1` | crop, tier, destination (`sack`/`gudang`) | After a harvest survives the season risks and the tier roll. | How often do players harvest, and do they chase rare tiers or just volume? |
| `raid_started` | `1` normal, `2` viral | `normal` / `viral` | A raid state machine starts for a player. | How often are raids triggered, and how many are player-driven (viral)? |
| `cheat_used` | `1` oplosan, `2` curi air, `3` gelap | cheat id | After a cheat action really applied (not on a failed attempt). | Which cheats are discovered and used most? |
| `report_made` | `1` | — | A report is accepted and the first-reporter reward is settled. | Is the report loop used at all? |
| `debt_borrowed` | principal | `pinjol` | A loan is committed. | How many players take the first loan, and for how much? |
| `debt_overdue` | stage (`1..3`) | `warning` / `shame` / `seize` | The loan crosses an overdue threshold. | Where do overdue players drop out of repayment? |
| `debt_cleared` | `1` | `ontime` / `overdue` / `seized` | The loan reaches zero, by repayment or seizure. | Do players recover from debt, and how? |
| `debt_seized` | Rp recovered | `gudang` | Each seizure that actually removes crops. | How much value does the collector recover per tick? |
| `purchase` | `1` | product key | A developer product was granted and saved. | Which Robux products convert? |
| `login_streak` | streak length | — | A daily login reward is claimed. | Is the login habit forming? |
| `task_claimed` | `1` | — | A daily task reward is claimed. | Are daily tasks finished or ignored? |
| `rank_up` | rank index | — | A player crosses a rank requirement. | How long does progression take, and where does it stall? |
| `badge_awarded` | badge id | — | A badge is awarded for the first time. | Which milestones are reached? |
| `risk_banjir` / `risk_hama` / `risk_gagal` | `1` | — | A seasonal risk destroys a crop at harvest. | Do seasons feel punishing or fair? |
| `first_harvest` (example `once`) | `1` | — | First time only, via `Analytics.once`. | Activation: did the player finish the core verb? |

---

## 3. Economy events

Every committed cash mutation logs one `LogEconomyEvent` from `EconomyService`:

| Flow | Trigger | `sku` examples | Transaction type |
|---|---|---|---|
| Source (earned) | Pasar sale | `pasar` | `Gameplay` |
| Source | Tengkulak Gelap sale | `tengkulak_gelap` | `Gameplay` |
| Source | Pinjol loan disbursed | `pinjol_pinjam` | `Gameplay` |
| Source | Quest / login reward | `hadiah_tugas`, `hadiah_login` | `Gameplay` |
| Source | Report reward (transfer in) | `hadiah_laporan` | `Gameplay` |
| Source | Admin grant (testing) | `admin_grant` | `Gameplay` |
| Source | Robux cash pack | product key, e.g. `rupiahKecil` | `IAP` |
| Sink (spent) | Seed purchase | `bibit_padi` | `Gameplay` |
| Sink | Tool upgrade | `alat_cangkul` | `Gameplay` |
| Sink | Tile purchase | `petak` | `Gameplay` |
| Sink | Buruh hire / wage | `buruh_sewa`, `upah_buruh` | `Gameplay` |
| Sink | Cosmetic purchase | `kosmetik_<id>` | `Gameplay` |
| Sink | Bribe | `sogok` | `Gameplay` |
| Sink | Pinjol repayment | `pinjol_bayar` | `Gameplay` |
| Sink | Raid fine / amplop | `raid_denda`, `raid_amplop` | `Gameplay` |
| Sink | Cheat cost, refund, report transfer out | `cheat_oplosan`, `refund_oplosan`, `hadiah_laporan` | `Gameplay` |

The reported balance is the value written by the mutation (`data.cash` after it changed), never a
number recomputed from a UI replica. Purchased cash is granted with `earned = false`, so it is a
real source in the economy graph but never raises rank or `lifetimeEarned`.

Questions answered: which sources fund the mid-game, which sinks actually bite, whether Robux
cash packs inflate the economy, and whether the pinjol is a source of new money or a trap.

---

## 4. Funnels

| Funnel | Steps | Sent when | Question answered |
|---|---|---|---|
| Onboarding (`LogOnboardingFunnelStepEvent`) | 1 plant, 2 harvest, 3 sell, 4 buy, 5 finished | `OnboardingService.advance` marks the expected step done. | Where does the first session break? |
| `ShopPurchase` (`LogFunnelStepEvent`) | 1 OpenedShop, 2 ViewedItem, 3 ClickedBuy, 4 Confirmed | Reserved for the client purchase funnel; not wired in M4. | Which shop step loses players? |

Skipped onboarding steps back-fill automatically on the platform, but the server only advances in
order, so a step cannot be reported before the action really happened.

---

## 5. What is deliberately not sent

- Display names, UserIds, account age, locale, chat, or any free text.
- Failed actions: a refused purchase, a failed borrow, or a raid that never started logs nothing.
- Client-reported events: an exploiter cannot inflate a counter because the client never calls the
  wrapper.
- Per-frame or per-tick noise: high-frequency signals are aggregated by the gameplay rule before
  they reach `track` (for example, harvest is one event per crop, not per tile refresh).

---

## 6. Adding an event

1. Pick an existing event name and a new custom field before inventing a name (100-name limit).
2. Call `Analytics.track` / `Analytics.economy` **after** the mutation succeeds.
3. Pass only config ids as fields; never a player name.
4. Add the row to the tables above.
5. If the event must fire once per player, use `Analytics.once`.
6. Add a test in `tests/specs/analytics_spec.luau` or the owning service spec.
7. Verify it in Studio: Creator Hub → Analytics → the event type → **View Events** (near real
   time, unlike the ~24h dashboard).
