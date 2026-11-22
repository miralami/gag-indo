"""Report GLB up-axis from POSITION bounds plus the node root rotation."""
import json
import struct
from pathlib import Path

RAW = Path(__file__).resolve().parent.parent / "raw" / "vegetation_r4"


def js(path):
    data = path.read_bytes()
    off = 12
    while off < len(data):
        clen, ctype = struct.unpack_from("<I4s", data, off)
        if ctype == b"JSON":
            return json.loads(data[off + 8 : off + 8 + clen].decode("utf-8"))
        off += 8 + clen


for p in sorted(RAW.glob("*.glb")):
    d = js(p)
    lo = [float("inf")] * 3
    hi = [float("-inf")] * 3
    for mesh in d.get("meshes", []):
        for prim in mesh["primitives"]:
            a = d["accessors"][prim["attributes"]["POSITION"]]
            for i in range(3):
                lo[i] = min(lo[i], a["min"][i])
                hi[i] = max(hi[i], a["max"][i])
    ext = [round(hi[i] - lo[i], 2) for i in range(3)]
    rot = [n.get("rotation") for n in d.get("nodes", [])[:3]]
    print(f"{p.stem:16} extents XYZ={ext} generator={d.get('asset', {}).get('generator')!r} rootRot={rot}")
