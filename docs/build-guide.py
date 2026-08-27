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

    ```fretwork-doc                a whole Typst document, compiled on its own
    #show: song.with(title: "…")   and shown as the page it makes
    #tab(```q 5/3```)
    ```

Anything after the language on a fence's info line, and anything in the trailing
comment of a table row, is passed to `tab` verbatim as named arguments, and is
printed above the example so that the reader sees what was passed. These are our
own files, so that is a convenience rather than a hole.

A `theme:` argument is the exception: it is merged with the guide's own ink
before rendering, so a chapter can demonstrate `repeat-style` or `mask` without
writing out the colours that make the picture legible in both colour schemes.
What it changes is presentation, never what the example says.

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
FENCE = re.compile(r"^```fretwork(-ascii|-doc)?[ \t]*(.*)$")
ROW_ARGS = re.compile(r"\|[ \t]*<!--(.*?)-->[ \t]*$")
CODE_SPAN = re.compile(r"`([^`]*)`")
CELL = re.compile(r"(?<!\\)\|")


def typst_string(s):
    """A Typst string literal. Both parsers take one, multi-line examples and all."""
    body = s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
    return f'"{body}"'


class Example:
    """One rendered example: the source, how to render it, and where it lands."""

    def __init__(self, ident, src, args, kind, in_table=False):
        self.ident = ident
        self.src = src
        self.args = args.strip()
        self.kind = kind  # "tab", "ascii" or "doc"
        self.in_table = in_table

    def call(self):
        fn = "ascii-tab" if self.kind == "ascii" else "tab"
        # A theme the chapter names is kept, with the guide's ink laid over it: a
        # theme is a plain dictionary, so the merge is the same one a reader
        # makes to reach a derived metric. Everything after `theme:` is the
        # expression, which is why it has to be the last argument given.
        given, _, expr = self.args.partition("theme:")
        if expr:
            # …except where the chapter is demonstrating the ink itself, in
            # which case its own choice is the whole point of the example.
            over = [f"{k}: {v}" for k, v in (("color", "ink"), ("faint", "faint"))
                    if f"{k}:" not in expr]
            theme = f"({expr.strip()})"
            if over:
                theme += " + (" + ", ".join(over) + ")"
        else:
            theme = "thm"
        given = given.strip().rstrip(",")
        # `show-time` and `warn` are defaults the chapters may override, so they
        # are only written where the example has not spoken for itself —
        # repeating a named argument is an error in Typst.
        extra = ""
        if "show-time" not in given:
            extra += ", show-time: false"
        if "warn" not in given:
            extra += ", warn: false"
        if given:
            given = ", " + given
        return f"#{fn}({typst_string(self.src)}, theme: {theme}{extra}{given})"

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
        # A whole document is a page of paper in either colour scheme, so it is
        # rendered once and both sources point at it.
        mode = "page" if self.kind == "doc" else "light"
        light = f"docs/guide/img/{self.ident}-{mode}.svg"
        dark = f"docs/guide/img/{self.ident}-{'page' if self.kind == 'doc' else 'dark'}.svg"
        alt = html.escape(self.alt(), quote=True)
        # A cell is split on pipes before any of it is read as HTML, so a
        # barline in the alt text ends the cell and spills the tag onto the page
        # as words. Markdown's own escape survives into the attribute.
        if self.in_table:
            alt = alt.replace("|", "\\|")
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
            kind = {"-ascii": "ascii", "-doc": "doc"}.get(fence.group(1), "tab")
            ex = Example(ident(), src, fence.group(2), kind)
            examples.append(ex)
            if ex.args:
                out.append(f"`{ex.args}`")
                out.append("")
            # A document example contains raw blocks of its own, so the fence
            # around it has to be longer than the longest run of backticks in
            # it — three inside three closes the block early.
            fence_len = max(3, max((len(m) for m in re.findall(r"`+", src)), default=0) + 1)
            bars = "`" * fence_len
            out += [bars, src, bars, "", f"@@{ex.ident}@@", ""]
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
                ex = Example(ident(), src, args.group(1) if args else "", "tab", in_table=True)
                examples.append(ex)
                cell = body.rstrip().rstrip("|").rstrip()
                # The arguments are shown, not hidden: a row rendered with a
                # tuning or a lyric line says so, or the reader is told the
                # syntax draws something the syntax alone does not.
                if ex.args:
                    cell += f" `{ex.args}`"
                out.append(f"{cell} | @@{ex.ident}@@ |")
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
    IMG.mkdir(parents=True, exist_ok=True)
    for f in IMG.glob("*.svg"):
        f.unlink()

    staves = [ex for ex in examples if ex.kind != "doc"]
    for ex in examples:
        if ex.kind == "doc":
            render_document(tmp, ex)
    if not staves:
        return

    doc = tmp / "examples.typ"
    body = "\n#pagebreak()\n".join(ex.call() for ex in staves)
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
    boxes = [ink_box(tmp / f"bbox-{i + 1}.png") for i in range(len(staves))]

    for mode in MODES:
        compile_to(str(tmp / f"{mode}-{{p}}.svg"), mode)
        for i, ex in enumerate(staves):
            svg = (tmp / f"{mode}-{i + 1}.svg").read_text()
            (IMG / f"{ex.ident}-{mode}.svg").write_text(crop(svg, boxes[i]))


def render_document(tmp, ex):
    """Render a whole-document example: its own compile, its own page.

    `song` sets the page, so it cannot share one with the staves — and a song
    sheet is paper whichever colour scheme the reader is in, so this is rendered
    once and shown in both. Only the first page: an example that spills onto a
    second is an example that wants shortening.
    """
    doc = tmp / f"{ex.ident}.typ"
    doc.write_text('#import "/src/lib.typ": *\n' + ex.src + "\n")
    for target, ppi in ((f"{ex.ident}-bbox-{{p}}.png", BBOX_PPI), (f"{ex.ident}-{{p}}.svg", None)):
        cmd = ["typst", "compile", "--root", str(ROOT), str(doc), str(tmp / target)]
        if ppi:
            cmd += ["--ppi", str(ppi)]
        subprocess.run(cmd, check=True)
    box = ink_box(tmp / f"{ex.ident}-bbox-1.png")
    svg = (tmp / f"{ex.ident}-1.svg").read_text()
    (IMG / f"{ex.ident}-page.svg").write_text(crop(svg, box))


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


def check_tables(guide):
    """Every row of a table must have as many cells as its header.

    A pipe that Markdown was not told to ignore ends the cell it is in, and the
    rest of the row lands on the page as words — which is how a barline inside an
    image's alt text once spilled an `<img` tag into the guide. The rows are
    written by this script, so it is the script that has to notice.
    """
    run, start = [], 0
    for number, line in enumerate(guide.splitlines() + [""], 1):
        if line.startswith("|"):
            if not run:
                start = number
            run.append((number, len(CELL.findall(line))))
            continue
        if run:
            width = run[0][1]
            for number, cells in run:
                if cells != width:
                    raise SystemExit(
                        f"GUIDE.md:{number}: row has {cells} cells, but the table "
                        f"opened at line {start} has {width} — an unescaped pipe?"
                    )
        run = []


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
    check_tables(guide)
    OUT.write_text(guide)

    size = sum(f.stat().st_size for f in IMG.glob("*.svg"))
    print(f"  GUIDE.md: {len(chapters)} chapter(s), {len(examples)} example(s), "
          f"{len(list(IMG.glob('*.svg')))} image(s), {size / 1024:.0f} kB")


if __name__ == "__main__":
    sys.exit(main())
