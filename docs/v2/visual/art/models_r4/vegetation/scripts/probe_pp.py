"""Throwaway recon helper: list Poly Pizza search results and their licence/author/tris.

Not part of the shipped asset pipeline. Run: python probe_pp.py banana_tree bamboo ...
"""
import re
import sys
import time

import requests

H = {"User-Agent": "Mozilla/5.0"}


def get(url):
    for attempt in range(4):
        t = requests.get(url, timeout=40, headers=H).text
        if "Just a moment" not in t:
            return t
        time.sleep(3 * (attempt + 1))
    return t


def search(term):
    url = "https://poly.pizza/search/" + term.replace(" ", "%20")
    t = get(url)
    pairs = re.findall(r'<a href="/m/([A-Za-z0-9]{9,12})">.*?title="([^"]+)"', t)
    seen, out = set(), []
    for mid, name in pairs:
        if mid in seen:
            continue
        seen.add(mid)
        out.append((mid, name))
    return out


def detail(mid):
    t = get("https://poly.pizza/m/" + mid)
    time.sleep(0.4)
    title = re.search(r"<title[^>]*>([^<]+)</title>", t)
    creator = re.search(r'"Creator":\{"Username":"([^"]+)"', t)
    tris = re.search(r'"Tris":(\d+)', t)
    glb = re.search(r"static\.poly\.pizza/([0-9a-f-]{36})\.glb", t)
    plain = re.sub(r"<[^>]+>", " ", t)
    plain = re.sub(r"\s+", " ", plain)
    lic = "UNKNOWN"
    if "Attribution-ShareAlike" in plain:
        lic = "CC_BY_SA"
    elif "Creative Commons Attribution" in plain:
        lic = "CC_BY"
    elif "Public Domain" in plain or "CC0" in plain:
        lic = "CC0"
    elif "Royalty Free" in plain or "Standard" in plain:
        lic = "STANDARD"
    return {
        "id": mid,
        "title": (title.group(1) if title else "")[:70],
        "creator": creator.group(1) if creator else "?",
        "tris": tris.group(1) if tris else "?",
        "glb": glb.group(1) if glb else None,
        "lic": lic,
    }


def main():
    for term in sys.argv[1:]:
        print("=== " + term + " ===")
        for mid, name in search(term)[:20]:
            d = detail(mid)
            if d["lic"] in ("CC0", "CC_BY") and "quaternius" not in d["creator"].lower():
                print(
                    f"  {d['id']:14} {d['lic']:6} {d['tris']:>7} tris  {d['creator'][:20]:20} "
                    f"{d['title'][:45]:45} glb={d['glb']}"
                )
            else:
                print(f"  {d['id']:14} {d['lic']:6} {d['tris']:>7} tris  {d['creator'][:20]:20} SKIP/OTHER {d['title'][:40]}")


if __name__ == "__main__":
    main()
