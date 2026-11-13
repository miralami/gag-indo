# Bug List

Single defect list for the Master Plan (`docs/v2/MASTER_PLAN.md` §0, §3.0.2, §3.0.3b).
Every agent reads this first and adds real findings only. No invented bugs, asset IDs or UserIds.

Status words follow `MASTER_PLAN.md` §7: `SEEN-IN-STUDIO`, `LUNE-ONLY`, `UNVERIFIED`, `BLOCKED`.
A Studio-only defect is `BLOCKED` until track C or track H runs it and saves evidence under
`docs/v2/evidence/`.

| ID | Severity | Owner track | Steps / evidence | Status |
|---|---|---|---|---|
| BUG-001 | minor | C | Play Solo `JuraganDesa.rbxl`. Output warns `Cloud instance must exist under Terrain node in workspace to be visible.` Cause: `src/client/World/Sky.luau` parented `Clouds` under `Lighting`. Fix: create/migrate `Clouds` under `workspace.Terrain`, wait up to 10 s for Terrain, and skip the tween if Terrain never appears. | fixed — `UNVERIFIED` (`BLOCKED` on Studio: needs Play Solo Output check) |
| BUG-002 | minor | C | Play Solo, then invoke `Greybox.build()` twice in the same session (server hook or command bar). Old code called `workspace.Terrain:FillBlock` on absolute CFrames without clearing, so the river and four terrace rows stacked. Fix: `Greybox.applyTerrain` fills every owned volume with `Enum.Material.Air` first, then refills the same five volumes; nothing outside those bounds is touched. First-build result is unchanged. | fixed — `LUNE-ONLY` (`tests/specs/greybox_spec.luau`, 2 tests); `BLOCKED` on Studio for visual check |
| BUG-003 | major | C | Play Solo `JuraganDesa.rbxl`. Output repeats 3×: `ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type`. `grep -R 203785492` finds only docs; every ID in `src/shared/Config/Visuals.luau` and `src/shared/Config/Audio.luau` is `0`. The place file is binary (`<roblox!` header, ID not plain ASCII), so the reference is baked into `JuraganDesa.rbxl` and cannot be fixed from `src/`. | open — `BLOCKED` on Studio (track C only; nobody else saves `JuraganDesa.rbxl`) |
| BUG-004 | major | B | **Broke player with an active loan cannot recover inside the session.** Quality bar §0.4 says no cash + no seeds + no crops must always be recoverable. The only recovery paths found in code are (a) `DebtService.borrow` (`src/server/Economy/DebtService.luau:99-122`) which refuses while `debt.active and debt.owed > 0`, and (b) `QuestService.claimDaily` (`src/server/Progression/QuestService.luau:102-129`), which refuses once `loginClaimedToday`. With an active loan, zero cash, zero `padi` seeds, no growing and no ready crop, both are closed, so the player has no action until the next calendar day. `Pinjol.calcLimit("gurem", 50)` = 500 (`src/shared/Config/Pinjol.luau:33-38`), so a non-borrowing broke player is fine — only the active-loan case is a dead end. | open — `UNVERIFIED` (no Studio; needs a one-player scripted check), `BLOCKED` on decision D-G3 |

## BUG-004 next step

Two candidate fixes; pick one before coding (D-G3). Both are server-side and small.
1. **Free seed floor (recommended, most satirical):** in `FarmService` or `PlayerData.onLoad`, when the player has no cash, no seeds of any kind, and no planted crop, grant 1 `padi` seed once per session with a "tetangga kasih bibit" message. Never grants cash, so the loan still hurts.
2. **Borrow top-up while a loan is active:** allow a second loan only when the player is completely idle (same conditions), capped so `owed` cannot exceed `Pinjol.maxDebtMultiplier`. Deepens the debt trap but makes the trap harder to escape and needs a fresh balance test.

## BUG-003 next step (Studio, track C)

Do not guess a replacement asset ID. Remove or re-type the existing reference first.

1. Open `JuraganDesa.rbxl` in Studio, **Edit** mode (not Play Solo).
2. Paste this into the command bar and run it. It prints every instance and property whose
   content string contains `203785492`.

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

3. Fix the reported slot: use a decal/image where an image is expected, a sound where a sound is
   expected, or delete the stale instance. No replacement ID is invented here.
4. Save the place file (track C only), re-run Play Solo, confirm the three load errors are gone.
5. Move BUG-003 to `SEEN-IN-STUDIO` and save the Output log under
   `docs/v2/evidence/c/2026-11-14-asset-type/`.

## Open blockers

- BUG-001, BUG-002 and BUG-003 all need a Studio session. No Studio session is available in the
  2026-11-14 fix pass; all three stay `BLOCKED`.
- `tests/specs/greybox_spec.luau` is registered in `tests/run.luau` by track H. Suite: 490 passing.
