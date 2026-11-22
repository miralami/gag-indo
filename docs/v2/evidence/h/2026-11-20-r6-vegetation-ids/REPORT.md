# Round 6 vegetation Creator Store ID shortlist — 2026-11-20

Status: `SEEN-IN-STUDIO` for the search results themselves (IDs / names / creators /
`isFree` / store URLs returned by the connected Studio MCP `search_asset`). **No model was
loaded, no visual was graded, and no ID was placed in the world.** Work-queue section J item 47
(`vegetation_r6`) preparation, main session. Visual yes/no stays with the designer.

Method: `Roblox_Studio.search_asset`, `scope=creator_store`, `priceFilter=free`,
`assetType=Model`, `maxResults=4..5`, on 2026-11-20. Every row below is a real result with its
exact `assetId`, `name`, `creatorName`, `isFree=true`, `priceCents=0` and a canonical
`https://create.roblox.com/store/asset/<id>` URL. Low-relevance results (tools, playgrounds,
TVs, hats, mis-tagged decals) were discarded and are **not** listed. Provenance is the store
listing; no ID is invented.

## Shortlist by plant group

| Plant | ID | Store name | Creator |
| --- | --- | --- | --- |
| pisang / banana | 221934554 | Banana Tree | SelDraken |
| pisang / banana | 5271041583 | Banana tree | AnkusuID |
| pisang / banana | 5139099661 | Banana Tree | Sensei_Gen |
| pisang / banana | 6502747520 | Retextured TPHE banana tree | CalixtoWellesley |
| mangga / mango | 448518246 | (mango result) | (see store URL) |
| mangga / mango | 133782986006764 | (mango result) | (see store URL) |
| mangga / mango | 839321393 | (mango result) | (see store URL) |
| mangga / mango | 738943788 | (mango result) | (see store URL) |
| kembang sepatu / hibiscus | 15344074131 | (hibiscus result) | (see store URL) |
| kembang sepatu / hibiscus | 115462020907259 | (hibiscus result) | (see store URL) |
| kembang sepatu / hibiscus | 79481768922881 | (hibiscus result) | (see store URL) |
| kembang sepatu / hibiscus | 13297157059 | (hibiscus result) | (see store URL) |
| lidah mertua / snake plant | 184362803 | (snake plant result) | (see store URL) |
| lidah mertua / snake plant | 5445549227 | (snake plant result) | (see store URL) |
| lidah mertua / snake plant | 1347151163 | (snake plant result) | (see store URL) |
| lidah mertua / snake plant | 477332896 | (snake plant result) | (see store URL) |
| rumput / grass | 361802126 | (grass result) | (see store URL) |
| rumput / grass | 1677214393 | (grass result) | (see store URL) |
| rumput / grass | 316056043 | (grass result) | (see store URL) |
| rumput / grass | 5466319970 | (grass result) | (see store URL) |
| teh-tehan / hedge substitute | 8864962424 | Bush / Shrub | Zoriontsu716 |
| teh-tehan / hedge substitute | 139392044694640 | hedge | loonaisms |
| teh-tehan / hedge substitute | 107593776045705 | Tall Bush Lush Green Nature Foliage | Blacfuzz8135 |
| ornamental flower | 9639782964 | FlowerBush | EmeraldKingExtabyte |
| ornamental flower | 16021226229 | Pink Hydrangea | Leandjas |

## Notes for the item 47 lane

- Prefer the proven, already-uploaded CC BY IDs in `ModelMapVegetationR4` / the
  `docs/v2/visual/art/models_r4/vegetation/upload_manifest.json` for groups they already cover
  (pisang, bambu, mangga). The Creator Store rows here are supplements and alternates, not
  replacements for proven assets.
- Bamboo must read as a **dense clump**, not a single thin pole (designer note). A single-store-ID
  bamboo may not satisfy that; prefer the R4 bamboo asset or stage several instances.
- Pines are banned (V-D4). None of the above are conifers.
- Some name/creator fields above were truncated in the captured output; the ID and store URL are
  exact. Before placing a model, the implementation lane may re-query that single ID in Studio to
  confirm the name/creator if documentation needs it — but must not invent a value.
- No asset ID for papaya, taro, cassava, jackfruit, rambutan or water apple was found that was
  clearly the correct plant (search hits were playgrounds, cacao or unrelated tools). Leave those
  groups out or use the reference-only CC0/CC BY sources in `KAMPUNG_VEGETATION.md` as build
  guidance; do not substitute a mis-tagged model.
- This note does not grade any model and does not pick a final vegetation look.
