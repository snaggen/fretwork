# fretwork — specification

Guitar tablature of publishing quality for Typst.

The target is a song sheet that looks like the published material this package
was designed against: rock tab with rhythm stems and a count row, in a page
layout with title, credits, section headings and a copyright footer. The symbol
set follows Hal Leonard's *Guitar Notation Legend*, which is the industry
reference for how professional guitar books notate technique.

## Scope

Phase 1 is **tablature only**. There is no notation staff and no chord diagrams.
The data model and the layout engine are nevertheless built so that a notation
staff can be added later without rewriting either — see
[Room for a notation staff](#room-for-a-notation-staff).

| | |
|---|---|
| In phase 1 | Tab systems, barlines, repeats and endings, technique symbols, section headings, title block, rhythm stems and the count row, chord names as text, ASCII tab import |
| Added in 0.2 | Lyrics under the staff, one lane per verse |
| Not in phase 1 | Chord diagrams, several simultaneous guitars, rhythm slashes |
| Distribution | Own use first; publication on Typst Universe later |
| Licence | EUPL-1.2 |

**No external font is required.** Typst packages cannot ship fonts — a font
dependency has to be installed by hand by every user, which is the well-known
pain point of packages that need one. Every music symbol is therefore drawn as a
vector curve. Only running text uses a font, and it degrades to whatever is
installed.

## Input syntax

Two layers. Document structure is ordinary Typst functions with named arguments,
so it is styleable, autocompleting and type-checked. Note-level content is a
compact string, because writing a riff as nested function calls is unbearable.

```typst
#import "@preview/fretwork:0.2.0": *

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

### Note values

Note values are **sticky**: one holds until another is written.

| Token | Value |
|---|---|
| `w` `h` `q` `e` `s` `t` | whole, half, quarter, eighth, sixteenth, thirty-second |
| `.` after a value | dotted — `e.` is a dotted eighth, `q..` doubly dotted |

An event written before any note value has `duration: none`. That is legal: the
model is allowed to be partially filled, and such a passage is spaced from its
columns instead of from its rhythm.

### Notes

A note is always `fret/string`, string 1 being the highest-sounding.

| Token | Meaning |
|---|---|
| `2/5` | fret 2 on string 5 |
| `11/3` | fret **eleven** on string 3 |
| `(2/5 2/4 0/6)` | a chord: notes in one column |
| `x/5` | dead string 5; a bare `x` deadens every string |
| `r` | rest |
| `@E5` | names a chord above the next event; `@"C#m7 add9"` when it contains spaces |
| `"Harm."` | a playing instruction above the next event |
| `!mf` | a dynamic, below the staff, holding until the next one |
| `g` `G` | the next event is a grace note — before the beat, or on it |
| `//` | comment to end of line |

### Techniques

Suffixes, always after the string number.

| Token | Technique |
|---|---|
| `5/3h7` `7/3p5` | hammer-on / pull-off to the given fret |
| `5/3s7` `5/3S7` | legato slide / shift slide |
| `5/3h` `5/3s` | the same, running to the next event on that string instead of naming a fret — the form that joins two notes with values of their own, and the only one that crosses a barline |
| `5/3sU` `5/3sN` | slide *out* of the note, up or down — it reaches nothing, so it names a direction where a link derives one |
| `7/3b` `7/3b(1/2)` | bend, a whole step or the size given |
| `7/3br` `7/3B` `7/3Br` | bend and release / pre-bend / pre-bend and release |
| `7/3v` `7/3V` | vibrato / wide vibrato |
| `12/3*` `5/3PH` `5/3AH` `7/3HH` `7/3TH` | natural / pinch / artificial / harp / tap harmonic |
| `7/3~` | tie to the next note on that string |
| `7/3g` | ghost note, printed in parentheses |
| `7/3>` `7/3^` `7/3!` `7/3-` | accent / marcato / staccato / tenuto |
| `7/3T` | tapping |
| `7/3tr9` `7/3tr` | trill, to the given fret or unspecified |
| `7/3TP` | tremolo picking |
| `7/3PS` | pick scrape |
| `7/3W` | vibrato with the tremolo bar, printed `w/ bar` |
| `7/3F` `rF` `xF` | fermata — over a note, a rest or a bare mute |
| `(…)A` `(…)An` `(…)Au` | arpeggiate, thick string to thin or the reverse |
| `(…)R` `(…)Rn` `(…)Ru` | rake, likewise |
| `7/3n` `7/3u` | downstroke ⊓ / upstroke ∨ |
| `0/4SL` `3/3PO` `x/3DS` | bass: slap / pop / dead slap |

A hammer-on, pull-off or slide target prints as a further number on the same
string, joined by a slur or a slide line, and shares the parent event's note
value. Notes needing independent rhythm are written as separate events.

Suffixes chain — `5/3h7v` — and a suffix after a closing parenthesis binds to
every note of the chord: `(2/5 2/4 0/6)~`.

A rest and a bare mute have no note to hang a suffix on, so `r` and `x` take a
suffix chain of their own and record it on the event. That is what lets `rF`
hold a rest, the one place a fermata is as common as it is over a note.

An arpeggio's direction letter is consumed by the arpeggio, so `Au` is one
technique rather than an arpeggio followed by a stray upstroke. Songsterr
separates a *brush* from an arpeggio by speed alone and draws the two
identically; this is the one mark, not two the page could not tell apart.

### Groups

One mechanism for spans, tuplets and endings.

```
{PM: e 0/6 0/6 0/6 0/6}    palm mute over the span
{LR: … }                    let ring
{3: e 0/6 2/6 3/6}          triplet — a numeric name is a tuplet
{7/4: … }                   an explicit tuplet ratio
{V1: … } {V2: … }           first and second endings
{cresc: … } {dim: … }       growing louder or quieter
```

Groups nest. Spans and tuplets are recorded on each event rather than as index
ranges, so a group split across a system break still draws correctly on both
halves.

### Barlines and the time signature

`|` single · `||` double · `|.` final · `|:` repeat start · `:|` repeat end ·
`:|x3` with a repeat count, printed as "Play 3 times" over the sign.

`[7/8]` at the start of a measure sets the time signature there. Brackets,
because the grammar has already spoken for a bare `7/8` — that is fret seven on
string eight — and because nothing else in either syntax uses one. `tab(time:)`
sets it for a whole passage; either way it is printed once, at the start, and
`show-time: false` suppresses it on the second and later blocks of one piece.

### Lyrics

Syllables are **not** written inline. They would drown the notes, and there is
already a pattern for data that runs parallel to the music and lines up with it
event by event — the ASCII annotation rows and the `rhythm:` argument. Lyrics
follow it:

```typst
#tab(lyrics: "Some- thing I can ne- ver say _", ```
q 0/6 2/6 e 3/6 3/6 …
```)
```

Space-separated syllables, spent in order over the events that are actually
sung. Rests and grace notes are passed over, and so is the far end of a tie: it
is not a new attack, and it keeps the syllable of the note it is held from. A
trailing `-` hyphenates into the next syllable; `_` spends a note without
printing anything on it, which is how a word held over several notes is written.

Several verses are `lyrics: ("verse one …", "verse two …")`, one lane each.
Syllables left over after the last note are reported on the page rather than
dropped in silence — miscounting a verse against the music is the one mistake
this syntax makes easy.

The syllable is stored **on the event**, as `chord` and `text` are, rather than
in a parallel array: an array would reintroduce exactly the index bookkeeping
across system breaks that spans and tuplets are recorded per event to avoid.

### Unambiguity

The grammar was audited specifically against multi-digit frets. Three rules
guarantee no expression can be read two ways.

1. **Whitespace separates events and nothing else.** A fret number is a maximal
   run of digits, so `11/3` can only be fret eleven; two separate first frets
   are `1/3 1/3`. The same holds inside a chord: `(11/3 12/2)`.
2. **A character means one thing standing alone and another inside a token.**
   Alone it is a note value or a rest (`s` a sixteenth, `t` a thirty-second,
   `x` a dead string, `r` a rest); inside a token's suffix chain it is a
   technique. A token contains no whitespace, so the two never meet.
3. **Suffixes are matched longest-first from a fixed table**, and those taking a
   fret argument require digits immediately after.

The audit found and fixed two real collisions in the first draft, which is why
the grammar reads as it does:

- **`/` meant both string separator and slide.** `5/7` was indistinguishable
  from "fret 5 on string 7". Slides moved to the `s`/`S` suffix, which also
  matches the commonest ASCII tab convention.
- **Parentheses meant both chord and ghost note.** `(7)/3` could not be told
  from the start of a chord. Ghost notes moved to the `g` suffix, so a
  parenthesis at the start of a token is always a chord and one inside a token
  is always a bend size.

Parse errors name the measure and token, and show the offending line with a
caret:

```
tab: measure 3, token 7: unknown duration 'w2'
  q 0/6 w2 3/6
        ^
```

`validate` separately reports bars whose length disagrees with the time
signature. It is advisory, not fatal: a pick-up bar is exempt, and unknown
durations are reported as unchecked rather than wrong. `tab` and `ascii-tab`
print what it finds on the page, because Typst has no user-level warning channel
— `panic` is its only diagnostic and it is fatal. `warn: false` silences the
report once a sheet is as intended.

Both parsers accept a raw block as well as a string, and unwrap it through
`source-text`. That indirection is not decoration: Typst takes the first token of
a *single-line* raw block as a language tag and strips it, so ``` ```q 0/6 2/6```
``` arrives as `0/6 2/6` with `lang: "q"`. Every note value is a bare word, so the
leading one would vanish without a sound and the bar would simply come out with
no rhythm.

## ASCII tab import

A second entry point takes pasted ASCII tab and parses it into the **same
model**, so the entire rendering chain is reused unchanged.

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

**How it is read:**

- String labels (`e|`, `B|`, `E|`) are used when present; otherwise the first row
  is the highest string. A block whose labels match the tuning reversed is read
  the other way round.
- **Column position carries simultaneity**: notes in one column form a chord.
- **Multi-digit frets**: adjacent digits are one fret, digits parted by filler
  are separate strikes. This is the universal convention and the only reading
  that makes sense of both `-11-` and `-1-1-`.

  Adjacent digits are one fret only as far as that fret exists, since half the
  sources hand-typed anywhere write `-33-333-` for eighth notes on the third.
  A number is at most two digits, no higher than the 24th and never opened by a
  `0`, so `-77-` is two sevenths, `-333-` three thirds and `-010-` the open
  string then the tenth. What remains ambiguous is the pair that reads both
  ways — `-11-`, `-22-` — where the convention wins and can be wrong. Brackets
  delimit the number explicitly: inside `( )` or `< >` the digits are one fret
  however many there are, which is also how a fret above the 24th is still
  written and still reported.
- `|` becomes a barline, and the repeat colons around one are read as music:
  `|:` opens a repeat, `:|` closes one, `:|:` closes one and opens the next where
  a repeated section runs straight into another, and `:|x3` names how many times
  to play it. A count is read only after `:|`, since `x` is also a dead string —
  `|x3` mid-row is a muted string and then the third fret. Adjacent strokes are
  one mark, so a repeat written against a double barline (`||:`) keeps it.
- Techniques are read inline: `h` `p` `s` `/` `\` `b` `r` `~` `v` `x` `*` `t`,
  `( )` for ghost notes and ties, `< >` for a natural harmonic. `7b9` bends to
  the pitch of fret 9 — two frets to a step.
- **A mark with no note left to reach is the note slid off**: `-15\-------` at
  the end of a row is a slide out, and the arrow says which way the pitch leaves
  — `/` climbs, `\` falls, and a bare `s` names no direction and falls, which is
  what sliding out of a note ordinarily does. A hammer-on or pull-off to nowhere
  means nothing and is still dropped. The mark used to be dropped in every case,
  so a figure that trails away came out as a plain note.
- **A linking mark's target is a second number inside the event unless the source
  says otherwise**, in one of two ways. Filler between the mark and its target —
  `5-h-7`, and above all a target in the *next bar* — makes it an event of its
  own, joined by an arc that runs from one to the other; that case used to
  produce both, a phantom fret beside the first note and the real one after the
  barline. A note value over the target's column says the same thing about the
  adjacent form: `3/7` with a `q` over the 7 is a slide into a note that has its
  own rhythm, while `3/7` left alone is the compact pair the legend sets.

  Nothing else can say it. In ASCII every character has a column, so `3/7` spends
  one on its target exactly as `3-/-7` does, and the `R:` row is the only place
  the source can give that column a value of its own. Reading it as a label
  regardless left the target with no rhythm — it is not an event — and the value
  written over it, claimed by no note, came out as a rest the source never had.
- **A fret in parentheses that repeats the note before it on the same string is
  a tie**, and any other fret in them is a ghost note. There is no other way to
  write a held note in ASCII tab: `~` is vibrato there, whatever the native
  syntax uses it for, and the convention that survives is to set the note that is
  not struck again in brackets — which is also how this package prints the far
  end of a tie, so what it writes reads back. The two print alike either way, the
  arc being what separates them, so the reading only matters to the model; but
  reading it wrong turns a note held over into a second strike.

  The tie is attached to the note the string is held *from*, which is where the
  native syntax writes it and where `mark-tie-targets` starts. A note struck in
  between ends what the first was sounding, so `-5-7-(5)-` is a ghost note.
  Barlines do not interrupt the run, since a tie across one is ordinary
  notation, but the end of a *block* does: the reading is made row by row, as
  every other linking mark in a row is, so a note held across a system break
  arrives as a ghost note.
- `<12>` is how Power Tab and Guitar Pro export a natural harmonic where the
  native syntax writes `12/3*`. It is a dialect of ASCII tab rather than of any
  one site, so it is read here rather than left to whatever fetched the file.
- Ultimate Guitar's own harmonic marks are read against the fret: `NH` `PH` `AH`
  `HH` `TH`, natural, pinch, artificial, harp and tap. Capitals collide with
  nothing, since every technique letter in the chain is lower case, and a
  harmonic names no target fret, so `7PH5` is the harmonic and then the fifth.
  They used to reach a tab only through a `T:` row, which put the right word over
  the right column and left the model none the wiser; now the model carries what
  the source said and `ascii-to-dsl` writes it back out.

  A source that writes the mark on a line of its own above the staff still needs
  the `T:` row: recognising an unprefixed line of marks and placing it on the
  right note is a separate design, and guessing at it would be worse than asking
  for the prefix.
- A bend must rise: `5b3` attaches no arrow and is reported, since `(3−5)/2`
  steps is not a bend. The note itself survives.
- A bend later in a chain measures from where the chain has arrived, not from
  the struck fret: `5h7b9` bends the hammered 7 up to 9, one step.
- `pb` is a pre-bend and `pbr` a pre-bend and release, which is Ultimate
  Guitar's own spelling. Unambiguous for the same reason `hb` is: a pull-off
  always writes its target as digits, so a `p` against a `b` can only be this.
  Read as a plain `p` the row was *misread* rather than impoverished — the
  pull-off was held for the next note and hung off it, inventing a slur the
  source never had.
- `hb` and `fb` spell a bend's size out in letters instead of implying it from a
  target fret: half bend and full bend. Despite `h` otherwise meaning a
  hammer-on this is unambiguous, because a hammer-on always writes its target as
  digits, so an `h` pressed directly against a `b` can only be a size. A spelled
  size already says how far the bend goes, so digits after it are the next note:
  `7fb5` is a full bend on the 7th fret and then the 5th. `fbr` and `hbr` fold
  the release in, as with any other bend.
- A syllable with no note near it gets a **column of its own** rather than being
  dropped: a singer carries on where the guitar stops, and a bar the
  transcription leaves empty is exactly where that happens. The event built
  there is a rest with no duration — nothing sounds on the guitar, and the
  source says when a word is sung but not for how long — so it draws no glyph
  and the bar stays empty under the words.
- A bar with nothing written in it is a bar of **silence**, and becomes one
  measure holding a rest as long as the bar. A bar carrying only syllables is
  one too, and keeps that rest ahead of them. It used to be dropped, which lost a
  whole block when every bar was empty — an outro where the guitar has stopped
  and only the voice carries on then left no trace. Adjacent barlines are one
  mark: `||` closes a measure once, not twice with a bar of rest between.
- Blocks of N rows stacked one after another concatenate into one continuous
  passage, not into separate pieces.
- Lines that are neither string rows nor known annotation rows are skipped with
  a warning; real tabs are full of headings and comments.

**The honest limitation:** ASCII tab carries almost nothing beyond fret
positions and the barlines between them — no note values, time signature,
tuning, sections or chords.
Without note values there are no stems, no beams and no optical spacing, so the
default is to space the staff from the source's own column positions:
considerably better than monospaced text, but with no rhythm lane.

### Supplying what is missing

The governing principle is that **enrichment is optional and incremental**.
Nothing is required, a bare paste always renders, and every fact added improves
the result. Three mechanisms, in the order to reach for them.

**1. Column-aligned annotation rows** — the primary mechanism. Extra rows in the
same block, prefixed with a key and a colon. Being column-aligned is the whole
point: a fact attaches to exactly the column it describes, so there is no need
to count events and a tab can be annotated partially.

```typst
#ascii-tab(```
S:   Main Riff
C:   E5          G5      A5
R:   q   q   e e e       e
PM:  --------
e|---0---2---3-5---------7--|
…
```)
```

| Prefix | Content |
|---|---|
| `R:` | note values — **the DSL's own tokens** (`w h q e s t`, dots), in either case, plus `3:` to open a tuplet over the next three events. A value over a column where nothing is struck is a rest that long |
| `C:` | chord names |
| `L:` | sung syllables — one row per verse, in the order they appear |
| `S:` | section heading |
| `PM:` `LR:` | bracketed spans — a run of dashes marks the extent |
| `1:` `2:` | first and second endings — a run of dashes marks the measures, which get volta brackets |
| `T:` | free playing instruction (`Harm.`, `w/ bar`) |
| `D:` | dynamics — a misspelt one is reported rather than printed, since a reader cannot tell one that means nothing from one they do not know |

`R:` reuses the DSL's tokens deliberately: no second notation to learn and no
second parser to keep in step. Case is ignored, which is what lets a Power Tab
or Guitar Pro export's own duration line — `W H Q E S`, dotted the same way —
be pasted in unchanged, so an exported tab arrives with real rhythm instead of
being spaced from its columns. `C:` and `T:` rows split on runs of two or more
spaces, so an instruction may contain single spaces. Each token attaches to the
single nearest event, so two events a column apart cannot both claim it.

**A block may carry more than one `R:` row**, and they are read together, column
by column. That is what makes `3:` writable in a densely spaced tab: a tuplet
opener needs whitespace on both sides, and a row whose events stand four columns
apart has no room for it between two values. Written on a row of its own it lands
on the column it belongs to and the values keep theirs:

```typst
R:          3:
R:  q   q   q   q   q
C|--3---3---5---3---2--|
```

Three quarters in the time of two, which is what lets a bar of five quarters add
up to four beats — and the bar disagreeing with the meter is how a missing tuplet
announces itself.

**Rests are written in the `R:` row**, because ASCII tab spells silence as
filler and has nowhere else to put them. A value standing over a column where
nothing is struck is a rest that long: `R: q q q q` over a bar holding one note
says the other three beats are silent, which is what lets such a bar add up to
its meter. A bar with nothing said about it is still one bar-long rest; one whose
rests are named is divided as the row says, without a whole-bar rest ahead of
them.

**The notes claim their tokens**, each taking the nearest one within reach, and
what no note claimed is a rest where it stands. The obvious rule — a token with
no note within reach is a rest — cannot read a densely spaced row at all: where
events stand two columns apart, a value written over the gap between two of them
is within reach of both. *Animal I Have Become*, eight eighths over seven notes,
lost its rest that way and came out a beat short in every bar. Letting the notes
choose leaves over exactly the tokens no note wanted, whatever the spacing.

The reach is still the three columns the other rows resolve by, so a token that
merely misses its note is claimed rather than left to become a silence beside it.
What the rule cannot recover is a row shifted *as a whole*: with every token a
column off, each note takes the neighbour on the wrong side and the leftover
comes out at the end of the bar rather than in the gap it was written over. The
bar's length is right, its silence is in the wrong place, and the fix is to align
the row.

**2. Named arguments** for facts about the whole piece, which have no column:
`tuning:`, `time:`, `tempo:`, `capo:`, `anacrusis:`.

**3. Inference helpers** for the common cases, so that annotating every column
is not busywork:

- `rhythm: even(1/8)` — every event is an eighth. One word covers a large share
  of real riffs.
- `rhythm: fill` — spread each bar's events evenly across the time signature.
  Often musically wrong, which is why it must be asked for.
- `rhythm: "q q e e | h h"` — an explicit sequence, spent event by event.
- `lyrics: "Some- thing I can ne- ver say _"` — one string per verse, spent
  syllable by syllable, for a source with no `L:` rows to align against.

Annotation rows win over named arguments, which win over inference: a value
already set is never overwritten.

Beyond the three, `enrich: part => …` receives the parsed part and returns a
modified one, since the model is public API.

`#ascii-to-dsl(source)` prints the equivalent DSL source. Once a tab is fully
annotated it is as complete as one written by hand, and this is how it graduates
to the native syntax.

**Warnings, never silent misreadings:** rows of differing length, frets above the
24th, a row count that does not match the tuning, and unrecognised lines are all
reported. Uneven column counts are the most reliable signal of a broken source.

## Technique symbols

Following the Hal Leonard legend, and — where the legend is silent because it
always has a notation staff to fall back on — the Songsterr guide, which
renders tablature alone.

**Supported.** Hammer-on, pull-off, legato and shift slide, bend,
bend-and-release, pre-bend and pre-bend-and-release, vibrato and wide vibrato,
tremolo-bar vibrato, palm mute, let ring, dead string, tie, ghost notes in
parentheses, natural, pinch, artificial, harp and tap harmonics, accent,
marcato, staccato and tenuto, down- and upstroke, tapping, trill, tremolo
picking, pick scrape, arpeggiate and rake with a direction, bass slap, pop and
dead slap, fermata, grace notes before and on the beat, dynamics and gradual
changes, the time signature and changes to it, first and second endings, repeat
signs and repeat counts.

**Not supported**, with the reason:

| From the legend | Why not |
|---|---|
| Rhythm slashes, musical staff | Out of phase 1 by design |
| Unison bend | Two notes bent to one pitch needs a bend that spans strings, not one anchored to a note |
| Vibrato bar dive / scoop / dip | Needs a pitch-contour sub-model, not a technique flag. `7/3W` covers the plain bar vibrato, which is the one member of the family that is only a flag |
| D.S., D.C., Coda, Fine | The segno and coda glyphs are drawn and exported; the navigation markup that would place them is not built |
| Rhy. Fig., Riff, Fill, tacet labels | Available as free text via `"…"`, not as first-class labels |
| Rasgueado, golpe, wah-wah, sustain pedal | Niche enough that the syntax would cost more than the marks are worth |
| The swing-feel graphic | `song(tempo-words: "Swing 8ths")` carries the text form, which is what a tab reader acts on |

## Visual requirements

Looking good is a stated goal, so it is specified as testable requirements.

1. **A string line never runs through a fret number.** The published sheets
   achieve this with an opaque white patch behind the digits; this package draws
   the lines as segments with a computed gap instead. The result looks the same,
   also survives a tinted page background, and costs nothing extra because the
   glyph width is already measured for spacing. `theme(mask: "box")` selects the
   opaque patch.

   The gap hugs the digit: measured off a published rock tab it is about 0.8
   staff spaces wide for a digit of roughly 0.6, leaving some 0.1 either side. A
   wider one reads as a hole in the staff rather than as room for a number.

   The **TAB mark is knocked out the same way, letter by letter**: a line is
   broken only where a letter actually sits on it. Breaking every line across the
   mark's full height clips the outermost ones, which have no letter over them,
   and that reads as a hole rather than as a knockout.
2. **Optical, not proportional, spacing.** Event width grows as
   `duration ^ 0.6`, with a floor set by the measured glyph width so a `12`
   claims more room than a `0`. Proportional spacing would strand long notes in
   white space and cram fast passages together.
3. **Justification is distributed proportionally** to the measures' natural
   widths, never equally between them. A final system below 65 % fill is left
   unstretched, the way the last line of a paragraph is.
4. **Everything derives from one unit**, `staff-space`: line weights, stem
   lengths, beam thickness, type sizes. Changing it rescales a whole sheet
   without the proportions drifting.
5. **Marks above the staff pack sideways, not into fixed lanes.** A mark sits as
   close to the staff as it fits, and things stack only where they are actually
   in each other's way — which is what published sheets do. Reserving a lane per
   kind for a whole system makes it taller than it needs to be whenever two
   marks are in different bars. Marks of one kind move together, so every palm
   mute in a system stays at one height; when two kinds do collide, the one that
   belongs closer to the staff wins the lower level.
6. **`TAB` is stacked vertically** at the start of every system.
7. **Barlines are heavier than string lines**; closing and repeat forms use the
   conventional thin-then-thick pair. `theme(repeat-style: "ornate")` gives the
   repeat signs the flared serifs of an engraved one, curling inwards over the
   music as engraved rock tab does; `"plain"` is the default.
8. **A system never breaks across a page.**
9. **Slurs are drawn as tapered arcs that keep clear of the line above.**
   A slur is a filled lens — swelling in the middle, coming to a point at each
   end — because a constant-thickness stroke reads as a wire. Its height follows
   its span: a long one peaks 1.36 staff spaces up, as the Hal Leonard legend
   does, and crosses the line one space above at a clear angle; a short one stays
   flatter and sits inside the string spacing. Whatever the span, the apex is
   then pushed out of the band around that line, because an apex landing on it
   runs along it and reads as merging with it. The tail sits at 0.52, lower than
   the legend's 0.74, so a short slur hugs its digits instead of stranding them.

   Stacked numbers in a chord force the slur to leave the digit's *side*. It
   attaches at the digit's upper part rather than level with its middle: level
   with the line, the arc and the line enclose a sliver and read as one closed
   shape.

   **A tie hangs under its line and curves down**, mirroring the slur. Drawn
   upward it is the same mark as a hammer-on's slur, and nothing in the picture
   tells the reader which is meant. Hal Leonard never faces this, because it
   draws no tie arcs in tablature at all — the held note is simply not struck
   again, or is set in parentheses, with the tie left to the notation staff — so
   the reference here is Songsterr, which renders tablature alone and flips the
   tie. Ties stay shallow, inside their own string's space, since the line below
   is close; a chord's tie leaves the flanks, shallower still, because under a
   stacked number the next string is right there.
10. **A bracketed span is closed by a tick that crosses its rule**, not one that
   merely hangs off it, and the dashed rule meets its label near the baseline
   rather than at the cap. Dash and gap are each about 0.3 staff spaces.
11. **A bend arrow rises from the fret number it belongs to**, not from a fixed
   height above the staff. The same bend must sit the same distance above its
   number whichever string it is on, and adding an accent elsewhere in the
   system must not move it. A pre-bend is already bent when struck, so its
   arrow is straight where an ordinary bend's curves.

   **A bend that is held carries a dashed rule on from the arrowhead**, at the
   height it reached, for as long as the pitch stays up. A bent note that is
   tied is a bend held: the rule runs to the end of the last tied event — to
   where the sound stops, not to where its number is — and crosses barlines with
   it. Without the rule a held bend reads as bent and released at once, and how
   long it is held has to be guessed from the ties.

   **A release is therefore two arrows, not one stroke.** Up, hold, down is
   three things, and the hold has to sit between the two arrowheads where it can
   be seen; a stroke already curving downwards has nowhere to hang a horizontal
   rule. The Hal Leonard legend draws the single stroke and this followed it
   until the hold arrived — the one place the legend is departed from, and
   Songsterr, which does draw the hold, splits the arrows for the same reason.
   Measured there, the two arrowheads stand about 2.2 staff spaces apart with
   the descent taking the last 0.7 of it. The gesture is kept inside the event's
   own slot, so a bend in a bar of sixteenths tightens up rather than running
   into the next event.
12. **The time signature is set on the staff, not above it**, with the string
   lines running behind the numerals as they run behind the `TAB` mark. Read off
   `research/TNT_0001.png`: each numeral is 1.22 staff spaces tall and the two
   stack tight against the staff's middle, all but touching, so the pair reads
   as one mark. Printed at the start of a passage and wherever it changes — not
   on every system, which a clef does but a signature does not, since it does
   not affect how the notes in front of the reader are read.

13. **A grace note is an ornament, not a beat.** Its numbers are set at two
   thirds size, and it is never beamed to the note it leans on — beaming the
   two would say they share a beat, which is the one thing a grace note does
   not do. It is spaced by a fixed narrow width rather than by its note value,
   and `sounding-duration` returns zero for it so that a bar containing one
   stays *checked* rather than becoming unmeasurable.

   In the rhythm lane it is a **miniature of a real value**, not a special
   shape: a short stem with a beam stub, and a beam rather than a stub when two
   fall in a row. It **hangs from the top of the lane** instead of standing on
   the foot the real stems stand on, so its beam floats above the beam line —
   which is what keeps it clear of a half note, the other short stem in this
   notation. A half note's stem occupies the lower half of the lane and carries
   nothing; a grace note's the upper half and carries a stub. Read off
   Songsterr's legend and confirmed in bar 4 of *Heart-Shaped Box*, where a lone
   one sits between ordinary stems at about two fifths of their length.

   A stroke through the first stem, running down to the right, marks the kind
   squeezed in ahead of the beat; one starting *on* the beat is written plain.

14. **The rhythm lane sits under the staff and its values are bars, not
   noteheads.** A beam runs along the bottom of the lane and the stems rise from
   it towards the music; beam levels stack upwards from the primary, which is
   the lowest. A quarter and longer is a bare stem, and a lone eighth or shorter
   gets a beam stub — left or right — rather than a flag. A tuplet brackets
   below the beam with its numeral in a break at the centre. All of it follows
   Songsterr, which renders tablature alone and therefore had to solve the same
   problem: with no notation staff there is no notehead to hang a value on.

   **A beam is a seventh of a stem thick, and the air between stacked beams is
   the same again.** Measured off the reference's vector art rather than judged
   by eye: 2 units of beam against a 14-unit stem, 2 units between levels. Half
   a staff space, which is what this was while the lane sat above the staff,
   reads as a slab below it — and a run of thirty-seconds as one solid block.

   **A tremolo slash is half a beam thick**, 0.78 spaces wide, and the three of
   them hang from the *top* of the stem, a quarter of a space apart. Hung from
   the top rather than centred, because the reference sets one, two and three of
   them all starting at the same height — and because that is what keeps them
   off the beam whatever the note value. The thickness is the number that
   matters: at a full beam's weight three slashes fuse into a block.

   **An augmentation mark is a square, exactly a beam thick**, set to the right
   of the stem in the slot immediately *above* the beam stack: one slot per beam
   the note carries, so a quarter's rests on the foot itself and a sixteenth's
   clears both of its beams. Checked against all five of the reference's worked
   examples. The rule matters because the square and the beam are the same
   weight, so anything drawn on the beam line disappears into it.

   Two values fall out of that. A **half note is a quarter's stem cut in two**,
   standing on the same foot — that proportion is structural rather than
   stylistic, so it lives in `render/rhythm.typ` and not in `theme.typ`. And a
   **whole note is written as nothing at all**, so a bar of them collapses the
   lane entirely rather than reserving a band of white space. Confirmed in the
   reference music, not just in the reference table: eight bars of one tied
   whole note each carry no ink in the rhythm row.

15. **A rest is drawn inside the staff, and carries no stem.** It stands where
   a note would have stood, because that is what it is; the rhythm lane carries
   note values only, and a rest is not one of them. Measured off
   `research/TNT_0001.png`, a tab-only sheet in exactly this format: its eighth
   rests are centred a little above the staff's middle, at 0.417 of the staff
   height, with nothing at all above them. The glyphs themselves are traced
   outlines rather than strokes, because an engraved rest has a thick-to-thin
   contrast along its length that a constant-weight stroke cannot express and
   reads as spindly beside the fret numbers without. They are set a fifth
   larger than the traced size, which puts an eighth rest a little above the
   1.17 staff spaces the sheet measures — at the traced size it sits too quiet
   on the page. A whole rest hangs
   below the nearest line and a half rest sits on it — the only thing that tells
   the two apart, and the reason the line runs behind them where it is broken
   around every other rest.

   The gap a rest knocks in a string line is taken from **the ink at that line's
   own height**, not from the glyph's box. A quarter rest is a narrow zigzag, so
   a line grazing its corner needs nothing like the room one through its middle
   does, and a fret number — measured type, with no gap between box and ink —
   would otherwise get a tighter gap than the rest standing beside it. The
   clearance around that ink is the same `gap-padding` a number gets, on every
   side.

16. **Lyrics ride on the guitar's own events.** A syllable is centred on the
   event it is sung on, exactly as the fret number above it is, and an event
   with nothing to sing is left blank. That is the layout the reference sheets
   use and the only one a single stream of events can express: a vocal line with
   a rhythm of its own would need a second voice, which belongs with the
   notation staff. A word held over several notes is written **once**, where it
   starts, with no extension line after it, and a hyphen is its own character
   centred in the gap between two syllables rather than tucked against the
   first.

   Syllables constrain each other **pairwise**, which no other mark on the page
   does: a syllable is routinely wider than the room its note bought, so the gap
   between two events has to hold half of each and air between them. That is a
   relation between two events rather than a width of one, and it crosses
   barlines, so it is applied in `layout/system.typ`, over the whole part in
   order, rather than in `measure-natural`, which sees one measure.

   The verses come **last, below everything else on the system** — below the
   rhythm, the dynamics and the count row alike. A dynamic marks the music and
   has to stay near the staff it marks: set above the lyrics it is pushed one
   row further out for every verse, until `mf` no longer reads as belonging to
   anything. Lyrics are running text and sit at the foot of the system for the
   same reason a caption does.

17. **Two-digit frets are centred on their column** and get a correspondingly
   wider gap. Fret numbers are set with tabular figures so that a bar mixing `0`
   and `12` keeps its columns straight.

18. **The far end of a tie is set in parentheses.** `~` is written on the note
   that starts the tie, so the note it runs into knows nothing about it; a
   forward pass over the piece marks it. Without that, a note held across eight
   bars reads as eight separate strikes. A ghost note prints identically and
   means the opposite — struck faintly rather than not struck at all — and the
   arc is what separates the two, which is the same ambiguity the published
   sheets carry. A note that is both still gets exactly one pair.
19. **A link comes in two forms, and the source picks between them.** A
   hammer-on, pull-off or slide written with a target fret — `5/3h7` — prints
   that fret beside its own number, the two sharing one note value, which is how
   the Hal Leonard legend sets them. Written without one — `5/3s` — it runs to
   the next event that plays the string, which keeps its own value and its own
   place. Only the second can join two independently timed notes, and only it can
   cross a barline, since a second number inside one event has nowhere to go
   after the bar ends.

   It is drawn the way a tie is drawn, and for the same reason: the note at the
   far end is a separate event, and finding it means searching forward through
   the system. Where it falls on the *next* system the mark is cut in two — a
   tail leaving the last note and an equal tail arriving at the first note of the
   line below. The landing system cannot see where the mark came from, so
   `mark-link-targets` leaves `linked-in` on the note that receives it, the
   mirror of `mark-tie-targets` and needed at the other end of the same geometry.
   Ties are drawn with both halves too, which they were not before.
20. **An arpeggio's arrowhead is a solid triangle as wide as it is tall** —
   0.54 staff spaces each way, with a flat base, which is exactly twice the
   width of the squiggle it caps. The squiggle stops where the head begins
   rather than running under it. A bend's head is a different mark and keeps its
   own shape: narrower, longer and slightly concave at the base, as the Hal
   Leonard legend draws it. Given the bend's proportions, an arpeggio's head
   reads as a stray tick rather than as an arrow.

## Fonts

The published sheets use a geometric sans throughout — simple, clear, and heavy
enough to hold up at small sizes. That is the direction here. Every choice is
exposed through `theme(font: …)`, so the whole set changes in one place.

| Role | Choice | Why |
|---|---|---|
| **Fret numbers** | Montserrat Medium (500) | Closest to the reference. Geometric and round, and its `1` has a flag, which separates it from `7` — unlike Poppins, where `1` is a bare stem. Medium is deliberate: Regular is too thin against the string lines, Bold too clumsy. |
| — fallback | Noto Sans | Widely installed, and close enough in weight and width that a sheet set in it still reads as intended. |
| — fallback | Noto Sans SemiBold | Widely installed already, and serviceable until Montserrat is. |
| Title | Montserrat Bold, ~30 pt | The same family as the numbers holds the sheet together. |
| Credits, source | Montserrat Regular, 9–11 pt | |
| Section headings | Montserrat Bold, ~11 pt | |
| Tempo indication | Montserrat Bold, ~10 pt | The note value in it is a **vector glyph**, not U+2669: most sans faces have no coverage, and those that do draw it at an unrelated weight. |
| Chord names | Montserrat SemiBold, ~10 pt | Figures raised with `super()`, accidentals via `sym.flat` / `sym.sharp`. |
| Count row | Montserrat Bold Italic, ~9 pt | |
| Playing instructions | Montserrat Regular, ~8 pt | `P.M.`, `Harm.`, `let ring`. Upright, per the Hal Leonard legend. |
| Bend labels | Montserrat Medium, ~7 pt | `full`, `1/2`, `1/4`. |
| Copyright | Montserrat Regular, ~7 pt | |
| Dynamics | vector glyphs, not text | `f`, `mf`, `p` have very specific shapes no text face reproduces. |
| Lyrics | Libertinus Serif, ~8 pt | Convention, even under a sans-set sheet, and it keeps a sung word from reading as a playing instruction. One family and no fallback chain, unlike the music font: Typst embeds this one, so it resolves everywhere. |

Fret numbers are set with **tabular figures** so `10` and `12` occupy the same
width; otherwise columns drift apart in bars mixing one- and two-digit frets.

Typst ships only Libertinus Serif, New Computer Modern and DejaVu Sans Mono, so
Montserrat must be installed locally. `theme.font` is a fallback chain,
`("Montserrat", "Noto Sans", "DejaVu Sans")`, so a sheet still sets reasonably
without it. This applies to **text only** — the music symbols are vectors and
never need a font.

Typst warns once for every family in a chain it cannot find, whether or not a
later one matches, and position in the list makes no difference — only presence
does. A machine without Montserrat therefore sees about fifteen warnings per
compile. That was measured, and the chain was kept anyway: the warning names
exactly what to install, the count does not grow with the document, and the
alternative is a default that silently abandons the design. Callers who would
rather not see them pass their own chain to `theme(font: …)`.

Generic CSS-style names are not an option: `Sans` and `sans-serif` both fail to
resolve, because Typst matches the family name recorded in the font file and does
not consult fontconfig's aliases. `DejaVu Sans` is the closest thing to a family
present on every Linux system.

## Page layout

Modelled on the reference sheet: source or arranger small at the top left, the
title large and centred, the writing credits right-aligned beneath it, the tempo
indication and first section heading left-aligned above the music, the copyright
centred in the foot, and a running head on continuation pages.

## Architecture

```
src/
  lib.typ            public API
  rational.typ       exact durations
  model.typ          the data model every syntax parses into
  tuning.typ         tunings, string + fret → pitch
  theme.typ          staff-space and every measurement derived from it
  page.typ           song(), title block, head and foot
  parse/
    dsl.typ          tokenizer, parser and writer for the native syntax
    ascii.typ        ASCII tab → model
    lyrics.typ       the syllable syntax, spent event by event
    errors.typ       located parse errors
  layout/
    spacing.typ      natural width per event and per measure
    beams.typ        beam grouping from the time signature
    system.typ       line breaking and justification
    lanes.typ        vertical stacking
  render/
    glyphs.typ       vector glyphs
    tabstaff.typ     string lines with gaps, TAB mark, fret numbers, rests,
                     and everything anchored to a string: slurs, slides, bends
    meter.typ        the time signature's stacked numerals
    rhythm.typ       stems, beams, stubs, grace stems, count row
    lyrics.typ       one lane per verse, at the foot of the system
    marks.typ        the lane machinery both mark lanes are built from
    techniques.typ   marks in the lane above: spans, vibrato, articulations
    dynamics.typ     marks in the lane below: dynamics, cresc. and dim.
    voltas.typ       the brackets over endings, and the repeat counts
    chordnames.typ   chord names with accidentals and raised figures
```

The layout engine runs inside `layout(size => …)`: measure the natural widths,
pack measures into systems greedily, distribute the surplus proportionally, then
position everything absolutely with `place`.

The split between the two technique renderers is by what a mark is positioned
against. Anything anchored to a **string** — the second number of a hammer-on,
the line of a slide, a bend arrow — is drawn by `tabstaff.typ`, because its
height depends on which string the note is on. Anything belonging to a **lane**
above the staff is drawn by `techniques.typ`, and one belonging to the lane
below it by `dynamics.typ`. Those two share `marks.typ`, which owns the packing
rule, the labelled dashed span and the lane plumbing: a mark is
`(x0, x1, height, draw: y => …)` and nothing in there cares what it is. Marks
anchored to a string reach
outside the staff, so `tabstaff.typ` reports how far with `overflow-above` and
`overflow-below`, and the staff's lane reserves exactly that much instead of
relying on the box not clipping.

Every closed vector path is closed with `curve.close(mode: "straight")`. Typst's
default is `"smooth"`, which rejoins the last point to the first with a
tangent-matched curve; since the two coincide in all of these shapes, the default
grows a spike out of the figure — visible as a slur that appeared to start before
its note.

Durations are exact rationals rather than floats. Tuplets introduce thirds and
fifths a binary float cannot represent, and both bar-length validation and beam
grouping compare durations for equality.

## Room for a notation staff

Three decisions make phase 2 additive rather than a rewrite.

1. **Pitch is already in the model.** String, fret and tuning determine the
   sounding pitch unambiguously, and `to-pitch` has been exposed from the start.
   A notation renderer needs no information the DSL does not already carry, so
   no new syntax layer is required.
2. **Rhythm and spacing are staff-agnostic.** Beam grouping, event widths and
   line breaking all work against the model, never against the tab renderer. A
   notation staff reuses them unchanged — and the x-positions the tab staff uses
   are exactly the ones a notation staff must share for the two to align.
3. **Vertical layout is a list of lanes.** Each lane declares a height and a
   draw function taking the shared x-positions, and collapses when empty. Adding
   notation means adding a lane.

A notation staff additionally needs work that is deliberately not anticipated
here: noteheads, ledger lines, accidentals and their stacking rules, second
displacement in chords, and slurs.

## Verification

- **Unit tests** (`tests/run.sh`): the parsers against the expected model,
  `to-pitch` against known pitches, beam grouping, spacing and line breaking at
  known widths. Every test document is a plain Typst file whose assertions panic
  on failure, so the compiler's exit status is the result.
- **Error paths**: one fixture per parser error category in `tests/errors/`,
  each declaring the substring its message must contain. The runner also checks
  that every message carries a source location.
- **Round trip**: an annotated ASCII tab, written out as DSL and read back,
  must give the same model.
- **Example documents** (`tests/examples.py`): every example is rendered and its
  PDF read back, and any `validate` report printed on the page fails the run.
  The examples are documentation, so a bar that does not add up is a red block
  in the package's own showcase — which is exactly how a run of them was found,
  one reader report at a time, once the reports stopped being swallowed.
  `demo.typ` carries one on purpose, under the text explaining it, and its count
  is pinned rather than exempted.
- **Image regression** (`tests/run.sh visual`): one fixture per feature area in
  `tests/visual/`, each rendered and compared pixel by pixel against a reference
  committed in `tests/refs/`. A difference writes a diff image with everything
  that moved tinted red. Every visual defect this package has had was found by
  looking at the output and none of them failed an assertion, so this is the
  only mechanism that can catch a change in what the sheet looks like.

  Rendering is reproducible only for a given renderer and a given set of fonts,
  so the references record both and the comparison **skips** rather than fails
  when they do not match: a reference rendered by another Typst version says
  nothing about whether a change was correct. The fixtures therefore pin a font
  that is widely installed rather than the theme default, which is a variable
  font. `tests/run.sh --update-refs` re-pins them, and the diff images are what
  the re-pinning is reviewed against.
- **Manual visual review**: `examples/demo.typ` is a tour of every feature and
  `examples/songsheet.typ` is a complete sheet to compare against published
  guitar tab. Where a figure above cites a measurement, it was taken by
  rasterising a published sheet and reading the pixels, not by eye. The sheets
  themselves are not distributed with the package.
  This remains the final acceptance criterion for "looks good": the image
  regression can only say that nothing changed, never that what it pinned was
  right in the first place. `examples/glyphs.typ` shows every vector glyph at three sizes
  inside its declared metric box, so a glyph that overflows its own metrics is
  immediately visible, and `examples/bends.typ` puts the same bend on all six
  strings — and every kind of bend side by side — for comparison against page 1
  of the Hal Leonard legend.
