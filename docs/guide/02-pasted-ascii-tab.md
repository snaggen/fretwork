## Pasted ASCII tab

`ascii-tab` takes the plain-text tab found on the web and renders it as it
stands. Nothing below is required — a bare paste always renders, and every fact
added improves the result. As in the tables above, each example is set from the
same string it is rendered from, so none of them can drift.

### What is read

A *block* is one row per string, written highest string first — the labels
before the barline say which, and a block whose labels are the tuning reversed
is read the other way round. *Column position carries simultaneity*: notes
standing in one column are struck together. Blocks stacked one after another
are one continuous passage rather than separate pieces, and lines that are
neither string rows nor annotation rows — titles, comments, chord charts — are
skipped with a warning.

```fretwork-ascii
e|-----------------|-----------------|
B|-----5h7---------|--------------8--|
G|--2--------------|-----7b9---------|
D|--2----------7\5-|-----------------|
A|--0--------------|--10-------------|
E|--------3--------|-----------------|
```

Adjacent digits are one fret as far as that fret exists, which is the only
reading that makes sense of both `-11-` and `-1-1-`: `-11-` is the eleventh,
`-1-1-` the first struck twice, `-77-` two sevenths — nothing is fretted at
the 77th — and `-010-` the open string then the tenth. Where the convention
can be wrong, brackets settle it: inside `( )` or `< >` the digits are one
fret however many there are.

### Marks read inside a row

| Mark | Meaning | Mark | Meaning |
|---|---|---|---|
| `h` | hammer-on | `p` | pull-off |
| `s` `\` | slide — out of the note where none follows | `~` `v` | vibrato |
| `b` | bend, to the pitch of the fret named | `r` | release, folded into the bend before it |
| `hb` `fb` | half and full bend, size spelled out | `pb` `pbr` | pre-bend, and pre-bend with release |
| `x` `X` | a dead string | `t` | tap — it marks the note it precedes |
| `*` | natural harmonic | `<` `>` | natural harmonic, as Power Tab writes it |
| `( )` | a ghost note — or a tie, see below | `\|` | a barline |
| `NH` `PH` `AH` | natural, pinch and artificial harmonic | `HH` `TH` | harp and tap harmonic |

A mark may stand anywhere between the notes it joins, and where it stands
decides what is drawn: `5h7`, the digits pressed against the mark, is one
event with the second number beside the first, while `5-h-7` is two events
joined by an arc — which is the only form that can reach into the next bar. An
`R:` row does the same to the compact form: a value over the target's column
says that note has a rhythm of its own. A slide with no note left to reach —
`15\` at the end of a row — is the note slid *off*, and the arrow says which
way the pitch leaves; a hammer-on or pull-off to nowhere means nothing and is
dropped. Marks chain: `5h7b9` bends the hammered seventh up to the pitch of the
ninth. A bend must rise, so `5b3` is reported and the note kept. The harmonic
marks are read in capitals, which collide with nothing since every other letter
is lower case, and none of them names a target fret: `7PH5` is the harmonic and
then the fifth. A source that writes them on a line of its own above the staff
uses a `T:` row instead. A pick scrape is written the same way but against an
`x`, having no pitch of its own — and it *does* read the digits against it,
`xPS1`, since those name the fret the pick stops at rather than a second attack.

```fretwork-ascii
e|--------------------------------------|
B|--------------------------------------|
G|--5h7p5--5s7--7fb--7b9r7--7PH--9-s-12\|
D|--xPS------5--------------------------|
A|----------------------------------x---|
E|----------(12)---<12>-----------------|
```

**A fret in parentheses that repeats the note before it on the same string is a
tie** — the string is still sounding and is not struck again. Any other fret in
them is the ghost note the brackets otherwise mean. There is no other way to
write a held note in ASCII tab, where `~` is vibrato whatever the native syntax
uses it for.

```fretwork-ascii rhythm: even(1/4)
e|--------------------------|--------------------------|
B|--------------------------|--------------------------|
G|--5-----(5)-----7-----(7)-|--------------------------|
D|--------------------------|--------------------------|
A|--------------------------|--0-----3-----(0)-----5---|
E|--------------------------|--------------------------|
```

Both are written the same, in brackets, so the reading is what separates them —
and it is set back out differently: a ghost note keeps its brackets, a tie's
far end prints no number at all and is carried by the arc alone. A note struck
in between ends what the first was sounding, which is why the `(0)` above is a
ghost note and not a tie. A tie is read across a barline but not across the end
of a block, the reading being made row by row like every other mark that joins
two notes.

### Barlines, repeats and endings

`|` is a barline, and `||` is one barline drawn twice rather than two with a
bar of silence between them. The repeat colons are read as music: `|:` opens a
repeat, `:|` closes one, `:|:` closes one and opens the next where a repeated
section runs straight into another, and `x3` after the closing stroke says how
many times to play it. A bar with nothing written in it is a bar of silence,
and becomes the rest a published sheet would write.

```fretwork-ascii
R:  q   q   q   q    q   q   q   q
e|:----------------|-----------------:|x3
B|:----------------|-----------------:|x3
G|:----------------|-----------------:|x3
D|:--2---2---2---2-|--5---5---5---5--:|x3
A|:--2---2---2---2-|--5---5---5---5--:|x3
E|:--0---0---0---0-|--3---3---3---3--:|x3
```

A count is read only after `:|`, since `x` is also a dead string: `|x3` in the
middle of a row is a muted string and then the third fret.

First and second endings are written as rows of their own, `1:` and `2:`, a run
of dashes marking the measures each covers. They attach to measures rather than
to events, which is what a volta is, and the first ending is closed off where
the repeat it leads back to is written.

```fretwork-ascii
1:                   --------------
2:                                  --------------
R:  q   q   q   q    q   q   q   q   q   q   q   q
e|:----------------|---------------:|---------------|
B|:----------------|---------------:|---------------|
G|:----------------|---------------:|---------------|
D|:--2---2---2---2-|--5---5---5---5:|--7---7---7--7-|
A|:--2---2---2---2-|--5---5---5---5:|--7---7---7--7-|
E|:--0---0---0---0-|--3---3---3---3:|--5---5---5--5-|
```

### Annotation rows

Everything ASCII tab cannot carry is supplied by extra rows in the same block,
each prefixed with a key and a colon. Being column-aligned is the whole point:
a fact attaches to exactly the column it sits over, so nothing has to be
counted and a tab may be annotated in part.

| Row | Carries | Row | Carries |
|---|---|---|---|
| `R:` | note values, and rests where nothing is struck | `C:` | chord names |
| `L:` | sung syllables, one row per verse | `S:` | a section heading |
| `T:` | a free playing instruction | `D:` | dynamics |
| `PM:` `LR:` | palm mute and let ring — dashes mark the extent | `1:` `2:` | first and second endings |

```fretwork-ascii
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
```

`R:` reuses the DSL's duration tokens deliberately — `w h q e s t`, dotted the
same way, and `3:` to open a tuplet — so there is no second notation to learn,
and a Power Tab or Guitar Pro export's own `W H Q E S` line pastes in
unchanged. Note values are sticky, as in the DSL. `C:` and `T:` rows split on
runs of two or more spaces, so an instruction may contain single spaces. Each
token attaches to the single nearest event within three columns, and one with
nothing near it is reported rather than moved — except a syllable, which is
given a column of its own so the voice can carry on where the guitar has
stopped.

**A block may carry more than one `R:` row**, read together column by column,
which is what makes `3:` writable in a tab whose events stand close: a tuplet
opener needs whitespace on both sides and rarely fits between two values.
Written on a row of its own it lands on the column it belongs to.

```fretwork-ascii
R:          3:
R:  q   q   q   q   q
e|---------------------|
B|---------------------|
G|--3---3---5---3---2--|
D|---------------------|
A|---------------------|
E|---------------------|
```

Three quarters in the time of two, which is what lets a bar of five quarters
add up to four beats. A bar that disagrees with the meter is reported on the
page, and a missing tuplet is one of the things that announces itself that way.

**Rests are written in the `R:` row as well**, because ASCII tab spells silence
as filler and has nowhere else to put them. A value standing over a column
where nothing is struck is a rest that long, which is what lets a bar that
stops halfway through still add up to its meter.

```fretwork-ascii
R:  q   e   e   h            q   e   e   h
e|------------------------|------------------------|
B|------------------------|------------------------|
G|------------------------|------------------------|
D|------5---7-------------|------7---8-------------|
A|--0---------------------|--0---------------------|
E|------------------------|------------------------|
```

The notes claim their tokens — each takes the nearest one within three
columns, the same reach every other row resolves by — and whatever no note
claimed is a rest where it stands. So a token that merely misses its note
still sets that note's value, while one written over a gap is a silence even
where the events are packed two columns apart. A bar with nothing said about
it is one bar-long rest, as before; a bar whose rests are named is divided as
the row says. Align the row and the bar adds up; a bar that does not is
reported on the page.

### Arguments and inference

Facts about the whole piece have no column, and are named arguments instead:
`tuning`, `time`, `tempo`, `capo`, `anacrusis`. Where annotating every column
would be busywork, `rhythm:` infers the note values — `even(1/8)` makes every
event an eighth, `fill` spreads each bar evenly across the time signature, and
a string such as `"q q e e | h h"` is spent event by event. `lyrics:` does the
same for a source with no `L:` rows. Annotation rows win over arguments, which
win over inference: a value already set is never overwritten.

```fretwork-ascii rhythm: even(1/8), time: (3, 4)
e|--------------|--------------|
B|--------------|--------------|
G|--------------|--------------|
D|--2-2-2-2-2-2-|--------------|
A|--0-0-0-0-0-0-|--2-2-2-2-2-2-|
E|--------------|--0-0-0-0-0-0-|
```

`tempo` and `capo` are carried into the model but drawn by the title block
rather than by the staff, so they appear on a page set with `song`.

Beyond the three there is `enrich: part => …`, which is handed the parsed part
and returns a modified one. The model is public API, so anything the rows and
the arguments do not reach can be set there.

`ascii-to-dsl(source)` prints the equivalent native source. Once a tab is
fully annotated it is as complete as one written by hand, and this is how it
graduates to the syntax in the tables above.
