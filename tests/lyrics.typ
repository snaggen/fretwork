#import "helpers.typ": ok, eq, report
#import "/src/rational.typ" as r
#import "/src/model.typ" as m
#import "/src/theme.typ": theme
#import "/src/parse/dsl.typ": parse
#import "/src/parse/ascii.typ"
#import "/src/parse/lyrics.typ": apply, has-lyrics, read-syllable, read-verse, takes-syllable
#import "/src/render/lyrics.typ" as lane

#let thm = theme(staff-space: 3mm)

// --- the syllable syntax ---------------------------------------------------

#eq(read-syllable("What"), m.syllable("What"), "a plain word is a syllable")
#eq(read-syllable("Twist-"), m.syllable("Twist", hyphen: true), "a trailing dash hyphenates")
// A word held over several notes is written once and the rest of its notes are
// spent, so `_` is a held note rather than an empty word: it prints the same
// nothing an unsung note does, but only it can carry an extender rule.
#eq(read-syllable("_"), m.hold, "an underscore holds the word before it")
#eq(read-syllable("-"), m.syllable("-"), "a lone dash is a word, not an empty hyphenation")

#eq(read-verse("one two").len(), 2, "a verse splits on whitespace")
#eq(read-verse("  one   two  ").len(), 2, "…and ignores the space around it")
#eq(read-verse("").len(), 0, "an empty verse is empty")

// --- which events are sung -------------------------------------------------

#let sung(src) = parse(src).measures.first().events.map(takes-syllable)

#eq(sung("q 0/6 r 2/6"), (true, false, true), "a rest is not sung")
#eq(sung("q g 5/6 q 7/6"), (false, true), "nor is a grace note")
// The far end of a tie is not a new attack: it keeps the syllable of the note it
// is held from. `mark-tie-targets` is what says which note that is.
#eq(
  m.mark-tie-targets(parse("q 5/6~ 5/6 3/6 0/6")).measures.first().events.map(takes-syllable),
  (true, false, true, true),
  "a note a tie runs into is not sung again",
)

// --- spending verses over the music ----------------------------------------

#let spent(src, verses) = apply(m.mark-tie-targets(parse(src)), verses)

#let one = spent("q 0/6 2/6 r 3/6", "What else now")
#eq(
  one.part.measures.first().events.map(ev => ev.lyrics.at(0, default: none)),
  (m.syllable("What"), m.syllable("else"), none, m.syllable("now")),
  "syllables are spent in order, and the rest is passed over rather than spent on",
)
#eq(one.warnings, (), "a verse that fits reports nothing")

// `_` spends a note without printing on it, which is how a word held over
// several notes is written.
#eq(
  spent("q 0/6 2/6 3/6", "held _ again")
    .part
    .measures
    .first()
    .events
    .map(ev => ev.lyrics.at(0, default: none)),
  (m.syllable("held"), m.hold, m.syllable("again")),
  "an underscore spends a note as a hold and prints nothing on it",
)

// Miscounting a verse against the music is the mistake this syntax makes
// easiest, so it is reported rather than swallowed.
#eq(spent("q 0/6 2/6 3/6", "one two three four").warnings.len(), 1, "leftover syllables are reported")

#let two = spent("q 0/6 2/6", ("one two", "ett tva"))
#eq(
  two.part.measures.first().events.first().lyrics.map(s => s.text),
  ("one", "ett"),
  "two verses put two syllables on the same event",
)
#eq(lane.verse-count(two.part), 2, "…and the part reports both")
#eq(lane.verse-count(parse("q 0/6 2/6")), 0, "music with no lyrics has no verses")

#ok(has-lyrics(two.part), "a part carrying syllables says so")
#ok(not has-lyrics(parse("q 0/6")), "…and one that carries none does not")

// --- the ASCII `L:` row ----------------------------------------------------
// Column-aligned, like chord names: the transcriber has already said where each
// syllable goes by writing it under the note, so no spending rule is involved.

// One tab block whose top string carries `row`, laid out so that an annotation
// row written directly above it lines up column for column.
#let block(row) = {
  let filler = "-" * row.len()
  ("e", "B", "G", "D", "A", "E")
    .enumerate()
    .map(((i, label)) => label + "|" + (if i == 0 { row } else { filler }) + "|")
    .join("\n")
}

#let syllables-of(part, verse) = (
  part.measures.first().events.map(ev => ev.lyrics.at(verse, default: none))
)

#let imported = ascii.parse("L:   What else nev-\n" + block("--0---2---3-----"))
#eq(
  syllables-of(imported.part, 0),
  (m.syllable("What"), m.syllable("else"), m.syllable("nev", hyphen: true)),
  "an L: row attaches a syllable to the column it sits over, dash and all",
)
#eq(imported.warnings, (), "…with nothing to report")

#let verses = ascii.parse("L:   one\nL:   ett\n" + block("--0---2---------"))
#eq(syllables-of(verses.part, 1).first(), m.syllable("ett"), "a second L: row is a second verse")
#eq(syllables-of(verses.part, 0).at(1), none, "…and a column with nothing sung stays empty")

// A syllable with no note near it still belongs on the page: a singer carries
// on where the guitar stops, and a bar the transcription leaves empty is
// exactly where that happens. It gets a column of its own rather than being
// dropped — in Nirvana's *All Apologies* eight of them were lost from one
// silent bar of the outro.
#let stranded = ascii.parse("L:   one two three four\n" + block("--0-----------------------"))
#eq(stranded.warnings, (), "syllables with no note under them are placed, not reported")
#let sung-events = stranded.part.measures.first().events
#eq(
  sung-events.map(ev => ev.lyrics.at(0, default: none)).filter(x => x != none).map(x => x.text),
  ("one", "two", "three", "four"),
  "…every one of them, in order",
)
// Nothing sounds where only a word is written, so the event is a rest with no
// duration: it draws no glyph and claims no rhythm the source never gave.
#eq(sung-events.at(1).kind, "rest", "a column carrying only a syllable is a rest")
#eq(sung-events.at(1).duration, none, "…with no duration")

// A bar with nothing but words in it is still a bar of silence, and says so.
#let voice-only = ascii.parse("L:   one two three\n" + block("----------------"))
#eq(voice-only.warnings, (), "a bar carrying only lyrics reports nothing")
#let bar = voice-only.part.measures.first().events
#eq(bar.first().duration, r.rat(1), "its first event is the bar's own rest")
#eq(
  bar.map(ev => ev.lyrics.at(0, default: none)).filter(x => x != none).len(),
  3,
  "…followed by the words, each on its own column",
)

#report("lyrics")
