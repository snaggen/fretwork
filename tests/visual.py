#!/usr/bin/env python3
"""Image-regression tests: render each visual fixture and compare it to a
pinned reference.

Every visual defect this package has had — a slur merging with the line above,
a smooth path closure growing a spike, a chord slur attaching one string too
high, a technique lane silently dropping an argument — was found by looking at
the output, and none of them made a single assertion fail. That is what this
covers: `tests/run.sh` proves the documents compile and the model is right, and
this proves the pixels have not moved.

    tests/visual.py                 compare against the references
    tests/visual.py --update        re-render the references
    tests/visual.py slurs bends     just those fixtures

A mismatch writes a diff image, tinting the changed pixels, and names the path.

Rendering is only reproducible for a given renderer and a given set of fonts, so
the references record both. When they do not match, comparison **skips** rather
than fails — a reference rendered by another Typst version says nothing about
whether this change was correct, and a test that cries wolf on an unrelated
upgrade is a test people learn to ignore. `--update` after a deliberate upgrade
is the way through, with the re-rendered images reviewed in the diff.
"""

import argparse
import json
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

from PIL import Image, ImageChops

PPI = 120

ROOT = pathlib.Path(__file__).resolve().parent.parent
FIXTURES = ROOT / "tests" / "visual"
REFS = ROOT / "tests" / "refs"
DIFFS = REFS / "diff"

# Fonts the fixtures name, which therefore have to be present for a render to
# mean the same thing twice. `_common.typ` pins these deliberately rather than
# using the theme default, which is a variable font not every machine has.
REQUIRED_FONTS = ["DejaVu Sans"]

# How much a pixel may differ before it counts as changed. Rendering is
# deterministic on one machine, so this exists for the antialiasing seam that
# an unrelated version bump can shift by a single level, not to absorb real
# movement — anything visible is far larger.
TOLERANCE = 8


def typst_version() -> str:
    out = subprocess.run(["typst", "--version"], capture_output=True, text=True).stdout
    match = re.search(r"\d+\.\d+\.\d+", out)
    return match.group(0) if match else out.strip()


def missing_fonts() -> list[str]:
    out = subprocess.run(["typst", "fonts"], capture_output=True, text=True).stdout
    have = set(out.splitlines())
    return [f for f in REQUIRED_FONTS if f not in have]


def environment() -> dict:
    return {"typst": typst_version(), "ppi": PPI, "fonts": REQUIRED_FONTS}


def fixtures(names: list[str]) -> list[pathlib.Path]:
    """The fixtures to run. Files starting with `_` are shared setup, not tests."""
    if names:
        return [FIXTURES / f"{n.removesuffix('.typ')}.typ" for n in names]
    return sorted(p for p in FIXTURES.glob("*.typ") if not p.name.startswith("_"))


def render(fixture: pathlib.Path, into: pathlib.Path) -> list[pathlib.Path]:
    """Render one fixture to PNG, one file per page. Returns them in page order."""
    out = into / f"{fixture.stem}-{{p}}.png"
    result = subprocess.run(
        ["typst", "compile", "--root", str(ROOT), str(fixture), str(out), "--ppi", str(PPI)],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip())
    return sorted(into.glob(f"{fixture.stem}-*.png"), key=lambda p: int(p.stem.split("-")[-1]))


def compare(ref: pathlib.Path, got: pathlib.Path) -> tuple[bool, str]:
    """Compare two renders. Returns whether they match, and what differs."""
    a = Image.open(ref).convert("RGB")
    b = Image.open(got).convert("RGB")
    if a.size != b.size:
        return False, f"size {a.size[0]}×{a.size[1]} → {b.size[0]}×{b.size[1]}"

    # Reduce the per-channel difference to one value per pixel, then count the
    # pixels that moved by more than the antialiasing tolerance.
    diff = ImageChops.difference(a, b).convert("L")
    mask = diff.point(lambda v: 255 if v > TOLERANCE else 0)
    changed = a.size[0] * a.size[1] - mask.histogram()[0]
    if changed == 0:
        return True, ""

    DIFFS.mkdir(parents=True, exist_ok=True)
    # The new render, with everything that moved tinted red, so the eye goes
    # straight to it rather than hunting between two images.
    tinted = b.copy()
    tinted.paste(Image.new("RGB", b.size, (220, 40, 40)), mask=mask)
    path = DIFFS / got.name
    tinted.save(path)
    pct = 100 * changed / (a.size[0] * a.size[1])
    return False, f"{changed} pixels ({pct:.3f}%) → {path.relative_to(ROOT)}"


def update(names: list[str]) -> int:
    missing = missing_fonts()
    if missing:
        print(f"  refusing to pin references without {', '.join(missing)}")
        return 1

    REFS.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for fixture in fixtures(names):
            pages = render(fixture, pathlib.Path(tmp))
            # Drop stale pages, so a fixture that gets shorter does not leave a
            # reference behind that nothing renders any more.
            for old in REFS.glob(f"{fixture.stem}-*.png"):
                old.unlink()
            for page in pages:
                shutil.copy(page, REFS / page.name)
            print(f"  pinned  {fixture.stem} ({len(pages)} page(s))")

    (REFS / "manifest.json").write_text(json.dumps(environment(), indent=2) + "\n")
    shutil.rmtree(DIFFS, ignore_errors=True)
    return 0


def check(names: list[str]) -> int:
    manifest_path = REFS / "manifest.json"
    if not manifest_path.exists():
        print("  no references pinned yet — run tests/visual.py --update")
        return 0

    manifest = json.loads(manifest_path.read_text())
    here = environment()
    if manifest != here:
        print(f"  skipped — references were pinned by {manifest['typst']} at {manifest['ppi']} ppi")
        print(f"            this is {here['typst']} at {here['ppi']} ppi")
        missing = missing_fonts()
        if missing:
            print(f"            and {', '.join(missing)} is not installed")
        print("            re-render with tests/visual.py --update and review the diff")
        return 0

    shutil.rmtree(DIFFS, ignore_errors=True)
    failed = 0
    with tempfile.TemporaryDirectory() as tmp:
        for fixture in fixtures(names):
            try:
                pages = render(fixture, pathlib.Path(tmp))
            except RuntimeError as err:
                print(f"  FAIL  visual/{fixture.stem}\n{err}")
                failed += 1
                continue

            refs = sorted(REFS.glob(f"{fixture.stem}-*.png"))
            if len(refs) != len(pages):
                print(
                    f"  FAIL  visual/{fixture.stem} "
                    f"({len(refs)} reference page(s), rendered {len(pages)})"
                )
                failed += 1
                continue
            if not refs:
                print(f"  FAIL  visual/{fixture.stem} (no reference — run --update)")
                failed += 1
                continue

            problems = []
            for page in pages:
                same, why = compare(REFS / page.name, page)
                if not same:
                    problems.append(f"{page.name}: {why}")
            if problems:
                print(f"  FAIL  visual/{fixture.stem}")
                for problem in problems:
                    print(f"        {problem}")
                failed += 1
            else:
                print(f"  ok    visual/{fixture.stem}")
    return failed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--update", action="store_true", help="re-render the references")
    parser.add_argument("names", nargs="*", help="fixtures to run (default: all)")
    args = parser.parse_args()
    return update(args.names) if args.update else check(args.names)


if __name__ == "__main__":
    sys.exit(main())
