"""Generate Shared.TextureMapR4.luau and MANIFEST.md from the completed uploads.

Only the two new r4 files are written. Every ID comes from upload_manifest.json,
which is written only after a completed Open Cloud operation. No ID is invented.
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REPO = ROOT.parent.parent.parent.parent.parent
MAP_FILE = REPO / "src" / "shared" / "TextureMapR4.luau"
MANIFEST_FILE = ROOT / "MANIFEST.md"

# slot, variant name, base material, source code, studs per tile, surface label
VARIANTS = [
    ("dry_grass", "R4_DryGrass", "Grass", "withered_grass", 10, "dry / withered grass"),
    ("laterite", "R4_Laterite", "Ground", "red_laterite_soil_stones", 10, "laterite red dirt"),
    ("paddy_mud", "R4_PaddyMud", "Mud", "Ground026", 8, "rice-paddy mud / wet clay"),
    ("cobblestone", "R4_Cobblestone", "Cobblestone", "cobblestone_floor_04", 6, "cobblestone path"),
    ("weathered_planks", "R4_WeatheredPlanks", "WoodPlanks", "weathered_planks", 8, "weathered planks"),
    ("bilik", "R4_Bilik", "Wood", "bamboo_wall_02", 6, "woven bamboo / bilik"),
    ("brick", "R4_BrickWall", "Brick", "worn_brick_wall", 6, "weathered brick wall"),
    ("plaster", "R4_PlasterWall", "Concrete", "blue_plaster_weathered", 8, "weathered plaster wall"),
    ("clay_tile", "R4_ClayTile", "Slate", "clay_roof_tiles_03", 8, "clay roof tile"),
    ("corrugated_metal", "R4_CorrugatedMetal", "Metal", "worn_corrugated_iron", 8, "corrugated seng"),
    ("riverbank", "R4_RiverBank", "Rock", "river_small_rocks", 12, "riverbank stones"),
    ("sand_path", "R4_SandPath", "Sand", "stony_dirt_path", 8, "sandy dirt path"),
]

SURFACES = {
    "grass": "dry_grass",
    "dry_grass": "dry_grass",
    "ground": "laterite",
    "laterite": "laterite",
    "mud": "paddy_mud",
    "paddy_mud": "paddy_mud",
    "cobblestone": "cobblestone",
    "wood": "bilik",
    "weathered_planks": "weathered_planks",
    "brick": "brick",
    "plaster": "plaster",
    "slate": "clay_tile",
    "clay_tile": "clay_tile",
    "corrugated_metal": "corrugated_metal",
    "bilik": "bilik",
    "riverbank": "riverbank",
    "sand": "sand_path",
}

POLY_TEXT = (
    "Our assets are all licensed as CC0, which is effectively Public Domain "
    "even in jurisdictions that do not support the Public Domain."
)
AMBIENT_TEXT = (
    "All ambientCG assets are provided under the Creative Commons CC0 1.0 "
    "Universal License. This applies to the downloadable asset files and the "
    "material preview renders shown for each asset on the site."
)


def main() -> None:
    records = json.loads((ROOT / "upload_manifest.json").read_text(encoding="utf-8"))
    if len(records) != 36:
        raise RuntimeError(f"expected 36 completed uploads, got {len(records)}")
    by_key = {}
    for record in records:
        if record.get("asset_type") != "Image" or not record.get("asset_id"):
            raise RuntimeError(f"incomplete upload record: {record.get('file')}")
        by_key[f"{record['code']}_{record['map']}"] = record

    id_lines = []
    for slot, name, base, code, studs, label in VARIANTS:
        for map_key in ("diff", "nor", "rough"):
            key = f"{code}_{map_key}"
            record = by_key[key]
            id_lines.append(f"\t{key} = {record['asset_id']},")

    variant_blocks = []
    for slot, name, base, code, studs, label in VARIANTS:
        record = by_key[f"{code}_diff"]
        variant_blocks.append(
            "\t"
            + f"{slot} = {{\n"
            + f"\t\tname = \"{name}\",\n"
            + f"\t\tbaseMaterial = \"{base}\",\n"
            + f"\t\tsurface = \"{label}\",\n"
            + f"\t\tdiff = \"{code}_diff\",\n"
            + f"\t\tnor = \"{code}_nor\",\n"
            + f"\t\trough = \"{code}_rough\",\n"
            + f"\t\tstudsPerTile = {studs},\n"
            + f"\t\tsource = \"{record['source']}\",\n"
            + f"\t\tsourcePage = \"{record['source_page']}\",\n"
            + "\t},"
        )

    base_lines = [f"\t{base} = \"{slot}\"," for slot, name, base, code, studs, label in VARIANTS]
    surface_lines = [f"\t{surface} = \"{slot}\"," for surface, slot in SURFACES.items()]

    map_source = """--!strict
-- TextureMapR4: real CC0 1K PBR sets for the OFF-BY-DEFAULT "textures_r4"
-- LookDev candidate (WORK_QUEUE item 29). All 36 IDs were returned by completed
-- ROBLOX_API_KEY -> Open Cloud POST /assets/v1/assets operations and recorded in
-- docs/v2/visual/art/textures_r4/upload_manifest.json + MANIFEST.md. None is
-- approved or shipped on by default.
--
-- Pure data: no Roblox API is touched at load. The applier reads ids only through
-- assetUrl(), so no asset ID literal appears in LookDev or its adapter. One
-- MaterialVariant per built-in base material; normal maps are OpenGL (nor_gl /
-- NormalGL), colour is Diffuse / Color, roughness is Rough / Roughness.

local TextureMapR4 = {}

TextureMapR4.ids = {
__IDS__
}

-- One variant per base material so MaterialService:SetBaseMaterialOverride can
-- install all twelve without a collision. studsPerTile drives the tile scale.
TextureMapR4.variants = {
__VARIANTS__
}

-- Built-in base material -> variant slot. Terrain and every Part with one of
-- these materials is changed by the global override; no name matching is used.
TextureMapR4.baseMaterials = {
__BASES__
}

-- Named village surface -> variant slot, including the r4 additions.
TextureMapR4.surfaces = {
__SURFACES__
}

function TextureMapR4.slotCount(): number
\tlocal n = 0
\tfor _ in TextureMapR4.variants do
\t\tn += 1
\tend
\treturn n
end

function TextureMapR4.mapCount(): number
\tlocal n = 0
\tfor _ in TextureMapR4.ids do
\t\tn += 1
\tend
\treturn n
end

function TextureMapR4.assetUrl(key: string): string?
\tlocal id = TextureMapR4.ids[key]
\treturn if id then "rbxassetid://" .. id else nil
end

return TextureMapR4
"""
    map_source = (
        map_source.replace("__IDS__", "\n".join(id_lines))
        .replace("__VARIANTS__", "\n".join(variant_blocks))
        .replace("__BASES__", "\n".join(base_lines))
        .replace("__SURFACES__", "\n".join(surface_lines))
    )
    MAP_FILE.write_text(map_source, encoding="utf-8")

    rows = []
    for slot, name, base, code, studs, label in VARIANTS:
        diff, nor, rough = (by_key[f"{code}_{k}"] for k in ("diff", "nor", "rough"))
        ids = f"{diff['asset_id']} / {nor['asset_id']} / {rough['asset_id']}"
        rows.append(
            f"| {label} | `{slot}` | `{name}` | {base} | {studs} | "
            f"[{code}]({diff['source_page']}) | {diff['source']} | {diff['author']} | "
            f"{diff['licence']} | {ids} |"
        )

    manifest = f"""# Textures r4 — source, licence and ID manifest

WORK_QUEUE item 29. CC0 only, from Poly Haven and ambientCG. Eleven Poly Haven
sets were fetched through `https://api.polyhaven.com/files/<code>` with every
MD5 checked against the API; ambientCG `Ground026` came from the public
`https://ambientcg.com/api/v2/full_json?id=Ground026` API (1K-JPG zip), whose API
does not publish per-file MD5s, so those three MD5s were computed locally and
are labelled as such. All 36 assets were uploaded as Roblox **Image** assets via
`ROBLOX_API_KEY` -> Open Cloud `POST /assets/v1/assets`; every ID below came from
a completed operation (`upload_manifest.json` has the operation IDs). No ID was
invented, no Creator Store / CC BY / NC / ND / QAL asset was used.

## Licence evidence (verbatim source text)

- Poly Haven, [Asset License](https://polyhaven.com/license):
  > {POLY_TEXT}
  >
  > "You can use our assets for any purpose, including commercial work."
  > "You do not need to give credit or attribution when using them (although it is appreciated)."
- ambientCG, [License](https://docs.ambientcg.com/license/):
  > {AMBIENT_TEXT}
  >
  > "You can copy, modify, distribute and perform the assets, even for commercial purposes, all without asking permission."
  > "You can include the raw files in your project, for example a video game."

Poly Haven author strings are taken from `https://api.polyhaven.com/assets?t=textures`
and stored per file in `download_manifest.json` (`author_api`). The ambientCG API
exposes no per-asset author field; the site credits the publisher as ambientCG
and its suggested credit is "Created using <asset name> from ambientCG.com,
licensed under the Creative Commons CC0 1.0 Universal License."

## Sets and real IDs

ID column order: diffuse / normal (`nor_gl` or `NormalGL`) / roughness.

| Surface | Slot | Variant | Base material | Studs per tile | Source page | Provider | Author | Licence | Asset IDs |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
{chr(10).join(rows)}

## Integrity

- `download_manifest.json`: 36 rows, each with `source`, `source_page`, `url`,
  `author`, `licence`, verbatim `licence_text`, `md5` and `md5_source`.
- `upload_manifest.json`: 36 rows, each with `asset_id`, `asset_type = "Image"`,
  `operation_id` and `upload_route = "ROBLOX_API_KEY"`.
- The API key was never printed, logged or written to disk.

No visual grading, screenshot claim, place save or publish is recorded here.
"""
    MANIFEST_FILE.write_text(manifest, encoding="utf-8")
    print(f"wrote {MAP_FILE}")
    print(f"wrote {MANIFEST_FILE}")
    print(f"ids={len(id_lines)} variants={len(variant_blocks)}")


if __name__ == "__main__":
    main()
