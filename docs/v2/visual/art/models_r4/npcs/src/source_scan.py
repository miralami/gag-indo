"""Scan poly.pizza search results for compliant, textured character candidates.

Prints only page metadata (title, author, licence, tris, direct GLB URL).
Never prints credentials. Read-only: no files written.
"""

import concurrent.futures
import json
import pathlib
import re
import sys
import time

import requests

CACHE = pathlib.Path(__file__).with_name("page_cache")
CACHE.mkdir(exist_ok=True)


def get(url):
    cached = CACHE / (re.sub(r"[^A-Za-z0-9_-]", "_", url) + ".html")
    if cached.is_file():
        return cached.read_text(encoding="utf-8")
    last = ""
    for attempt in range(4):
        try:
            response = requests.get(url, headers=HEADERS, timeout=30)
            if response.status_code == 200 and len(response.text) > 2000:
                cached.write_text(response.text, encoding="utf-8")
                return response.text
            last = "HTTP " + str(response.status_code)
        except Exception as exc:
            last = repr(exc)
        time.sleep(1.5 * (attempt + 1))
    print("FETCH FAIL", url, last, file=sys.stderr)
    return ""

TERMS = sys.argv[1:] or [
    "police",
    "policeman",
    "merchant",
    "vendor",
    "farmer woman",
    "villager",
    "character",
    "worker",
    "human",
    "person",
    "farmer",
    "woman",
    "man",
    "guard",
    "seller",
    "shop",
    "civilian",
    "old man",
    "grandma",
    "gardener",
]
HEADERS = {"User-Agent": "JuraganDesa-npcs-r4-source-scan/1.0"}


def search(term):
    url = "https://poly.pizza/search/" + term.replace(" ", "%20")
    html = get(url)
    slugs = list(dict.fromkeys(re.findall(r'<a href="/m/([^"]+)"', html)))
    return [(term, slug) for slug in slugs]


def page_info(item):
    term, slug = item
    url = "https://poly.pizza/m/" + slug
    html = get(url)
    licence = re.search(r'"Licence":"([^"]+)"', html)
    if not licence:
        return term, slug, "NO_META"
    name = re.search(r"<title[^>]*>([^<]+?)\s*-\s*Free 3D Model", html)
    creator = re.search(r'"Creator":\{"Username":"([^"]*)"', html)
    tris = re.search(r'"Tris":(\d+)', html)
    resource = re.search(r'"ResourceID":"([^"]+)"', html)
    public = re.search(r'"PublicID":"([^"]+)"', html)
    key = resource.group(1) if resource else (public.group(1) if public else slug)
    return term, slug, {
        "title": name.group(1) if name else "?",
        "author": creator.group(1) if creator else "?",
        "licence": licence.group(1),
        "tris": int(tris.group(1)) if tris else -1,
        "glb": "https://static.poly.pizza/" + key + ".glb",
    }


pairs = []
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
    for found in pool.map(search, TERMS):
        pairs.extend(found)
pairs = list(dict.fromkeys(pairs))
print("SEARCH RESULTS", len(pairs), file=sys.stderr)

with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
    results = list(pool.map(page_info, pairs))

out_path = __import__("pathlib").Path(__file__).with_name("scan_results.jsonl")
with out_path.open("w", encoding="utf-8") as out:
    for term, slug, info in results:
        if not isinstance(info, dict):
            continue
        if info["licence"].startswith("CC0") or info["licence"].startswith("CC-BY"):
            out.write(json.dumps({"term": term, "page": "https://poly.pizza/m/" + slug, **info}, ensure_ascii=False) + "\n")
print("WROTE", out_path, file=sys.stderr)
