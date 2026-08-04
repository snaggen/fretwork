// Stems, flags, beams, dots, rests and tuplets.
//
// Pins: beams grouped by the beat rather than across it, the clearance between
// the stem feet and the top staff line, dotted values, and the count row.

#import "/src/lib.typ": *
#import "_common.typ": fixture, vt

#show: fixture.with("rhythm")

#tab(theme: vt, ```
w 0/6 | h 0/6 0/6 | q 0/6 0/6 0/6 0/6 | e 0/6 0/6 0/6 0/6 0/6 0/6 0/6 0/6
```)

#tab(theme: vt, ```
s 0/6 0/6 0/6 0/6 e 0/6 0/6 q. 0/6 e 0/6 | t 0/6 0/6 0/6 0/6 0/6 0/6 0/6 0/6 e 0/6 0/6 h 0/6
```)

#tab(theme: vt, ```
q r 0/6 e r 0/6 0/6 r | h r q 0/6 r
```)

// Every rest value in one row. The pin here is that the whole rest and the half
// rest are *not* the same picture: the block hangs below its line in one and
// sits on it in the other, and for a long time both drew identically.
#tab(theme: vt, ```
w r | h r r | q r r r r | e r r r r r r r r
```)

#tab(theme: vt, ```
{3: e 0/6 2/6 3/6} {3: e 5/6 3/6 2/6} q 0/6 {5: s 0/6 2/6 3/6 5/6 7/6}
```)

// Grace notes: small numbers on a short flagged stem, never beamed to the note
// they ornament, and taking no room in the bar — which is why neither of these
// bars is reported short. `g` is squeezed in before the beat and carries the
// slash; `G` starts on it and does not.
#tab(theme: vt, ```
q g 5/3 7/3 5/3 3/3 5/3 | G 3/3h5 q 7/3 e 5/3 3/3 q 5/3 g 7/3 3/3
```)

#tab(theme: vt, count-in: true, ```
q 0/6 2/6 3/6 5/6
```)
