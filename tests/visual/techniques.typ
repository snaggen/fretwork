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
