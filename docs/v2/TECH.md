# Juragan Desa — v2 Technical Foundation (M0–M2)

> What M0, M1 and M2 changed, and the rules the rest of v2 builds on. Read this together with
> [v1/TECH.md](../v1/TECH.md): the ground rules there still hold — the server decides
> everything, one owner per piece of state, config lives in tables, every remote is validated
> and rate-limited. This file only documents what v2 added.

Status: **M0 complete** (except the designer decision on UI — D1 in [DECISIONS.md](DECISIONS.md) —
and the in-Studio checks in §10). **M1 (farming depth) is implemented**: 12 crops in three
families, server-rolled rarity tiers, condition-driven traits, the Almanak and the rarity reveal.
**M2 (living world) is implemented**: seasons drive growth and sky, a rotating seed shop, Pasar
supply and demand, permanent tools, the gudang and the hired buruh tani.

---

## 1. Save schema v3

Owner: `server/Data/PlayerData.luau`. Other modules call `PlayerData.get(player)`; they never load,
release or replace a profile.

Store names are unchanged on purpose (`PlayerData_v1_Studio` in Studio, `PlayerData_v1` live), so
existing saves migrate in place instead of being abandoned.

```
version       3
cash, lifetimeEarned, tilesOwned, sus, namaBaik, rank, timesElected
tiles         ["t1"] = { crop, plantedAt, growSeconds, quality, hot,
                          harvests, fertilised, certified? }     -- regrow fields are M1
produce       ["padi|sultan|oplosan"] = { crop, tier, traits, count, qualitySum }
items         [itemId] = count        -- consumables (amplopPremium) and seeds (seed_padi)
tools         [lineId] = tierId       -- cangkul/gembor/karung/traktor, one tier per line (M2)
shop          { cycle, restockAt, musim, stock = { [cropId] = amount } }  -- M2
worker        { hiredUntil }          -- buruh tani shift end, unix time (M2)
gudang        { capacity, stacks = { [stackKey] = stack } }
debt          { active, principal, owed, takenAt, dueAt }
quests        { daily = {}, loginStreak, lastLoginDay }
almanak       { crops = { [cropId] = { tiers, traits, count } }, pages = { [familyId] = true } }
story         { chapter, flags = {} } -- v2.1
housing       {}                      -- reserved for v2.2, never migrated
prestige      { level = 0 }           -- reserved for v3
cooldowns, cosmetics, equipped, stats, receipts
```

### Produce stacks

`shared/Produce.luau` owns the format. A stack key is `crop | tier | traits`:

```lua
produce["padi|biasa|"]          -- clean common rice
produce["padi|biasa|oplosan"]   -- hot (dirty-fertiliser) rice
produce["durian|langka|basah+organik"]
```

- `traits` are filtered against `Config/Traits`, de-duplicated and **sorted**, so the same stack
  always produces the same key. Never build a key by hand — call `Produce.key`.
- `tier` is one of `Config/Tiers`. Unknown or missing tiers fall back to `Tiers.default`.
- The old `hot` boolean is now the `oplosan` trait. `Produce.isHot(stack)` is the single check used
  by the Pasar, the Tengkulak Gelap and raids.
- `qualitySum` is the sum of per-item minigame quality, exactly like v2's `qualitySum`. Since M1 it
  no longer affects the payout — the price is `count × base × tier` — it only feeds the rarity roll.

### Items

`shared/Inventory.luau` owns the bag. `items[itemId] = count`; seeds are `seed_<crop>`.

```lua
Inventory.get(data, "amplopPremium")
Inventory.takeSeed(data, "padi", 1)
```

Adding a new consumable or currency-like item needs **no migration** — just use the id.

### Migration

`PlayerData.migrate(data)` runs after `ProfileStore:Reconcile()` on every load:

| From | To | What happens |
|---|---|---|
| unknown | 1 | `version = 1` |
| 1 | 2 | splits the old folded quality into clean + hot (`hotQualitySum`) |
| 2 | 3 | `harvest` → `produce` stacks (`biasa`, clean and `oplosan`); `inventory` + `seeds` → `items`; old fields removed; new sections defaulted |

Two details worth remembering:

- **Reconcile runs first.** It copies `TEMPLATE` into an old save, which means a v2 profile has a
  default `items` table (including starting seeds) before migration. `migrateItems` therefore builds
  the bag from the *old* `inventory` + `seeds` only, and ignores the reconciled defaults.
- Migrations must stay idempotent. A v3 save passes through untouched; running `migrate` twice gives
  the same result (`tests/specs/playerdata_spec.luau`).

Adding a field:

1. Add it to `TEMPLATE`.
2. If old saves need data moved, add a `if data.version < N then ... data.version = N end` branch.
3. Bump `CURRENT_VERSION` and add a migration test.

Reserved fields (`housing`, `prestige`) exist so v2.2/v3 do not need a migration just to add them.

M2 added `shop` and `worker` as **v3 section defaults** (`PlayerData.migrate` repairs a missing or
malformed one on load), deliberately without a version bump: nothing had to be moved from an old
field, so an existing v3 save keeps its shelves and shift.

---

## 2. Replicated state

Scalars stay on **player attributes** — cheap, replicated for free, no ordering problems:
`Cash`, `LifetimeEarned`, `TilesOwned`, `HarvestCount`, `Sus`, `NamaBaik`, `Rank`, `Tier`,
`Seed_<crop>`, `Item_<id>`, `Pass_*`, `IsAdmin`, and per-tile `Hot` / `Crop` / `ReadyAt`.
M2 added `ShopStock_<crop>` + `ShopRestockAt`, `Tool_<line>` + `SackCapacity`,
`GudangUsed` + `GudangCapacity`, and `WorkerUntil` + `WorkerActive`. World and market values
that are not per player (`Musim`, `Cuaca`, `Anomali`, `Market_<crop>`) are attributes on
`ReplicatedStorage`.

Everything structured goes through one snapshot + section patches:

| Piece | File | Job |
|---|---|---|
| Shape | `shared/State.luau` | `State.snapshot(data)`, `State.patch(data, names)`, `State.SECTIONS` |
| Server | `server/Net/State.luau` | sends `State_Snapshot` on join, coalesces `State.touch` into `State_Patch` every `Game.statePatchInterval` |
| Client | `client/State.luau` | `State.get(section)`, `State.onChanged(cb)`, `State.ready`, re-requests on demand |

Sections: `produce`, `items`, `shop`, `tools`, `gudang`, `debt`, `quests`, `almanak`, `story`.

Rules:

- A service that mutates a section calls `State.touch(player, "section")` **after** the mutation.
  Do not send remotes from services; `Net/State` owns transport.
- Patch payloads are whole sections (`{ produce = {...} }`), not per-item deltas. Sections are small;
  correctness beats bytes. `State.snapshot` / `State.section` always return copies, never the save table.
- The client store replaces the whole section on a patch and fires listeners for that section
  (`"all"` for a full snapshot).
- Adding a section: add the name to `State.SECTIONS`, add a branch in `State.section`, then send it.
  Clients that do not know a section can ignore it.

Example (client):

```lua
local State = require(script.Parent.State)
local function render()
    local sack = State.get("produce") or {}
    -- build the sack list
end
State.onChanged(function(section)
    if section == "produce" or section == "all" then render() end
end)
```

---

## 3. Tag-driven world

The place file is the source of truth for Workspace. `World/Village.luau` no longer builds layout:
it finds tags and attaches behaviour. `World/Greybox.luau` builds the v1 village and tags it, so the
game runs before the art pass and in tests.

### Contract (`World/Map.luau`)

| Tag | On | Attributes | Meaning |
|---|---|---|---|
| `VillageWorld` | Model/Folder | — | the designer's world root. Presence = real map |
| `PlayerSpawn` | SpawnLocation | — | where players spawn |
| `PasarPrompt` | ProximityPrompt | — | sell clean produce |
| `GelapPrompt` | ProximityPrompt | — | sell anything, black-market premium |
| `PakRTPrompt` | ProximityPrompt | — | bribe |
| `PolisiPrompt` | ProximityPrompt | — | report evidence |
| `WarungPrompt` | ProximityPrompt | — | rumours / VIP |
| `RondaAnchor` | BasePart | — | jail teleport target |
| `PlotAnchor` | BasePart | `PlotIndex` 1..10 | plot origin; `-Z` faces the entrance |
| `NpcSpawn` | Model | `Npc = "pakrt" \| "tengkulak" \| "polisi"` | NPC with speech/walk API |
| `Tile` | BasePart | added by PlotService | client finds tiles by tag (works with streaming) |
| `GreyboxWorld` | Folder | added by Greybox | lets a re-run replace only generated geometry |

Decision rule: if `VillageWorld` **or** `PlotAnchor` exists, the designer map wins and the greybox is
never built. Otherwise greybox builds, tags itself and plot models are generated in a ring.

Prompts get `Bound = true` after `Village.bind`, so calling `bind()` again after a Studio hot reload
never double-connects. `Village.positions` is filled from the tagged prompt's parent, falling back to
the v1 coordinates; services keep calling `Village.getPosition("pasar")` and friends.

Designer workflow:

1. Model the village in Studio. Tag the root `VillageWorld`.
2. Tag one prompt per stall/NPC. Tag one part per plot with `PlotIndex`.
3. Tag NPC models with `NpcSpawn` + attribute `Npc`.
4. Run `Village.bind()` from the bootstrap (already wired) and check Output for missing tags.
5. Committing the `.rbxl` is a designer decision; Rojo syncs scripts only.

---

## 4. LiveConfig

`server/Live/LiveConfig.luau` is the live-tuning document: season override, anomaly, weather
override, price multipliers, feature switches and event modes. It is **global**, not per player.

- Storage: one document, key `current`. Store names `LiveConfig_v1_Studio` / `LiveConfig_v1`.
- Read path: `GetAsync` on start, then every 60 s. `MessagingService` publishes updates so other
  servers apply them immediately instead of waiting for the poll.
- Validation: `LiveConfig.sanitize(raw)` keeps only known fields and sane values. A malformed
  document degrades to defaults; it never errors a live server.
- Merge: `LiveConfig.merge(base, patch)` deep-merges `priceMultipliers`, `features`, `events` and
  replaces scalars. Partial admin writes never wipe the rest of the document.
- Resolution: `LiveConfig.resolve(config, now)` is pure and returns
  `{ musim, anomali, cuaca, seasonSource, priceMultipliers, features, events, updatedAt }`.
  Priority is admin override → calendar fallback. Weather is stable per UTC day until the M2 hook.

Runtime attributes (readable by the client HUD for free): `Musim`, `Anomali`, `Cuaca`,
`LiveConfigVersion` on `ReplicatedStorage`.

Reading it from a service:

```lua
local LiveConfig = require(script.Parent.Parent.Live.LiveConfig)
local runtime = LiveConfig.getRuntime()
if runtime.events.cabai == "off" then ... end

LiveConfig.onChanged(function(config, runtime) ... end)
```

The cabai event already does this: mode `auto` keeps the v1 timer, `on`/`off` let an admin force it.

Defaults ship as if LiveConfig did not exist (v1 behaviour), so a fresh place with no DataStore
access behaves exactly like v1.

---

## 5. Admin panel

- Allowlist: `server/Live/Admins.luau` (`Admins.userIds`), empty by default. Server-side only; the
  client never decides who is an admin.
- `AdminService.start()` sets the `IsAdmin` attribute for allowlisted players and rejects every
  non-allowlisted `Admin_Command`.
- The client panel (`client/UI/Admin.luau`) opens with **F2** only when `IsAdmin` is true. It uses
  the v1 `Theme` deliberately until D1 approves the new kit.
- Actions: `inspect { userId }`, `setSeason`, `setAnomaly`, `setEvent { event = "cabai", mode }`,
  `grantItem { userId, itemId, amount }`, `getConfig`, `refresh`.
- Every action is rate-limited (`Admin_Command`, 4/s), hand-validated and replies on `Admin_Result`
  to the calling admin only.

Putting your Roblox UserId in `Admins.userIds` is the only setup step; see D10 in
[DECISIONS.md](DECISIONS.md).

---

## 6. Content as config

New tables:

| File | Holds |
|---|---|
| `shared/Config/Crops.luau` | 12 crops: cost, grow time, price, rank, colour, `family`, `regrowSeconds`/`maxHarvests`, `permit`; derived `families` and `familyOrder` |
| `shared/Config/Almanak.luau` | one page per family, cosmetic reward, label key |
| `shared/Config/Tiers.luau` | tier order, chance, `valueMultiplier`, colour, label key; `Tiers.rareFrom`, `Tiers.isRare` |
| `shared/Config/Traits.luau` | trait order, `hot` flag, `condition`/`chance`, label key; `Traits.hotTrait`, `Traits.isHot` |
| `shared/Config/Seasons.luau` | seasons, anomalies, weather weights, growth per family, sky palettes, calendar helpers |
| `shared/Config/Shop.luau` | restock window, shelf size, per-season family odds, `always`, amount range |
| `shared/Config/Market.luau` | pressure per item, decay window, price floor/ceiling, tick rate |
| `shared/Config/Tools.luau` | tool lines and tiers: cost, rank, `plantBonus`, `grow`, `sack`, `row` |
| `shared/Config/Worker.luau` | buruh hire fee/duration, wage per item, pass interval and cap |
| `shared/Config/Game.luau` | `gudangBaseCapacity`, `gudangPassCapacity`, `sackBaseCapacity`, `statePatchInterval`, `rarityQualityBoost` |

Conventions: display names live in `shared/Strings.luau` and tables store a `labelKey`; adding a crop,
tier or trait is a data edit plus strings, not a code change. Every new table gets a `config_spec`
sanity check (counts, sums, ordering).

---

## 7. Tests

Run from the repository root:

```bash
lune run tests/run
lune run tests/run -- produce     # filter by name
```

M0, M1 and M2 added:

| Spec | Covers |
|---|---|
| `produce_spec` | key format, trait sorting/filtering, add/count, hot vs clean removal, snapshot isolation |
| `state_spec` | section list, copies (never save references), snapshot/patch shape |
| `seasons_spec` | calendar boundaries, validation, weighted weather rolls |
| `liveconfig_spec` | sanitize, deep merge, resolve priority, stable daily weather |
| `playerdata_spec` | v1 → v2 → v3, produce/items migration, Reconcile hazard, idempotence, section defaults |
| `config_spec` | new: tiers sum to 1 and pay more when rarer; exactly one hot trait; labels exist; 12 crops, family membership, regrow/permit rules, one almanak page per family with a real cosmetic |
| `economy_spec` | v3 stacks: tier multiplier, Pasar refuses hot, black market sells both, seed purchases, `addHarvest` options |
| `receipts_spec` | grants land in `items` (`seed_<crop>`) |
| `rarity_spec` | weight table, quality boost doubles rare tiers, roll boundaries, clamped/invalid quality |
| `traits_spec` | which condition opens which trait, per-trait chance, stacking, sorted output, nil context |
| `almanak_spec` | discovery records, new tier/trait reporting, family progress, page reward granted once |
| `shop_spec` | restock windows, deterministic roll (rejoin cannot refresh), shelf bounds, always-on padi, purchase/refusal paths, HUD attributes |
| `market_spec` | pressure per sale, crop isolation, floor/ceiling clamp, exponential decay, price board |
| `tool_spec` | tier lookup, next-tier chain and maxed, effects, grow-time clamping, purchase rules, publish |
| `storage_spec` | capacity and pass, clean-only deposits, quality-preserving round trip, full/empty toasts |
| `worker_spec` | hire fee and shift, busy refusal, pass cap, per-item wage, unpaid/expired/full-gudang stops |

The harness remains `tests/lib/Env.luau` (real modules, fake Instances, fake time). `Fakes.newData(env)`
now returns a v3 save, so new services can be tested without hand-building one.

Not covered automatically (needs Studio): `CollectionService` tags, `DataStore` / `MessagingService`,
`Instance.new` world building, UI layout, and the admin panel's input handling.

---

## 8. M1 — farming depth

Owner modules: `server/Farm/FarmService.luau` (tile state), `server/Farm/RarityService.luau`
(the roll), `server/Farm/TraitService.luau` (the traits), `server/Progression/AlmanakService.luau`
(discoveries and page rewards).

### Crops and families

`Config/Crops.luau` holds all 12 crops. `Crops.order` is sorted by `growSeconds`; `config_spec`
enforces that, so the seed bar reads fastest-first.

| Family | Crops | Behaviour |
|---|---|---|
| `palawija` | padi, singkong, jagung, bawang, cabai | plant once, harvest once (1–4 min) |
| `kebun` | tembakau, kopi, kakao, cengkeh, durian | first harvest after 8–15 min, then `maxHarvests` re-harvests every `regrowSeconds` |
| `perkebunan` | tebu, sawit | `permit = true` (the Balai Desa check lands in M2), re-harvests, biggest payouts |

A tile entry records `harvests`, `fertilised` and (later) `certified`. On harvest, `FarmService`
increments `harvests`; while `harvests < maxHarvests` it keeps the same crop, resets `plantedAt`
and swaps `growSeconds` for the crop's `regrowSeconds`, so clients see the regrow timer with no
new code. Otherwise the tile is cleared.

### Rarity roll

`RarityService.weight(tierId, quality)` is the only place tier odds are computed:

```
weight = tier.chance * (1 + clamp(quality, 0, 3) * Game.rarityQualityBoost)   -- rare tiers only
```

`Game.rarityQualityBoost = 1` means quality 1 (a perfect plant + harvest) doubles the weight of
`super` and above; quality is clamped, and `nil`/`NaN` count as 0. `RarityService.roll(quality, rng)`
walks `Tiers.order` with a cumulative sum, so the table stays ordered and adding a tier is a data
edit. The rng is injected: game code passes `math.random`, tests pass a fixed value.

Minigame quality no longer multiplies the price; `EconomyService.sellAll` applies
`Tiers.multiplier(stack.tier)` to the crop's base price instead.

### Traits from conditions

`TraitService.roll(context, rng)` returns a sorted list. Each config trait has an optional
`condition` and `chance`:

| Trait | Condition | Chance | Context field |
|---|---|---|---|
| `oplosan` | the tile was force-fed (hot) | always | `hot` |
| `basah` | weather is `hujan` or `badai` | 0.35 | `weather` |
| `kering` | anomaly is `elNino` | 0.35 | `anomaly` |
| `organik` | the plot was never fertilised this cycle | 0.30 | `fertilised` |
| `bersertifikat` | a Balai Desa stamp was applied | always | `certified` |

`FarmService` builds the context from the tile entry plus `LiveConfig.getRuntime()`
(`cuaca`, `anomali`). `TraitService.eligible` lists the conditions that are met before the roll,
which the UI can use to explain a result.

### Almanak

`data.almanak` is a structured state section (see §1) owned by `AlmanakService`:

```lua
data.almanak.crops.padi = { tiers = { biasa = true, sultan = true }, traits = { basah = true }, count = 7 }
data.almanak.pages.palawija = true
```

`record(player, cropId, tier, traits)` counts every harvest and reports what was new
(`first`, `newTier`, `newTraits`). A page completes when every crop in its family has been seen
at least once; `Config/Almanak.luau` maps each page to one existing cosmetic, granted for free
through `Cosmetics.grant` (never charged, never granted twice). `record` touches the `almanak`
section, so the client sees it through the normal state patch.

### Reveal

`FarmService` picks the toast by outcome: a rare tier (`Tiers.isRare`) sends `n_rarity_reveal`
with the crop, tier label and tier id; a new tier/trait sends `n_almanak_new`; otherwise the
plain `n_harvested`. The HUD tints the reveal toast with `Tiers.list[tier].color`.

---

## 9. M2 — the living world

Owners: `server/Season/SeasonService.luau`, `server/Economy/ShopService.luau` (+
`shared/ShopStock.luau`), `server/Economy/MarketService.luau`, `server/Farm/ToolService.luau`,
`server/Farm/StorageService.luau`, `server/Farm/WorkerService.luau`, and the client-only
`client/World/Sky.luau`.

Start order in `Main.server.luau`: LiveConfig → SeasonService → MarketService → EconomyService →
ShopService → ToolService → StorageService → FarmService → WorkerService. Each line only depends
on the ones above it, so a service can always read the owner of the thing it needs.

### Seasons drive growth and sky

`Config/Seasons.luau` holds the numbers; `SeasonService` is a thin mapper from the LiveConfig
runtime to those numbers. Nothing else reads `LiveConfig.getRuntime()` for growth.

```lua
SeasonService.musim()                      -- "hujan" | "kemarau" | "pancaroba"
SeasonService.growSeconds(base, family)    -- season + anomaly, floored at 5 s
SeasonService.growth(family)               -- multiplier only
```

| Musim | palawija | kebun | perkebunan |
|---|---|---|---|
| hujan | 1.25 | 1.10 | 1.05 |
| kemarau | 0.75 | 0.95 | 1.00 |
| pancaroba | 1.00 | 1.00 | 1.00 |

`Anomali` bends that again (`elNino` 0.85, `laNina` 1.10). `FarmService` resolves the real
seconds **at plant time** and stores them on the tile, so a season change never rewrites a crop
already in the ground; the next regrow picks up the new season. `SeasonService` mirrors
`Growth_<family>` onto `ReplicatedStorage` for the UI; `client/World/Sky.luau` tweens Lighting
and Atmosphere towards the `Seasons.sky` preset merged with the weather overlay from `Cuaca`.

### Toko Bibit: rotating, deterministic shelves

`shared/ShopStock.luau` is pure and shared by server and tests:

```lua
ShopStock.cycle(now)                        -- restock window index
ShopStock.restockAt(cycle)                  -- unix time the next window opens
ShopStock.roll(cycle, userId, musim)        -- { [cropId] = amount }
ShopStock.chance(cropId, musim)             -- 0..1; Shop.always makes padi 1
```

The roll is a Lehmer LCG seeded by cycle + UserId + season, so the same player always sees the
same shelves inside a window: **rejoining cannot refresh the shop**. `ShopService` owns
`data.shop` and is the only writer. On load and every 2 s it calls `ensure`, which re-rolls only
when the cycle or the season changed; `publish` mirrors `ShopRestockAt` and `ShopStock_<crop>`
(nil for crops not sold this cycle, which removes the attribute). Buying goes
`ShopService.buy` → rank check → shelf check → `EconomyService.buySeed` (cash + seeds) → shelf
decrement, so the wallet and the shelf can never drift apart. Seasonal odds from
`Shop.chanceBySeason`, per-crop rarity from `Shop.rareChance`, stack size from
`Shop.familyAmount`; `padi` is always stocked.

### Pasar supply and demand

`MarketService` owns one in-memory pressure table per server (a restart is a fresh market, which
suits a ten-minute wave; nothing is saved).

```
multiplier(crop) = clamp(1 - pressure, Market.minMultiplier, Market.maxMultiplier)  -- 0.6 .. 1.25
pressure += count * Market.pressurePerItem                                          -- 0.003/item
pressure *= e^(-dt / Market.decaySeconds)                                           -- 600 s
```

`EconomyService.sellAll` asks for the multiplier on the Pasar channel and calls
`MarketService.recordSale` for each clean stack. The Tengkulak Gelap neither reads nor records
pressure — that is his whole business. `MarketService.tick` decays and mirrors `Market_<crop>`
onto `ReplicatedStorage` every 5 s; the phone's price board reads those attributes.

### Tools

`Config/Tools.luau` is a table of lines and tiers; `data.tools[lineId] = tierId`.

| Line | Tiers | Effect |
|---|---|---|
| `cangkul` | bambu → baja | `plantBonus` +0.05 / +0.12 added to the planting quality before the rarity roll |
| `gembor` | gembor → sprinkler | `grow` 1.10 / 1.25 divides the resolved grow time |
| `karung` | besar → gerobak | `sack` +20 / +60 on top of `Game.sackBaseCapacity` |
| `traktor` | traktor | `row` reserved for row planting; no effect yet |

`ToolService` is the only reader of the table. `FarmService` asks it for `growSeconds`,
`plantBonus` and `sackCapacity` at the moment it needs them, so a purchase applies to the next
plant. A tier id from a future config resolves to no bonus instead of crashing. `ToolService.publish`
mirrors `Tool_<line>` and `SackCapacity`.

### Gudang

`StorageService` owns `data.gudang`. Capacity is stored in the save
(`max(base, saved)`), so the Gudang Besar pass can raise it without a migration while removing
the pass never deletes stored items. `depositAll` moves **clean** produce only — hot stacks stay
in the sack, a raid must never be dodged by parking evidence in a shed — and preserves the
average quality of each stack. `withdrawAll` moves everything back. Both touch `produce` and
`gudang` and mirror `GudangUsed` / `GudangCapacity`.

### Buruh tani

`Config/Worker.luau` (fee, shift length, per-item wage, pass interval/cap) plus
`WorkerService`, which owns `data.worker.hiredUntil`. Each pass asks `FarmService.readyTiles`
and harvests up to `maxItemsPerPass` ready tiles straight into the gudang through
`FarmService.harvestToStorage` — no minigame, but the exact same rarity/trait/Almanak path.
The wage is paid per item after the pass; the buruh goes home when the shift ends, the gudang is
full, or the cash cannot cover the next item. One shift at a time.

---

## 10. Acceptance

| Check | Command | Result |
|---|---|---|
| Unit tests | `lune run tests/run` | 355 passed |
| Static analysis | `luau-lsp analyze --platform roblox --defs .luau/globalTypes.d.luau --sourcemap sourcemap.json --ignore "**/Packages/**" src` | 0 diagnostics |
| Build | `rojo build default.project.json -o JuraganDesa.rbxlx` | builds |
| v1 plays unchanged | Studio playtest: plant → harvest → sell both markets → raid → purchase | manual, see below |
| Schema migration | `playerdata_spec` v1/v2 fixtures | green |
| M1 rarity spread | Studio playtest: harvest 20+ crops, confirm biasa/bagus/super mix and one reveal toast | manual, see below |
| M2 seasons | `seasons_spec` + `MarketService` growth mirror | green |
| M2 shop | `shop_spec`: deterministic roll, rejoin cannot refresh, rank/stock/cash refusals | green |
| M2 market | `market_spec`: pressure, isolation, clamp, decay | green |
| M2 tools | `tool_spec`: chain, effects, publish | green |
| M2 gudang | `storage_spec`: clean-only, quality-preserving, capacity | green |
| M2 buruh | `worker_spec`: hire, wage, pass cap, stop conditions | green |

Manual checks still required in Studio (see [docs/testing](../testing/README.md)):

1. Play the v1 loop; confirm cash, sack count, Pasar vs Gelap, hot-produce refusal and a raid still work.
2. Rejoin with an existing v1/v2 save; confirm cash, rank, tiles and planted crops survive, and the
   sack shows the same totals as before (now as stacks).
3. Publish a private place, add your UserId to `Admins.userIds`, press F2, change the season and force
   the cabai event on/off; confirm the attributes and HUD follow on a second client.
4. Confirm a malformed LiveConfig document (temporarily wrong field types) cannot break a running
   server: it logs one warning and keeps the defaults.
5. M1 loop: plant a palawija, a kebun and a perkebunan crop; confirm the seed bar scrolls, the shop
   lists all 12, a kebun tile regrows after harvest, a rare tier tints the toast, and completing a
   family shows the Almanak page toast with the cosmetic reward.
6. M2 loop: confirm the sky matches the season, the shop shows a restock countdown and the same
   shelves after a rejoin, selling a large stack drops the Pasar price and the phone board shows
   it, a tool purchase changes grow time / sack size, the gudang refuses oplosan produce and
   returns it unchanged, and a hired buruh harvests into the gudang while the wage is paid.

---

## 11. Gaps and next steps

- **D1 (UI direction)** is the only M0 item not code: mockups live in
  [mockups/index.html](mockups/index.html). The v1 Theme stays until they are approved; the M2
  phone tab was built on it deliberately.
- M1 leaves two seams for later milestones: `permit` is still read but not enforced (the Balai
  Desa check moved to v2.1 with the story), and `certified` is rolled but nothing sets it yet
  (planned Balai Desa stamp). The Almanak still has no screen (blocked on D1).
- M2 tuning is a starting point, not a balance pass: shop odds, market pressure/floor, tool
  prices and the buruh wage all sit in `Config/*` for the balance sheet. `traktor` is a
  placeholder row until row planting exists.
- Season risk events from PLAN §3.3 (*banjir*, *hama*, *gagal panen*) are **not** implemented;
  seasons currently change growth, shop odds and sky only.
- `Config/Audio.luau`, real pass/product ids and the `Mbah Dukun` / pinjol names stay open (D4–D9).
- The `VillageWorld` tag contract needs a real map before M3; the greybox remains the fallback.
