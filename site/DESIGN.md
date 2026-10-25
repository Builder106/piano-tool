# Piano Tool showcase: design record

## Brief

- Subject: Piano Tool, a Flutter practice tutor. It scrolls a staff, listens to an acoustic
  piano through the microphone (YIN pitch detection) or a MIDI keyboard, and marks every note
  as hit or missed, with timing quality. It can also turn a recording into a level.
- Audience: people learning to read music at a real piano, and developers and reviewers who
  look at the repository.
- Job: show what the app does and how it works, and send people to the source and the web build.
- Assets: the app's own fonts (Cormorant Garamond, IBM Plex Sans, Bravura), its colour tokens,
  its notehead rules (`lib/ui/staff/note_glyph.dart`), its stage 1 level, its scoring windows.
  New art: one Blender keyboard (61 keys, C2 to C7, like the app's keyboard view) and
  Glaxnimate figures.
- Constraints: no conventional skeleton. Everything runs in the browser, no backend.

## Concepts

| | A. Stage one (material) | B. The listening chain (process) | C. The level file (formal) |
|---|---|---|---|
| Idea | The site is stage 1 of the app, the C major scale. You read it by playing it: each of the eight notes is a page | The site is the path from a hammer hitting a string to a filled notehead; you travel string, air, microphone, buffer, YIN dip, MIDI number, staff | Every page is a `LevelNote(...)` record; editing the record changes the page |
| Anchor | `level_1` really is C4 D4 E4 F4, G4 A4 B4 C5 at ♩ = 80; notes are MIDI numbers; state is a notehead shape; the app listens with YIN | the YIN pipeline in `pitch_detector.dart` | the data model in `level_models.dart` |
| Structure | the instrument at the bench: staff on the desk, keyboard under your hands. Move by playing a key (click, computer keys, MIDI, or the real piano through the microphone). One unit is a note | one horizontal signal chain, scrubbed | one code file, each record a link |
| Signature | play D4 on your own piano and the site turns to the D4 page; the notehead fills the way the app marks a hit | a live waveform travelling through the stages | records rewrite themselves |
| O / F / Fe / P / S | 5 / 5 / 3 / 1 / 5 | 4 / 4 / 4 / 2 / 3 | 3 / 3 / 4 / 3 / 4 |

Pick A. Its navigation is the product's own mechanism, and the swap test fails for any other
subject (another piano app does not have this stage 1, these notehead rules, or this listener).
Steal from B for the D4 page: the listening chain is that page's figure, live from the microphone.

## Concept card

```
Idea:        This site is stage one of Piano Tool. Play the C major scale to read it.
Metaphor:    the practice screen at the instrument: staff on the desk, 61 keys under your hands
Signature:   play a note (click, A to K keys, MIDI, or your piano through the mic, detected by a
             browser port of the app's YIN detector) and the site turns to that note's page;
             the key goes down (Blender pressed render) and the notehead changes state the way
             the app marks it: hollow, then ringed, then filled
Emotion:     the hush before you play: a dark lacquered instrument, one lit desk, an invitation
Motion verb: strike and ring: a fast attack (90 ms down), then a long release (expo.out)
Screenshot:  the staff with C4 ringed in blue, the keyboard below with middle C held down,
             "Piano Tool" set large in Cormorant on the desk
Structure:   the site is the instrument; you move by playing notes; one unit is a note of the
             scale, with its own URL (/listening/ is D4). Staff noteheads and keys are the
             navigation. The corner HUD reads like the app's practice HUD (stage, tempo, n of 8)
Escape hatch: /score/, the plain list of all eight notes with real links, one tap from the HUD
```

## Units (stage one, measures 1 and 2)

| Note | MIDI | Route | Unit |
|---|---|---|---|
| C4 | 60 | `/` | Piano Tool: what it is, and how to play this site |
| D4 | 62 | `/listening/` | It listens: YIN, live from your microphone |
| E4 | 64 | `/staff/` | Measured in staff spaces |
| F4 | 65 | `/shape/` | Shape before colour |
| G4 | 67 | `/timing/` | Early, late, on the beat (hit windows, tap demo) |
| A4 | 69 | `/midi/` | Or plug the piano in |
| B4 | 71 | `/import/` | A recording becomes a level |
| C5 | 72 | `/play/` | Stage complete: get the app and the source |

Black keys inside the octave are pressable and are not in the stage: they flash a struck
notehead (the app's missed glyph) and go nowhere. The 404 is the same idea at page scale.

## Art direction

Palette (from the app's Recital Dark theme, moved to a neutral lacquer black; the app's warm
paper and ink tones are not used because cream and warm off-white are banned here):

| Role | Hex | Use |
|---|---|---|
| ground | `#0A0A0B` | lacquer black, page and curtain |
| desk | `#121214` | the lit music desk panel behind the staff |
| ink | `#ECECEC` | text, white keys |
| muted | `#9B9BA1` | secondary text (AA on ground and desk) |
| line | `#2A2A2E` | hairlines |
| staff | `#7A7A82` | staff lines and upcoming noteheads |
| active | `#6591E1` | the note that is due (app `accent`, dark) |
| hit / okay / miss | `#5DAD70` / `#FFB74D` / `#D8625C` | the app's state colours, only on noteheads |

Type: Cormorant Garamond (display, titles, the decal), IBM Plex Sans (text, every number and
label), Bravura (clef, time signature, metronome mark). All three are the app's own bundled
families. Display: Cormorant 500, tracking -0.02em to -0.035em by size, leading 0.9.

Grid: 12 columns, fluid gutter. Two hanging lines: column 1 (titles, staff clef) and column 6
(body text). Body measure 34rem.

Shape: radius 0 everywhere except noteheads and the ring (they are ellipses).

Motion: one family. Attack `power4.out` 0.09 s, release `expo.out` 0.9 to 1.3 s. Line
reveals stagger 60 ms. Transitions: the old desk releases (drops 12 px, fades, 0.28 s), the key
holds, the new desk rings in (lines rise, 1.1 s).

Idle: the next key's marker breathes very slightly (ring opacity 0.6 to 1 over 2.4 s) and the
staff's active ring pulses at ♩ = 80 (750 ms), on the GSAP ticker, off under reduced motion.
This is the app's own active state, so the concept is what moves.

Sound: off by default, a toggle in the HUD. Keys then play the app's review tone (fundamental
plus 2nd and 3rd harmonics, 5 ms attack, exponential decay).

## Structure plan

Desktop 1440:
```
┌ Piano Tool (home)                 Stage 1  C major  ♩ = 80   3 of 8   Score  Sound  Listen ┐  HUD, fixed
│                                                                                            │
│  𝄞 4/4  o      o      ◉      o   |   o      o      o      o   ‖                            │  staff: 8 links
│                                                                                            │
│  E4 · MIDI 64                                                                              │
│  Measured in                                  body text from column 6                     │  the desk (scrolls)
│  staff spaces                                 figure (Glaxnimate)                          │
│                                                                                            │
│  Next: F4, Shape before colour   (press F, click the key, or play it)                      │
├────────────────────────────────────────────────────────────────────────────────────────────┤
│ ▓ cheek │ C2 ........ [C4 D4 E4 F4 G4 A4 B4 C5] ........ C7 │ cheek ▓                      │  keyboard band, fixed
└────────────────────────────────────────────────────────────────────────────────────────────┘
```
Phone 390: HUD collapses to "Piano Tool" left and "3 of 8 / Score" right; the staff is
re-tuned (space 10 px); the desk is one column; the band zooms to B3 to D5 (10 white keys,
39 px each) so every stage key is a real tap target. Listen and Sound move into the band's
top edge.

Opening a unit: the key goes down and holds, the noteheads update, the desk swaps with the
release then ring motion. Back closes it (it is a route).

## Decisions made during QA

- Idle motion is the due note keeping time: its ring swells on every beat at ♩ = 80
  (750 ms), and the next key's hollow head pulses with it. `shoot.mjs` reports
  `idleMotion: false` because it compares two frames 1.5 s apart, exactly two beats, so both
  frames land on the same phase. Sampling every 170 ms shows the ring opacity moving between
  0.22 and 0.42 (checked 2026-10-25). The pulse is real; the check aliases with the tempo.
- The staff is sized from the space between the HUD and the keyboard band, not the page width,
  so the first frame always holds the staff, the title and the band together.
- The band shows all 61 keys on wide screens, C3 to C6 on tablets, and B3 to D5 on phones,
  where each stage key is a 39 px tap target. Phones crop the name board; the HUD carries the
  name there.
- Note names sit below the staff box, so they never collide with C4's ledger line at phone size.
- The letter keys can be switched off (the Keys toggle), as WCAG 2.1.4 asks of single-character
  shortcuts. The toggle is hidden on touch devices, where there are no letter keys.

## Genericness test

- Skeleton: no navbar, no hero, no stacked sections, no footer. The staff and the keyboard are
  the navigation; the HUD is the app's practice HUD. Pass.
- Hero: there is no hero; the home is the C4 page of the same instrument. Pass.
- Palette: near-black with one blue would be generic as a style, but here the blue is the
  app's own "active note" colour and appears only on the due note. Kept with that reason.
- Type: Cormorant is the app's title face; Plex is its metric face. Kept, they are the brand.
- Changed: dropped a loader (the brief does not earn one); dropped WebGL (renders do the job).
