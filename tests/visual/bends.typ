// Bend arrows on every string, and every bend variant.
//
// Pins: the arrow starting just above its own fret number rather than floating
// in a lane, the head shape, the label clamped so it cannot run over the next
// event, and the return of a release landing back on the string.
//
// And the hold. A bend up, a hold and a release is three things, so a release
// is two arrows with a dashed rule between them rather than one stroke curving
// over — a stroke already bending downwards has nowhere to hang the rule. A
// bend that is *tied* is held for as long as the tie lasts, and its rule says
// so, ending with the last tied event rather than at its number.

#import "/src/lib.typ": *
#import "_common.typ": fixture, vt

#show: fixture.with("bends")

#tab(theme: vt, ```
q 7/1b 7/2b 7/3b 7/4b | 7/5b 7/6b h r
```)

#tab(theme: vt, ```
q 7/3b 7/3b(1/2) 7/3br 7/3B | 7/3Br 9/3b 12/3b(1/2) 14/3br
```)

// Held bends. The first is held through one tied quarter, the second across a
// barline and through two, and the third is not tied at all — so its rule ends
// with the release instead of carrying on.
#tab(theme: vt, ```
q 7/3b~ 7/3 5/3 3/3 | h 7/3b~ 7/3~ | w 7/3
```)

// Sixteenths leave each event about a staff space, so the labels have to be
// clamped rather than allowed to overlap their neighbours.
#tab(theme: vt, ```
s 7/3b 9/3b 7/3b 9/3b 7/3b 9/3b 7/3b 9/3b
7/3b 9/3b 7/3b 9/3b 7/3b 9/3b 7/3b 9/3b
```)
