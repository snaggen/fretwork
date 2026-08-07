// Lyrics: syllables under the rhythm, one lane per verse.
//
// Pins the three things the layout has to get right, none of which a fret
// number needs. A syllable is centred on the event it is sung on, exactly as
// the number above it is. A hyphen is its own character, centred in the gap
// between two syllables rather than tucked against the first. And syllables
// constrain each other *pairwise* — one is routinely wider than the room its
// note bought — so the spacing engine has to widen the gap by half of each,
// across barlines as well as within a bar.
//
// Also pinned: what is deliberately *not* drawn. A word held over several notes
// is written once and `_` spends the rest of them, with no extension line after
// it, because the sheets this follows draw none.
//
// And the lane order. The verses come last, below the dynamics and the count
// row alike: a dynamic marks the music and has to stay near the staff, and set
// above the lyrics it is pushed one row further out for every verse.

#import "/src/lib.typ": *
#import "_common.typ": fixture, vt

#show: fixture.with("lyrics")

#tab(theme: vt, lyrics: "What else should I be _ All a- po- lo- gies", ```
q 0/6 2/6 3/6 5/6 | q 3/6 5/6 h 7/6 | e 0/6 2/6 3/6 5/6 q 7/6 8/6
```)

// Two verses, one lane each, and a hyphen in each of them landing in its own
// gap rather than at the same place on the page. The dynamics and the count row
// stay between the staff and the verses, however many verses there are.
#tab(
  theme: vt,
  count-in: true,
  lyrics: (
    "Twist- ing and smash- ing the win- dow",
    "Blind- ed by ev- ery sing- le light",
  ),
  ```
  !mf q 0/6 2/6 3/6 5/6 | !ff q 3/6 5/6 7/6 8/6
  ```,
)

// A syllable far wider than its note's allocation, and — the pin — two of them
// meeting across a barline. The constraint crosses it, which is why it is
// applied to the whole part in order rather than measure by measure.
#tab(theme: vt, lyrics: "here now everything extraordinarily immeasurably wide syllables crowding", ```
q 0/6 2/6 3/6 5/6 | q 7/6 8/6 10/6 12/6
```)

// A rest is not sung and is passed over, and the far end of a tie is not sung
// again — it keeps the syllable of the note it is held from, and prints its
// fret number in parentheses to say it was never struck.
#tab(theme: vt, lyrics: "held a- cross the", ```
h 12/3~ h 12/3 | q r 5/3 3/3 0/3
```)

// The ASCII importer's own row: column-aligned, so the transcriber says where
// each syllable goes by writing it under the note.
#ascii-tab(theme: vt, ```
R:   q   q   q   q
L:   ne- ver mind that
e|------------------|
B|------------------|
G|------------------|
D|------------------|
A|------------------|
E|---0---2---3---5--|
```)
