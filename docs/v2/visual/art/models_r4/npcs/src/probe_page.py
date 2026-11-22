"""Temporary individual model page probe for the npcs_r4 lane."""

import re
import sys

import requests

url = sys.argv[1]
html = requests.get(url, timeout=30).text
print("URL", url, "LEN", len(html))
for needle in ["CC0", "CC BY", "Public Domain", "Quaternius", "Author", "author", "Download", "static.poly.pizza", ".glb", "licen"]:
    hits = [m.start() for m in re.finditer(re.escape(needle), html, re.I)]
    print(needle, "COUNT", len(hits), "FIRST", hits[:4])
for needle in ["licen", "License", "Licence"]:
    for m in list(re.finditer(needle, html, re.I))[:5]:
        print("--- LICEN ---")
        print(html[max(0, m.start() - 500) : m.start() + 700])
for needle in ["CC0", "CC BY", "Public Domain", "Download", ".glb"]:
    at = html.find(needle)
    if at >= 0:
        print("---", needle, "---")
        print(html[max(0, at - 350) : at + 450])
