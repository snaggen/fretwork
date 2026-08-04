#import "helpers.typ": ok, eq, report
#import "/src/rational.typ" as r
#import "/src/model.typ" as m
#import "/src/theme.typ": theme
#import "/src/layout/beams.typ": beat-unit, dots-of, flags-of, group-beams, sub-beams, tuplet-runs
#import "/src/layout/spacing.typ": event-natural, measure-natural
#import "/src/layout/system.typ": justify-factor, layout-part, pack
#import "/src/parse/dsl.typ": parse, parse-measures
#import "/src/render/tabstaff.typ"
#import "/src/render/dynamics.typ"
#import "/src/render/rhythm.typ"

#let thm = theme(staff-space: 3mm)
#let events(src) = parse-measures(src).first().events

// --- note values ----------------------------------------------------------

#eq(flags-of(m.event(duration: m.durations.q)), 0, "a quarter has no flags")
#eq(flags-of(m.event(duration: m.durations.e)), 1, "an eighth has one")
#eq(flags-of(m.event(duration: m.durations.s)), 2, "a sixteenth has two")
#eq(flags-of(m.event(duration: m.durations.h)), -1, "a half is below the flag threshold")
#eq(flags-of(m.event(duration: m.durations.w)), -2, "and a whole further below")
#eq(flags-of(m.event(duration: r.rat(3, den: 8))), 0, "a dotted quarter flags like a quarter")
#eq(dots-of(m.event(duration: r.rat(3, den: 8))), 1, "…and reports its dot")
#eq(flags-of(m.event()), none, "an unknown duration has no flag count")

// --- beat units -----------------------------------------------------------

#eq(beat-unit((4, 4)), r.rat(1, den: 4), "4/4 beats in quarters")
#eq(beat-unit((3, 4)), r.rat(1, den: 4), "3/4 too")
#eq(beat-unit((6, 8)), r.rat(3, den: 8), "6/8 is compound: three eighths to a beat")
#eq(beat-unit((12, 8)), r.rat(3, den: 8), "12/8 likewise")
#eq(beat-unit((3, 8)), r.rat(1, den: 8), "3/8 is simple, not compound")
#eq(beat-unit(none), none, "no time signature, no beat")

// --- beam grouping --------------------------------------------------------
// Beams show where the beats are, so a group never crosses a beat boundary.

#eq(
  group-beams(events("e 0/6 0/6 0/6 0/6 0/6 0/6 0/6 0/6"), (4, 4)),
  ((0, 1), (2, 3), (4, 5), (6, 7)),
  "eighths in 4/4 beam in pairs, one per beat",
)
#eq(
  group-beams(events("s 0/6 0/6 0/6 0/6"), (4, 4)),
  ((0, 1, 2, 3),),
  "four sixteenths fill one beat and beam together",
)
#eq(
  group-beams(events("q 0/6 e 0/6 0/6"), (4, 4)),
  ((1, 2),),
  "a quarter is not beamed and does not join the group after it",
)
#eq(
  group-beams(events("e 0/6 r 0/6 0/6"), (4, 4)),
  ((0,), (2, 3)),
  "a rest breaks the beam",
)
#eq(
  group-beams(events("e 0/6 0/6 0/6 0/6 0/6 0/6"), (6, 8)),
  ((0, 1, 2), (3, 4, 5)),
  "6/8 beams in threes",
)
#eq(
  group-beams(events("h 0/6 0/6"), (4, 4)),
  (),
  "half notes form no beam groups at all",
)
#eq(
  group-beams(events("0/6 0/6"), (4, 4)),
  (),
  "events with no duration are not beamed",
)

// A sixteenth pair inside a beat of eighths shares the primary beam but only
// the pair carries the second.
#let mixed = events("e 0/6 s 0/6 0/6")
#eq(group-beams(mixed, (4, 4)), ((0, 1, 2),), "the whole beat is one group")
#eq(sub-beams(mixed, (0, 1, 2), 1), ((0, 1, 2),), "the primary beam spans the group")
#eq(sub-beams(mixed, (0, 1, 2), 2), ((1, 2),), "the second beam spans only the sixteenths")

// --- tuplets --------------------------------------------------------------

#let trip = events("{3: e 0/6 2/6 3/6} q 0/6")
#eq(
  tuplet-runs(trip),
  ((tuplet: (count: 3, of: 2), indices: (0, 1, 2)),),
  "consecutive events with the same tuplet form one run",
)
#eq(tuplet-runs(events("q 0/6 0/6")), (), "no tuplet, no runs")

// --- optical spacing ------------------------------------------------------
// Width grows with duration, but far more slowly: a whole note is nowhere near
// eight times as wide as an eighth.

#let w(src) = event-natural(thm, events(src).first(), 4mm)
#ok(w("e 0/6") < w("q 0/6"), "an eighth is narrower than a quarter")
#ok(w("q 0/6") < w("h 0/6"), "a quarter is narrower than a half")
#ok(w("w 0/6") < 4 * w("e 0/6"), "a whole note is not eight times an eighth")
#ok(w("w 0/6") > w("h 0/6"), "but it is still the widest")

// A wide glyph sets the floor, so a bar mixing 0 and 12 keeps its columns clear.
#ok(
  event-natural(thm, events("t 0/6").first(), 12mm) >= 12mm,
  "a wide fret number is never overlapped by the next event",
)

#let natural = measure-natural(
  thm,
  parse-measures("q 0/6 0/6 0/6 0/6").first(),
  ((total: 4mm, anchor: 4mm),) * 4,
)
#eq(natural.events.len(), 4, "one width per event")
#ok(
  natural.total > natural.events.fold(0mm, (a, b) => a + b),
  "the measure total includes its padding",
)

// --- packing and justification --------------------------------------------

#eq(pack((30mm, 30mm, 30mm), 100mm, 10mm), ((0, 1, 2),), "three measures fit on one system")
#eq(pack((30mm, 30mm, 30mm), 70mm, 10mm), ((0, 1), (2,)), "the third overflows to the next")
#eq(pack((80mm,), 50mm, 10mm), ((0,),), "an oversized measure still gets a system")
#eq(pack((), 100mm, 10mm), (), "no measures, no systems")

#eq(justify-factor(50mm, 100mm), 2.0, "an interior system stretches to the margin")
#eq(justify-factor(200mm, 100mm), 0.5, "an overfull system is compressed")
#eq(justify-factor(10mm, 100mm, last: true), 1.0, "a barely started last system is not stretched")
#ok(
  justify-factor(90mm, 100mm, last: true) > 1.0,
  "a nearly full last system is justified like any other",
)
#eq(
  justify-factor(60mm, 100mm, last: true),
  1.0,
  "a last system below the fill threshold keeps its natural width",
)

// --- reserved room above the staff ----------------------------------------
// Bends and slurs are anchored to their own string, so how far they reach above
// the top line depends on which string that is. The staff lane reserves exactly
// that much, which is what keeps a bend clear of the rhythm lane above it.

#context {
  let system(src) = {
    let part = parse(src)
    let widths = part.measures.map(m => m.events.map(ev => tabstaff.event-metrics(thm, ev)))
    layout-part(thm, part, widths, 120mm, thm.tab-mark-width).first()
  }
  let over(src) = tabstaff.overflow-above(thm, system(src))
  let under(src) = tabstaff.overflow-below(thm, 6, system(src))

  eq(over("q 0/6 0/6 0/6 0/6"), 0pt, "plain notes need no room above the staff")
  ok(over("q 7/1b 0/6 0/6 0/6") > 0pt, "a bend on the top string does")
  ok(
    over("q 7/6b 0/6 0/6 0/6") < over("q 7/1b 0/6 0/6 0/6"),
    "the same bend on the bottom string needs less, since the staff itself gives room",
  )
  ok(over("q 5/1h7 0/6 0/6 0/6") > 0pt, "a slur on the top string needs room too")
  ok(
    over("q 5/1h7 0/6 0/6 0/6") < over("q 7/1b 0/6 0/6 0/6"),
    "but less than a bend, which climbs further and carries a label",
  )
  eq(over("q 5/6h7 0/6 0/6 0/6"), 0pt, "a slur low on the staff needs none at all")

  // A slur leaving a number's side is held far lower than one springing over its
  // top, so that it stays inside its own string's space.
  let span = 4 * thm.staff-space
  ok(
    tabstaff.slur-apex(thm, span, side: true) < tabstaff.slur-apex(thm, span),
    "a side-attached slur peaks lower than a top-attached one",
  )
  ok(
    tabstaff.slur-apex(thm, span, side: true) < thm.staff-space,
    "…and below the line one space up, which is what it has to clear",
  )
  // A tie is drawn under its line, so it reserves nothing above — and below only
  // when it is on the lowest string, where it leaves the staff.
  eq(over("q 5/1~ 5/1 0/6 0/6"), 0pt, "a tie asks for no room above the staff")
  eq(
    under("q 5/1~ 5/1 0/6 0/6"),
    under("q 5/1 5/1 0/6 0/6"),
    "…nor below, while it hangs inside the staff",
  )
  ok(
    under("q 5/6~ 5/6 0/6 0/6") > under("q 5/1~ 5/1 0/6 0/6"),
    "…but a tie on the lowest string hangs past it, and that has to be reserved",
  )
  ok(
    tabstaff.tie-depth(thm, span, side: true) < tabstaff.tie-depth(thm, span),
    "a chord's tie, leaving the numbers' flanks, dips less than a lone note's",
  )
  ok(
    tabstaff.tie-depth(thm, span) < thm.staff-space,
    "…and neither reaches the line below, which is what they must clear",
  )

  // The dynamics lane costs nothing at all until something is written in it,
  // which is what lets it be added below every staff unconditionally.
  eq(dynamics.lane-for(thm, system("q 0/6 0/6 0/6 0/6"), 120mm).height, 0pt,
     "no dynamic, no lane")
  ok(dynamics.lane-for(thm, system("!mf q 0/6 0/6 0/6 0/6"), 120mm).height > 0pt,
     "…and a dynamic opens one")
  ok(dynamics.lane-for(thm, system("{cresc: q 0/6 0/6 0/6 0/6}"), 120mm).height > 0pt,
     "…as does a gradual change on its own")

  // Rests are drawn inside the staff, so a bar of nothing but them needs no
  // rhythm lane at all — and a bar that mixes them with notes still does.
  eq(rhythm.lane-for(thm, system("q r r r r"), 120mm).height, 0pt,
     "a bar of rests asks for no rhythm lane")
  ok(rhythm.lane-for(thm, system("q r 0/6 r 0/6"), 120mm).height > 0pt,
     "…but one note in it brings the lane back for that note's stem")

  // A rest is drawn on the staff, so it has to claim the room its glyph needs.
  // Optical spacing alone buys a thirty-second almost none, and the glyph is
  // wider than a fret number — left unclaimed, fast rests overlap each other.
  ok(
    event-natural(thm, events("t r").first(), 0pt) >= tabstaff.rest-glyph(thm, events("t r").first()).width,
    "a rest is never narrower than the glyph it prints",
  )
  eq(
    tabstaff.rest-glyph(thm, events("q 0/6").first()),
    none,
    "a note prints no rest glyph",
  )
  eq(
    tabstaff.rest-glyph(thm, m.event(rest: true)),
    none,
    "…nor does a rest whose length is unknown",
  )

  // A ghost note prints in parentheses, so it is wider than the bare number and
  // the gap in the string line has to follow.
  ok(
    tabstaff.event-metrics(thm, events("q 5/3g").first()).anchor
      > tabstaff.event-metrics(thm, events("q 5/3").first()).anchor,
    "a ghost note claims the width of its parentheses",
  )

  // An ornate repeat sign's serifs reach past the staff at both ends, so the
  // lane has to reserve room for them too.
  let ornate = theme(staff-space: 3mm, repeat-style: "ornate")
  let ornate-system(src) = {
    let part = parse(src)
    let widths = part.measures.map(m => m.events.map(ev => tabstaff.event-metrics(ornate, ev)))
    layout-part(ornate, part, widths, 120mm, ornate.tab-mark-width).first()
  }
  ok(
    tabstaff.overflow-above(ornate, ornate-system("|: q 0/6 0/6 0/6 0/6 :|")) > 0pt,
    "an ornate repeat reserves room above the staff",
  )
  eq(
    tabstaff.overflow-above(ornate, ornate-system("q 0/6 0/6 0/6 0/6")),
    0pt,
    "…but only where there is a repeat to draw",
  )
  ok(
    tabstaff.overflow-below(ornate, 6, ornate-system("|: q 0/6 0/6 0/6 0/6 :|"))
      > tabstaff.overflow-below(thm, 6, system("|: q 0/6 0/6 0/6 0/6 :|")),
    "and room below, which the plain style does not need",
  )
}

#report("layout")
