// The staff itself: the TAB mark, barlines, repeats, endings, chord names, and
// the theme options that change how it is drawn.
//
// Pins: the string lines breaking around the fret numbers, the TAB mark's white
// backing leaving the outer lines whole, both repeat styles, and a staff drawn
// against a tuning with a different number of strings.

#import "/src/lib.typ": *
#import "_common.typ": fixture, vt

#show: fixture.with("staff, repeats and themes")

#tab(theme: vt, ```
@E5 q 0/6 12/6 @G5 3/6 15/6 || @A5 5/6 17/6 @"C#m7 add9" 9/6 21/6 |.
```)

#tab(theme: vt, ```
|: q 0/6 3/6 5/6 3/6 :|x3
```)

#tab(theme: vt, ```
|: q 0/6 3/6 5/6 3/6
 | {V1: q 5/6 7/6 8/6 7/6 :|x3}
   {V2: q 5/6 3/6 h 0/6 |.}
```)

#tab(theme: theme(font: ("DejaVu Sans",), repeat-style: "ornate"), ```
|: q 0/6 3/6 5/6 3/6 :|
```)

#tab(theme: theme(font: ("DejaVu Sans",), mask: "box"), ```
q 0/6 12/6 3/6 15/6
```)

#tab(theme: theme(font: ("DejaVu Sans",), staff-space: 3.2mm), ```
q 0/6 3/6 5/6 3/6
```)

#tab(theme: vt, tuning: tunings.bass, ```
q 0/4 3/4 5/4 3/4
```)

#tab(theme: vt, tuning: tunings.seven-string, ```
q 0/7 3/7 5/7 3/7
```)
