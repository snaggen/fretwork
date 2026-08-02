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

### Fonts

Running text looks best in Montserrat, which Typst does not bundle. Google Fonts
now ships it as two variable files, and Typst instantiates every weight the
package asks for from them:

```sh
mkdir -p ~/.local/share/fonts/montserrat
base=https://raw.githubusercontent.com/google/fonts/main/ofl/montserrat
curl -sL -o "$HOME/.local/share/fonts/montserrat/Montserrat[wght].ttf" \
  "$base/Montserrat%5Bwght%5D.ttf"
curl -sL -o "$HOME/.local/share/fonts/montserrat/Montserrat-Italic[wght].ttf" \
  "$base/Montserrat-Italic%5Bwght%5D.ttf"
fc-cache -f ~/.local/share/fonts
```

**Installing it also silences Typst's font warnings.** The default chain is
`("Montserrat", "Noto Sans", "DejaVu Sans")`, and Typst warns once per family it
cannot find — even when a later one in the chain matches — so a machine without
Montserrat gets about fifteen `unknown font family: montserrat` warnings per
compile. The count does not grow with the document, and the sheet still sets
correctly in Noto Sans; the warnings just name what to install.

To silence them without installing anything, pass a chain of fonts you do have:

```typst
#tab(theme: theme(font: ("Noto Sans", "DejaVu Sans")), ```…```)
```

Music symbols are unaffected either way — they are vectors, not glyphs.

## Quick start

```typst
#import "@local/tablature:0.1.0": *

#show: song.with(
  title: "Twelve Past Nine",
  words: "A. Guitarist",
  music: "A. Guitarist",
  copyright: "© 2026 A. Guitarist",
  tempo: 132,
  tempo-words: "Driving Rock",
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
typst compile --root . examples/demo.typ       # a tour of everything
typst compile --root . examples/songsheet.typ # a complete song sheet
typst compile --root . examples/ascii.typ     # ASCII import, enriched in stages
typst compile --root . examples/bends.typ     # bend arrows on every string
typst compile --root . examples/glyphs.typ    # every vector glyph, three sizes
```

## Tests

```sh
./tests/run.sh          # everything
./tests/run.sh dsl      # one suite
```

Each test is a Typst document whose assertions panic on failure, so the
compiler's exit status is the result. `tests/errors/` holds fixtures that must
*fail*, each declaring the message it expects.

## Themes

Everything derives from one unit, so `theme(staff-space: 3.2mm)` rescales a sheet
without its proportions drifting. `mask: "box"` prints fret numbers on an opaque
patch instead of breaking the string lines, and `repeat-style: "ornate"` gives
repeat signs the flared serifs of an engraved one.

```typst
#tab(theme: theme(staff-space: 3.2mm, repeat-style: "ornate"), ```
|: q 0/6 3/6 5/6 3/6 :|
```)
```

## Scope

Version 0.1 is tablature only — no notation staff, chord diagrams or lyrics. The
model and layout engine are built so a notation staff can be added without
rewriting them; [`SPEC.md`](SPEC.md) says how.

## Licence

EUPL-1.2. See [`LICENSE`](LICENSE).
