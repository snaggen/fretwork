#!/usr/bin/env python3
"""Check that no example document renders a diagnostic block.

`validate` reports bars that disagree with their time signature, and since `tab`
prints what it finds on the page, a wrong bar in an example is a red block in the
package's own showcase. Nothing checked for that, so they accumulated invisibly
while the reports were being swallowed, and surfaced all at once when they were
made visible — found one reader report at a time.

This reads the rendered PDFs rather than the sources, so it asserts exactly what
a reader sees. `demo.typ` ends with one report on purpose, where the text
explains it; that one is expected and its count is pinned.

    tests/examples.py            check every example
    tests/examples.py demo       check one
"""

import pathlib
import re
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
EXAMPLES = ROOT / "examples"

# How many diagnostics each example is allowed to print. Anything not listed
# must print none.
EXPECTED = {
    "demo": 1,  # the deliberate one, under the text that explains it
}

# A rendered diagnostic is `source + ": " + message`, and the source is always
# `tab` or `ascii-tab`. Requiring that prefix is what separates a real report
# from `demo.typ` printing `validate`'s return value as example text — the words
# are the same, but only the report carries the prefix.
MESSAGES = (
    "but the time signature calls for",
    "does not exist in tuning",
    "is above the 24th",
    "ignored line inside a tab block",
    "string rows, expected",
    "does not rise",
    "columns; ignored",
    "may be misaligned",
)
DIAGNOSTIC = re.compile(
    r"\b(?:ascii-)?tab: [^;]{0,80}?(?:" + "|".join(re.escape(m) for m in MESSAGES) + ")"
)


def diagnostics(path: pathlib.Path) -> list[str] | None:
    """Render one example and return the diagnostics it prints, or None if it
    fails to compile."""
    with tempfile.TemporaryDirectory() as tmp:
        pdf = pathlib.Path(tmp) / "out.pdf"
        result = subprocess.run(
            ["typst", "compile", "--root", str(ROOT), str(path), str(pdf)],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            return None
        txt = subprocess.run(
            ["pdftotext", "-nopgbrk", str(pdf), "-"], capture_output=True, text=True
        ).stdout
    # A diagnostic can wrap across lines, so flatten before matching.
    flat = re.sub(r"\s+", " ", txt)
    return [m.group(0) for m in DIAGNOSTIC.finditer(flat)]


def main() -> int:
    names = sys.argv[1:]
    files = (
        [EXAMPLES / f"{n.removesuffix('.typ')}.typ" for n in names]
        if names
        else sorted(EXAMPLES.glob("*.typ"))
    )
    failed = 0
    for path in files:
        found = diagnostics(path)
        if found is None:
            print(f"  FAIL  examples/{path.stem} (does not compile)")
            failed += 1
            continue
        allowed = EXPECTED.get(path.stem, 0)
        if len(found) == allowed:
            note = f" ({allowed} expected)" if allowed else ""
            print(f"  ok    examples/{path.stem}{note}")
        else:
            print(f"  FAIL  examples/{path.stem}: {len(found)} diagnostic(s), expected {allowed}")
            for f in found:
                print(f"        {f}")
            failed += 1
    return failed


if __name__ == "__main__":
    sys.exit(main())
