// A tour of everything the package can set.
//
// Compile with `typst compile --root . examples/demo.typ`.

#import "/src/lib.typ": *

#let note(body) = block(
  above: 0.6em,
  below: 0.9em,
  text(size: 9.5pt, fill: luma(70), body),
)

#show: song.with(
  title: "tablature",
  subtitle: "A demonstration of the Typst package",
  words: "Mattias Eriksson",
  music: "Mattias Eriksson",
  source: "Package demo · v0.1.0",
  copyright: "Typeset with tablature · EUPL-1.2",
  tempo: 120,
  tempo-words: "Moderately",
)

= A song sheet

The page furniture above — source, title, credits, tempo indication, copyright
footer — comes from a single `song` show rule. Below is a riff with chord names,
palm muting and the count row a learner reads along with.

#section("Main Riff")

#tab(
  count-in: true,
  ```
  |: @E5 e 0/6 0/6 {PM: 0/6 0/6 0/6 0/6 0/6 0/6}
   |  @G5 q 3/6 3/6 @A5 5/6 5/6
   |  @E5 e 0/6 0/6 {PM: 0/6 0/6 0/6 0/6 0/6 0/6}
   |  @A5 q 5/6> 5/6> h 7/6v :|
  ```,
)

= Note values

Values are sticky, so only a change needs writing. Stems hang from beams grouped
by the beat, and everything longer than a quarter carries a hollow head — with no
notation staff underneath there is nothing else to tell a half note from a
quarter.

#note[`w 0/6 | h 0/6 0/6 | q 0/6 0/6 0/6 0/6 | e 0/6 0/6 0/6 0/6 0/6 0/6 0/6 0/6 | s ...`]

#tab(```
w 0/6 | h 0/6 0/6 | q 0/6 0/6 0/6 0/6
| e 0/6 0/6 0/6 0/6 0/6 0/6 0/6 0/6
| s 0/6 0/6 0/6 0/6 e 0/6 0/6 q 0/6 0/6
```)

Dots and rests, and a beat of sixteenths inside a beat of eighths — the second
beam covers only the notes fast enough to need it.

#note[`q. 0/6 e 2/6 h 3/6 | q 0/6 r 3/6 r | e 0/6 s 0/6 0/6 e 0/6 0/6 q 0/6`]

#tab(```
q. 0/6 e 2/6 h 3/6 | q 0/6 r 3/6 r | e 0/6 s 0/6 0/6 e 0/6 0/6 q 0/6
```)

Tuplets are groups with a numeric name.

#note[`{3: e 0/6 2/6 3/6} {3: e 5/6 3/6 2/6} {5: s 0/6 2/6 3/6 5/6 3/6} q 0/6`]

#tab(```
{3: e 0/6 2/6 3/6} {3: e 5/6 3/6 2/6} {5: s 0/6 2/6 3/6 5/6 3/6} q 0/6
| {3: q 0/6 3/6 5/6} {3: q 3/6 5/6 7/6} |.
```)

= Chords, dead strings and ties

A chord is notes in one column. A tie carries a note into the next one on the
same string, and `x` deadens a string — or all six at once.

#note[`q (0/1 2/2 2/3 1/4) (3/1 3/2 0/3 0/4) h (2/5 2/4 0/6)~ | w (2/5 2/4 0/6)`]

#tab(```
q (0/1 2/2 2/3 1/4) (3/1 3/2 0/3 0/4) h (2/5 2/4 0/6)~ | w (2/5 2/4 0/6)
| q x x/5 (x/1 x/2 x/3) x |.
```)

#pagebreak()

= Techniques

The symbol set follows Hal Leonard's _Guitar Notation Legend_. Marks anchored to
a string are drawn on the staff; marks that belong to the music as a whole get a
lane above it, and a lane nobody uses costs no vertical space.

Hammer-on, pull-off, legato slide, shift slide:

#tab(```
q 5/3h7 7/3p5 5/3s7 5/3S7 |.
```)

Bend, half-step bend, bend and release, pre-bend, pre-bend and release. A
pre-bend is already bent when the string is struck, so its arrow is straight —
the curve is what shows the pitch rising after the attack.

#tab(```
q 7/3b 7/3b(1/2) 7/3br 7/3B | h 7/3Br 7/3b(1/4) |.
```)

Vibrato, wide vibrato, natural harmonic, pinch harmonic:

#tab(```
q 7/3v 7/3V 12/3* 5/3PH |.
```)

Accent, marcato, staccato, tenuto; then downstroke, upstroke, tapping and a
ghost note:

#tab(```
q 7/3> 7/3^ 7/3! 7/3- | q 7/3n 7/3u 7/3T 7/3g |.
```)

Palm mute and let ring bracket whatever they are wrapped around, and a free
instruction can be written in quotes:

#tab(```
{PM: e 0/6 0/6 0/6 0/6} {LR: e (0/1 2/2 2/3) 0/6 0/6 0/6}
| "w/ bar" h 7/3V q 5/3s12 5/3 |.
```)

= Repeats and endings

#tab(```
|: q 0/6 0/6 0/6 0/6
 | {V1: q 3/6 3/6 3/6 3/6 :|}
   {V2: q 5/6 5/6 h 7/6 |.}
```)

= Another tuning

Tuning is a named argument on `tab`, and the sounding pitch of every note
follows from it — which is exactly what a notation staff would need if one were
added later, with no new syntax. Passing a tuning to `song` instead announces it
in the sheet's header, since that one applies to the whole piece.

#tab(
  tuning: tunings.drop-d,
  ```
  |: q (0/6 0/5 0/4) e 0/6 0/6 h (5/6 5/5 5/4)
   |  q (0/6 0/5 0/4) e 0/6 0/6 h (7/6 7/5 7/4) :|
  ```,
)

= Importing ASCII tab

A tab pasted from the web renders as it stands. It carries no rhythm, so there
are no stems — the layout follows the source's own columns instead.

#ascii-tab(```
e|-----------------|-----------------|
B|-----5h7---------|--------------8--|
G|--2--------------|-----7b9---------|
D|--2----------7\5-|-----------------|
A|--0--------------|--10-------------|
E|--------3--------|-----------------|
```)

Everything missing can be supplied, a little at a time. Column-aligned
annotation rows are the main way: `R:` note values, `C:` chord names, `PM:` a
bracketed span. Each attaches to exactly the column it sits over.

#ascii-tab(```
C:   E5          G5      A5
R:   q   q   e e h       q
PM:  --------
e|---0---2---3-5---------7--|
B|---0---2---3-5---------7--|
G|---1---2---4-6---------8--|
D|--------------------------|
A|--------------------------|
E|--------------------------|
```)

When the rhythm is regular, one argument replaces the annotation row entirely:

#ascii-tab(
  ```
  e|--------------------------|
  B|--------------------------|
  G|--------------------------|
  D|--------------7-----------|
  A|--0---2---3---------------|
  E|--------------------------|
  ```,
  rhythm: even(1 / 8),
)

= Themes

Everything derives from one unit, `staff-space`, so a sheet rescales without its
proportions drifting.

#block(breakable: false, grid(
  columns: (1fr, 1fr),
  column-gutter: 8mm,
  [
    #note[`theme(staff-space: 2.2mm)`]
    #tab(theme: theme(staff-space: 2.2mm), ```
    q 0/6 3/6 5/6 3/6
    ```)
  ],
  [
    #note[`theme(staff-space: 3.6mm)`]
    #tab(theme: theme(staff-space: 3.6mm), ```
    q 0/6 3/6 5/6 3/6
    ```)
  ],
))

A string line must never run through a fret number. By default the lines are
broken around the digits, which also works on a tinted page; `mask: "box"` puts
them on an opaque patch instead, as the published sheets do.

#tab(
  theme: theme(mask: "box", color: rgb("#1b3a5c")),
  ```
  q 10/6 12/5 e 11/4 9/3 7/2 5/1 q 24/1 0/6 |.
  ```,
)

#note[Frets 0 to 24 keep their columns straight because the numbers are set with
  tabular figures and each one's line gap follows its measured width.]

= Round-tripping

An annotated ASCII tab is as complete as one written by hand, so it can be
printed back out as native source and kept:

#note(raw(
  ascii-to-dsl("R:   q   q   e   e\n" + "e|---0---2---3---5--|\n" + "B|------------------|\n" + "G|------------------|\n" + "D|------------------|\n" + "A|------------------|\n" + "E|------------------|"),
  lang: "typst",
))
