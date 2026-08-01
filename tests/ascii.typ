#import "helpers.typ": ok, eq, report
#import "/src/rational.typ" as r
#import "/src/model.typ" as m
#import "/src/tuning.typ": tunings
#import "/src/parse/ascii.typ": even, fill, parse
#import "/src/parse/dsl.typ": parse-measures, write

/// Build a six-string ASCII block from the bodies between the barlines.
///
/// Writing the fixtures this way keeps the column of every fret number obvious,
/// which matters because column position is what carries simultaneity.
#let block(..bodies) = {
  let rows = bodies.pos()
  let width = rows.fold(0, (acc, b) => calc.max(acc, b.len()))
  let filler = "-" * width
  ("e", "B", "G", "D", "A", "E")
    .enumerate()
    .map(((i, label)) => label + "|" + rows.at(i, default: filler) + "|")
    .join("\n")
}

#let part-of(src, ..args) = parse(src, ..args).part
#let events-of(src, ..args) = part-of(src, ..args).measures.map(m => m.events).flatten()

// --- reading fret positions -----------------------------------------------

#let simple = part-of(block(
  "--0---5-",
  "--------",
  "--2-----",
  "--------",
  "-----3--",
  "--------",
))
#eq(simple.measures.len(), 1, "one bar")
#let evs = simple.measures.first().events
#eq(evs.len(), 3, "three columns carry notes")
#eq(evs.at(0).notes, (m.note(1, 0), m.note(3, 2)), "a shared column is a chord")
#eq(evs.at(1).notes, (m.note(5, 3),), "the next column is a single note")
#eq(evs.at(2).notes, (m.note(1, 5),), "and so is the last")
#eq(evs.at(0).duration, none, "a bare paste carries no note values")
#ok(evs.at(0).column-span != none, "but it does record how wide the column was")

// --- multi-digit frets ----------------------------------------------------
// Adjacent digits are one fret; digits parted by filler are separate strikes.
// This is the one place ASCII tab is genuinely ambiguous, and the convention
// is the only reading that makes sense of both.

#let two-digit = events-of(block("--11----"))
#eq(two-digit.len(), 1, "'11' is one event")
#eq(two-digit.first().notes.first().fret, 11, "…on the eleventh fret")

#let one-one = events-of(block("--1-1---"))
#eq(one-one.len(), 2, "'1-1' is two events")
#eq(one-one.map(e => e.notes.first().fret), (1, 1), "…both on the first fret")

#eq(events-of(block("--12-0--")).map(e => e.notes.first().fret), (12, 0), "12 then 0")

// --- barlines -------------------------------------------------------------

#eq(part-of(block("--0--|--3--")).measures.len(), 2, "an interior barline splits the music")

// --- inline techniques ----------------------------------------------------

#let tech(body) = events-of(block(body)).first().notes.first().techniques

#eq(tech("--5h7---").first(), m.technique("hammer", fret: 7), "h is a hammer-on")
#eq(tech("--7p5---").first(), m.technique("pull", fret: 5), "p is a pull-off")
#eq(tech("--5/7---").first().fret, 7, "a forward slash slides up")
#eq(tech("--7\\5---").first().fret, 5, "a backslash slides down")
#eq(tech("--7b9---").first().amount, r.rat(1), "a bend of two frets is a whole step")
#eq(tech("--7b8---").first().amount, r.rat(1, den: 2), "one fret is a half step")
#eq(tech("--7b9r--").first().release, true, "r after a bend is a release")
#eq(tech("--7~----").first(), m.technique("vibrato", wide: false), "a tilde is vibrato")
#eq(tech("--12*---").first().style, "natural", "an asterisk is a natural harmonic")
#eq(tech("--(7)---").first().kind, "ghost", "parentheses mark a ghost note")
#eq(events-of(block("--x-----")).first().notes.first().fret, m.MUTED, "x is a dead string")

// --- noise around the music -----------------------------------------------
// Real tabs are full of headings and comments; they must be skipped, not
// mistaken for music.

#let noisy = parse("Verse riff — play twice\n" + block("--0-----"))
#eq(noisy.part.measures.len(), 1, "a prose line does not break the block")
#eq(noisy.part.measures.first().events.len(), 1, "and the music still reads")

// --- annotation rows ------------------------------------------------------

#let annotated = parse(
  "S:   Main Riff\n"
    + "C:   E5      G5\n"
    + "R:   q   q   e e\n"
    + "PM:  ----\n"
    + block("--0---2---3-5---"),
)
#let ann = annotated.part.measures.first().events
#eq(ann.len(), 4, "four events")
#eq(ann.at(0).duration, m.durations.q, "the R row supplies note values")
#eq(ann.at(1).duration, m.durations.q, "…which stick like the DSL's")
#eq(ann.at(2).duration, m.durations.e, "…until the next token")
#eq(ann.at(3).duration, m.durations.e, "…and then stick again")
#eq(ann.at(0).chord, "E5", "the C row names a chord at its column")
#eq(ann.at(2).chord, "G5", "a name goes to the nearest event, not to every nearby one")
#eq(ann.at(3).chord, none, "columns with no chord name get none")
#eq(annotated.part.sections.first().title, "Main Riff", "the S row becomes a section heading")
#ok("PM" in ann.at(0).spans, "the PM row marks the columns it covers")
#ok("PM" not in ann.at(3).spans, "…and stops where it stops")

// A tuplet is opened with a count and a colon, which stays column-aligned.
#let tuplets = parse("R:   3:  e   e   e\n" + block("--0---2---3-----"))
#let tevs = tuplets.part.measures.first().events
#eq(tevs.at(0).tuplet, (count: 3, of: 2), "'3:' opens a triplet")
#eq(tevs.at(2).tuplet, (count: 3, of: 2), "…covering three events")

// --- inference ------------------------------------------------------------

#let plain = block("--0---2---3-5---")

#ok(
  events-of(plain, rhythm: even(1 / 8)).all(e => e.duration == m.durations.e),
  "even() gives every event one value",
)
#eq(
  m.measure-duration(part-of(plain, rhythm: fill).measures.first()),
  r.rat(1),
  "fill spreads a bar across its time signature",
)
#eq(
  events-of(plain, rhythm: "q q e e").map(e => e.duration),
  (m.durations.q, m.durations.q, m.durations.e, m.durations.e),
  "an explicit sequence is spent event by event",
)

// Annotation wins over inference: a value already set is never overwritten.
#eq(
  events-of("R:   h\n" + block("--0---2---"), rhythm: even(1 / 8)).at(0).duration,
  m.durations.h,
  "the R row wins over the rhythm argument",
)

// --- warnings, not silent misreadings -------------------------------------

#let ragged = parse(
  "e|---0---2--|\nB|---|\nG|----------|\nD|----------|\nA|----------|\nE|----------|",
)
#ok(ragged.warnings.len() > 0, "rows of different lengths are reported")

#ok(
  parse(block("--30----")).warnings.any(w => "30" in w),
  "a fret above the 24th is reported",
)

// --- round trip -----------------------------------------------------------
// A fully annotated ASCII tab is equivalent to one written in the DSL, and
// this is how it graduates to the native syntax.

#let annotated-src = "R:   q   q   e   e\n" + block("--0---2---3---5---")
#let dsl-source = write(parse(annotated-src).part)
#eq(
  parse-measures(dsl-source).first().events.map(e => (e.notes, e.duration)),
  events-of(annotated-src).map(e => (e.notes, e.duration)),
  "an annotated ASCII tab round-trips through the DSL unchanged",
)

// --- the writer -----------------------------------------------------------

#eq(
  write(m.part(measures: parse-measures("q 0/6 e 2/5 3/4"))),
  "q 0/6 e 2/5 3/4 |",
  "note values are written only where they change",
)
#eq(
  write(m.part(measures: parse-measures("q (2/5 2/4 0/6) x r"))),
  "q (2/5 2/4 0/6) x r |",
  "chords, mutes and rests round-trip",
)
#eq(
  write(m.part(measures: parse-measures("q 5/3h7 7/3b(1/2) 12/3* 7/3~"))),
  "q 5/3h7 7/3b(1/2) 12/3* 7/3~ |",
  "techniques round-trip through their suffixes",
)
#eq(
  write(m.part(measures: parse-measures("{PM: q 0/6 0/6}"))),
  "{PM: q 0/6 0/6 } |",
  "spans round-trip as groups",
)
#eq(write(m.part(measures: parse-measures("|: q 0/6 :|"))), "|: q 0/6 :|", "repeats round-trip")
#eq(write(m.part(measures: parse-measures("@E5 q 0/6"))), "@E5 q 0/6 |", "chord names round-trip")

#report("ascii")
