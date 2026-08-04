// Dynamics and gradual changes, in the lane below the staff.
//
// Pins: the lane hanging under the staff rather than joining the crowd above
// it, the bold italic every engraver sets a dynamic in, the closing tick on a
// `cresc.` rule turning back *up* towards the music where a palm mute's turns
// down, marks packing sideways onto one row where they do not collide, and the
// lane vanishing entirely when nothing needs it.

#import "/src/lib.typ": *
#import "_common.typ": fixture, vt

#show: fixture.with("dynamics")

#tab(theme: vt, ```
!mf q 0/6 2/6 3/6 5/6 | {cresc: q 3/6 5/6 7/6 8/6}
| !ff q 10/6 8/6 {dim: 7/6 5/6} | !p q 3/6 2/6 0/6 r |.
```)

// A dynamic and a palm mute are in opposite lanes, so neither pushes the other
// about however much they overlap horizontally.
#tab(theme: vt, ```
{PM: !fff q 0/6 0/6 0/6 0/6} | !pp q 3/6 5/6 7/6 8/6
```)

// No dynamic anywhere: the lane collapses and costs nothing.
#tab(theme: vt, ```
q 0/6 2/6 3/6 5/6
```)
