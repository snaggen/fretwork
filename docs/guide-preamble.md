# Writing tablature with fretwork

Every construct the package understands, the syntax for it, and what that syntax
draws, followed by a chapter on reading pasted ASCII tab. The rendering beside
each row is produced from the syntax beside it by the package itself —
[`docs/guide.typ`](docs/guide.typ) uses each string twice, once set as code and
once handed to `tab`, so a row cannot drift from what it documents.

Regenerate with `docs/build.sh`; the rest of this file is written by it.

For the reasoning behind the design, see [SPEC.md](SPEC.md). For a working
sheet, see [`examples/songsheet.typ`](examples/songsheet.typ).
