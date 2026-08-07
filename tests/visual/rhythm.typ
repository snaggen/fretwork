// Stems, beams, stubs, augmentation marks, rests and tuplets.
//
// The lane is *under* the staff and its values are bars: a beam along the
// bottom with stems rising from it. Pins: beams grouped by the beat rather than
// across it, the clearance between the stem tops and the bottom staff line, a
// half note drawn as a quarter's stem cut in two from the same foot, a whole
// note drawn as nothing at all, and the count row.

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

// Every rest value in one row.
//
// Three pins. Rests are drawn *inside* the staff and carry no stem — the rhythm
// lane carries note values only, and a rest is not one; the published sheet in
// research/TNT_0001.png sets them exactly so. The whole rest and the half rest
// are not the same picture: the block hangs below its line in one and sits on
// it in the other, which is the only thing that tells them apart, and for a
// long time both drew identically. And the gap a rest knocks in a string line
// is taken from its *ink* at that line's own height, so a line grazing the
// zigzag of a quarter rest is broken no wider than the ink there is.
#tab(theme: vt, ```
w r | h r r | q r r r r | e r r r r r r r r
```)

// Tuplets bracket *below* the beam, `└─ 3 ─┘` with the numeral in a break at
// the centre. Two triplets in a row carry identical records, so nothing in the
// events parts them: the beat grid does, and it has to, or one bracket is drawn
// across both groups.
#tab(theme: vt, ```
{3: e 0/6 2/6 3/6} {3: e 5/6 3/6 2/6} q 0/6 {5: s 0/6 2/6 3/6 5/6 7/6}
```)

// A lone eighth or shorter gets beam stubs rather than a flag, stacked upwards
// from the beam line, and one at the end of a measure turns back into it rather
// than pointing at the barline.
#tab(theme: vt, ```
q 0/6 0/6 0/6 e 2/6 2/6 | q 0/6 s 2/6 e. 3/6 q 0/6 0/6
```)

// Grace notes: small numbers over a miniature of a real value — a short stem
// with a beam stub, or a beam where two fall in a row — never beamed to the
// note they ornament, and taking no room in the bar, which is why neither of
// these bars is reported short. `g` is squeezed in before the beat and carries
// the slash; `G` starts on it and does not.
//
// The pin is that the ornament hangs from the *top* of the lane while every
// real stem stands on the foot. That is what tells it from a half note, the
// other short stem in this notation: one sits high and carries a stub, the
// other sits low and carries nothing.
#tab(theme: vt, ```
q g 5/3 7/3 5/3 3/3 5/3 | G 3/3h5 q 7/3 e 5/3 3/3 q 5/3 g 7/3 3/3
| q g 3/3 g 5/3 7/3 5/3 3/3 5/3 | h 5/3 q g 7/3 5/3 3/3
```)

#tab(theme: vt, count-in: true, ```
q 0/6 2/6 3/6 5/6
```)
