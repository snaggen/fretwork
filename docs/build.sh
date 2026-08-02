#!/usr/bin/env bash
# Render the README illustrations, light and dark, and crop each to its ink.
#
# Typst Universe renders the README in the reader's own colour scheme, so every
# figure exists twice and the README picks between them with a <picture> element.
# The images are committed (Universe needs them) but excluded from the package
# bundle, since nothing importing the package ever reads them.
#
# Usage: docs/build.sh
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Not a round number, and it must not be "tidied" into one.
#
# A staff line is 0.075 of a staff space, and the default staff space is 2.9 mm.
# At an arbitrary resolution the 2.9 mm spacing is a fractional number of pixels,
# so successive lines land in different sub-pixel phases: some snap to one pixel
# row, some spread over two, and the staff comes out with lines of visibly
# different weight. Which lines thicken changes with the resolution — at 150 dpi
# it was the middle two, at 200 dpi the outer ones — which is what gives the
# artifact away as rasterisation rather than a fault in the package.
#
# Choosing a resolution that makes the staff space an exact pixel count puts
# every line in the same phase, so they rasterise identically. 27 px per staff
# space needs 27 × 25.4 / 2.9 dpi, and of the candidates it also renders the line
# closest to its designed weight (1.87 px of ink against 2.02 nominal).
PPI=236.48

render() {
  local name="$1" file="$2" mode="$3" extra="${4-}"
  # shellcheck disable=SC2086
  typst compile --root "$root" "$root/docs/$file" "$tmp/$name-$mode-{p}.png" \
    --ppi "$PPI" --input "mode=$mode" $extra
  # Only ever page 1; a figure that spills is a figure that needs shortening.
  mv "$tmp/$name-$mode-1.png" "$tmp/$name-$mode.png"
  rm -f "$tmp/$name-$mode-"[0-9]*.png
}

for mode in light dark; do
  render hero hero.typ "$mode"
  render techniques showcase.typ "$mode" "--input figure=techniques"
  render ascii showcase.typ "$mode" "--input figure=ascii"
done

python3 - "$tmp" "$root/docs" <<'PY'
import pathlib
import sys

from PIL import Image

tmp, out = (pathlib.Path(p) for p in sys.argv[1:3])
MARGIN = 18

for src in sorted(tmp.glob("*.png")):
    im = Image.open(src).convert("RGB")
    # Crop to the drawn content rather than to the page, so the figure carries no
    # arbitrary white space into the README. The background is whatever the
    # corner pixel is, which is the page fill in both modes.
    bg = im.getpixel((0, 0))
    diff = Image.new("RGB", im.size, bg)
    from PIL import ImageChops

    box = ImageChops.difference(im, diff).convert("L").point(lambda v: 255 if v > 12 else 0).getbbox()
    if box is None:
        raise SystemExit(f"{src.name}: nothing drawn")
    left, top, right, bottom = box
    box = (
        max(0, left - MARGIN),
        max(0, top - MARGIN),
        min(im.width, right + MARGIN),
        min(im.height, bottom + MARGIN),
    )
    im.crop(box).save(out / src.name, optimize=True)
    print(f"  {src.name}  {box[2] - box[0]}×{box[3] - box[1]}")
PY

printf '\n%s\n' "wrote $(ls -1 "$root/docs"/*.png | wc -l) image(s), $(du -sh "$root/docs" | cut -f1) total"
