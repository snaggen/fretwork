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
  tab(theme: thm, ```
  q 5/3h7 7/3p5 5/3s7 5/3S7 |.
  ```)

  caption[Bend, half-step bend, bend and release, pre-bend. Every arrow in a system ends level:]
  tab(theme: thm, ```
  q 7/3b 7/3b(1/2) 7/3br 7/3B |.
  ```)

  caption[Vibrato, wide vibrato, natural and pinch harmonic, tapping, ghost note:]
  tab(theme: thm, ```
  q 7/3v 7/3V 12/3* 5/3PH | q 7/3T 7/3g h 7/3v |.
  ```)

  caption[Palm mute and let ring bracket what they wrap; a free instruction goes in quotes:]
  tab(theme: thm, ```
  {PM: e 0/6 0/6 0/6 0/6} {LR: e (0/1 2/2 2/3) 0/6 0/6 0/6}
  | "w/ bar" h 7/3V q 5/3s12 5/3 |.
  ```)

  caption[Repeats, endings and repeat counts — `repeat-style: "ornate"` flares the serifs:]
  tab(theme: theme(color: ink, faint: faint, repeat-style: "ornate"), ```
  |: q 0/6 0/6 0/6 0/6
   | {V1: q 3/6 3/6 3/6 3/6 :|x3}
     {V2: q 5/6 5/6 h 7/6 ||}
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

#if figure-name == "techniques" { techniques } else { ascii }
