# v2 — Designer Decisions

> Decisions that belong to the designer, kept out of code and out of the plan. Nothing here
> blocks M0/M1 code: each item has a safe default already in place, marked **Default**.

Status values: **open** · **decided** · **changed**

| # | Decision | Default if unanswered | Status |
|---|---|---|---|
| D1 | Approve or redirect the UI direction (PLAN §3.1). Static mockups: `docs/v2/mockups/index.html` | **Approved with redirects:** HUD → more playful, less clean. Toko Bibit → slightly more playful/Robloxy (not v1-basic, not generic-Roblox-basic). HP Chat → almost perfect, nudge toward playful. HP home → app-grid layout like a real phone. Surat → brilliant, polish only. | **decided** |
| D2 | "Politics (story)" = story chapters + Kepala Desa system? | Yes, story chapters. Build in v2.1. | **decided** |
| D3 | Launch after v2.0 instead of waiting for all four releases? | **Launch when ready:** when the gates in `MASTER_PLAN.md` §6 pass, not after a fixed list of releases. (Was: wait for all 4 releases.) | **changed** 2026-11-14 |
| D4 | Name of the hidden informant NPC (currently "Mbah Dukun-style") | Context-dependent: if mystical/dukun context → `Mbah Dukun`. If shady/underworld → pick a relevant Indonesian name for that archetype. | **decided** |
| D5 | Name of the pinjol app | **BayarLater** | **decided** |
| D6 | Roblox access in Indonesia (PLAN §8.1) — verify before M3 writes final copy | Keep ID-first. Add language picker so player can choose. | **decided** |
| D7 | Maturity questionnaire answers and policy review (PLAN §8.2) | Use real officials as inspiration but **plesetin** (parody) names and appearances. Keep persona/stereotype accurate, change names and looks. | **decided** |
| D8 | Audio source and licence (PLAN §3.1) | Keep audio planned in `Config/Audio.luau` as-is; IDs stay `0` until assets are sourced. Audio is planned, not cut. | **decided** |
| D9 | Real pass/product IDs and prices (M4) | Still open — designer unsure. `Config/Products.luau` IDs stay `0` until created in Creator Dashboard. | open |
| D10 | Admin allowlist: whose Roblox UserIds? | Clear to fill. Designer will provide UserId. | **decided** |
| D11 | Art direction (world, characters, crops, UI) | **Cat tangan berkontur:** moodboard A (painted, warm) + B (ink contour, sticker UI). High-quality graphics are a selling point for the Indonesian market, but it stays Roblox-themed (R15, chunky, phone-first). See `ART.md`. | **decided** |
| D12 | Priority order for all work | **Fun first, then looks and sound, then depth, then social drama.** All four get built. See `MASTER_PLAN.md` §2. | **decided** 2026-11-14 |
| D13 | Who produces art and audio | Agents via Blender MCP, Roblox Toolbox / licensed catalogue, and outside tools connected through MCP after the designer approves each one. Agents run in parallel with Studio MCP. | **decided** 2026-11-14 |
| D-G1 | Asset upload route (MASTER_PLAN §9.1). See `docs/v2/TOOLS.md` §3. | An Open Cloud API key scoped to the designer's account, `asset:read` + `asset:write`, kept outside the repo. Meshes still go through Studio Importer; icons, textures and audio can be automated. Hand upload alone cannot cover the `ART.md` volume. | open |
| D-G2 | Studio sessions (MASTER_PLAN §9.2). | One shared session run by track H; tracks queue for it. Importer presets are per-machine and must match between imports. | open |
| D-G3 | How a broke player recovers when an active pinjol loan blocks borrowing and today's login reward is already claimed (BUG-004). | Free 1 `padi` seed floor, once per session, when the player has no cash, no seeds and no planted crop. No cash is granted, so the loan still hurts. Alternative in `docs/testing/BUGS.md`. | open |

## How to change one

1. Edit this table: set **Status** to `decided` and write the answer in **Default if unanswered**.
2. If it unblocks code, make the code change in the same commit and link the row number in the
   commit message (e.g. `M3: UI kit per D1`).

## Notes

- Decisions already fixed by the designer and folded into the plan are not repeated here.
- Anything that changes player-visible balance belongs in `Config/`, not in this file.
