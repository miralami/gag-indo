"""Temporary source-page probe for the npcs_r4 lane. Not part of the shipped pipeline."""

import re
import sys

import requests

url = sys.argv[1] if len(sys.argv) > 1 else "https://poly.pizza/search/farmer"
html = requests.get(url, timeout=30).text
print("URL", url, "STATUS", len(html))
if len(sys.argv) > 2:
    needle = sys.argv[2]
    at = html.find(needle)
    print("NEEDLE", needle, "AT", at)
    print(html[max(0, at - 300) : at + 2200])
else:
    matches = list(re.finditer(r'<a href="/m/([^"]+)"', html))
    for i, match in enumerate(matches):
        block = html[match.start() : matches[i + 1].start() if i + 1 < len(matches) else match.start() + 5000]
        title = re.search(r'alt="([^"]+)"', block)
        licence = re.search(r"(Public Domain \(CC0\)|CC BY[^<]*|CC0[^<]*|Attribution[^<]*|Licen[cs]e[^<]*)", block)
        print(match.group(1), "|", title.group(1) if title else "?", "|", licence.group(1) if licence else "?")
