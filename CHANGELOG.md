# Changelog

## 0.4.0 — unreleased

### Added

- **`tunings.drop-c`** — standard down a whole step with the sixth dropped
  another, `D4 A3 F3 C3 G2 C2`. The tuning most often asked for after Drop D,
  and the one a great deal of the music this package is aimed at is written in.

### Fixed

- **A note may be short, accented and struck downward at once.** All three marks
  are drawn, where before only the first written survived — `(10/1 10/2)!>n` gave
  the staccato dot and dropped the accent and the stroke, and `)>n!` gave the
  accent and dropped the other two, so which mark reached the page came down to
  the order the suffixes happened to be typed in. The three are now separate
  kinds and stack: the length mark closest to the staff, the attack mark outside
  it, the stroke direction outside both — an engraver's order against a notehead,
  `⊓` and `∨` being the bowing marks, which are set clear of every other
  articulation and keep one row down the system.

  The length and attack marks are packed **by depth rather than by kind**, so
  each note's stack falls as far towards the staff as its own contents allow: an
  accent with nothing under it sits against the staff instead of holding the
  height of one that has a staccato dot beneath it. A row running level through
  the system is what a span looks like, and these belong to single notes.
- **A staccato dot no longer floats above the staff.** Every articulation was
  centred in a box sized for the tallest of them, so a dot — a quarter the height
  of an accent — hung about a third of a staff space clear of the staff while the
  accent beside it nearly touched. They now sit on their row's floor, and the box
  is measured from the glyphs rather than written down.

  More generally, a mark now sits on the inward edge of the level it is on rather
  than filling the level's height, so one tall member no longer lifts the short
  marks sharing it away from the staff.
- **An ornate repeat no longer lifts every mark in the system.** The serifs flare
  past the staff at both ends of a bar, and their reach was reserved as a band
  across the whole system: with `repeat-style: "ornate"` every accent, dot and
  stroke sat 1.15 staff spaces higher than with `"plain"`, however far from a
  barline it was. The lane now reserves the serifs at the two stretches where
  they stand and packs its marks around them. Below the staff the room is still
  reserved as a band — the rhythm lane's stems stand where the notes do and
  cannot pack around anything.
- **A stroke direction keeps air under it.** `⊓` and `∨` are open shapes as wide
  as they are tall, and at the packer's ordinary gap they read as resting on
  whatever is beneath — the top string line where the note is otherwise unmarked,
  an accent where it is not.
- **A mark over a note on the top string no longer prints on its fret number.**
  A number is centred on its line, so half of one on string 1 stands above the
  staff; the room below for the lowest string was reserved and the room above was
  not. It went unnoticed because an ornate repeat's serifs happened to reserve
  more than enough, and showed up as soon as they stopped.

## 0.3.0 — 2026-08-25

### Added

- **Words written for another part.** A verse may now be given as timed
  syllables — `lyric-at(measure, position, text)` — instead of a run spent over
  the notes. That is what lets a singer's line be printed under a guitar's staff,
  where the two share bars but not notes: counting through the guitar's notes
  would start the first word bars before anyone sings, while a moment means the
  same thing in both parts. Both forms may be mixed, one verse each, and every
  verse keeps the lane its position in the argument gives it.

  A bar is settled one way or the other, never both: where every syllable finds
  an event of its own it is hung on that event, and where any cannot — a bar the
  part rests through is a *single* whole rest, and a phrase sung across it is not
  — all of them are placed by their moments instead. Mixing the two put syllables
  in one bar on two different timelines, and they collided.

  A moment is read against the **notes**, not against the bar's width: events are
  spaced optically, so a fraction of the width lands nowhere near the note
  sounding then. And a bar is **widened for what is sung across it** — until now
  it was spaced only for what it plays, so a phrase over a resting bar was set in
  the room one whole rest had bought.
- **Verse numbers.** Where more than one verse is sung, each lane carries its
  number just before its first syllable, on the system where it begins. That is
  what tells one stanza's row from another's under a repeated passage, whose
  music is written once while its words are written out a row per time round.
  `verse-labels:` replaces the numbering with the caller's own, one per verse;
  `""` leaves a row unlabelled so two rows can share the number over the first,
  which is how one stanza spanning two times round is set. The number is set
  against the first syllable's *edge*: a syllable is centred on its moment, so
  half of it lies left of the x it is placed at, and a number set against that x
  lands on top of the word instead of before it.
- **Extender rules for melisma**, behind `lyric-extender` on the theme. A word
  held over several notes is ruled out to the last of them, as a vocal score
  does. Off by default: the published tab sheets write the word once and leave
  the held notes bare, which is what this package is set to look like. `_` in a
  verse is now a *held* note rather than nothing at all, which is what makes the
  two tellable apart — an unsung note is still `none`.

### Changed

- **The far end of a tie prints no fret number.** It used to be set in
  parentheses, which is exactly how a ghost note is set — so the two, meaning
  opposite things, were one picture and only the arc under it told them apart.
  Hal Leonard can afford that, having a notation staff carrying the tie; a tab
  staff alone cannot, and a bracketed digit there reads as a second, quieter
  attack. Songsterr, which is the reference for how ties are drawn here for the
  same reason, prints nothing and lets the arc carry it. The note is otherwise
  unchanged: it keeps its slot and its value in the rhythm lane, and it still
  claims the width of the number it would have printed, that room being what the
  arc is drawn in — measured at nothing, a held thirty-second is spaced by its
  duration alone and the tie has nowhere to arch. `model.is-parenthesised` is now
  a ghost note's business alone, and `model.prints-fret` is the new predicate.

  ASCII tab is read as before — `-5-(5)-` is still a tie and `-5-7-(5)-` still a
  ghost note — so a sheet read in and set back out comes back with the brackets
  gone and the arc in their place, saying the same thing.
- **A run of links takes one slur** over the whole of it rather than an arc per
  pair. A hammer-on into a pull-off into a slide is one gesture; drawn pair by
  pair the arcs met at the notes between and came out as a row of bumps, reading
  as several articulations where the music has one — and on a fast run each was
  so short as to be nearly flat. A shift slide ends a run, its target being
  picked again, and a pick scrape joins none, drawing its wave and no arc. The
  lines are untouched: a slide still draws its own diagonal between its own two
  numbers.

### Fixed

- **Two marks of one kind no longer print on top of each other.** A group of
  marks — every palm mute in a system, every bracketed span — moves as a unit so
  that a kind keeps one height down the page, and it was only ever measured
  against *other* groups; two of its own members in each other's way were never
  noticed. A `let ring` label is three staff spaces wide, so two spans a
  sixteenth apart came out as `let ringlet ring`. The kind is now split into the
  fewest runs whose members clear each other, and each run placed as a unit, so
  it still occupies one level wherever it can and gains a second only across the
  stretch where it must.
- **A word the system break cuts in two keeps its hyphen**, set at the end of the
  line. Only the second half showed the break before, and the first half read as
  a word that ended there.
- **A free instruction stays inside the system, and two of them stack.** A
  remark is a phrase rather than a word — imported scores carry whole sentences —
  so it is now boxed at a width it fits in, shifted left where that is what it
  takes and wrapped only where the system itself is too narrow, with the height
  it really occupies reserved. Set loose it wrapped inside a level one line tall
  and printed over the marks below it; and two remarks in one system, being one
  kind, shared a level by construction and printed over each other.
- **The system that closes a passage is spaced at the density of the one above
  it**, rather than being left at natural width whenever it fell below 65 % fill.
  Two bars that do not fit on one line are a bar to the system — usually the same
  bar twice — and the second came out half the width of the first, which says the
  music is shorter than it is. The fill rule now applies only to a passage that
  fills *one* system and stops, where there is no line above to disagree with; a
  two-note tail under a page of music still stops where the music stops.
- **A short bar closing a passage is no longer reported.** It pairs with the
  pick-up that opened it — between them they are one bar — and a passage set on
  its own simply stops where it stops. A closing bar holding *more* than the
  signature allows is still wrong, and a part of a single bar is exempt from
  nothing.

## 0.2.0 — 2026-08-10

### Added

- **Lyrics.** `lyrics:` on `tab` and `ascii-tab` takes one string per verse,
  spent syllable by syllable; `L:` annotation rows do the same by column in
  imported tabs. One lane per verse, at the foot of the system. A trailing `-`
  hyphenates and the hyphen is centred in the gap; `_` spends a note without
  printing. Rests, grace notes and the far ends of ties are passed over.
  Syllables left over are reported on the page.
- **Held bends.** A bend carrying a tie is held: a dashed rule runs from the
  arrowhead for as long as the note sounds, across barlines. No new syntax —
  `7/3b~` was already legal.
- Theme values `lyric-size` and `lyric-gap`. `lyric-font` was reserved in 0.1.0
  and is now used.
- ASCII import reads a **pick scrape**, written the way it writes the harmonic
  marks but against an `x`, the scrape having no pitch of its own: `xPS1` drags
  to the first fret, `xPS` to whatever plays the string next. A dead note never
  entered the technique chain, so the mark is read where the `x` itself is read.
- ASCII import reads two dialect spellings it did not before: `<12>` for a
  natural harmonic, as Power Tab and Guitar Pro export it, and `W H Q E S` in an
  `R:` row, which is how those exports write their own duration line — so a tab
  exported that way arrives with real rhythm instead of being spaced from its
  columns.
- **Repeats in ASCII tab.** The colons around a barline are read as music: `|:`
  opens a repeat, `:|` closes one, `:|:` does both where a repeated section runs
  straight into the next, and `:|x3` says how many times to play it. They were
  skipped as filler before, so a repeated section rendered as though it were
  played once. A count is read only after `:|`, since `x` is also a dead string.
  Adjacent strokes still collapse into the one mark they are drawn as, but no
  longer drop what the collapsed stroke said, so `||:` keeps its repeat.
- **Rests in ASCII tab**, written in the `R:` row: a note value standing over a
  column where nothing is struck is a rest that long. ASCII tab spells silence
  as filler and has nowhere else to put one, so a bar that stopped halfway
  through could not be made to add up to its meter. The notes claim their tokens
  — each takes the nearest within three columns, the reach the other annotation
  rows resolve by — and what no note claimed is the rest. Asking the other way
  round, whether a token has a note near it, cannot read a densely spaced row at
  all: where events stand two columns apart, a value over the gap is within reach
  of both sides. A bar with nothing said about it is still one bar-long rest, and
  one carrying only syllables still keeps that rest ahead of them.
- **A slide out of a note**, `5/3sU` and `5/3sN` — up and down. It reaches
  nothing, so it names a direction where a link derives one from the fret it
  lands on. In ASCII it is a mark the row runs out on: `-15\-------` falls,
  `-15/-------` climbs, and a bare `s` falls, which is what sliding out of a note
  ordinarily does. Such a mark was dropped without a word before, so a figure
  that trails away came out as a plain note. A hammer-on or pull-off to nowhere
  still means nothing and is still dropped.

  The direction is written in capitals because `n` and `u` are the strokes: a
  lower-case pair could also be spelled by a slide and a stroke on one note, and
  the writer would emit exactly that, so `su` would have read back as something
  it was not. No suffix begins with `N` or `U`.
- **A link that runs to the next note instead of naming a fret.** `5/3h7` still
  prints the target beside its own number, the two sharing one note value, as the
  legend sets them; `5/3s` — no target — runs to the next event that plays the
  string, which keeps its own value and its own place. Only that form can join
  two independently timed notes, and only it can cross a barline, since a second
  number inside one event has nowhere to go once the bar ends. It is drawn the
  way a tie is, by searching forward through the system.
- **Links and ties are drawn in both halves across a system break** — a tail
  leaving the last note and an equal tail arriving at the first note of the line
  below, which is the conventional way of showing a mark the break cuts in two.
  A tie previously trailed off and left nothing on the system it landed on.
  `mark-link-targets` is what makes the landing half possible: a system is drawn
  on its own and cannot see the note the mark came from.
- **Ties in ASCII tab.** A fret in parentheses that repeats the note before it on
  the same string is a tie; any other fret in them is the ghost note the brackets
  otherwise mean. ASCII tab has no other way of writing a held note — `~` is
  vibrato there whatever the native syntax uses it for — and setting the note
  that is not struck again in brackets is both what transcribers do and what this
  package prints for the far end of a tie, so what it writes now reads back. A
  note struck in between ends what the first was sounding, and the reading is
  made row by row, so a tie crosses a barline but not the end of a block.
- **Ultimate Guitar's harmonic marks are read inline** in ASCII tab, against the
  fret: `NH` `PH` `AH` `HH` `TH`. They previously reached the page only through a
  `T:` row, which put the right word over the right column and left the model
  none the wiser. Capitals collide with nothing, since every technique letter in
  a row is lower case, and none of them names a target fret, so `7PH5` is the
  harmonic and then the fifth.
- **Artificial and tap harmonics** in the model, the DSL (`5/3AH`, `5/3TH`) and
  on the page ("A.H.", "T.H."), which is what reading `AH` and `TH` needs to have
  somewhere to go.
- The user guide has a chapter on the ASCII format: what a block is, every mark
  read inside a row, repeats and endings, all eight annotation rows including
  rests, and the arguments and inference that supply what is left.
- `show-time` on `ascii-tab`, which only `tab` had. A piece pasted in several
  blocks is several calls, so without it every block restated the meter — a thing
  the reader is told once, and which an ASCII-imported song had no way to
  suppress.
- Model additions for building parts in code: `event(lyrics:)`, `syllable`,
  `mark-tie-targets`, `is-parenthesised`, and `lyrics:` on `render`.
  `tuplet-runs` takes an optional `time:`; without it the old behaviour stands.

### Changed

- **Beams group by the metre, not by the beat alone.** Eight eighths in 4/4 are
  now two beamed groups of four rather than four pairs, which is how a published
  sheet sets them; 2/4 and 3/4 beam a whole bar of eighths, 7/8 counts 2+2+3, and
  values shorter than an eighth still group by the beat. The rules are Gould's
  (*Behind Bars* p. 153), held as a table in the new `layout/metre.typ`. Every
  document containing a bar of eighths renders differently.
- **The rhythm lane sits below the staff**, and its values are bars rather than
  noteheads: a beam along the bottom with stems rising from it, beam levels
  stacking upwards. A whole note is not written at all, so a bar of them
  collapses the lane; a half note is a quarter's stem cut in two from the same
  foot; a lone eighth or shorter gets a beam stub instead of a flag; an
  augmentation mark is a square in the slot above the beam stack; a tuplet
  brackets below the beam.
- **Grace notes** are miniatures of a real value — a short stem with a stub, two
  in a row beamed — hung from the top of the lane, not flagged.
- **Beams are thinner.** Thickness and gap are both 0.286 staff spaces, down
  from 0.5 and 0.32. At the old weight a run of thirty-seconds fused into a
  block.
- **A bend release is two arrows** with the hold between them, rather than one
  stroke curving over. The only departure from the Hal Leonard legend, and the
  only way the hold has somewhere to sit.
- **The far end of a tie prints in parentheses**, so a note held across several
  bars no longer reads as several strikes.
- Tremolo slashes are half a beam thick and hang from the top of the stem.
- Arpeggio and rake arrowheads are solid triangles as wide as they are tall.
- A rest's gap in the string lines is taken from its ink at each line's own
  height rather than from its bounding box, so the clearance matches a fret
  number's on every side.

### Fixed

- **A pick scrape was drawn beside the music rather than on it.** The wave sat
  above the staff next to the words, so the mark said a scrape happened
  somewhere hereabouts and named no string. Both references put it on the
  string: Hal Leonard's legend writes `P.S.` above and an `X` on the string, and
  Songsterr runs the wave from that `X` to the note the scrape lands on. It is
  now drawn in the staff. A scrape is a *link*, in the sense the model already
  had for slides: named a fret it drags to that fret, whose number shares the
  note's value rather than being struck, and the wave spans the note's whole
  length — so the same mark over a half note is twice the drag it is over a
  quarter. Named none it runs to the next note on the string, and carries across
  a system break as any other link does. The wave tilts across
  the string line rather than lying along it — flat, the two merge into one thick
  dashed rule and the string disappears inside it.
- **Tapping was never drawn.** `5/3T` and the ASCII importer's inline `t` both
  reached the model, and four places in the documentation promised the mark, but
  the technique lane had no branch for it — a tapped note printed exactly like an
  untapped one. It is now a `T` over the note, by the same mechanism as the bass
  right hand's letters. The visual fixture already contained a `7/3T`, which is
  how this stayed hidden: a reference pinned around the empty space where a mark
  should be says nothing about the mark.
- Two tuplets written one after the other drew a single bracket across both.
  Runs now part at a beat boundary, as beam groups do.
- A densely noted string row — two-digit frets with single dashes between them —
  fell under the ASCII importer's filler test and was dropped as prose, taking
  its whole system with it. Fret numbers now count towards the alphabet tab is
  written with.
- `pb` and `pbr` were *misread* rather than merely lost: the `p` was held as a
  pull-off and hung off the next note, so the page gained a slur the source
  never had, and the pre-bend came out as an ordinary bend. Both now read as
  Ultimate Guitar's own symbol table spells them.
- A bar with nothing written in it is now a bar of silence — one measure holding
  a rest as long as the bar — instead of being dropped. A block whose bars were
  all empty used to vanish whole, so an outro where the guitar has stopped and
  only the voice carries on left no trace on the sheet. Runs of adjacent
  barlines (`||`, `:|`) still count as the one mark they are drawn as.
- A linking mark whose target was parted from it by filler drew that fret
  **twice** — once as a phantom number beside the note the mark came from, once
  as the real note at its own column. `-5-h-7-` and, worse, a slide into the next
  bar both came out that way. The target now keeps its place and the link runs
  to it.
- A note value written over a link's target had nowhere to go: the target was
  read as a second number inside the event before it, which has no rhythm of its
  own, and the value, claimed by no note, came out as a **rest the source never
  had**. `-3-3/7-7-8-` under an `R:` row lost the 7's rhythm and gained a rest.
  A value over the target's column now says it is a note in its own right, which
  is the only way ASCII tab can say so — every character has a column there, so
  `3/7` spends one on its target exactly as `3-/-7` does.
- A linking mark left standing between a dead string and the next note — the
  stray `p` of `0-x---pbr12` where no fret precedes it — was hung off the `x`,
  and the renderer, asked whether the 12th fret is above one called "x", stopped
  the whole document. Nothing sounds on a dead string, so the mark is dropped and
  reported instead.
- `docs/build.sh` wrote `GUIDE.md` with unpadded page numbers while Typst pads
  them to the width of the last page, so a guide of ten pages left every image
  in it broken. The names now come from the files that were rendered.
- Syllables with no note near them are placed on a column of their own instead
  of being dropped and reported. A singer carries on where the guitar stops, so
  a bar the transcription leaves empty is where lyrics need it most — the outro
  of a fetched tab used to lose its words entirely. The event made there is a
  rest with no duration, so it draws nothing and claims no rhythm the source
  never gave; a bar holding only words still shows its whole rest.

## 0.1.0 — 2026-08-04

Initial release. Guitar tablature for Typst, with no music font required —
every symbol is a vector curve.

- A compact syntax for notes, chords, rests, note values, dotted values and
  tuplets, with the technique set of the Hal Leonard *Guitar Notation Legend*:
  hammer-ons, slides, bends, harmonics, vibrato, articulations, arpeggios,
  bass slap and pop.
- Groups as one mechanism for palm mute and let ring spans, tuplets, first and
  second endings, and gradual dynamics.
- Barlines, repeats with counts, time signatures, chord names and free playing
  instructions.
- ASCII tab import, enriched incrementally by column-aligned annotation rows,
  named arguments or `enrich:`. `ascii-to-dsl` prints the equivalent native
  source.
- Optical spacing, beat-aware beam grouping, line breaking and justification.
- Page furniture: `song`, `section`, title block, running head, copyright.
- Eleven tunings and `tuning()` for any other; the number of staff lines
  follows the tuning. Pitch is in the model.
- Themes derived from a single `staff-space`.
- `validate` reports bars that disagree with the time signature, on the page.
