// Public API of the `tablature` package.
//
//   #import "@local/tablature:0.1.0": *
//
//   #show: song.with(title: "Twelve Past Nine", tempo: 132)
//   #section("Main Riff")
//   #tab(```
//   |: q (2/5 2/4 0/6)  q x  e 0/3 3/6 0/6 0/6 :|
//   ```)

#import "model.typ"
#import "rational.typ"
#import "tuning.typ": tunings, tuning, to-pitch, pitch-name, string-count
#import "theme.typ": theme, default-theme
#import "parse/dsl.typ"
#import "parse/ascii.typ"
#import "parse/ascii.typ": even, fill
#import "layout/lanes.typ": lane, stack-lanes
#import "layout/system.typ": layout-part
#import "render/tabstaff.typ"
#import "render/rhythm.typ"
#import "render/chordnames.typ"
#import "render/techniques.typ"
#import "render/voltas.typ"
#import "page.typ": song, section, credits

/// Width every event needs for its fret numbers.
///
/// Measured once and reused for spacing, for the gaps in the string lines and
/// for drawing, so the three can never disagree.
#let _glyph-widths(thm, part) = {
  part.measures.map(m => m.events.map(ev => tabstaff.event-metrics(thm, ev)))
}

/// Report problems where the reader can actually see them.
///
/// Typst offers no user-level warning channel: `panic` is the only diagnostic
/// it has and it is fatal. A problem that must not stop the compile therefore
/// has nowhere to go but the page. That is the point — a bar that is short is
/// worth knowing about — and it is why `place(hide[…])` was the wrong answer:
/// it satisfied the type checker and showed the reader nothing.
///
/// `warn: false` on `tab` and `ascii-tab` silences this once the sheet is as
/// intended.
#let _diagnostics(thm, source, messages) = {
  if messages.len() == 0 { return }
  block(
    width: 100%,
    above: thm.staff-space * 0.7,
    below: thm.staff-space * 1.0,
    fill: rgb("#fdf3f0"),
    stroke: (left: 2pt + rgb("#b4491f")),
    inset: (x: 7pt, y: 5pt),
    text(
      font: thm.font,
      size: thm.technique-size,
      fill: rgb("#7a2e11"),
      messages.map(m => source + ": " + m).join(linebreak()),
    ),
  )
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

  // Reported rather than raised: a partially filled model is legal, and an
  // imported tab is often musically imperfect but still worth setting.
  if warn { _diagnostics(thm, "tab", model.validate(part)) }

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
      // above it, then the rhythm, then chord names, and the endings furthest
      // out, as they bracket whole measures rather than single events.
      let lanes = (
        voltas.lane-for(thm, sys, w),
        chordnames.lane-for(thm, sys, w),
        rhythm.lane-for(thm, sys, w),
        techniques.lane-for(thm, sys, w),
        {
          // Bends and slurs are anchored to their own string and reach above the
          // top line by an amount that depends on which string that is, and a
          // fret number on the lowest string hangs below it. The staff lane
          // reserves both rather than overflowing into its neighbours.
          let over = tabstaff.overflow-above(thm, sys)
          let under = tabstaff.overflow-below(thm, sys)
          lane(over + tabstaff.height(thm, strings) + under, () => tabstaff.draw(
            thm,
            strings,
            sys,
            w,
            overflow: over,
          ))
        },
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

/// Typeset a pasted ASCII tab.
///
/// A bare paste always renders. Everything ASCII tab cannot carry — note
/// values, chord names, sections, spans — can be supplied, and supplying it is
/// optional and incremental:
///
/// - **Column-aligned annotation rows** inside the block, which is the primary
///   mechanism because a fact attaches to exactly the column it describes:
///   `R:` note values, `C:` chord names, `S:` a section heading, `T:` a playing
///   instruction, `PM:` and `LR:` bracketed spans.
/// - **Named arguments** for facts about the whole piece: `tuning`, `time`,
///   `tempo`, `capo`, `anacrusis`.
/// - **`rhythm:`** for the common cases: `even(1/8)`, `fill`, or an explicit
///   sequence such as `"q q e e"`.
///
/// `enrich` is the escape hatch for anything the three do not cover: it
/// receives the parsed part and returns a modified one.
///
/// ```typc
/// ascii-tab(```
/// R:   q   q   e e
/// e|---0---2---3-5--|
/// ```, rhythm: even(1/8))
/// ```
#let ascii-tab(
  source,
  tuning: tunings.standard,
  time: (4, 4),
  tempo: none,
  capo: 0,
  anacrusis: false,
  rhythm: none,
  count-in: false,
  theme: default-theme,
  enrich: none,
  warn: true,
) = {
  let result = ascii.parse(
    source,
    tuning: tuning,
    time: time,
    tempo: tempo,
    capo: capo,
    anacrusis: anacrusis,
    rhythm: rhythm,
  )
  let part = if enrich != none { enrich(result.part) } else { result.part }

  // Sections carried by `S:` rows are headings in their own right.
  for mark in part.sections {
    if mark.index == 0 { section(mark.title, theme: theme) }
  }

  // The staff first, then one report covering both what the source could not
  // say and what the result does not add up to. `tab` is told to stay quiet so
  // the two do not appear as separate blocks.
  tab(part, theme: theme, count-in: count-in, warn: false)

  // Malformed input is reported but never fatal: a real tab is usually
  // imperfect, and refusing to set it would defeat the purpose of importing.
  if warn {
    _diagnostics(theme, "ascii-tab", result.warnings + model.validate(part))
  }
}

/// Convert an ASCII tab to equivalent DSL source.
///
/// Once a tab is fully annotated it is as complete as one written by hand, and
/// this is how it graduates to the native syntax: import, print, keep.
#let ascii-to-dsl(source, ..args) = dsl.write(ascii.parse(source, ..args).part)
