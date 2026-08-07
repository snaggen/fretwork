// The ASCII importer, raw and enriched.
//
// Pins: a bare paste spaced from the source's own columns, and the same source
// once the annotation rows supply what ASCII tab cannot carry — so a change in
// the importer that silently drops a technique shows up as a moved slur.

#import "/src/lib.typ": *
#import "_common.typ": fixture, vt

#show: fixture.with("ASCII import")

#ascii-tab(theme: vt, ```
e|-----------------|-----------------|
B|-----5h7---------|--------------8--|
G|--2--------------|-----7b9---------|
D|--2----------7\5-|-----------------|
A|--0--------------|--10-------------|
E|--------3--------|-----------------|
```)

#ascii-tab(theme: vt, ```
S:  Main Riff
R:  q   q   q   q    q   q   h
C:  E5               G5
PM: ---------
T:                           Harm.
e|----------------|----------------|
B|----------------|----------------|
G|----------------|----------------|
D|--2---2---2---2-|--5---5---------|
A|--2---2---2---2-|--5---5---------|
E|--0---0---0---0-|--3---3---12----|
```)

// Bend sizes spelled out in letters rather than implied by a target fret, which
// has to reach the arrow's label: `hb` half, `fb` full. The last pair is the
// case that used to lose both marks — the size is spelled, so the 5 is the next
// note and not the bend's target.
#ascii-tab(theme: vt, ```
e|--------------------------------|
B|--------------------------------|
G|---3hb----3fb----3b5----7fb5----|
D|--------------------------------|
A|--------------------------------|
E|--------------------------------|
```)

// A fret in parentheses that repeats the note before it on the same string is a
// held note, not a ghost note — the arc is what separates them on the page, and
// the last pair here has an intervening strike, so it stays a ghost.
#ascii-tab(theme: vt, rhythm: even(1 / 4), ```
e|--------------------------|--------------------------|
B|--------------------------|--------------------------|
G|--5-----(5)-----7-----(7)-|--------------------------|
D|--------------------------|--------------------------|
A|--------------------------|--0-----3-----(0)-----5---|
E|--------------------------|--------------------------|
```)

// Where the target has a column of its own the link runs to it as an event,
// which is the only way a slide into the next bar can be said. `5h7`, the digits
// pressed against the mark, is still the compact pair sharing one note value —
// both forms are here, in that order.
#ascii-tab(theme: vt, rhythm: even(1 / 4), ```
e|--------------------------|--------------------------|
B|--------------------------|--------------------------|
G|--5---7---9---10\---------|--3---5-h-7---9h11--------|
D|--------------------------|--------------------------|
A|--------------------------|--------------------------|
E|--------------------------|--------------------------|
```)

// A mark with no note left to reach is the note slid *off*, in the direction the
// arrow points — `\` falls, `/` climbs. It used to be dropped without a word, so
// a figure that trails away came out as a plain note.
// One block each: a mark is only slid *off* when the row has no note left for it
// to reach, and two bars on one row would leave the first mark reaching into the
// second — which is a link, and drawn as one.
#ascii-tab(theme: vt, rhythm: even(1 / 4), ```
e|--13--13--15--15\-|
B|------------------|
G|------------------|
D|------------------|
A|------------------|
E|------------------|
```)
#ascii-tab(theme: vt, rhythm: even(1 / 4), ```
e|--13--13--15--15/-|
B|------------------|
G|------------------|
D|------------------|
A|------------------|
E|------------------|
```)

// Ultimate Guitar's harmonic marks, read against the fret rather than reaching
// the page through a `T:` row that leaves the model none the wiser.
#ascii-tab(theme: vt, ```
e|-------------------------------------|
B|-------------------------------------|
G|--12NH----5PH----5AH----9HH----7TH---|
D|-------------------------------------|
A|-------------------------------------|
E|-------------------------------------|
```)

// A value written where nothing is struck is a rest that long. ASCII tab spells
// silence as filler, so the `R:` row is the only place a rest can be said — and
// saying it is what lets a bar that stops halfway through add up to its meter.
#ascii-tab(theme: vt, ```
R:  q   e   e   h            q   e   e   h
e|------------------------|------------------------|
B|------------------------|------------------------|
G|------------------------|------------------------|
D|------5---7-------------|------7---8-------------|
A|--0---------------------|--0---------------------|
E|------------------------|------------------------|
```)

// Repeats written into the rows themselves. The first ending closes off against
// the repeat it leads back to, which is what the colons are for: a bracket left
// open there would say the music runs on.
#ascii-tab(theme: vt, ```
1:                   --------------
2:                                  --------------
R:  q   q   q   q    q   q   q   q   q   q   q   q
e|:----------------|---------------:|---------------|
B|:----------------|---------------:|---------------|
G|:----------------|---------------:|---------------|
D|:--2---2---2---2-|--5---5---5---5:|--7---7---7--7-|
A|:--2---2---2---2-|--5---5---5---5:|--7---7---7--7-|
E|:--0---0---0---0-|--3---3---3---3:|--5---5---5--5-|
```)

// A repeat count, and a repeated section running straight into the next: `:|:`
// is one barline carrying both marks.
#ascii-tab(theme: vt, ```
R:   q   q   q   q      q   q   q   q
e|:----------------:|:----------------:|x3
B|:----------------:|:----------------:|x3
G|:----------------:|:----------------:|x3
D|:--2---2---2---2-:|:--5---5---5---5-:|x3
A|:--2---2---2---2-:|:--5---5---5---5-:|x3
E|:--0---0---0---0-:|:--3---3---3---3-:|x3
```)

// Ending rows and a section heading in the middle of the piece. `1:`/`2:`
// become volta brackets; the mid-piece `S:` heading must land between its
// measures rather than vanish.
#ascii-tab(theme: vt, ```
S:  First part
1:            ---------
2:                       --------
e|--0---2----|--3---5---|--7---8--|
B|-----------|----------|---------|
G|-----------|----------|---------|
D|-----------|----------|---------|
A|-----------|----------|---------|
E|-----------|----------|---------|
S:  Second part
e|--12--10---|
B|-----------|
G|-----------|
D|-----------|
A|-----------|
E|-----------|
```)
