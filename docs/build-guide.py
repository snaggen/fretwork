#!/usr/bin/env python3
"""Build GUIDE.md from the chapters in docs/guide/.

The guide is Markdown so that a reader can search it: headings, prose, tables
and the syntax itself are text on the page, and only the staff — the one thing
nobody searches for — is an image.

The chapters are the *source* of the examples, not a description of them. An
example is written once, and this script renders that same string and writes the
picture next to it, so a row cannot drift from what it documents. That is the
invariant `docs/guide.typ` used to keep by using each string twice; here there is
only one string.

Two ways to write an example:

    <!-- fretwork-table -->        a two-column table; a third column of
    | What it is | Syntax |        renderings is written by this script
    |---|---|
    | A note | `5/3` |
    | Slap | `0/4SL` | <!-- tuning: tunings.bass -->

    ```fretwork                    a fenced block, rendered underneath it;
    q 5/3 5/3 5/3 5/3              `fretwork-ascii` goes through `ascii-tab`
    ```                            instead, and the info line may carry
                                   arguments the same way

Anything after the language on a fence's info line, and anything in the trailing
comment of a table row, is passed to `tab` verbatim as named arguments. These are
our own files, so that is a convenience rather than a hole.

Usage: docs/build-guide.py
"""

import html
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

from PIL import Image, ImageChops

ROOT = pathlib.Path(__file__).resolve().parent.parent
CHAPTERS = ROOT / "docs" / "guide"
IMG = CHAPTERS / "img"
OUT = ROOT / "GUIDE.md"

# Rendering. The examples are no longer squeezed into a table column of a paged
# document, so this is the staff space the package itself defaults to rather than
# the 2.1mm the old guide had to use. PAGE_WIDTH only bounds a line: every image
# is cropped to its ink, so a one-bar example does not carry the rest of the page
# with it.
PAGE_WIDTH = "150mm"
STAFF_SPACE = "2.6mm"
BBOX_PPI = 96  # only used to find the ink; the published image is vector
MARGIN_PT = 3.0

MODES = ("light", "dark")

# Markers.
TABLE = "<!-- fretwork-table -->"
FENCE = re.compile(r"^```fretwork(-ascii)?[ \t]*(.*)$")
ROW_ARGS = re.compile(r"\|[ \t]*<!--(.*?)-->[ \t]*$")
CODE_SPAN = re.compile(r"`([^`]*)`")
CELL = re.compile(r"(?<!\\)\|")


def typst_string(s):
    """A Typst string literal. Both parsers take one, multi-line examples and all."""
    body = s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
    return f'"{body}"'


class Example:
    """One rendered example: the source, how to render it, and where it lands."""

    def __init__(self, ident, src, args, ascii_tab):
        self.ident = ident
        self.src = src
        self.args = args.strip()
        self.ascii_tab = ascii_tab

    def call(self):
        fn = "ascii-tab" if self.ascii_tab else "tab"
        # `show-time` and `warn` are defaults the chapters may override, so they
        # are only written where the example has not spoken for itself —
        # repeating a named argument is an error in Typst.
        given = self.args
        extra = ""
        if "show-time" not in given:
            extra += ", show-time: false"
        if "warn" not in given:
            extra += ", warn: false"
        if given:
            given = ", " + given
        return f"#{fn}({typst_string(self.src)}, theme: thm{extra}{given})"

    def alt(self):
        """What the picture shows, for a reader who cannot see it.

        The source itself, where it is short enough to read aloud; a multi-line
        paste is already on the page above the image, so pointing at it says
        more than repeating it would.
        """
        if "\n" in self.src:
            return "what fretwork draws from the tab above"
        return f"what fretwork draws from {self.src}"

    def picture(self):
        light = f"docs/guide/img/{self.ident}-light.svg"
        dark = f"docs/guide/img/{self.ident}-dark.svg"
        alt = html.escape(self.alt(), quote=True)
        return (
            f'<picture><source media="(prefers-color-scheme: dark)" srcset="{dark}">'
            f'<img alt="{alt}" src="{light}"></picture>'
        )


def scan(text, stem):
    """Pull every example out of one chapter, and return it with its examples.

    The chapter comes back rewritten: each example is replaced by a placeholder
    that `emit` fills in once the pictures exist. Reading and writing in two
    passes is what lets every example in the guide be rendered by one compile.
    """
    examples = []
    out = []
    lines = text.splitlines()
    i = 0
    row = None  # how far into a marked table we are, or None if outside one

    def ident():
        return f"{stem}-{len(examples):03d}"

    while i < len(lines):
        line = lines[i]

        if line.strip() == TABLE:
            row = 0
            i += 1
            continue

        fence = FENCE.match(line)
        if fence:
            end = i + 1
            while end < len(lines) and lines[end].rstrip() != "```":
                end += 1
            if end >= len(lines):
                raise SystemExit(f"{stem}: unclosed ```fretwork block at line {i + 1}")
            src = "\n".join(lines[i + 1 : end])
            ex = Example(ident(), src, fence.group(2), fence.group(1) is not None)
            examples.append(ex)
            if ex.args:
                out.append(f"`{ex.args}`")
                out.append("")
            out += ["```", src, "```", "", f"@@{ex.ident}@@", ""]
            i = end + 1
            continue

        if row is not None and line.startswith("|"):
            if row == 0:  # the header, which gains a column for the renderings
                out.append(line.rstrip() + " |")
            elif row == 1:  # its separator, which has to gain one too
                out.append(line.rstrip() + "---|")
            else:
                args = ROW_ARGS.search(line)
                body = line[: args.start() + 1] if args else line.rstrip()
                # The syntax is the last cell, and a cell is split on pipes that
                # the chapter has not escaped — `\|` is a barline inside a code
                # span, which GitHub needs escaped and the parser does not.
                cells = [c for c in CELL.split(body.strip().strip("|"))]
                span = CODE_SPAN.search(cells[-1]) if cells else None
                if span is None:
                    raise SystemExit(f"{stem}: table row with no syntax at line {i + 1}")
                src = span.group(1).replace("\\|", "|")
                ex = Example(ident(), src, args.group(1) if args else "", False)
                examples.append(ex)
                out.append(f"{body.rstrip().rstrip('|').rstrip()} | @@{ex.ident}@@ |")
            row += 1
            i += 1
            continue

        if row is not None and not line.startswith("|"):
            if row < 3:
                raise SystemExit(f"{stem}: marked table has no rows at line {i + 1}")
            row = None

        out.append(line)
        i += 1

    return "\n".join(out), examples


def render(examples):
    """Compile every example, once per colour scheme, one to a page."""
    try:
        _render(examples)
    finally:
        for leftover in ROOT.glob(".guide-build-*"):
            shutil.rmtree(leftover, ignore_errors=True)


def _render(examples):
    # Inside the repository: Typst will not compile a file outside `--root`, and
    # the root has to stay the package so that `/src/lib.typ` resolves.
    tmp = pathlib.Path(tempfile.mkdtemp(dir=ROOT, prefix=".guide-build-"))
    doc = tmp / "examples.typ"
    body = "\n#pagebreak()\n".join(ex.call() for ex in examples)
    doc.write_text(
        f"""// Generated by docs/build-guide.py. Do not edit.
#import "/src/lib.typ": *

#let dark = sys.inputs.at("mode", default: "light") == "dark"
#let ink = if dark {{ rgb("#e9e6e1") }} else {{ rgb("#101010") }}
#let paper = if dark {{ rgb("#1c1c1e") }} else {{ white }}
#let faint = if dark {{ rgb("#8b8b8f") }} else {{ luma(105) }}
#let thm = theme(color: ink, faint: faint, staff-space: {STAFF_SPACE})

#set page(width: {PAGE_WIDTH}, height: auto, margin: 2mm, fill: paper)
#set text(font: thm.font, fill: ink, size: 9pt)
#set par(justify: false)

{body}
"""
    )

    def compile_to(target, mode, ppi=None):
        cmd = ["typst", "compile", "--root", str(ROOT), str(doc), target,
               "--input", f"mode={mode}"]
        if ppi:
            cmd += ["--ppi", str(ppi)]
        subprocess.run(cmd, check=True)

    # The ink is found on a raster of the light pass and reused for the dark one:
    # the two differ in colour and in nothing else, so the box is the same box.
    compile_to(str(tmp / "bbox-{p}.png"), "light", BBOX_PPI)
    boxes = [ink_box(tmp / f"bbox-{i + 1}.png") for i in range(len(examples))]

    IMG.mkdir(parents=True, exist_ok=True)
    for f in IMG.glob("*.svg"):
        f.unlink()
    for mode in MODES:
        compile_to(str(tmp / f"{mode}-{{p}}.svg"), mode)
        for i, ex in enumerate(examples):
            svg = (tmp / f"{mode}-{i + 1}.svg").read_text()
            (IMG / f"{ex.ident}-{mode}.svg").write_text(crop(svg, boxes[i]))


def ink_box(png):
    """The drawn content's box, as a fraction of the page in each direction."""
    im = Image.open(png).convert("RGB")
    flat = Image.new("RGB", im.size, im.getpixel((0, 0)))
    mask = ImageChops.difference(im, flat).convert("L").point(lambda v: 255 if v > 12 else 0)
    box = mask.getbbox()
    if box is None:
        raise SystemExit(f"{png.name}: nothing drawn")
    left, top, right, bottom = box
    return (left / im.width, top / im.height, right / im.width, bottom / im.height)


def crop(svg, box):
    """Narrow an SVG's viewport to the ink, with a small margin.

    Typst writes the page size into `viewBox`, `width` and `height`; moving the
    viewport is what crops, since an `<img>` clips to it. Cropping here rather
    than in the raster is the point of using SVG at all — the published image is
    still the vector one.
    """
    m = re.search(r'viewBox="0 0 ([\d.]+) ([\d.]+)"', svg)
    if m is None:
        raise SystemExit("no viewBox in SVG output")
    page_w, page_h = float(m.group(1)), float(m.group(2))
    x0 = max(0.0, box[0] * page_w - MARGIN_PT)
    y0 = max(0.0, box[1] * page_h - MARGIN_PT)
    x1 = min(page_w, box[2] * page_w + MARGIN_PT)
    y1 = min(page_h, box[3] * page_h + MARGIN_PT)
    w, h = x1 - x0, y1 - y0
    svg = svg.replace(m.group(0), f'viewBox="{x0:.3f} {y0:.3f} {w:.3f} {h:.3f}"', 1)
    svg = re.sub(r'\swidth="[\d.]+pt"', f' width="{w:.3f}pt"', svg, count=1)
    svg = re.sub(r'\sheight="[\d.]+pt"', f' height="{h:.3f}pt"', svg, count=1)
    return svg


def main():
    chapters = sorted(CHAPTERS.glob("*.md"))
    if not chapters:
        raise SystemExit(f"no chapters in {CHAPTERS}")

    parts, examples = [], []
    for chapter in chapters:
        stem = chapter.stem.split("-", 1)[0]
        text, found = scan(chapter.read_text(), stem)
        parts.append(text.rstrip())
        examples += found

    render(examples)

    guide = "\n\n".join(parts) + "\n"
    for ex in examples:
        guide = guide.replace(f"@@{ex.ident}@@", ex.picture())
    left = re.findall(r"@@[\w-]+@@", guide)
    if left:
        raise SystemExit(f"unresolved example placeholders: {left}")
    OUT.write_text(guide)

    size = sum(f.stat().st_size for f in IMG.glob("*.svg"))
    print(f"  GUIDE.md: {len(chapters)} chapter(s), {len(examples)} example(s), "
          f"{len(list(IMG.glob('*.svg')))} image(s), {size / 1024:.0f} kB")


if __name__ == "__main__":
    sys.exit(main())
