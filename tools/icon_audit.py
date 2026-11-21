"""Objective icon audit: size, alpha coverage, near-duplicate perceptual hash.

Hash: dHash 8x8 (64-bit). RGB composited over white, resized to 9x8 grayscale
(LANCZOS), each pixel compared to its right neighbour; bit=1 if left>right.
Near-duplicate: Hamming distance <= 5 (documented in output header).
Coverage: percent of pixels with alpha>0; PASS iff 15<=coverage<=85 inclusive.
No alpha channel -> coverage 100% -> FAIL (opaque/no-alpha).
Report only; exit code always 0. No visual/aesthetic judgment.
"""

import argparse
from pathlib import Path

from PIL import Image

COVERAGE_MIN = 15.0
COVERAGE_MAX = 85.0
NEAR_DUP_THRESHOLD = 5
HASH_SIZE = 8

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_ROOT = REPO_ROOT / "docs" / "v2" / "visual" / "art" / "icons"


def rel_display(path, repo_root):
    try:
        return path.resolve().relative_to(repo_root).as_posix()
    except ValueError:
        return path.as_posix()


def coverage_of(img):
    has_alpha = img.mode in ("RGBA", "LA") or (img.mode == "P" and "transparency" in img.info)
    if not has_alpha:
        return 100.0, False
    alpha = img.convert("RGBA").getchannel("A")
    nonzero = sum(alpha.histogram()[1:])
    total = img.width * img.height
    return (100.0 * nonzero / total if total else 0.0), True


def dhash_bits(img):
    rgba = img.convert("RGBA")
    bg = Image.new("RGBA", rgba.size, (255, 255, 255, 255))
    bg.alpha_composite(rgba)
    gray = bg.convert("L").resize((HASH_SIZE + 1, HASH_SIZE), Image.Resampling.LANCZOS)
    bits = []
    for y in range(HASH_SIZE):
        for x in range(HASH_SIZE):
            bits.append(1 if gray.getpixel((x, y)) > gray.getpixel((x + 1, y)) else 0)
    return bits


def bits_hex(bits):
    value = 0
    for bit in bits:
        value = (value << 1) | bit
    return "%016x" % value


def hamming(a, b):
    return sum(x != y for x, y in zip(a, b))


def main():
    parser = argparse.ArgumentParser(description="Objective icon audit (report only).")
    parser.add_argument("--root", type=Path, default=DEFAULT_ROOT, help="icons directory (default: repo icons dir)")
    args = parser.parse_args()

    root = args.root.resolve()
    png_paths = sorted(root.rglob("*.png"), key=lambda p: rel_display(p, REPO_ROOT))
    records = []
    for path in png_paths:
        with Image.open(path) as img:
            size = img.size
            coverage, has_alpha = coverage_of(img)
            bits = dhash_bits(img)
        records.append(
            {
                "display": rel_display(path, REPO_ROOT),
                "size": size,
                "coverage": coverage,
                "has_alpha": has_alpha,
                "bits": bits,
                "hex": bits_hex(bits),
                "pass": COVERAGE_MIN <= coverage <= COVERAGE_MAX,
            }
        )

    print(
        "ICON AUDIT | hash=dHash-8x8 (64-bit; RGB over white; 9x8 grayscale LANCZOS) "
        "| near-dup Hamming<=%d | coverage bounds %.0f%%-%.0f%% inclusive | PNGs=%d"
        % (NEAR_DUP_THRESHOLD, COVERAGE_MIN, COVERAGE_MAX, len(records))
    )
    print()
    print("=== PER-PNG ===")
    for r in records:
        status = "PASS coverage" if r["pass"] else "FAIL coverage"
        if not r["has_alpha"]:
            status += " (opaque/no-alpha)"
        print(
            "%s | %dx%d | %.2f%% | %s | %s"
            % (r["display"], r["size"][0], r["size"][1], r["coverage"], status, r["hex"])
        )

    passing = [r for r in records if r["pass"]]
    failing = [r for r in records if not r["pass"]]

    near_pairs = []
    for i in range(len(records)):
        for j in range(i + 1, len(records)):
            dist = hamming(records[i]["bits"], records[j]["bits"])
            if dist <= NEAR_DUP_THRESHOLD:
                near_pairs.append((records[i]["display"], records[j]["display"], dist))
    near_pairs.sort()

    print()
    print("=== SUMMARY ===")
    print("total PNGs: %d" % len(records))
    print("coverage PASS: %d" % len(passing))
    print("coverage FAIL: %d" % len(failing))
    if failing:
        print("coverage FAIL list:")
        for r in failing:
            extra = " (opaque/no-alpha)" if not r["has_alpha"] else ""
            print("  %s | %.2f%%%s" % (r["display"], r["coverage"], extra))
    else:
        print("coverage FAIL list: (none)")
    print("near-duplicate pairs (Hamming<=%d): %d" % (NEAR_DUP_THRESHOLD, len(near_pairs)))
    if near_pairs:
        for p1, p2, dist in near_pairs:
            print("  %s <-> %s | distance=%d" % (p1, p2, dist))
    else:
        print("  (none)")

    print()
    print("=== tier_biasa ===")
    by_display = {r["display"]: r for r in records}
    for dirname in ("render", "render_r3"):
        target = "docs/v2/visual/art/icons/%s/tier_biasa.png" % dirname
        r = by_display.get(target)
        if r is None:
            candidates = [x for x in records if Path(x["display"]).name == "tier_biasa.png" and Path(x["display"]).parent.name == dirname]
            r = candidates[0] if candidates else None
        if r is None:
            print("%s | NOT FOUND" % target)
            continue
        others = [
            (hamming(r["bits"], o["bits"]), o["display"])
            for o in records
            if o["display"] != r["display"]
        ]
        others.sort()
        nearest_dist, nearest_path = others[0] if others else (None, "(none)")
        print(
            "%s | size=%dx%d | coverage=%.2f%% | coverage_pass=%s | hash=%s | nearest=%s | nearest_distance=%s | has_alpha=%s"
            % (
                r["display"],
                r["size"][0],
                r["size"][1],
                r["coverage"],
                "YES" if r["pass"] else "NO",
                r["hex"],
                nearest_path,
                nearest_dist,
                "YES" if r["has_alpha"] else "NO",
            )
        )


if __name__ == "__main__":
    main()
