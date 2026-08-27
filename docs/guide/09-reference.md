## Reference

Every name the package exports.

### Rendering

| Name | Signature |
|---|---|
| `tab` | `tab(source, tuning:, time:, tempo:, capo:, anacrusis:, count-in:, show-time:, lyrics:, verse-labels:, theme:, warn:)` |
| `ascii-tab` | `ascii-tab(source, tuning:, time:, tempo:, capo:, anacrusis:, rhythm:, lyrics:, count-in:, show-time:, theme:, enrich:, warn:)` |
| `render` | `render(part, theme:, count-in:, show-time:, lyrics:)` — set a part built in code rather than parsed |
| `ascii-to-dsl` | `ascii-to-dsl(source, ..args)` — the equivalent native source, as text |

`tab` and `ascii-tab` share most of their arguments:

| Argument | Default | What it does |
|---|---|---|
| `source` | — | the music, as a string or a raw block |
| `tuning` | `tunings.standard` | how many strings, what they are called, what they sound |
| `time` | `(4, 4)` | the time signature, where the source does not set one with `[3/4]` |
| `tempo` | `none` | carried into the model and drawn by `song`'s title block |
| `capo` | `0` | which fret the written zero really is |
| `anacrusis` | `false` | the first bar is a pick-up and is not checked against the meter |
| `count-in` | `false` | a counting row under the staff, on the first system only |
| `show-time` | `true` | print the time signature. `false` on the second and later blocks of one piece |
| `lyrics` | `none` | a string, or a list of them, one per verse |
| `verse-labels` | `none` | replaces the verse numbering, one per verse. `tab` only |
| `theme` | `default-theme` | see [Appearance](#appearance) |
| `warn` | `true` | report on the page what could not be read |
| `rhythm` | `none` | infer note values. `ascii-tab` only |
| `enrich` | `none` | `part => part`, applied after parsing. `ascii-tab` only |

### The page

| Name | Signature |
|---|---|
| `song` | `song(title:, subtitle:, words:, music:, arranged:, artist:, source:, copyright:, tempo:, tempo-words:, tempo-note-flags:, tuning:, capo:, theme:, paper:, margin:, body)` |
| `section` | `section(title, theme:)` |
| `tempo-mark` | `tempo-mark(tempo, words:, note-flags:, theme:)` |
| `credits` | `credits(words:, music:, arranged:, theme:)` |

### Themes

| Name | Signature |
|---|---|
| `theme` | `theme(staff-space:, font:, lyric-font:, color:, faint:, mask:, repeat-style:, lyric-extender:)` |
| `default-theme` | the theme used when a caller supplies none |

### Tunings

| Name | Signature |
|---|---|
| `tunings` | the eleven built-in tunings — see [Tunings and capo](#tunings-and-capo) |
| `tuning` | `tuning(pitches, name:, labels:)` — pitches highest string first, as `"E4 B3 G3 D3 A2 E2"` |
| `string-count` | `string-count(t)` |
| `to-pitch` | `to-pitch(t, string, fret, capo: 0)` — the MIDI number a fret sounds |
| `pitch-name` | `pitch-name(midi)` |

### Lyrics

| Name | Signature |
|---|---|
| `lyric-at` | `lyric-at(measure, position, text)` — a syllable placed by its moment rather than by counting notes |

### Rhythm inference

For `ascii-tab`'s `rhythm:` argument, where annotating every column would be
busywork.

| Name | What it does |
|---|---|
| `even(value)` | every event takes that value — `even(1/8)` for a bar of eighths |
| `fill` | each bar is spread evenly across the time signature |
| a string | `"q q e e \| h h"`, spent event by event |

### The model

`model` and `rational` are exported too. They are the data the parsers build and
the renderers read — events, notes, techniques, spans, durations as exact
fractions — and they are public so that `enrich:` and `render` have something to
work with. [`SPEC.md`](SPEC.md) describes them; nothing in this guide needs them.
