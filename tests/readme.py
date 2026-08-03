#!/usr/bin/env python3
"""Compile every Typst snippet in README.md.

Typst Universe parses the README with the Typst parser and reports what it
finds, so a snippet that only *looks* like Typst becomes a public review
comment. That happened once: an elided example written as ```` ```…``` ````
made the parser read `…` as a language tag, and the submission came back with
"no whitespace before raw text".

Snippets are rendered against the working tree rather than the published
package, so this also catches a snippet the code has outgrown.

    tests/readme.py
"""

import pathlib
import re
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
README = ROOT / "README.md"

# The snippets import the published package, which is not what we want to test.
PUBLISHED = re.compile(r'^#import "@preview/fretwork:[^"]*"', re.MULTILINE)
LOCAL = '#import "/src/lib.typ"'

# Montserrat is the designed-against font and is deliberately not a dependency:
# the README's own Fonts section explains this warning and how to silence it.
# Whether it is installed is a property of the machine, not of the README.
IGNORED = "unknown font family"


def snippets(text: str) -> list[tuple[int, str]]:
    """Every ```typst fenced block, as (first line number, source)."""
    found, lines, i = [], text.split("\n"), 0
    while i < len(lines):
        if lines[i].startswith("```typst"):
            end = i + 1
            while end < len(lines) and lines[end] != "```":
                end += 1
            found.append((i + 2, "\n".join(lines[i + 1 : end])))
            i = end
        i += 1
    return found


def check(line: int, src: str) -> bool:
    """Compile one snippet; return True if it is clean."""
    if PUBLISHED.search(src):
        src = PUBLISHED.sub(LOCAL, src)
    else:
        src = LOCAL + ": *\n\n" + src
    # Inside the repository, because Typst refuses to compile a file outside its
    # root and the root has to be the repository for `/src/lib.typ` to resolve.
    with tempfile.NamedTemporaryFile("w", dir=ROOT, suffix=".typ") as f:
        f.write(src + "\n")
        f.flush()
        with tempfile.TemporaryDirectory() as tmp:
            result = subprocess.run(
                ["typst", "compile", "--root", str(ROOT), f.name, f"{tmp}/out.pdf"],
                capture_output=True,
                text=True,
            )
    noise = [
        block
        for block in re.split(r"\n(?=(?:error|warning): )", result.stderr.strip())
        if block and IGNORED not in block.split("\n")[0]
    ]
    if not noise:
        print(f"  ok    README.md:{line}")
        return True
    print(f"  FAIL  README.md:{line}")
    for block in noise:
        print("".join(f"        {ln}\n" for ln in block.split("\n")), end="")
    return False


def main() -> int:
    return sum(0 if check(line, src) else 1 for line, src in snippets(README.read_text()))


if __name__ == "__main__":
    sys.exit(main())
