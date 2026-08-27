# Writing tablature with fretwork

Every construct the package understands, the syntax for it, and what that syntax
draws, followed by a chapter on reading pasted ASCII tab.

The rendering beside each row is produced from the syntax beside it by the
package itself. The chapters in [`docs/guide/`](docs/guide/) are the source of
both: an example is written once, and `docs/build-guide.py` renders that same
string, so a row cannot drift from what it documents.

Regenerate with `docs/build.sh`. `GUIDE.md` is written by it — edit the chapters,
not this file.

For the reasoning behind the design, see [SPEC.md](SPEC.md). For a working
sheet, see [`examples/songsheet.typ`](examples/songsheet.typ).
