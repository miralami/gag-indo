"""Verify each Poly Pizza source page, download the real GLB, and report its contents.

stdlib + requests only. The licence text printed here is copied verbatim into
SOURCES.md / MANIFEST.md. No API key is used: Poly Pizza serves GLBs publicly.
"""

import json
import re
import struct
from pathlib import Path

import requests

from probe_pp import get

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "raw" / "vegetation_r4"
H = {"User-Agent": "Mozilla/5.0"}

CANDIDATES = [
    ("kelapa", "bXUTyfiwqBb", "8f6cf878-c10b-4d28-b38c-45e09d079031"),
    ("pisang", "d0WJSiuOz6o", "9beeeccc-55e3-46d8-8d9a-0933dc49194f"),
    ("bambu", "eixDUxUDkTK", "6dfe1137-b696-4d9e-ac40-dbc8f51353f0"),
    ("mangga_standin", "ekCgu7iLrz2", "4c740e67-5607-4dae-889f-cbd747ca5b1b"),
    ("shrubs_pbg", "aMGUklRjpyo", "c6494160-b811-4990-8dac-6fda50ad3b95"),
    ("shrubs_cc0", "I5KhMKZKju", "395da3ee-c61f-4a7d-b9ed-eb2052c8e86b"),
]


def page_info(pid):
    t = get("https://poly.pizza/m/" + pid)
    plain = re.sub(r"<[^>]+>", " ", t)
    plain = re.sub(r"\s+", " ", plain)
    title = re.search(r"<title[^>]*>([^<]+)</title>", t)
    creator = re.search(r'"Creator":\{"Username":"([^"]+)"', t)
    tris = re.search(r'"Tris":(\d+)', t)
    # Licence sentence as rendered on the page: "Oct 12, 2017 · OBJ /GLTF format · <licence>"
    m = re.search(r"format\s*[·&#;a-z]*\s*([A-Z][^<]{3,70})", plain)
    licence = m.group(1).strip() if m else "?"
    by = re.search(r"Creative Commons Attribution[^<]{0,30}", plain)
    licence_link = re.search(r'href="(https://creativecommons.org/licenses/[^"]+)"', t)
    return {
        "page": "https://poly.pizza/m/" + pid,
        "title": title.group(1).strip() if title else "?",
        "creator": creator.group(1) if creator else "?",
        "page_tris": int(tris.group(1)) if tris else None,
        "licence": licence,
        "licence_detail": by.group(0) if by else licence,
        "licence_url": licence_link.group(1) if licence_link else None,
    }


def glb_info(path):
    data = path.read_bytes()
    magic, version, length = struct.unpack_from("<4sII", data, 0)
    assert magic == b"glTF" and version == 2 and length == len(data), (magic, version, length, len(data))
    off = 12
    js = None
    while off < length:
        clen, ctype = struct.unpack_from("<I4s", data, off)
        chunk = data[off + 8 : off + 8 + clen]
        if ctype == b"JSON":
            js = json.loads(chunk.decode("utf-8"))
        off += 8 + clen
    tris = 0
    has_color = False
    for mesh in js.get("meshes", []):
        for prim in mesh["primitives"]:
            if "COLOR_0" in prim.get("attributes", {}):
                has_color = True
            idx = prim.get("indices")
            if idx is not None:
                tris += js["accessors"][idx]["count"] // 3
            else:
                pos = prim["attributes"].get("POSITION")
                if pos is not None:
                    tris += js["accessors"][pos]["count"] // 3
    images = len(js.get("images", []))
    textures = len(js.get("textures", []))
    materials = len(js.get("materials", []))
    textured = images > 0 or has_color
    return {
        "bytes": len(data),
        "tris": tris,
        "images": images,
        "textures": textures,
        "materials": materials,
        "vertex_color": has_color,
        "textured": textured,
        "extensions": js.get("extensionsUsed", []),
    }


def main():
    RAW.mkdir(parents=True, exist_ok=True)
    out = []
    for slot, pid, uuid in CANDIDATES:
        info = page_info(pid)
        url = f"https://static.poly.pizza/{uuid}.glb"
        r = requests.get(url, timeout=90, headers=H)
        print(f"download {slot}: HTTP {r.status_code} {len(r.content)} bytes")
        if r.status_code != 200:
            continue
        path = RAW / f"{slot}.glb"
        path.write_bytes(r.content)
        gi = glb_info(path)
        info.update({"slot": slot, "glb_uuid": uuid, "glb_url": url, "glb": gi})
        out.append(info)
        print(
            f"  {info['title'][:40]:40} by {info['creator'][:18]:18} "
            f"lic={info['licence_detail'][:38]:38} "
            f"tris={gi['tris']:>6} img={gi['images']} tex={gi['textures']} "
            f"vcol={gi['vertex_color']} textured={gi['textured']}"
        )
    (ROOT / "sources.json").write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print("wrote sources.json with", len(out), "verified candidates")


if __name__ == "__main__":
    main()
