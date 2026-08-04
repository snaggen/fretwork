// Everything drawn in the lane above the staff, and the sideways packing.
//
// Pins: marks sitting as close to the staff as they fit, a whole kind moving
// together so every palm mute stays at one height, the dashed span rule with its
// closing tick, and the order when two kinds do collide.

#import "/src/lib.typ": *
#import "_common.typ": fixture, vt

#show: fixture.with("techniques and spans")

#tab(theme: vt, ```
q 7/3> 7/3^ 7/3! 7/3- | 7/3n 7/3u 7/3g 12/3*
```)

#tab(theme: vt, ```
q 7/3v 7/3V 7/3tr9 7/3tr | 7/3TP 7/3PS 5/3PH 7/3HH
```)

#tab(theme: vt, ```
{PM: e 0/6 0/6 0/6 0/6} {LR: q 3/6 5/6}
| q "w/ bar" 7/3 7/3T (2/5 2/4 0/6)A (2/5 2/4 0/6)R
```)

// A palm mute in one bar and an instruction in the next are not in each other's
// way, so they share a level rather than stacking.
#tab(theme: vt, ```
{PM: q 0/6 0/6 0/6 0/6} | q "Harm." 12/3* 12/4* 12/5* 12/6*
```)

// A repeat count shares the volta lane, written out rather than set as "x3",
// and held clear of the boundary where a following ending's bracket starts.
#tab(theme: vt, ```
|: q 5/3 5/3 7/3 7/3 :|x4
```)

#tab(theme: vt, ```
|: q 5/3 5/3 7/3 7/3 {V1: q 8/3 8/3 5/3 5/3 :|x3} {V2: q 3/3 3/3 5/3 5/3 |.}
```)

// A ghost note prints in parentheses, alone and stacked in a chord, and the
// gap in the string line follows the wider glyph.
#tab(theme: vt, ```
q 5/3 5/3g 12/3 12/3g | q (2/5 2/4 0/6)g 5/3 5/3g 7/3
```)

// A fermata takes the outermost level whatever else is there, since it governs
// everything written under it — including over a rest and over a bare mute,
// which have no note to carry a suffix and hold theirs on the event.
#tab(theme: vt, ```
q 7/3F 7/3>F rF xF | h 7/3W q 7/3 7/3v
```)

// An arpeggio and a rake carry an arrowhead at the end they travel to. A
// downstroke runs thick string to thin, so its head is the upper one — the
// unmarked default, which is why a bare `A` draws it.
#tab(theme: vt, ```
q (2/5 2/4 0/6)A (2/5 2/4 0/6)Au 3/6 5/6
| (0/1 2/2 2/3 1/4)Rn (0/1 2/2 2/3 1/4)Ru 3/6 5/6
```)

// The bass right hand.
#tab(theme: vt, tuning: tunings.bass, ```
q 0/4SL 3/3PO 0/4SL x/3DS | e 0/4SL 3/3PO 0/4SL 3/3PO q 5/2PO 0/4SL
```)
