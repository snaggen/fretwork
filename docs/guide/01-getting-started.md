## Getting started

```typst
#import "@preview/fretwork:0.4.0": *

#show: song.with(title: "Twelve Past Nine", music: "A. Guitarist", tempo: 132)

#section("Main Riff")

#tab(```
|: @E5 e 0/6 0/6 {PM: 0/6 0/6 0/6 0/6 0/6 0/6}
 |  @G5 q 3/6 3/6 @A5 5/6 5/6 :|
```)
```

That is the whole shape of it. There are **two layers**, and the split is
deliberate:

- **Document structure is ordinary Typst.** `song`, `section`, `tab` and the
  rest are functions with named arguments, so they autocomplete, type-check and
  take a `theme`.
- **The music is a string.** A riff written as nested function calls is
  unbearable to write and impossible to read, so note-level content is a compact
  syntax of its own — the one the [tablature chapter](#writing-tablature) is
  about.

Nothing but `tab` is required. A bare call renders a staff on its own, wherever
you put it, and everything else on this page is optional:

```fretwork
q 5/3 5/3 7/3 7/3
```

### The music argument

`tab` takes its music as a string or as a raw block. A raw block is usually
easier — it keeps line breaks, needs no escaping, and lets an editor leave the
contents alone:

```typst
#tab(```
q 5/3 5/3 7/3 7/3
```)
```

Both forms reach the same parser, so a string works where a raw block would be
awkward — building the source in code, for instance.

### Which chapter you want

| If you want to | Read |
|---|---|
| write a riff | [Writing tablature](#writing-tablature) |
| set a whole song sheet | [The song sheet](#the-song-sheet) |
| play in something other than standard tuning | [Tunings and capo](#tunings-and-capo) |
| change how it looks | [Appearance](#appearance) |
| set words under the notes | [Lyrics](#lyrics) |
| render tab pasted from the web | [Pasted ASCII tab](#pasted-ascii-tab) |
| look an argument up | [Reference](#reference) |
