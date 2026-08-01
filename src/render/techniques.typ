// Playing techniques drawn above the staff.
//
// The lane is built from sub-rows that appear only when something needs them:
// articulations sit closest to the staff, then vibrato, free text, and
// bracketed spans at the top. An empty row costs no vertical space, so a plain
// riff stays as compact as it would be with no technique support at all.
//
// The division of labour with `tabstaff.typ` is by what a mark is positioned
// against: anything anchored to a *string* — the second number of a hammer-on,
// the line of a slide, a bend arrow — is drawn there. Only marks that belong to
// a lane above the staff are drawn here.

#import "../model.typ": get-technique, has-technique
#import "../layout/lanes.typ": empty-lane, lane
#import "glyphs.typ" as g

/// Labels for bracketed spans. Unknown names are printed as written.
#let SPAN-LABELS = (
  PM: "P.M.",
  LR: "let ring",
)

/// All events of a system in one list, with their x-positions.
///
/// Techniques are flattened across measures on purpose: a palm mute bracket
/// runs from where it starts to where it stops, and barlines do not interrupt it.
#let _flatten(system) = system.measures.map(m => m.events).flatten()

/// Maximal runs of consecutive events carrying the given span.
#let _span-runs(placed, name) = {
  let runs = ()
  let current = ()
  for pe in placed {
    if name in pe.event.spans {
      current.push(pe)
    } else {
      if current.len() > 0 { runs.push(current) }
      current = ()
    }
  }
  if current.len() > 0 { runs.push(current) }
  runs
}

/// Every span name used anywhere in the system, in first-seen order.
#let _span-names(placed) = {
  let names = ()
  for pe in placed {
    for s in pe.event.spans {
      if s not in names { names.push(s) }
    }
  }
  names
}

/// Techniques of a kind carried by any note of an event.
#let _event-techniques(ev, kind) = ev.notes.map(n => get-technique(n, kind)).filter(t => t != none)

#let _ARTICULATIONS = ("accent", "marcato", "staccato", "tenuto", "stroke")

#let _has-articulation(placed) = placed.any(pe => pe.event.notes.any(n => n
  .techniques
  .any(t => t.kind in _ARTICULATIONS)))

#let _has(placed, kind) = placed.any(pe => _event-techniques(pe.event, kind).len() > 0)
#let _has-text(placed) = placed.any(pe => pe.event.text != none)

/// The sub-rows present in this system, bottom to top, with their heights.
#let _rows(theme, placed) = {
  let sp = theme.staff-space
  let rows = ()
  if _has-articulation(placed) { rows.push((name: "artic", height: 0.85 * sp)) }
  if _has(placed, "vibrato") { rows.push((name: "vibrato", height: 0.75 * sp)) }
  if _has(placed, "harmonic") or _has-text(placed) {
    rows.push((name: "text", height: theme.technique-size * 1.3))
  }
  if _span-names(placed).len() > 0 { rows.push((name: "span", height: 1.15 * sp)) }
  rows
}

#let height(theme, system) = {
  let rows = _rows(theme, _flatten(system))
  if rows.len() == 0 { return 0pt }
  rows.fold(0pt, (acc, row) => acc + row.height)
}

/// Top edge of a named row, measured from the top of the lane.
#let _row-top(rows, name, total) = {
  // Rows were collected bottom-up, so stack them from the bottom of the lane.
  let y = total
  for row in rows {
    y -= row.height
    if row.name == name { return y }
  }
  none
}

/// A vibrato squiggle of the given width.
#let _vibrato(theme, x, y, w, wide) = {
  let sp = theme.staff-space
  let amp = if wide { 0.30 * sp } else { 0.18 * sp }
  let step = 0.42 * sp
  let n = calc.max(3, int(w / step))
  let parts = (curve.move((x, y)),)
  for i in range(n) {
    let x0 = x + i * step
    parts.push(curve.cubic(
      (x0 + step * 0.3, y - amp),
      (x0 + step * 0.7, y + amp),
      (x0 + step, y),
    ))
  }
  place(top + left, dx: 0pt, dy: 0pt, curve(
    stroke: (paint: theme.color, thickness: 0.09 * sp, cap: "round"),
    ..parts,
  ))
}

/// Draw the technique lane for one placed system.
#let draw(theme, system, width) = {
  let sp = theme.staff-space
  let placed = _flatten(system)
  let rows = _rows(theme, placed)
  let total = height(theme, system)

  box(width: width, height: total, {
    // --- articulations, closest to the staff ---
    let y = _row-top(rows, "artic", total)
    if y != none {
      for pe in placed {
        for n in pe.event.notes {
          for t in n.techniques {
            let glyph = if t.kind == "accent" {
              g.accent(sp, fill: theme.color)
            } else if t.kind == "marcato" {
              g.marcato(sp, fill: theme.color)
            } else if t.kind == "staccato" {
              g.staccato(sp, fill: theme.color)
            } else if t.kind == "tenuto" {
              g.tenuto(sp, fill: theme.color)
            } else if t.kind == "stroke" and t.dir == "down" {
              g.downstroke(sp, fill: theme.color)
            } else if t.kind == "stroke" {
              g.upstroke(sp, fill: theme.color)
            } else { none }
            if glyph == none { continue }
            place(
              top + left,
              dx: pe.x - glyph.width / 2,
              dy: y + (0.85 * sp - glyph.height) / 2,
              glyph.body,
            )
            break
          }
        }
      }
    }

    // --- vibrato ---
    let y = _row-top(rows, "vibrato", total)
    if y != none {
      for pe in placed {
        for t in _event-techniques(pe.event, "vibrato") {
          _vibrato(theme, pe.x - 0.2 * sp, y + 0.4 * sp, calc.max(1.4 * sp, pe.alloc * 0.8), t.wide)
          break
        }
      }
    }

    // --- harmonics and free text ---
    let y = _row-top(rows, "text", total)
    if y != none {
      for pe in placed {
        let harmonics = _event-techniques(pe.event, "harmonic")
        let label = if pe.event.text != none {
          pe.event.text
        } else if harmonics.len() > 0 {
          let style = harmonics.first().style
          if style == "natural" { "Harm." } else if style == "pinch" { "P.H." } else { "H.H." }
        } else { none }
        if label == none { continue }
        place(
          top + left,
          dx: pe.x - 0.2 * sp,
          dy: y,
          text(
            font: theme.font,
            size: theme.technique-size,
            fill: theme.color,
            top-edge: "cap-height",
            bottom-edge: "baseline",
            label,
          ),
        )
      }
    }

    // --- bracketed spans, furthest from the staff ---
    let y = _row-top(rows, "span", total)
    if y != none {
      for name in _span-names(placed) {
        let label = SPAN-LABELS.at(name, default: name)
        for run in _span-runs(placed, name) {
          let text-body = text(
            font: theme.font,
            size: theme.technique-size,
            fill: theme.color,
            top-edge: "cap-height",
            bottom-edge: "baseline",
            label,
          )
          let label-w = measure(text-body).width
          let x0 = run.first().x - 0.2 * sp
          let x1 = run.last().x + 0.3 * sp
          place(top + left, dx: x0, dy: y, text-body)
          // A dashed rule from the end of the label to the last event, closed
          // by a downward tick, marks how far the instruction reaches.
          if x1 > x0 + label-w + 0.3 * sp {
            place(
              top + left,
              dx: x0 + label-w + 0.3 * sp,
              dy: y + 0.5 * sp,
              line(
                length: x1 - x0 - label-w - 0.3 * sp,
                stroke: (paint: theme.color, thickness: 0.07 * sp, dash: "dashed"),
              ),
            )
            place(
              top + left,
              dx: x1,
              dy: y + 0.5 * sp,
              line(
                angle: 90deg,
                length: 0.45 * sp,
                stroke: (paint: theme.color, thickness: 0.07 * sp),
              ),
            )
          }
        }
      }
    }
  })
}

/// The technique lane, collapsing when nothing needs it.
#let lane-for(theme, system, width) = {
  if height(theme, system) == 0pt { return empty-lane }
  lane(height(theme, system), () => draw(theme, system, width))
}
