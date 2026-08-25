// A tour of everything the package can set.
//
// Self-contained: all the music here was written for this document, so the file
// stands on its own and ships with the package.
//
// Compile with `typst compile --root . examples/demo.typ`.

#import "/src/lib.typ": *

#let note(body) = block(
  above: 0.6em,
  below: 0.9em,
  text(size: 9.5pt, fill: luma(70), body),
)

#let src(code) = note(raw(code, lang: "typst"))

#show: song.with(
  title: "fretwork",
  subtitle: "A demonstration of the Typst package",
  words: "Mattias Eriksson",
  music: "Mattias Eriksson",
  arranged: "Mattias Eriksson",
  source: "Package demo · v0.3.0",
  copyright: "Typeset with fretwork · EUPL-1.2",
  tempo: 120,
  tempo-words: "Moderately",
)

= A song sheet

Everything above the first stave — the source line, the title and subtitle, the
writing credits, the tempo indication and the copyright footer — comes from a
single `song` show rule. Continuation pages get a running head automatically.

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

`#section` prints a heading, `count-in: true` adds the counting row a learner
reads along with, `@E5` names a chord over the next event, and `{PM: … }`
brackets a palm mute over whatever it wraps.

= Note values

Values are sticky, so only a change needs writing: `w h q e s t` for whole down
to thirty-second, with `.` for each augmentation dot. Beams are grouped by the
beat, and a second beam covers only the notes fast enough to need it.

#src("w 0/6 | h 0/6 0/6 | q 0/6 0/6 0/6 0/6 | e 0/6 …")

#tab(```
w 0/6 | h 0/6 0/6 | q 0/6 0/6 0/6 0/6
| e 0/6 0/6 0/6 0/6 0/6 0/6 0/6 0/6
| s 0/6 0/6 0/6 0/6 e 0/6 0/6 q 0/6 0/6
| t 0/6 0/6 0/6 0/6 s 0/6 0/6 e 0/6 0/6 h 0/6 |.
```)

The lane sits under the staff and draws bars rather than noteheads: a beam along
the bottom with the stems rising from it. With no notation stave to hang a
notehead on, the stem's length carries the value — a half note is a quarter's
stem cut in two from the same foot, and a whole note is not written at all,
which is why the first bar above shows nothing.

Dots and rests. An augmentation dot is a small square at the foot of the stem;
a rest is drawn inside the staff, where the note it replaces would have stood.

#src("q. 0/6 e 2/6 h 3/6 | q.. 0/6 t 2/6 2/6 h 3/6 | q 0/6 r 3/6 r | …")

#tab(```
q. 0/6 e 2/6 h 3/6 | q.. 0/6 t 2/6 2/6 h 3/6 | q 0/6 r 3/6 r
| h r h r | w r |.
```)

Tuplets are groups with a numeric name. `{3: … }` is three in the time of two;
`{7/4: … }` states the ratio outright. Groups nest.

#tab(```
{3: e 0/6 2/6 3/6} {3: e 5/6 3/6 2/6} {5: s 0/6 2/6 3/6 5/6 3/6} q 0/6
| {3: q 0/6 3/6 5/6} {PM: {3: q 3/6 5/6 7/6}} |.
```)

= Chords, dead strings and ties

A chord is notes written in one column. `x` deadens a string, or all six at
once. `~` ties a note into the next one on the same string.

A tie hangs *under* its line and curves down — the mirror of the slur that
arches over a hammer-on above, so the two marks can never be read for each
other. Under a stacked number there is no room, the next string being right
there, so a chord's ties leave the numbers' flanks instead.

The far end of a tie prints no fret number, because it is not struck: the arc is
the whole of what says the string is still sounding, and a digit there would read
as a second, quieter attack — which is what a ghost note's brackets mean. The
event keeps its slot in the rhythm lane, so the held note still has a value.

#src("h 5/3~ q 5/3 7/3 | q (0/1 2/2 2/3 1/4) (3/1 3/2 0/3 0/4) h (2/5 2/4 0/6)~")

#tab(```
h 5/3~ q 5/3 7/3
| q (0/1 2/2 2/3 1/4) (3/1 3/2 0/3 0/4) h (2/5 2/4 0/6)~ | w (2/5 2/4 0/6)
| q x x/5 (x/1 x/2 x/3) x |.
```)

Fret numbers are set with tabular figures, and each one's gap in the string line
follows its own measured width, so a bar mixing one- and two-digit frets keeps
its columns straight.

#tab(```
q 10/6 12/5 e 11/4 9/3 7/2 5/1 | q 24/1 0/6 h 12/3 |.
```)

#pagebreak()

= Techniques

Techniques are suffixes written after the string number. They chain, and a
suffix after a closing parenthesis binds to every note of the chord.

Hammer-on `h`, pull-off `p`, legato slide `s`, shift slide `S`:

#tab(```
q 5/3h7 7/3p5 5/3s7 5/3S7 |.
```)

A slur springs from the top centre of a lone number. Several in a row, across
strings, keep clear of one another and of the line above:

#tab(```
e 5/3h7 7/3p5 5/2h7 7/2p5 5/1h7 7/1p5 5/3h7 7/3p5
| e 2/6h4 4/6p2 3/5h5 5/5p3 12/1h14 14/1p12 7/4h9 9/4p7 |.
```)

Written with no target fret a link runs to the *next event* that plays the
string, so the two notes keep their own values — and a run of them is one
gesture and takes one slur over the whole of it. A shift slide ends the run,
its target being picked again:

#tab(```
s 7/1h 8/1p 7/1s 5/1 q r r r | s 7/1h 8/1p 7/1S 5/1 q r r r |.
```)

Stacked numbers cannot attach at the top — the arc would run into the number
above — so a chord ties from the sides, level with each digit's middle:

#tab(```
h (5/3 5/2 5/1)~ (7/3 7/2 7/1)~ | w (7/3 7/2 7/1) |.
```)

Bend `b`, half-step bend `b(1/2)`, bend and release `br`, pre-bend `B`,
pre-bend and release `Br`, quarter-tone bend `b(1/4)`. A pre-bend is already
bent when the string is struck, so its arrow is straight — the curve is what
shows the pitch rising after the attack. Every arrow in a system ends at the
same height.

#tab(```
q 7/3b 7/3b(1/2) 7/3br 7/3B | h 7/3Br 7/3b(1/4) |.
```)

Vibrato `v`, wide vibrato `V`, and the five harmonics — natural `*`, pinch `PH`,
artificial `AH`, harp `HH`, tap `TH`:

#tab(```
q 7/3v 7/3V 12/3* 5/3PH | q 5/3AH 7/3HH 7/3TH 7/3v |.
```)

Accent `>`, marcato `^`, staccato `!`, tenuto `-`; then downstroke `n`,
upstroke `u`, tapping `T` and a ghost note `g`:

#tab(```
q 7/3> 7/3^ 7/3! 7/3- | q 7/3n 7/3u 7/3T 7/3g |.
```)

Trill `tr`, tremolo picking `TP` and pick scrape `PS` print a word and then a
wavy line for as long as they last:

#tab(```
q 7/3tr9 e 7/3TP 7/3TP q 12/6PS 7/3v |.
```)

An arpeggio `A` and a rake `R` are wavy lines beside the chord, spanning the
strings they touch. The arrowhead says which way it is rolled: `An` runs thick
string to thin, which is what a bare `A` means, and `Au` reverses it.

#tab(```
q (0/1 2/2 2/3 1/4)An h (3/1 3/2 0/3 0/4)Au q (0/1 2/2 2/3 1/4)Rn |.
```)

Vibrato with the tremolo bar is `W`, and a fermata is `F` — over a note, over a
rest, or over a bare mute, since `r` and `x` take suffixes of their own:

#tab(```
h 7/3W 7/3 | q 7/3F rF xF 5/3 |.
```)

On bass, slap `SL`, pop `PO` and dead slap `DS` print over the note they strike:

#tab(tuning: tunings.bass, ```
q 0/4SL 3/3PO 0/4SL x/3DS | e 0/4SL 3/3PO 0/4SL 3/3PO q 5/2PO 0/4SL |.
```)

Palm mute `{PM: … }` and let ring `{LR: … }` bracket whatever they wrap, and a
free instruction goes in quotes:

#tab(```
{PM: e 0/6 0/6 0/6 0/6} {LR: e (0/1 2/2 2/3) 0/6 0/6 0/6}
| "w/ bar" h 7/3V q 5/3s12 5/3 |.
```)

= Grace notes

A grace note is an ornament rather than a beat: it is squeezed out of its
neighbour's time and takes none of the bar's, so a bar full of them is still
full. A standalone `g` marks the next event as one played before the beat, `G`
as one starting on it — the slash through the stem is the difference. Inside a
token `g` is still the ghost note; the two never meet, because a token holds no
whitespace.

#src("q g 3/3 5/3 7/3 G 5/3 7/3 g 3/3h5 5/3")

#tab(```
q g 3/3 5/3 7/3 G 5/3 7/3 g 3/3h5 5/3 | q 5/3 g 7/3 5/3 g 3/3 h 5/3 |.
```)

= Dynamics

Dynamics go below the staff, where nothing else is competing for the room. A
dynamic holds until the next one; `{cresc: … }` and `{dim: … }` mark the
stretches that change gradually.

#src("!mf q 0/6 2/6 3/6 5/6 | {cresc: q 3/6 5/6 7/6 8/6} | !ff q 10/6 …")

#tab(```
!mf q 0/6 2/6 3/6 5/6 | {cresc: q 3/6 5/6 7/6 8/6}
| !ff q 10/6 8/6 {dim: 7/6 5/6} | !p q 3/6 2/6 h 0/6 |.
```)

= Lyrics

Syllables are not written among the notes — they would drown them. They run
parallel to the music instead, spent one per sung note, and rests, grace notes
and the far ends of ties are passed over because none of them is sung.

A trailing `-` hyphenates into the next syllable, and the hyphen is drawn as its
own character centred in the gap between the two. `_` spends a note without
printing anything on it, which is how a word held over several notes is written:
the sheets this follows write it once, where the note starts, and draw no line
after it.

#src("#tab(lyrics: \"Some- thing I can ne- ver say _\", ```…```)")

#tab(lyrics: "Some- thing I can ne- ver say _", ```
q 0/6 2/6 e 3/6 3/6 q 5/6 | q 3/6 2/6 h 0/6 |.
```)

Several verses are an array, one lane each. A syllable is routinely wider than
the room its note bought, so the spacing engine widens the gap between two
events by half of each syllable — a constraint no other mark on the page needs,
and one that crosses barlines.

#tab(
  lyrics: (
    "Twist- ing and smash- ing the win- dow",
    "Blind- ed by ev- ery sing- le light",
  ),
  ```
  q 0/6 2/6 3/6 5/6 | q 3/6 5/6 7/6 8/6 |.
  ```,
)

= Barlines, repeats and endings

`|` single · `||` double · `|.` final · `|:` opens a repeat · `:|` closes one ·
`:|x3` says how many times, and prints it · `{V1: … }` and `{V2: … }` are first
and second endings.

#tab(```
|: q 0/6 0/6 0/6 0/6
 | {V1: q 3/6 3/6 3/6 3/6 :|x3}
   {V2: q 5/6 5/6 h 7/6 ||}
 | q 7/6 5/6 h 0/6 |.
```)

= The time signature

`tab(time: …)` sets it for a whole passage, and `[7/8]` at the start of a
measure changes it there. Brackets, because a bare `7/8` is already fret seven
on string eight. It is printed once, at the start; pass `show-time: false` on
the second and later blocks of one piece.

#src("[3/4] q 0/6 2/6 3/6 | [7/8] e 0/6 2/6 3/6 5/6 7/6 8/6 10/6")

#tab(```
[3/4] q 0/6 2/6 3/6 | [7/8] e 0/6 2/6 3/6 5/6 7/6 8/6 10/6 | [4/4] q 0/6 2/6 h 3/6 |.
```)

#pagebreak()

= Tunings and capo

Tuning is a named argument, and the sounding pitch of every note follows from
it — which is exactly what a notation stave would need if one were added later,
with no new syntax. Passing a tuning to `song` instead announces it in the
sheet's header, since that one applies to the whole piece.

#src("#tab(tuning: tunings.drop-d, ```…```)")

#tab(
  tuning: tunings.drop-d,
  ```
  |: q (0/6 0/5 0/4) e 0/6 0/6 h (5/6 5/5 5/4)
   |  q (0/6 0/5 0/4) e 0/6 0/6 h (7/6 7/5 7/4) :|
  ```,
)

Eleven tunings ship with the package — standard, drop D, a half and a whole step
down, open G and open D, DADGAD, seven-string, four- and five-string bass, and
ukulele — and `tuning` builds any other from a list of pitches. A staff of seven
strings or of four needs nothing else said.

#src("tuning(\"E4 B3 G3 D3 A2 E2 B1\", name: \"7-string\")")

#tab(
  tuning: tunings.seven-string,
  ```
  q (0/7 0/6) e 3/7 5/7 q (0/7 0/6) e 7/7 5/7 |.
  ```,
)

#tab(
  tuning: tunings.bass,
  ```
  q 0/4 e 3/4 5/4 q 0/4 e 7/4 5/4 | w 0/4 |.
  ```,
)

A capo transposes everything without changing a single fret number:

#context {
  let open = to-pitch(tunings.standard, 6, 0)
  let capo = to-pitch(tunings.standard, 6, 0, capo: 3)
  note[
    `to-pitch(tunings.standard, 6, 0)` is #pitch-name(open) (MIDI #open); with
    `capo: 3` the same note sounds #pitch-name(capo). The fifth fret of the
    sixth string and the open fifth string agree, as they must:
    #pitch-name(to-pitch(tunings.standard, 6, 5)) and
    #pitch-name(to-pitch(tunings.standard, 5, 0)).
  ]
}

= Importing ASCII tab

A tab pasted from the web renders as it stands. It carries no rhythm, so there
are no stems — the layout follows the source's own columns instead. Techniques
written inline are read: `h` `p` `/` `\` `b` `r` `~` `x` `*` `t`, `( )` for a
ghost note, and the harmonic marks `NH` `PH` `AH` `HH` `TH` against the fret.

#ascii-tab(```
e|-----------------|-----------------|
B|-----5h7---------|--------------8--|
G|--2--------------|-----7b9---------|
D|--2----------7\5-|-----------------|
A|--0--------------|--10-------------|
E|--------3--------|-----------------|
```)

Everything missing can be supplied, a little at a time. Column-aligned
annotation rows are the main way, because each one attaches to exactly the
column it sits over: `R:` note values, `C:` chord names, `S:` a section heading,
`T:` a playing instruction, `PM:` and `LR:` bracketed spans.

#ascii-tab(```
S:   Second riff
C:   E5          G5      A5
R:   q   q   e e e       e
PM:  --------
T:                       let ring
e|---0---2---3-5---------7--|
B|---0---2---3-5---------7--|
G|---1---2---4-6---------8--|
D|--------------------------|
A|--------------------------|
E|--------------------------|
```)

When the rhythm is regular, one argument replaces the annotation row: `even(…)`
gives every event the same value, `fill` spreads each bar evenly across the time
signature, and a string spends note values event by event.

#ascii-tab(
  ```
  e|--------------------|
  B|--------------------|
  G|--------------------|
  D|----7---7---9---7---|
  A|--0---2---3---2-----|
  E|--------------------|
  ```,
  rhythm: even(1 / 8),
)

Facts about the whole piece are named arguments — `tuning`, `time`, `tempo`,
`capo`, `anacrusis` — and `enrich` takes the parsed part and hands back a
modified one, for whatever the other two do not cover.

#ascii-tab(
  ```
  e|--------------|
  B|--------------|
  G|--------------|
  D|--0---0---0---|
  A|--0---0---0---|
  E|--0---0---0---|
  ```,
  tuning: tunings.drop-d,
  time: (3, 4),
  rhythm: "q q q",
)

An annotated tab is as complete as one written by hand, so `ascii-to-dsl` prints
it back as native source, ready to keep:

#src(ascii-to-dsl(
  "R:   q   q   e   e\n"
    + "e|---0---2---3---5--|\n"
    + "B|------------------|\n"
    + "G|------------------|\n"
    + "D|------------------|\n"
    + "A|------------------|\n"
    + "E|------------------|",
))

#pagebreak()

= Themes

Everything derives from one unit, `staff-space`, so a sheet rescales without its
proportions drifting.

#block(breakable: false, grid(
  columns: (1fr, 1fr),
  column-gutter: 8mm,
  [
    #src("theme(staff-space: 2.2mm)")
    #tab(theme: theme(staff-space: 2.2mm), ```
    q 0/6 3/6 5/6 3/6
    ```)
  ],
  [
    #src("theme(staff-space: 3.6mm)")
    #tab(theme: theme(staff-space: 3.6mm), ```
    q 0/6 3/6 5/6 3/6
    ```)
  ],
))

A string line must never run through a fret number. By default the lines are
broken around the digits, which also works on a tinted page; `mask: "box"` puts
them on an opaque patch instead. The type and the ink colour are arguments too.

#tab(
  theme: theme(mask: "box", color: rgb("#1b3a5c")),
  ```
  q 10/6 12/5 e 11/4 9/3 7/2 5/1 | q 24/1 0/6 h 12/3 |.
  ```,
)

Repeat signs come in two styles: `"plain"` is the bare thick-thin-and-dots form,
`"ornate"` adds the flared serifs of an engraved one.

#block(breakable: false, grid(
  columns: (1fr, 1fr),
  column-gutter: 8mm,
  [
    #src("repeat-style: \"plain\"")
    #tab(theme: theme(staff-space: 2.6mm), ```
    |: q 0/6 3/6 5/6 3/6 :|
    ```)
  ],
  [
    #src("repeat-style: \"ornate\"")
    #tab(theme: theme(staff-space: 2.6mm, repeat-style: "ornate"), ```
    |: q 0/6 3/6 5/6 3/6 :|
    ```)
  ],
))

= Building music in code

The data model is public API, so a passage can be built without the DSL at all
and handed to `render`. It is also what `enrich` receives.

#src(
  "model.measure(events: (\n"
    + "  model.event(notes: (model.note(6, 0),), duration: model.durations.q),\n"
    + "  …\n"
    + "))",
)

#context {
  let bar = model.measure(events: range(4).map(i => model.event(
    notes: (model.note(6, i * 2),),
    duration: model.durations.q,
  )))
  render(model.part(measures: (bar,)))
}

`validate` checks a part against its time signature and reports what disagrees.
It is advisory rather than fatal: a pick-up bar is exempt, and an event with no
note value is reported as unchecked rather than as wrong.

#context {
  let short = model.part(measures: (model.measure(events: (
    model.event(notes: (model.note(6, 0),), duration: model.durations.h),
  )),))
  note[`model.validate(…)` → #raw(repr(model.validate(short)))]
}

// Kept in one unbreakable block: the report below is deliberate, and a page
// break that separated it from the sentence explaining it would read as a
// genuine failure in the package's own showcase.
#block(breakable: false)[
  `tab` and `ascii-tab` print what it finds on the page, because Typst gives a
  package no other channel for a problem that must not stop the compile: `panic`
  is its only diagnostic and it is fatal.

  *The stave below is deliberately wrong*, and the only one in this document
  that is: three quarter notes in a bar of four. Every other stave here adds up.
  `warn: false` silences the report once a sheet is as intended.

  #src("q 0/6 2/6 3/6 |.")

  #tab(```
  q 0/6 2/6 3/6 |.
  ```)
]
