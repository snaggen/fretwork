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
  write(m.part(measures: parse-measures("q 7/3tr9 7/3TP 7/3PS 7/3A 7/3R"))),
  "q 7/3tr9 7/3TP 7/3PS 7/3A 7/3R |",
  "the later technique additions round-trip too",
)
#eq(
  write(m.part(measures: parse-measures("{PM: q 0/6 0/6}"))),
  "{PM: q 0/6 0/6 } |",
  "spans round-trip as groups",
)
#eq(write(m.part(measures: parse-measures("|: q 0/6 :|"))), "|: q 0/6 :|", "repeats round-trip")
#eq(write(m.part(measures: parse-measures("@E5 q 0/6"))), "@E5 q 0/6 |", "chord names round-trip")

#report("ascii")

// --- markers that sit between the notes they join ------------------------
// Written tabs put the target wherever the column falls, so a marker has to
// reach forward to the next note on the row rather than demanding a digit
// immediately after it. Requiring adjacency silently dropped most of the
// hammer-ons and slides in a real transcription.

#let joined(body) = events-of(block(body))

#eq(joined("--5h7----").len(), 1, "an adjacent target stays inside one event")
#eq(
  m.get-technique(joined("--5h7----").first().notes.first(), "hammer").fret,
  7,
  "…as a hammer-on to that fret",
)

#for form in ("--5h-7---", "--5-h-7--", "--5---h---7--") {
  let evs = joined(form)
  eq(evs.len(), 2, "'" + form.trim("-") + "' is two events")
  eq(
    m.get-technique(evs.first().notes.first(), "hammer").fret,
    7,
    "…joined by a hammer-on to the second",
  )
  eq(evs.last().notes.first().fret, 7, "…and the second note survives")
}

#eq(
  m.get-technique(joined("--5/-7---").first().notes.first(), "slide").fret,
  7,
  "a slash reaches the next note too",
)
#eq(
  m.get-technique(joined("--7\\-5---").first().notes.first(), "slide").fret,
  5,
  "and a backslash downwards",
)
#eq(
  m.get-technique(joined("--5p-7---").first().notes.first(), "pull").fret,
  7,
  "so does a pull-off",
)
#eq(
  m.get-technique(joined("--12h-14--").first().notes.first(), "hammer").fret,
  14,
  "multi-digit frets on both sides",
)

#eq(
  m.get-technique(joined("--5s7----").first().notes.first(), "slide").fret,
  7,
  "'s' is a slide in ASCII tab, not a stray character splitting the note",
)
#ok(m.has-technique(joined("--t12----").first().notes.first(), "tap"), "'t' taps the note it precedes")

// A marker with nothing to point at is dropped rather than invented.
#eq(joined("--5h-----").first().notes.first().techniques, (), "a dangling marker attaches to nothing")
#eq(joined("--5h-----").len(), 1, "…and does not conjure an event")

// The importer takes the same source, so it needs the same repair.
#eq(
  parse(```e|--0---2--|
B|---------|
G|---------|
D|---------|
A|---------|
E|---------|```).part.measures.first().events.len(),
  2,
  "a raw block whose first token is a string label keeps that row",
)

// --- bend sizes spelled out in letters ------------------------------------
// `hb` and `fb` are common in pasted tabs. The reading has to stay unambiguous
// against `h` for hammer-on, which it is: a hammer-on always writes its target
// as digits, so an `h` pressed directly against a `b` can only be a size.

#let bends(row) = {
  let pad = "-------------"
  let src = "e|" + pad + "|\nB|" + pad + "|\nG|" + row + "|\nD|" + pad + "|\nA|" + pad + "|\nE|" + pad + "|"
  parse(src).part.measures.first().events.first().notes.first().techniques
}

#eq(bends("--3hb--------").first().amount, r.rat(1, den: 2), "`hb` is a half bend")
#eq(bends("--3fb--------").first().amount, r.rat(1), "`fb` is a full bend")
#eq(bends("--3hb--------").first().kind, "bend", "…and nothing else comes of it")
#eq(bends("--3hb--------").len(), 1, "in particular, no hammer-on is invented")
#eq(bends("--3hbr-------").first().release, true, "a release still folds in after")
#eq(bends("--3hbr-------").first().amount, r.rat(1, den: 2), "…keeping the size")

// The readings that existed before must not have moved.
#eq(bends("--3b---------").first().amount, r.rat(1), "a bare `b` is still a whole step")
#eq(bends("--3b5--------").first().amount, r.rat(1), "`3b5` is still two frets, a step")
#eq(bends("--3b4--------").first().amount, r.rat(1, den: 2), "`3b4` is still one fret")
#eq(bends("--3h5--------").first().kind, "hammer", "`h` with a target is still a hammer-on")
#eq(bends("--3h5--------").first().fret, 5, "…pointing where it did")
#eq(bends("--3bh5-------").len(), 2, "a bend followed by a hammer-on still reads as both")

// A target names the pitch wanted, so it wins over a size given in letters.
#eq(bends("--3hb5-------").first().amount, r.rat(1), "an explicit target beats `hb`")
// A stray `f` is not a technique and must leave the note alone.
#eq(bends("--3f---------").len(), 0, "a bare `f` adds nothing")

// --- a bend must rise ------------------------------------------------------
// `5b3` used to come out as an upward arrow labelled "−1": the size is
// `(target − fret)/2` and nothing checked the sign. The note survives, the
// arrow is refused, and the author is told.

#let down = parse("e|-------------|\nB|-------------|\nG|--5b3---3b3--|\nD|-------------|\nA|-------------|\nE|-------------|")
#eq(
  down.part.measures.first().events.map(ev => ev.notes.first().techniques.len()),
  (0, 0),
  "a non-rising bend attaches no technique",
)
#eq(
  down.warnings.filter(w => w.contains("does not rise")).len(),
  2,
  "…and each one is reported",
)
#eq(
  down.part.measures.first().events.map(ev => ev.notes.first().fret),
  (5, 3),
  "…while the notes themselves survive",
)

// --- ending rows -----------------------------------------------------------
// `1:` and `2:` mark first and second endings with dash runs, the way `PM:`
// marks its extent. They attach to measures, which is what a volta is.

#let volta-tab = parse("1:        ------------
2:                       ---------
e|--0---2--|--3---5-----|--7---8--|
B|---------|------------|---------|
G|---------|------------|---------|
D|---------|------------|---------|
A|---------|------------|---------|
E|---------|------------|---------|")
#eq(
  volta-tab.part.measures.map(me => me.volta),
  (none, (1,), (2,)),
  "ending rows become voltas on the measures under their dashes",
)
