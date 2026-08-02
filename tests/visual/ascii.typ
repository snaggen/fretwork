// The ASCII importer, raw and enriched.
//
// Pins: a bare paste spaced from the source's own columns, and the same source
// once the annotation rows supply what ASCII tab cannot carry — so a change in
// the importer that silently drops a technique shows up as a moved slur.

#import "/src/lib.typ": *
#import "_common.typ": fixture, vt

#show: fixture.with("ASCII import")

#ascii-tab(theme: vt, ```
e|-----------------|-----------------|
B|-----5h7---------|--------------8--|
G|--2--------------|-----7b9---------|
D|--2----------7\5-|-----------------|
A|--0--------------|--10-------------|
E|--------3--------|-----------------|
```)

#ascii-tab(theme: vt, ```
S:  Main Riff
R:  q   q   q   q    q   q   h
C:  E5               G5
PM: ---------
T:                           Harm.
e|----------------|----------------|
B|----------------|----------------|
G|----------------|----------------|
D|--2---2---2---2-|--5---5---------|
A|--2---2---2---2-|--5---5---------|
E|--0---0---0---0-|--3---3---12----|
```)
