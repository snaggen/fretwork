// Sources for the technique and ASCII-import illustrations in README.md.
//
// Rendered by `docs/build.sh` into `docs/*.png`, twice each — once for a light
// page and once for a dark one, since Typst Universe honours the reader's
// colour scheme. Not part of the published bundle.
//
//   typst compile --root . docs/showcase.typ --input figure=techniques out.png

#import "/src/lib.typ": *

#let figure-name = sys.inputs.at("figure", default: "techniques")
#let dark = sys.inputs.at("mode", default: "light") == "dark"

// One ink colour and one paper colour drive everything, because every
// measurement and every rule in the package derives from the theme.
#let ink = if dark { rgb("#e9e6e1") } else { rgb("#101010") }
#let paper = if dark { rgb("#1c1c1e") } else { white }
#let faint = if dark { rgb("#8b8b8f") } else { luma(105) }
#let thm = theme(color: ink, faint: faint)

#set page(width: 185mm, height: auto, margin: 9mm, fill: paper)
#set text(font: thm.font, fill: ink, size: 10pt)
#set par(justify: false)

#let caption(body) = block(above: 1.2em, below: 0.45em, text(size: 9.5pt, fill: faint, body))

#let techniques = {
  caption[Hammer-on, pull-off, legato and shift slide — one slur for both, direction tells which:]
  tab(theme: thm, show-time: false, ```
  q 5/3h7 7/3p5 5/3s7 5/3S7 |.
  ```)

  caption[A tie hangs under its line — the mirror of the slur above, so neither can be read for the other:]
  tab(theme: thm, show-time: false, ```
  h 5/3~ q 5/3 7/3 | h (5/1 5/2 5/3)~ (5/1 5/2 5/3) |.
  ```)

  caption[Bend, half-step bend, bend and release, pre-bend. Every arrow in a system ends level:]
  tab(theme: thm, show-time: false, ```
  q 7/3b 7/3b(1/2) 7/3br 7/3B |.
  ```)

  caption[Grace notes lean on the beat without taking any of it, and a fermata holds:]
  tab(theme: thm, show-time: false, ```
  q g 3/3 5/3 7/3 G 5/3 7/3 g 3/3h5 5/3 | h 7/3F rF |.
  ```)

  caption[Dynamics sit below the staff, where nothing else is competing for the room:]
  tab(theme: thm, show-time: false, ```
  !mf q 0/6 2/6 3/6 5/6 | {cresc: q 3/6 5/6 7/6 8/6} | !ff q 10/6 8/6 7/6 5/6 |.
  ```)

  caption[Vibrato, wide vibrato, natural and pinch harmonic, tapping, ghost note:]
  tab(theme: thm, show-time: false, ```
  q 7/3v 7/3V 12/3* 5/3PH | q 7/3T 7/3g h 7/3v |.
  ```)

  caption[Palm mute and let ring bracket what they wrap; a free instruction goes in quotes:]
  tab(theme: thm, show-time: false, ```
  {PM: e 0/6 0/6 0/6 0/6} {LR: e (0/1 2/2 2/3) 0/6 0/6 0/6}
  | "w/ bar" h 7/3V q 5/3s12 5/3 |.
  ```)

  caption[A time signature is set on the staff, and can change at any bar:]
  tab(theme: thm, ```
  [3/4] q 0/6 2/6 3/6 | [7/8] e 0/6 2/6 3/6 5/6 7/6 8/6 10/6 |.
  ```)

  caption[Repeats, endings and repeat counts — `repeat-style: "ornate"` flares the serifs:]
  tab(theme: theme(color: ink, faint: faint, repeat-style: "ornate"), show-time: false, ```
  |: q 0/6 0/6 0/6 0/6
   | {V1: q 3/6 3/6 3/6 3/6 :|x3}
     {V2: q 5/6 5/6 h 7/6 ||}
  ```)
}

#let rhythm = {
  caption[Eighths beam in half-bars, so the middle of the bar is never in doubt:]
  tab(theme: thm, ```
  e 0/6 2/6 3/6 5/6 3/6 2/6 0/6 2/6 |.
  ```)

  caption[Shorter values have no such licence and group by the beat:]
  tab(theme: thm, show-time: false, ```
  s 0/6 2/6 3/6 5/6 3/6 5/6 7/6 8/6 7/6 5/6 3/6 2/6 0/6 2/6 3/6 5/6 |.
  ```)

  caption[Thirty-seconds, sixteenths and eighths in one bar — the beams stack as
    the values shorten, and the shortest in a run is what sets its grouping:]
  tab(theme: thm, show-time: false, ```
  t 0/6 2/6 3/6 5/6 3/6 2/6 0/6 2/6 s 3/6 5/6 7/6 8/6 e 7/6 5/6 q 3/6 |.
  ```)

  caption[Within a group the primary beam spans the whole of it and each further
    beam only the notes fast enough to need one, so an eighth among sixteenths
    leaves a stub pointing back at the note it belongs with:]
  tab(theme: thm, show-time: false, ```
  s 5/3 7/3 e 8/3 e 7/3 s 5/3 3/3 s 5/3 e 7/3 s 8/3 e 5/3 s 7/3 8/3 |.
  ```)

  caption[The metre decides, not the note value alone — a whole bar of eighths in
    3/4, and 2+2+3 in 7/8:]
  tab(theme: thm, ```
  [3/4] e 0/6 2/6 3/6 5/6 3/6 2/6 | [7/8] e 0/6 2/6 3/6 5/6 7/6 8/6 10/6 |.
  ```)

  caption[…and a compound metre counts in threes, whatever its numerals say:]
  tab(theme: thm, ```
  [6/8] e 0/6 2/6 3/6 5/6 3/6 2/6 | [12/8] e 0/6 2/6 3/6 5/6 3/6 2/6 0/6 2/6 3/6 5/6 3/6 2/6 |.
  ```)
}

#let ascii = {
  caption[A tab pasted from the web renders as it stands — techniques read inline,
    spacing taken from the source's own columns:]
  ascii-tab(theme: thm, ```
  e|-----------------|-----------------|
  B|-----5h7---------|--------------8--|
  G|--2--------------|-----7b9---------|
  D|--2----------7\5-|-----------------|
  A|--0--------------|--10-------------|
  E|--------3--------|-----------------|
  ```)

  caption[Add column-aligned annotation rows and the same paste gains rhythm,
    chords, a section heading and spans — each attaching to the column it sits over:]
  ascii-tab(theme: thm, ```
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
}

#if figure-name == "techniques" {
  techniques
} else if figure-name == "rhythm" {
  rhythm
} else { ascii }
