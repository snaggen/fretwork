// Slurs and slide lines — where most of the visual defects have been.
//
// Pins: the tail rising from the number's top centre rather than its corner, the
// clearance to the line above, the thickness swelling at the apex, a slur under
// the staff matching one over it, and a chord slur attaching near the middle of
// its own number instead of at the top of the stack.
//
// And the one distinction the whole set exists to protect: a slur arches *over*
// its numbers, a tie hangs *under* them. Drawn the same way the two marks are
// the same picture, and the reader cannot tell a hammer-on from a held note.

#import "/src/lib.typ": *
#import "_common.typ": fixture, vt

#show: fixture.with("slurs and slide lines")

#tab(theme: vt, ```
q 5/3h7 7/3p5 5/3s7 7/3S5
```)

#tab(theme: vt, ```
q 5/1h7 7/1p5 5/1h7 7/1p5 | 5/6h7 7/6p5 5/6h7 7/6p5
```)

#tab(theme: vt, ```
e 5/3h7 7/3p5 5/3h7 7/3p5 5/3h7 7/3p5 5/3h7 7/3p5
```)

#tab(theme: vt, ```
q (5/1 5/2 5/3)h7 (7/4 7/5 7/6)p5 h r | q 12/3~ 12/3 h r
```)

// A tie across a whole bar, which is the only thing here long enough to reach
// the cap on how far a slur climbs.
#tab(theme: vt, ```
w 12/3~ | w 12/3
```)

// A tie whose target is several events away: the reserved height must follow
// the drawn span, not the event's own width. This exact case used to run the
// arc straight through the rest glyphs in the rhythm lane.
#tab(theme: vt, ```
q 5/1~ r r 5/1
```)

// Tied chords, and a tie on the lowest string. A stacked number has no room
// beneath it — the next string is right there — so the tie leaves the flanks,
// shallower still. On the bottom string it leaves the staff altogether, and the
// lane has to have reserved the room.
#tab(theme: vt, ```
h (5/1 5/2 5/3)~ (5/1 5/2 5/3) | q 3/6~ 3/6 (0/5 2/6)~ (0/5 2/6)
```)
