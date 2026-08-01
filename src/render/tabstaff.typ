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

#import "../model.typ": MUTED
#import "glyphs.typ" as g

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
#let _link-gap(theme) = 0.85 * theme.staff-space

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
#let _slur(theme, x0, x1, y) = {
  let sp = theme.staff-space
  place(top + left, dx: 0pt, dy: 0pt, curve(
    stroke: (paint: theme.color, thickness: 0.08 * sp, cap: "round"),
    curve.move((x0, y - 0.5 * sp)),
    curve.cubic(
      (x0 + (x1 - x0) * 0.3, y - 1.15 * sp),
      (x0 + (x1 - x0) * 0.7, y - 1.15 * sp),
      (x1, y - 0.5 * sp),
    ),
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
#let draw(theme, strings, system, width, indent: 0pt) = {
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
    }
  }

  // 2. String lines, broken around the numbers that sit on them — and around
  //    the TAB mark, which the same rule applies to.
  let mark = tab-mark(theme, strings)
  let mark-gap = (start: 0.3 * sp, end: mark.width + 0.25 * sp)
  let lines = ()
  for s in range(1, strings + 1) {
    let y = string-y(theme, s)
    let gaps = if theme.mask == "gap" {
      _merge(
        (mark-gap,)
          + labels
            .filter(l => l.string == s)
            .map(l => (
              start: l.x - l.w / 2 - theme.gap-padding,
              end: l.x + l.w / 2 + theme.gap-padding,
            )),
      )
    } else { (mark-gap,) }
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

  box(width: width, height: h, {
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

    // Connectors are drawn last so they sit over the numbers they join, and
    // they are allowed to reach above the top string line — the box does not
    // clip, and the lane gap above leaves room.
    for c in connectors {
      if c.kind == "slide" {
        _slide-line(theme, c.from, c.to, c.y, c.rising)
        if c.legato { _slur(theme, c.from, c.to, c.y) }
      } else {
        _slur(theme, c.from, c.to, c.y)
      }
    }
  })
}
