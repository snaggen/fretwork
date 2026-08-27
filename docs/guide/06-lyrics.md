## Lyrics

Syllables are **not** written inline. They would drown the notes, and there is
already a pattern for data that runs parallel to the music and lines up with it
event by event. Lyrics follow it: a string of space-separated syllables, spent in
order over the events that are actually sung.

<!-- fretwork-table -->
| What it is | Syntax |
|---|---|
| One syllable per sung note | `q 5/3 7/3 8/3 7/3` | <!-- lyrics: "one two three four" -->
| A word broken in two | `q 5/3 7/3 8/3 7/3` | <!-- lyrics: "Twist- ing the night" -->
| A word held — `_` spends a note | `q 5/3 7/3 8/3 7/3` | <!-- lyrics: "held _ and gone" -->
| Rests and ties are passed over | `q 5/3 r 8/3~ 8/3` | <!-- lyrics: "not sung" -->

A trailing `-` hyphenates into the next syllable. `_` spends a note without
printing anything, which is how a word held over several notes is written — the
far end of a tie is passed over for the same reason it prints no number: it is
not a new attack, so it keeps the syllable of the note it is held from.

### Several verses

`lyrics` takes a list, one string per verse, and each verse gets a lane of its
own under the staff.

<!-- fretwork-table -->
| What it is | Syntax |
|---|---|
| Two verses, two lanes | `q 5/3 7/3 8/3 7/3` | <!-- lyrics: ("one two three four", "five six seven eight") -->

Where more than one verse is sung, each lane carries its number just before its
first syllable, on the system where it begins — which is what tells one stanza's
row from another's under a repeated passage, whose music is written once while
its words are written out a row per time round.

`verse-labels` replaces the numbering with your own, one per verse. An empty
string leaves a lane unlabelled.

<!-- fretwork-table -->
| What it is | Syntax |
|---|---|
| Labels of your own | `q 5/3 7/3 8/3 7/3` | <!-- lyrics: ("one two three four", "five six seven eight"), verse-labels: ("V.", "Ch.") -->

### Words written for another part

A verse spent over the notes is one written for *this* music. A singer's line
under a guitar's staff is not: the two share bars but not notes, so counting
through the guitar's notes would start the first word bars before anyone sings.

`lyric-at(measure, position, text)` gives each syllable a moment instead —
the measure it falls in, counted from zero, and where in that measure, as a
fraction of a whole note or as a `(numerator, denominator)` pair.

```typst
#tab(
  lyrics: ((lyric-at(0, (1, 2), "half-"), lyric-at(1, 0, "way")),),
  ```q 5/3 5/3 5/3 5/3 | q 7/3 7/3 7/3 7/3```,
)
```

A bar is settled one way or the other, never both. Where every syllable finds an
event of its own it is hung on that event; where any cannot — a bar the part
rests through is a *single* whole rest, and a phrase sung across it is not — all
of them are placed by their moments instead. Mixing the two put syllables in one
bar on two different timelines, and they collided.

A moment is read against the **notes**, not against the bar's width: events are
spaced optically, so a fraction of the width lands nowhere near the note sounding
then. And a bar is widened for what is sung across it, since otherwise it is
spaced only for what it plays.

Both forms may be mixed, one verse each, and every verse keeps the lane its
position in the argument gives it.

### A syllable with nothing to sit on

A syllable with no note near it gets a column of its own rather than being
dropped: a singer carries on where the guitar stops, and a bar the transcription
leaves empty is exactly where that happens.

See also [`lyric-extender`](#a-rule-under-a-held-word), which draws a rule after
a held word, and `L:` rows in [Pasted ASCII tab](#annotation-rows).
