# Round 6 classic-clothing template layout — 2026-11-20

Status: `LUNE-ONLY` for the documentation research (external docs, no Studio, no upload, no visual).
Work-queue section J item 48 (`npcs_r6`) Route B preparation, main session. No asset was created or
graded; the designer still owns the yes/no verdict.

## Route B is viable with Image assets

- Open Cloud **cannot** create `Shirt` / `Pants` asset types. `POST /assets/v1/assets` supports only
  Animation, Audio, Decal/Image, Mesh, Model, Video. Image constraints: `.png/.jpeg/.bmp/.tga`,
  < 8000×8000, ≤ 20 MB, no content update. Classic Shirt/Pants upload is Dashboard-only
  (80 Robux per submission). Source: https://create.roblox.com/docs/cloud/guides/usage-assets
- **Image** asset IDs work directly in `Shirt.ShirtTemplate` and `Pants.PantsTemplate` (both
  `ContentId`, read-write). Use **Image** IDs, not Decal IDs and not clothing IDs; the community
  verified decals render invisible and Image IDs fix it. Sources:
  https://create.roblox.com/docs/reference/engine/classes/Shirt/ShirtTemplate ,
  https://create.roblox.com/docs/reference/engine/classes/Pants ,
  https://devforum.roblox.com/t/advanced-classic-clothing-v14-layered4k-texture-rendering-for-classic-clothing-r6-and-r15/3914685
- Set the `Shirt`/`Pants` as a **sibling of a `Humanoid`** on the generated rig; do **not** route an
  Image ID through `HumanoidDescription.Shirt` / `.Pants` (docs require an actual Shirt asset type
  there). Source: https://create.roblox.com/docs/reference/engine/classes/HumanoidDescription
- Classic `Shirt`/`Pants` render on **R15** as well as R6 (official template files are literally
  named `Template-Shirts-R15.png` / `Template-Pants-R15.png`). Detail across the UpperTorso/
  LowerTorso and arm/leg joints can break, so flat colours and simple patterns are safest. Standard
  `Shirt`/`Pants` instances are sufficient; no special rig work is needed beyond Humanoid siblinging.
  Source: https://create.roblox.com/docs/avatar/classic-clothing
- `Players:CreateHumanoidModelFromDescription` is deprecated in favour of
  `CreateHumanoidModelFromDescriptionAsync`. Source: https://create.roblox.com/docs/reference/engine/classes/Players
- Moderation: every uploaded Image must reach an approved state; check
  `moderationResult.moderationState` in the Get Operation response before using the ID.

## Template canvas and UV rectangles (585 × 559 px)

Official docs list panel sizes (front/back 128×128; torso sides + limb long faces 64×128; up/down
128×64; limb caps 64×64) but not the canvas number. The 585×559 canvas is measured from Roblox's
own `Template-Shirts-R15.png` / `Template-Pants-R15.png` in the official
`Classic-Clothing-Templates.zip` (https://prod.docsiteassets.roblox.com/assets/accessories/classic-clothing/Classic-Clothing-Templates.zip).

| Region | x, y, w, h |
| --- | --- |
| Torso UP | 231, 8, 128, 64 |
| Torso FRONT | 231, 74, 128, 128 |
| Torso RIGHT side | 165, 74, 64, 128 |
| Torso LEFT side | 361, 74, 64, 128 |
| Torso BACK | 427, 74, 128, 128 |
| Torso DOWN | 231, 204, 128, 64 |
| Right limb long faces (inner/back/outer/front) | (19,355), (85,355), (151,355), (217,355), each 64×128 |
| Right limb caps (top/bottom) | (217,289), (217,485), each 64×64 |
| Left limb long faces (front/outer/back/inner) | (308,355), (374,355), (440,355), (506,355), each 64×128 |
| Left limb caps (top/bottom) | (308,289), (308,485), each 64×64 |

Pants uses the same torso and limb rectangles; limbs wrap legs instead of arms. Gaps are ignored.
64 px ≈ 1 stud. Exact left/right face-name order varies between community sources; flat colours and
non-directional patterns avoid that ambiguity. UpperTorso ≈ 96 px / LowerTorso ≈ 32 px of the torso
panel height (community R15 UV guide).

## Consequence for item 48

The viable pipeline is: draw role-specific 585×559 Shirt and Pants PNGs by script (flat colour +
simple batik/stripe/apron cues, no asymmetric fine detail), upload each as an **Image** through the
verified `ROBLOX_API_KEY` Open Cloud route (adapt `docs/v2/visual/art/textures_r4/src/upload.py`;
key never printed or committed), record every returned real ID in `ASSET_MANIFEST.md` with
provenance, then in the server applier parent a `Shirt` and `Pants` sibling of each R15 Humanoid with
`.ShirtTemplate` / `.PantsTemplate` set to `rbxassetid://<ImageId>`. This note does not pick a final
look and does not grade any visual.
