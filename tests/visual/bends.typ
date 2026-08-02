// Bend arrows on every string, and every bend variant.
//
// Pins: the arrow starting just above its own fret number rather than floating
// in a lane, the head shape, the label clamped so it cannot run over the next
// event, and the return of a release landing back on the string.

#import "/src/lib.typ": *
#import "_common.typ": fixture, vt

#show: fixture.with("bends")

#tab(theme: vt, ```
q 7/1b 7/2b 7/3b 7/4b | 7/5b 7/6b h r
```)

#tab(theme: vt, ```
q 7/3b 7/3b(1/2) 7/3br 7/3B | 7/3Br 9/3b 12/3b(1/2) 14/3br
```)

// Sixteenths leave each event about a staff space, so the labels have to be
// clamped rather than allowed to overlap their neighbours.
#tab(theme: vt, ```
s 7/3b 9/3b 7/3b 9/3b 7/3b 9/3b 7/3b 9/3b
7/3b 9/3b 7/3b 9/3b 7/3b 9/3b 7/3b 9/3b
```)
