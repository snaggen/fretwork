// Visual proof sheet: every vector glyph the package draws, at three sizes.
//
// Compile with `typst compile --root . examples/glyphs.typ`.

#import "/src/render/glyphs.typ" as g

#set page(width: 18cm, height: auto, margin: 1.5cm)
#set text(font: ("Montserrat", "Inter", "Noto Sans"), size: 9pt)

#let sizes = (2.9mm, 5mm, 9mm)

#let row(name, make) = {
  grid(
    columns: (4cm, 1fr),
    align: (left + horizon, left + bottom),
    text(size: 9pt, name),
    stack(
      dir: ltr,
      spacing: 8mm,
      ..sizes.map(sp => {
        let glyph = make(sp)
        // A hairline box shows the reported extent, so a glyph that overflows
        // its own metrics is visible immediately.
        box(
          width: glyph.width,
          height: glyph.height,
          stroke: 0.2pt + rgb("#d0d0d0"),
          glyph.body,
        )
      })
    ),
  )
  v(3mm)
}

= tablature — vector glyphs

#v(4mm)

#row("whole / half rest", sp => g.whole-rest(sp))
#row("quarter rest", sp => g.quarter-rest(sp))
#row("eighth rest", sp => g.eighth-rest(sp))
#row("sixteenth rest", sp => g.sixteenth-rest(sp))
#row("32nd rest", sp => g.flagged-rest(sp, 3))
#row("flag (stem up)", sp => g.flag(sp))
#row("flag (stem down)", sp => g.flag(sp, down: true))
#row("augmentation dot", sp => g.aug-dot(sp))
#row("repeat dots", sp => g.repeat-dots(sp, 5 * sp))
#row("accent", sp => g.accent(sp))
#row("marcato", sp => g.marcato(sp))
#row("staccato", sp => g.staccato(sp))
#row("tenuto", sp => g.tenuto(sp))
#row("downstroke", sp => g.downstroke(sp))
#row("upstroke", sp => g.upstroke(sp))
#row("harmonic diamond", sp => g.harmonic-diamond(sp))
#row("tempo note (quarter)", sp => g.tempo-note(sp))
#row("tempo note (eighth)", sp => g.tempo-note(sp, flags: 1))
#row("tempo note (half)", sp => g.tempo-note(sp, hollow: true))
#row("coda", sp => g.coda(sp))
#row("segno", sp => g.segno(sp))
