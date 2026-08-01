// Bend arrows, checked against the bend cells of the Hal Leonard
// Guitar Notation Legend.
//
// The arrow is anchored to the fret number it belongs to, so the same bend must
// sit at the same distance above its number whichever string that is — and the
// staff must reserve room for however far it reaches above the top line.
//
// Compile with `typst compile --root . examples/bends.typ`.

#import "/src/lib.typ": *

#show: song.with(
  title: "Bends",
  subtitle: "One bend per string, then the same bends under pressure",
  source: "tablature",
)

#section("The same whole-step bend on every string")

A bend on string 1 reaches furthest above the staff; the identical bend on
string 6 barely leaves it. Both sit the same distance above their own number.

#tab(```
q 7/1b 7/2b 7/3b 7/4b | q 7/5b 7/6b h r
```)

#section("Every kind of bend")

Bend, half-step bend, bend and release, pre-bend, pre-bend and release. A
pre-bend is already bent when the string is struck, so its arrow is straight:
the curve is what shows the pitch rising after the attack.

#tab(```
q 7/3b 7/3b(1/2) 7/3br 7/3B | q 7/3Br h 7/3b(1/4) |.
```)

#section("Under pressure")

A bend on every sixteenth is not music anyone writes, but it is the worst case
for the geometry. The arrow stops leaning and the interval label is held inside
the event's own allocation, so nothing escapes into the next event — at this
density the labels sit shoulder to shoulder, which is as good as it gets.

#tab(```
s 7/3b 8/3b 9/3b 10/3b 7/3b(1/2) 8/3br 9/3b 10/3b
 | e 7/3b 9/3br 12/3b 7/3b h 9/3Br |.
```)

#section("Alongside other techniques")

Articulations and spans live in a lane above the staff; bends do not, so adding
an accent no longer pushes every arrow in the system upwards.

#tab(```
{PM: q 7/3b> 7/3br} q 5/3h7 12/3* | q 7/6b 7/6v h 7/1b |.
```)
