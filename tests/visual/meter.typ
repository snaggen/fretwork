// Time signatures.
//
// Pins: the pair of numerals stacked tight against the staff's middle, the air
// between them and both the TAB mark and the first fret number, the string
// lines running behind rather than being knocked out, a change printed
// mid-piece, and the numerals shrinking to fit a shorter staff.

#import "/src/lib.typ": *
#import "_common.typ": fixture, vt

#show: fixture.with("time signatures")

#tab(theme: vt, ```
q 0/6 2/6 3/6 5/6 | [7/8] e 0/6 2/6 3/6 5/6 7/6 8/6 10/6
```)

// Two digits over one: the numerals are tabular, so the pair stays on one axis
// however wide it is, and the measure claims the extra room rather than letting
// the signature run into the first note.
#tab(theme: vt, ```
[12/8] e 0/6 0/6 0/6 0/6 0/6 0/6 0/6 0/6 0/6 0/6 0/6 0/6 | [2/4] q 3/6 5/6 |.
```)

// A four-string staff has no room for a signature sized for six, so it shrinks
// to fit rather than overhanging the lines.
#tab(theme: vt, tuning: tunings.bass, ```
[3/4] q 0/4 2/4 3/4
```)

// Suppressed, for the second and later blocks of one piece.
#tab(theme: vt, show-time: false, ```
q 0/6 2/6 3/6 5/6
```)
