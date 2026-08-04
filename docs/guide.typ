// The user guide: every piece of syntax, with what it draws beside it.
//
// Rendered by `docs/build.sh` into `docs/guide-*.png`, which `GUIDE.md` embeds.
// Not part of the published bundle.
//
//   typst compile --root . docs/guide.typ --input mode=light out-{p}.png
//
// The point of building it in Typst rather than writing it out by hand is that
// each row's syntax column and rendering column are *the same string*. A row
// cannot drift from what it documents, and a change that breaks a construct
// breaks the guide with it.

#import "/src/lib.typ": *

#let dark = sys.inputs.at("mode", default: "light") == "dark"
#let ink = if dark { rgb("#e9e6e1") } else { rgb("#101010") }
#let paper = if dark { rgb("#1c1c1e") } else { white }
#let faint = if dark { rgb("#8b8b8f") } else { luma(105) }
#let rule = if dark { rgb("#3a3a3d") } else { luma(210) }
#let thm = theme(color: ink, faint: faint, staff-space: 2.1mm)

// Paged rather than one tall strip: `GUIDE.md` embeds the pages one after
// another, and a single image ten thousand pixels tall is unreadable at any
// width a browser will give it.
#set page(width: 195mm, height: 262mm, margin: (x: 10mm, y: 11mm), fill: paper)
#set text(font: thm.font, fill: ink, size: 9pt)
#set par(justify: false)

#let heading-style(body) = block(
  above: 1.6em,
  below: 0.7em,
  text(size: 13pt, weight: 700, body),
)
#let note(body) = block(below: 0.8em, text(size: 9pt, fill: faint, body))

/// One row: what it is with how it is written under it, and what that draws.
///
/// `src` is used twice — set as code and handed to `tab` — so the two can never
/// disagree. `..args` passes through to `tab` for the rows that need a tuning
/// or a count-in.
///
/// The name and the syntax share one column rather than taking one each,
/// because the columns have to be a fixed share of the page: with `auto`
/// widths, one long syntax string squeezes the rendering column for every row
/// of its table, and a squeezed one breaks its bars onto separate systems.
#let row(feature, src, ..args) = (
  {
    text(size: 8.5pt, feature)
    linebreak()
    text(size: 8.5pt, raw(src, lang: none))
  },
  tab(src, theme: thm, show-time: false, warn: false, ..args),
)

#let syntax-table(title, ..rows) = {
  heading-style(title)
  table(
    columns: (47%, 1fr),
    align: (left + horizon, left + horizon),
    inset: (x: 6pt, y: 5pt),
    stroke: (x, y) => (top: if y == 0 { none } else { 0.5pt + rule }),
    ..rows.pos().flatten(),
  )
}

= fretwork — writing tablature

#block(below: 1.2em, text(size: 10pt, [
  Every construct the package understands, the syntax for it, and what that
  syntax draws. The third column of each table is rendered from the second by
  the package itself, so nothing here can be out of date.

  A tab is a sequence of *events* separated by whitespace. An event is a note
  `fret/string`, a chord `(… …)`, or a rest `r`. Everything else — note values,
  techniques, spans — attaches to those.
]))

#syntax-table(
  "Notes and rests",
  row("A note: fret over string", "5/3"),
  row("String 1 is the highest-sounding", "0/1 0/2 0/3 0/4 0/5 0/6"),
  row("Two-digit frets need no marking", "11/3 1/3 1/3"),
  row("A chord: one column", "(2/5 2/4 0/6)"),
  row("A rest", "q 5/3 r 5/3 r"),
  row("A dead string", "x/5 5/3"),
  row("A whole dead strum", "x 5/3"),
)

#syntax-table(
  "Note values",
  row("Whole, half, quarter", "w 5/3 | h 5/3 5/3 | q 5/3 5/3 5/3 5/3"),
  row("Eighth, sixteenth, thirty-second", "e 5/3 5/3 s 5/3 5/3 5/3 5/3 t 5/3 5/3 5/3 5/3"),
  row("Values are sticky until changed", "e 5/3 5/3 q 7/3 7/3"),
  row("Dotted, doubly dotted", "q. 5/3 e 5/3 h.. 7/3"),
  row("Rests take the value in force", "h r q r e r r"),
  row("A tuplet", "{3: e 5/3 7/3 8/3} q 5/3"),
  row("…with an explicit ratio", "{5/4: s 5/3 7/3 8/3 7/3 5/3}"),
)

#syntax-table(
  "Left hand",
  row("Hammer-on", "5/3h7"),
  row("Pull-off", "7/3p5"),
  row("Legato slide — target not struck", "5/3s7"),
  row("Shift slide — target struck", "5/3S7"),
  row("Chained", "5/3h7p5"),
  row("Tie to the next strike", "5/3~ 5/3"),
  row("…on a whole chord", "(5/1 5/2 5/3)~ (5/1 5/2 5/3)"),
  row("Vibrato, wide vibrato", "5/3v 5/3V"),
  row("Trill, to a named fret", "5/3tr7 5/3tr"),
  row("Tapping", "5/3T 12/3T"),
  row("Grace note, before the beat", "q g 3/3 5/3 5/3 5/3 5/3"),
  row("Grace note, on the beat", "q G 3/3 5/3 5/3 5/3 5/3"),
  row("…and a grace hammer-on", "q g 3/3h5 5/3 5/3 5/3"),
)

#syntax-table(
  "Bends",
  row("A whole-step bend", "7/3b"),
  row("A half-step bend", "7/3b(1/2)"),
  row("Any size", "7/3b(1/4) 7/3b(2)"),
  row("Bend and release", "7/3br"),
  row("Pre-bend — already bent when struck", "7/3B"),
  row("Pre-bend and release", "7/3Br"),
  row("Vibrato with the tremolo bar", "7/3W"),
)

#syntax-table(
  "Right hand",
  row("Downstroke, upstroke", "5/3n 5/3u"),
  row("Arpeggio — thick string to thin", "(2/5 2/4 0/6)An"),
  row("…the other way", "(2/5 2/4 0/6)Au"),
  row("Rake", "(2/5 2/4 0/6)Rn"),
  row("Tremolo picking", "h 5/3TP 5/3TP"),
  row("Pick scrape", "5/3PS 5/3PS"),
  row("Natural harmonic", "12/3* 12/4*"),
  row("Pinch harmonic, harp harmonic", "5/3PH 5/3HH"),
)

#syntax-table(
  "Bass",
  row("Slap, pop", "0/4SL 3/3PO", tuning: tunings.bass),
  row("Dead slap", "x/4DS 0/4SL", tuning: tunings.bass),
)

#syntax-table(
  "Articulations",
  row("Accent, heavy accent", "5/3> 5/3^"),
  row("Staccato, tenuto", "5/3! 5/3-"),
  row("Ghost note — felt, not heard", "5/3 5/3g"),
  row("Fermata — hold", "5/3F 5/3"),
  row("…over a rest", "5/3 rF"),
)

#syntax-table(
  "Spans and instructions",
  row("Palm mute", "{PM: e 0/6 0/6 0/6 0/6} q 5/3"),
  row("Let ring", "{LR: q (0/1 2/2 2/3) 0/6} q 5/3"),
  row("A free instruction", "\"w/ bar\" 7/3V 5/3"),
  row("A chord name", "@E5 (2/5 2/4 0/6) @\"C#m7\" (4/5 4/4 4/3)"),
)

#syntax-table(
  "Dynamics",
  row("A dynamic, held until the next", "!mf 5/3 5/3 !ff 7/3 7/3"),
  row("Growing louder", "{cresc: q 3/6 5/6 7/6 8/6}"),
  row("…and quieter", "{dim: q 8/6 7/6 5/6 3/6}"),
)

#note[
  The dynamics are `ppp pp p mp mf f ff fff sf sfz fp`. Anything else is
  reported rather than printed.
]

#syntax-table(
  "Bars and structure",
  row("A barline", "5/3 5/3 | 7/3 7/3"),
  row("Double, final", "5/3 5/3 || 7/3 7/3 |."),
  row("A repeat", "|: q 5/3 5/3 7/3 7/3 :|"),
  row("…a given number of times", "|: q 5/3 5/3 7/3 7/3 :|x4"),
  row("First and second endings", "|: q 5/3 5/3 {V1: q 7/3 7/3 :|} {V2: q 8/3 8/3 |.}"),
  row("A time signature", "[3/4] q 5/3 5/3 5/3"),
  row("…changing mid-piece", "[3/4] q 5/3 5/3 5/3 | [4/4] q 5/3 5/3 5/3 5/3"),
  row("A count-in row", "q 5/3 5/3 5/3 5/3", count-in: true),
)

#note[
  A comment runs from `//` to the end of the line. A bar whose length disagrees
  with the time signature is reported on the page; `warn: false` silences that
  once a sheet is as intended.
]

#heading-style("Pasted ASCII tab")

#block(below: 0.9em, text(size: 10pt, [
  `ascii-tab` takes tab copied off the web and renders it as it stands. Nothing
  is required, and every fact added improves the result.
]))

#ascii-tab(theme: thm, ```
e|-----------------|-----------------|
B|-----5h7---------|--------------8--|
G|--2--------------|-----7b9---------|
D|--2----------7\5-|-----------------|
A|--0--------------|--10-------------|
E|--------3--------|-----------------|
```)

#note[
  Techniques are read inline: `h` `p` `s` `/` `\` `b` `r` `~` `v` `x` `*` `t`,
  and `( )` for a ghost note. `7b9` bends to the pitch of the 9th fret; `hb`
  and `fb` spell the size out instead.
]

#block(above: 1.2em, below: 0.9em, text(size: 10pt, [
  Column-aligned annotation rows supply what ASCII tab cannot carry. Each
  attaches to the column it sits over, so a tab can be annotated in part.
]))

#ascii-tab(theme: thm, ```
S:  Main Riff
R:  q   q   q   q    q   q   h
C:  E5               G5
D:  mf               ff
PM: ---------
T:                           Harm.
e|----------------|----------------|
B|----------------|----------------|
G|----------------|----------------|
D|--2---2---2---2-|--5---5---------|
A|--2---2---2---2-|--5---5---------|
E|--0---0---0---0-|--3---3---12----|
```)

#note[
  The rows are `R:` note values · `C:` chord names · `S:` a section heading ·
  `T:` a playing instruction · `D:` dynamics · `PM:` and `LR:` spans ·
  `1:` and `2:` endings. Whole-piece facts go in named arguments instead:
  `tuning`, `time`, `tempo`, `capo`, `anacrusis`. `rhythm: even(1/8)` or
  `rhythm: fill` covers a bar that has no `R:` row, and `enrich:` is the escape
  hatch for everything else.

  `ascii-to-dsl` prints the equivalent native source, which is how an annotated
  paste graduates to the syntax in the tables above.
]
