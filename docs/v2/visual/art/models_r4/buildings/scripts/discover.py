"""One-off discovery helper: print Grab3D model links for a search term."""
import re
import sys

import requests

term = sys.argv[1]
r = requests.get(
    "https://grab3d.com/search/",
    params={"q": term},
    headers={"User-Agent": "JuraganDesa-asset-pipeline/1.0"},
    timeout=30,
)
print(r.status_code, r.url, len(r.text))
links = sorted(set(re.findall(r'href="(/models/[^"]+)"', r.text)))
print("\n".join(links[:120]))
for match in re.finditer(term, r.text, re.I):
    print("...", r.text[max(0, match.start() - 200) : match.end() + 200].replace("\n", " "))
