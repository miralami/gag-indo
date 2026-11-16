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
| BUG-004 | major | B | A player with no cash, no seeds of any kind, no planted crop and an active `pinjol` loan that blocks a new one, on a day whose login reward is already claimed, has no way to plant again inside one session — the free-seed floor does not exist. Found by the Phase 0.3b broken-state reading, not yet reproduced in Studio. Two candidate fixes are written under "BUG-004 next step" below; the choice is decision D-G3. | open — `BLOCKED` on D-G3 |
| BUG-003 | major | C | Play Solo `JuraganDesa.rbxl`. Output repeats 3× per play start: `ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type`. Still open after the 2026-11-14 run. Not found in: the DataModel in Client or Server mode (scan of ~7500 and ~4000 descendants across `Image`, `Texture`, `SoundId`, `MeshId`, `TextureContent`, `ImageContent`, `SoundContent`, `Asset`, `ColorMap`, `AlphaMap`, `EmissiveMask`, `ResourceId`, `Skybox*`), any script source in the Server DataModel, `JuraganDesa.rbxl` bytes (binary ASCII scan), `src/` or `tests/`, or the installed Rojo plugin file. `%LOCALAPPDATA%\Roblox\Plugins` holds only `RojoManagedPlugin.rbxm`, and every Studio install's `content` folder (541 script/model/json/xml files across five versions) was scanned with no hit — the reference is not in any locally installed file. `grep -R 203785492` finds only docs. Full-machine sweep 2026-11-14 (method re-validated: PowerShell `& findstr /c:"..."` passes the quotes literally and silently returns nothing, so every sweep was redone through `cmd /c` with a passing control): nothing under `%LOCALAPPDATA%\Roblox` outside `Versions` and `logs` (20 top-level dirs incl. `rbx-storage` 2.9 GB, `OTAPlugins`, `placeIDEState`, `StudioMCP`), nothing in `%TEMP%` or `%LOCALAPPDATA%\Temp\Roblox`, no matching filename anywhere, `reg query /s /f 203785492 HKCU\Software\Roblox\RobloxStudio` → 0 matches (installed plugins: Rojo 7.7.1 plus Studio builtins `ExplorerPlugin`, `AssetManager`, `PluginManagement`, `AssetQualityValidation`), and no hit in any of the 15 Roblox `.exe` binaries including the running `RobloxStudioBeta.exe` (control `rbxassetid` hits it). | closed — external, `SEEN-IN-STUDIO` 2026-11-14 (a hand-written blank place with `Workspace`, `Lighting` and `Players` only, no scripts, no asset references, `persistedToCloud` false, reproduces the same three lines about 6 s after play start; log in `docs/v2/evidence/h/2026-11-14-phase0/bug003-blank-place.log`). Studio or the account emits it at play start; no change in this repo can remove it. Excluded from the "zero warnings" bar || BUG-004 | major | B | **Broke player with an active loan cannot recover inside the session.** Quality bar §0.4 says no cash + no seeds + no crops must always be recoverable. The only recovery paths found in code are (a) `DebtService.borrow` (`src/server/Economy/DebtService.luau:99-122`) which refuses while `debt.active and debt.owed > 0`, and (b) `QuestService.claimDaily` (`src/server/Progression/QuestService.luau:102-129`), which refuses once `loginClaimedToday`. With an active loan, zero cash, zero `padi` seeds, no growing and no ready crop, both are closed, so the player has no action until the next calendar day. `Pinjol.calcLimit("gurem", 50)` = 500 (`src/shared/Config/Pinjol.luau:33-38`), so a non-borrowing broke player is fine — only the active-loan case is a dead end. | fixed — `LUNE-ONLY` 2026-11-14 (D-G3 option A: `FarmService.checkSeedFloor`, 1 `padi` seed once per session when cash <= 0, no seeds, no planted tile; hooked on join, after harvest and after a tile purchase; `tests/specs/seedfloor_spec.luau`, 510 tests). Studio only confirmed the new code is synced and join is clean (Output: BUG-003 line only); the broke state itself was not reproduced in Studio. Not hooked: other cash spends (tools, workers, debt), so a player who spends their last cash there is not rescued until the next harvest, tile purchase or rejoin |
| BUG-005 | major | H | Every sell and every buy printed a server error in Output: `argument #6 expects a string, but EnumItem was passed`, stack `Analytics.luau:157 → Analytics.luau:84 economy → EconomyService:95 addCash / 116 trySpend`. Cause: `Analytics.economy` passed `Enum.AnalyticsEconomyTransactionType[...]` where the engine signature is `AnalyticsService:LogEconomyEvent(player, flowType: AnalyticsEconomyFlowType, currencyType: string, amount, endingBalance, transactionType: string, itemSku: string, customFields?)` — `transactionType` is a **string**, not an `EnumItem` (confirmed against create.roblox.com/docs/reference/engine/classes/AnalyticsService). Fix: pass the string directly in `src/server/Analytics/Analytics.luau`; `tests/specs/analytics_spec.luau` asserts the string type (495 tests pass). Re-ran the full loop in Studio after the fix: the error is gone, `AnalyticsService: LogEconomyEvent event fired.` printed twice, zero stack traces in Output. | fixed — `SEEN-IN-STUDIO` (2026-11-14, `docs/v2/evidence/h/2026-11-14-phase0/`) |
| BUG-006 | minor | D | Play Solo `JuraganDesa.rbxl`, iPhone 14 emulation (844x390), player standing on their plot. The village BillboardGui labels (`LAHAN MIRALAMI` and the leftmost sign) sit under the top-left HUD panel: the panel covers part of the world text and the world text shows through beside the panel, so both are harder to read. World/UI conflict, not a logic bug. Evidence: `docs/v2/evidence/baseline/phone-plot.png`. | fixed — `LUNE-ONLY` (2026-11-14 Track D: HUD stats panel converted to compact 32px icon chips positioned below top-bar inset, leaving 3D world billboard labels unobstructed) |
| BUG-007 | minor | D | Same session and frame. Player-facing HUD copy is English (`Rank: Smallholder`, `Sack: 0/40`, `Sus`, `Reputation`, `Seeds`, `Phone`, `Board`, `Rice`, `Cassava`, `Rp`) while world copy in the same frame is Indonesian (`LAHAN MIRALAMI`, `Ayam kosong`). Master Plan §7 item 4 wants player text in `Strings.luau` in ID and EN. Investigated: the copy is not hardcoded — `src/shared/Strings.luau` carries both variants (`hud_rank` line 79, `hud_harvest_bag` 86, `hud_namabaik` 81, `rank_gurem` 29) and `Strings.langFor` (line 386) returns `id` only when the locale id starts with `id`, so an en-us Studio client legitimately renders the `en` variant. Evidence: `docs/v2/evidence/baseline/phone-plot.png`. | fixed — `LUNE-ONLY` (2026-11-14 Track D: Indonesian default set in HUD/Phone, plus interactive language toggle chip `ID`/`EN` added for runtime switching) |
| BUG-008 | major | C | World labels unreadable on a phone (designer playtest 2026-11-14, Xiaomi 12 Lite; baseline `phone-pasar.png`, `phone-plot.png`): at the Pasar the `BillboardGui` signs are `AlwaysOnTop` at 140 studs and pile on each other into one blob; at the plot `LAHAN MIRALAMI` and `AYAM KOSONG` are oversized and clip at the screen edge. Source: `Props.billboard`, `Greybox.luau:93`, `PlotService.luau:102`. A player notices it at once, so `major` (quality bar §0.1, Gate 1 'no placeholder visible'). | fixed — `LUNE-ONLY` 2026-11-14 (billboards use a fixed 22 px text (TextScaled ignored the size cap in Studio), shorter fade distance, sign labels raised to 7 studs above roofs, signs no longer always-on-top; `tests/specs/greybox_spec.luau`). Studio measured the structure only; no after-fix screenshot is saved yet, so not `SEEN-IN-STUDIO`. **Reopened 2026-11-14:** the HEAD build still piled hub labels at the spawn (audit screenshot = `docs/v2/evidence/h/2026-11-14-audit-fixes/before-spawn-desktop.jpg`). Second fix: the hub name is painted on the Sign board itself (SurfaceGui `SignFront`/`SignBack` in `Greybox.sign`), no floating BillboardGui. Fixed again — `SEEN-IN-STUDIO` 2026-11-14 desktop (6 signs, 6 with both faces, 0 billboards; `h/2026-11-14-audit-fixes/after-spawn-desktop.jpg`); `greybox_spec.luau` updated. Phone size not yet checked |
| BUG-009 | major | D | HUD text too small on a phone: `Rank`, `Sack`, `Sus`, `Reputation` lines are tiny and the top-left panel covers world signs (extends BUG-006). Owner `src/client/UI/Hud.luau`. | fixed — `SEEN-IN-STUDIO` (desktop size) 2026-11-14 (stats panel moved below the Roblox top bar, text >= 14, hotbar contrast, panel shadows now mirror `UISizeConstraint` in `Theme.addSticker` so no empty dark box). `SEEN-IN-STUDIO` 2026-11-14 desktop-size viewport (`docs/v2/evidence/d/2026-11-14-hud-labels/hud-after-designer.webp`), not yet at phone size. The `Board` button's own empty dark box (`Leaderboard.luau`, `lb_button`) is not checked |
| BUG-010 | major | C | Every NPC (Pak RT, Bang Jago, both Polisi Desa) showed two overlapping name tags and two speech billboards: `Greybox` builds the NPC through `NpcFactory.build` and `Village.bindNpcs` (`Village.luau:107`) wraps the same model again, and `wrap` created new billboards each time. Found from the designer's screenshot 2026-11-14. | fixed — `SEEN-IN-STUDIO` structure 2026-11-14 (each NPC now holds 2 billboards instead of 4, Output shows only the BUG-003 line); regression `tests/specs/npcfactory_spec.luau`, mutation-checked. No after-fix screenshot saved |
| BUG-011 | blocker | D | Found by reading code 2026-11-17: `src/client/UI/Phone.luau` used `homeBarHeight` (content `Size`, line 281) before `local homeBarHeight = PhoneLayout.homeBarHeight` (line 287), since commit 5d6e65c (44 px touch targets). `70 + nil` errors inside `Phone.mount`, so the phone would not mount. Not reproduced in Studio (no instance open). | fixed — `LUNE-ONLY` 2026-11-17, declaration moved above `content`; needs a Studio check that the phone mounts with the right content height. |

## BUG-004 next step

Two candidate fixes; pick one before coding (D-G3). Both are server-side and small.
1. **Free seed floor (recommended, most satirical):** in `FarmService` or `PlayerData.onLoad`, when the player has no cash, no seeds of any kind, and no planted crop, grant 1 `padi` seed once per session with a "tetangga kasih bibit" message. Never grants cash, so the loan still hurts.
2. **Borrow top-up while a loan is active:** allow a second loan only when the player is completely idle (same conditions), capped so `owed` cannot exceed `Pinjol.maxDebtMultiplier`. Deepens the debt trap but makes the trap harder to escape and needs a fresh balance test.

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

- BUG-003 stays open and `BLOCKED` on Studio: the 2026-11-14 run reproduced it (3× per play
  start) and ruled out the DataModel, the place bytes and the plugins' code, but did not find
  the source.
- BUG-004 is `BLOCKED` on decision D-G3.
- `tests/specs/greybox_spec.luau` is registered in `tests/run.luau` by track H. Suite: 495 passing.

### Studio run 2026-11-14

Passed (`SEEN-IN-STUDIO`): bridge smoke check and `enable`, plant → ready → harvest → sell →
buy with the tutorial chain completing, save → stop → play → `status` with cash 48, `padi` 6 and
tilesOwned 6, a second full loop, BUG-001, BUG-002 and BUG-005. Output after the BUG-005 fix:
only the 3 BUG-003 lines.

Left: BUG-004 (needs D-G3), minigame feel, frame rate, ten-player
session, soak, and persistence in a published place. BUG-003 is closed as external — a blank place
reproduces it. The village sign BillboardGui overlaps the
HUD at iPhone 14 size (BUG-006, filed 2026-11-14). HUD text rendered in English in that frame
(BUG-007), but `Strings.langFor` keys off the client locale and this machine is en-us, so it is
not a defect until an id-ID run says otherwise. Phase 0.4 baseline shots and design timings are in
`docs/v2/evidence/baseline/REPORT.md`.
