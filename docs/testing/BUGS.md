# Bug List

Single defect list for the Master Plan (`docs/v2/MASTER_PLAN.md` §0, §3.0.2, §3.0.3b).
Every agent reads this first and adds real findings only. No invented bugs, asset IDs or UserIds.

Status words follow `MASTER_PLAN.md` §7: `SEEN-IN-STUDIO`, `LUNE-ONLY`, `UNVERIFIED`, `BLOCKED`.
A Studio-only defect is `BLOCKED` until track C or track H runs it and saves evidence under
`docs/v2/evidence/`.

| ID | Severity | Owner track | Steps / evidence | Status |
|---|---|---|---|---|
| BUG-001 | minor | C | Play Solo `JuraganDesa.rbxl`. Output warned `Cloud instance must exist under Terrain node in workspace to be visible.` Cause: `src/client/World/Sky.luau` parented `Clouds` under `Lighting`. Fix: create/migrate `Clouds` under `workspace.Terrain`, wait up to 10 s for Terrain, and skip the tween if Terrain never appears. Measured 2026-11-14: `workspace.Terrain` has a `Clouds` instance with `Cover` 0.55, none under `Lighting`, no Clouds warning in Output. | fixed — `SEEN-IN-STUDIO` (2026-11-14, `docs/v2/evidence/h/2026-11-14-phase0/`) |
| BUG-002 | minor | C | Play Solo, then invoke `Greybox.build()` twice in the same session. Old code called `workspace.Terrain:FillBlock` on absolute CFrames without clearing, so the river and four terrace rows stacked. Fix: `Greybox.applyTerrain` fills every owned volume with `Enum.Material.Air` first, then refills the same five volumes; nothing outside those bounds is touched. First-build result is unchanged. Measured 2026-11-14: water voxel count in the owned river region read 2700 before, 2700 after build 1, 2700 after build 2 — two consecutive `Greybox.build()` calls did not stack terrain. | fixed — `SEEN-IN-STUDIO` (2026-11-14, `docs/v2/evidence/h/2026-11-14-phase0/`); `LUNE-ONLY` regression test `tests/specs/greybox_spec.luau` |
| BUG-003 | major | C | Play Solo `JuraganDesa.rbxl`. Output repeats 3× per play start: `ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type`. Still open after the 2026-11-14 run. Not found in: the DataModel in Client or Server mode (scan of ~7500 and ~4000 descendants across `Image`, `Texture`, `SoundId`, `MeshId`, `TextureContent`, `ImageContent`, `SoundContent`, `Asset`, `ColorMap`, `AlphaMap`, `EmissiveMask`, `ResourceId`, `Skybox*`), any script source in the Server DataModel, `JuraganDesa.rbxl` bytes (binary ASCII scan), `src/` or `tests/`, or the installed Rojo plugin file. `%LOCALAPPDATA%\Roblox\Plugins` holds only `RojoManagedPlugin.rbxm`, and every Studio install's `content` folder (541 script/model/json/xml files across five versions) was scanned with no hit — the reference is not in any locally installed file. `grep -R 203785492` finds only docs. | open — `BLOCKED` on Studio (track C only; nobody else saves `JuraganDesa.rbxl`); unexplained |
| BUG-004 | major | B | **Broke player with an active loan cannot recover inside the session.** Quality bar §0.4 says no cash + no seeds + no crops must always be recoverable. The only recovery paths found in code are (a) `DebtService.borrow` (`src/server/Economy/DebtService.luau:99-122`) which refuses while `debt.active and debt.owed > 0`, and (b) `QuestService.claimDaily` (`src/server/Progression/QuestService.luau:102-129`), which refuses once `loginClaimedToday`. With an active loan, zero cash, zero `padi` seeds, no growing and no ready crop, both are closed, so the player has no action until the next calendar day. `Pinjol.calcLimit("gurem", 50)` = 500 (`src/shared/Config/Pinjol.luau:33-38`), so a non-borrowing broke player is fine — only the active-loan case is a dead end. | open — `UNVERIFIED` (no Studio; needs a one-player scripted check), `BLOCKED` on decision D-G3 |
| BUG-005 | major | H | Every sell and every buy printed a server error in Output: `argument #6 expects a string, but EnumItem was passed`, stack `Analytics.luau:157 → Analytics.luau:84 economy → EconomyService:95 addCash / 116 trySpend`. Cause: `Analytics.economy` passed `Enum.AnalyticsEconomyTransactionType[...]` where the engine signature is `AnalyticsService:LogEconomyEvent(player, flowType: AnalyticsEconomyFlowType, currencyType: string, amount, endingBalance, transactionType: string, itemSku: string, customFields?)` — `transactionType` is a **string**, not an `EnumItem` (confirmed against create.roblox.com/docs/reference/engine/classes/AnalyticsService). Fix: pass the string directly in `src/server/Analytics/Analytics.luau`; `tests/specs/analytics_spec.luau` asserts the string type (495 tests pass). Re-ran the full loop in Studio after the fix: the error is gone, `AnalyticsService: LogEconomyEvent event fired.` printed twice, zero stack traces in Output. | fixed — `SEEN-IN-STUDIO` (2026-11-14, `docs/v2/evidence/h/2026-11-14-phase0/`) |
| BUG-006 | minor | D | Play Solo `JuraganDesa.rbxl`, iPhone 14 emulation (844x390), player standing on their plot. The village BillboardGui labels (`LAHAN MIRALAMI` and the leftmost sign) sit under the top-left HUD panel: the panel covers part of the world text and the world text shows through beside the panel, so both are harder to read. World/UI conflict, not a logic bug. Evidence: `docs/v2/evidence/baseline/phone-plot.png`. | open — SEEN-IN-STUDIO (2026-11-14) |
| BUG-007 | minor | D | Same session and frame. Player-facing HUD copy is English (`Rank: Smallholder`, `Sack: 0/40`, `Sus`, `Reputation`, `Seeds`, `Phone`, `Board`, `Rice`, `Cassava`, `Rp`) while world copy in the same frame is Indonesian (`LAHAN MIRALAMI`, `Ayam kosong`). Master Plan §7 item 4 wants player text in `Strings.luau` in ID and EN. Investigated: the copy is not hardcoded — `src/shared/Strings.luau` carries both variants (`hud_rank` line 79, `hud_harvest_bag` 86, `hud_namabaik` 81, `rank_gurem` 29) and `Strings.langFor` (line 386) returns `id` only when the locale id starts with `id`, so an en-us Studio client legitimately renders the `en` variant. Evidence: `docs/v2/evidence/baseline/phone-plot.png`. | open — not a defect as seen; needs an `id-ID` locale run to confirm the Indonesian variant, then close |

## BUG-004 next step

Two candidate fixes; pick one before coding (D-G3). Both are server-side and small.
1. **Free seed floor (recommended, most satirical):** in `FarmService` or `PlayerData.onLoad`, when the player has no cash, no seeds of any kind, and no planted crop, grant 1 `padi` seed once per session with a "tetangga kasih bibit" message. Never grants cash, so the loan still hurts.
2. **Borrow top-up while a loan is active:** allow a second loan only when the player is completely idle (same conditions), capped so `owed` cannot exceed `Pinjol.maxDebtMultiplier`. Deepens the debt trap but makes the trap harder to escape and needs a fresh balance test.

## BUG-003 next step (Studio, track C)

Do not guess a replacement asset ID. Remove or re-type the existing reference first.

The 2026-11-14 scan came up empty (DataModel in Client and Server mode, server script source,
`JuraganDesa.rbxl` bytes, `src/`, `tests/`, the installed Rojo plugin), so bisect the source of
the line instead of searching for it:

1. Open a **blank place** and press Play. If the 3 lines appear, they come from Studio or an
   installed plugin, not from this place.
2. With `JuraganDesa.rbxl` open, disable plugins (Rojo included) one at a time and press Play
   after each change. Record which plugin, if any, makes the line disappear.
3. Only if a plugin is cleared and the line remains: fall back to the property scan below in
   **Edit** mode, widening the property list.

Evidence gathered 2026-11-14 that shortens the list: no Studio plugin other than Rojo is
installed, and no file in any Studio `content` folder mentions the ID. If step 1 (blank place)
reproduces the line, nothing in this repository or on this machine can be the cause, and the
finding belongs upstream in Studio rather than in track C.

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

Left: BUG-003 (unexplained), BUG-004 (needs D-G3), minigame feel, frame rate, ten-player
session, soak, and persistence in a published place. The village sign BillboardGui overlaps the
HUD at iPhone 14 size (BUG-006, filed 2026-11-14). HUD text rendered in English in that frame
(BUG-007), but `Strings.langFor` keys off the client locale and this machine is en-us, so it is
not a defect until an id-ID run says otherwise. Phase 0.4 baseline shots and design timings are in
`docs/v2/evidence/baseline/REPORT.md`.
