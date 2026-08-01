// Music symbols, drawn as vector paths.
//
// Typst packages cannot ship fonts — a font dependency has to be installed by
// hand by every user, which is the well-known pain point of packages that need
// one. Drawing the symbols instead keeps the package self-contained and works
// at any size, and phase 1 needs only a small set: flags, rests, dots, repeat
// signs, articulations and the note value in a tempo mark.
//
// Every glyph returns `(width, height, body)`. The body is a box of exactly
// that size with the drawing inside, so callers position it by its top-left
// corner and know its extent without measuring.

/// Wrap a drawing in a box of known size.
///
/// Every element inside `body` must be positioned with `_draw` or `_blob`.
/// Content that merely flows would push the box past its declared extent, and
/// callers rely on `width` and `height` being exact.
#let _glyph(w, h, body) = (width: w, height: h, body: box(width: w, height: h, body))

/// Anchor a drawing at the glyph's top-left corner.
#let _draw(el) = place(top + left, dx: 0pt, dy: 0pt, el)

/// Place a filled circle by its centre.
#let _blob(cx, cy, r, fill) = place(
  top + left,
  dx: cx - r,
  dy: cy - r,
  circle(radius: r, fill: fill, stroke: none),
)

#let _stroke(sp, weight, paint) = (
  paint: paint,
  thickness: weight * sp,
  cap: "round",
  join: "round",
)

// ---------------------------------------------------------------------------
// Rests
// ---------------------------------------------------------------------------

/// Whole rest: a block hanging below the line it is measured from.
#let whole-rest(sp, fill: black) = _glyph(
  1.15 * sp,
  0.45 * sp,
  _draw(rect(width: 1.15 * sp, height: 0.45 * sp, fill: fill, stroke: none)),
)

/// Half rest: the same block, sitting on its line.
#let half-rest(sp, fill: black) = whole-rest(sp, fill: fill)

/// Quarter rest: the zigzag, ending in a curl.
///
/// Drawn as four stroked segments of different weights rather than as one
/// filled outline. The shape is defined by the taper of its strokes, and
/// varying the stroke weight reproduces that far more legibly at small sizes
/// than an outline with a dozen control points would.
#let quarter-rest(sp, fill: black) = _glyph(
  0.95 * sp,
  2.2 * sp,
  {
    _draw(curve(
      stroke: _stroke(sp, 0.28, fill),
      curve.move((0.20 * sp, 0.18 * sp)),
      curve.line((0.68 * sp, 0.70 * sp)),
    ))
    _draw(curve(
      stroke: _stroke(sp, 0.13, fill),
      curve.move((0.68 * sp, 0.70 * sp)),
      curve.line((0.24 * sp, 1.08 * sp)),
    ))
    _draw(curve(
      stroke: _stroke(sp, 0.28, fill),
      curve.move((0.24 * sp, 1.08 * sp)),
      curve.line((0.76 * sp, 1.64 * sp)),
    ))
    _draw(curve(
      stroke: _stroke(sp, 0.15, fill),
      curve.move((0.76 * sp, 1.64 * sp)),
      curve.cubic((0.46 * sp, 1.66 * sp), (0.18 * sp, 1.82 * sp), (0.46 * sp, 2.05 * sp)),
    ))
  },
)

/// A flagged rest: a slanted stem carrying `n` hooks — an eighth rest for
/// `n = 1`, a sixteenth for 2, a thirty-second for 3.
#let flagged-rest(sp, n, fill: black) = {
  let h = (1.25 + 0.5 * n) * sp
  let (x0, y0) = (0.70 * sp, 0.28 * sp)
  let (x1, y1) = (0.22 * sp, h - 0.10 * sp)
  _glyph(
    0.92 * sp,
    h,
    {
      _draw(curve(
        stroke: _stroke(sp, 0.10, fill),
        curve.move((x0, y0)),
        curve.line((x1, y1)),
      ))
      // Hooks hang to the left of the stem, stepping down it as it leans over.
      for i in range(n) {
        let t = (0.05 + i * 0.44) / (0.05 + n * 0.44)
        _blob(
          x0 + (x1 - x0) * t - 0.17 * sp,
          y0 + (y1 - y0) * t + 0.10 * sp,
          0.21 * sp,
          fill,
        )
      }
    },
  )
}

#let eighth-rest(sp, fill: black) = flagged-rest(sp, 1, fill: fill)
#let sixteenth-rest(sp, fill: black) = flagged-rest(sp, 2, fill: fill)

/// The rest for a given number of flags: 0 is a quarter, -1 a half, -2 a whole.
#let rest-for(sp, flags, fill: black) = {
  if flags <= -2 {
    whole-rest(sp, fill: fill)
  } else if flags == -1 {
    half-rest(sp, fill: fill)
  } else if flags == 0 {
    quarter-rest(sp, fill: fill)
  } else {
    flagged-rest(sp, flags, fill: fill)
  }
}

// ---------------------------------------------------------------------------
// Flags
// ---------------------------------------------------------------------------

/// A single stem flag, drawn for a stem that points up.
///
/// The origin is the tip of the stem and the flag falls away to the right. Pass
/// `down: true` to mirror it for a downward stem, which is what the rhythm lane
/// above a tab staff uses.
#let flag(sp, down: false, fill: black) = {
  let w = 1.0 * sp
  let h = 1.75 * sp
  let shape = curve(
    fill: fill,
    stroke: none,
    // Outer edge: away from the stem, then a long sweep down to the tip.
    curve.move((0pt, 0pt)),
    curve.cubic((0.78 * sp, 0.38 * sp), (0.96 * sp, 1.00 * sp), (0.30 * sp, h)),
    // Inner edge back to the stem, hollowed out so the flag tapers.
    curve.cubic((0.52 * sp, 1.05 * sp), (0.38 * sp, 0.58 * sp), (0pt, 0.48 * sp)),
    curve.close(),
  )
  _glyph(w, h, _draw(if down { scale(y: -100%, origin: center + horizon, shape) } else { shape }))
}

// ---------------------------------------------------------------------------
// Dots and repeat signs
// ---------------------------------------------------------------------------

/// Augmentation dot.
#let aug-dot(sp, fill: black) = _glyph(
  0.30 * sp,
  0.30 * sp,
  _blob(0.15 * sp, 0.15 * sp, 0.15 * sp, fill),
)

/// The pair of dots on a repeat barline, centred within `height`.
#let repeat-dots(sp, height, fill: black) = {
  let r = 0.14 * sp
  _glyph(2 * r, height, {
    _blob(r, height / 2 - 0.55 * sp, r, fill)
    _blob(r, height / 2 + 0.55 * sp, r, fill)
  })
}

// ---------------------------------------------------------------------------
// Articulations
// ---------------------------------------------------------------------------

#let accent(sp, fill: black) = _glyph(
  0.85 * sp,
  0.62 * sp,
  _draw(curve(
    stroke: _stroke(sp, 0.13, fill),
    curve.move((0.04 * sp, 0.04 * sp)),
    curve.line((0.81 * sp, 0.31 * sp)),
    curve.line((0.04 * sp, 0.58 * sp)),
  )),
)

#let marcato(sp, fill: black) = _glyph(
  0.70 * sp,
  0.62 * sp,
  _draw(curve(
    stroke: _stroke(sp, 0.14, fill),
    curve.move((0.06 * sp, 0.58 * sp)),
    curve.line((0.35 * sp, 0.05 * sp)),
    curve.line((0.64 * sp, 0.58 * sp)),
  )),
)

#let staccato(sp, fill: black) = _glyph(
  0.26 * sp,
  0.26 * sp,
  _blob(0.13 * sp, 0.13 * sp, 0.13 * sp, fill),
)

#let tenuto(sp, fill: black) = _glyph(
  0.70 * sp,
  0.14 * sp,
  _draw(curve(
    stroke: _stroke(sp, 0.11, fill),
    curve.move((0.04 * sp, 0.07 * sp)),
    curve.line((0.66 * sp, 0.07 * sp)),
  )),
)

/// Downstroke: the square bracket of a down pick.
#let downstroke(sp, fill: black) = _glyph(
  0.55 * sp,
  0.65 * sp,
  _draw(curve(
    stroke: _stroke(sp, 0.13, fill),
    curve.move((0.07 * sp, 0.61 * sp)),
    curve.line((0.07 * sp, 0.06 * sp)),
    curve.line((0.48 * sp, 0.06 * sp)),
    curve.line((0.48 * sp, 0.61 * sp)),
  )),
)

/// Upstroke: the V of an up pick.
#let upstroke(sp, fill: black) = _glyph(
  0.55 * sp,
  0.65 * sp,
  _draw(curve(
    stroke: _stroke(sp, 0.13, fill),
    curve.move((0.07 * sp, 0.06 * sp)),
    curve.line((0.28 * sp, 0.59 * sp)),
    curve.line((0.49 * sp, 0.06 * sp)),
  )),
)

/// The diamond marking a harmonic.
#let harmonic-diamond(sp, fill: black) = _glyph(
  0.66 * sp,
  0.66 * sp,
  _draw(curve(
    stroke: _stroke(sp, 0.10, fill),
    curve.move((0.33 * sp, 0.05 * sp)),
    curve.line((0.61 * sp, 0.33 * sp)),
    curve.line((0.33 * sp, 0.61 * sp)),
    curve.line((0.05 * sp, 0.33 * sp)),
    curve.close(),
  )),
)

/// A wavy line, used for vibrato, trills, pick scrapes and arpeggios.
///
/// `vertical: true` runs it down the staff instead of along it, which is the
/// form an arpeggio or a rake takes beside a chord.
#let wavy(sp, length, amp: 0.18, vertical: false, fill: black) = {
  let step = 0.42 * sp
  let n = calc.max(2, int(length / step))
  let a = amp * sp
  let along(t) = if vertical { (a, t) } else { (t, a) }
  let across(t, d) = if vertical { (a + d, t) } else { (t, a + d) }

  let parts = (curve.move(along(0pt)),)
  for i in range(n) {
    let t = i * step
    parts.push(curve.cubic(
      across(t + step * 0.3, -a),
      across(t + step * 0.7, a),
      along(t + step),
    ))
  }
  let thickness = 0.09 * sp
  _glyph(
    if vertical { 2 * a + thickness } else { n * step },
    if vertical { n * step } else { 2 * a + thickness },
    _draw(curve(stroke: (paint: fill, thickness: thickness, cap: "round"), ..parts)),
  )
}

// ---------------------------------------------------------------------------
// Note values used outside the staff
// ---------------------------------------------------------------------------

/// A note value for a tempo mark, e.g. the quarter in "Moderately ♩ = 116".
///
/// `flags` counts the flags: 0 is a quarter, 1 an eighth. Drawn rather than set
/// as U+2669 because most sans faces have no coverage for it, and those that do
/// draw it at a weight unrelated to the surrounding text.
#let tempo-note(sp, flags: 0, hollow: false, fill: black) = {
  let head-w = 0.92 * sp
  let head-h = 0.64 * sp
  let h = 2.7 * sp
  let stem-x = head-w - 0.10 * sp
  _glyph(
    if flags > 0 { stem-x + 0.09 * sp + 1.0 * sp } else { head-w },
    h,
    {
      place(
        top + left,
        dx: 0pt,
        dy: h - head-h,
        rotate(
          -20deg,
          ellipse(
            width: head-w,
            height: head-h,
            fill: if hollow { none } else { fill },
            stroke: if hollow { 0.10 * sp + fill } else { none },
          ),
        ),
      )
      place(
        top + left,
        dx: stem-x,
        dy: 0.12 * sp,
        rect(width: 0.09 * sp, height: h - head-h - 0.02 * sp, fill: fill, stroke: none),
      )
      if flags > 0 {
        place(top + left, dx: stem-x + 0.09 * sp, dy: 0.12 * sp, flag(sp, fill: fill).body)
      }
    },
  )
}

// ---------------------------------------------------------------------------
// Navigation marks
// ---------------------------------------------------------------------------

/// Coda: a circle crossed by a vertical and a horizontal bar.
#let coda(sp, fill: black) = {
  let d = 1.5 * sp
  let pad = 0.28 * sp
  let total = d + 2 * pad
  _glyph(total, total, {
    place(top + left, dx: pad, dy: pad, circle(radius: d / 2, fill: none, stroke: 0.11 * sp + fill))
    _draw(curve(
      stroke: _stroke(sp, 0.11, fill),
      curve.move((total / 2, 0.02 * sp)),
      curve.line((total / 2, total - 0.02 * sp)),
    ))
    _draw(curve(
      stroke: _stroke(sp, 0.11, fill),
      curve.move((0.02 * sp, total / 2)),
      curve.line((total - 0.02 * sp, total / 2)),
    ))
  })
}

/// Segno: an S crossed by a slash, with a dot in each of the two open corners.
#let segno(sp, fill: black) = {
  let w = 1.45 * sp
  let h = 1.6 * sp
  _glyph(w, h, {
    _draw(curve(
      stroke: _stroke(sp, 0.15, fill),
      curve.move((1.02 * sp, 0.32 * sp)),
      curve.cubic((0.70 * sp, 0.08 * sp), (0.34 * sp, 0.34 * sp), (0.62 * sp, 0.62 * sp)),
      curve.cubic((0.94 * sp, 0.92 * sp), (0.62 * sp, 1.30 * sp), (0.30 * sp, 1.18 * sp)),
    ))
    _draw(curve(
      stroke: _stroke(sp, 0.09, fill),
      curve.move((1.06 * sp, 0.24 * sp)),
      curve.line((0.28 * sp, 1.32 * sp)),
    ))
    _blob(1.10 * sp, 0.98 * sp, 0.10 * sp, fill)
    _blob(0.28 * sp, 0.56 * sp, 0.10 * sp, fill)
  })
}
