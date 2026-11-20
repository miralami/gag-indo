"""Probe candidate direct GLB URLs, without writing any response bodies."""
import requests

names = ["stilt-house", "chicken-coop", "garden-shed", "market-stall", "shop-front"]
suffixes = ["", "-light", "_light", "-low", "-lite"]
for name in names:
    for suffix in suffixes:
        url = f"https://grab3d.com/dl/{name}/{name}{suffix}.glb"
        try:
            r = requests.head(url, headers={"User-Agent": "JuraganDesa-asset-pipeline/1.0"}, timeout=20, allow_redirects=True)
            print(r.status_code, r.headers.get("content-length"), url)
        except Exception as exc:  # noqa: BLE001 - diagnostic helper
            print("ERR", type(exc).__name__, url)
