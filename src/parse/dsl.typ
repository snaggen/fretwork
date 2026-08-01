// The native tablature DSL: tokenizer and parser.
//
// A source string holds one or more measures separated by barlines. Note values
// are sticky, so only changes need writing. The grammar is designed so that no
// expression can be read two ways; see `SPEC.md` for the full rules, of which
// the three load-bearing ones are:
//
//   1. Whitespace separates events and nothing else, so a fret number is always
//      a maximal run of digits: `11/3` can only be fret eleven.
//   2. A character means one thing standing alone (a note value or a rest) and
//      another inside a token (a technique). The two never meet because a token
//      contains no whitespace.
//   3. Suffixes are matched longest-first from a fixed table, and the ones
//      taking a fret argument require digits immediately after.

#import "../rational.typ" as r
#import "../model.typ" as m
#import "../tuning.typ": string-count, tunings
#import "errors.typ"

#let _DIGITS = ("0", "1", "2", "3", "4", "5", "6", "7", "8", "9")
#let _SPACE = (" ", "\t", "\n", "\r")
#let _DURATION-LETTERS = ("w", "h", "q", "e", "s", "t")

// Characters that end a token without being part of it.
#let _STRUCTURAL = ("(", ")", "{", "}", "|", ":", "@")

// Technique suffixes, longest first. Matching in this order is what keeps `br`
// from being read as `b` followed by a stray `r`, and `PH` from being read as
// the pull-off `p`.
#let _SUFFIXES = (
  ("PH", "harmonic-pinch"),
  ("HH", "harmonic-harp"),
  ("br", "bend-release"),
  ("Br", "prebend-release"),
  ("h", "hammer"),
  ("p", "pull"),
  ("s", "slide-legato"),
  ("S", "slide-shift"),
  ("b", "bend"),
  ("B", "prebend"),
  ("v", "vibrato"),
  ("V", "vibrato-wide"),
  ("*", "harmonic-natural"),
  ("~", "tie"),
  ("g", "ghost"),
  (">", "accent"),
  ("^", "marcato"),
  ("!", "staccato"),
  ("-", "tenuto"),
  ("T", "tap"),
  ("n", "stroke-down"),
  ("u", "stroke-up"),
)

// Suffixes that must be followed by a fret number.
#let _NEEDS-FRET = ("hammer", "pull", "slide-legato", "slide-shift")

// ---------------------------------------------------------------------------
// Low-level scanning
// ---------------------------------------------------------------------------

#let _is-sep(chars, i) = {
  i >= chars.len() or chars.at(i) in _SPACE or chars.at(i) in _STRUCTURAL
}

/// The run of non-separator characters starting at `i`, for error messages.
#let _word-at(chars, i) = {
  let j = i
  while j < chars.len() and not (chars.at(j) in _SPACE) { j += 1 }
  chars.slice(i, j).join()
}

#let _scan-int(chars, i) = {
  let start = i
  while i < chars.len() and chars.at(i) in _DIGITS { i += 1 }
  (v: if i > start { int(chars.slice(start, i).join()) } else { none }, i: i)
}

/// Parse a bend size written `(1/2)`, `(1)` or `(full)`, in whole steps.
#let _scan-bend-amount(chars, i, loc, source) = {
  if i >= chars.len() or chars.at(i) != "(" { return (v: r.rat(1), i: i) }
  let close = i + 1
  while close < chars.len() and chars.at(close) != ")" { close += 1 }
  if close >= chars.len() {
    errors.fail("tab", loc, "unclosed bend amount", source: source)
  }
  let body = chars.slice(i + 1, close).join().trim()
  let value = if body == "full" {
    r.rat(1)
  } else if "/" in body {
    let parts = body.split("/")
    if parts.len() != 2 {
      errors.fail("tab", loc, "malformed bend amount '" + body + "'", source: source)
    }
    r.rat(int(parts.at(0)), den: int(parts.at(1)))
  } else {
    r.rat(int(body))
  }
  (v: value, i: close + 1)
}

/// Build a technique record from a matched suffix kind and its argument.
#let _make-technique(kind, arg) = {
  if kind == "hammer" { m.technique("hammer", fret: arg) } else if kind == "pull" {
    m.technique("pull", fret: arg)
  } else if kind == "slide-legato" {
    m.technique("slide", fret: arg, legato: true)
  } else if kind == "slide-shift" {
    m.technique("slide", fret: arg, legato: false)
  } else if kind == "bend" {
    m.technique("bend", amount: arg, release: false, pre: false)
  } else if kind == "bend-release" {
    m.technique("bend", amount: arg, release: true, pre: false)
  } else if kind == "prebend" {
    m.technique("bend", amount: arg, release: false, pre: true)
  } else if kind == "prebend-release" {
    m.technique("bend", amount: arg, release: true, pre: true)
  } else if kind == "vibrato" {
    m.technique("vibrato", wide: false)
  } else if kind == "vibrato-wide" {
    m.technique("vibrato", wide: true)
  } else if kind == "harmonic-natural" {
    m.technique("harmonic", style: "natural")
  } else if kind == "harmonic-pinch" {
    m.technique("harmonic", style: "pinch")
  } else if kind == "harmonic-harp" {
    m.technique("harmonic", style: "harp")
  } else if kind == "stroke-down" {
    m.technique("stroke", dir: "down")
  } else if kind == "stroke-up" {
    m.technique("stroke", dir: "up")
  } else {
    m.technique(kind)
  }
}

/// Read a chain of technique suffixes.
#let _scan-suffixes(chars, i, loc, source) = {
  let techs = ()
  while not _is-sep(chars, i) {
    let matched = none
    for (token, kind) in _SUFFIXES {
      let n = token.clusters().len()
      if i + n <= chars.len() and chars.slice(i, i + n).join() == token {
        matched = (token: token, kind: kind, n: n)
        break
      }
    }
    if matched == none {
      errors.fail(
        "tab",
        loc,
        "unknown technique '" + chars.at(i) + "' in '" + _word-at(chars, loc.col) + "'",
        source: source,
      )
    }
    i += matched.n
    let arg = none
    if matched.kind in _NEEDS-FRET {
      let scanned = _scan-int(chars, i)
      if scanned.v == none {
        errors.fail(
          "tab",
          loc,
          "'" + matched.token + "' must be followed by a target fret",
          source: source,
        )
      }
      arg = scanned.v
      i = scanned.i
    } else if matched.kind in ("bend", "bend-release", "prebend", "prebend-release") {
      let scanned = _scan-bend-amount(chars, i, loc, source)
      arg = scanned.v
      i = scanned.i
    }
    techs.push(_make-technique(matched.kind, arg))
  }
  (v: techs, i: i)
}

/// Read one `fret/string` note with its suffixes.
#let _scan-note(chars, i, loc, source) = {
  let fret = none
  if chars.at(i) == "x" {
    fret = m.MUTED
    i += 1
  } else {
    let scanned = _scan-int(chars, i)
    fret = scanned.v
    i = scanned.i
  }
  if i >= chars.len() or chars.at(i) != "/" {
    errors.fail(
      "tab",
      loc,
      "expected '/' between fret and string in '" + _word-at(chars, loc.col) + "'",
      source: source,
    )
  }
  i += 1
  let scanned = _scan-int(chars, i)
  if scanned.v == none {
    errors.fail("tab", loc, "missing string number after '/'", source: source)
  }
  let string = scanned.v
  i = scanned.i
  let suffixes = _scan-suffixes(chars, i, loc, source)
  (v: m.note(string, fret, techniques: suffixes.v), i: suffixes.i)
}

/// Read a chord `( … )` and any suffixes that follow it.
///
/// A suffix after the closing paren binds to every note in the chord, which is
/// what makes `(2/5 2/4 0/6)~` tie the whole chord.
#let _scan-chord(chars, i, loc, source) = {
  i += 1 // consume '('
  let notes = ()
  while true {
    while i < chars.len() and chars.at(i) in _SPACE { i += 1 }
    if i >= chars.len() {
      errors.fail("tab", loc, "unclosed chord", source: source)
    }
    if chars.at(i) == ")" {
      i += 1
      break
    }
    let scanned = _scan-note(chars, i, loc, source)
    notes.push(scanned.v)
    i = scanned.i
  }
  if notes.len() == 0 {
    errors.fail("tab", loc, "empty chord", source: source)
  }
  let shared = _scan-suffixes(chars, i, loc, source)
  if shared.v.len() > 0 {
    notes = notes.map(n => m.note(n.string, n.fret, techniques: n.techniques + shared.v))
  }
  (v: notes, i: shared.i)
}

// ---------------------------------------------------------------------------
// Tokenizer
// ---------------------------------------------------------------------------

/// Split a DSL source string into tokens.
///
/// Exposed for testing; `parse` is the normal entry point.
#let tokenize(source) = {
  let chars = source.clusters()
  let tokens = ()
  let i = 0
  let measure = 1
  let ordinal = 0

  while i < chars.len() {
    let c = chars.at(i)
    if c in _SPACE {
      i += 1
      continue
    }
    // Line comment.
    if c == "/" and i + 1 < chars.len() and chars.at(i + 1) == "/" {
      while i < chars.len() and chars.at(i) != "\n" { i += 1 }
      continue
    }

    ordinal += 1
    let loc = errors.at(measure: measure, token: ordinal, col: i)
    let next = if i + 1 < chars.len() { chars.at(i + 1) } else { none }

    if c == "|" {
      let style = if next == ":" { "repeat-start" } else if next == "|" {
        "double"
      } else if next == "." { "final" } else { "single" }
      i += if style == "single" { 1 } else { 2 }
      if style != "repeat-start" { measure += 1 }
      tokens.push((kind: "barline", style: style, count: none, loc: loc))
      continue
    }

    if c == ":" and next == "|" {
      i += 2
      // An optional repeat count, written `:|x3`.
      let count = none
      if i < chars.len() and chars.at(i) == "x" {
        let scanned = _scan-int(chars, i + 1)
        if scanned.v != none {
          count = scanned.v
          i = scanned.i
        }
      }
      measure += 1
      tokens.push((kind: "barline", style: "repeat-end", count: count, loc: loc))
      continue
    }

    if c in _DURATION-LETTERS {
      let j = i + 1
      let dots = 0
      while j < chars.len() and chars.at(j) == "." {
        dots += 1
        j += 1
      }
      if not _is-sep(chars, j) {
        errors.fail("tab", loc, "unknown duration '" + _word-at(chars, i) + "'", source: source)
      }
      tokens.push((kind: "duration", value: m.dotted(m.durations.at(c), dots), loc: loc))
      i = j
      continue
    }

    if c == "r" {
      if not _is-sep(chars, i + 1) {
        errors.fail("tab", loc, "unknown token '" + _word-at(chars, i) + "'", source: source)
      }
      tokens.push((kind: "rest", loc: loc))
      i += 1
      continue
    }

    // A bare `x` mutes every string; `x/5` mutes one.
    if c == "x" and next != "/" {
      if not _is-sep(chars, i + 1) {
        errors.fail("tab", loc, "unknown token '" + _word-at(chars, i) + "'", source: source)
      }
      tokens.push((kind: "mute-all", loc: loc))
      i += 1
      continue
    }

    if c == "(" {
      let scanned = _scan-chord(chars, i, loc, source)
      tokens.push((kind: "event", notes: scanned.v, loc: loc))
      i = scanned.i
      continue
    }

    if c in _DIGITS or c == "x" {
      let scanned = _scan-note(chars, i, loc, source)
      tokens.push((kind: "event", notes: (scanned.v,), loc: loc))
      i = scanned.i
      continue
    }

    if c == "{" {
      let j = i + 1
      while j < chars.len() and chars.at(j) != ":" and chars.at(j) != "}" { j += 1 }
      if j >= chars.len() or chars.at(j) != ":" {
        errors.fail("tab", loc, "group is missing its ':' — write '{PM: … }'", source: source)
      }
      let name = chars.slice(i + 1, j).join().trim()
      if name == "" {
        errors.fail("tab", loc, "group has an empty name", source: source)
      }
      tokens.push((kind: "group-open", name: name, loc: loc))
      i = j + 1
      continue
    }

    if c == "}" {
      tokens.push((kind: "group-close", loc: loc))
      i += 1
      continue
    }

    if c == "@" {
      i += 1
      let name = ""
      if i < chars.len() and chars.at(i) == "\"" {
        let close = i + 1
        while close < chars.len() and chars.at(close) != "\"" { close += 1 }
        if close >= chars.len() {
          errors.fail("tab", loc, "unclosed chord name", source: source)
        }
        name = chars.slice(i + 1, close).join()
        i = close + 1
      } else {
        let start = i
        while not _is-sep(chars, i) { i += 1 }
        name = chars.slice(start, i).join()
      }
      if name == "" {
        errors.fail("tab", loc, "'@' must be followed by a chord name", source: source)
      }
      tokens.push((kind: "chord-name", name: name, loc: loc))
      continue
    }

    if c == "\"" {
      let close = i + 1
      while close < chars.len() and chars.at(close) != "\"" { close += 1 }
      if close >= chars.len() {
        errors.fail("tab", loc, "unclosed playing instruction", source: source)
      }
      tokens.push((kind: "text", text: chars.slice(i + 1, close).join(), loc: loc))
      i = close + 1
      continue
    }

    errors.fail("tab", loc, "unexpected character '" + c + "'", source: source)
  }

  tokens
}

// ---------------------------------------------------------------------------
// Parser
// ---------------------------------------------------------------------------

/// The number a tuplet is played "in the time of".
///
/// Three in the time of two, five in the time of four, and so on: the largest
/// power of two below the count. Duplets and quadruplets are the exception —
/// they only occur in compound time, where they replace three.
#let _tuplet-of(count) = {
  if count in (2, 4) { return 3 }
  let p = 1
  while p * 2 < count { p = p * 2 }
  p
}

/// Interpret a group name as a tuplet, a volta, or a bracketed span.
#let _classify-group(name, loc, source) = {
  let digits-only = name.clusters().all(c => c in _DIGITS)
  if digits-only {
    let count = int(name)
    if count < 2 {
      errors.fail("tab", loc, "a tuplet needs at least two notes", source: source)
    }
    return (kind: "tuplet", tuplet: (count: count, of: _tuplet-of(count)))
  }
  if "/" in name {
    let parts = name.split("/")
    if parts.len() == 2 and parts.all(p => p.clusters().all(c => c in _DIGITS)) {
      return (kind: "tuplet", tuplet: (count: int(parts.at(0)), of: int(parts.at(1))))
    }
  }
  if (
    name.starts-with("V")
      and name.len() > 1
      and name.slice(1).clusters().all(c => c in _DIGITS)
  ) {
    return (kind: "volta", volta: (int(name.slice(1)),))
  }
  (kind: "span", span: name)
}

/// Parse DSL source into an array of measures.
#let parse-measures(source, tuning: tunings.standard) = {
  let tokens = tokenize(source)
  let strings = string-count(tuning)

  let measures = ()
  let events = ()
  let duration = none
  let spans = ()
  let tuplet = none
  let volta = none
  let stack = ()
  let pending-chord = none
  let pending-text = none
  let start-repeat = false

  for tok in tokens {
    if tok.kind == "barline" {
      // Closing off the measure is written out rather than factored into a
      // closure because a Typst closure captures by value and could not update
      // `measures` and `events` here.
      //
      // A leading barline produces no measure; `|:` only arms the repeat sign
      // for the measure that follows it.
      if events.len() > 0 or start-repeat {
        measures.push(m.measure(
          events: events,
          start-repeat: start-repeat,
          end-repeat: tok.style == "repeat-end",
          end: if tok.style in ("double", "final") { tok.style } else { "single" },
          volta: volta,
          repeat-count: tok.count,
        ))
        events = ()
        start-repeat = false
      }
      if tok.style == "repeat-start" { start-repeat = true }
      continue
    }

    if tok.kind == "duration" {
      duration = tok.value
      continue
    }

    if tok.kind == "chord-name" {
      pending-chord = tok.name
      continue
    }

    if tok.kind == "text" {
      pending-text = tok.text
      continue
    }

    if tok.kind == "group-open" {
      let g = _classify-group(tok.name, tok.loc, source)
      stack.push((kind: g.kind, spans: spans, tuplet: tuplet, volta: volta))
      if g.kind == "tuplet" {
        tuplet = g.tuplet
      } else if g.kind == "volta" {
        volta = g.volta
      } else {
        spans = spans + (g.span,)
      }
      continue
    }

    if tok.kind == "group-close" {
      if stack.len() == 0 {
        errors.fail("tab", tok.loc, "'}' without a matching group", source: source)
      }
      let prev = stack.pop()
      spans = prev.spans
      tuplet = prev.tuplet
      volta = prev.volta
      continue
    }

    // Everything below produces one event.
    let notes = if tok.kind == "mute-all" {
      range(1, strings + 1).map(s => m.note(s, m.MUTED))
    } else if tok.kind == "rest" {
      ()
    } else {
      tok.notes
    }

    for n in notes {
      if n.string > strings {
        errors.fail(
          "tab",
          tok.loc,
          "string " + str(n.string) + " does not exist in tuning " + repr(tuning.name),
          source: source,
        )
      }
    }

    events.push(m.event(
      notes: notes,
      duration: duration,
      rest: tok.kind == "rest",
      spans: spans,
      tuplet: tuplet,
      chord: pending-chord,
      text: pending-text,
    ))
    pending-chord = none
    pending-text = none
  }

  if stack.len() > 0 {
    errors.fail("tab", errors.at(), "unclosed group '{'", source: source)
  }
  if events.len() > 0 or start-repeat {
    measures.push(m.measure(
      events: events,
      start-repeat: start-repeat,
      end-repeat: false,
      end: "single",
      volta: volta,
      repeat-count: none,
    ))
  }
  measures
}

/// Parse DSL source into a complete part.
#let parse(
  source,
  tuning: tunings.standard,
  time: (4, 4),
  tempo: none,
  capo: 0,
  anacrusis: false,
) = {
  // Accept a raw block as well as a plain string, since raw blocks keep the
  // source readable in a document.
  let text = if type(source) == str { source } else { source.text }
  m.part(
    measures: parse-measures(text, tuning: tuning),
    tuning: tuning,
    time: time,
    tempo: tempo,
    capo: capo,
    anacrusis: anacrusis,
  )
}
