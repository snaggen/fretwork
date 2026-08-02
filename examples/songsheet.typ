// A complete song sheet, end to end.
//
// The music is original and written for this file, so the example ships with
// the package. It exercises the whole page: title block, section headings, the
// count row, chord names, palm muting, repeats and a technique passage.
//
// Compile with `typst compile --root . examples/songsheet.typ`.

#import "/src/lib.typ": *

#show: song.with(
  title: "Twelve Past Nine",
  artist: "for one electric guitar",
  words: "Mattias Eriksson",
  music: "Mattias Eriksson",
  source: "fretwork",
  copyright: "Typeset with fretwork · EUPL-1.2",
  tempo: 132,
  tempo-words: "Driving Rock",
)

#section("Intro")

#tab(
  count-in: true,
  ```
  @E5 q (2/5 2/4 0/6)  q x  e 0/3 3/6 0/6 0/6
    | q (2/5 2/4 0/6)  q x  e 0/3 3/6 0/6 0/6
  ```,
)

#section("Main Riff")

#tab(```
|: @E5 e 0/6 0/6 {PM: 0/6 0/6 0/6 0/6 0/6 0/6}
 |  @G5 q 3/6 3/6 @A5 5/6 5/6
 |  @E5 e 0/6 0/6 {PM: 0/6 0/6 0/6 0/6 0/6 0/6}
 |  @A5 q 5/6> 5/6> h 7/6v :|
```)

#section("Bridge")

#tab(```
|: @Am q (0/1 1/2 2/3 2/4) e 0/1 1/2 q (0/1 1/2 2/3 2/4)
 |  @C   q (0/1 1/2 0/3 2/4) e 0/1 1/2 q (0/1 1/2 0/3 2/4)
 |  @G   q (3/1 0/2 0/3 0/4) e 3/1 0/2 q (3/1 0/2 0/3 0/4)
 |  {V1: @Am h (0/1 1/2 2/3 2/4)~ (0/1 1/2 2/3 2/4) :|}
    {V2: @Am w (0/1 1/2 2/3 2/4) ||}
```)

#section("Solo")

#tab(```
q 5/3h7 7/3p5 e 5/2h7 7/2p5 q 7/3b
| e 7/3br 5/3s7 q 12/3* h 7/3V
| {3: e 5/6 7/6 8/6} {3: e 7/6 8/6 10/6} q 12/6PS 7/3tr9
| "let ring" w (0/1 2/2 2/3 1/4)A |.
```)
