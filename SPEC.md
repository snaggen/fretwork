# tablature — specification

Guitar tablature of publishing quality for Typst.

The target is a song sheet that looks like the published material this package
was designed against: rock tab with rhythm stems and a count row, in a page
layout with title, credits, section headings and a copyright footer. The symbol
set follows Hal Leonard's *Guitar Notation Legend*, which is the industry
reference for how professional guitar books notate technique.

## Scope

Phase 1 is **tablature only**. There is no notation staff, no chord diagrams and
no lyrics. The data model and the layout engine are nevertheless built so that a
notation staff can be added later without rewriting either — see
[Room for a notation staff](#room-for-a-notation-staff).

| | |
|---|---|
| In phase 1 | Tab systems, barlines, repeats and endings, technique symbols, section headings, title block, rhythm stems and the count row, chord names as text, ASCII tab import |
| Not in phase 1 | Chord diagrams, lyrics, several simultaneous guitars, rhythm slashes |
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
#import "@preview/tablature:0.1.0": *

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
| `//` | comment to end of line |

### Techniques

Suffixes, always after the string number.

| Token | Technique |
|---|---|
| `5/3h7` `7/3p5` | hammer-on / pull-off to the given fret |
| `5/3s7` `5/3S7` | legato slide / shift slide |
| `7/3b` `7/3b(1/2)` | bend, a whole step or the size given |
| `7/3br` `7/3B` `7/3Br` | bend and release / pre-bend / pre-bend and release |
| `7/3v` `7/3V` | vibrato / wide vibrato |
| `12/3*` `5/3PH` `7/3HH` | natural / pinch / harp harmonic |
| `7/3~` | tie to the next note on that string |
| `7/3g` | ghost note, printed in parentheses |
| `7/3>` `7/3^` `7/3!` `7/3-` | accent / marcato / staccato / tenuto |
| `7/3T` | tapping |
| `7/3tr9` `7/3tr` | trill, to the given fret or unspecified |
| `7/3TP` | tremolo picking |
| `7/3PS` | pick scrape |
| `(…)A` `(…)R` | arpeggiate / rake — a wavy line beside the chord |
| `7/3n` `7/3u` | downstroke ⊓ / upstroke ∨ |

A hammer-on, pull-off or slide target prints as a further number on the same
string, joined by a slur or a slide line, and shares the parent event's note
value. Notes needing independent rhythm are written as separate events.

Suffixes chain — `5/3h7v` — and a suffix after a closing parenthesis binds to
every note of the chord: `(2/5 2/4 0/6)~`.

### Groups

One mechanism for spans, tuplets and endings.

```
{PM: e 0/6 0/6 0/6 0/6}    palm mute over the span
{LR: … }                    let ring
{3: e 0/6 2/6 3/6}          triplet — a numeric name is a tuplet
{7/4: … }                   an explicit tuplet ratio
{V1: … } {V2: … }           first and second endings
```

Groups nest. Spans and tuplets are recorded on each event rather than as index
ranges, so a group split across a system break still draws correctly on both
halves.

### Barlines

`|` single · `||` double · `|.` final · `|:` repeat start · `:|` repeat end ·
`:|x3` with a repeat count.

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
- `|` becomes a barline.
- Techniques are read inline: `h` `p` `/` `\` `b` `r` `~` `x` `*` `t`, and `( )`
  for ghost notes. `7b9` bends to the pitch of fret 9 — two frets to a step.
- A bend must rise: `5b3` attaches no arrow and is reported, since `(3−5)/2`
  steps is not a bend. The note itself survives.
- `hb` and `fb` spell a bend's size out in letters instead of implying it from a
  target fret: half and full. Despite `h` otherwise meaning a hammer-on this is
  unambiguous, because a hammer-on always writes its target as digits, so an `h`
  pressed directly against a `b` can only be a size. Where a tab gives both, as
  in `3hb5`, the target wins — it names the pitch wanted rather than merely how
  far to travel.
- Blocks of N rows stacked one after another concatenate into one continuous
  passage, not into separate pieces.
- Lines that are neither string rows nor known annotation rows are skipped with
  a warning; real tabs are full of headings and comments.

**The honest limitation:** ASCII tab carries almost nothing beyond fret
positions — no note values, time signature, tuning, sections, repeats or chords.
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
R:   q   q   e e h       q
PM:  --------
e|---0---2---3-5---------7--|
…
```)
```

| Prefix | Content |
|---|---|
| `R:` | note values — **the DSL's own tokens** (`w h q e s t`, dots), plus `3:` to open a tuplet over the next three events |
| `C:` | chord names |
| `S:` | section heading |
| `PM:` `LR:` | bracketed spans — a run of dashes marks the extent |
| `1:` `2:` | first and second endings — a run of dashes marks the measures, which get volta brackets |
| `T:` | free playing instruction (`Harm.`, `w/ bar`) |

`R:` reuses the DSL's tokens deliberately: no second notation to learn and no
second parser to keep in step. `C:` and `T:` rows split on runs of two or more
spaces, so an instruction may contain single spaces. Each token attaches to the
single nearest event, so two events a column apart cannot both claim it.

**2. Named arguments** for facts about the whole piece, which have no column:
`tuning:`, `time:`, `tempo:`, `capo:`, `anacrusis:`.

**3. Inference helpers** for the common cases, so that annotating every column
is not busywork:

- `rhythm: even(1/8)` — every event is an eighth. One word covers a large share
  of real riffs.
- `rhythm: fill` — spread each bar's events evenly across the time signature.
  Often musically wrong, which is why it must be asked for.
- `rhythm: "q q e e | h h"` — an explicit sequence, spent event by event.

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

Following the Hal Leonard legend.

**Supported.** Hammer-on, pull-off, legato and shift slide, bend,
bend-and-release, pre-bend and pre-bend-and-release, vibrato and wide vibrato,
palm mute, let ring, dead string, tie, ghost notes in parentheses, natural,
pinch and harp harmonics, accent, marcato, staccato and tenuto, down- and
upstroke, tapping, trill, tremolo picking, pick scrape, arpeggiate, rake, first
and second endings, repeat signs and repeat counts.

**Not supported**, with the reason:

| From the legend | Why not |
|---|---|
| Rhythm slashes, musical staff | Out of phase 1 by design |
| Grace-note bend | Grace notes are not in the model; adding them touches the rhythm engine, not just a renderer |
| Unison bend | Two notes bent to one pitch needs a bend that spans strings, not one anchored to a note |
| Vibrato bar dive / scoop / dip | Needs a pitch-contour sub-model, not a technique flag |
| D.S., D.C., Coda, Fine | The segno and coda glyphs are drawn and exported; the navigation markup that would place them is not built |
| Rhy. Fig., Riff, Fill, tacet labels | Available as free text via `"…"`, not as first-class labels |

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
10. **A bracketed span is closed by a tick that crosses its rule**, not one that
   merely hangs off it, and the dashed rule meets its label near the baseline
   rather than at the cap. Dash and gap are each about 0.3 staff spaces.
11. **A bend arrow rises from the fret number it belongs to**, not from a fixed
   height above the staff. The same bend must sit the same distance above its
   number whichever string it is on, and adding an accent elsewhere in the
   system must not move it. A pre-bend is already bent when struck, so its
   arrow is straight where an ordinary bend's curves.
12. **Two-digit frets are centred on their column** and get a correspondingly
   wider gap. Fret numbers are set with tabular figures so that a bar mixing `0`
   and `12` keeps its columns straight.

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
| Lyrics (phase 2) | serif, e.g. Libertinus Serif | Convention, even under a sans-set sheet. |

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
    errors.typ       located parse errors
  layout/
    spacing.typ      natural width per event and per measure
    beams.typ        beam grouping from the time signature
    system.typ       line breaking and justification
    lanes.typ        vertical stacking
  render/
    glyphs.typ       vector glyphs
    tabstaff.typ     string lines with gaps, TAB mark, fret numbers,
                     and everything anchored to a string: slurs, slides, bends
    rhythm.typ       stems, beams, rests, count row
    techniques.typ   marks that belong to a lane: spans, vibrato, articulations
    voltas.typ       the numbered brackets over first and second endings
    chordnames.typ   chord names with accidentals and raised figures
```

The layout engine runs inside `layout(size => …)`: measure the natural widths,
pack measures into systems greedily, distribute the surplus proportionally, then
position everything absolutely with `place`.

The split between the two technique renderers is by what a mark is positioned
against. Anything anchored to a **string** — the second number of a hammer-on,
the line of a slide, a bend arrow — is drawn by `tabstaff.typ`, because its
height depends on which string the note is on. Anything belonging to a **lane**
above the staff is drawn by `techniques.typ`. Marks anchored to a string reach
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
