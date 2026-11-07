# Piano Tool app design

Status: concept chosen 2026-11-06. Art direction (palette, type, grid,
motion tokens) is the next phase. The previous desk, method-book and
pencil interface is retired; nothing from it carries over.

## Brief

- **Subject:** a piano tutor that listens (microphone or MIDI), shows
  the score, and marks every note.
- **Audience:** everyday beginners. No jargon in the interface.
- **Job:** make practice feel alive and make it obvious what to play
  next.
- **Platforms:** iOS, Android, web, macOS, Windows, Linux, from one
  Flutter codebase.
- **Constraints:** the app makes no sound while the microphone is
  listening, because the detector would hear it. Feedback during play is
  visual.

## Concept card

```
Idea:        The app is the inside of an open grand piano. Each piece is
             a string, and a note played right makes its staff line ring.
Metaphor:    a grand piano's action and stringing: strings, hammers,
             dampers, bridge pins, tuning pins, the cast-iron plate.
Signature:   a correct note rings its bar of the staff like a struck
             string, then decays over the written duration. Continuity
             moment: opening a piece, its damper lifts, the string sounds,
             and the one string fans into the five staff lines.
Emotion:     the instrument is awake and answering you.
Motion verb: strike and ring. A fast attack, a long natural decay, a
             damper that stops it.
Screenshot:  the results staff with every learned bar ringing in
             overtones and two quiet bars waiting to be looped.
Structure:   the app is the open piano. You move along the strings
             (pan), into a string (open a piece), and back out (the
             damper falls). One unit is a piece: one string.
Escape hatch: a plain repertoire list, one tap away from every screen,
             with every piece, its state and its best result.
```

Anchor: piano tone comes from struck strings terminated at bridge pins
and silenced by dampers. Bass strings are copper-wound, treble strings
plain steel, all held by a cast-iron plate and tuned at the pinblock.

Runner-up detail kept: the speed control is a metronome pendulum weight
(higher on the rod is slower, as on a real metronome).

## Structure in the piano's terms

| App need | In the piano | Behavior |
|---|---|---|
| Home, piece list | the strung plate seen from above | one string per piece, in learning order; learned strings keep a faint idle ring, open ones are still, locked ones are slack |
| Piece name and status | the damper resting on each string | name set on the damper head; best result beside it (hammers strike from below and are hidden from above, so the dampers carry the labels) |
| Open a piece | damper lifts, string fans into the staff | shared-element transition; back closes it and the damper falls |
| Practice | the staff strung between bridge pins | barlines are bridge pins; each bar vibrates on its own; hit grades set ring strength; a miss is a damped thud with a shape mark, never color alone |
| Results | the whole staff rings at once | quiet bars are the ones to practise; tapping a bar loops it at the chosen speed |
| Input check, settings | the tuning pins | play middle C and watch the pitch settle; input source, timing tolerance, appearance |
| Import and review | stringing a new piece | record or upload, then tune it (fix notes) before it goes on the plate |
| Keyboard | the key bed along the near edge | shows the keys the piece needs and what you played |
| Empty and error states | an unstrung plate, a broken string | written in plain words |

Orientation: home works upright and sideways. Upright phones get tall
strings and a sideways pan. Practice prefers sideways on phones and
falls back to a two-octave keyboard centred on the piece's range when
upright. MIDI is the primary input on desktop and web.

Reduced motion: no idle ring, no fan transition; a hit brightens its
bar briefly instead of vibrating it. Every state also has a shape mark.

## Asset split

Most of the life is code. Blender supplies a small set of static,
orthographic top-down renders that the code layers and animates. The
strings themselves, their vibration and every state change are drawn
live.

### Blender (one scene, orthographic top-down, Cycles on Metal)

| Asset | Renders | Notes |
|---|---|---|
| Cast-iron plate | 1 tileable section + 2 end caps | lacquered metal with rosette holes; tiles horizontally behind the string row |
| Pinblock with tuning pins | 1 tileable strip | settings and input check live here |
| Damper | down, lifted | lacquered head over a grey felt pad; the name is drawn in code on the head; falls when a piece closes or a MIDI key is released |
| Bridge pin | 1 sprite | doubles as the barline in practice |
| String surface | steel tile, copper-wound tile | small tileable textures sampled by the live string painter |
| Key bed | 1 octave at rest, pressed white key, pressed black key | the live keyboard is assembled from these; built from `site/design/blender/keyboard.py` with a top-down camera |
| Metronome weight and rod | 1 sprite each | speed control |

About 15 renders from one file, at the device pixel ratios the app ships.
Light and dark appearance are lighting setups in the same scene, not a
second model.

### Code (Flutter, one ticker)

- string geometry and vibration: a few standing-wave modes per bar,
  pinned at the bridge pins, decayed per note duration
- the fan from one string into five staff lines
- notes, clefs and rests (Bravura), and the shape marks for hit grades
- the idle ring of learned strings, paused off screen
- pans, the repertoire list, text, focus and every control state

### Glaxnimate

- shape marks for perfect, good, okay and missed
- small line icons where a control needs one

## Brand

Kept: middle C circled in pencil, and the palette and type in
`brand/README.md` (lacquer, paper, ink, graphite, one Pencil Blue accent,
neutrals on hue 262; Cormorant Garamond for the wordmark and titles, IBM
Plex Sans for text, Bravura for music). The mark fits the new world:
practice opens by playing middle C, and the input check at the tuning
pins starts there.

The piano's materials are read through that palette: black lacquer case
and damper heads, a graphite plate, steel strings, grey felt, and blued
steel tuning pins, which carry the one blue accent as a real material.
Plate gold and red felt are left out. Copper stays on the wound bass
strings: it is a material, not a UI colour, and the strings looked like a
stripe pattern without it. The first look-development still checks whether the result reads
as a piano or as a cold machine; warmth may have to come from light
rather than colour.

## Look development

Script: `design/blender/strung.py` (builds on `site/design/blender/keyboard.py`).

- Passes 1 to 3 looked straight down at tuning pins, the pressure bar and
  dampers. The user could not tell what it was: most people have never
  seen those parts, and nothing in the frame said "piano".
- Rule from that: the keyboard is always in frame, seen from the player's
  seat (orthographic, tilted 40 degrees, so strings stay parallel lines the
  app can draw over). Detail people do not recognise (pins, bushings,
  coils, the pressure bar) is cut. Recognition comes first, then the
  strings.
- Pass 5 reads as keys, the name board with the mark, a row of dampers and
  strings over the soundboard.
- Still open: the rendered strings are a dense field, so a piece cannot be
  one rendered string. Likely answer: the render is the quiet backdrop and
  the app draws each piece's string brighter on top, with its name on that
  damper.
- Passes 6 and 7 detail the strings: thickness by register, copper-wound
  bass bichords crossing over the tenor at 13 degrees, a plate bar at the
  break, a bridge with two pins per string, agraffes, roughness that varies
  along each string, and a low sun so strings shadow the soundboard.
- Pass 8 darkens the soundboard and trims the overhead light so the
  strings lead, levels the damper tops across bass and tenor, lowers the
  overstrung bass to sit just over the plate bar, and coarsens the copper
  winding so it shows at full size.

## Home screen (first build)

Code: `lib/home/` (`home_screen.dart`, `strung_geometry.dart`), colours and
families in `lib/brand/palette.dart`. Backdrop `assets/art/strung/home.jpg`
is pass 8; `home.json` is the image-space geometry `strung.py` exports with
it (each note's string x positions, damper box and key box).

- Placement: pieces sit in learning order on every other white key from
  middle C, so the first three spell C, E, G. Two built-in pieces start on
  middle C, so "the string of its first note" could not work.
- A learned piece's strings glow paper white, the next piece's glow Pencil
  Blue, locked pieces stay unlit. The strings area is dimmed slightly so
  lit strings read as lit.
- Diegetic pass (2026-11-07): pieces are paper slips resting on the
  strings, rendered in Blender in the scene's light (`STRUNG_SLIP=1`,
  `assets/art/strung/slip.png`) with the lettering drawn by the app and
  foreshortened to lie flat. A locked piece's slip lies under the strings,
  in their shade, with the strings drawn across it. Adding a piece is a
  blank slip written in blue pencil. Slips alternate between two heights;
  a slip is never wider than the gap to the piece two along.
- The next piece's key is circled with the brand's pencil loop; keys that
  hold pieces show their letter.
- All pieces and Settings are inlaid in nickel on the name board, left of
  the maker's mark, in the mark's typeface.
- Framing: cover fit with the damper row near 42% of the height, so wide
  phones crop a little of the strings and a little of the keys, never all
  of the keys.
- Not built yet: idle ring of learned strings, opening a piece (damper
  lift and fan into the staff), playing a key to open its piece, portrait
  phones, the list and settings views.
