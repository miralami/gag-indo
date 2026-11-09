# Juragan Desa: Technical Development Guide

> Companion to [GDD.md](GDD.md). Written for a solo developer who is new to Luau.
> Version 0.1 · 2026-11-09

---

## 1. Ground rules (read these first)

1. **The client lies.** Exploiters can fire any RemoteEvent with any arguments. The client only *asks* ("I want to plant padi on tile 3"). The **server checks and decides** everything: money, Sus, crops, raids and rewards.
2. **One owner per piece of state.** For example, only `SusService` changes Sus, and only `EconomyService` changes cash. Other code calls those services; it never edits the values directly.
3. **Config lives in data, not code.** Crop stats, cheat values, prices and thresholds go in `shared/Config/*`. To rebalance, edit a table.
4. **Every week ends in something playable.** If a feature isn't playable by Friday, cut scope; don't push the deadline.

## 2. Tools & workflow

| Tool | Purpose |
|---|---|
| **Roblox Studio** | Building the map, testing, publishing |
| **Rojo** (installed with Rokit) | Syncs `.luau` files from this folder into Studio, so you (and Claude Code) can write scripts as normal files with git history |
| **ProfileStore** | Player save data with session locking. Get it from its official DevForum thread / GitHub release and put it in `src/server/Packages/`. Check the current docs, because its API can change. |
| StyLua, Selene *(optional)* | Formatting and linting |

Workflow: code in this folder, run `rojo serve`, connect the Rojo plugin in Studio, build the map in Studio, then playtest in Studio.

**Studio-only alternative:** if Rojo setup blocks you on day 1, write scripts directly in Studio and keep the same folder structure. You can switch to Rojo later.

> Turn the repo into git (`git init`) before writing code, so you can always roll back.

## 3. Project structure

```
src/
  server/                      → ServerScriptService
    Main.server.luau           bootstrap: requires and starts services in order
    Packages/ProfileStore.luau
    Data/PlayerData.luau       load/save profiles, template, migrations
    Farm/FarmService.luau      plots, tiles, plant/harvest, growth timers
    Farm/PlotAssigner.luau     gives each joining player a free plot
    Economy/EconomyService.luau cash in/out, selling, shop
    Law/SusService.luau        Sus value, decay, thresholds
    Law/CheatService.luau      applies cheats, logs evidence events
    Law/RaidService.luau       raid state machine, NPC police
    Law/EvidenceService.luau   bukti tokens, Lapor, VIRAL
    Law/BribeService.luau      Pak RT + raid amplop
    Progression/RankService.luau ranks, Nama Baik
    Monetization/Passes.luau   pass ID → benefit registry
    Monetization/Receipts.luau ProcessReceipt (the ONLY place dev products are granted)
    Net/RateLimit.luau         per-player, per-remote limiter
  client/                      → StarterPlayerScripts
    Main.client.luau
    UI/Hud.luau
    UI/Phone.luau              bukti, lapor, inventory
    UI/RaidOverlay.luau
    Minigames/Mencangkul.luau  timing bar
    Minigames/Babat.luau       hold-release
  shared/                      → ReplicatedStorage
    Config/Crops.luau
    Config/Cheats.luau
    Config/Law.luau            Sus thresholds, fines, bribe prices
    Config/Products.luau       pass and product IDs
    Strings.luau               { key = { id = "...", en = "..." } }
    Remotes.luau               creates and returns all RemoteEvents by name
```

> **Current state (week 1):** plot building and assignment live in `Farm/PlotService.luau` (it replaces the planned `PlotAssigner`). Ranks are handled inside `EconomyService` until RankService is needed. Tiles and the Pasar prompt are tagged `Tile` / `PasarPrompt` (CollectionService) so the client works with streaming.

`Main.server.luau` starts the services one by one, in this order: Data → Economy → Farm → Sus → Cheat → Evidence → Raid → Bribe → Rank → Receipts. Modules don't do heavy work or yield when they are required.

## 4. Player data

### 4.1 Template (schema v1)

```luau
local TEMPLATE = {
    version = 1,
    cash = 50,
    lifetimeEarned = 0,
    tilesOwned = 6,
    tiles = {},          -- STRING keys: ["t1"] = { crop = "padi", plantedAt = os.time(), growSeconds = 60, quality = 1.1, hot = false }
                         -- Never use number keys with gaps (tiles 1, 3, 7): sparse arrays don't save reliably.
                         -- Empty tile = key absent. Convert with `"t" .. index`.
    seeds = { padi = 5 },
    harvest = {},        -- [cropId] = { count = 0, qualitySum = 0, hotCount = 0 }
    sus = 0,
    namaBaik = 50,
    rank = "gurem",      -- "gurem" | "petani" | "juragan" | later "kades"
    timesElected = 0,    -- reserved for the Kepala Desa update
    inventory = { amplopPremium = 0, jaminanKilat = 0 },
    cooldowns = {},      -- [name] = unix time when usable again
    cosmetics = {},      -- [itemId] = true
    equipped = {},
    stats = { raids = 0, reportsMade = 0, timesReported = 0, cheats = 0 },
    receipts = {},       -- array of recent PurchaseIds (keep the last 50) for idempotency
}
```

Rules:

- Store name: `PlayerData_v1`. In Studio use `ProfileStore.Mock` (or a `_Studio` suffix) so test saves never touch live data.
- Profile key: `player_<UserId>`. Keeping the user ID inside the key lets Roblox's data-deletion (right to be forgotten) requests find the record.
- On load: `StartSessionAsync` → `AddUserId` → `Reconcile` (fills in fields added after a record was saved) → run migrations if `version` < current.
- Kick the player with a friendly message if their profile can't load. **Never** let them play on an unsaved blank profile.
- Only save plain numbers, strings and tables. Never save Instances. Before writing, check numbers for NaN and inf.

### 4.2 Offline growth

A crop is ready when `os.time() >= plantedAt + growSeconds`. Cheats change `growSeconds` at the moment they are applied. Growth needs no loops on the server. The client shows a countdown, and the server rechecks readiness when the player harvests.

## 5. Remotes (the whole API)

> **Current state (week 1):** planting, harvesting, tile buying and selling go through server-side `ProximityPrompt.Triggered` (no remote). The only remotes are `Farm_SelectSeed(cropId)`, `Shop_BuySeed(cropId, amount)` and `Notify`. `Farm_Begin`/`Farm_Complete`/`Farm_Auto` arrive with the minigames in week 2. The source of truth is `src/shared/Remotes.luau`.

All remotes are `RemoteEvent`s. Every handler must:

1. Pass the per-player rate limiter.
2. Check argument **types** and **ranges** (`typeof`, integer, bounds).
3. Check **ownership**: it's the player's own plot or token.
4. Check **distance** when the action is at a place (player within N studs of the NPC or tile).
5. Check **affordability** and **cooldowns** against server data.
6. Apply the change only through the owning service.

### Client → server

| Remote | Args | Server checks | Rate |
|---|---|---|---|
| `Farm_Begin` | `tile:int, action:"plant"\|"harvest", cropId:string?` | Own tile; tile empty (plant) or ready (harvest); has the seed; within 15 studs. Stores `pending = {tile, action, crop, t0 = os.clock()}` | 4/s |
| `Farm_Complete` | `score:number` | A pending action exists; elapsed time is between 1.5 s and 30 s; `score` is clamped to 0–1, then `quality = 0.8 + 0.5*score` | 4/s |
| `Farm_Auto` | `tile:int, action, cropId?` | Same checks as `Farm_Begin`; quality 0.9 | 4/s |
| `Cheat_Apply` | `cheatId:string, tile:int?, targetPlayer:Player?` | Valid cheat; can afford; own tile; `curi_air` target is a neighbor without an active steal | 1/s |
| `Market_Sell` | `cropId:string\|"all", channel:"pasar"\|"gelap"` | Near the correct NPC; has the harvest | 2/s |
| `Shop_Buy` | `itemId:string` | Item exists; can afford; rank requirement met | 2/s |
| `Bribe_RT` | — | Near Pak RT; cooldown elapsed; can afford the escalating price | 1/s |
| `Raid_Choose` | `choice:"denda"\|"amplop"` | Player has an active raid; amplop is not allowed when VIRAL | 1/s |
| `Evidence_Record` | `eventId:string` | The player was offered this event; it's not already recorded | 2/s |
| `Evidence_Report` | `tokenId:string` | Token is the player's own and not expired; player is near the Pos Polisi | 1/s |
| `Item_Use` | `item:"amplopPremium"\|"jaminanKilat"` | Has the item; guardrails from GDD §9.2 | 1/s |

### Server → client

| Remote | Payload |
|---|---|
| `Notify` | `key:string, params:{}?`, a string key the client looks up in the localized string table |
| `Evidence_Offer` | `eventId, cheaterName, cheatId, expiresAt` |
| `Raid_Start` / `Raid_End` | `isViral:boolean` / `outcome` |
| `Minigame_Start` | `action, tile`, sent after `Farm_Begin` succeeds |

**Replicated values** (simpler than a sync system): the server sets player attributes `Cash`, `Sus`, `NamaBaik`, `Rank` and `InRaid`, and the HUD listens with `GetAttributeChangedSignal`. Tile state lives in the tiles' attributes on the plot model in Workspace.

### Why minigame scores are safe enough

An exploiter can always send `score = 1`. The worst case is quality 1.3 instead of about 1.1, which is a small, capped advantage. The minimum time check stops them from spamming plant and harvest instantly. **Don't** build anything more complex.

## 6. Systems notes

### SusService
- `add(player, amount, reason)` / `reduce(...)` clamp Sus to 0–100 and update the attribute.
- One loop every 20 s for everyone: decay by 1 point, and for players at Sus 80 or more, roll the 10% raid chance. When Sus reaches 100, it calls `RaidService.start(player, false)` right away.

### RaidService (state machine per player)
`idle → incoming (NPCs walk, overlay) → choosing (20 s timeout = denda) → resolving → cooldown (3 min) → idle`.
- Confiscates `hot` crops from tiles and harvest when a raid starts.
- If the player leaves mid-raid, it auto-resolves as **denda** (the fine). That stops logging out to dodge a raid.
- **Order matters:** the fine must be applied *before* PlayerData ends the profile session. PlayerData's `PlayerRemoving` handler calls `RaidService.resolveOnLeave(player)` first, then `profile:EndSession()`. Don't give RaidService its own `PlayerRemoving` connection, because the two handlers would race.
- NPC police are server-owned models. Move them with `Humanoid:MoveTo`, or teleport them if pathfinding fails. Keep it simple.

### EvidenceService
- `logCheat(cheater, cheatId, value, position)` creates `eventId` (GUID) and offers it to players within 40 studs (the victim always gets it).
- Tokens are stored in a server memory table, not saved, and expire after 180 s.
- Report → if this is the **first** report of the event, move `min(0.5 * cheatValue, cheater.cash)` from the cheater to the reporter through `EconomyService.transfer` (never mint new money). Add 25 Sus to the cheater, then check VIRAL: 2 distinct reporters within 300 s starts `RaidService.start(cheater, true)`.
- Per-reporter cooldown of 60 s; Nama Baik from reports is capped at +10 per day (track in `cooldowns`).
- If the cheater has already left, the report counts for nothing in v1 (no reward, no offline Sus). The token simply expires.

### BribeService
- Pak RT price = `100 * 1.5^(recentBribes)`, where `recentBribes` counts bribes in the last 10 minutes and is stored in `cooldowns`.
- Raid amplop: `math.random() < 0.75` on the **server**.

## 7. Monetization implementation

### Passes
- `Config/Products.luau` maps each pass ID to a benefit key. `Passes.luau` checks `UserOwnsGamePassAsync` (wrapped in `pcall`) on join and on `PromptGamePassPurchaseFinished`, then sets `player:SetAttribute("Pass_Ordal", true)` and so on. Benefits read only these attributes on the server.

### Developer products: `Receipts.luau` is the only grant path
```luau
MarketplaceService.ProcessReceipt = function(info)
    local player = Players:GetPlayerByUserId(info.PlayerId)
    if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
    local profile = PlayerData.get(player)
    if not profile then return Enum.ProductPurchaseDecision.NotProcessedYet end

    if table.find(profile.Data.receipts, info.PurchaseId) then
        return Enum.ProductPurchaseDecision.PurchaseGranted -- already granted earlier
    end
    local grant = PRODUCT_GRANTS[info.ProductId]
    if not grant then
        warn("Unknown product", info.ProductId)
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    -- Grant AND record the PurchaseId in the same step (no yield in between),
    -- so a retry after a crash sees the ID and doesn't grant twice.
    grant(profile.Data)                             -- e.g. inventory.amplopPremium += 1
    table.insert(profile.Data.receipts, info.PurchaseId)
    if #profile.Data.receipts > 50 then table.remove(profile.Data.receipts, 1) end

    -- Acknowledge ONLY after a save containing this PurchaseId succeeded.
    if not PlayerData.saveAndConfirm(profile, info.PurchaseId, 15) then
        return Enum.ProductPurchaseDecision.NotProcessedYet -- Roblox redelivers later; the ID check above prevents a double grant
    end
    return Enum.ProductPurchaseDecision.PurchaseGranted
end
```

`PlayerData.saveAndConfirm(profile, purchaseId, timeoutSeconds)` asks ProfileStore to save now, waits (bounded by the timeout) for that save to finish, and returns `true` only if the session is still active and the last saved data contains `purchaseId`. Build it from ProfileStore's current save API and signals (at the time of writing: `profile:Save()`, `profile.OnAfterSave`, `profile.LastSavedData`, `profile:IsActive()`), and **check the ProfileStore docs' developer-product example before writing it**. Never return `PurchaseGranted` when the session ended or the save didn't confirm.
- Purchases only add **items**. Using an item (`Item_Use`) is a separate, guarded action. That way an "ineligible right now" situation never wastes Robux.
- The client calls `PromptProductPurchase`. `PromptProductPurchaseFinished` is **not** proof of payment; only the receipt is.
- Test: buy twice quickly, leave mid-purchase, rejoin, and confirm exactly one item each time. Use Studio test purchases.

## 8. UI & mobile

- Use `ProximityPrompt` on tiles and NPCs. It works with touch, keyboard and gamepad without extra code.
- Tap targets should be at least 44 px. Test in Studio's **Device Emulator** with a small phone, a tablet and a 1080p screen.
- Use `UIScale` / `UIAspectRatioConstraint` and anchor points, not fixed pixel positions.
- Strings: always call `Strings.get(key)`, and pick the language from `LocalizationService` (`id` if the locale starts with "id", else `en`). This lets you move to a Roblox LocalizationTable later without rewriting UI code.

## 9. Art pipeline (biggest schedule risk)

- **Environment:** Creator Store models (rice fields, warung, houses, trees) + your own simple parts. Check licenses and remove scripts inside free models (they can be malicious).
- **Caricature NPCs:** a standard R15 rig with `HeadScale` around 1.4, adjusted `BodyWidthScale`/`BodyHeightScale`, expressive face decals, and Marketplace animations for idle, angry and dramatic gestures. No custom meshes in v1.
- **Performance budget:** 30 fps or better on a mid-range phone. Avoid thousands of loose parts; use meshes where possible. Streaming enabled.

## 10. Six-week plan

> Honest note: 4–6 weeks is **tight** for a first Roblox game. Plan for 6 and accept that 8 is normal. The cut line below is how you ship anyway.

| Week | Build | Playtest proof (must work by end of week) |
|---|---|---|
| 1 | git + Rojo, greybox map, plot assignment, PlayerData (ProfileStore), plant/harvest/sell with Auto quality, cash | Plant padi, leave, rejoin after 60 s, harvest, sell, and the cash is saved |
| 2 | Mencangkul minigame, 4 crops, tile purchase, rank Gurem → Petani, HUD, Strings | Play 10 min on the phone emulator; numbers feel OK |
| 3 | SusService, Pupuk Oplosan + Tengkulak Gelap, Pak RT bribe, RaidService (denda/amplop/jail) | Cheat → Sus rises → get raided → pay or bribe → jail works |
| 4 | EvidenceService + Lapor + VIRAL, Curi Air, Nama Baik, Juragan rank | 2-player Studio test (Test → Server with 2–3 clients): A cheats, B records and reports, A gets a VIRAL raid |
| 5 | Art pass (NPCs, village, raid overlay, sounds), Passes + Receipts + Item_Use, Babat minigame | Test purchases grant once; raid scene is funny |
| 6 | Balance, EN strings, maturity questionnaire, friends playtest, bug fixes, publish (private → public) | 3+ friends play 20 min without help |

**Cut line, in order, if behind at the end of week 3:**
1. Babat minigame (harvest = hold button)
2. Curi Air cheat
3. Raid NPC walk-in (overlay only)
4. VIP Warung pass and cosmetics shop (keep 1 pass + Amplop Premium)

**Never cut:** saving, server validation, Sus → raid, Lapor. Those are the game.

## 11. Pre-publish checklist

- [ ] Data: rejoin keeps everything; 2 servers can't load the same profile at once (session lock); `BindToClose` saves on shutdown
- [ ] Studio uses Mock or `_Studio` data, never the live store
- [ ] Every remote has type, range, ownership and distance checks and a rate limit
- [ ] Spam test: fire each remote 100× per second from the command bar, and nothing breaks or duplicates
- [ ] Receipts: duplicate, player-leaves and unknown-product cases tested
- [ ] Leaving mid-raid resolves as a fine
- [ ] Phone emulator: all UI readable and tappable
- [ ] No real names, parties, Polri insignia or real logos in assets or text
- [ ] Maturity questionnaire completed; free models cleaned of scripts
- [ ] Analytics events: `cheat_used`, `raid_started`, `report_made`, `rank_up`, `purchase` (for the GDD §12 metrics)

## 12. Working with Claude Code in this repo

Good prompts to use as you go:
- "Set up Rojo and the folder structure from docs/TECH.md §3"
- "Implement PlayerData.luau with the template in §4.1 using ProfileStore"
- "Add the Farm_Begin/Farm_Complete remotes with all checks from §5"
- "Review my remotes against TECH.md §5 for exploits"

Keep these docs up to date when design changes, so every future session starts from the same plan.
