# The fretwork guide

How to use the package, and every construct it understands with what that
construct draws set beside it.

The rendering beside each row is produced by the package from the syntax beside
it. The chapters in [`docs/guide/`](docs/guide/) are the source of both: an
example is written once, and `docs/build-guide.py` renders that same string, so
a row cannot drift from what it documents.

Regenerate with `docs/build.sh`. `GUIDE.md` is written by it — edit the
chapters, not this file.

For the reasoning behind the design, see [SPEC.md](SPEC.md). For a working
sheet, see [`examples/songsheet.typ`](examples/songsheet.typ).
