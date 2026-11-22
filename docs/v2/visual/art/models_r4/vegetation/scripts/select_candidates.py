"""Mechanical cleanup: rename the two chosen candidates to slot names, drop the unused CC0 bush."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "raw" / "vegetation_r4"
for old, new in (("mangga_standin.glb", "mangga.glb"), ("shrubs_pbg.glb", "shrubs.glb")):
    (RAW / old).rename(RAW / new)
(RAW / "shrubs_cc0.glb").unlink(missing_ok=True)
src = json.loads((ROOT / "sources.json").read_text(encoding="utf-8"))
src = [s for s in src if s["slot"] != "shrubs_cc0"]
for s in src:
    if s["slot"] == "mangga_standin":
        s["slot"] = "mangga"
    if s["slot"] == "shrubs_pbg":
        s["slot"] = "shrubs"
(ROOT / "sources.json").write_text(json.dumps(src, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print("selected:", [s["slot"] for s in src])
