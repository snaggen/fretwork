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

/// One ASCII example: the source set as code, and what `ascii-tab` makes of it.
///
/// The text set as code is the text handed to the parser, as in `row`, so the
/// two cannot disagree. `call` names the arguments that belong with it, which
/// have no place in the source itself.
#let paste(src, call: none, ..args) = block(breakable: false, below: 1.4em, {
  if call != none {
    block(below: 0.4em, text(size: 8pt, fill: faint, raw(call, lang: none)))
  }
  block(below: 0.7em, text(size: 8pt, raw(src.text, lang: none, block: true)))
  ascii-tab(src, theme: thm, warn: false, ..args)
})

/// A reference list of marks and what they mean, two pairs to a line.
#let mark-table(..pairs) = block(
  below: 1.2em,
  table(
    columns: (auto, 1fr, auto, 1fr),
    align: left + top,
    inset: (x: 6pt, y: 4pt),
    stroke: none,
    ..pairs
      .pos()
      .map(((mark, meaning)) => (raw(mark, lang: none), text(size: 8.5pt, meaning)))
      .flatten()
  ),
)

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
  row("Every rest value, whole to thirty-second", "w r | h r | q r | e r | s r | t r"),
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
  row("…to the next note instead, across a bar", "h 10/3s 5/1 | h 3/3 5/1"),
  row("Slide out of the note, up or down", "h 15/1sU 15/1sN"),
  row("Tie — the far end is not struck", "5/3~ 5/3"),
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
  row("Pinch, artificial harmonic", "5/3PH 5/3AH"),
  row("Harp, tap harmonic", "5/3HH 5/3TH"),
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
  "Lyrics",
  row("One syllable per sung note", "q 5/3 7/3 8/3 7/3", lyrics: "one two three four"),
  row("A word broken in two", "q 5/3 7/3 8/3 7/3", lyrics: "Twist- ing the night"),
  row("A word held — `_` spends a note", "q 5/3 7/3 8/3 7/3", lyrics: "held _ and gone"),
  row("Rests and ties are passed over", "q 5/3 r 8/3~ 8/3", lyrics: "not sung"),
)

#note[
  Verses are `lyrics: ("verse one …", "verse two …")`, one lane each, below
  everything else on the system. Syllables left over after the last note are
  reported on the page.
]

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

#pagebreak()

= Pasted ASCII tab

#block(below: 1.2em, text(size: 10pt, [
  `ascii-tab` takes the plain-text tab found on the web and renders it as it
  stands. Nothing below is required — a bare paste always renders, and every fact
  added improves the result. As in the tables above, each example is set from the
  same string it is rendered from, so none of them can drift.
]))

#heading-style("What is read")

#block(below: 0.9em, [
  A *block* is one row per string, written highest string first — the labels
  before the barline say which, and a block whose labels are the tuning reversed
  is read the other way round. *Column position carries simultaneity*: notes
  standing in one column are struck together. Blocks stacked one after another
  are one continuous passage rather than separate pieces, and lines that are
  neither string rows nor annotation rows — titles, comments, chord charts — are
  skipped with a warning.
])

#paste(```
e|-----------------|-----------------|
B|-----5h7---------|--------------8--|
G|--2--------------|-----7b9---------|
D|--2----------7\5-|-----------------|
A|--0--------------|--10-------------|
E|--------3--------|-----------------|
```)

#note[
  Adjacent digits are one fret as far as that fret exists, which is the only
  reading that makes sense of both `-11-` and `-1-1-`: `-11-` is the eleventh,
  `-1-1-` the first struck twice, `-77-` two sevenths — nothing is fretted at
  the 77th — and `-010-` the open string then the tenth. Where the convention
  can be wrong, brackets settle it: inside `( )` or `< >` the digits are one
  fret however many there are.
]

#heading-style("Marks read inside a row")

#mark-table(
  ("h", "hammer-on"),
  ("p", "pull-off"),
  ("s / \\", "slide — out of the note where none follows"),
  ("~ v", "vibrato"),
  ("b", "bend, to the pitch of the fret named"),
  ("r", "release, folded into the bend before it"),
  ("hb fb", "half and full bend, size spelled out"),
  ("pb pbr", "pre-bend, and pre-bend with release"),
  ("x X", "a dead string"),
  ("t", "tap — it marks the note it precedes"),
  ("*", "natural harmonic"),
  ("< >", "natural harmonic, as Power Tab writes it"),
  ("( )", "a ghost note — or a tie, see below"),
  ("|", "a barline"),
  ("NH PH AH", "natural, pinch and artificial harmonic"),
  ("HH TH", "harp and tap harmonic"),
)

#note[
  A mark may stand anywhere between the notes it joins, and where it stands
  decides what is drawn: `5h7`, the digits pressed against the mark, is one
  event with the second number beside the first, while `5-h-7` is two events
  joined by an arc — which is the only form that can reach into the next bar. An
  `R:` row does the same to the compact form: a value over the target's column
  says that note has a rhythm of its own. A slide with no note left to reach —
  `15\` at the end of a row — is the note slid *off*, and the arrow says which
  way the pitch leaves; a hammer-on or pull-off to nowhere means nothing and is
  dropped. Marks chain: `5h7b9` bends the hammered seventh up to the pitch of the
  ninth. A bend must rise, so `5b3` is reported and the note kept. The harmonic marks are read in capitals, which collide with
  nothing since every other letter is lower case, and none of them names a
  target fret: `7PH5` is the harmonic and then the fifth. A source that writes
  them on a line of its own above the staff uses a `T:` row instead.
]

#paste(```
e|--------------------------------------|
B|--------------------------------------|
G|--5h7p5--5s7--7fb--7b9r7--7PH--9-s-12\|
D|--------------------------------------|
A|----------------------------------x---|
E|----------(12)---<12>-----------------|
```)

#block(above: 1.2em, below: 0.9em, [
  *A fret in parentheses that repeats the note before it on the same string is a
  tie* — the string is still sounding and is not struck again. Any other fret in
  them is the ghost note the brackets otherwise mean. There is no other way to
  write a held note in ASCII tab, where `~` is vibrato whatever the native syntax
  uses it for.
])

#paste(
  rhythm: even(1 / 4),
  ```
  e|--------------------------|--------------------------|
  B|--------------------------|--------------------------|
  G|--5-----(5)-----7-----(7)-|--------------------------|
  D|--------------------------|--------------------------|
  A|--------------------------|--0-----3-----(0)-----5---|
  E|--------------------------|--------------------------|
  ```,
)

#note[
  Both print the same, in brackets — the arc is what separates them, as it does
  on a published sheet — so the reading matters to what the piece *means* rather
  than to how it looks. A note struck in between ends what the first was
  sounding, which is why the `(0)` above is a ghost note and not a tie. A tie is
  read across a barline but not across the end of a block, the reading being made
  row by row like every other mark that joins two notes.
]

#heading-style("Barlines, repeats and endings")

#block(below: 0.9em, [
  `|` is a barline, and `||` is one barline drawn twice rather than two with a
  bar of silence between them. The repeat colons are read as music: `|:` opens a
  repeat, `:|` closes one, `:|:` closes one and opens the next where a repeated
  section runs straight into another, and `x3` after the closing stroke says how
  many times to play it. A bar with nothing written in it is a bar of silence,
  and becomes the rest a published sheet would write.
])

#paste(```
R:  q   q   q   q    q   q   q   q
e|:----------------|-----------------:|x3
B|:----------------|-----------------:|x3
G|:----------------|-----------------:|x3
D|:--2---2---2---2-|--5---5---5---5--:|x3
A|:--2---2---2---2-|--5---5---5---5--:|x3
E|:--0---0---0---0-|--3---3---3---3--:|x3
```)

#note[
  A count is read only after `:|`, since `x` is also a dead string: `|x3` in the
  middle of a row is a muted string and then the third fret.
]

#block(above: 1.2em, below: 0.9em, [
  First and second endings are written as rows of their own, `1:` and `2:`, a run
  of dashes marking the measures each covers. They attach to measures rather than
  to events, which is what a volta is, and the first ending is closed off where
  the repeat it leads back to is written.
])

#paste(```
1:                   --------------
2:                                  --------------
R:  q   q   q   q    q   q   q   q   q   q   q   q
e|:----------------|---------------:|---------------|
B|:----------------|---------------:|---------------|
G|:----------------|---------------:|---------------|
D|:--2---2---2---2-|--5---5---5---5:|--7---7---7--7-|
A|:--2---2---2---2-|--5---5---5---5:|--7---7---7--7-|
E|:--0---0---0---0-|--3---3---3---3:|--5---5---5--5-|
```)

#heading-style("Annotation rows")

#block(below: 0.9em, [
  Everything ASCII tab cannot carry is supplied by extra rows in the same block,
  each prefixed with a key and a colon. Being column-aligned is the whole point:
  a fact attaches to exactly the column it sits over, so nothing has to be
  counted and a tab may be annotated in part.
])

#mark-table(
  ("R:", "note values, and rests where nothing is struck"),
  ("C:", "chord names"),
  ("L:", "sung syllables, one row per verse"),
  ("S:", "a section heading"),
  ("T:", "a free playing instruction"),
  ("D:", "dynamics"),
  ("PM: LR:", "palm mute and let ring — dashes mark the extent"),
  ("1: 2:", "first and second endings"),
)

#paste(```
S:  Main Riff
R:  q   q   q   q    q   q   h
C:  E5               G5
L:  Ha- ven't we met  be- fore
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
  `R:` reuses the DSL's duration tokens deliberately — `w h q e s t`, dotted the
  same way, and `3:` to open a tuplet — so there is no second notation to learn,
  and a Power Tab or Guitar Pro export's own `W H Q E S` line pastes in
  unchanged. Note values are sticky, as in the DSL. `C:` and `T:` rows split on
  runs of two or more spaces, so an instruction may contain single spaces. Each
  token attaches to the single nearest event within three columns, and one with
  nothing near it is reported rather than moved — except a syllable, which is
  given a column of its own so the voice can carry on where the guitar has
  stopped.
]

#block(above: 1.2em, below: 0.9em, [
  *A block may carry more than one `R:` row*, read together column by column,
  which is what makes `3:` writable in a tab whose events stand close: a tuplet
  opener needs whitespace on both sides and rarely fits between two values.
  Written on a row of its own it lands on the column it belongs to.
])

#paste(```
R:          3:
R:  q   q   q   q   q
e|---------------------|
B|---------------------|
G|--3---3---5---3---2--|
D|---------------------|
A|---------------------|
E|---------------------|
```)

#note[
  Three quarters in the time of two, which is what lets a bar of five quarters
  add up to four beats. A bar that disagrees with the meter is reported on the
  page, and a missing tuplet is one of the things that announces itself that way.
]

#block(above: 1.2em, below: 0.9em, [
  *Rests are written in the `R:` row as well*, because ASCII tab spells silence
  as filler and has nowhere else to put them. A value standing over a column
  where nothing is struck is a rest that long, which is what lets a bar that
  stops halfway through still add up to its meter.
])

#paste(```
R:  q   e   e   h            q   e   e   h
e|------------------------|------------------------|
B|------------------------|------------------------|
G|------------------------|------------------------|
D|------5---7-------------|------7---8-------------|
A|--0---------------------|--0---------------------|
E|------------------------|------------------------|
```)

#note[
  The notes claim their tokens — each takes the nearest one within three
  columns, the same reach every other row resolves by — and whatever no note
  claimed is a rest where it stands. So a token that merely misses its note
  still sets that note's value, while one written over a gap is a silence even
  where the events are packed two columns apart. A bar with nothing said about
  it is one bar-long rest, as before; a bar whose rests are named is divided as
  the row says. Align the row and the bar adds up; a bar that does not is
  reported on the page.
]

#heading-style("Arguments and inference")

#block(below: 0.9em, [
  Facts about the whole piece have no column, and are named arguments instead:
  `tuning`, `time`, `tempo`, `capo`, `anacrusis`. Where annotating every column
  would be busywork, `rhythm:` infers the note values — `even(1/8)` makes every
  event an eighth, `fill` spreads each bar evenly across the time signature, and
  a string such as `"q q e e | h h"` is spent event by event. `lyrics:` does the
  same for a source with no `L:` rows. Annotation rows win over arguments, which
  win over inference: a value already set is never overwritten.
])

#paste(
  call: "rhythm: even(1/8), time: (3, 4)",
  rhythm: even(1 / 8),
  time: (3, 4),
  ```
  e|--------------|--------------|
  B|--------------|--------------|
  G|--------------|--------------|
  D|--2-2-2-2-2-2-|--------------|
  A|--0-0-0-0-0-0-|--2-2-2-2-2-2-|
  E|--------------|--0-0-0-0-0-0-|
  ```,
)

#note[
  `tempo` and `capo` are carried into the model but drawn by the title block
  rather than by the staff, so they appear on a page set with `song`.

  Beyond the three there is `enrich: part => …`, which is handed the parsed part
  and returns a modified one. The model is public API, so anything the rows and
  the arguments do not reach can be set there.

  `ascii-to-dsl(source)` prints the equivalent native source. Once a tab is
  fully annotated it is as complete as one written by hand, and this is how it
  graduates to the syntax in the tables above.
]
