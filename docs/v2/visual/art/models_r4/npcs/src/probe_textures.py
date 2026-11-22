"""Probe shortlisted source GLBs for embedded textures / vertex colours."""

import json
import pathlib
import re
import sys

import requests

from inspect_glb import describe

HERE = pathlib.Path(__file__).resolve().parent
RAW = HERE.parent / "raw" / "npcs_r4" / "candidates"
RAW.mkdir(parents=True, exist_ok=True)
ROWS = [json.loads(line) for line in (HERE / "scan_results.jsonl").open(encoding="utf-8")]

PATTERN = re.compile(
    r"farmer|peasant|woman|man|officer|vendor|merchant|villager|worker|guard|"
    r"person|character|human|citizen|grandpa|grandmother|oldman|cowboy|cowgirl|dude|base",
    re.I,
)
seen = set()
picked = []
for row in ROWS:
    if row["author"].strip().lower() == "quaternius" or row["tris"] > 8000:
        continue
    if not PATTERN.search(row["title"]) or row["page"] in seen:
        continue
    seen.add(row["page"])
    picked.append(row)

out = (HERE / "texture_probe.txt").open("w", encoding="utf-8")
for index, row in enumerate(picked):
    path = RAW / (row["page"].rsplit("/", 1)[-1] + ".glb")
    if not path.is_file():
        response = requests.get(row["glb"], timeout=90)
        if response.status_code != 200 or response.content[:4] != b"glTF":
            print("FAIL", row["title"], response.status_code, file=sys.stderr)
            continue
        path.write_bytes(response.content)
    try:
        info = describe(path)
    except Exception as exc:
        print("BAD", row["title"], repr(exc), file=sys.stderr)
        continue
    out.write(
        json.dumps(
            {
                "title": row["title"],
                "author": row["author"],
                "licence": row["licence"],
                "page": row["page"],
                "tris": info["triangles"],
                "textures": info["textures"],
                "vcol": info["vertexColor"],
                "uv": info["uv"],
                "skins": info["skins"],
                "size": [round(v, 4) for v in info["bounds"]["size"]],
                "file": path.name,
            },
            ensure_ascii=False,
        )
        + "\n"
    )
    out.flush()
