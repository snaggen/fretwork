// Playing techniques drawn above the staff.
//
// Marks pack sideways rather than into fixed lanes: each sits as close to the
// staff as it fits, and things stack only where they are actually in each
// other's way. A palm mute in one bar and an instruction in the next therefore
// share a level, and a plain riff costs no vertical space at all.
//
// Marks of one kind move together, so every palm mute in a system stays at one
// height. When two kinds do collide the order decides, closest to the staff
// first: articulations, vibrato, trills and scrapes, free text, spans.
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

/// Marks that print as a word followed by a wavy line running over the event.
#let _WAVY-LABELS = (trill: "tr", scrape: "P.S.")

/// Vertical clearance between two levels of marks.
#let _LEVEL-GAP = 0.15

/// A vibrato squiggle, drawn from its left edge with `y` at its top.
#let _vibrato-mark(theme, x, y, w, wide) = {
  let wave = g.wavy(theme.staff-space, w, amp: if wide { 0.30 } else { 0.18 }, fill: theme.color)
  place(top + left, dx: x, dy: y, wave.body)
}

/// A short label, set in the technique face.
#let _label(theme, body, italic: false) = text(
  font: theme.font,
  size: theme.technique-size,
  style: if italic { "italic" } else { "normal" },
  fill: theme.color,
  top-edge: "cap-height",
  bottom-edge: "baseline",
  body,
)

/// Every mark the lane has to place.
///
/// A mark records the horizontal room it needs and how to draw itself at a
/// given top edge. They come back grouped by kind, ordered by how close to the
/// staff the kind wants to sit — which is the order the packer tries them in.
///
/// Must be called from a context: labels are measured.
#let _marks(theme, placed) = {
  let sp = theme.staff-space
  let groups = ()

  // --- articulations, one glyph per event ---
  let artic = ()
  for pe in placed {
    for n in pe.event.notes {
      let glyph = none
      for t in n.techniques {
        glyph = if t.kind == "accent" {
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
        if glyph != none { break }
      }
      if glyph == none { continue }
      let x = pe.x - glyph.width / 2
      artic.push((
        x0: x,
        x1: x + glyph.width,
        height: 0.85 * sp,
        draw: y => place(top + left, dx: x, dy: y + (0.85 * sp - glyph.height) / 2, glyph.body),
      ))
      break
    }
  }
  if artic.len() > 0 { groups.push(artic) }

  // --- vibrato ---
  let vibrato = ()
  for pe in placed {
    for t in _event-techniques(pe.event, "vibrato") {
      let w = calc.max(1.4 * sp, pe.alloc * 0.8)
      let x = pe.x - 0.2 * sp
      vibrato.push((
        x0: x,
        x1: x + w,
        height: 0.75 * sp,
        draw: y => _vibrato-mark(theme, x, y + 0.1 * sp, w, t.wide),
      ))
      break
    }
  }
  if vibrato.len() > 0 { groups.push(vibrato) }

  // --- a trill or a pick scrape: a word, then a wavy line for as long as it lasts ---
  let wavy = ()
  for pe in placed {
    for kind in _WAVY-LABELS.keys() {
      if _event-techniques(pe.event, kind).len() == 0 { continue }
      let word = _label(theme, _WAVY-LABELS.at(kind), italic: kind == "trill")
      let word-w = measure(word).width
      let wave = g.wavy(
        sp,
        calc.max(1.2 * sp, pe.alloc - word-w - 0.5 * sp),
        fill: theme.color,
      )
      let x = pe.x - 0.2 * sp
      wavy.push((
        x0: x,
        x1: x + word-w + 0.25 * sp + wave.width,
        height: theme.technique-size * 1.3,
        draw: y => {
          place(top + left, dx: x, dy: y, word)
          place(
            top + left,
            dx: x + word-w + 0.25 * sp,
            dy: y + theme.technique-size * 0.25,
            wave.body,
          )
        },
      ))
    }
  }
  if wavy.len() > 0 { groups.push(wavy) }

  // --- harmonics and free instructions ---
  let texts = ()
  for pe in placed {
    let harmonics = _event-techniques(pe.event, "harmonic")
    let word = if pe.event.text != none {
      pe.event.text
    } else if harmonics.len() > 0 {
      let style = harmonics.first().style
      if style == "natural" { "Harm." } else if style == "pinch" { "P.H." } else { "H.H." }
    } else { none }
    if word == none { continue }
    let body = _label(theme, word)
    let x = pe.x - 0.2 * sp
    texts.push((
      x0: x,
      x1: x + measure(body).width,
      height: theme.technique-size * 1.3,
      draw: y => place(top + left, dx: x, dy: y, body),
    ))
  }
  if texts.len() > 0 { groups.push(texts) }

  // --- bracketed spans ---
  let spans = ()
  for name in _span-names(placed) {
    let body = _label(theme, SPAN-LABELS.at(name, default: name))
    let label-w = measure(body).width
    for run in _span-runs(placed, name) {
      let x0 = run.first().x - 0.2 * sp
      let x1 = run.last().x + 0.3 * sp
      let rule-x = x0 + label-w + 0.3 * sp
      spans.push((
        x0: x0,
        x1: calc.max(x1, rule-x),
        height: 1.15 * sp,
        draw: y => {
          place(top + left, dx: x0, dy: y, body)
          // A dashed rule to the last event, closed by a tick that crosses it
          // rather than merely hanging off it. Dash and gap are each about a
          // third of a staff space, and the rule meets the label near its
          // baseline rather than at its cap.
          if x1 > rule-x {
            let rule-y = y + 0.5 * sp
            place(top + left, dx: rule-x, dy: rule-y, line(
              length: x1 - rule-x,
              stroke: (
                paint: theme.color,
                thickness: 0.07 * sp,
                dash: (array: (0.30 * sp, 0.30 * sp), phase: 0pt),
              ),
            ))
            place(top + left, dx: x1, dy: rule-y - 0.28 * sp, line(
              angle: 90deg,
              length: 1.05 * sp,
              stroke: (paint: theme.color, thickness: 0.07 * sp),
            ))
          }
        },
      ))
    }
  }
  if spans.len() > 0 { groups.push(spans) }

  groups
}

/// Pack groups of marks into as few levels as the horizontal room allows.
///
/// Published sheets pack sideways: a mark sits as close to the staff as it fits,
/// and things only stack where they are actually in each other's way. Reserving
/// a level per kind for the whole system instead makes a system taller than it
/// needs to be whenever two marks are in different bars.
///
/// A whole group moves together, so every palm mute in a system stays at one
/// height. Groups are offered the levels in the order `_marks` returns them, so
/// when two do collide the closer-to-the-staff kind wins the lower level.
#let _pack(groups) = {
  let levels = ()
  for group in groups {
    let target = none
    for (i, level) in levels.enumerate() {
      let clear = group.all(m => level.all(o => m.x1 <= o.x0 or m.x0 >= o.x1))
      if clear {
        target = i
        break
      }
    }
    if target == none {
      levels.push(group)
    } else {
      levels.at(target) = levels.at(target) + group
    }
  }
  levels
}

/// The levels of a system, each with the height it needs.
#let _levels(theme, system) = {
  _pack(_marks(theme, _flatten(system))).map(level => (
    marks: level,
    height: level.fold(0pt, (acc, m) => calc.max(acc, m.height)),
  ))
}

/// Total height of the lane.
#let height(theme, system) = {
  let levels = _levels(theme, system)
  if levels.len() == 0 { return 0pt }
  let gap = _LEVEL-GAP * theme.staff-space
  levels.fold(0pt, (acc, l) => acc + l.height) + gap * (levels.len() - 1)
}

/// Draw the technique lane for one placed system.
#let draw(theme, system, width, levels: none) = {
  let levels = if levels != none { levels } else { _levels(theme, system) }
  if levels.len() == 0 { return box(width: width, height: 0pt) }

  let gap = _LEVEL-GAP * theme.staff-space
  let total = levels.fold(0pt, (acc, l) => acc + l.height) + gap * (levels.len() - 1)

  box(width: width, height: total, {
    // Level 0 sits closest to the staff, so the stack is laid out upwards from
    // the bottom of the lane.
    let bottom = total
    for level in levels {
      let y = bottom - level.height
      for m in level.marks {
        (m.draw)(y)
      }
      bottom = y - gap
    }
  })
}

/// The technique lane, collapsing when nothing needs it.
#let lane-for(theme, system, width) = {
  // Packed once and handed to `draw`, rather than worked out twice.
  let levels = _levels(theme, system)
  if levels.len() == 0 { return empty-lane }
  let gap = _LEVEL-GAP * theme.staff-space
  let total = levels.fold(0pt, (acc, l) => acc + l.height) + gap * (levels.len() - 1)
  lane(total, () => draw(theme, system, width, levels: levels))
}
