#!/usr/bin/env bash
# Render the README illustrations and the user guide, light and dark.
#
# Typst Universe renders the README in the reader's own colour scheme, so every
# figure exists twice and the README picks between them with a <picture> element.
# The images are committed (Universe needs them) but excluded from the package
# bundle, since nothing importing the package ever reads them.
#
# The figures are cropped to their ink so they carry no arbitrary white space.
#
# The guide is built by `docs/build-guide.py`, which this script runs last: its
# examples are vector rather than raster and are cropped by their own viewport,
# so none of the resolution reasoning below applies to them.
#
# Usage: docs/build.sh
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# --- resolution ------------------------------------------------------------
#
# Everything is rasterised at 40 pixels per staff space and then scaled down to
# the size it is published at. That number is not arbitrary: a staff line is
# 0.075 of a staff space, so 40 px per space makes the line exactly 3 px, and
# both quantities are whole pixels at once.
#
# Both have to be. If the *spacing* is fractional, successive lines land in
# different sub-pixel phases and the staff comes out with lines of visibly
# different weight — which is what an earlier version of this script fixed by
# choosing a whole-pixel spacing. But that left the *line* at 1.2 px, and Typst
# renders a line of 1.2 px as one solid pixel row or two depending on where it
# falls, so whole staves came out at double weight while their neighbours did
# not. Measured on a page of the old raster guide: one page's lines were two
# solid rows and another's were one. Nothing in the package differed; only where
# the staff happened to land.
#
# Rendering where both are exact removes the choice: every line is 3 px of ink
# wherever it sits. Scaling down afterwards preserves the ink rather than
# re-rounding it, so every line arrives at the same weight on the page.
SRC_PER_SPACE=40

# Staff space of each document, in mm, and the pixels per space it is published
# at. `ppi = per-space × 25.4 / staff-space`.
FIG_SPACE_MM=2.9   # showcase.typ and hero.typ use the theme default
FIG_PER_SPACE=27

FIG_PPI="$(python3 -c "print($SRC_PER_SPACE * 25.4 / $FIG_SPACE_MM)")"
FIG_SCALE="$(python3 -c "print($FIG_PER_SPACE / $SRC_PER_SPACE)")"

render() {
  local name="$1" file="$2" mode="$3" extra="${4-}"
  # shellcheck disable=SC2086
  typst compile --root "$root" "$root/docs/$file" "$tmp/$name-$mode-{p}.png" \
    --ppi "$FIG_PPI" --input "mode=$mode" $extra
  # Only ever page 1; a figure that spills is a figure that needs shortening.
  mv "$tmp/$name-$mode-1.png" "$tmp/$name-$mode.png"
  rm -f "$tmp/$name-$mode-"[0-9]*.png
}

for mode in light dark; do
  render hero hero.typ "$mode"
  render techniques showcase.typ "$mode" "--input figure=techniques"
  render rhythm showcase.typ "$mode" "--input figure=rhythm"
  render ascii showcase.typ "$mode" "--input figure=ascii"
done

python3 - "$tmp" "$root/docs" "$FIG_SCALE" <<'PY'
import pathlib
import sys

from PIL import Image, ImageChops

tmp, out = (pathlib.Path(p) for p in sys.argv[1:3])
fig_scale = float(sys.argv[3])
MARGIN = 18


def downsample(im, scale):
    """Scale to the published size, preserving ink rather than re-rounding it.

    LANCZOS averages the source pixels, so a line that is 3 px of solid ink at
    the source arrives as the same amount of ink here wherever it happened to
    fall — which is the whole point of rendering large and scaling down.
    """
    size = (round(im.width * scale), round(im.height * scale))
    return im.resize(size, Image.LANCZOS)


def crop_to_ink(im):
    """Crop to the drawn content rather than to the page, so a figure carries no
    arbitrary white space into the README. The background is whatever the corner
    pixel is, which is the page fill in both modes."""
    bg = im.getpixel((0, 0))
    flat = Image.new("RGB", im.size, bg)
    mask = ImageChops.difference(im, flat).convert("L").point(lambda v: 255 if v > 12 else 0)
    box = mask.getbbox()
    if box is None:
        raise SystemExit("nothing drawn")
    left, top, right, bottom = box
    return im.crop((
        max(0, left - MARGIN),
        max(0, top - MARGIN),
        min(im.width, right + MARGIN),
        min(im.height, bottom + MARGIN),
    ))


for src in sorted(tmp.glob("*.png")):
    im = Image.open(src).convert("RGB")
    im = crop_to_ink(downsample(im, fig_scale))
    # Scaling down turns crisp edges into a spread of near-identical greys, which
    # PNG compresses badly — it nearly doubled the size of this directory. These
    # are two-tone line drawings; 64 levels is far more than they use. Measured
    # against the full-colour image the worst pixel differs by 5 of 255, and the
    # average by 0.04, for a little over a third of the bytes.
    im = im.quantize(colors=64, method=Image.MEDIANCUT)
    im.save(out / src.name, optimize=True)
    print(f"  {src.name}  {im.width}×{im.height}")
PY

"$root/docs/build-guide.py"

printf '\n%s\n' "wrote $(ls -1 "$root/docs"/*.png | wc -l) figure(s), $(du -sh "$root/docs" | cut -f1) total"
