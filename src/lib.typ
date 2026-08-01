// Public API of the `tablature` package.
//
//   #import "@local/tablature:0.1.0": *
//
//   #show: song.with(title: "T.N.T.", tempo: 127)
//   #section("Main Riff")
//   #tab(```
//   |: q (2/5 2/4 0/6)  q x  e 0/3 3/6 0/6 0/6 :|
//   ```)

#import "model.typ"
#import "rational.typ"
#import "tuning.typ": tunings, tuning, to-pitch, pitch-name, string-count
#import "theme.typ": theme, default-theme
#import "parse/dsl.typ"
#import "layout/lanes.typ": lane, stack-lanes
#import "layout/system.typ": layout-part
#import "render/tabstaff.typ"
#import "render/rhythm.typ"
#import "render/chordnames.typ"
#import "render/techniques.typ"
#import "page.typ": song, section, credits

/// Width every event needs for its fret numbers.
///
/// Measured once and reused for spacing, for the gaps in the string lines and
/// for drawing, so the three can never disagree.
#let _glyph-widths(thm, part) = {
  part.measures.map(m => m.events.map(ev => tabstaff.event-metrics(thm, ev)))
}

/// Typeset a passage of tablature.
///
/// `source` is either DSL source — a raw block or a string — or an already
/// parsed part, which lets callers build one programmatically.
///
/// ```typc
/// tab(```
/// q (2/5 2/4 0/6)  q x  e 0/3 3/6 0/6 0/6
/// ```)
/// ```
#let tab(
  source,
  tuning: tunings.standard,
  time: (4, 4),
  tempo: none,
  capo: 0,
  anacrusis: false,
  count-in: false,
  theme: default-theme,
  warn: true,
) = {
  let thm = theme
  let part = if type(source) == dictionary and source.at("kind", default: none) == "part" {
    source
  } else {
    dsl.parse(source, tuning: tuning, time: time, tempo: tempo, capo: capo, anacrusis: anacrusis)
  }

  if warn {
    for problem in model.validate(part) {
      // A warning rather than an error: a partially filled model is legal, and
      // an imported tab is often musically imperfect but still worth setting.
      // Typst has no user-level warning channel, so this goes to the document.
      place(hide[#problem])
    }
  }

  layout(size => {
    let strings = string-count(part.tuning)
    let widths = _glyph-widths(thm, part)
    let systems = layout-part(thm, part, widths, size.width, thm.tab-mark-width)

    for (i, sys) in systems.enumerate() {
      // Every lane is drawn to the system's own width, not to the full line: an
      // unjustified final system must stop at its last barline rather than
      // trailing string lines out to the margin.
      let w = sys.width

      // Bottom to top: the count row under the staff, technique marks directly
      // above it, then the rhythm, then chord names furthest out.
      let lanes = (
        chordnames.lane-for(thm, sys, w),
        rhythm.lane-for(thm, sys, w),
        techniques.lane-for(thm, sys, w),
        lane(tabstaff.height(thm, strings), () => tabstaff.draw(thm, strings, sys, w)),
        rhythm.count-lane-for(thm, sys, w, enabled: count-in and i == 0),
      )
      // A system must never be split by a page break.
      block(breakable: false, stack-lanes(lanes, w, thm.lane-gap))
      if i < systems.len() - 1 { v(thm.system-gap, weak: true) }
    }
  })
}

/// Render a part programmatically, bypassing the DSL.
#let render(part, theme: default-theme, count-in: false) = tab(
  part,
  theme: theme,
  count-in: count-in,
)
