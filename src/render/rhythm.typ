// The rhythm lane: stems, beams, flags, rests and the count row.
//
// Rock tab shows rhythm above the staff without a notation staff underneath, so
// there are no noteheads to hang the values on. Stems descend from a beam at the
// top of the lane towards the staff, exactly as on the sheets this package is
// modelled on. Values longer than a quarter would otherwise be indistinguishable
// from one another, so half and whole notes carry a small hollow head at the top
// of the stem, following the convention used by tab editors.

#import "../rational.typ" as r
#import "../model.typ": sounding-duration
#import "../layout/beams.typ": dots-of, flags-of, group-beams, sub-beams, tuplet-runs
#import "../layout/lanes.typ": empty-lane, lane
#import "glyphs.typ" as g

/// Whether any event in the system carries a note value at all.
#let _has-rhythm(system) = system.measures.any(m => m.events.any(pe => pe.event.duration != none))

/// Whether the system contains a tuplet, which needs room for its numeral.
#let _has-tuplet(system) = system.measures.any(m => m.events.any(pe => pe.event.tuplet != none))

/// Height of the rhythm lane.
#let height(theme, system) = {
  if not _has-rhythm(system) { return 0pt }
  theme.stem-length + theme.rhythm-clearance + (if _has-tuplet(system) { 1.2 * theme.staff-space } else { 0pt })
}

#let _bar(theme, x, y, w, h) = place(
  top + left,
  dx: x,
  dy: y,
  rect(width: w, height: h, fill: theme.color, stroke: none),
)

/// The hollow head marking a half or whole note.
///
/// With no notation staff below there is nothing else to tell a half note from
/// a quarter, so the head does that job. It is an oval, slanted like a real
/// notehead, and sits at the top of the stem where a beam would otherwise be.
#let _hollow-head(theme, x, y) = {
  let sp = theme.staff-space
  // Set to the left of the stem, the way a notehead sits beside an upward stem,
  // rather than threaded onto it.
  place(
    top + left,
    dx: x - 0.80 * sp,
    dy: y - 0.04 * sp,
    rotate(-20deg, ellipse(
      width: 0.84 * sp,
      height: 0.58 * sp,
      fill: none,
      stroke: theme.stem * 1.7 + theme.color,
    )),
  )
}

/// Draw the rhythm for one placed system.
#let draw(theme, system, width) = {
  let sp = theme.staff-space
  let top-pad = if _has-tuplet(system) { 1.2 * sp } else { 0pt }
  let beam-y = top-pad
  let foot = top-pad + theme.stem-length
  let h = height(theme, system)

  box(width: width, height: h, {
    for m in system.measures {
      let events = m.measure.events
      let groups = group-beams(events, m.time)
      let beamed = groups.filter(gr => gr.len() > 1).flatten()

      // Stems, flags and rests.
      for (i, pe) in m.events.enumerate() {
        let ev = pe.event
        let flags = flags-of(ev)
        if flags == none { continue }

        if ev.kind == "rest" {
          let rest = g.rest-for(sp, flags, fill: theme.color)
          // Centring is right for every rest: the flagged ones are drawn about
          // their own middle, and the whole and half rests each carry the line
          // they are measured from at their middle, so centring puts that line
          // at one height and their blocks on opposite sides of it.
          place(
            top + left,
            dx: pe.x - rest.width / 2,
            dy: beam-y + (theme.stem-length - rest.height) / 2,
            rest.body,
          )
          continue
        }

        if flags > -2 {
          _bar(theme, pe.x - theme.stem / 2, beam-y, theme.stem, foot - beam-y)
        }
        if flags < 0 {
          _hollow-head(theme, pe.x, beam-y)
        }
        // An unbeamed eighth or shorter gets its own flag.
        if flags >= 1 and not (i in beamed) {
          let f = g.flag(sp * 0.85, fill: theme.color)
          place(top + left, dx: pe.x, dy: beam-y, f.body)
        }
        // Tremolo picking: slashes across the stem, as many as the legend uses.
        if ev.notes.any(n => n.techniques.any(t => t.kind == "tremolo")) {
          for k in range(3) {
            let sy = beam-y + (0.5 + k * 0.42) * sp
            place(top + left, dx: 0pt, dy: 0pt, curve(
              stroke: (paint: theme.color, thickness: theme.beam-thickness * 0.6, cap: "butt"),
              curve.move((pe.x - 0.32 * sp, sy + 0.22 * sp)),
              curve.line((pe.x + 0.32 * sp, sy - 0.12 * sp)),
            ))
          }
        }
        for d in range(dots-of(ev)) {
          let dot = g.aug-dot(sp, fill: theme.color)
          place(
            top + left,
            dx: pe.x + 0.35 * sp + d * 0.4 * sp,
            dy: foot - 0.5 * sp,
            dot.body,
          )
        }
      }

      // Beams. The primary spans the whole group; each further level spans only
      // the runs fast enough to need it, so a sixteenth among eighths gets a
      // stub rather than a full beam.
      for group in groups.filter(gr => gr.len() > 1) {
        let deepest = group.map(i => flags-of(events.at(i))).fold(0, calc.max)
        for level in range(1, deepest + 1) {
          let y = beam-y + (level - 1) * (theme.beam-thickness + theme.beam-gap)
          for run in sub-beams(events, group, level) {
            let (x0, x1) = if run.len() > 1 {
              (m.events.at(run.first()).x, m.events.at(run.last()).x)
            } else {
              // A lone note at this level gets a stub, pointing back towards
              // the group it belongs to.
              let x = m.events.at(run.first()).x
              let stub = 0.8 * sp
              if run.first() == group.first() { (x, x + stub) } else { (x - stub, x) }
            }
            _bar(theme, x0 - theme.stem / 2, y, x1 - x0 + theme.stem, theme.beam-thickness)
          }
        }
      }

      // Tuplet numerals, above the beam.
      for run in tuplet-runs(events) {
        if run.tuplet == none or run.indices.len() == 0 { continue }
        let xs = run.indices.map(i => m.events.at(i).x)
        let mid = (xs.first() + xs.last()) / 2
        place(
          top + center,
          dx: mid - width / 2,
          dy: 0pt,
          text(
            font: theme.font,
            size: 0.95 * sp,
            weight: 600,
            style: "italic",
            fill: theme.color,
            str(run.tuplet.count),
          ),
        )
      }
    }
  })
}

/// The rhythm lane, or an empty lane when the music carries no note values.
#let lane-for(theme, system, width) = {
  if not _has-rhythm(system) { return empty-lane }
  lane(height(theme, system), () => draw(theme, system, width))
}

// ---------------------------------------------------------------------------
// Count row
// ---------------------------------------------------------------------------

#let _SUBDIVISIONS = (
  (r.rat(0), ""),
  (r.rat(1, den: 4), "e"),
  (r.rat(1, den: 2), "+"),
  (r.rat(3, den: 4), "a"),
)

/// The syllable counted at a position within a beat, or `none` if it falls
/// between the four subdivisions a player would actually count.
#let _syllable(offset, beat) = {
  let frac = r.div(offset, beat)
  for (at, name) in _SUBDIVISIONS {
    if r.eq(frac, at) { return name }
  }
  none
}

/// Draw the "1 2 3 + 4 +" row under the staff.
#let draw-count(theme, system, width) = {
  let sp = theme.staff-space
  box(width: width, height: theme.count-size, {
    for m in system.measures {
      let time = m.time
      let beat = if time == none { r.rat(1, den: 4) } else { r.rat(1, den: time.at(1)) }
      let position = r.zero

      for pe in m.events {
        let d = sounding-duration(pe.event)
        let beats = r.to-float(r.div(position, beat))
        let whole = calc.floor(beats)
        let offset = r.sub(position, r.mul(beat, r.rat(whole)))
        let syllable = _syllable(offset, beat)
        if syllable != none and pe.event.kind != "rest" {
          let label = if syllable == "" { str(whole + 1) } else { syllable }
          place(
            top + center,
            dx: pe.x - width / 2,
            dy: 0pt,
            text(
              font: theme.font,
              size: theme.count-size,
              weight: 700,
              style: "italic",
              fill: theme.color,
              top-edge: "cap-height",
              bottom-edge: "baseline",
              label,
            ),
          )
        }
        if d == none { break }
        position = r.add(position, d)
      }
    }
  })
}

/// The count row lane, shown only where it was asked for and is derivable.
#let count-lane-for(theme, system, width, enabled: false) = {
  if not enabled or not _has-rhythm(system) { return empty-lane }
  lane(theme.count-size + 0.3 * theme.staff-space, () => draw-count(theme, system, width))
}
