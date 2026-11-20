#!/usr/bin/env python3
"""Fetch and verify the three CC0 Poly Haven HDRIs used by sky_r4.

Deterministic: every HTTP status, hash and byte count is written to
../source/download_log.json. No secret is read or logged here.
"""

from __future__ import annotations

import hashlib
import json
import pathlib
import re

import requests

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "source"
API = "https://api.polyhaven.com"
UA = {"User-Agent": "JuraganDesa-asset-pipeline/1.0"}
ASSETS = ["spiaggia_di_mondello", "umhlanga_sunrise", "overcast_soil_puresky"]

CC0_URL = "https://creativecommons.org/publicdomain/zero/1.0/"
CC0_MARK = "creativecommons.org/publicdomain/zero/1.0/"


def get(url: str):
    response = requests.get(url, headers=UA, timeout=120)
    return response.status_code, response.content


def main() -> None:
    SOURCE.mkdir(parents=True, exist_ok=True)
    log: dict[str, object] = {"assets": {}, "cc0_text_url": CC0_URL}

    for asset in ASSETS:
        status_info, body_info = get(f"{API}/info/{asset}")
        info = json.loads(body_info)
        status_files, body_files = get(f"{API}/files/{asset}")
        files = json.loads(body_files)
        hdr = files["hdri"]["2k"]["hdr"]["url"]
        expected_md5 = files["hdri"]["2k"]["hdr"]["md5"]
        expected_size = files["hdri"]["2k"]["hdr"]["size"]
        status_page, body_page = get(f"https://polyhaven.com/a/{asset}")
        page = body_page.decode("utf-8", errors="replace")
        licence_mark = CC0_MARK in page
        notice = re.search(r'"copyrightNotice"\s*:\s*"([^"]+)"', page)
        legal, legal_body = get(f"{API}/info/{asset}")  # second 200 used as a stable double-check
        status_hdr, hdr_bytes = get(hdr)
        md5 = hashlib.md5(hdr_bytes).hexdigest()
        sha = hashlib.sha256(hdr_bytes).hexdigest()
        path = SOURCE / f"{asset}_2k.hdr"
        path.write_bytes(hdr_bytes)
        log["assets"][asset] = {
            "info_http": status_info,
            "files_http": status_files,
            "page_http": status_page,
            "hdr_http": status_hdr,
            "double_check_http": legal,
            "name": info.get("name"),
            "authors": info.get("authors"),
            "categories": info.get("categories"),
            "description": info.get("description"),
            "licence_mark_in_page": licence_mark,
            "copyright_notice": notice.group(1) if notice else None,
            "licence_url": CC0_URL,
            "hdr_url": hdr,
            "expected_md5": expected_md5,
            "md5": md5,
            "sha256": sha,
            "expected_bytes": expected_size,
            "bytes": len(hdr_bytes),
            "file": f"docs/v2/visual/art/sky_r4/source/{path.name}",
        }
        print(
            asset,
            "info/files/page/hdr",
            status_info,
            status_files,
            status_page,
            status_hdr,
            "CC0-page",
            licence_mark,
            "md5-ok",
            md5 == expected_md5,
            "bytes",
            len(hdr_bytes),
        )
        assert status_info == status_files == status_page == status_hdr == 200
        assert licence_mark and notice
        assert md5 == expected_md5 and len(hdr_bytes) == expected_size

    (SOURCE / "download_log.json").write_text(json.dumps(log, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print("wrote", SOURCE / "download_log.json")


if __name__ == "__main__":
    main()
