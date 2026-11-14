# TOOLS — asset pipeline, upload routes and licences

Master Plan task 0.5, track G. Answers three questions: how a Blender file becomes a Roblox
asset, who presses the upload button, and which outside tools may legally be used.

**Status:** `UNVERIFIED` — written, not run. No asset has been exported, uploaded or bought.
Every claim below is from a Roblox or vendor primary source listed in §8, or marked
`UNVERIFIED` in §7 with what would settle it. Nothing here creates an account, accepts terms,
spends money or connects a new MCP server; those are the designer's steps (Master Plan §5).

---

## 1. Decisions that block this track

| # | Decision | Blocks | Recommendation |
|---|---|---|---|
| D-G1 | Upload route: designer uploads by hand, or designer creates an Open Cloud API key for track G (Master Plan §9.1) | Every non-zero ID in the manifest, so every icon, texture and mesh swap | Open Cloud key scoped to one user, `asset:read` + `asset:write`, stored outside the repo. Hand upload cannot cover the volume in `ART.md`; see §3 for why the key still cannot upload meshes. |
| D-G2 | One Studio session shared through track H, or one per agent (Master Plan §9.2) | Import testing and screenshot evidence for anything imported | Shared session. Importer state (presets, creator, package toggle) is per-machine and must match between imports. |

Both are `BLOCKED` on the designer. Until they are answered, files are prepared and the
manifest keeps `id = 0`; the UI must degrade cleanly per Master Plan §5.

---

## 2. Export route: Blender → Roblox

Roblox's own recommendation, verbatim:

> "Export your mesh or model as a .fbx to take advantage of all of Studio's 3D import features."
> — `create.roblox.com/docs/art/modeling/export-requirements`

The same page gives the exact Blender steps, so there is no guesswork:

1. File → Export → FBX (.fbx).
2. Path Mode = **Copy**, enable **Embed Textures**.
3. Transform → Apply Scalings = **FBX Unit Scale**. If scale is still wrong on import, use the
   alternatives in `art/blender#adjust-scale-fbx`.
4. Armature → disable **Add Leaf Bones**.
5. Disable **Bake Animation** unless the file carries keyframes.
6. Export FBX.

glTF/GLB is the fallback, not the default. The Importer does accept `.gltf`, and its glTF
hierarchy differs from FBX: an extra `Model` wraps each `MeshPart`, and cages arrive as extra
models that must be deleted after import. Pick one format per asset class and stay on it.

Hard limits, from `art/modeling/specifications` and `reference/engine/classes/BasePart`:

| Limit | Value | Source |
|---|---|---|
| Triangles per mesh | 20,000 max | `art/modeling/specifications` ("Individual meshes can not exceed 20,000 triangles") |
| Texture resolution | 1024×1024 max, single UV set, UVs inside 0:1 | `art/modeling/texture-specifications` |
| Geometry | watertight, no n-gons, non-zero volume | `art/modeling/specifications` |
| Rig | bones frozen at scale 1/1/1, rotation 0/0/0, max 4 influences per vertex | same |
| `BasePart.Size` | 0.001 to 2048 studs per axis | `BasePart.md` |
| Animation per export | one track per file | same |

Consequence for track G: a modular building kit must be authored so that each piece is a
separate mesh under 20k triangles, and the size of the assembled kit is bounded by
`BasePart.Size` when pieces are welded, not by the mesh budget.

---

## 3. Upload routes

Three routes exist. They do not have equal powers.

| Route | Can upload | Notes |
|---|---|---|
| Studio **Importer** (File → Import) | model (.fbx/.obj/.gltf), image, audio, video | Full 3D preview, error checks, presets, import queue, `Upload to Roblox`, `Import as Package`. The only route for a **new** mesh. |
| **Asset Manager** / Creator Dashboard | image, audio, model, mesh, animation | Same inventory the Importer writes to. No 3D preview. |
| **Open Cloud Assets API** | Animation, Audio, Decal/Image, **Model**, Video | `POST https://apis.roblox.com/assets/v1/assets`, multipart `request` + `fileContent`, 20 MB per file, one asset per call. Scopes `asset:read` `asset:write`. |

**The Open Cloud mesh trap.** The API's `Mesh` asset type accepts "Only content downloaded from
Asset delivery API"; the docs say plainly: "If you are not trying to download and re-upload
meshes, then use Importer to import meshes instead." A `Model` upload does accept `.fbx`,
`.gltf`, `.glb` and arrives as a `Model` containing `MeshPart`s, but the docs recommend the
Importer for that use case because it previews, error-checks and exposes import settings.

So: **meshes and models go through the Importer in Studio. Everything flat and everything
audible can go through Open Cloud.** That splits D-G1 in two — the designer's API key covers
icons, textures and audio; the designer still presses the button for 3D, or hands track G a
Studio session (D-G2).

Open Cloud request shape, for the record:

```
curl 'https://apis.roblox.com/assets/v1/assets' \
  -H 'x-api-key: ${ApiKey}' \
  -F 'request={"assetType":"Decal","displayName":"…","description":"…",
       "creationContext":{"creator":{"userId":"${userId}"}}}' \
  -F 'fileContent=@"/path/p1.png"'
```

It returns an Operation ID; poll `GET /assets/v1/operations/{id}` until `done` and read
`response.assetId`. Uploaded assets belong to the `creationContext` user or group and appear in
the Toolbox and Asset Manager. Use `rbxassetid://<assetId>` in properties.

Per-type limits (Open Cloud guide):

| Type | Formats | Limit |
|---|---|---|
| Audio | .mp3 .ogg .wav .flac | 7 min; 100 uploads/month if ID-verified, 10 if not; no update |
| Decal/Image | .png .jpeg .bmp .tga | under 8000×8000 px; no update |
| Video | .mp4 .mov | 5 min, 4096×2160, 3.75 GB, 20/day if 13+ and ID-verified |
| Animation / Model | .rbxm/.rbxmx; .fbx/.gltf/.glb/.rbxm/.rbxmx | edited-outside-Studio rbxm may fail; models land as packages |

Studio-side audio rules (`audio/assets`): single track, `.mp3/.ogg/.wav/.flac`, **under 20 MB and
7 minutes**, sample rate ≤ 48 kHz, mono or stereo 2.0/3.0/5.1, and "You have the legal rights to
that audio asset." Quotas differ between the two pages — see §7.

---

## 4. Per-asset-class recommendation

Order of preference is fixed by Master Plan §5: Toolbox/licensed catalogue restyled → Blender via
MCP → outside generation cleaned up.

| Asset class | Source | Route | Licence gate |
|---|---|---|---|
| Icons 256×256 PNG (`art/ICONS.md`) | Blender or vector tool, drawn by track G; Poly Haven only for reference | Open Cloud Decal/Image or Importer | Own work — no gate. Never traced from another game's icon. |
| Seamless textures 512×512 (`art/TEXTURES.md`) | Poly Haven (CC0) first; own work in Blender second | Open Cloud Decal/Image | CC0, no attribution. Confirm on `polyhaven.com/license` before shipping (§7). |
| SurfaceAppearance PBR maps | Blender bake or Poly Haven set | Open Cloud Decal/Image | Same as above; must stay ≤1024×1024 per map. |
| Hero props, 6–8 models | Blender via MCP, procedural and stylised | Studio Importer (.fbx) | Own work. |
| Modular building kit | Blender via MCP, pieces about 2k tris (20k is Roblox's upload ceiling, not a budget; see `art/RESEARCH_VISUAL_TIPS.md` §3) | Studio Importer (.fbx), `Import as Package` | Own work. |
| Background scenery | Creator Store free models, restyled | Toolbox insert, then manifest row | Creator Store terms; see §5 gate. |
| SFX | Own recording, Kenney, or Freesound per-file | Open Cloud Audio or Importer | Kenney: commercial OK, no credit. Freesound: check each file's licence. |
| Music | Own or licensed only | — | **No commercial music.** Roblox Licensed Music may not be exported or downloaded for use outside the Services (ToU §7.1), so it cannot be baked into a file. |
| UI fonts | — | — | `BLOCKED` on D3 (Master Plan §9.3); not a track G decision. |

---

## 5. Outside tools and licence verdicts

Verdicts are about shipping a paid game, not about prototyping. "Paid only" means the free tier
legally cannot be used in the shipped experience.

| Tool | Free tier | Paid tier | Verdict |
|---|---|---|---|
| **Blender + MCP for Blender** (`ahujasid/mcp-for-blender`, formerly `blender-mcp`) | MIT licence plugin; Blender itself free | — | **OK.** MIT permits commercial use. Plugin is third-party, "not affiliated with the Blender Foundation". Socket server has no auth — keep it on `localhost`. |
| **Poly Haven** (via MCP `search_assets`) | CC0, ~2,400 HDRIs/textures/models | — | **OK, no attribution.** Best texture source. |
| **Poly Pizza** (via MCP) | ~10,600 low-poly `.glb`; ~69% CC-BY | — | **OK with credit.** Filter `licence="CC0"` to avoid attribution work; the MCP writes a ready credit line onto the imported object. |
| **Tripo** | Free outputs are public by default; you waive copyright and grant the public a licence that includes commercial exploitation | Paid: rights belong to you, commercial use allowed, keep private | **Paid only.** A free output cannot be exclusive, so it cannot anchor a game's identity. |
| **Meshy** | Meshy owns the output and licenses it back under **CC BY 4.0** — attribution required; non-enterprise content used for training unless you opt out | Paid: you own the output, private option | **Usable free with a credit line; prefer paid.** CC BY 4.0 forbids nothing here but forces an attribution surface in the game. |
| **ElevenLabs** | "you may only use the Services for non-commercial purposes" | Paid: commercial use permitted | **Paid only.** Note the perpetual, irrevocable licence you grant over your input, and that your voice is not commercialised standalone without permission. |
| **Suno** | Free/basic: "only use such Outputs for your lawful, personal and non-commercial purposes" | Pro/Premier: Suno assigns its rights in Output, "provided such Output will remain subject to these Terms of Service including any applicable commercial use restrictions"; only **downloaded** Output may be exploited | **Paid only, downloaded files only.** Roblox's own audio rules still apply on top — Suno says a third-party platform's refusal "means only that the third party, and not Suno, governs whether you may make that use". |
| **Leonardo.Ai** | Free: "ownership of all Intellectual Property Rights in any Output … will vest in us upon creation" | Paid: rights vest in you on creation | **Paid only.** Free tier output is Leonardo's property. |
| **Kenney** | CC0-style, commercial use allowed, attribution not required | — | **OK.** |
| **Freesound** | Per-file CC licences, some non-commercial | — | **OK per file**, only after reading that file's licence. Never batch-download. |

Two rules that override any tool verdict: Roblox requires that you hold the rights to anything
you upload ("You have the legal rights to that audio asset"; the ToU makes the Creator warrant
the rights they license), and Master Plan §5 bans commercial music, ripped game assets, real
people's faces or names, and real brand logos outright.

**Creator Store gate.** Purchased and free Store assets are governed by the Creator Store Terms.
What those terms actually say today:

- Assets "may only be obtained on the Creator Store for the use in Roblox Studio".
- Transactions are "non-transferable".
- You "cannot sell or distribute composite models that contain Restricted assets that you didn't
  create", though you may share them directly with collaborators.
- Asset privacy "is not a form of DRM".
- Paid models are used for AI training only if you opt in.

There is **no explicit licence-grant clause** on the public page — see §7. Practical consequence:
using a Store model inside our own experience is the intended case; redistributing it, reselling
it or shipping it as our own asset is not.

---

## 6. Asset manifest

Master Plan §5: "Every asset has a manifest row: slot, source, licence, who approved it. No row,
no merge." One row per slot in `art/ICONS.md` and `art/TEXTURES.md` plus one per model.

Fields:

| Field | Meaning |
|---|---|
| `slot` | Stable key, matches the key used in `Config/Visuals.luau` or `UI/Icons.luau` |
| `class` | `icon`, `texture`, `pbr`, `model`, `sfx`, `music` |
| `source` | Who made it: `track-g`, `polyhaven`, `creator-store`, vendor name |
| `source_ref` | URL or repo path of the source item; blank for own work |
| `licence` | `own-work`, `CC0`, `CC-BY-4.0`, `creator-store`, `paid-<vendor>` |
| `attribution` | Exact credit string, or empty when none is required |
| `id` | Roblox asset ID, or `0` until uploaded |
| `approved_by` | Designer name/date for anything not `own-work` |
| `status` | `UNVERIFIED` / `LUNE-ONLY` / `SEEN-IN-STUDIO` / `BLOCKED` per Master Plan §7 |

Rows are appended, never rewritten, so a replaced asset keeps its history. `id = 0` means "not
uploaded"; the UI must render the fallback (Color + Material per `art/TEXTURES.md`) rather than a
broken image.

Example, all IDs deliberately zero — nothing has been uploaded:

```
slot,class,source,source_ref,licence,attribution,id,approved_by,status
icon.harvest,icon,track-g,,own-work,,0,,UNVERIFIED
tex.rice.seamless,texture,polyhaven,https://polyhaven.com/a/…,CC0,,0,,UNVERIFIED
model.sawah.gate,model,track-g,,own-work,,0,,UNVERIFIED
sfx.harvest.sickle,sfx,kenney,https://kenney.nl/assets/…,CC0,,0,,UNVERIFIED
```

---

## 7. UNVERIFIED

| Claim | Why it is not settled | What settles it |
|---|---|---|
| Scope of the licence a Creator Store purchaser receives, including whether editing is allowed and what "non-transferable" forbids | The published Creator Store Terms contain sections 1–8 only (marketplace mechanics, taxes, disbursements). No licence-grant clause appears. The ToU §(Creator Store) says only that publishers warrant they can grant "the license to Purchasing Creators" | Ask Roblox support for the licence text; or a Store asset page's own licence field |
| Whether a purchased Store model may be modified and used in one experience | The FAQ bans resale and listing, not modification | Same as above |
| Which audio import quota applies to which route | `audio/assets` says 2,000 free audio assets per 30 days if ID-verified, 100 if not; the Open Cloud guide says 100/month ID-verified, 10 if not. Both are primary and they disagree | Test one Open Cloud audio upload and read the quota error, or ask Roblox |
| Whether Open Cloud `Model` uploads count against the Creator Store distribution limits (200/10 mesh and model assets per 30 days) | Distribution limits are documented for the Store, not for API uploads to inventory | Upload one model via API on a test account and observe |
| `.glb` acceptance in the Importer | The Importer's table lists ".fbx, .obj, or .gltf"; the glTF hierarchy section says ".gltf / .glb" | Import one `.glb` and watch for a warning |
| Blender's GPL does not extend to models created in Blender | `blender.org/about/license` returned 403 (Cloudflare) | Read that page in a browser, or the GPL FAQ |
| Poly Haven is entirely CC0 | Stated in the MCP for Blender README, not read on Poly Haven's own site | `polyhaven.com/license` |
| Contents of Roblox's Audio Upload License Agreement | Link confirmed (`en.help.roblox.com/hc/en-us/articles/23359485439124-Audio-Upload-License-Agreement`) but not read | Read it before the first music upload |
| Whether the MCP `generate_3d` path (Tripo/Meshy via the plugin's Premium tier) changes the licence position versus a direct account | Vendor terms bind the account holder; the plugin's Premium tier is a separate commercial relationship | Designer decision; not needed for MVP, which uses Blender geometry |

---

## 8. Sources

Roblox: `art/modeling/specifications`, `art/modeling/export-requirements`, `art/blender`,
`art/modeling/texture-specifications`, `studio/importer`, `cloud/guides/usage-assets`,
`audio/assets`, `production/creator-store`, `reference/engine/classes/BasePart`,
`en.help.roblox.com/hc/en-us/articles/21308223046932-Creator-Store-Terms`,
`en.help.roblox.com/hc/en-us/articles/115004647846` (ToU, incl. §7.1 Licensed Music).

Vendors: `tripo3d.ai/terms` (updated 2026-11-13), `meshy.ai/terms-of-use` (updated 2026-09-19),
`elevenlabs.io/terms-of-use`, `suno.com/terms`, `leonardo.ai/terms-of-service` (updated
2026-01-19), `kenney.nl` support page, `freesound.org` FAQ, `github.com/ahujasid/mcp-for-blender`.
