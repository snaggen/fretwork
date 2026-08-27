## Appearance

Every measurement on the page derives from one unit, `staff-space` — the
distance between two string lines. Line weights, stem lengths, beam thickness
and type sizes are all fractions of it, so changing that one value rescales a
whole sheet without the proportions drifting.

`theme()` builds a theme; pass it to `tab`, or to `song` for a whole sheet.

```typst
#tab(theme: theme(staff-space: 3.2mm), ```q 5/3 5/3 7/3 7/3```)
```

### Size

<!-- fretwork-table -->
| What it is | Syntax |
|---|---|
| The default, 2.9 mm | `\|: q 5/3 5/3 7/3 7/3 :\|` | <!-- theme: theme() -->
| Smaller | `\|: q 5/3 5/3 7/3 7/3 :\|` | <!-- theme: theme(staff-space: 2.2mm) -->
| Larger | `\|: q 5/3 5/3 7/3 7/3 :\|` | <!-- theme: theme(staff-space: 4mm) -->

### Repeat signs

`repeat-style` is `"plain"` by default — the bare thick-thin-and-dots sign.
`"ornate"` adds the flared serifs of an engraved one, as published rock tab uses.

<!-- fretwork-table -->
| What it is | Syntax |
|---|---|
| Plain, the default | `\|: q 5/3 5/3 7/3 7/3 :\|` | <!-- theme: theme() -->
| Ornate | `\|: q 5/3 5/3 7/3 7/3 :\|` | <!-- theme: theme(repeat-style: "ornate") -->

### Fret numbers on the lines

A fret number sits on its string's line, so something has to give way. `mask` is
`"gap"` by default, which breaks the line around the digits the way the
published sheets do. `"box"` draws them on an opaque patch instead, which is
what works on a tinted page.

<!-- fretwork-table -->
| What it is | Syntax |
|---|---|
| A gap in the line, the default | `q 12/3 5/3 11/3 7/3` | <!-- theme: theme() -->
| An opaque patch | `q 12/3 5/3 11/3 7/3` | <!-- theme: theme(mask: "box") -->

### Ink

`color` is everything the staff draws — lines, numbers, stems, every mark. Any
Typst colour works.

<!-- fretwork-table -->
| What it is | Syntax |
|---|---|
| Ink of your own | `q 5/3 5/3 7/3 7/3` | <!-- theme: theme(color: rgb("#2f81f7")) -->

`faint` is the second ink, and belongs to the title block rather than the staff:
the subtitle, the artist, the source line, the performance notes under the
credits, the running head and the copyright line. Nothing `tab` draws uses it,
so it only shows on a sheet set with [`song`](#the-song-sheet).

### Type

`font` is the music's type — fret numbers, chord names, instructions — and takes
a family or a list of fallbacks. `lyric-font` is the sung words, set in a serif
so that a syllable is never mistaken for a playing instruction.

The default is `("Montserrat", "Noto Sans", "DejaVu Sans")`, which is the face
the package was designed against and degrades to whatever is installed. No music
font is needed for either: every symbol is a vector curve.

```typst
#tab(theme: theme(font: ("Noto Sans", "DejaVu Sans")), ```q 12/3 5/3 11/3```)
```

### A rule under a held word

A word sung over several notes is written once. `lyric-extender` draws a rule
after it, running to the last note it is held over. Vocal scores use one; the
published *tab* sheets this package is set to look like do not, so it is off.

<!-- fretwork-table -->
| What it is | Syntax |
|---|---|
| Off, the default | `q 5/3 7/3 8/3 7/3` | <!-- lyrics: "held _ _ gone", theme: theme() -->
| On | `q 5/3 7/3 8/3 7/3` | <!-- lyrics: "held _ _ gone", theme: theme(lyric-extender: true) -->

### Everything else a theme holds

`theme()` takes the eight arguments above, and returns a **plain dictionary** of
every measurement derived from them — line weights, type sizes, horizontal
spacing, the gaps between lanes. Those are not arguments, because they normally
follow from `staff-space` and setting them by hand is how proportions drift.

Where you do want one, merge it in. A theme is a dictionary, so `+` is all it
takes:

```typst
#tab(
  theme: theme(staff-space: 3.6mm) + (
    min-event-gap: 1.1 * 3.6mm,
    quarter-width: 5.5 * 3.6mm,
  ),
  ```q 5/3 5/3 7/3 7/3```,
)
```

The values in the dictionary are **absolute lengths**, already multiplied out, so
an override has to be multiplied by your own staff space rather than the
default.

| Key | Default | What it governs |
|---|---|---|
| `line`, `barline`, `heavy-barline` | 0.075, 0.12, 0.45 sp | rule weights |
| `gap-padding` | 0.08 sp | air either side of a fret number where the line breaks |
| `stem`, `stem-length` | 0.09, 2.0 sp | the rhythm lane's stems |
| `beam-thickness`, `beam-gap` | 0.286 sp each | beams, and the augmentation dot, which is a beam thick |
| `rhythm-clearance` | 0.15 sp | staff to the top of the stems |
| `fret-size`, `chord-size`, `section-size`, `count-size`, `technique-size`, `lyric-size`, `bend-size`, `tempo-size`, `title-size`, `credit-size`, `copyright-size` | 0.8–3.4 sp | type sizes |
| `spacing-exponent` | 0.6 | how fast width grows with duration |
| `quarter-width` | 3.6 sp | width of a quarter before justification |
| `min-event-gap` | 0.55 sp | least air between two events |
| `lyric-gap` | 0.8 sp | least air between two syllables |
| `measure-padding` | 0.7 sp | air inside the barlines |
| `tab-mark-width` | 2.7 sp | room for the vertical `TAB` mark |
| `system-gap`, `lane-gap` | 4.0, 0.30 sp | vertical space between systems, and between lanes |

Spacing is optical rather than proportional: width grows with duration, but far
more slowly, so a whole note does not eat a whole system. `spacing-exponent` is
that curve.
