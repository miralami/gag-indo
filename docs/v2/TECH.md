# Juragan Desa — v2 Technical Foundation (M0)

> What M0 changed, and the rules the rest of v2 builds on. Read this together with
> [v1/TECH.md](../v1/TECH.md): the ground rules there still hold — the server decides
> everything, one owner per piece of state, config lives in tables, every remote is validated
> and rate-limited. This file only documents what v2 added.

Status: **M0 complete except the designer decision on UI (D1 in [DECISIONS.md](DECISIONS.md)) and
the in-Studio checks in §8.** The v1 game runs unchanged on the new foundation: same gameplay,
same balance, same save files (migrated in place).

---

## 1. Save schema v3

Owner: `server/Data/PlayerData.luau`. Other modules call `PlayerData.get(player)`; they never load,
release or replace a profile.

Store names are unchanged on purpose (`PlayerData_v1_Studio` in Studio, `PlayerData_v1` live), so
existing saves migrate in place instead of being abandoned.

```
version       3
cash, lifetimeEarned, tilesOwned, sus, namaBaik, rank, timesElected
tiles         ["t1"] = { crop, plantedAt, growSeconds, quality, hot }   -- tile `hot` flag stays in v2
produce       ["padi|sultan|oplosan"] = { crop, tier, traits, count, qualitySum }
items         [itemId] = count        -- consumables (amplopPremium) and seeds (seed_padi)
tools         [toolId] = level or true
gudang        { capacity, stacks = { [stackKey] = stack } }
debt          { active, principal, owed, takenAt, dueAt }
quests        { daily = {}, loginStreak, lastLoginDay }
almanak       [cropId] = { ... }      -- filled by AlmanacService in M1
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
- `qualitySum` is the sum of per-item minigame quality, exactly like v2's `qualitySum`.

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

---

## 2. Replicated state

Scalars stay on **player attributes** — cheap, replicated for free, no ordering problems:
`Cash`, `LifetimeEarned`, `TilesOwned`, `HarvestCount`, `Sus`, `NamaBaik`, `Rank`, `Tier`,
`Seed_<crop>`, `Item_<id>`, `Pass_*`, `IsAdmin`, and per-tile `Hot` / `Crop` / `ReadyAt`.

Everything structured goes through one snapshot + section patches:

| Piece | File | Job |
|---|---|---|
| Shape | `shared/State.luau` | `State.snapshot(data)`, `State.patch(data, names)`, `State.SECTIONS` |
| Server | `server/Net/State.luau` | sends `State_Snapshot` on join, coalesces `State.touch` into `State_Patch` every `Game.statePatchInterval` |
| Client | `client/State.luau` | `State.get(section)`, `State.onChanged(cb)`, `State.ready`, re-requests on demand |

Sections: `produce`, `items`, `tools`, `gudang`, `debt`, `quests`, `almanak`, `story`.

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
| `shared/Config/Tiers.luau` | tier order, chance, `valueMultiplier`, colour, label key |
| `shared/Config/Traits.luau` | trait order, `hot` flag, label key; `Traits.hotTrait` |
| `shared/Config/Seasons.luau` | seasons, anomalies, weather weights, growth multipliers, calendar helpers |
| `shared/Config/Game.luau` | `gudangBaseCapacity`, `gudangPassCapacity`, `statePatchInterval` |

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

M0 added:

| Spec | Covers |
|---|---|
| `produce_spec` | key format, trait sorting/filtering, add/count, hot vs clean removal, snapshot isolation |
| `state_spec` | section list, copies (never save references), snapshot/patch shape |
| `seasons_spec` | calendar boundaries, validation, weighted weather rolls |
| `liveconfig_spec` | sanitize, deep merge, resolve priority, stable daily weather |
| `playerdata_spec` | v1 → v2 → v3, produce/items migration, Reconcile hazard, idempotence, section defaults |
| `config_spec` | new: tiers sum to 1 and pay more when rarer; exactly one hot trait; labels exist |
| `economy_spec` | v3 stacks: tier multiplier, Pasar refuses hot, black market sells both, seed purchases |
| `receipts_spec` | grants land in `items` (`seed_<crop>`) |

The harness remains `tests/lib/Env.luau` (real modules, fake Instances, fake time). `Fakes.newData(env)`
now returns a v3 save, so new services can be tested without hand-building one.

Not covered automatically (needs Studio): `CollectionService` tags, `DataStore` / `MessagingService`,
`Instance.new` world building, UI layout, and the admin panel's input handling.

---

## 8. M0 acceptance

| Check | Command | Result |
|---|---|---|
| Unit tests | `lune run tests/run` | 219 passed |
| Static analysis | `luau-lsp analyze --platform roblox --defs .luau/globalTypes.d.luau --sourcemap sourcemap.json --ignore "**/Packages/**" src` | 0 diagnostics |
| Build | `rojo build default.project.json -o JuraganDesa.rbxl` | builds |
| v1 plays unchanged | Studio playtest: plant → harvest → sell both markets → raid → purchase | manual, see below |
| Schema migration | `playerdata_spec` v1/v2 fixtures | green |

Manual checks still required in Studio (see [docs/testing](../testing/README.md)):

1. Play the v1 loop; confirm cash, sack count, Pasar vs Gelap, hot-produce refusal and a raid still work.
2. Rejoin with an existing v1/v2 save; confirm cash, rank, tiles and planted crops survive, and the
   sack shows the same totals as before (now as stacks).
3. Publish a private place, add your UserId to `Admins.userIds`, press F2, change the season and force
   the cabai event on/off; confirm the attributes and HUD follow on a second client.
4. Confirm a malformed LiveConfig document (temporarily wrong field types) cannot break a running
   server: it logs one warning and keeps the defaults.

---

## 9. Gaps and next steps

- **D1 (UI direction)** is the only M0 item not code: mockups live in
  [mockups/index.html](mockups/index.html). The v1 Theme stays until they are approved.
- Rarity rolls, traits from weather and the almanak are M1. M0 ships the vocabulary and the sale
  multiplier seam only.
- Seasons/weather are read but not yet applied to growth, shop or lighting (M2). The admin override
  and attributes are already live.
- `Config/Audio.luau`, real pass/product ids and the `Mbah Dukun` / pinjol names stay open (D4–D9).
- The `VillageWorld` tag contract needs a real map before M3; the greybox remains the fallback.
