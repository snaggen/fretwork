// The lead illustration for README.md: a complete sheet, set by the package's
// own `song` show rule rather than mocked up, so what the picture shows is
// exactly what the four lines of code beside it produce.
//
// Rendered by `docs/build.sh`; not part of the published bundle.

#import "/src/lib.typ": *

#let dark = sys.inputs.at("mode", default: "light") == "dark"
#let ink = if dark { rgb("#e9e6e1") } else { rgb("#101010") }
#let paper = if dark { rgb("#1c1c1e") } else { white }
#let faint = if dark { rgb("#8b8b8f") } else { luma(105) }
#let thm = theme(color: ink, faint: faint)

#set page(fill: paper)

#show: song.with(
  title: "Twelve Past Nine",
  words: "A. Guitarist",
  music: "A. Guitarist",
  copyright: "© 2026 A. Guitarist",
  tempo: 132,
  tempo-words: "Driving Rock",
  theme: thm,
  margin: (x: 16mm, top: 14mm, bottom: 16mm),
)

#section("Main Riff", theme: thm)

#tab(
  theme: thm,
  count-in: true,
  ```
  |: @E5 e 0/6 0/6 {PM: 0/6 0/6 0/6 0/6 0/6 0/6}
   |  @G5 q 3/6 3/6 @A5 5/6 5/6
   |  @E5 e 0/6 0/6 {PM: 0/6 0/6 0/6 0/6 0/6 0/6}
   |  @A5 q 5/6> 5/6> h 7/6v :|
  ```,
)

#section("Solo", theme: thm)

#tab(theme: thm, show-time: false, ```
e 12/1 14/1 15/1b 15/1br q 14/1v 12/1~ | w 12/1
```)

#section("Chorus", theme: thm)

#tab(theme: thm, show-time: false, ```
|: @D5 q (5/5 7/4 7/3) 5/5 @C5 (3/5 5/4 5/3) 3/5
 |  @G5 h (3/6 5/5 5/4) q 3/6 5/5
 |  @D5 q (5/5 7/4 7/3) 5/5 @A5 (0/5 2/4 2/3) 0/5
 |  @E5 w (0/6 2/5 2/4) :|
```)

#section("Outro", theme: thm)

#tab(theme: thm, show-time: false, ```
{LR: q (0/6 2/5 2/4 1/3) h. (0/6 2/5 2/4 1/3)} | w (0/6 2/5 2/4 1/3) |.
```)
