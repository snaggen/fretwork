# Reworking the guide

Working notes for turning `GUIDE.md` from thirteen page images into a searchable
Markdown document, and for widening it from the tab syntax to the whole package.

**Status.** Phase 1 is done and phase 3 came with it, the syntax gaps being one
line each once the machinery existed. Phase 2 — looking at the result on
github.com — is the next thing, and phase 4 waits on it.

## The constraint that settles the format

The guide has to render **on github.com**, because that is where a reader
arriving from the Typst Universe page lands. GitHub renders Markdown and shows
`.html` as source text, so the deliverable is `GUIDE.md` and nothing else can
stand in for it.

That rules out the HTML route before any of its merits matter. Recorded anyway,
because it was worth knowing:

| | |
|---|---|
| `typst compile --format html` | refuses without `--features html` |
| with `--features html` | prose, headings and tables come out as clean semantic HTML |
| `tab()` inside it | **renders to nothing** — `layout()` is ignored in HTML export, and the whole package is built on it |
| `html.frame(tab(…))` | works: the staff comes back as inline SVG, all `<path>`, no `font-family`, no external references |
| the feature itself | warns *"do not rely on this feature for production use cases"* |

So HTML export can produce a guide, and one day it may be the natural way to
build one. It cannot produce the file GitHub will show, and it is explicitly not
production-ready. Not the foundation to build on.

## The format

**Markdown for everything a reader might search for; one small image per
rendered example.**

Headings, prose, tables and the syntax itself become real Markdown. Only the
staff — the one thing nobody searches for — stays an image. That inverts today's
ratio, where every word in the guide is inside a PNG.

Measured, per example:

| | size | notes |
|---|---|---|
| SVG | 6–13 kB | resolution-independent, pure `<path>`, no fonts or external refs |
| PNG at 300 ppi | 5–9 kB | fixed resolution, blurs on a zoomed or high-DPI screen |

92 examples × 2 colour schemes lands at roughly 1.8 MB of SVG or 1.3 MB of PNG,
against the 4.5 MB of page images in `docs/` today. Either way the repository
gets smaller.

**Recommendation: SVG.** A staff is line art; it should stay crisp when a reader
zooms in, which is exactly when they are trying to see what a mark looks like.
The one thing to confirm before committing to it is that GitHub's image
sanitiser passes our SVGs — they contain nothing but `<path>`, which is the safe
subset, but that is reasoning rather than evidence. See *Verification* below.

Dark mode keeps the `<picture>` element the README already uses, so two files per
example.

## The invariant

`docs/guide.typ` exists so that *"each row's syntax column and rendering column
are the same string"*. Whatever replaces it has to keep that, or the guide starts
lying the first time a construct changes.

The proposal keeps it in a stronger form: **the Markdown is the source, and the
build renders the examples out of it.** The string a reader sees is not a copy of
the string that was rendered — it is that string.

### Source layout

```
docs/guide/01-getting-started.md    chapters, written as Markdown
docs/guide/02-song-sheet.md
…
docs/guide-render.typ               a small renderer: one example per page
docs/build-guide.py                 scans, renders, writes GUIDE.md
```

`docs/guide.typ` goes away. Once the guide is Markdown, Typst no longer typesets
a document — it renders 92 small examples. That also retires the constraints the
current file works under: the 195 × 262 mm page, the 47 % column, and the
`staff-space: 2.1mm` chosen *"to fit a table column"*.

### Two ways to write an example

**In a table**, for the reference sections, which is what makes them scannable —
the third column is written by the build:

```markdown
<!-- fretwork-table -->
| What it is | Syntax |
|---|---|
| A note: fret over string | `5/3` |
| A chord: one column | `(2/5 2/4 0/6)` |
```

**As a fenced block**, for the ASCII chapter and for examples too long for a
cell — the image is inserted after it:

````markdown
```fretwork
|: q 5/3 5/3 | {V1: q 7/3 7/3 :|} {V2: q 8/3 8/3 |.}
```
````

Eleven of the 83 present rows need arguments passed to `tab` — a tuning, a
count-in, a lyric line. Those carry a trailing comment, which is the only piece
of syntax the format invents:

```markdown
| Slap, pop | `0/4SL 3/3PO` | <!-- tuning: tunings.bass -->
```

### The build

1. Scan the chapters in order; collect every example with its source, its
   arguments and a stable id (chapter + index).
2. Generate `docs/guide-examples.typ` from that list and compile it twice, once
   per colour scheme, one example per page at `height: auto`. Verified: Typst
   gives each page its own height, and `{p}` templating emits one file per page
   for both SVG and PNG.
3. Crop each to its ink — `docs/build.sh` already has `crop_to_ink` for the
   README figures — and write `docs/guide-<id>-<mode>.svg`.
4. Concatenate the chapters into `GUIDE.md`, inserting each `<picture>`.

An example whose id no longer resolves is a hard error, not a broken image.

## What the guide is missing

The tab **syntax** is in good shape: 83 rows covering nearly every token in
`SPEC.md`. Parsing every example with the DSL and collecting the technique kinds
it produces gives `accent arpeggiate bar-vibrato bend dead-slap fermata ghost
hammer harmonic marcato pop pull rake scrape slap slide staccato stroke tap tenuto
tie tremolo trill vibrato` — the whole set.

Small syntax gaps:

- `//` — a comment to end of line is documented in `SPEC.md` and nowhere in the guide.
- Bare `(…)A` and `(…)R`; the guide shows only `An`, `Au` and `Rn`, never `Ru`.
- The dynamics are shown as `!mf` and `!ff`; the closed set of eleven is never listed.
- *"Groups nest"* is a rule in `SPEC.md` with no example behind it.
- `capo` and `anacrusis` appear only in the ASCII chapter's prose, never demonstrated.

The real gap is the one you named: **the guide documents the notation and not the
package.** Nothing below appears anywhere in it.

| Missing | What it is |
|---|---|
| `song()` | the whole document wrapper — title, subtitle, words, music, arranged, artist, source, copyright, tempo, tempo-words, tempo-note-flags, paper, margin, and the running head on continuation pages |
| `section()` | section headings |
| `theme()` | every one of the eight options |
| `repeat-style: "ornate"` | the engraved repeat sign, mentioned only in the README |
| `mask: "box"` | the alternative to breaking the string lines |
| `lyric-extender` | the rule after a held word |
| `staff-space` | the one option that normally needs setting |
| `color`, `faint`, `font`, `lyric-font` | ink and type |
| the derived metrics | `theme(…) + (quarter-width: …, min-event-gap: …)` — the escape hatch for spacing is documented nowhere at all, not even in the README |
| `tunings` | eleven built-ins; the guide uses `tunings.bass` twice without ever saying the set exists |
| `tuning()` | writing one that is not built in |
| `tab()` arguments | `tempo`, `capo`, `anacrusis`, `verse-labels`, `warn`, `show-time` |
| `lyric-at()` | timed syllables — the headline feature of 0.3.0 |
| `render()` | rendering a part built in code rather than parsed |
| `ascii-to-dsl()` | converting a paste into DSL text |
| `even()`, `fill()` | the helpers for `rhythm:` |
| diagnostics | what a warning looks like, and `warn: false` |

## Proposed chapters

1. **Getting started** — importing, the smallest complete document, `song` + `section` + `tab`.
2. **The song sheet** — `song()` argument by argument, with the title block and footer rendered.
3. **Writing tablature** — today's twelve syntax tables, content unchanged, plus the small gaps above.
4. **Tunings and capo** — the eleven built-ins as a table, a custom `tuning()`, `capo:`, and bass, seven-string and ukulele examples.
5. **Appearance** — `theme()` option by option, each with the same bar rendered twice to show what it changes. This is where `ornate`, `mask` and the spacing metrics finally get shown.
6. **Lyrics** — today's table, plus several verses, `verse-labels` and `lyric-at()`.
7. **Pasted ASCII tab** — today's chapter, plus `rhythm:`, `even()`, `fill()` and `enrich:`.
8. **Diagnostics** — what the package tells you when it cannot read something.
9. **Reference** — every public name with its arguments, in one table to search.

## Phases

Each phase leaves the repository working and `GUIDE.md` readable.

**1 — Build the machinery, keep the content.** Write `build-guide.py` and
`guide-render.typ`; port the existing twelve tables and the ASCII chapter to
Markdown verbatim. Nothing new is documented. The measure of success is that the
new `GUIDE.md` says exactly what the old one said and is searchable. Delete
`docs/guide.typ` and `docs/guide-preamble.md`, and drop the guide branch from
`docs/build.sh`.

**2 — Verify on GitHub.** Push the branch and look at the file on github.com:
that the SVGs render, that `<picture>` picks the dark set, that images inside
table cells behave, and that the page is not absurdly long. Fall back to PNG if
the sanitiser objects. Do this before writing new chapters, so a format problem
costs one chapter and not nine.

**3 — Close the syntax gaps.** The five small omissions above. Cheap, and it
makes chapter 3 complete.

**4 — Write the new chapters.** In the order they earn their keep: Appearance
(5), Tunings (4), the song sheet (2), Getting started (1), the rest of Lyrics
(6), Diagnostics (8), Reference (9).

**5 — Point at it.** The README links to `GUIDE.md` at the release tag already;
check the link text still describes what the reader will find.

## Verification

- **GitHub's SVG sanitiser** — the one genuine unknown. Our SVGs are pure
  `<path>` with no `<text>`, no `font-family`, no external references, which is
  the subset GitHub is known to pass, but it has to be seen rather than reasoned
  about. Phase 2 exists for this.
- **Images in table cells** — GFM allows inline HTML in a cell provided it is on
  one line. The build writes the cells, so that is a property of the generator,
  worth a test.
- **Length** — nine chapters of 92 examples is a long page. If it reads badly as
  one file, split it into `docs/guide/*.md` with an index in `GUIDE.md`, which
  the source layout already allows.
- **Drift** — the invariant is what stops the guide going stale, so the build
  must fail loudly: an unresolved example id, an example that no longer parses,
  or an image with no example are all errors.

## What this does not change

`SPEC.md` stays what it is: the reasoning, not the manual. The guide says what to
write; the spec says why it draws that way. Nothing above moves content between
them.
