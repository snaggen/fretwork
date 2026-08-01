# tablature

Guitar tablature of publishing quality for Typst — rhythm stems, technique
symbols, and ASCII tab import.

Existing Typst packages either draw chord diagrams or render standard notation;
none sets a guitar tab that looks like a published song sheet. This one does:
optical spacing, string lines broken around the fret numbers, beams grouped by
the beat, and the technique symbols from Hal Leonard's *Guitar Notation Legend*.

No font is required. Every music symbol is a vector curve, because Typst
packages cannot ship fonts.

## Install

Not yet published. For local use:

```sh
git clone https://github.com/snaggen/tablature
ln -s "$PWD/tablature" ~/.local/share/typst/packages/local/tablature/0.1.0
```

Then `#import "@local/tablature:0.1.0": *`.

Running text looks best in Montserrat, which is not bundled with Typst. Install
it, or let the fallback chain (`Montserrat`, `Inter`, `Noto Sans`) pick what you
have. Music symbols are unaffected.

## Quick start

```typst
#import "@local/tablature:0.1.0": *

#show: song.with(
  title: "T.N.T.",
  words: "Angus Young, Malcolm Young and Bon Scott",
  music: "Angus Young, Malcolm Young and Bon Scott",
  copyright: "Copyright © 1975 J. Albert & Son Pty., Ltd.",
  tempo: 127,
  tempo-words: "Moderate Rock",
)

#section("Main Riff")

#tab(```
|: @E5 e 0/6 0/6 {PM: 0/6 0/6 0/6 0/6 0/6 0/6}
 |  @G5 q 3/6 3/6 @A5 5/6 5/6 :|
```)
```

A note is `fret/string`, string 1 being the highest. Note values (`w h q e s t`,
with `.` for dotted) are sticky — write one only when it changes. `|` is a
barline, `|:` and `:|` are repeats, `@E5` names a chord, and `{PM: … }` brackets
a span.

Techniques are suffixes after the string number:

```typst
#tab(```
q 5/3h7 7/3p5 e 5/3s7 7/3b 7/3br q 12/3* 7/3v
```)
```

`h` hammer-on, `p` pull-off, `s`/`S` slide, `b` bend (`br` release, `B`
pre-bend), `v`/`V` vibrato, `*` harmonic, `~` tie, `g` ghost, `>` accent,
`n`/`u` down- and upstroke. See [`SPEC.md`](SPEC.md) for the full table.

## ASCII tab

Paste a tab and it renders:

```typst
#ascii-tab(```
e|-----------------|-----------------|
B|-----5h7---------|--------------8--|
G|--2--------------|-----7b9---------|
D|--2----------7\5-|-----------------|
A|--0--------------|--10-------------|
E|--------3--------|-----------------|
```)
```

ASCII tab carries no rhythm, so this gets no stems or beams — it is spaced from
the source's own columns. Everything missing can be supplied, a little at a
time. Column-aligned annotation rows are the main way:

```typst
#ascii-tab(```
S:   Main Riff
C:   E5      G5
R:   q   q   e e
PM:  --------
e|---0---2---3-5--|
…
```)
```

`R:` note values, `C:` chord names, `S:` a section heading, `T:` a playing
instruction, `PM:`/`LR:` bracketed spans. `R:` uses the same tokens as the
native syntax.

When the rhythm is regular, one argument does the job instead:

```typst
#ascii-tab(source, rhythm: even(1/8))
```

`#ascii-to-dsl(source)` prints the equivalent native source, for when an
imported tab is worth keeping.

## Examples

```sh
typst compile --root . examples/tnt.typ      # a full song sheet
typst compile --root . examples/ascii.typ    # ASCII import, enriched in stages
typst compile --root . examples/glyphs.typ   # every vector glyph, three sizes
```

## Tests

```sh
./tests/run.sh          # everything
./tests/run.sh dsl      # one suite
```

Each test is a Typst document whose assertions panic on failure, so the
compiler's exit status is the result. `tests/errors/` holds fixtures that must
*fail*, each declaring the message it expects.

## Scope

Version 0.1 is tablature only — no notation staff, chord diagrams or lyrics. The
model and layout engine are built so a notation staff can be added without
rewriting them; [`SPEC.md`](SPEC.md) says how.

## Licence

EUPL-1.2. See [`LICENSE`](LICENSE).
