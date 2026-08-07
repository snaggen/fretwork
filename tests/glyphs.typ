#import "helpers.typ": ok, eq, report
#import "/src/render/glyphs.typ" as g

// The ink profile of a rest, which is what the staff breaks its string lines
// around. Measuring the bounding box instead is the defect this exists to
// prevent: a quarter rest is a narrow zigzag, so a line grazing its corner was
// broken as widely as one through its middle, and a fret number — measured type
// — got a tighter gap than the rest standing beside it.

#let sp = 10pt
#let quarter = g.quarter-rest(sp)
#let eighth = g.eighth-rest(sp)

#let span-at(glyph, fraction) = {
  let y = glyph.height * fraction
  g.ink-span(glyph, y - 0.02 * sp, y + 0.02 * sp)
}
#let width-at(glyph, fraction) = {
  let s = span-at(glyph, fraction)
  if s == none { 0pt } else { s.end - s.start }
}

// --- the profile covers the glyph, and no more -----------------------------

#let whole = g.ink-span(quarter, 0pt, quarter.height)
#ok(whole.start >= 0pt, "the ink never starts left of the glyph")
#ok(whole.end <= quarter.width, "…nor ends right of it")
#ok(whole.end - whole.start > 0.8 * quarter.width, "…and it does fill most of the box")

#eq(g.ink-span(quarter, quarter.height * 2, quarter.height * 3), none, "no ink below the glyph")
#eq(g.ink-span(quarter, -2 * sp, -sp), none, "…and none above it")

// --- the zigzag is narrower at its ends than across its middle -------------

#ok(
  width-at(quarter, 0.02) < width-at(quarter, 0.5),
  "a quarter rest's top is narrower than its middle",
)
#ok(
  width-at(quarter, 0.5) < quarter.width,
  "…and even its middle is narrower than the box the old gap was taken from",
)

// The eighth rest hangs its hook from a stroke, so the same holds at its foot.
#ok(width-at(eighth, 0.95) < width-at(eighth, 0.15), "an eighth rest tapers towards its foot")

// --- a glyph with no profile falls back to its box -------------------------
// Right for a solid one: the whole and half rests are plain slabs.

#let solid = g.block-rest(sp)
#eq(
  g.ink-span(solid, 0pt, solid.height),
  (start: 0pt, end: solid.width),
  "a rest with no profile reports its full box",
)

#report("glyphs")
