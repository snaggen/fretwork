// Shared page setup for the visual fixtures.
//
// Deliberately plain: a fixed width, an automatic height and a tight margin, so
// a reference image is only as tall as the thing it pins down and a change in
// one fixture cannot shift the others. Nothing here may depend on the date, the
// filename or anything else outside the document, or the comparison would fail
// for reasons that have nothing to do with rendering.
//
// The font is pinned to DejaVu Sans rather than the theme default. Montserrat is
// the better face and stays the default for real sheets, but it is a variable
// font that not every machine has, and a reference image has to mean the same
// thing on the next machine that renders it.

#import "/src/lib.typ": *

#let fixture(title, body) = {
  set page(width: 150mm, height: auto, margin: 6mm, fill: white)
  set text(font: "DejaVu Sans", size: 9pt)
  block(below: 5mm, text(size: 8pt, fill: rgb("#666"), title))
  body
}

/// The theme every fixture renders with, unless it is testing a theme option.
#let vt = theme(font: ("DejaVu Sans",))
