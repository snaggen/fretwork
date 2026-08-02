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

#tab(theme: vt, ```
{3: e 0/6 2/6 3/6} {3: e 5/6 3/6 2/6} q 0/6 {5: s 0/6 2/6 3/6 5/6 7/6}
```)

#tab(theme: vt, count-in: true, ```
q 0/6 2/6 3/6 5/6
```)
