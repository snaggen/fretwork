## Tunings and capo

A tuning does three things: it says how many strings the staff has, it labels
them, and it gives each one a pitch so that a bend knows how far it is bending.
Pass it to `tab`, or to `song` to set it for a whole sheet.

What a tuning changes on the page is the **number of string lines**. It does not
change the numbers: a fret is a fret, and `0/6` is the open sixth string in Drop
D exactly as in standard. What changes is what that string sounds — which is
what the bends measure against, and what `song` prints under the credits.

<!-- fretwork-table -->
| What it is | Syntax |
|---|---|
| Six strings, the default | `q 0/6 0/5 0/4 0/3 0/2 0/1` |
| Seven | `q 0/7 0/6 0/5 0/4 0/3 0/2 0/1` | <!-- tuning: tunings.seven-string -->
| Bass — four | `q 0/4 0/3 0/2 0/1` | <!-- tuning: tunings.bass -->
| Five-string bass | `q 0/5 0/4 0/3 0/2 0/1` | <!-- tuning: tunings.bass-5 -->
| Ukulele — four, and much higher | `q 0/4 0/3 0/2 0/1` | <!-- tuning: tunings.ukulele -->

### The built-in tunings

`tuning` takes the pitches **highest string first** — string 1 first, which is
the order the tab staff is written in, top row to bottom. A guitarist says a
tuning the other way round, lowest string first, so both are given here.

| Name | Highest string first | Low to high |
|---|---|---|
| `tunings.standard` | `E4 B3 G3 D3 A2 E2` | E–A–D–G–B–E |
| `tunings.drop-d` | `E4 B3 G3 D3 A2 D2` | D–A–D–G–B–E |
| `tunings.drop-c` | `D4 A3 F3 C3 G2 C2` | C–G–C–F–A–D |
| `tunings.half-step-down` | `Eb4 Bb3 Gb3 Db3 Ab2 Eb2` | E♭–A♭–D♭–G♭–B♭–E♭ |
| `tunings.full-step-down` | `D4 A3 F3 C3 G2 D2` | D–G–C–F–A–D |
| `tunings.open-g` | `D4 B3 G3 D3 G2 D2` | D–G–D–G–B–D |
| `tunings.open-d` | `D4 A3 F#3 D3 A2 D2` | D–A–D–F♯–A–D |
| `tunings.dadgad` | `D4 A3 G3 D3 A2 D2` | D–A–D–G–A–D |
| `tunings.seven-string` | `E4 B3 G3 D3 A2 E2 B1` | B–E–A–D–G–B–E |
| `tunings.bass` | `G2 D2 A1 E1` | E–A–D–G |
| `tunings.bass-5` | `G2 D2 A1 E1 B0` | B–E–A–D–G |
| `tunings.ukulele` | `A4 E4 C4 G4` | G–C–E–A |

Drop D and Drop C keep the sixth string tuned below the fifth, which is what
lets a power chord be one finger across three strings — and what makes a `0/6`
in them sound a tone or a fourth below the same `0/6` in standard.

`song` prints the tuning's name as a performance note under the credits, unless
it is standard — which is what a published sheet does, and why the standard
tuning is the one that says nothing.

### Writing your own

`tuning` takes the pitches highest string first, as scientific pitch names —
the same order as the table above, and the order the tab staff is written in.
A name and string labels are optional; without labels the staff is unlabelled,
which is what the built-in tunings other than standard and Drop D do.

```typst
#let open-c = tuning("E4 C4 G3 C3 G2 C2", name: "Open C")
#tab(tuning: open-c, ```q 0/6 0/5 0/4 0/3 0/2 0/1```)
```

Any number of strings works, so a lute, a bass VI or a stick are a `tuning` call
away. The pitches are what the bend arrows read: a bend is drawn in steps, and a
step is a step of the string it is on.

### Capo

`capo` is a whole-sheet fact rather than a per-note one: the fret numbers are
written relative to the capo, as every published sheet writes them, and the capo
says where that zero really is. It shifts the pitches used for bends and is
printed as a performance note under the credits.

```typst
#tab(capo: 3, ```q 0/6 2/6 3/6 2/6```)
```

Nothing on the staff changes — `0/6` is still the open sixth string. What
changes is what that string sounds, which is what the bends and the printed note
are about.
