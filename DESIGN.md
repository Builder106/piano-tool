# Piano Tool app design

Status: method-book direction chosen 2026-11-08. It replaces the retired
desk and pencil interface and the "Strung" open-grand concept, whose
Blender renders made the app look antiquated.

## Brief

- **Subject:** a piano tutor that listens (microphone or MIDI), shows the
  score, and marks every note.
- **Audience:** everyday beginners. No jargon in the interface.
- **Job:** make practice feel alive and make it obvious what to play next.
- **Platforms:** iOS, Android, web, macOS, Windows, Linux, from one Flutter
  codebase.
- **Constraint:** the app makes no sound while the microphone is listening,
  because the detector would hear it. Feedback during play is visual.

## Concept

The app is a lesson book and a teacher's pencil. A pupil's copy gets circled
and ticked, and that is already what the brand mark is: middle C, circled.

- **Field and pages.** A flat blue field, white pages on it, ink engraving
  in Bravura. No gradients, glass, glow, shadows or photographic renders.
- **Two pencils.** Blue says what to play and what was right: the loop round
  the next note and the next key, ticks under notes played well. Red says
  what to fix and the grade: a loop round a missed note, a loop round the
  score. Colour never carries a meaning alone; every state also has a shape
  (loop, tick, ring, line).
- **Plain words.** Titles are set large, heavy and left-aligned in
  Atkinson Hyperlegible Next. Sentences say what happened and what to do
  next. No stat cards, no eyebrow labels, no percentages shown as a dial.

## Structure

| Screen | What it is |
|---|---|
| Home | the book's contents on the field, one row per piece, the chosen piece circled in white pencil; the opened page beside it with the piece's first bars engraved and a Start button |
| Find the notes | before a new piece: the first few notes it asks for are circled on the keyboard and named as large letters, each ticked in blue as it is played, in any order; a digital piano's key strike counts at once and the microphone needs the same note twice; Start listening asks for the microphone only when pressed, and Skip goes straight to practice |
| Practice | a page with the music scrolling right to left through a blue pencil strike line, and a keyboard below with the key to play next circled; Back, Speed and Start sit on the field above |
| Results | the page handed back marked: the whole piece with a tick under each note played well and a red loop round each miss, the grade circled in red, one sentence about what to repeat, and Practise bar N |

The input check (play middle C) is a line of words on the practice page.

## Not built yet

- Settings, Add a piece (record or upload) and a pieces list screen.
- Hear it (playing the piece back) and on-screen keys that make sound.

## Type

Atkinson Hyperlegible Next for everything, including the wordmark. Bravura
for music. See `brand/README.md`.

## Studies

`design/screens/pencil.html` is the chosen look as a playable study (keys
`a s d f g h j k l`; add `#home`, `#lesson`, `#practice` or `#results` to
the address). `colour.html`, `index.html` and their `shots/` are earlier,
rejected directions kept for reference: glass and glow was called AI slop,
a colour for every note was called childish, and the realistic piano was
called antiquated.
