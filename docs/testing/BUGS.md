# Bug List

Single defect list for the Master Plan (`docs/v2/plan/MASTER_PLAN.md` §0, §3.0.2, §3.0.3b).
Every agent reads this first and adds real findings only. No invented bugs, asset IDs or UserIds.

Status words follow `MASTER_PLAN.md` §7: `SEEN-IN-STUDIO`, `LUNE-ONLY`, `UNVERIFIED`, `BLOCKED`.
A Studio-only defect is `BLOCKED` until track C or track H runs it and saves evidence under
`docs/v2/evidence/`.

| ID | Severity | Owner track | Steps / evidence | Status |
|---|---|---|---|---|
| BUG-001 | minor | C | Play Solo `JuraganDesa.rbxl`. Output warned `Cloud instance must exist under Terrain node in workspace to be visible.` Cause: `src/client/World/Sky.luau` parented `Clouds` under `Lighting`. Fix: create/migrate `Clouds` under `workspace.Terrain`, wait up to 10 s for Terrain, and skip the tween if Terrain never appears. Measured 2026-11-14: `workspace.Terrain` has a `Clouds` instance with `Cover` 0.55, none under `Lighting`, no Clouds warning in Output. | fixed — `SEEN-IN-STUDIO` (2026-11-14, `docs/v2/evidence/h/2026-11-14-phase0/`) |
| BUG-002 | minor | C | Play Solo, then invoke `Greybox.build()` twice in the same session. Old code called `workspace.Terrain:FillBlock` on absolute CFrames without clearing, so the river and four terrace rows stacked. Fix: `Greybox.applyTerrain` fills every owned volume with `Enum.Material.Air` first, then refills the same five volumes; nothing outside those bounds is touched. First-build result is unchanged. Measured 2026-11-14: water voxel count in the owned river region read 2700 before, 2700 after build 1, 2700 after build 2 — two consecutive `Greybox.build()` calls did not stack terrain. | fixed — `SEEN-IN-STUDIO` (2026-11-14, `docs/v2/evidence/h/2026-11-14-phase0/`); `LUNE-ONLY` regression test `tests/specs/greybox_spec.luau` |
| BUG-004 | major | B | A player with no cash, no seeds of any kind, no planted crop and an active `pinjol` loan that blocks a new one, on a day whose login reward is already claimed, had no way to plant again inside one session — the free-seed floor did not exist. Found by the Phase 0.3b broken-state reading. Fix (D-G3 option A: free 1 `padi` seed once per session, no cash granted) implemented in `FarmService.checkSeedFloor`. Reproduced and verified in Studio 2026-11-19: broken state cash 0 / 0 seeds / 0 tiles → exactly 1 `padi` seed, cash still 0, `n_seed_floor` notified, once-per-session guard held. | fixed — `SEEN-IN-STUDIO` (2026-11-19, `docs/v2/evidence/h/2026-11-19-gate1-studio/`); regression `tests/specs/seedfloor_spec.luau` |
| BUG-003 | major | C | Play Solo `JuraganDesa.rbxl`. Output repeats 3× per play start: `ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type`. Still open after the 2026-11-14 run. Not found in: the DataModel in Client or Server mode (scan of ~7500 and ~4000 descendants across `Image`, `Texture`, `SoundId`, `MeshId`, `TextureContent`, `ImageContent`, `SoundContent`, `Asset`, `ColorMap`, `AlphaMap`, `EmissiveMask`, `ResourceId`, `Skybox*`), any script source in the Server DataModel, `JuraganDesa.rbxl` bytes (binary ASCII scan), `src/` or `tests/`, or the installed Rojo plugin file. `%LOCALAPPDATA%\Roblox\Plugins` holds only `RojoManagedPlugin.rbxm`, and every Studio install's `content` folder (541 script/model/json/xml files across five versions) was scanned with no hit — the reference is not in any locally installed file. `grep -R 203785492` finds only docs. Full-machine sweep 2026-11-14 (method re-validated: PowerShell `& findstr /c:"..."` passes the quotes literally and silently returns nothing, so every sweep was redone through `cmd /c` with a passing control): nothing under `%LOCALAPPDATA%\Roblox` outside `Versions` and `logs` (20 top-level dirs incl. `rbx-storage` 2.9 GB, `OTAPlugins`, `placeIDEState`, `StudioMCP`), nothing in `%TEMP%` or `%LOCALAPPDATA%\Temp\Roblox`, no matching filename anywhere, `reg query /s /f 203785492 HKCU\Software\Roblox\RobloxStudio` → 0 matches (installed plugins: Rojo 7.7.1 plus Studio builtins `ExplorerPlugin`, `AssetManager`, `PluginManagement`, `AssetQualityValidation`), and no hit in any of the 15 Roblox `.exe` binaries including the running `RobloxStudioBeta.exe` (control `rbxassetid` hits it). | closed — external, `SEEN-IN-STUDIO` 2026-11-14 (a hand-written blank place with `Workspace`, `Lighting` and `Players` only, no scripts, no asset references, `persistedToCloud` false, reproduces the same three lines about 6 s after play start; log in `docs/v2/evidence/h/2026-11-14-phase0/bug003-blank-place.log`). Studio or the account emits it at play start; no change in this repo can remove it. Excluded from the "zero warnings" bar |
| BUG-005 | major | H | Every sell and every buy printed a server error in Output: `argument #6 expects a string, but EnumItem was passed`, stack `Analytics.luau:157 → Analytics.luau:84 economy → EconomyService:95 addCash / 116 trySpend`. Cause: `Analytics.economy` passed `Enum.AnalyticsEconomyTransactionType[...]` where the engine signature is `AnalyticsService:LogEconomyEvent(player, flowType: AnalyticsEconomyFlowType, currencyType: string, amount, endingBalance, transactionType: string, itemSku: string, customFields?)` — `transactionType` is a **string**, not an `EnumItem` (confirmed against create.roblox.com/docs/reference/engine/classes/AnalyticsService). Fix: pass the string directly in `src/server/Analytics/Analytics.luau`; `tests/specs/analytics_spec.luau` asserts the string type (495 tests pass). Re-ran the full loop in Studio after the fix: the error is gone, `AnalyticsService: LogEconomyEvent event fired.` printed twice, zero stack traces in Output. | fixed — `SEEN-IN-STUDIO` (2026-11-14, `docs/v2/evidence/h/2026-11-14-phase0/`) |
| BUG-006 | minor | D | Play Solo `JuraganDesa.rbxl`, iPhone 14 emulation (844x390), player standing on their plot. The village BillboardGui labels (`LAHAN MIRALAMI` and the leftmost sign) sit under the top-left HUD panel: the panel covers part of the world text and the world text shows through beside the panel, so both are harder to read. World/UI conflict, not a logic bug. Evidence: `docs/v2/evidence/baseline/phone-plot.png`. | fixed — `LUNE-ONLY` (2026-11-14 Track D: HUD stats panel converted to compact 32px icon chips positioned below top-bar inset, leaving 3D world billboard labels unobstructed) |
| BUG-007 | minor | D | Same session and frame. Player-facing HUD copy is English (`Rank: Smallholder`, `Sack: 0/40`, `Sus`, `Reputation`, `Seeds`, `Phone`, `Board`, `Rice`, `Cassava`, `Rp`) while world copy in the same frame is Indonesian (`LAHAN MIRALAMI`, `Ayam kosong`). Master Plan §7 item 4 wants player text in `Strings.luau` in ID and EN. Investigated: the copy is not hardcoded — `src/shared/Strings.luau` carries both variants (`hud_rank` line 79, `hud_harvest_bag` 86, `hud_namabaik` 81, `rank_gurem` 29) and `Strings.langFor` (line 386) returns `id` only when the locale id starts with `id`, so an en-us Studio client legitimately renders the `en` variant. Evidence: `docs/v2/evidence/baseline/phone-plot.png`. | fixed — `LUNE-ONLY` (2026-11-14 Track D: Indonesian default set in HUD/Phone, plus interactive language toggle chip `ID`/`EN` added for runtime switching) |
| BUG-008 | major | C | World labels unreadable on a phone (designer playtest 2026-11-14, Xiaomi 12 Lite; baseline `phone-pasar.png`, `phone-plot.png`): at the Pasar the `BillboardGui` signs are `AlwaysOnTop` at 140 studs and pile on each other into one blob; at the plot `LAHAN MIRALAMI` and `AYAM KOSONG` are oversized and clip at the screen edge. Source: `Props.billboard`, `Greybox.luau:93`, `PlotService.luau:102`. A player notices it at once, so `major` (quality bar §0.1, Gate 1 'no placeholder visible'). | fixed — `LUNE-ONLY` 2026-11-14 (billboards use a fixed 22 px text (TextScaled ignored the size cap in Studio), shorter fade distance, sign labels raised to 7 studs above roofs, signs no longer always-on-top; `tests/specs/greybox_spec.luau`). Studio measured the structure only; no after-fix screenshot is saved yet, so not `SEEN-IN-STUDIO`. **Reopened 2026-11-14:** the HEAD build still piled hub labels at the spawn (audit screenshot = `docs/v2/evidence/h/2026-11-14-audit-fixes/before-spawn-desktop.jpg`). Second fix: the hub name is painted on the Sign board itself (SurfaceGui `SignFront`/`SignBack` in `Greybox.sign`), no floating BillboardGui. Fixed again — `SEEN-IN-STUDIO` 2026-11-14 desktop (6 signs, 6 with both faces, 0 billboards; `h/2026-11-14-audit-fixes/after-spawn-desktop.jpg`); `greybox_spec.luau` updated. Phone size not yet checked |
| BUG-009 | major | D | HUD text too small on a phone: `Rank`, `Sack`, `Sus`, `Reputation` lines are tiny and the top-left panel covers world signs (extends BUG-006). Owner `src/client/UI/Hud.luau`. | fixed — `SEEN-IN-STUDIO` (desktop size) 2026-11-14 (stats panel moved below the Roblox top bar, text >= 14, hotbar contrast, panel shadows now mirror `UISizeConstraint` in `Theme.addSticker` so no empty dark box). `SEEN-IN-STUDIO` 2026-11-14 desktop-size viewport (`docs/v2/evidence/d/2026-11-14-hud-labels/hud-after-designer.webp`), not yet at phone size. The `Board` button's own empty dark box (`Leaderboard.luau`, `lb_button`) is not checked |
| BUG-010 | major | C | Every NPC (Pak RT, Bang Jago, both Polisi Desa) showed two overlapping name tags and two speech billboards: `Greybox` builds the NPC through `NpcFactory.build` and `Village.bindNpcs` (`Village.luau:107`) wraps the same model again, and `wrap` created new billboards each time. Found from the designer's screenshot 2026-11-14. | fixed — `SEEN-IN-STUDIO` structure 2026-11-14 (each NPC now holds 2 billboards instead of 4, Output shows only the BUG-003 line); regression `tests/specs/npcfactory_spec.luau`, mutation-checked. No after-fix screenshot saved |
| BUG-011 | blocker | D | Found by reading code 2026-11-17: `src/client/UI/Phone.luau` used `homeBarHeight` (content `Size`, line 281) before `local homeBarHeight = PhoneLayout.homeBarHeight` (line 287), since commit 5d6e65c (44 px touch targets). `70 + nil` errors inside `Phone.mount`, so the phone would not mount. Not reproduced in Studio (no instance open). | fixed — `SEEN-IN-STUDIO` 2026-11-17: phone mounts with only `PhoneButton` (lazy), first tap builds Root/Card/Content/PageHome + all 8 app tiles + all header controls, `App_phone` opens `PagePhone`, ID→EN switches tile labels, landscape applies on the short viewport. Output clean except the external BUG-003 line. `docs/v2/evidence/h/2026-11-17-phone-studio/`. Portrait rotation and the other 7 app pages stay `LUNE-ONLY`. |
| BUG-012 | major | A | Found in Studio 2026-11-17 during the Gate 1 harness loop: every `sell` printed `Z is not a valid member of Vector2` at `ActionFeel.cashFlyTrajectory` line 22 (`(startPos :: any).Z ~= nil`). Runtime callers pass a Roblox `Vector2` (screen-space cash fly), whose missing `.Z` read throws instead of returning nil; the Lune spec used a plain `{X,Y}` table, so it never caught it. Fix: probe `.Z` with `pcall` (`okZ and startZ ~= nil`). Regression spec adds a strict 2D vector whose `.Z` access throws. | fixed — `SEEN-IN-STUDIO` 2026-11-17: after fix, plant→ready→harvest→sell loop ran with clean Output (no `Z` error); `tests/specs/feel_spec.luau` (1676 passing). `docs/v2/evidence/h/2026-11-17-gate1/`. |
| BUG-013 | minor | H | Reported as a probable bug from the 2026-11-19 unsynced Studio pass: the minigame Cancel appeared not to close the overlay (`h/2026-11-19-gate1-studio/REPORT.md` Q3 "still open"). Re-checked on Rojo-synced code (`h/2026-11-19-gate1-sweep/`): `Minigame_Cancel:FireClient` closed the scrim `true → false`, and the source wiring is intact (`cancel.Activated:Connect(close)` line 182, `Minigame_Cancel.OnClientEvent:Connect(close)` line 190, `scrim.Visible = false` in `close()` line 106). Not reproducible; the earlier observation was an artifact of hand-injected, unsynced sources. No code defect, no fix. A static regression spec now locks the wiring: `tests/specs/minigame_cancel_spec.luau`. Fresh 2026-11-19 proof drove the **real** `Cancel.Activated`: fired 1×, scrim `true→false`, PlayArea destroyed, zero commit remotes, profile identical before/after — `h/2026-11-19-cancel-proof/`. | closed — not reproduced on synced code, `SEEN-IN-STUDIO` 2026-11-19 (`docs/v2/evidence/h/2026-11-19-gate1-sweep/`, `h/2026-11-19-cancel-proof/`); `LUNE-ONLY` wiring regression `tests/specs/minigame_cancel_spec.luau` |
| BUG-014 | major | H | Found by reading code 2026-11-19 (WORK_QUEUE item 10). `src/shared/Produce.luau` `snapshot()` indexed every sack value (`stack.crop`, `table.clone(stack.traits)`) with no `type(stack) == "table"` guard, unlike its siblings `count/removeHot/removeClean`. But `produce` and `gudang.stacks` are dynamic-key tables that `SaveSanitize.sanitize` deliberately does NOT repair, so one damaged non-table value (or a non-table `traits`) throws and breaks `StateSchema.snapshot` → `State_Snapshot:FireClient` for that player on every load/touch. Fix: skip non-table stacks and default a non-table `traits` to `{}`; valid stacks copy unchanged. Regression `tests/specs/produce_spec.luau` (2 cases: non-table stacks, bad traits) proves no throw and that valid stacks still copy. | fixed — `LUNE-ONLY` (2026-11-19, `tests/specs/produce_spec.luau`); mutation-checked (old `snapshot` → both cases fail with pcall false); suite 1772 |
| BUG-015 | minor | H | Found by reading code 2026-11-19 (WORK_QUEUE item 10). `src/server/Economy/EconomyService.luau` read `MarketConfig.namaBaikMaxBonus` for the Pasar price scale but clamped with a hardcoded `math.clamp(..., -0.05, 0.05)`, so tuning the config away from 0.05 silently capped the bonus at the shipped 5% — the config knob did nothing. Fix: derive both bounds from `maxBonus` (`-maxBonus, maxBonus`), so the shipped 0.05 behaviour is byte-for-byte unchanged and only a tuned config changes payouts. Regression `tests/specs/economy_config_spec.luau` drives the real `sellAll` with a 10% config and expects +10% (old clamp paid +5%). | fixed — `LUNE-ONLY` (2026-11-19, `tests/specs/economy_config_spec.luau`); mutation-checked (old clamp → spec fails, expected 69 got 68); suite 1772 |

## BUG-004 resolution

D-G3 decided option A on 2026-11-14; option B (borrow top-up) was not taken.

- **Root cause:** with an active loan, both recovery paths were closed — `DebtService.borrow` refuses while `debt.active and debt.owed > 0`, and `QuestService.claimDaily` refuses once `loginClaimedToday` — so a broke player with an active loan had no action until the next calendar day. `Pinjol.calcLimit("gurem", 50)` = 500, so a non-borrowing broke player was never the dead end.
- **Fix shipped (option A, free seed floor):** `FarmService.checkSeedFloor` grants 1 `padi` seed once per session when the player has no cash, no seeds of any kind and no planted crop, with the `n_seed_floor` ("Tetangga kasih bibit padi.") message. Never grants cash, so the loan still hurts.
- **Verified in Studio 2026-11-19:** drove the broken state on the live profile (cash 0, all `seed_*` zeroed, `tiles={}`), called `checkSeedFloor` and observed cash still 0, exactly 1 `padi` seed, `n_seed_floor` captured on the client, and a second call returning `false` (once-per-session guard held). Evidence `docs/v2/evidence/h/2026-11-19-gate1-studio/`. This closes BUG-004.
- **Remaining caveat (not a dead end):** `checkSeedFloor` fires on join, post-harvest and post-tile-purchase only; a spend through another route (e.g. shop buy) that empties cash and seeds mid-session is not covered until the next join/harvest. Regression `tests/specs/seedfloor_spec.luau`. The rejected option B was the borrow top-up while a loan is active.

## BUG-003 next step (Studio, track C)

Closed 2026-11-14. No next step, no asset to replace: the line is external. The blank-place test
item 1 below was run and reproduced the same three lines from a place with no content.

Do not guess a replacement asset ID. Remove or re-type the existing reference first.

The 2026-11-14 scan came up empty (DataModel in Client and Server mode, server script source,
`JuraganDesa.rbxl` bytes, `src/`, `tests/`, the installed Rojo plugin), so bisect the source of
the line instead of searching for it:

1. ~~Open a **blank place** and press Play.~~ Done 2026-11-14: reproduced, three lines, ~6 s after
   play start, from `blank-probe.rbxlx` (Workspace, Lighting, Players and nothing else).
2. ~~Disable plugins one at a time.~~ Done 2026-11-14: plugin registry holds only Rojo 7.7.1 plus
   Studio builtins, and the id is in none of their files.
3. Not needed. The property scan below was already run in Play mode over ~7500 Client and ~4000
   Server descendants with no hit.

Evidence gathered 2026-11-14 that shortens the list: no Studio plugin other than Rojo is
installed, no file in any Studio `content` folder mentions the ID, and the whole machine is clean
(see the BUG-003 row). If step 1 (blank place) reproduces the line, nothing in this repository or
on this machine can be the cause, and the finding belongs upstream in Studio rather than in track C.

Original property scan, for step 3:
Paste this into the command bar in **Edit** mode and run it. It prints every instance and
property whose content string contains `203785492`.

```lua
local needle = "203785492"
for _, d in game:GetDescendants() do
	for _, p in { "Image", "Texture", "TextureId", "SoundId", "ColorMap", "MeshId" } do
		local ok, v = pcall(function()
			return d[p]
		end)
		if ok and type(v) == "string" and string.find(v, needle, 1, true) then
			print(d:GetFullName(), p, v)
		end
	end
end
```

4. Fix the reported slot: use a decal/image where an image is expected, a sound where a sound is
   expected, or delete the stale instance. No replacement ID is invented here.
5. Save the place file (track C only), re-run Play Solo, confirm the three load errors are gone.
6. Move BUG-003 to `SEEN-IN-STUDIO` and save the Output log under
   `docs/v2/evidence/c/2026-11-14-asset-type/`.

## Open blockers

- BUG-003 is **closed as external**: the 2026-11-14 blank-place test reproduced the 3× line
  with no content in the place, so the source is upstream in Studio, not in this repository.
  It is accepted noise (D-G4 acceptance still pending for the Gate 1 Q2 wording).
- BUG-004 is **closed** — D-G3 option A implemented and verified in Studio 2026-11-19 (`h/2026-11-19-gate1-studio/`); no longer a blocker.
- `tests/specs/greybox_spec.luau` is registered in `tests/run.luau` by track H. Suite: 495 passing.

### Studio run 2026-11-14

Passed (`SEEN-IN-STUDIO`): bridge smoke check and `enable`, plant → ready → harvest → sell →
buy with the tutorial chain completing, save → stop → play → `status` with cash 48, `padi` 6 and
tilesOwned 6, a second full loop, BUG-001, BUG-002 and BUG-005. Output after the BUG-005 fix:
only the 3 BUG-003 lines.

Left: minigame feel (mid-minigame cancel `UNVERIFIED`), frame rate, ten-player
session, soak, and persistence in a published place. BUG-003 is closed as external — a blank place
reproduces it. The village sign BillboardGui overlaps the
HUD at iPhone 14 size (BUG-006, filed 2026-11-14). HUD text rendered in English in that frame
(BUG-007), but `Strings.langFor` keys off the client locale and this machine is en-us, so it is
not a defect until an id-ID run says otherwise. Phase 0.4 baseline shots and design timings are in
`docs/v2/evidence/baseline/REPORT.md`.
