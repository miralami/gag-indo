# Testing

Juragan Desa is tested in three layers. Each catches a different kind of problem, so none replaces another.

| Layer | What it checks | How it runs | When |
|---|---|---|---|
| **1. Automated tests** | Game rules and numbers: money, Sus, ranks, raids' maths, Robux receipts, save migrations, config sanity | `lune run tests/run` (no Roblox Studio needed, runs in about a second) | Before every commit, and on every push (CI) |
| **2. Static checks** | Type errors and typos | `luau-lsp analyze` (see [SETUP.md](../SETUP.md)) | Before every commit |
| **3. Manual test cases** | Feel, visuals, UI, multiplayer, anything that needs Studio | [MANUAL_TESTS.md](MANUAL_TESTS.md) + a signed run sheet | Before each version you publish |

## 1. Automated tests

### Run them

```bash
lune run tests/run
```

Run only the tests whose name contains a word:

```bash
lune run tests/run -- economy
```

Exit code is `0` when everything passes and `1` otherwise, which is what CI uses.

### What they test, and what they do not

The tests load the **real** modules from `src/` into a fake Roblox environment (`tests/lib/Env.luau`), then replace
their neighbours (save data, notifications, rate limiter, world) with small fakes. So `EconomyService` is real, while
`PlayerData` is a fake that holds a plain table.

They cover rules a script can judge. They **cannot** judge anything that needs the real engine: physics, animation,
UI layout, sound, Roblox's DataStore, or what multiplayer feels like. That is what the manual cases are for.

| Spec | Covers |
|---|---|
| `config_spec` | Balance sanity: prices, thresholds, probabilities, rank requirements, product grants; tier chances sum to 1 and pay more when rarer; exactly one hot trait; every tier/trait has a label; 12 crops, family membership, regrow/permit rules, one almanak page per family |
| `ratelimit_spec` | Token-bucket limiter used by every remote |
| `sus_spec` | Sus clamping, the letter warning, raid at 100 |
| `rank_spec` | Rank promotion, Nama Baik, daily caps |
| `produce_spec` | Produce stack keys (`crop\|tier\|traits`): trait sorting/filtering, add/count, hot vs clean removal, snapshot isolation |
| `state_spec` | Replicated state: section list, snapshot/patch shape, copies never returning the save table |
| `seasons_spec` | Season calendar boundaries, anomaly/weather validation, weighted weather rolls |
| `liveconfig_spec` | LiveConfig: `sanitize` validation, deep `merge`, `resolve` override → calendar priority, stable daily weather |
| `economy_spec` | Cash, spending, transfers, sack, Pasar, Tengkulak Gelap, Ordal, cabai event; v3 stacks, tier multipliers and count-based payouts |
| `rarity_spec` | Rarity roll: tier weights, the quality boost doubling rare tiers, roll boundaries, clamped/invalid quality |
| `traits_spec` | Condition-driven traits: weather/anomaly/fertiliser/certified conditions, per-trait chance, stacking, sorted output |
| `almanak_spec` | Discovery book: per-crop tier/trait record, new-discovery reporting, family progress, page reward granted once |
| `receipts_spec` | Robux purchases: exactly-once grants, retry safety, grants landing in `items` (`seed_<crop>`) |
| `playerdata_spec` | Old-save migration v1 → v2 → v3: produce/items, Reconcile hazard, idempotence, section defaults |
| `shop_spec` | Rotating shop: restock windows, deterministic roll (rejoin cannot refresh), shelf bounds, always-on padi, purchase/refusal paths, HUD attributes |
| `market_spec` | Pasar supply and demand: pressure per sale, crop isolation, floor/ceiling clamp, exponential decay, price board |
| `tool_spec` | Tools: tier lookup, next-tier chain and maxed line, effects, grow-time clamp, purchase rules, attribute publish |
| `storage_spec` | Gudang: capacity and Gudang Besar pass, clean-only deposits, quality-preserving round trip, full/empty toasts |
| `worker_spec` | Buruh tani: hire fee and shift, busy refusal, pass cap, per-item wage, unpaid/expired/full-gudang stops |

### Write a new test

1. Create `tests/specs/<name>_spec.luau`:

   ```luau
   return function(t, Env, Fakes)
       local expect = t.expect
       local env, Thing

       t:describe("Thing", function()
           t:beforeEach(function()
               env = Env.new() -- a fresh fake world for every test
               env:mock("server/Net/Notify", Fakes.notify()) -- replace neighbours with fakes
               Thing = env:require("server/Some/Thing") -- load the real module
           end)

           t:it("does the expected thing", function()
               expect(Thing.double(2)):toBe(4)
           end)
       end)
   end
   ```

2. Add `require("./specs/<name>_spec")` to the list in `tests/run.luau`.
3. Run `lune run tests/run -- thing`.

Helpers you will use most:

| Helper | Does |
|---|---|
| `Env.new()` | New fake game. `env:require("server/...")` loads a real module, `env:mock(path, fake)` replaces one. Do the mocks **before** the first `require`. |
| `env:advance(seconds)` | Moves the fake clock (`os.clock`, `os.time`) and runs due `task.defer` / `task.delay` calls |
| `env:flush()` | Runs `task.defer` calls without moving time |
| `Fakes.player(env, {position = ...})` | A fake player with attributes and a character |
| `Fakes.newData(env)` | Fresh **v3** save data (same defaults as a new player) |
| `Fakes.playerData()`, `Fakes.notify()`, `Fakes.analytics()`, `Fakes.remotes(env)`, `Fakes.rateLimit()` | Ready-made stand-ins for the common neighbours |
| `expect(x):toBe / toEqual / toBeNear / toBeGreaterThan / toBeLessThan / toBeAtLeast / toBeAtMost / toBeNil / toBeTruthy / toBeFalsy / toContain / toThrow` | Assertions. Use `expect(x).never:toBe(y)` to negate. |

### Rules of thumb

- **Every bug you fix gets a test first.** Write the failing test, then fix it. Name it after the bug, as the Pasar sack test does.
- Test **rules and numbers**, not implementation details. If a refactor with the same behaviour breaks a test, the test was too tight.
- If a service is hard to test because it needs something we have not faked, add the fake to `tests/lib` (unknown services fail loudly on purpose) rather than skipping the test.
- If a function is private but important (like `PlayerData.migrate`), export it with a comment saying the tests use it.

## 2. Static checks

See "Checking code" in the [README](../../README.md). Run `luau-lsp analyze` before committing.

## 3. Manual test cases

A real tester works from **written cases with a pass/fail result per version**, not from memory. That is what these files do:

- [MANUAL_TESTS.md](MANUAL_TESTS.md): the catalogue. Every case has an ID, a priority (P0 smoke, P1 core, P2 polish), setup, steps and the expected result.
- [runs/TEMPLATE.md](runs/TEMPLATE.md): the run sheet. Copy it to `runs/<date>-<commit>.md`, tick off each case for that exact version, and sign it off.

### Release routine

1. `lune run tests/run` is green.
2. `git rev-parse --short HEAD` to get the version, copy the run sheet to `docs/testing/runs/<date>-<commit>.md`.
3. Play in Studio. Do every **P0** case, plus every **P1** case in areas you changed. Do **P2** before a public update.
4. Record every result. Write findings. Fix or consciously accept every failure.
5. Sign off, then commit the run sheet. The file is your proof that *this version* was checked.

### Keeping the catalogue alive

- New feature: add its cases to `MANUAL_TESTS.md` in the same commit.
- A bug found by hand: add a case, and an automated test too if the rule can be tested by script.
- A case that is now fully covered by an automated test keeps its entry but says **Auto** with the spec name. Only the parts a script cannot see stay manual.
