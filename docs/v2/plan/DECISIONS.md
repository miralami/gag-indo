# v2 — Designer Decisions

> Decisions that belong to the designer, kept out of code and out of the plan. Nothing here
> blocks M0/M1 code: each item has a safe default already in place, marked **Default**.

Status values: **open** · **decided** · **changed**

| # | Decision | Default if unanswered | Status |
|---|---|---|---|
| D1 | Approve or redirect the UI direction (PLAN §3.1). Static mockups: `docs/v2/visual/mockups/index.html` | **Approved with redirects:** HUD → more playful, less clean. Toko Bibit → slightly more playful/Robloxy (not v1-basic, not generic-Roblox-basic). HP Chat → almost perfect, nudge toward playful. HP home → app-grid layout like a real phone. Surat → brilliant, polish only. | **decided** |
| D2 | "Politics (story)" = story chapters + Kepala Desa system? | Yes, story chapters. Build in v2.1. | **decided** |
| D3 | Launch after v2.0 instead of waiting for all four releases? | **Launch when ready:** when the gates in `plan/MASTER_PLAN.md` §6 pass, not after a fixed list of releases. (Was: wait for all 4 releases.) | **changed** 2026-11-14 |
| D4 | Name of the hidden informant NPC (currently "Mbah Dukun-style") | Context-dependent: if mystical/dukun context → `Mbah Dukun`. If shady/underworld → pick a relevant Indonesian name for that archetype. | **decided** |
| D5 | Name of the pinjol app | **BayarLater** | **decided** |
| D6 | Roblox access in Indonesia (PLAN §8.1) — verify before M3 writes final copy | Keep ID-first. Add language picker so player can choose. | **decided** |
| D7 | Maturity questionnaire answers and policy review (PLAN §8.2) | Use real officials as inspiration but **plesetin** (parody) names and appearances. Keep persona/stereotype accurate, change names and looks. | **decided** |
| D8 | Audio source and licence (PLAN §3.1) | Keep audio planned in `Config/Audio.luau` as-is; IDs stay `0` until assets are sourced. Audio is planned, not cut. | **decided** |
| D9 | Real pass/product IDs and prices (M4) | Deferred until Gate 1 passes (2026-11-19); price after real playtests. Still unsure. `Config/Products.luau` IDs stay `0` until created in Creator Dashboard. | open |
| D10 | Admin allowlist: whose Roblox UserIds? | Clear to fill. Designer will provide UserId. | **decided** |
| D11 | Art direction (world, characters, crops, UI) | **Cat tangan berkontur:** moodboard A (painted, warm) + B (ink contour, sticker UI). High-quality graphics are a selling point for the Indonesian market, but it stays Roblox-themed (R15, chunky, phone-first). See `visual/ART.md`. **Refined 2026-11-14: "cartoonish realism"** — chunky stylized shapes and the D11 palette, with Roblox textured materials (WoodPlanks, Grass, Slate, CorrodedMetal) on buildings, props and foliage. Reference: the Warung hub. A flat SmoothPlastic pass was tried in Studio and rejected by the designer. | **changed** 2026-11-14 |
| D12 | Priority order for all work | **Fun first, then looks and sound, then depth, then social drama.** All four get built. See `plan/MASTER_PLAN.md` §2. | **decided** 2026-11-14 |
| D13 | Who produces art and audio | Agents via Blender MCP, Roblox Toolbox / licensed catalogue, and outside tools connected through MCP after the designer approves each one. Agents run in parallel with Studio MCP. | **decided** 2026-11-14 |
| D14 | Visual target (refines D11) | **Aim realistic, land believable.** Realistic is the aim, not brutal photorealism; semi-realistic is the floor. "Better" means higher fidelity in every detail (effects, UI, motion), not only more realism. Visuals are the hook. Palette, UI kit and NPC caricature from D11 stay. Plan and open sub-decisions V-D1..V-D6: `visual/VISUAL_MASTER_PLAN.md`. | **decided** 2026-11-16 |
| D-G1 | Asset upload route (MASTER_PLAN §9.1). See `docs/v2/plan/TOOLS.md` §3. | An Open Cloud API key scoped to the designer's account, `asset:read` + `asset:write`, kept outside the repo. Meshes still go through Studio Importer; icons, textures and audio can be automated. Hand upload alone cannot cover the `visual/ART.md` volume. | Decided 2026-11-14: Open Cloud API key for icons, textures and audio; meshes and models through the Studio Importer. Uploads land in the designer's own Roblox account inventory (Creator Hub > Creations > Assets, also Studio Asset Manager), because the key's owner is the designer; the key is created at create.roblox.com > Open Cloud > API Keys with `asset:read` + `asset:write` and kept outside the repo. No key exists yet. | **decided** 2026-11-14 |
| D-G2 | Studio sessions (MASTER_PLAN §9.2). | One shared session run by track H; tracks queue for it. Importer presets are per-machine and must match between imports. | Decided 2026-11-14: yes, one shared session run by track H. | **decided** 2026-11-14 |
| D-G3 | How a broke player recovers when an active pinjol loan blocks borrowing and today's login reward is already claimed (BUG-004). | Free 1 `padi` seed floor, once per session, when the player has no cash, no seeds and no planted crop. No cash is granted, so the loan still hurts. Alternative in `docs/testing/BUGS.md`. | Decided 2026-11-14: option A, free 1 `padi` seed floor once per session. Implements BUG-004. | **decided** 2026-11-14 |
| D-G4 | May the quality bar's "zero errors and zero warnings" pass with the BUG-003 line excluded? The line is external: a blank place with no content reproduces it and the id exists nowhere on this machine (`docs/v2/evidence/h/2026-11-14-phase0/bug003-blank-place.log`). | Accept the exclusion and record it as a known external line, because nothing in this repo can remove it. The alternative is a bar that cannot be met until Roblox fixes it upstream. | Decided 2026-11-14: yes, the BUG-003 line is excluded from the zero-warnings bar and recorded as a known external line. | **decided** 2026-11-14 |
| D15 | Where 3D models come from | **Ladder, in order (designer 2026-11-19):** (1) free assets: Creator Store models whose licence allows use (strip every Script on insert), CC0 sources (Poly Haven, Poly Pizza, CC0 Sketchfab); (2) auto-generated: Studio MCP `generate_mesh` / `generate_procedural_model`, Blender MCP `generate_3d`; (3) the designer builds it; (4) Roblox parts/CSG modelling in Studio. Every source and licence goes in `ASSET_MANIFEST.md`. Everything enters as a `LookDev` candidate until the designer says yes. | **decided** |
| V-D1 | Retire the world ink outline? (`VISUAL_MASTER_PLAN.md` §10) | **Yes**: no outline on world geometry, `Highlight` only as a focus cue, UI keeps its outline. Supersedes the ink-contour half of D11; D14 governs the look. | **decided** |
| V-D2 | Let the clock move? | **Yes, slowly**: golden hour → dusk → night → morning, golden hour guaranteed for the first session and at spawn. | **decided** |
| V-D3 | The ten low-poly props | **Replace all** with real 3D models from the D15 ladder (designer 2026-11-19, overrides the per-prop recommendation). | **decided** |
| V-D4 | Pine backdrop | **Replace with tropical trees** (kelapa, pisang, bambu) within sight of the village. | **decided** |
| V-D5 | Reference photos (V0.3) | **Mix**: designer gives 3–5 (the SAWAH INDO screenshots count, for mood only, never copied), agent fills the rest from CC0 sources with links. | **decided** |
| V-D6 | Animation route | **Mix**: Creator Store for generic motion (walk, idle), authored for the tool verbs (cangkul, panen) and NPC habits. | **decided** |
| D16 | `StreamingEnabled` | **Off for now**: revisit after G6 real-device fps. | **decided** |
| D17 | Cap the Studio-only crops showcase on low tiers (round 2 item 11) | **Yes**: mature `siap` stage only on Rendah/Sedang, all stages on Tinggi. | **decided** |
| D18 | Art sourcing per candidate type (round 2 review, 2026-11-19) | Icons: keep as the base, improve all (start with `tier_biasa`, `debt`). Textures: download CC0 PBR textures online (ambientCG, Poly Haven) into MaterialVariants; the agent-drawn ones are rejected. NPCs, crops: real 3D models via the D15 ladder. Hub props: case by case, mostly real 3D models; the primitive versions are rejected, the idea (goods on the counter, lanterns) is kept. | **decided** |
| D19 | Day cycle | The eight phases in `docs/v2/visual/DAY_CYCLE.md`. 24-minute day, server start at 16:00 golden hour, readable night, soft adzan with a player on/off setting (default on, low, muted during satire moments), time-based gameplay after Gate 1. | **decided** |

## How to change one

1. Edit this table: set **Status** to `decided` and write the answer in **Default if unanswered**.
2. If it unblocks code, make the code change in the same commit and link the row number in the
   commit message (e.g. `M3: UI kit per D1`).

## Notes

- Decisions already fixed by the designer and folded into the plan are not repeated here.
- Anything that changes player-visible balance belongs in `Config/`, not in this file.
