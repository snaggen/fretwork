#import "helpers.typ": ok, eq, report
#import "/src/rational.typ" as r
#import "/src/model.typ" as m
#import "/src/tuning.typ": tunings
#import "/src/parse/dsl.typ": parse, parse-measures, tokenize

#let notes-of(measure, i) = measure.events.at(i).notes
#let first(src) = parse-measures(src).first()

// --- durations are sticky -------------------------------------------------

#let bar = first("q 0/6 2/6 e 3/6 3/6 h 0/6")
#eq(bar.events.len(), 5, "five events parsed")
#eq(bar.events.at(0).duration, m.durations.q, "the first note takes the stated value")
#eq(bar.events.at(1).duration, m.durations.q, "the value sticks until changed")
#eq(bar.events.at(2).duration, m.durations.e, "a new value takes over")
#eq(bar.events.at(4).duration, m.durations.h, "and again")
#eq(first("e. 0/6").events.at(0).duration, r.rat(3, den: 16), "a dot lengthens by half")
#eq(first("q.. 0/6").events.at(0).duration, r.rat(7, den: 16), "two dots compound")
#eq(first("0/6").events.at(0).duration, none, "with no value stated the duration is unknown")

// --- notes, chords, rests, mutes ------------------------------------------

#eq(notes-of(first("q 2/5"), 0), (m.note(5, 2),), "fret 2 on string 5")
#eq(notes-of(first("q (2/5 2/4 0/6)"), 0), (m.note(5, 2), m.note(4, 2), m.note(6, 0)), "a chord")
#eq(first("q r").events.at(0).kind, "rest", "a rest")
#eq(notes-of(first("q x/5"), 0), (m.note(5, m.MUTED),), "one muted string")
#eq(notes-of(first("q x"), 0).len(), 6, "a bare x mutes every string")
#eq(notes-of(first("q x"), 0).at(0).fret, m.MUTED, "…and each is muted")

// --- unambiguity ----------------------------------------------------------
// These are the cases the grammar was audited against. A fret number is a
// maximal run of digits, so a two-digit fret can never be read as two notes.

#eq(notes-of(first("q 11/3"), 0), (m.note(3, 11),), "11/3 is fret eleven, not fret one twice")
#eq(first("q 11/3").events.len(), 1, "…and it is a single event")
#eq(first("q 1/3 1/3").events.len(), 2, "two separate first frets need whitespace")
#eq(notes-of(first("q (11/3 12/2)"), 0), (m.note(3, 11), m.note(2, 12)), "two-digit frets inside a chord")
#eq(notes-of(first("q 24/1"), 0), (m.note(1, 24),), "the highest fret parses")

// A letter standing alone is a note value; the same letter inside a token is a
// technique. Tokens contain no whitespace, so the two can never collide.
#eq(first("s 0/6").events.at(0).duration, m.durations.s, "'s' alone is a sixteenth")
#eq(
  m.get-technique(notes-of(first("q 5/3s7"), 0).at(0), "slide").fret,
  7,
  "'s' inside a token is a slide",
)
#eq(first("h 0/6").events.at(0).duration, m.durations.h, "'h' alone is a half note")
#eq(
  m.get-technique(notes-of(first("q 5/3h7"), 0).at(0), "hammer").fret,
  7,
  "'h' inside a token is a hammer-on",
)
#eq(first("t 0/6").events.at(0).duration, m.durations.t, "'t' alone is a 32nd")
#ok(m.has-technique(notes-of(first("q 5/3T"), 0).at(0), "tap"), "'T' inside a token is tapping")

// A paren at the start of a token is a chord; a paren inside one is a bend
// amount. Ghost notes use the `g` suffix precisely so this stays true.
#eq(notes-of(first("q (2/5 2/4)"), 0).len(), 2, "a leading paren opens a chord")
#eq(
  m.get-technique(notes-of(first("q 7/3b(1/2)"), 0).at(0), "bend").amount,
  r.rat(1, den: 2),
  "a paren inside a token is a bend amount",
)
#ok(m.has-technique(notes-of(first("q 7/3g"), 0).at(0), "ghost"), "'g' marks a ghost note")

// --- techniques -----------------------------------------------------------

#let tech(src) = notes-of(first("q " + src), 0).at(0).techniques

#eq(tech("7/3p5").at(0), m.technique("pull", fret: 5), "pull-off")
#eq(tech("5/3S7").at(0), m.technique("slide", fret: 7, legato: false), "shift slide")
#eq(tech("5/3s7").at(0).legato, true, "legato slide")
#eq(tech("7/3b").at(0), m.technique("bend", amount: r.rat(1), release: false, pre: false), "a plain bend is a whole step")
#eq(tech("7/3b(full)").at(0).amount, r.rat(1), "'full' is spelled out")
#eq(tech("7/3br").at(0).release, true, "bend and release")
#eq(tech("7/3B").at(0).pre, true, "pre-bend")
#eq(tech("7/3Br").at(0), m.technique("bend", amount: r.rat(1), release: true, pre: true), "pre-bend and release")
#eq(tech("7/3v").at(0).wide, false, "vibrato")
#eq(tech("7/3V").at(0).wide, true, "wide vibrato")
#eq(tech("12/3*").at(0).style, "natural", "natural harmonic")
#eq(tech("5/3PH").at(0).style, "pinch", "pinch harmonic — not read as a pull-off")
#eq(tech("7/3HH").at(0).style, "harp", "harp harmonic — not read as a hammer-on")
#eq(tech("7/3~").at(0).kind, "tie", "tie")
#eq(tech("7/3>").at(0).kind, "accent", "accent")
#eq(tech("7/3^").at(0).kind, "marcato", "marcato")
#eq(tech("7/3!").at(0).kind, "staccato", "staccato")
#eq(tech("7/3-").at(0).kind, "tenuto", "tenuto")
#eq(tech("7/3n").at(0).dir, "down", "downstroke")
#eq(tech("7/3u").at(0).dir, "up", "upstroke")

// Suffixes chain, and the longest match wins at each step.
#eq(tech("5/3h7v").len(), 2, "a hammer-on can be followed by vibrato")
#eq(tech("5/3h7v").at(0).kind, "hammer", "…in the order written")
#eq(tech("5/3h7v").at(1).kind, "vibrato", "…with the second read correctly")

// A suffix after a closing paren binds to the whole chord.
#let tied-chord = notes-of(first("q (2/5 2/4 0/6)~"), 0)
#ok(tied-chord.all(n => m.has-technique(n, "tie")), "a chord suffix reaches every note")

// --- groups ---------------------------------------------------------------

#let pm = first("{PM: e 0/6 0/6} 0/6")
#eq(pm.events.at(0).spans, ("PM",), "a span marks the events inside it")
#eq(pm.events.at(2).spans, (), "and stops at the closing brace")

#let trip = first("{3: e 0/6 2/6 3/6}")
#eq(trip.events.at(0).tuplet, (count: 3, of: 2), "three in the time of two")
#eq(m.measure-duration(trip), r.rat(1, den: 4), "a triplet of eighths lasts a quarter")
#eq(first("{5: s 0/6}").events.at(0).tuplet, (count: 5, of: 4), "five in the time of four")
#eq(first("{2: e 0/6}").events.at(0).tuplet, (count: 2, of: 3), "a duplet replaces three")
#eq(first("{7/4: s 0/6}").events.at(0).tuplet, (count: 7, of: 4), "an explicit ratio is honoured")

#let nested = first("{PM: {3: e 0/6 0/6 0/6}}")
#eq(nested.events.at(0).spans, ("PM",), "groups nest — the span survives")
#eq(nested.events.at(0).tuplet, (count: 3, of: 2), "…and so does the tuplet")

#eq(first("{LR: q 0/6} {PM: 0/6}").events.at(1).spans, ("PM",), "consecutive groups do not leak")

// --- chord names and playing instructions ---------------------------------

#eq(first("@E5 q 0/6 0/6").events.at(0).chord, "E5", "a chord name attaches to the next event")
#eq(first("@E5 q 0/6 0/6").events.at(1).chord, none, "…and only to that one")
#eq(first("@\"C#m7\" q 0/6").events.at(0).chord, "C#m7", "a quoted chord name may hold anything")
#eq(first("\"Harm.\" q 12/3*").events.at(0).text, "Harm.", "a quoted string is a playing instruction")

// --- barlines and repeats -------------------------------------------------

#let ms = parse-measures("q 0/6 0/6 0/6 0/6 | q 2/6 2/6 2/6 2/6")
#eq(ms.len(), 2, "a barline splits measures")
#eq(ms.at(0).end, "single", "a plain barline")
#eq(parse-measures("q 0/6 ||").first().end, "double", "a double barline")
#eq(parse-measures("q 0/6 |.").first().end, "final", "a final barline")

#let rep = parse-measures("|: q 0/6 | q 2/6 :|")
#eq(rep.len(), 2, "a leading repeat sign makes no empty measure")
#eq(rep.at(0).start-repeat, true, "the repeat opens on the first measure")
#eq(rep.at(1).end-repeat, true, "and closes on the last")
#eq(parse-measures("|: q 0/6 :|x3").first().repeat-count, 3, "a repeat count is read")

#let both = parse-measures("|: q 0/6 :||: q 2/6 :|")
#eq(both.len(), 2, "a back-to-back repeat makes two measures, not three")
#eq(both.at(1).start-repeat, true, "the second repeat opens correctly")

#let volta = parse-measures("{V1: q 0/6 |} {V2: q 2/6 |}")
#eq(volta.at(0).volta, (1,), "first ending")
#eq(volta.at(1).volta, (2,), "second ending")

// --- whole parts ----------------------------------------------------------

#let p = parse("q (2/5 2/4 0/6) q x e 0/3 3/6 0/6 0/6 | h 0/6 0/6", tempo: 127)
#eq(p.measures.len(), 2, "a part holds its measures")
#eq(p.tempo, 127, "…and its tempo")
#eq(p.tuning.name, "Standard", "…and its tuning")
#eq(m.validate(p), (), "the parsed bars are the right length")

// Comments and free line breaks are ignored.
#eq(
  parse-measures("q 0/6 // the open low E\n  2/6").first().events.len(),
  2,
  "a line comment is skipped",
)

#report("dsl")
