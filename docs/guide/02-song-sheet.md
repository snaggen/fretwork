## The song sheet

`song` is a show rule that sets the page: paper, margins, the title block, the
running head on continuation pages and the copyright line at the foot. Applied
once at the top of a document, everything after it is the music.

```fretwork-doc
#show: song.with(
  title: "Twelve Past Nine",
  subtitle: "from the first record",
  words: "A. Guitarist",
  music: "A. Guitarist",
  tempo: 132,
  tempo-words: "Driving Rock",
)

#section("Main Riff")

#tab(```
|: @E5 q 0/6 0/6 @G5 3/6 3/6 | @A5 q 5/6 5/6 @G5 3/6 3/6 :|
```)
```

### Arguments

| Argument | What it does |
|---|---|
| `title` | the sheet's title, centred and largest; also the PDF's document title |
| `subtitle` | a faint line under it |
| `artist` | a faint line under that — who plays it, where `words` and `music` say who wrote it |
| `words`, `music` | the writing credits, right-aligned. Passing the same value to both prints the single "Words and Music by" line the published sheets use |
| `arranged` | a third credit line under those |
| `source` | a small faint line above the title, and the left half of the running head — where the transcription came from |
| `copyright` | centred at the foot of every page. Omitted, there is no footer at all |
| `tempo` | a number: prints as a note and an equals sign, drawn rather than set from a font |
| `tempo-words` | a word before it, such as "Moderately" or "Driving Rock" |
| `tempo-note-flags` | which note the tempo is counted in — `0` a quarter, `1` an eighth |
| `tuning`, `capo` | printed as performance notes under the credits, and used for the string count. See [Tunings and capo](#tunings-and-capo) |
| `theme` | see [Appearance](#appearance) |
| `paper`, `margin` | passed to Typst's own `page`, so any paper name or margin dictionary works |

A sheet that runs past one page repeats its identification in a running head —
the source and the title, then the page number — which is what multi-page
published sheets do. The first page never carries it.

### Section headings

`section` is a heading in the sheet's own type, spaced as the published sheets
space theirs. It is a plain function rather than a `heading` show rule, so it
does not disturb whatever the surrounding document does with headings.

```typst
#section("Main Riff")
#section("Solo")
```

### The tempo mark on its own

`tempo-mark` draws what `song` puts under the title, for a document that wants
it somewhere else — a tempo change halfway down a page, say.

```typst
#tempo-mark(132, words: "Driving Rock")
#tempo-mark(96, note-flags: 1)
```

The note is a drawn glyph rather than U+2669, which most sans faces do not cover
and the rest draw at an unrelated weight.

### Credits on their own

`credits` prints the block of writing credits by itself, taking the same
`words`, `music` and `arranged` that `song` does.

```typst
#credits(words: "A. Guitarist", music: "A. Guitarist", arranged: "You")
```
