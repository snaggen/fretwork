## Diagnostics

The package reports what it could not read **on the page**, above the staff it
belongs to, rather than as a compiler warning. A tab is proofread by looking at
it, and a warning in a terminal is a warning nobody sees.

Reporting is on by default. The examples in this chapter pass `warn: true`
because every other example in this guide passes `warn: false` — a document
about the package is the one place a deliberate mistake is not a mistake.

A bar that does not add up to its time signature says so, and says by how much:

```fretwork warn: true
q 5/3 5/3 5/3
```

```fretwork warn: true
q 5/3 5/3 5/3 5/3 5/3
```

Nothing is thrown away because of it. The bar is still set, in the room its
events need — a bar half written is usually a bar still being written, and
refusing to draw it would take away the thing you check it against.

Syllables that outlast the notes are reported the same way, per verse:

```fretwork warn: true, lyrics: "one two three four five six"
q 5/3 5/3 5/3 5/3
```

`ascii-tab` has far more to say, a paste from the web being exactly the kind of
source that is missing something: every line the importer skipped, every mark it
did not recognise, every token that landed near nothing, and every bend written
downwards is reported above the staff it came from.

```fretwork-ascii warn: true
Tabbed by someone, 2004
e|--------------|
B|--------------|
G|--5b3---------|
D|--------------|
A|--------------|
E|--------------|
```

### Turning it off

`warn: false` silences one call — for a figure in a document about the package,
or for a passage you know is short because the next block continues it.

```typst
#tab(warn: false, ```q 5/3 5/3 5/3```)
```

It silences the reporting, not the reading: what the package could not make
sense of is still absent from the page. Prefer fixing the source.
