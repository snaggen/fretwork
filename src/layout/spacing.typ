// Horizontal spacing: how much room each event and each measure wants.
//
// Spacing is optical rather than proportional. A whole note lasts eight times
// as long as an eighth but is nowhere near eight times as wide on the page —
// engravers have always compressed the relationship, and `spacing-exponent`
// (0.6 by default) is that compression. Proportional spacing would leave long
// notes stranded in white space and cram fast passages together.
//
// The functions here are pure: glyph widths are measured by the caller, which
// is what keeps the packing logic testable without a layout context.

#import "../rational.typ" as r
#import "../model.typ": sounding-duration

/// Natural width of one event.
///
/// `glyph-width` is the total width the event's fret numbers occupy, including
/// any linked hammer-on or slide target, so a `12` claims more room than a `0`
/// and `5h7` more than either.
///
/// An event with no duration — an ASCII tab imported without rhythm — falls
/// back to the width of a quarter, optionally stretched by `column-span` so that
/// the source's own column positions still shape the result.
#let event-natural(theme, ev, glyph-width) = {
  let d = sounding-duration(ev)
  let base = if d == none {
    let span = ev.at("column-span", default: none)
    if span == none { theme.quarter-width } else { theme.quarter-width * span }
  } else {
    theme.quarter-width * calc.pow(r.to-float(d) * 4.0, theme.spacing-exponent)
  }
  calc.max(base, glyph-width + theme.min-event-gap)
}

/// Natural widths for every event in a measure, plus the measure total.
///
/// `glyph-widths` is one `(total, anchor)` pair per event, in order: `total` is
/// the width of everything the event prints, `anchor` the width of the number
/// the event is aligned on.
#let measure-natural(theme, measure, glyph-widths) = {
  let widths = measure.events.enumerate().map(((i, ev)) => event-natural(
    theme,
    ev,
    glyph-widths.at(i, default: (total: 0pt, anchor: 0pt)).total,
  ))
  let total = widths.fold(0pt, (a, b) => a + b) + 2 * theme.measure-padding
  (events: widths, total: total)
}

/// Extra width claimed by a measure's opening and closing barlines.
///
/// Repeat signs are wide, and a system whose measures all carry them must make
/// room or the music is squeezed.
#let barline-allowance(theme, measure) = {
  let sp = theme.staff-space
  let left = if measure.start-repeat { 1.1 * sp } else { 0pt }
  let right = if measure.end-repeat {
    1.1 * sp
  } else if measure.end == "final" { 0.6 * sp } else if measure.end == "double" {
    0.35 * sp
  } else { 0pt }
  left + right
}
