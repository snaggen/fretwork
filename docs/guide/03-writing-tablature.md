## Writing tablature

A tab is a sequence of *events* separated by whitespace. An event is a note
`fret/string`, a chord `(… …)`, or a rest `r`. Everything else — note values,
techniques, spans — attaches to those.

### Notes and rests

<!-- fretwork-table -->
| What it is | Syntax |
|---|---|
| A note: fret over string | `5/3` |
| String 1 is the highest-sounding | `0/1 0/2 0/3 0/4 0/5 0/6` |
| Two-digit frets need no marking | `11/3 1/3 1/3` |
| A chord: one column | `(2/5 2/4 0/6)` |
| A rest | `q 5/3 r 5/3 r` |
| A dead string | `x/5 5/3` |
| A whole dead strum | `x 5/3` |
| A comment, to end of line | `5/3 // the rest of this line is ignored` |

### Note values

Note values are sticky: one holds until another is written.

<!-- fretwork-table -->
| What it is | Syntax |
|---|---|
| Whole, half, quarter | `w 5/3 \| h 5/3 5/3 \| q 5/3 5/3 5/3 5/3` |
| Eighth, sixteenth, thirty-second | `e 5/3 5/3 s 5/3 5/3 5/3 5/3 t 5/3 5/3 5/3 5/3` |
| Values are sticky until changed | `e 5/3 5/3 q 7/3 7/3` |
| Dotted, doubly dotted | `q. 5/3 e 5/3 h.. 7/3` |
| Every rest value, whole to thirty-second | `w r \| h r \| q r \| e r \| s r \| t r` |
| Rests take the value in force | `h r q r e r r` |
| A tuplet | `{3: e 5/3 7/3 8/3} q 5/3` |
| …with an explicit ratio | `{5/4: s 5/3 7/3 8/3 7/3 5/3}` |
| Groups nest | `{3: {PM: e 5/3 7/3} 8/3} q 5/3` |

### Beam grouping

<!-- fretwork-table -->
| What it is | Syntax |
|---|---|
| Eighths beam in half-bars | `e 0/6 2/6 3/6 5/6 3/6 2/6 0/6 2/6` | <!-- show-time: true -->
| Sixteenths group by the beat | `s 0/6 2/6 3/6 5/6 3/6 2/6 0/6 2/6` |
| A lone eighth among sixteenths keeps a stub | `s 5/3 e 7/3 s 8/3 e 5/3 s 7/3 8/3` |
| A syncopation carries its beam across the beat | `s 5/3 7/3 8/3 e 7/3 s 5/3 3/3 5/3` |
| 3/4 beams a whole bar of eighths | `[3/4] e 0/6 2/6 3/6 5/6 3/6 2/6` | <!-- show-time: true -->
| 7/8 counts 2+2+3 | `[7/8] e 0/6 2/6 3/6 5/6 7/6 8/6 10/6` | <!-- show-time: true -->
| 6/8 counts in threes | `[6/8] e 0/6 2/6 3/6 5/6 3/6 2/6` | <!-- show-time: true -->

### Left hand

<!-- fretwork-table -->
| What it is | Syntax |
|---|---|
| Hammer-on | `5/3h7` |
| Pull-off | `7/3p5` |
| Legato slide — target not struck | `5/3s7` |
| Shift slide — target struck | `5/3S7` |
| Chained | `5/3h7p5` |
| …to the next note instead, across a bar | `h 10/3s 5/1 \| h 3/3 5/1` |
| Slide out of the note, up or down | `h 15/1sU 15/1sN` |
| Tie — the far end is not struck | `5/3~ 5/3` |
| …on a whole chord | `(5/1 5/2 5/3)~ (5/1 5/2 5/3)` |
| Vibrato, wide vibrato | `5/3v 5/3V` |
| Trill, to a named fret | `5/3tr7 5/3tr` |
| Tapping | `5/3T 12/3T` |
| Grace note, before the beat | `q g 3/3 5/3 5/3 5/3 5/3` |
| Grace note, on the beat | `q G 3/3 5/3 5/3 5/3 5/3` |
| …and a grace hammer-on | `q g 3/3h5 5/3 5/3 5/3` |

### Bends

<!-- fretwork-table -->
| What it is | Syntax |
|---|---|
| A whole-step bend | `7/3b` |
| A half-step bend | `7/3b(1/2)` |
| Any size | `7/3b(1/4) 7/3b(2)` |
| Bend and release | `7/3br` |
| Pre-bend — already bent when struck | `7/3B` |
| Pre-bend and release | `7/3Br` |
| Vibrato with the tremolo bar | `7/3W` |

### Right hand

<!-- fretwork-table -->
| What it is | Syntax |
|---|---|
| Downstroke, upstroke | `5/3n 5/3u` |
| Arpeggio — thick string to thin | `(2/5 2/4 0/6)A` |
| …written out, and the other way | `(2/5 2/4 0/6)An (2/5 2/4 0/6)Au` |
| Rake | `(2/5 2/4 0/6)R` |
| …and the other way | `(2/5 2/4 0/6)Ru` |
| Tremolo picking | `h 5/3TP 5/3TP` |
| Pick scrape, to the fret it stops at | `q x/3PS1 5/3 5/3 5/3` |
| …the same over a longer note | `h. x/3PS12 q 5/3` |
| …or to the next note on the string | `q x/3PS 5/3 5/3 5/3` |
| Natural harmonic | `12/3* 12/4*` |
| Pinch, artificial harmonic | `5/3PH 5/3AH` |
| Harp, tap harmonic | `5/3HH 5/3TH` |

### Bass

<!-- fretwork-table -->
| What it is | Syntax |
|---|---|
| Slap, pop | `0/4SL 3/3PO` | <!-- tuning: tunings.bass -->
| Dead slap | `x/4DS 0/4SL` | <!-- tuning: tunings.bass -->

### Articulations

A note may carry a length mark, an attack mark and a stroke direction at once;
all three are drawn, stacked outward from the staff.

<!-- fretwork-table -->
| What it is | Syntax |
|---|---|
| Accent, heavy accent | `5/3> 5/3^` |
| Staccato, tenuto | `5/3! 5/3-` |
| All three at once | `5/3!>n 5/3-^u` |
| Ghost note — felt, not heard | `5/3 5/3g` |
| Fermata — hold | `5/3F 5/3` |
| …over a rest | `5/3 rF` |

### Spans and instructions

<!-- fretwork-table -->
| What it is | Syntax |
|---|---|
| Palm mute | `{PM: e 0/6 0/6 0/6 0/6} q 5/3` |
| Let ring | `{LR: q (0/1 2/2 2/3) 0/6} q 5/3` |
| A free instruction | `"w/ bar" 7/3V 5/3` |
| A chord name | `@E5 (2/5 2/4 0/6) @"C#m7" (4/5 4/4 4/3)` |

### Dynamics

A dynamic holds until the next one. The set is closed: `ppp pp p mp mf f ff fff
sf sfz fp`.

<!-- fretwork-table -->
| What it is | Syntax |
|---|---|
| A dynamic, held until the next | `!mf 5/3 5/3 !ff 7/3 7/3` |
| Growing louder | `{cresc: q 3/6 5/6 7/6 8/6}` |
| …and quieter | `{dim: q 8/6 7/6 5/6 3/6}` |

### Bars and structure

<!-- fretwork-table -->
| What it is | Syntax |
|---|---|
| A barline | `5/3 5/3 \| 7/3 7/3` |
| Double, final | `5/3 5/3 \|\| 7/3 7/3 \|.` |
| A repeat | `\|: q 5/3 5/3 7/3 7/3 :\|` |
| …a given number of times | `\|: q 5/3 5/3 7/3 7/3 :\|x4` |
| First and second endings | `\|: q 5/3 5/3 \| {V1: q 7/3 7/3 :\|} {V2: q 8/3 8/3 \|.}` |
| A time signature | `[3/4] q 5/3 5/3 5/3` |
| …changing mid-piece | `[3/4] q 5/3 5/3 5/3 \| [4/4] q 5/3 5/3 5/3 5/3` |
| A count-in row | `q 5/3 5/3 5/3 5/3` | <!-- count-in: true -->
| A pick-up bar before the first full one | `q 5/3 \| q 7/3 7/3 7/3 7/3` | <!-- anacrusis: true -->
