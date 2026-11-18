# NPC pathing robustness — Track H, 2026-11-19

WORK_QUEUE item 18: police and debt-collector walk-to-plot for every plot, with stuck detection, a
timeout and a teleport fallback. Shared walker implemented in `src/server/World/NpcWalk.luau`;
`NpcFactory:walkTo` and `DebtCollector.summon` both delegate to it. Specs are `LUNE-ONLY`; the live
plot walks and fallback are `SEEN-IN-STUDIO` (this file + `results.json`).

## What changed

- **New `src/server/World/NpcWalk.luau`** — dependency-free (only `Vector3`/`CFrame`/`task`), so
  neither `NpcFactory` (Map/Props) nor `DebtCollector` (PlotService/Props) needs the other. For a host
  with `GetPivot()`/`PivotTo()` it:
  - interpolates toward the goal in 0.05 s steps (orientation via `CFrame.lookAt`, a small bob),
  - detects a stall (`< 0.05` studs of progress for 12 consecutive steps ≈ 0.6 s),
  - bounds total travel at `2 × (distance / speed)` with a 3 s floor,
  - on stall **or** timeout pivots straight onto the goal (teleport fallback), so the mover always
    arrives; on cancellation (`walkToken` changed) or an unparented host it returns `false` **without**
    teleporting. Returns `false` for a host without a pivot API (fake parts degrade quietly).
- **`src/server/World/NpcFactory.luau`** — `Npc:walkTo` now delegates to `NpcWalk.walkTo(
  self.model, target, speed, isCancelled)`. Police (`RaidService.policeGoTo` / `policeReturn`) and
  the item-9 walk-in candidate inherit the guarantees with no change to their call sites. Public API
  (yields, default speed 14, `walkToken` cancellation) unchanged.
- **`src/server/Economy/DebtCollector.luau`** — `summon` still spawns the marker at the plot offset;
  it now walks that part to `plot.spawnCFrame.Position` via `NpcWalk.walkTo(part, target, 8)` in a
  `task.spawn`, so the collector visibly arrives for every plot. Idempotence and hook events unchanged.

## LUNE-ONLY proof — `tests/specs/npc_pathing_robustness_spec.luau` (9 cases)

Drives the real `NpcWalk` with an injectable host and a minimal `CFrame` shim: normal exact arrival,
stuck → teleport, timeout (slow crawl that keeps moving but never arrives) → teleport, cancellation
without teleport, unparent-mid-walk without teleport, four distinct plot positions, no-op on a host
with no pivot API, and a native-`vector` analogue (see below). A source check locks that both public
callers call `NpcWalk.walkTo`. Registered in `tests/run.luau`.

**Regression mutation-checked.** The Lune harness supplies `Vector3` as a plain table, which hid a
real defect during the first Studio run: `positionOf` originally required `type(p) == "table"`, but a
Studio `Vector3` is a native `vector` (`type()` returns `"vector"`), so every live walk bailed at the
first guard. Fixed by reading `X`/`Y`/`Z` inside `pcall` (works for table, userdata and vector). The
native-vector case overrides `type()` in a fresh module env to report `"vector"`; reverting the fix
to the old type-name guard makes exactly that case fail (1 FAILED, 8 passed), and restoring it makes
all 9 pass. No pre-existing shipped bug: the defect existed only in this item's new module and was
caught before commit.

## Studio proof — `SEEN-IN-STUDIO`

Rojo-synced code (`ServerScriptService.Server.World.NpcWalk`), Play Solo, **Server** datamodel, fresh
`VERIFY-TEMP` profile, place never saved/published and no `profile:Save()`:

- Required `NpcWalk` in the live Server VM: `walkTo` is a function.
- Walked a real anchored `Part` from an 8-stud offset to **each of the ten plots**
  (`Workspace.World.Plot_1` … `Plot_10`) with real Roblox `Vector3`/`CFrame`/`PivotTo`: **10/10
  arrived, final XZ distance 0.00 for every plot**. All probe parts destroyed afterwards.
- Drove the stuck fallback against a live host whose `PivotTo` never moves it: `walkTo` returned
  `true` and the last commanded pivot was exactly the goal (`X = 60`), proving the teleport fallback
  fires with real engine types.
- Console over the pass: no game-code errors (only the known external BUG-003 asset line and two
  Assistant-plugin version warnings). Returned to Edit mode; place not saved.

`results.json` holds the raw per-plot distances and fallback readings.

### Studio limitation (honest scope)

The two public gameplay callers could not be driven live in this session: `Village.police` was empty
(no designer `NpcSpawn` tags are bound in this place) and the single Play-Solo player had no plot
assigned, so `DebtCollector.summon` had nothing to walk to. Their wiring through the shared walker is
locked by the source-check spec, and the walker itself was proven end to end at every plot with real
engine types. No plot assignment or profile data was mutated to force a caller-level run.

## Proof

- `lune run tests/run.luau`: **1854 passing** (was 1845; +9 new cases).
- `selene src`: 0 errors / 0 warnings / 0 parse errors.
- Files: new `src/server/World/NpcWalk.luau`, edited `src/server/World/NpcFactory.luau` and
  `src/server/Economy/DebtCollector.luau`, new spec + registration in `tests/run.luau`.
