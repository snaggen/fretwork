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

// A run of digits is one fret only as far as that fret exists. Beyond the 24th
// it is quick notes on one string, which is how sources write eighth-note power
// chords — and reading them greedily used to fill the page with reports of
// frets that no source ever meant.
#eq(
  events-of(block("--77----")).map(e => e.notes.first().fret),
  (7, 7),
  "'77' is two sevenths, not the 77th fret",
)
#eq(
  events-of(block("--333---")).map(e => e.notes.first().fret),
  (3, 3, 3),
  "and '333' is three thirds",
)
#eq(events-of(block("--80----")).map(e => e.notes.first().fret), (8, 0), "'80' is 8 then open")
#eq(
  events-of(block("--010---")).map(e => e.notes.first().fret),
  (0, 10),
  "a leading zero opens no number: '010' is the open string then the 10th",
)
#eq(
  events-of(block("-101010-")).map(e => e.notes.first().fret),
  (10, 10, 10),
  "'101010' is three tenths",
)
#eq(events-of(block("--7b910-")).map(e => e.notes.first().fret), (7, 10), "a bend target stops too")

// --- barlines -------------------------------------------------------------

#eq(part-of(block("--0--|--3--")).measures.len(), 2, "an interior barline splits the music")

// --- bars with nothing in them ---------------------------------------------
// An empty bar is not an empty statement: it says this part is silent here.
// Dropping it lost the whole block when every bar was empty, so an outro where
// the guitar has stopped and only the voice carries on vanished from the sheet.

#let silent = part-of(block("-----------|-----------"))
#eq(silent.measures.len(), 2, "a bar with nothing written in it is still a bar")
#eq(
  silent.measures.map(me => me.events.map(e => e.kind)),
  (("rest",), ("rest",)),
  "…and holds a rest, which is what a silent bar is",
)
#eq(
  silent.measures.first().events.first().duration,
  r.rat(1),
  "as long as the bar, so the meter still checks out",
)
#eq(m.validate(silent), (), "…and validation has nothing to say about it")

// The leading barline of a *second* block opens it rather than closing a bar:
// blocks concatenate, and every one of them starts with a barline of its own.
#eq(
  part-of(block("--0---2----") + "\n" + block("--12--10---")).measures.len(),
  2,
  "a following block's opening barline does not invent an empty measure",
)
// `||` is one barline drawn twice, not two with a bar of silence between them.
#eq(part-of(block("--0---2---|")).measures.len(), 1, "a double barline closes one measure")

// --- repeats ---------------------------------------------------------------
// `|:` and `:|` are music, not filler: a section played four times and one
// played once are not the same piece.

#let repeats-of(src) = {
  part-of(src).measures.map(me => (me.start-repeat, me.end-repeat, me.repeat-count))
}

#eq(
  repeats-of(block(":--0---5--:")),
  ((true, true, none),),
  "the colons around a block's own barlines open and close a repeat",
)
#eq(
  repeats-of(block("--0--|:--5---7--:|--3--")),
  ((false, false, none), (true, true, none), (false, false, none)),
  "an interior repeat marks the measure it encloses, not its neighbours",
)
#eq(
  repeats-of(block(":--0---5--:|x3")),
  ((true, true, 3),),
  "`x3` after the closing stroke is how many times to play it",
)
// `:|:` is where a repeated section runs straight into the next one, and is one
// barline carrying both marks.
#eq(
  repeats-of(block("--0--:|:--5--")),
  ((false, true, none), (true, false, none)),
  "`:|:` closes one repeat and opens the next",
)
// Collapsing adjacent strokes must not collapse what they say: in `||:` the
// repeat is written on the second stroke.
#eq(
  repeats-of(block("--0--||:--5--:||--3--")),
  ((false, false, none), (true, true, none), (false, false, none)),
  "a repeat written against a double barline survives",
)
// A repeat may open at the end of one block and be played out in the next.
#eq(
  repeats-of(block("--0---5--|:") + "\n" + block("--3---7--:|")),
  ((false, false, none), (true, true, none)),
  "a repeat carries across the join between two blocks",
)
// `x` is also a dead note, so a count is read only where no other reading is
// open: after the stroke that closes a repeat.
#eq(
  part-of(block("--0--|x3--5--")).measures.last().events.map(e => e.notes.first().fret),
  ("x", 3, 5),
  "`|x3` in the middle of a row is a muted string and then the third fret",
)

// --- inline techniques ----------------------------------------------------

#let tech(body) = events-of(block(body)).first().notes.first().techniques

#eq(tech("--5h7---").first(), m.technique("hammer", fret: 7), "h is a hammer-on")
#eq(tech("--7p5---").first(), m.technique("pull", fret: 5), "p is a pull-off")
#eq(tech("--5/7---").first().fret, 7, "a forward slash slides up")
#eq(tech("--7\\5---").first().fret, 5, "a backslash slides down")
#eq(tech("--7b9---").first().amount, r.rat(1), "a bend of two frets is a whole step")
#eq(tech("--7b8---").first().amount, r.rat(1, den: 2), "one fret is a half step")
#eq(tech("--7b9r--").first().release, true, "r after a bend is a release")
// `pb` and `pbr` are Ultimate Guitar's own spelling of a pre-bend. Read as a
// plain `p` the row was *misread*, not merely impoverished: the pull-off was
// held for the next note on the row and hung off it, inventing a slur the
// source never had, and the pre-bend came out as an ordinary bend.
#eq(tech("--7pb9--").first().pre, true, "pb is a pre-bend")
#eq(tech("--7pb9r-").first().release, true, "…and pbr releases it")
#eq(
  events-of(block("--7pb9--5---")).at(1).notes.first().techniques,
  (),
  "…and neither invents a pull-off on the note that follows",
)
#eq(tech("--7~----").first(), m.technique("vibrato", wide: false), "a tilde is vibrato")
#eq(tech("--12*---").first().style, "natural", "an asterisk is a natural harmonic")
// Power Tab and Guitar Pro export a natural harmonic in angle brackets, which
// is a dialect of ASCII tab rather than of any one site.
#eq(tech("--<12>--").first().style, "natural", "…and so are angle brackets")
#eq(
  events-of(block("--<12>--")).first().notes.first().fret,
  12,
  "the fret inside them is the note, not part of the bracket",
)
#eq(tech("--(7)---").first().kind, "ghost", "parentheses mark a ghost note")

// …unless the fret in them repeats the note before it on that string, which is
// how a held note is written: the string is still sounding and is not struck
// again. The two print alike — a ghost note and the far end of a tie are both
// parenthesised, the arc being what separates them — so only the model can tell
// them apart, and reading it wrong turns a note held over into a second strike.
#let held = m.mark-tie-targets(part-of(block("--5-----(5)--")))
#let held-events = held.measures.first().events
#eq(
  held-events.at(0).notes.first().techniques,
  (m.technique("tie"),),
  "a repeated fret in parentheses ties the note it repeats",
)
#ok(held-events.at(1).notes.first().tied-in, "…and the far end is the note not struck")
#eq(
  tech("--5-----(7)--").len(),
  0,
  "a different fret in parentheses leaves the note before it alone",
)
#eq(
  events-of(block("--5-----(7)--")).at(1).notes.first().techniques.first().kind,
  "ghost",
  "…and is the ghost note the brackets otherwise mean",
)
// The note before it, not merely an earlier one: a fret struck between the two
// has ended whatever the first was sounding.
#eq(
  events-of(block("--5--7--(5)--")).at(2).notes.first().techniques.first().kind,
  "ghost",
  "an intervening note makes the brackets a ghost note again",
)
// A tie across a barline is ordinary notation, and barlines do not interrupt
// the run of notes on a row.
#ok(
  m.has-technique(events-of(block("--5--|--(5)--")).at(0).notes.first(), "tie"),
  "a tie is read across a barline",
)
#eq(events-of(block("--x-----")).first().notes.first().fret, m.MUTED, "x is a dead string")

// Nothing sounds on a dead string, so nothing can be hammered, pulled or slid
// from it. A stray letter between one and the next note used to hang a link
// there — `0-x---pbr12` in a real transcription left a pull-off pointing from
// `x` to the 12th, and the renderer, asked whether the 12th is above a fret
// called "x", stopped the whole document.
#let from-dead = parse(block("--0-x---p12--"))
#eq(
  from-dead.part.measures.first().events.at(1).notes.first().techniques,
  (),
  "a linking mark is not hung off a dead string",
)
#ok(
  from-dead.warnings.any(w => w.contains("dead string")),
  "…and dropping it is reported rather than silent",
)

// Ultimate Guitar's own two-letter harmonic marks, written against the fret.
// They used to reach the page only through a `T:` row, which put the right word
// over the right column and left the model none the wiser.
#eq(tech("--7PH---").first().style, "pinch", "PH is a pinch harmonic")
#eq(tech("--7AH---").first().style, "artificial", "AH is an artificial harmonic")
#eq(tech("--12NH--").first().style, "natural", "NH is a natural harmonic")
#eq(tech("--9HH---").first().style, "harp", "HH is a harp harmonic")
#eq(tech("--7TH---").first().style, "tap", "TH is a tap harmonic")
// Capitals collide with nothing, since every technique letter read inside a row
// is lower case — but the mark must not swallow the note after it.
#eq(
  events-of(block("--7PH5--")).map(e => e.notes.first().fret),
  (7, 5),
  "a harmonic takes no target fret, so the digits after it are the next note",
)
#eq(
  write(part-of("R:  q   q\n" + block("--7PH--9TH--"))),
  "q 7/1PH 9/1TH |",
  "…and each writes back out as the mark the native syntax uses",
)

// A pick scrape is written the same way and read at the same point, but against
// an `x`: it has no pitch of its own, which is what both legends say by drawing
// an X on the string. A dead note never enters the fret scan, so the mark had to
// be read where the `x` itself is read or it could not be written at all.
#eq(tech("--xPS---").first().kind, "scrape", "PS against an x is a pick scrape")
#eq(events-of(block("--xPS---")).first().notes.first().fret, m.MUTED, "…on a dead note")
#eq(tech("--x-----"), (), "a plain dead note carries nothing")

// Unlike a harmonic, a scrape *does* read the digits against it: they are the
// fret the pick stops at, and that is where the gesture ends rather than a
// second attack. A slide's target is written the same way for the same reason.
#eq(tech("--xPS5--").first().fret, 5, "digits against the mark are the fret it runs to")
#eq(
  events-of(block("--xPS5--")).len(),
  1,
  "…so the target is part of the scrape, not an event with a value of its own",
)
#eq(tech("--xPS12-").first().fret, 12, "a two-digit target reads whole")
#eq(tech("--xPS---").first().at("fret", default: none), none, "and it may name none")
#eq(
  write(part-of("R:  h\n" + block("--xPS1--"))),
  "h x/1PS1 |",
  "…each writing back out as the native syntax spells it",
)
#eq(
  write(part-of("R:  q   q\n" + block("--xPS--5--"))),
  "q x/1PS 5/1 |",
  "a targetless scrape still leaves the note after it alone",
)

// --- noise around the music -----------------------------------------------
// Real tabs are full of headings and comments; they must be skipped, not
// mistaken for music.

#let noisy = parse("Verse riff — play twice\n" + block("--0-----"))
#eq(noisy.part.measures.len(), 1, "a prose line does not break the block")
#eq(noisy.part.measures.first().events.len(), 1, "and the music still reads")

// A densely noted row is still music. Counting only the filler put this one at
// 0.49 and dropped it as prose — two of them in Nirvana's *All Apologies*, which
// then left the block a string short. Fret numbers count towards the alphabet
// tab is written with, because they are part of it.
#let dense = parse(
  "D#|------------------------|\n"
    + "A#|------------------------|\n"
    + "F#|------------------------|\n"
    + "C#|------------------------|\n"
    + "G#|---9-10---10s12-12-10-9-|\n"
    + "D#|------------------------|",
  tuning: tunings.half-step-down,
)
#eq(dense.warnings, (), "a two-digit row with single dashes is read, not ignored")
// Six events, not seven: `10s12` is one note sliding to the 12th, and the
// target is a technique on it rather than a strike of its own.
#eq(dense.part.measures.first().events.len(), 6, "…and every note in it arrives")

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
// Power Tab and Guitar Pro write their duration rows in capitals. Reading them
// is what turns an exported tab from column-spaced into one with real rhythm.
#let shouted = parse("R:   Q   Q   E E\n" + block("--0---2---3-5---"))
#eq(
  shouted.part.measures.first().events.map(e => e.duration),
  (m.durations.q, m.durations.q, m.durations.e, m.durations.e),
  "an R row in capitals reads the same as one in lower case",
)
#eq(
  parse("R:   Q.  E\n" + block("--0-------2-----")).part.measures.first().events.at(0).duration,
  m.dotted(m.durations.q, 1),
  "…dots and all",
)

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

// The D row carries dynamics, attaching to the column each one sits over.
#let dyn = parse("D:   mf      ff\n" + block("--0---2---3-5---"))
#let devs = dyn.part.measures.first().events
#eq(devs.at(0).dynamic, "mf", "the D row marks a dynamic at its column")
#eq(devs.at(2).dynamic, "ff", "…and the next at its own")
#eq(devs.at(1).dynamic, none, "columns with no dynamic get none")
// A misspelling is reported rather than printed: the reader cannot tell a
// dynamic that means nothing from one they do not know.
#let bad-dyn = parse("D:   loud\n" + block("--0---2---3-5---"))
#ok(
  bad-dyn.warnings.any(w => w.contains("unknown dynamic")),
  "an unrecognised dynamic is reported, not set",
)
#eq(bad-dyn.part.measures.first().events.at(0).dynamic, none, "…and does not reach the model")

// A note value written where nothing is struck is a rest that long. ASCII tab
// spells silence as filler, so the annotation row is the only place a rest can
// be said at all — and saying it is what lets a bar that stops halfway through
// still add up to its meter.
#let rests = parse("R:  q   q   q   q\n" + block("--0---5-------------"))
#eq(
  rests.part.measures.first().events.map(e => (e.kind, e.duration)),
  (
    ("note", m.durations.q),
    ("note", m.durations.q),
    ("rest", m.durations.q),
    ("rest", m.durations.q),
  ),
  "values over columns with no note are rests of that length",
)
#eq(m.validate(rests.part), (), "…so the bar adds up to its meter")
// The reach is the three columns every other annotation row resolves by: a
// hand-aligned token that merely misses its note must set that note's value
// rather than invent a silence beside it.
#eq(
  events-of("R:  q q\n" + block("--0-5---------------")).map(e => e.kind),
  ("note", "note"),
  "a token within three columns of a note is that note's value, not a rest",
)
// Which is why the notes claim their tokens rather than each token asking
// whether a note is near. Where events stand two columns apart a value written
// over the gap is within reach of the notes on both sides, and asking by
// distance alone could not read such a row at all: this is a real transcription
// — Three Days Grace, *Animal I Have Become* — whose eight eighths over seven
// notes came out a beat short in every bar.
#eq(
  parse(
    "R:    e e e e e e e e\n"
      + "D|:-------------------|\n"
      + "A|:-------------------|\n"
      + "F|:-------------------|\n"
      + "C|:-------------------|\n"
      + "G|:---0-0-------7-----|\n"
      + "C|:---0-0---7-8---8-7-|",
  )
    .part
    .measures
    .first()
    .events
    .map(e => e.kind),
  ("note", "note", "rest", "note", "note", "note", "note", "note"),
  "a densely spaced row leaves over the token no note wanted, in its own place",
)
// A bar written empty is one whole rest, but a bar whose rests are named is
// divided as the row says — the whole-bar rest ahead of them would be a second
// bar's worth of silence.
#eq(
  parse("R:  q   q   q   q\n" + block("--------------------"))
    .part
    .measures
    .first()
    .events
    .map(e => (e.kind, e.duration)),
  (("rest", m.durations.q),) * 4,
  "an empty bar takes the rests the R row names instead of one whole rest",
)
#eq(
  part-of(block("--------------------")).measures.first().events.map(e => e.duration),
  (r.rat(1),),
  "…while one with nothing said about it is still a single bar-long rest",
)

// A tuplet is opened with a count and a colon, which stays column-aligned.
#let tuplets = parse("R:   3:  e   e   e\n" + block("--0---2---3-----"))
#let tevs = tuplets.part.measures.first().events
#eq(tevs.at(0).tuplet, (count: 3, of: 2), "'3:' opens a triplet")
#eq(tevs.at(2).tuplet, (count: 3, of: 2), "…covering three events")

// A block may carry several `R:` rows, read together column by column. That is
// what makes `3:` writable where the events stand close: the opener needs
// whitespace on both sides and rarely fits between two values.
#let split-rows = parse(
  "R:          3:\n" + "R:  q   q   q   q   q\n" + block("--3---3---5---3---2--"),
)
#eq(
  split-rows.part.measures.first().events.map(e => (e.duration, e.tuplet)),
  (
    (m.durations.q, none),
    (m.durations.q, none),
    (m.durations.q, (count: 3, of: 2)),
    (m.durations.q, (count: 3, of: 2)),
    (m.durations.q, (count: 3, of: 2)),
  ),
  "a tuplet opened from a second R row lands on its own column",
)
// Three quarters in the time of two is exactly what makes five of them a bar.
#eq(m.validate(split-rows.part), (), "…and the bar then adds up to its meter")

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

// A bare `30` is read as two notes rather than a fret that does not exist, so
// the report needs a source that means the 30th and says so: inside brackets the
// digits are delimited and no other reading is open.
#ok(
  parse(block("-(30)---")).warnings.any(w => "30" in w),
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

// The structure round-trips with the notes: what the colons said comes back out
// as the repeat signs the native syntax writes.
#eq(
  write(parse("R:   q   q\n" + block(":--0---2--:|x3")).part),
  "|: q 0/1 2/1 :|x3",
  "a repeat written in ASCII is written back as one",
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
  // The writer spells the arpeggio's direction out even when it is the
  // default, so what it emits reads back as exactly what it was given.
  "q 7/3tr9 7/3TP 7/3PS 7/3An 7/3Rn |",
  "the later technique additions round-trip too",
)
#eq(
  write(m.part(measures: parse-measures("{PM: q 0/6 0/6}"))),
  "{PM: q 0/6 0/6 } |",
  "spans round-trip as groups",
)
#eq(
  write(m.part(measures: parse-measures("q 10/3s | 3/3"))),
  "q 10/3s |\n3/3 |",
  "a link running to the next event round-trips as the bare mark",
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

// Where the target has a column of its own it is a second event with its own
// note value, and the link runs to it rather than printing its fret again beside
// the first. Attaching a target *and* keeping the note drew the fret twice — a
// phantom number beside the first note and the real one at its own column.
#for form in ("--5h-7---", "--5-h-7--", "--5---h---7--") {
  let evs = joined(form)
  eq(evs.len(), 2, "'" + form.trim("-") + "' is two events")
  eq(
    m.get-technique(evs.first().notes.first(), "hammer").fret,
    none,
    "…joined by a hammer-on running to the second, not to a fret of its own",
  )
  eq(evs.last().notes.first().fret, 7, "…and the second note survives")
}

#eq(
  m.get-technique(joined("--5/-7---").first().notes.first(), "slide").fret,
  none,
  "a slash reaches the next note too",
)
#eq(
  m.get-technique(joined("--7\\-5---").first().notes.first(), "slide").fret,
  none,
  "and a backslash downwards",
)
#eq(
  m.get-technique(joined("--5p-7---").first().notes.first(), "pull").fret,
  none,
  "so does a pull-off",
)
#eq(
  joined("--12h-14--").map(e => e.notes.first().fret),
  (12, 14),
  "multi-digit frets on both sides",
)
// A note value over the target's column says it is a note in its own right, and
// then the adjacent form means the same as the spaced one. Nothing else can say
// it: in ASCII every character has a column, so `3/7` spends one on its target
// exactly as `3-/-7` does. Without this the target had no rhythm of its own —
// it is not an event — and the value written over it, claimed by no note, came
// out as a rest that the source never had.
#let owned = parse("R:  q q q e\n" + block("--3-3/7-7-8-"))
#eq(
  owned.part.measures.first().events.map(e => (e.kind, e.notes.first().fret, e.duration)),
  (
    ("note", 3, m.durations.q),
    ("note", 3, m.durations.q),
    ("note", 7, m.durations.q),
    ("note", 7, m.durations.e),
    ("note", 8, m.durations.e),
  ),
  "a value over a link's target makes it an event of its own, and no rest is invented",
)
#eq(
  m.get-technique(owned.part.measures.first().events.at(1).notes.first(), "slide").fret,
  none,
  "…with the link running to it",
)
// Left alone, the same row is the compact pair the legend sets.
#eq(
  m.get-technique(joined("--3-3/7-7-8-").at(1).notes.first(), "slide").fret,
  7,
  "with nothing said about it the target is a second number inside the event",
)
// A bend names a pitch to reach, never a second strike, so a value over its
// digits changes nothing.
#eq(
  m.get-technique(
    parse("R:  q q\n" + block("--7b9-------")).part.measures.first().events.first().notes.first(),
    "bend",
  ).amount,
  r.rat(1),
  "a bend's target is a pitch, and stays one whatever the R row says",
)

// The target may be in the next bar, which is the one case that can only be
// said this way: a barline does not interrupt the run of notes on a row.
#let across = part-of(block("--10\\-|--3---"))
#eq(across.measures.len(), 2, "the barline still splits the music")
#eq(
  m.get-technique(across.measures.first().events.last().notes.first(), "slide").fret,
  none,
  "a slide reaches across a barline to the note it lands on",
)
#eq(
  across.measures.last().events.first().notes.first().fret,
  3,
  "…and that note keeps its own place, rather than being drawn twice",
)

#eq(
  m.get-technique(joined("--5s7----").first().notes.first(), "slide").fret,
  7,
  "'s' is a slide in ASCII tab, not a stray character splitting the note",
)
#ok(m.has-technique(joined("--t12----").first().notes.first(), "tap"), "'t' taps the note it precedes")

// A marker with nothing to point at is dropped rather than invented — unless it
// is a slide, which means something on its own: the note is slid off, in the
// direction the arrow points. A figure that trails away used to come out as a
// plain note, the mark dropped without a word.
#eq(joined("--5h-----").first().notes.first().techniques, (), "a dangling hammer-on attaches to nothing")
#eq(joined("--5h-----").len(), 1, "…and does not conjure an event")
#eq(tech("--15\\----").first().out, "down", "a trailing backslash slides out downwards")
#eq(tech("--15/----").first().out, "up", "…and a forward slash upwards")
#eq(tech("--15s----").first().out, "down", "a bare 's' names no direction, and falls")
#eq(joined("--15/----").len(), 1, "a slide out conjures no event either")
// With a note still to come it is an ordinary link, not a slide out.
#eq(
  m.get-technique(joined("--15/--13-").first().notes.first(), "slide").at("out", default: none),
  none,
  "a mark that does reach a note is a link, whatever direction it points",
)
#eq(
  write(part-of("R:  q\n" + block("--15\\----"))),
  "q 15/1sN |",
  "a slide out round-trips through the DSL",
)

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
// `hb` and `fb` are common in pasted tabs: half bend and full bend. The reading
// has to stay unambiguous against `h` for hammer-on, which it is: a hammer-on
// always writes its target as digits, so an `h` pressed directly against a `b`
// can only be a size.

#let row-src(row) = {
  let pad = "-------------"
  "e|" + pad + "|\nB|" + pad + "|\nG|" + row + "|\nD|" + pad + "|\nA|" + pad + "|\nE|" + pad + "|"
}
#let events(row) = parse(row-src(row)).part.measures.first().events
#let bends(row) = events(row).first().notes.first().techniques

#eq(bends("--3hb--------").first().amount, r.rat(1, den: 2), "`hb` is a half bend")
#eq(bends("--3fb--------").first().amount, r.rat(1), "`fb` is a full bend")
#eq(bends("--3fbr-------").first().release, true, "`fbr` is a full bend and release")
#eq(bends("--3fbr-------").first().amount, r.rat(1), "…still a whole step")
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

// A spelled size already says how far the bend goes, so digits after it are the
// next note. `7fb5` is a full bend and then the 5th fret — reading the 5 as a
// target swallowed the note and refused the bend for not rising.
#eq(bends("--7fb5-------").first().amount, r.rat(1), "digits after `fb` leave the size alone")
#eq(events("--7fb5-------").len(), 2, "…and the fret after it is a note of its own")
#eq(events("--7fb5-------").last().notes.first().fret, 5, "…at the fret written")
#eq(
  parse(row-src("--7fb5-------")).warnings.len(),
  0,
  "…with nothing to report, since no bend was asked to fall",
)

// A bend later in a chain measures from where the chain has arrived, not from
// the struck fret: `5h7b9` bends the hammered 7 up to 9, one step, not two.
#let chain = bends("--5h7b9------")
#eq(chain.first().kind, "hammer", "`5h7b9` still hammers first")
#eq(chain.last().amount, r.rat(1), "…and bends a whole step from the hammered fret")

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
