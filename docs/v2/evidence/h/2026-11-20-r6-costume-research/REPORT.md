# Round 6 costume route research — 2026-11-20

Status: `SEEN-IN-STUDIO` for the tool-capability finding. No visual verdict, no asset uploaded, no
candidate enabled. Work-queue section J item 48 (`npcs_r6`) preparation, main session.

## Finding

The round-6 queue offers two routes for role-specific, textured villager outfits:

- **Route A** — real catalog / Creator Store clothing IDs from a real search.
- **Route B** — original classic-clothing templates drawn by script and uploaded as Images via Open
  Cloud, set as `Shirt.ShirtTemplate` / `Pants.PantsTemplate`.

Route A is **not achievable with the tooling available in this session**:

1. `Roblox_Studio.search_asset` accepted `assetType` values are only
   `Model | Audio | Mesh | MeshPart | Image | Decal | Video | Package`. There is no `Shirt`, `Pants`,
   `Hat`, `Accessory`, `ClassicShirt` or `ClassicPants` option. Calls with those values are rejected by
   the tool with an explicit argument error. There is no catalog (`Catalog`/`Marketplace`) search tool
   in the connected Studio MCP, so wearable clothing IDs cannot be retrieved here.
2. Creator Store `assetType=Model`, `scope=creator_store`, `priceFilter=free` searches for
   `police uniform shirt`, `police uniform pants`, `batik shirt`, `peci songkok hat`, `caping hat`,
   `apron shirt`, `kebaya blouse` and `hijab headscarf accessory` returned low-relevance **Model**
   assets (hat "givers", statues, capes, generic roleplay outfits, mis-tagged images), not wearable
   layered clothing. Example top hits: `79057186012323` "Police uniform shirts" / Zhiyuan20171017 and
   `112619701652459` "Police uniform pants" / Zhiyuan20171017 (both `isFree=true`, `priceCents=0`,
   type `Model`) — these are Models, not `Shirt`/`Pants` assets, and were **not** selected.

## Consequence for item 48

The viable route is **Route B**: draw Shirt/Pants classic templates by script, upload the PNGs as real
Images through Open Cloud (main session, `ROBLOX_API_KEY` env var, key never printed or committed), and
record every returned Image ID in `docs/v2/visual/art/ASSET_MANIFEST.md`. Role texturing then happens
through those real templates: brown shirt/trousers for polisi, batik for Pak RT, faded shirt + rolled
trousers for petani, apron/kaos for pedagang, kebaya-style top for petani wanita. Peci / caping /
headscarf remain a separate accessory question and must not reuse the three round-5 hat IDs that hit
the 0-accessory bug — that bug still has to be fixed in the applier.

This note records tooling capability only. It does not pick a final costume look and does not grade any
visual; the designer still owns the yes/no verdict.
