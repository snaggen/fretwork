// The tab staff: string lines, fret numbers, barlines and the TAB mark.
//
// The load-bearing visual requirement is that a string line must never run
// through a fret number. The published sheets this package is modelled on solve
// it by printing the numbers on an opaque white patch; here the lines are drawn
// as segments with a computed gap around each number instead. The result looks
// the same and also survives a tinted page background, and the gap costs
// nothing extra to compute because the glyph width is already measured for
// spacing. `theme(mask: "box")` selects the opaque patch for callers who
// prefer it.
//
// Callers must be inside a context, since glyph widths are measured.

#import "../model.typ": get-technique, MUTED
#import "../rational.typ" as r
#import "glyphs.typ" as g

// Vertical geometry shared by the drawing code and by `overflow-above`, in
// staff spaces measured from the string's own line. Keeping the numbers in one
// place is what lets the reserved height match what is actually drawn.
//
// The slur figures are taken off the Hal Leonard legend: its hammer-on slur
// leaves the note line 0.30 spaces up and peaks 1.35 spaces up over a span of
// about six and a half spaces.
#let _TAIL-RISE = 0.55 // where a bend arrow starts above its fret number
#let _BEND-RISE = 1.50 // how far that arrow then climbs
#let _SLUR-TAIL = 0.30 // where a slur or tie leaves the note line
#let _SLUR-APEX-MAX = 1.35 // how high a long one is allowed to peak
#let _SLUR-APEX-MIN = 0.75 // and how flat a short one stays
#let _SLUR-WEIGHT = 0.11 // thickness at the middle, tapering to nothing at the ends

/// How high a slur peaks above the note line, for a given horizontal span.
///
/// The height follows the span rather than being fixed. A long slur rises to
/// the reference height and crosses the line above it at a clear angle; a short
/// one stays flat enough to sit inside the string spacing. A fixed height does
/// one of the two badly: at 1.15 spaces it ran almost tangent to the line one
/// space up and read as merging with it.
#let slur-apex(theme, span) = {
  let sp = theme.staff-space
  calc.max(_SLUR-APEX-MIN * sp, calc.min(_SLUR-APEX-MAX * sp, _SLUR-TAIL * sp + span * 0.22))
}

/// Vertical extent of the staff: string 1 sits at y = 0.
#let height(theme, strings) = (strings - 1) * theme.staff-space

/// y-position of a string's line, counted from the top of the staff.
#let string-y(theme, string) = (string - 1) * theme.staff-space

/// A fret number, set for measurement and for drawing.
///
/// The edges are pinned to the glyph itself rather than to the line box, so the
/// measured height *is* the cap height and centring the box on a string line
/// centres the digits on it exactly.
#let fret-label(theme, fret) = {
  let muted = fret == MUTED
  text(
    font: theme.font,
    size: theme.fret-size,
    weight: 500,
    fill: theme.color,
    number-width: "tabular",
    top-edge: if muted { "x-height" } else { "cap-height" },
    bottom-edge: "baseline",
    if muted { "x" } else { str(fret) },
  )
}

/// The frets a note is linked to by a hammer-on, pull-off or slide.
///
/// These print as further numbers on the same string, joined to the first by a
/// slur or a slide line, and share the parent event's duration. Writing them as
/// separate events with their own note values is the way to give them
/// independent rhythm.
#let link-targets(n) = {
  n
    .techniques
    .filter(t => t.kind in ("hammer", "pull", "slide"))
    .map(t => (kind: t.kind, fret: t.fret, legato: t.at("legato", default: true)))
}

/// Gap between a note and a fret it is linked to.
///
/// Wide enough for the slur joining them to read as an arc. Published sheets set
/// the two numbers of a hammer-on a whole event apart, because there they are
/// separate events; here they share one, so this is the compromise.
#let _link-gap(theme) = 1.15 * theme.staff-space

/// Width an event's fret numbers occupy.
///
/// `total` covers everything the event prints, including linked targets, and
/// governs how much room the spacing engine reserves. `anchor` is the width of
/// the event's own number, which is what every lane aligns on.
///
/// Must be called from a context, since it measures type.
#let event-metrics(theme, ev) = {
  if ev.notes.len() == 0 { return (total: 0pt, anchor: 0pt) }
  let gap = _link-gap(theme)
  let anchor = ev.notes.map(n => measure(fret-label(theme, n.fret)).width).fold(0pt, calc.max)
  let total = ev
    .notes
    .map(n => {
      let widths = (
        (measure(fret-label(theme, n.fret)).width,)
          + link-targets(n).map(t => measure(fret-label(theme, t.fret)).width)
      )
      widths.fold(0pt, (a, b) => a + b) + gap * (widths.len() - 1)
    })
    .fold(0pt, calc.max)
  (total: calc.max(total, anchor), anchor: anchor)
}

/// Merge overlapping intervals, given as `(start, end)` pairs.
#let _merge(intervals) = {
  let sorted = intervals.sorted(key: iv => iv.start)
  let merged = ()
  for iv in sorted {
    if merged.len() > 0 and iv.start <= merged.last().end {
      let last = merged.pop()
      merged.push((start: last.start, end: calc.max(last.end, iv.end)))
    } else {
      merged.push(iv)
    }
  }
  merged
}

/// Draw one string line from 0 to `width`, skipping the given gaps.
#let _line-with-gaps(theme, y, width, gaps) = {
  let segments = ()
  let cursor = 0pt
  for gap in gaps {
    if gap.start > cursor { segments.push((cursor, gap.start)) }
    cursor = calc.max(cursor, gap.end)
  }
  if cursor < width { segments.push((cursor, width)) }

  segments
    .map(((a, b)) => place(
      top + left,
      dx: a,
      dy: y - theme.line / 2,
      rect(width: b - a, height: theme.line, fill: theme.color, stroke: none),
    ))
    .join()
}

/// A barline of the given kind, as `(width, body)`.
///
/// Barlines are drawn heavier than string lines so the metre reads at a glance,
/// and the closing and repeat forms use the conventional thin-then-thick pair.
#let barline(theme, h, kind) = {
  let sp = theme.staff-space
  let thin = theme.barline
  let heavy = theme.heavy-barline
  let gap = 0.28 * sp

  let bar(x, w) = place(
    top + left,
    dx: x,
    dy: 0pt,
    rect(width: w, height: h, fill: theme.color, stroke: none),
  )
  let dots(x) = {
    let d = g.repeat-dots(sp, h, fill: theme.color)
    place(top + left, dx: x, dy: 0pt, d.body)
  }
  let dots-w = 0.28 * sp

  if kind == "single" {
    (width: thin, body: bar(0pt, thin))
  } else if kind == "double" {
    (width: thin * 2 + gap, body: bar(0pt, thin) + bar(thin + gap, thin))
  } else if kind == "final" {
    (width: thin + gap + heavy, body: bar(0pt, thin) + bar(thin + gap, heavy))
  } else if kind == "repeat-start" {
    (
      width: heavy + gap + thin + gap + dots-w,
      body: bar(0pt, heavy) + bar(heavy + gap, thin) + dots(heavy + gap + thin + gap),
    )
  } else if kind == "repeat-end" {
    (
      width: dots-w + gap + thin + gap + heavy,
      body: dots(0pt) + bar(dots-w + gap, thin) + bar(dots-w + gap + thin + gap, heavy),
    )
  } else {
    panic("tabstaff: unknown barline kind '" + kind + "'")
  }
}

/// The slur joining a hammer-on or pull-off to its target.
///
/// Hal Leonard prints the same slur for both: which one it is follows from
/// whether the pitch rises or falls, so no letter is needed.
/// Drawn as a filled lens rather than a stroked curve, so it swells in the
/// middle and tapers to a point at each end the way an engraved slur does. A
/// constant-thickness stroke reads as a wire.
#let _slur(theme, x0, x1, y) = {
  let sp = theme.staff-space
  let span = x1 - x0
  let ends = y - _SLUR-TAIL * sp
  // A cubic peaks at three quarters of its control offset, so the controls sit
  // higher than the apex they produce.
  let lift = (slur-apex(theme, span) - _SLUR-TAIL * sp) * 4 / 3
  let outer = ends - lift
  let inner = outer + _SLUR-WEIGHT * sp * 4 / 3

  place(top + left, dx: 0pt, dy: 0pt, curve(
    fill: theme.color,
    stroke: none,
    curve.move((x0, ends)),
    curve.cubic((x0 + span * 0.3, outer), (x0 + span * 0.7, outer), (x1, ends)),
    curve.cubic((x0 + span * 0.7, inner), (x0 + span * 0.3, inner), (x0, ends)),
    curve.close(),
  ))
}

/// The diagonal joining a slide to its target.
#let _slide-line(theme, x0, x1, y, rising) = {
  let sp = theme.staff-space
  let rise = 0.28 * sp
  place(top + left, dx: 0pt, dy: 0pt, curve(
    stroke: (paint: theme.color, thickness: 0.09 * sp, cap: "round"),
    curve.move((x0 + 0.1 * sp, y + (if rising { rise } else { -rise }))),
    curve.line((x1 - 0.1 * sp, y + (if rising { -rise } else { rise }))),
  ))
}

/// The interval a bend is written with: `full`, `1/2`, `1/4`.
#let bend-label(theme, amount) = {
  let size = if r.eq(amount, r.rat(1)) {
    "full"
  } else if amount.den == 1 {
    str(amount.num)
  } else {
    str(amount.num) + "/" + str(amount.den)
  }
  text(font: theme.font, size: theme.bend-size, weight: 500, fill: theme.color, size)
}

/// An arrowhead pointing along the y axis, with a slightly concave base.
#let _arrowhead(theme, x, y, down: false) = {
  let sp = theme.staff-space
  let d = if down { -1.0 } else { 1.0 }
  place(top + left, dx: 0pt, dy: 0pt, curve(
    fill: theme.color,
    stroke: none,
    curve.move((x, y)),
    curve.line((x - 0.20 * sp, y + d * 0.55 * sp)),
    curve.cubic(
      (x - 0.07 * sp, y + d * 0.40 * sp),
      (x + 0.07 * sp, y + d * 0.40 * sp),
      (x + 0.20 * sp, y + d * 0.55 * sp),
    ),
    curve.close(),
  ))
}

/// A bend arrow, rising from just above the fret number it belongs to.
///
/// Anchoring to the note's own string rather than to a lane above the staff is
/// what the published sheets do, and it is the only way the arrow stays a fixed
/// distance from its number whatever else the system contains.
///
/// `alloc` is the horizontal room the event was given. The lean and the release
/// spacing are both capped by it, so a bend in a bar of sixteenths tightens up
/// instead of running into the next event.
///
/// A pre-bend is already bent when the string is struck, so it gets a straight
/// vertical arrow rather than a curved one — the curve is what shows the pitch
/// rising after the attack.
#let _bend-arrow(theme, x, y, bend, alloc) = {
  let sp = theme.staff-space
  let tail-y = y - _TAIL-RISE * sp
  let peak-y = y - (_TAIL-RISE + _BEND-RISE) * sp
  let head-base = peak-y + 0.5 * sp
  let tip-x = if bend.pre { x } else { x + calc.min(1.0 * sp, alloc * 0.4) }

  place(top + left, dx: 0pt, dy: 0pt, curve(
    stroke: (paint: theme.color, thickness: 0.09 * sp, cap: "round"),
    curve.move((x, tail-y)),
    if bend.pre {
      curve.line((tip-x, head-base))
    } else {
      curve.cubic(
        (x + (tip-x - x) * 0.75, tail-y),
        (tip-x, tail-y - (tail-y - peak-y) * 0.45),
        (tip-x, head-base),
      )
    },
  ))
  _arrowhead(theme, tip-x, peak-y)

  let label = bend-label(theme, bend.amount)
  let size = measure(label)
  // Centred on the tip, but never allowed past the event's own allocation.
  let label-x = calc.min(
    tip-x - size.width / 2,
    x + alloc - theme.min-event-gap / 2 - size.width,
  )
  place(
    top + left,
    dx: calc.max(label-x, x - 0.3 * sp),
    dy: peak-y - size.height - 0.2 * sp,
    label,
  )

  // A release returns to the original pitch: a mirrored arrow back down.
  if bend.release {
    let back-x = tip-x + calc.min(0.9 * sp, alloc * 0.35)
    place(top + left, dx: 0pt, dy: 0pt, curve(
      stroke: (paint: theme.color, thickness: 0.09 * sp, cap: "round"),
      curve.move((tip-x, peak-y)),
      curve.cubic(
        (back-x, peak-y),
        (back-x, peak-y + (tail-y - peak-y) * 0.55),
        (back-x, tail-y - 0.5 * sp),
      ),
    ))
    _arrowhead(theme, back-x, tail-y, down: true)
  }
}

/// How far the drawing reaches above the top string line.
///
/// Bends and slurs are anchored to their own string, so how much room they need
/// above the staff depends on which string that is: the same bend needs far more
/// clearance on string 1 than on string 6. Reserving the space — rather than
/// relying on the box not clipping — is what keeps a bend from colliding with
/// the rhythm lane above it.
///
/// Must be called from a context: the bend label is measured.
#let overflow-above(theme, system) = {
  let sp = theme.staff-space
  let over = 0pt
  for pe in system.measures.map(m => m.events).flatten() {
    for n in pe.event.notes {
      let y = string-y(theme, n.string)
      let bend = get-technique(n, "bend")
      if bend != none {
        let reach = (_TAIL-RISE + _BEND-RISE) * sp + measure(bend-label(theme, bend.amount)).height
        over = calc.max(over, reach + 0.25 * sp - y)
      }
      if link-targets(n).len() > 0 or n.techniques.any(t => t.kind == "tie") {
        over = calc.max(over, slur-apex(theme, pe.alloc) + 0.15 * sp - y)
      }
    }
  }
  over
}

/// How far the drawing reaches below the bottom string line.
///
/// A fret number is centred on its line, so half of one on the lowest string
/// hangs below the staff. Unlike `overflow-above` this does not depend on the
/// music — every system has a bottom string — but it must still be reserved, or
/// the count row rides up into the numbers.
///
/// Must be called from a context: the fret label is measured.
#let overflow-below(theme) = measure(fret-label(theme, 0)).height / 2 + 0.15 * theme.staff-space

/// The vertical TAB mark that opens every system.
///
/// Returns `(width, body)` where `width` is how much the letters actually cover,
/// so the string lines can be broken around them the same way they are broken
/// around fret numbers. `theme.tab-mark-width` is the space reserved for the
/// mark by the layout engine, which is a little wider.
///
/// Must be called from a context: the letter width is measured.
#let tab-mark(theme, strings) = {
  let sp = theme.staff-space
  let h = height(theme, strings)
  let cap = h / 4.8
  let gap = cap * 0.3
  let total = 3 * cap + 2 * gap
  let inset = 0.45 * sp
  let letters = ("T", "A", "B")

  let styled(letter) = text(
    font: theme.font,
    size: cap / 0.72,
    weight: 700,
    fill: theme.color,
    top-edge: "cap-height",
    bottom-edge: "baseline",
    letter,
  )
  let ink = letters.map(l => measure(styled(l)).width).fold(0pt, calc.max)

  (
    width: inset + ink,
    body: box(width: theme.tab-mark-width, height: h, {
      for (i, letter) in letters.enumerate() {
        place(
          top + left,
          dx: inset,
          dy: (h - total) / 2 + i * (cap + gap),
          styled(letter),
        )
      }
    }),
  )
}

/// Draw the tab staff for one placed system.
///
/// `system` comes from `layout/system.typ` and carries the x-position of every
/// event; `width` is the full system width including the indent.
///
/// `overflow` is the room to leave above the top string line for bends and
/// slurs, from `overflow-above`. The staff is pushed down by that much, and the
/// box also allows for what hangs below the bottom line, so the returned box
/// contains everything it draws.
#let draw(theme, strings, system, width, overflow: 0pt) = {
  let sp = theme.staff-space
  let h = height(theme, strings)

  // 1. Fret numbers, measured up front: their widths decide both the gaps in
  //    the string lines and where the digits are drawn. Linked targets are
  //    numbers too, so they are laid out here and joined by a connector.
  let placed = system.measures.map(m => m.events).flatten()
  let labels = ()
  let connectors = ()
  // Where each string's last drawn number ended, so a tie knows where to start.
  for (i, pe) in placed.enumerate() {
    for n in pe.event.notes {
      let body = fret-label(theme, n.fret)
      let size = measure(body)
      let y = string-y(theme, n.string)
      labels.push((x: pe.x, string: n.string, w: size.width, h: size.height, body: body))

      let cursor = pe.x + size.width / 2
      let from-fret = n.fret
      for target in link-targets(n) {
        let tbody = fret-label(theme, target.fret)
        let tsize = measure(tbody)
        let tx = cursor + _link-gap(theme) + tsize.width / 2
        labels.push((x: tx, string: n.string, w: tsize.width, h: tsize.height, body: tbody))
        connectors.push((
          kind: target.kind,
          legato: target.legato,
          from: cursor,
          to: tx - tsize.width / 2,
          y: y,
          rising: target.fret > from-fret,
        ))
        cursor = tx + tsize.width / 2
        from-fret = target.fret
      }

      // A tie runs to the next event that plays this string. When that event
      // falls on the next system the tie trails off instead, which is the
      // conventional way of showing a note held across the break.
      if n.techniques.any(t => t.kind == "tie") {
        let target-x = none
        for j in range(i + 1, placed.len()) {
          let later = placed.at(j).event.notes.filter(o => o.string == n.string)
          if later.len() > 0 {
            target-x = placed.at(j).x - measure(fret-label(theme, later.first().fret)).width / 2
            break
          }
        }
        connectors.push((
          kind: "tie",
          legato: true,
          from: cursor,
          to: if target-x != none { target-x } else { cursor + 1.6 * theme.staff-space },
          y: y,
          rising: false,
        ))
      }

      let bend = get-technique(n, "bend")
      if bend != none {
        connectors.push((kind: "bend", from: pe.x, y: y, bend: bend, alloc: pe.alloc))
      }
    }
  }

  // 2. String lines, broken around the numbers that sit on them. The TAB mark
  //    is not one of them: the reference sheets run their lines straight through
  //    it and let the letters sit over the top, and breaking them there leaves
  //    the outermost lines looking clipped.
  let mark = tab-mark(theme, strings)
  let lines = ()
  for s in range(1, strings + 1) {
    let y = string-y(theme, s)
    let gaps = if theme.mask == "gap" {
      _merge(
        labels
          .filter(l => l.string == s)
          .map(l => (
            start: l.x - l.w / 2 - theme.gap-padding,
            end: l.x + l.w / 2 + theme.gap-padding,
          )),
      )
    } else { () }
    lines.push(_line-with-gaps(theme, y, width, gaps))
  }

  // 3. Barlines. Every system opens with one at the staff edge; each measure
  //    then draws its own opening repeat sign and its closing barline.
  let bars = ()
  bars.push(barline(theme, h, "single").body)

  for m in system.measures {
    if m.measure.start-repeat {
      let b = barline(theme, h, "repeat-start")
      bars.push(place(top + left, dx: m.start, dy: 0pt, b.body))
    }
    let kind = if m.measure.end-repeat {
      "repeat-end"
    } else if m.measure.end == "final" {
      "final"
    } else if m.measure.end == "double" { "double" } else { "single" }
    let b = barline(theme, h, kind)
    bars.push(place(top + left, dx: m.end - b.width, dy: 0pt, b.body))
  }

  box(width: width, height: overflow + h + overflow-below(theme), place(top + left, dy: overflow, box(
    width: width,
    height: h,
    {
      lines.join()
      bars.join()
      place(top + left, dx: 0pt, dy: 0pt, mark.body)

      for l in labels {
        // An opaque patch instead of a broken line, when asked for.
        if theme.mask == "box" {
          place(
            top + left,
            dx: l.x - l.w / 2 - theme.gap-padding,
            dy: string-y(theme, l.string) - l.h / 2 - 0.1 * sp,
            rect(
              width: l.w + 2 * theme.gap-padding,
              height: l.h + 0.2 * sp,
              fill: white,
              stroke: none,
            ),
          )
        }
        place(
          top + left,
          dx: l.x - l.w / 2,
          dy: string-y(theme, l.string) - l.h / 2,
          l.body,
        )
      }

      // Connectors are drawn last so they sit over the numbers they join. What
      // they reach above the top string line is reserved by `overflow-above`.
      for c in connectors {
        if c.kind == "bend" {
          _bend-arrow(theme, c.from, c.y, c.bend, c.alloc)
        } else if c.kind == "slide" {
          _slide-line(theme, c.from, c.to, c.y, c.rising)
          if c.legato { _slur(theme, c.from, c.to, c.y) }
        } else {
          _slur(theme, c.from, c.to, c.y)
        }
      }
    },
  )))
}
