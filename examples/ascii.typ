// Importing ASCII tab, in four stages.
//
// The same source is rendered raw, then with note values, then with chord names
// and a section, then fully annotated. Nothing is required: each stage only adds
// information, and every stage renders.
//
// Compile with `typst compile --root . examples/ascii.typ`.

#import "/src/lib.typ": *

#show: song.with(
  title: "Progressive enrichment",
  subtitle: "The same ASCII tab, told more each time",
  source: "fretwork",
)

#let riff = "
e|------------------|------------------|
B|------------------|------------------|
G|------------------|--------------7---|
D|--------------7---|------------------|
A|--0---2---3-------|--0---2---3-------|
E|------------------|------------------|
"

#section("1 — as pasted")

Nothing but fret positions. The layout follows the source's own columns, so it
is spaced the way its author laid it out, but there is no rhythm to show.

#ascii-tab(riff)

#section("2 — with note values")

An `R:` row supplies the rhythm. Note values are sticky, exactly as in the
native syntax, so only changes need writing. Stems, beams and optical spacing
all follow.

#ascii-tab("
R:   q   q   e   e     q   q   e   e
" + riff)

#section("3 — with chord names")

A `C:` row names chords at the columns they fall on.

#ascii-tab("
C:   A5      C5        A5      C5
R:   q   q   e   e     q   q   e   e
" + riff)

#section("4 — fully annotated")

A `PM:` row brackets a palm mute over the columns it covers, and a `T:` row adds
a playing instruction.

#ascii-tab("
C:   A5      C5        A5      C5
R:   q   q   e   e     q   q   e   e
PM:  ------------
T:            let ring
" + riff)

#section("The same riff, inferred")

When the rhythm is regular, `rhythm: even(1/8)` says so in one word instead of
annotating every column.

#ascii-tab(riff, rhythm: even(1 / 8))
