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

| Name | Strings | Name | Strings |
|---|---|---|---|
| `tunings.standard` | E4 B3 G3 D3 A2 E2 | `tunings.drop-d` | E4 B3 G3 D3 A2 D2 |
| `tunings.half-step-down` | E♭4 B♭3 G♭3 D♭3 A♭2 E♭2 | `tunings.full-step-down` | D4 A3 F3 C3 G2 D2 |
| `tunings.open-g` | D4 B3 G3 D3 G2 D2 | `tunings.open-d` | D4 A3 F♯3 D3 A2 D2 |
| `tunings.dadgad` | D4 A3 G3 D3 A2 D2 | `tunings.seven-string` | E4 B3 G3 D3 A2 E2 B1 |
| `tunings.bass` | G2 D2 A1 E1 | `tunings.bass-5` | G2 D2 A1 E1 B0 |
| `tunings.ukulele` | A4 E4 C4 G4 | | |

`song` prints the tuning's name as a performance note under the credits, unless
it is standard — which is what a published sheet does, and why the standard
tuning is the one that says nothing.

### Writing your own

`tuning` takes the pitches highest string first, as scientific pitch names.
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
