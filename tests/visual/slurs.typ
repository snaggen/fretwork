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

// A link written with no target fret runs to the next event that plays the
// string, joining two notes that each keep their own value — the only form that
// can cross a barline, and the one a slide into the next bar has to use. The
// second pair is a hammer-on between separate events, which draws the arc but no
// line; the third is the labelled form, unchanged, for comparison.
#tab(theme: vt, ```
q 10/3s 5/1 5/1 5/1 | q 3/3 5/3h 7/3 5/3h7
```)

// A run of links is one gesture and takes one slur over the whole of it, not an
// arc per pair — pair by pair the arcs meet at the notes between and come out as
// a row of bumps. The second bar ends the run with a shift slide, whose target
// is picked again: the arc stops before it, and the slide keeps its line.
#tab(theme: vt, ```
s 7/1h 8/1p 7/1s 5/1 q r r r | s 7/1h 8/1p 7/1S 5/1 q r r r
```)

// The same run tied into, which is what a transcription of a real passage looks
// like: the tie hangs under the pair it joins, the slur arches over the run
// after it, and the held note prints no number of its own.
#tab(theme: vt, ```
e 7/1 s 7/1~ 7/1h 8/1p 7/1s e 5/1 q r r
```)

// A slide *out* of a note, which reaches nothing and so names its own direction
// — the one thing a link cannot do, having a fret to derive one from.
#tab(theme: vt, ```
q 13/1 15/1sU 13/1 15/1sN | q 3/6sN 3/6sU (5/1 5/2 5/3)sU r
```)

// A link whose far end is on the next system. Both halves are drawn: a tail
// leaving the last note, and the same tail arriving at the first note of the
// line below, which is the conventional way of showing a mark cut in two by the
// break. The system it lands on cannot see the note it came from, so the mark on
// that note is the only trace there is.
// Narrowed so the break falls where the marks do; `tab` fills what it is given.
#block(width: 46mm, tab(theme: vt, ```
h 10/3s 5/1 | h 3/3 5/1 | h 12/3~ 5/1 | h 12/3 5/1
```))
