// Breaking music into systems, and placing events along each one.
//
// The result is a single array of x-positions per system, shared by every lane
// drawn on it. That sharing is deliberate: a chord name, a rhythm stem and a
// fret number belonging to the same event must line up vertically, and a
// notation staff added later lines up for free by consuming the same positions.

#import "spacing.typ": barline-allowance, measure-natural

/// Pack measures greedily into systems.
///
/// `widths` holds one packed width per measure — its natural width plus its
/// barline allowance. `indent` is what the system start consumes before any
/// music, i.e. the vertical TAB mark.
///
/// A measure wider than the whole line still gets a system of its own rather
/// than being dropped.
#let pack(widths, available, indent) = {
  let limit = available - indent
  let systems = ()
  let current = ()
  let used = 0pt

  for (i, w) in widths.enumerate() {
    if current.len() > 0 and used + w > limit {
      systems.push(current)
      current = ()
      used = 0pt
    }
    current.push(i)
    used += w
  }
  if current.len() > 0 { systems.push(current) }
  systems
}

/// How far to stretch a system so it reaches the right margin.
///
/// Justification is proportional: one factor applied to every natural width,
/// so measures keep their relative sizes and a bar of sixteenths does not end
/// up as wide as a bar of whole notes.
///
/// A final system that is barely started is left unstretched, the way the last
/// line of a paragraph is — spreading four events across a full page reads as a
/// mistake rather than as music.
#let justify-factor(stretchable, available, last: false, min-fill: 0.65) = {
  if stretchable <= 0pt { return 1.0 }
  let factor = available / stretchable
  if last and factor > 1.0 and available > 0pt and stretchable / available < min-fill {
    return 1.0
  }
  factor
}

/// Assign an x-position to every event in one system.
///
/// Returns `(measures: (…), width: length)`, where each measure carries its
/// start and end x and its events carry the x at which their fret number is
/// centred. Barline allowances are *not* scaled: a repeat sign is a fixed piece
/// of graphic, so only the music between barlines stretches.
#let place-system(theme, measures, times, naturals, glyph-widths, indices, factor, indent) = {
  let x = indent
  let placed = ()

  for mi in indices {
    let m = measures.at(mi)
    let start = x
    if m.start-repeat { x += 1.1 * theme.staff-space }
    x += theme.measure-padding * factor

    let events = ()
    for (i, ev) in m.events.enumerate() {
      let alloc = naturals.at(mi).events.at(i) * factor
      let gw = glyph-widths.at(mi).at(i, default: (total: 0pt, anchor: 0pt))
      events.push((
        event: ev,
        // Aligned on the event's own number, not on the whole run it prints, so
        // a rhythm stem stays over the note it belongs to even when a hammer-on
        // target follows it.
        x: x + gw.anchor / 2 + theme.min-event-gap / 2,
        left: x,
        alloc: alloc,
        glyph-width: gw.total,
      ))
      x += alloc
    }

    x += theme.measure-padding * factor
    x += barline-allowance(theme, m) - (if m.start-repeat { 1.1 * theme.staff-space } else { 0pt })
    placed.push((
      index: mi,
      measure: m,
      // The signature in force here, not merely one declared here: renderers
      // need it for beam grouping and for the count row.
      time: times.at(mi),
      start: start,
      end: x,
      events: events,
    ))
  }

  (measures: placed, width: x)
}

/// Break a part into placed systems.
///
/// `glyph-widths` is a per-measure array of per-event widths, measured by the
/// caller. `available` is the usable line width.
#let layout-part(theme, part, glyph-widths, available, indent) = {
  // The signature in force at each measure, carried forward in one pass —
  // calling `time-signature-at` per measure rescans the part each time, which
  // is quadratic over the piece.
  let times = ()
  let sig = part.time
  for m in part.measures {
    if m.time != none { sig = m.time }
    times.push(sig)
  }
  let naturals = part
    .measures
    .enumerate()
    .map(((i, m)) => measure-natural(theme, m, glyph-widths.at(i, default: ())))
  let packed-widths = part
    .measures
    .enumerate()
    .map(((i, m)) => naturals.at(i).total + barline-allowance(theme, m))

  let groups = pack(packed-widths, available, indent)

  groups
    .enumerate()
    .map(((gi, indices)) => {
      let fixed = indices.fold(0pt, (acc, mi) => acc + barline-allowance(theme, part.measures.at(mi)))
      let stretchable = indices.fold(0pt, (acc, mi) => acc + naturals.at(mi).total)
      let factor = justify-factor(
        stretchable,
        available - indent - fixed,
        last: gi == groups.len() - 1,
      )
      place-system(theme, part.measures, times, naturals, glyph-widths, indices, factor, indent)
    })
}
