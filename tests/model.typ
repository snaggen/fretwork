#import "helpers.typ": ok, eq, report
#import "/src/rational.typ" as r
#import "/src/model.typ" as m
#import "/src/tuning.typ": tunings, tuning, to-pitch, pitch-name, string-count, midi-of

// --- rational -------------------------------------------------------------

#eq(r.rat(2, den: 8), r.rat(1, den: 4), "rationals normalise to lowest terms")
#eq(r.rat(-1, den: -2), r.rat(1, den: 2), "double negative normalises")
#eq(r.rat(0, den: 5), r.rat(0), "zero normalises")
#eq(r.add(r.rat(1, den: 4), r.rat(1, den: 4)), r.rat(1, den: 2), "1/4 + 1/4")
#eq(r.sub(r.rat(1), r.rat(1, den: 3)), r.rat(2, den: 3), "1 - 1/3")
#eq(r.mul(r.rat(2, den: 3), r.rat(3, den: 4)), r.rat(1, den: 2), "2/3 * 3/4")
#eq(r.div(r.rat(1, den: 2), r.rat(1, den: 4)), r.rat(2), "half divided by quarter")
#eq(r.sum((r.rat(1, den: 8),) * 8), r.rat(1), "eight eighths make a whole")
#ok(r.lt(r.rat(1, den: 3), r.rat(1, den: 2)), "1/3 < 1/2")
#ok(not r.lt(r.rat(1, den: 2), r.rat(1, den: 2)), "1/2 is not less than itself")
#eq(r.str-of(r.rat(3, den: 8)), "3/8", "rational prints as a fraction")

// Thirds are the reason durations are exact rather than floating point.
#eq(r.sum((r.rat(1, den: 12),) * 3), r.rat(1, den: 4), "three triplet eighths make a quarter")

// --- durations ------------------------------------------------------------

#eq(m.dotted(m.durations.q, 1), r.rat(3, den: 8), "dotted quarter is 3/8")
#eq(m.dotted(m.durations.q, 2), r.rat(7, den: 16), "doubly dotted quarter is 7/16")
#eq(m.dotted(m.durations.e, 0), m.durations.e, "no dots changes nothing")
#eq(m.decompose(r.rat(3, den: 8)), (base: m.durations.q, dots: 1), "3/8 decomposes to a dotted quarter")
#eq(m.decompose(m.durations.s), (base: m.durations.s, dots: 0), "a plain sixteenth decomposes to itself")
#eq(m.duration-token(m.durations.t), "t", "32nd note round-trips to its token")
#eq(m.duration-token(r.rat(1, den: 5)), none, "an unwritable value has no token")

// --- tuning ---------------------------------------------------------------

#eq(midi-of("C4"), 60, "middle C is MIDI 60")
#eq(midi-of("E2"), 40, "low E is MIDI 40")
#eq(midi-of("F#3"), 54, "sharps raise by a semitone")
#eq(midi-of("Bb1"), 34, "flats lower by a semitone")
#eq(pitch-name(64), "E4", "MIDI 64 names the high E")

#eq(string-count(tunings.standard), 6, "standard tuning has six strings")
#eq(to-pitch(tunings.standard, 6, 0), 40, "open sixth string is low E")
#eq(to-pitch(tunings.standard, 1, 0), 64, "open first string is high e")
#eq(to-pitch(tunings.standard, 5, 2), 47, "fifth string, second fret is B2")
#eq(to-pitch(tunings.drop-d, 6, 0), 38, "drop D lowers the sixth string a whole step")
#eq(to-pitch(tunings.standard, 6, 0, capo: 2), 42, "a capo transposes upwards")
#eq(tunings.standard.labels, ("e", "B", "G", "D", "A", "E"), "ASCII labels are ordered high to low")
#eq(string-count(tunings.seven-string), 7, "seven-string tuning has seven strings")

// The same pitch reached two ways must agree; this is what a future notation
// staff relies on.
#eq(
  to-pitch(tunings.standard, 6, 5),
  to-pitch(tunings.standard, 5, 0),
  "sixth string fret 5 equals the open fifth string",
)

// --- notes and events -----------------------------------------------------

#let n = m.note(3, 7, techniques: (m.technique("bend", amount: r.rat(1)),))
#ok(m.has-technique(n, "bend"), "technique is found by kind")
#ok(not m.has-technique(n, "vibrato"), "an absent technique is not found")
#eq(m.get-technique(n, "bend").amount, r.rat(1), "technique arguments survive")
#eq(m.get-technique(n, "slide"), none, "an absent technique reads as none")
#eq(m.note(5, m.MUTED).fret, m.MUTED, "a muted string is a legal fret value")

#let ev = m.event(notes: (m.note(6, 0),), duration: m.durations.e)
#eq(m.sounding-duration(ev), m.durations.e, "outside a tuplet, sounding equals written")
#eq(
  m.sounding-duration(m.event(notes: (m.note(6, 0),), duration: m.durations.e, tuplet: (count: 3, of: 2))),
  r.rat(1, den: 12),
  "inside a triplet, a written eighth sounds for a twelfth",
)
#eq(m.sounding-duration(m.event()), none, "an event without a duration has no sounding length")
#eq(m.event(rest: true).kind, "rest", "a rest is its own event kind")

// --- measures and validation ----------------------------------------------

#let full = m.measure(events: (
  m.event(notes: (m.note(5, 2), m.note(4, 2)), duration: m.durations.q),
  m.event(rest: true, duration: m.durations.q),
  m.event(notes: (m.note(6, 0),), duration: m.durations.h),
))
#eq(m.measure-duration(full), r.rat(1), "a full 4/4 bar sums to one whole note")
#eq(
  m.measure-duration(m.measure(events: (m.event(notes: (m.note(6, 0),)),))),
  none,
  "a bar with an undated event has no known length",
)

#eq(m.validate(m.part(measures: (full,))), (), "a correct part reports no problems")

#let short = m.part(measures: (m.measure(events: (m.event(notes: (m.note(6, 0),), duration: m.durations.h),)),))
#eq(m.validate(short).len(), 1, "a short bar is reported")
#ok("1/2" in m.validate(short).first(), "the report names the actual length")

#eq(
  m.validate(m.part(measures: short.measures, anacrusis: true)),
  (),
  "a pick-up bar is exempt from the length check",
)

#let unknown = m.part(measures: (m.measure(events: (m.event(notes: (m.note(6, 0),)),)),))
#eq(m.validate(unknown), (), "an unfilled duration is not an error, only unchecked")

#let offstring = m.part(measures: (m.measure(events: (
  m.event(notes: (m.note(9, 0),), duration: m.durations.w),
)),))
#eq(m.validate(offstring).len(), 1, "a note on a nonexistent string is reported")

#eq(m.time-at(m.part(measures: (full, full)), 1), r.rat(1), "the time signature carries forward")
#eq(
  m.time-at(m.part(measures: (full, m.measure(time: (3, 4))), time: (4, 4)), 1),
  r.rat(3, den: 4),
  "a mid-piece time change takes effect",
)

#report("model")
