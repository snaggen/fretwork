// The on-page report, which is the only channel a Typst package has for a
// problem that must not stop the compile.
//
// Pins: that a short bar is reported at all, that `ascii-tab` merges its parse
// warnings with the model's into one block rather than two, and that
// `warn: false` leaves nothing behind.

#import "/src/lib.typ": *
#import "_common.typ": fixture, vt

#show: fixture.with("diagnostics")

#tab(theme: vt, ```
q 0/6 2/6 3/6 | q 0/6 2/6 3/6 5/6
```)

#tab(theme: vt, warn: false, ```
q 0/6 2/6 3/6 | q 0/6 2/6 3/6 5/6
```)

// A row whose string label matches no string in the tuning, and a bar that is
// short once the rhythm is supplied: two sources, one block.
#ascii-tab(theme: vt, ```
R:  q   q   q
Z|--0---2---3-----|
e|----------------|
B|----------------|
G|----------------|
D|----------------|
A|----------------|
E|----------------|
```)
