// What fretwork draws for bends today, next to the passage it was compared
// against: bars 145–146 of the Songsterr screenshot from 2026-08-06.
//
//   typst compile --root . sample.typ
//
// It reads the working tree, so an edit to src/ shows up on the next compile.
// To check the *installed* package instead, change the import to
// `@local/fretwork:0.3.0` and drop `--root .`.

#import "/src/lib.typ": *

#set page(width: 190mm, height: auto, margin: 12mm)
#set text(font: default-theme.font, size: 9.5pt)
#set par(justify: false)

#let thm = theme(staff-space: 3.2mm)
#let note(body) = block(above: 0.5em, below: 1.1em, text(size: 9pt, fill: luma(95), body))
#let head(body) = block(above: 1.5em, below: 0.6em, text(size: 12pt, weight: 700, body))

#text(size: 17pt, weight: 700)[Bends — what we draw today]

#note[
  Every bend construct the package understands, then the reference passage
  rebuilt from them. Compiled from `src/`, so this is the current state and not
  a picture of it.
]

#head[The reference passage]

#note[
  Two dead strings, then the two gestures the screenshot is about. Bar 1 bends
  as the note sounds and holds it across the barline: `~` ties the bent note, so
  the held fret prints in parentheses, which is what the reference does with it.
  Bar 2 is the whole gesture on one note — strike, bend up, release — written
  `br`.
]

#tab(theme: thm, ```
q x/5 x/4 4/2b~ 4/2 | q 4/2br 5/2 r 2/2p1
```)

#note[
  *The hold is the dashed rule.* A bend up, a hold and a release is three parts,
  and the rule is the middle one: it carries `full` on from the arrowhead at the
  height the bend reached. A bent note that is *tied* is a bend held, so the
  rule runs to the end of the last tied event — to where the sound stops, not to
  where its number is — and crosses barlines with it.

  That is also why a release is drawn as *two* arrows: the hold has to sit
  between the two arrowheads where it can be seen, and a stroke already curving
  downwards has nowhere to hang a horizontal rule. The Hal Leonard legend draws
  one continuous stroke and this package followed it until the hold arrived.
]

#head[Every bend the syntax has]

#note[
  `b` is a whole step and prints `full`; any other size is written in
  parentheses after it. A pre-bend is already bent when the string is struck, so
  its arrow is straight — the curve is what shows the pitch rising after the
  attack.
]

#let row(label, src) = (
  {
    text(size: 8.5pt, label)
    linebreak()
    text(size: 8.5pt, raw(src, lang: none))
  },
  tab(src, theme: thm, show-time: false, warn: false),
)

#table(
  columns: (34%, 1fr),
  align: (left + horizon, left + horizon),
  inset: (x: 6pt, y: 7pt),
  stroke: (x, y) => (top: if y == 0 { none } else { 0.5pt + luma(210) }),
  ..(
    row("Whole step — printed `full`", "q 7/3b 5/3"),
    row("Half step", "q 7/3b(1/2) 5/3"),
    row("Quarter tone", "q 7/3b(1/4) 5/3"),
    row("Two steps", "q 7/3b(2) 5/3"),
    row("Bend and release", "q 7/3br 5/3"),
    row("Pre-bend — straight arrow", "q 7/3B 5/3"),
    row("Pre-bend and release", "q 7/3Br 5/3"),
    row("Held across a tie", "h 7/3b~ 7/3"),
    row("…and on across a barline", "h 7/3b~ 7/3~ | w 7/3"),
    row("On a chord", "q (7/3 7/2)b 5/3"),
    row("With vibrato after it", "q 7/3bv 5/3"),
    row("Tremolo-bar vibrato", "q 7/3W 5/3"),
  ).flatten(),
)

#head[Where a bend sits]

#note[
  An arrow rises from the fret number it belongs to rather than from a fixed
  height, so the same bend sits the same distance above its number whichever
  string it is on — and every arrow in a system ends at the same height, which
  is how the reference sets them. The staff reserves exactly the room the
  highest one needs.
]

#tab(theme: thm, ```
q 7/1b 7/2b 7/3b 7/4b | q 7/5b 7/6b h 7/1b(1/2)
```)

#note[
  Imported ASCII tab reads bends inline: `7b9` bends to the pitch of the 9th
  fret, and `hb` and `fb` spell the size out. A size no target fret can name — a
  quarter tone — has no ASCII notation, and neither has a pre-bend; both need
  the native syntax.
]

#ascii-tab(theme: thm, ```
R:   q   q     q    q
e|---------------------|
B|---------------------|
G|---7b9---7hb---7fb---|
D|---------------------|
A|---------------------|
E|-----------------0---|
```)
