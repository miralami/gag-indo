# Performance pass — Track H, 2026-11-19

Build: `track/c-world-look` after `f31e38f`, Rojo serving `localhost:34872`. Studio instance
`447c176b-1d7b-4b9c-a794-45912fea4b63`, cloud dev place `Development-Juragan-Desa` (placeId
`132087524375529`, universeId `10776530981`). Machine-readable readings in `results.json`.

**Play Solo only. The place was never saved or published. `profile:Save()` was never called. Play was
stopped and Studio returned to Edit.**

## 1. Instance counts per hub

Measured in the Play Solo Server VM on the startup-built world. The two fixes are client-only
(`Wind`, `CameraFeel`) and build no instances, so before and after are byte-identical:

| Hub | Model | Parts | Descendants | Prompts |
|---|---|---:|---:|---:|
| Pasar | `Pasar` | 38 | 46 | 1 |
| Tengkulak Gelap | `TengkulakGelap` | 17 | 25 | 1 |
| Warung | `Warung` | 21 | 29 | 1 |
| Pos Ronda | `PosRonda` | 27 | 34 | 0 |
| Pos Polisi | `PosPolisi` | 18 | 26 | 1 |
| Rumah Pak RT | `RumahPakRT` | 51 | 59 | 1 |
| **Total workspace** | | **1706** | **3289** | |

No instance-count regression (`SEEN-IN-STUDIO`).

## 2. Connection leaks found and fixed

Audited every `Heartbeat` / `RenderStepped` / signal connection under `src/`.

- **`src/client/World/Wind.luau`** — `start()` connected `GetInstanceRemovedSignal("WindShake")` and
  `RunService.Heartbeat` but stored neither and exposed no Disconnect. **Fixed:** both connections
  are stored; `Wind.stop()` disconnects them, restores every swayed part's original CFrame, clears
  the weak-cache and resets the cursor/accumulator; `Wind.isStarted()` added. Idempotent start and
  clean restart are spec-locked.
- **`src/client/Feel/CameraFeel.luau`** — `start()` connected `CharacterAdded`, `CharacterRemoving`
  and `Heartbeat` into a `connections` table with no teardown. **Fixed:** `CameraFeel.stop()`
  disconnects all three, cancels the active tween, unbinds the humanoid and resets `started`;
  `CameraFeel.isStarted()` added. Safe to call before start or twice.

Already had teardown (no change needed): `FidelityRuntime`, `FpsSampler`, `RaidOverlay`,
`Mencangkul`, `PerfSwitches`, `Babat`.

## 3. Per-frame allocation found and fixed

`Wind`'s hot path is the 20 Hz Heartbeat. Its `tierSettings()` built a **fresh `pcall` closure and
re-resolved `require(FidelityRuntime)` on every tick** — about 20 closures and 20 module resolutions
per second for the life of the client. **Fixed:** `FidelityRuntime` is resolved exactly once in
`start()` and cached; `tierSettings()` calls the stored `settings` function reference under `pcall`
(no new closure). `settings()` is still read every tick, so a tier change made after start still
lands on the next tick — behaviour is unchanged.

Before/after: closures per tick **1 → 0**; module resolutions per tick **1 → 0**; total resolutions
per client start **1** (was ~20/s).

## 4. Proof

- **`tests/specs/perf_hotpath_spec.luau` (7 cases, `LUNE-ONLY`):** resolution is once per start and
  still once after 50 heartbeat fires while `settings()` is called 50 times; `start()` idempotent;
  `stop()` disconnects every owned signal, restores swayed parts and allows a clean restart; safe
  before start. CameraFeel start/stop teardown the same way.
- **Studio (client VM):** both updated modules load (`Wind`/`CameraFeel` require OK, `stop` present);
  11 PlayerGui children mounted (client bootstrapped); console identical before and after with
  **zero new Output errors**. `execute_luau` requires in its own module cache, so the resolver counter
  reads 0 in the probe even though the game is running — the per-tick behaviour is proven by the
  Lune spec, not asserted from the probe.

Full suite `lune run tests/run.luau`: **1732 passing** (was 1725). `selene src`: **0 errors, 3
pre-existing warnings in untouched files** (`Admin.luau`, `MapSpec.luau`, `Greybox.luau`), 0 parse
errors. The 4th warning recorded in earlier items is no longer reported.
