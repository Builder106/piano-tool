# Piano Tool showcase: design record

Second composition, 2026-10-25. The first one (Astro desk with a HUD bar, a large title, two
columns of prose and a "play next" block over a keyboard band) had the right idea and the
wrong page: it read as an article framed by a staff and a keyboard. This record replaces it.

## Brief

- Subject: Piano Tool, a practice app for people learning piano. It scrolls a score, listens
  to your piano through the microphone or reads a digital piano over USB or Bluetooth, and
  marks every note you play.
- Audience: people getting into piano, at a real instrument. Not developers: code and
  algorithm detail belong in the README. No jargon on any page (pitch detection, MIDI bytes,
  staff spaces, quantising).
- Job: show what a learner gets from the app, one plain benefit per page, by letting them play
  the page; then send them to the free browser build at `/app/`. That is the only call to
  action.
- Tone: the hush of a practice room at night. Precise, unhurried, a little private.

## What is kept, what is new

Kept (named by the user's go-ahead, nothing else is ported):

| Kept | File |
|---|---|
| Input and listening code: letters, pointer, Web MIDI, microphone pitch detector, synth | `src/instrument/index.ts`, `yin.ts`, `synth.ts` |
| Live figure drivers (heard note, tap test, digital piano key) | `src/instrument/figures.ts` (rewired to new markup) |
| Blender keyboard: rest render, 13 pressed renders, key geometry | `src/assets/keyboard/*`, `design/blender/keyboard.py` |
| Glaxnimate source drawings | `design/glaxnimate/*` |
| Fonts: Cormorant Garamond, IBM Plex Sans, Bravura | `public/fonts/*` |
| Unit data (routes, MIDI, keys, measures, meta descriptions) | `src/data/site.ts` |
| Staff geometry rules (everything in staff spaces, notehead tilt and size) | `src/data/staff.ts` |
| Page engine (GSAP context per page, Astro router adapter) | `src/engine/*` |
| `/score/` as the plain list escape hatch | `src/pages/score.astro` (restyled) |

New: the page model, every component's markup, all CSS, all visible copy except facts, the
music desk and ledge renders, the paper, the pencil marks.

## Organizing idea

**The practice copy.** The site is one sheet of music standing on the music desk of the piano
you are sitting at: stage one of Piano Tool, the C major scale. You read it by playing it.
Each note you play gets the app's mark on its notehead, and the note's pencil annotation is
written in beside it, the way a teacher writes in a pupil's copy. Play all eight and the
sheet has become a marked practice copy.

Why this is Piano Tool's and no one else's: the app's whole job is marking the notes you play
on a scrolling staff. Its practice screen is literally a score above a keyboard
(`references/app-practice-screen.png`). The notehead states are the app's rules
(`note_glyph.dart`), the scale and tempo are `level_1`, the listener is a port of the app's own pitch detector. A
different piano site could borrow "sheet music", but not this sheet, these marks or this
listener. Swap test against the genre (any piano-learning site): fails to transfer. Pass.

## Structure

Three questions, answered from the metaphor:

- **What the page is.** The view from the bench, one screen tall on desktop. The keyboard
  is under your hands at the bottom. Above it the lacquered music desk fills the rest of the
  screen, with its ledge, and one sheet of paper stands on the ledge. No header bar, no
  footer, no sections.
- **How you move.** By playing the next note: click or tap its key, type its letter, play it
  on a digital piano, or play it on your own piano through the microphone. The noteheads on
  the sheet are also links. Each note has its own URL; the sheet persists across routes, so
  only the marks change.
- **One unit.** A note of the scale and its pencil annotation: a short heading, two or three
  short paragraphs, and one drawing made on or around the actual staff.

Orientation in 3 seconds: the printed title on the sheet says what this is; the blue ring
on the due note and the lit key say what to do. Escape hatch: "The score" at the foot of every note's page opens
`/score/`, a plain list of all eight notes with real links. Every route is crawlable HTML
with its annotation in it.

What sits where, and why:

| Element | Place | Reason (content or action) |
|---|---|---|
| Keyboard render | bottom band, fixed | it is the main input; your hands are there |
| Music desk + ledge (Blender) | behind and under the sheet | the sheet needs something to stand on; the ledge is where small things live on a real piano |
| Sheet | centred on the desk | it is the content |
| Printed header (title, stage, tempo, fingering) | top of the sheet, as engraved | a printed score says what it is in its header |
| Staff, measures 1 and 2 | across the sheet | the eight notes are the eight pages |
| Pencil annotation | written next to the due note, below the staff | it explains that note, so it hangs off that note with a drawn arrow |
| Marks from notes already played | small pencil marks left beside their notes | the copy accumulates, like a practised score |
| Inputs (Sound, Letter keys, Digital piano, Microphone) | on the ledge, below the sheet | they are tools at the instrument, not site navigation |

## Signature element

The pencil marginalia drawn on the real staff geometry of the sheet. Not illustrations beside
text: marks that measure, bracket and point at the printed notes.

- C4: a loop around middle C and the ledger line, "you are here".
Each page is one thing a learner gets from the app, and its drawing shows that thing:

| Note | Page | Drawing | Source of the claim |
|---|---|---|---|
| C4 | `/` Start here | a loop round middle C and its ledger line | the page itself |
| D4 | `/listens/` It listens to your piano | a phone on the music stand hearing the piano; with Microphone on, a line says which note it hears | `lib/audio/` (mobile recorder and the web PCM recorder) |
| E4 | `/marks/` Every note gets a mark | the three marks a note can get: to play, got it, missed (struck through) | `lib/ui/staff/note_glyph.dart` |
| F4 | `/timing/` Right on time | a bracket under F4's beat on the staff, and a beat line with a tap test that marks each tap perfect, good or okay | `lib/engine/stage_engine.dart`, `lib/data/settings_repository.dart` (normal windows) |
| G4 | `/slow-down/` Slow it down | the printed tempo struck through and 40 written beside it; a tortoise, "slow and steady" | `speedSteps` in `lib/ui/practice/transport_column.dart` (0.5x to 2x) |
| A4 | `/plug-in/` Got a digital piano? | a digital piano cabled to a tablet; with Digital piano on, a line names each key it sends | `lib/services/midi_service.dart` (USB and Bluetooth LE on devices, Web MIDI in the browser build) |
| B4 | `/stages/` One step at a time | the three built-in stages as a list, the first ticked | `lib/data/level_repository.dart`, `lib/data/progress_repository.dart` |
| C5 | `/play/` That's a scale | the closing double bar circled, a star, the count of notes you played, and the one link to `/app/` | `/app/` is the Flutter web build |

Timing copy says "perfect, good or okay" because that is what the app shows. It does not tell
the player early or late, so no page claims it does (the site's own tap test may).

## Art direction

Palette. Paper is a cool white (no cream or warm off-white). Graphite is cool grey. The
app's blue marks the due note only; state colours only on noteheads.

| Role | Hex | Use |
|---|---|---|
| lacquer | `#0A0A0B` | page ground behind the renders |
| paper | `#ECEEF1` | the sheet |
| ink | `#141519` | printed staff, notes, title (16.9:1 on paper) |
| graphite | `#4E535C` | pencil annotation text and marks (6.6:1 on paper) |
| graphite-soft | `#60656E` (dark scheme `#575C65`) | words left by earlier notes and stages not yet open (5.0:1 on paper, 4.9:1 on the dimmed paper) |
| due | `#2456C8` | the due note and its ring (app light accent, 5.9:1 on paper) |
| hit / okay / miss | `#1E7A3C` / `#A85F00` / `#B3261E` | notehead states, light-theme values |
| ledge text | `#A3A3AA` | labels on the ledge (7.6:1 on lacquer) |

Type. Three levels on the sheet, big jumps, nothing in between.

| Level | Face | Size desktop / phone | Where |
|---|---|---|---|
| Printed title | Cormorant Garamond 500 | 44 / 30 px, tracking -0.01em | sheet header, centred, once |
| Annotation heading | Cormorant Garamond 600, graphite | 30 / 24 px | top of the pencil note (roman: italic headings are banned) |
| Annotation text | Cormorant Garamond italic 400 | 20 / 18 px, leading 1.45 | pencil note body, measure 34ch |
| Printed small | IBM Plex Sans 400 | 13 px, tabular figures | subtitle line, tempo, measure numbers |
| Ledge | IBM Plex Sans 500 | 13 px | inputs and progress on the ledge |

The pencil note is set in Cormorant italic because a teacher's note is cursive and quick, and
Cormorant italic at 20 px stays readable on paper. The printed header stays roman, so
printed and handwritten never look alike. Numbers in figures are Plex. Music glyphs are
Bravura. No uppercase labels, no monospace, no eyebrow lines.

Space. The sheet is dense where it is printed (header, staff, fingering, tight like an
engraved page) and open where it is margin: the lower half of the sheet is margin on purpose,
because that is where pencil goes. The desk around the sheet is open and dark: the
instrument, not padding.

Lines and labels. Lines exist only where a score has them: staff lines, barlines, ledger
lines, stems, and the pencil marks. No borders around blocks, no cards, no dividers. Labels
appear only as a score has them: measure numbers, fingering numbers, tempo mark.

Shape. The sheet is a rectangle with a real paper edge (a 1 px lighter top edge, a soft
contact shadow on the ledge), no radius. Noteheads are ellipses. Pencil strokes are drawn
paths with a slight wobble and a graphite grain filter; their width varies along the stroke.

## References

| Reference | Still | Craft taken |
|---|---|---|
| Maria Vasilyeva portfolio (Awwwards SOTD, 9 Oct 2026) | `references/vasilyeva-live-1440.png`, `vasilyeva-awwwards.png` | a loose hand-drawn layer (loops, arrows) over strict type, and a switch that hides it |
| Piano Tool practice screen, light theme (golden test image) | `references/app-practice-screen.png` | the composition of the product itself: a score above a keyboard, staff as the largest element |
| Piano Tool staff states (golden) | `references/app-staff-states.png` | the notehead states and the due-note ring, exactly |
| Engraved score practice (domain) | none saved | header layout of a printed score: centred title, tempo top left, fingering above notes, measure numbers at system starts |

Gap: no photograph of a pupil's pencil-marked score was found under a usable licence in the
time given; the pencil vocabulary (loops round notes, arrows, brackets, fingering, ticks)
is common teaching practice and is drawn from that knowledge.

## Motion

GSAP only (core, DrawSVGPlugin, Flip). Native scroll, no ScrollSmoother: the desktop page
does not scroll at all, and the phone page scrolls the sheet natively.

- Strike and ring (kept): key down 60 ms `power4.out`, release `expo.out` 0.5 s.
- Writing: when a note becomes due, its pencil marks draw on in the order a hand would make
  them (arrow first, then the drawing, stroke by stroke, about 0.45 s each, `power1.inOut`),
  and the text lines fade up behind the pen, 70 ms apart.
- Settling: the previous note's annotation shrinks to its leftover mark (a tick, a word) by
  Flip, 0.6 s `expo.out`; the notehead fills with the app's hit glyph.
- Due note: the blue ring keeps the beat at 80 bpm (kept idle behaviour).
- Reduced motion: every mark appears complete, no drawing, no Flip.

Motion values live in `src/motion/params.ts`.

## Responsive

- 1440 x 900: one screen. Keyboard band 24svh (all 61 keys). Sheet up to 1180 px wide, with
  dark desk on both sides. Staff space 26 px.
- 768: keyboard C3 to C6. Sheet full width minus 24 px desk each side. Staff space 20 px.
- 375 / 320: keyboard B3 to D5 (every stage key a 39 px tap target), fixed at the bottom.
  Sheet full width minus 10 px desk; the page scrolls the sheet natively above the band.
  Staff space 9 px so measures 1 and 2 fit; the annotation sits under the staff. The pencil
  word beside F4 is left off; the bracket and the copy carry it.
- Under 900 px the Letter keys switch is hidden: phones and tablets have no letters to type.
- Dark colour scheme: the same sheet under a dimmer lamp. The paper takes an 8% dark overlay
  (about `#D9DCE1`) and the lamp highlight drops, so the page does not glare in a dark room.
  Every text colour stays AA on the dimmer paper; nothing else changes, because the desk is
  already dark.

## Assets

| ID | Route | Output | Status |
|---|---|---|---|
| A1 | blender | music desk panel, lacquer, lamp falloff | cut: its reflections read as grey bands that compete with the sheet; the ground is plain lacquer |
| A2 | blender | ledge strip with the paper groove, `src/assets/desk/ledge.png` (`design/blender/desk.py`) | superseded by A6; not on the page |
| A3 | glaxnimate | pencil mark set: loop, arrow, bracket, tick, underline, dimension, `design/glaxnimate/pencil-marks.svg` | done |
| A4 | glaxnimate | per-note pencil drawings: `listen-sketch.svg` (D4), `tortoise.svg` (G4), `plug-sketch.svg` (A4), `star.svg` (C5), inlined in `src/components/drawings/` | done |
| A4b | inline | E4 marks and the F4 beat line are drawn from the app's glyph rules and timing windows in `src/components/drawings/`, with the A3 pencil vocabulary | done |
| A5 | blender | paper grain tile, `src/assets/desk/paper.png`, 512 px, tileable | done |
| A6 | blender | music rack frame with its ledge, two page clips, and the pencil on the ledge: `rack.png`, `clip.png`, `pencil.png` from `design/blender/desk-props.blend` (Cycles) | done |
| A7 | brand | the mark (middle C circled in pencil) printed before the title like a publisher's device, the favicon, touch icon and `og.jpg`, all from `brand/mark.py`; see `brand/README.md` | done |

## Copy

All annotation copy lives in `src/data/annotations.ts`, 60 words or fewer per note so each
annotation fits the sheet at 1440 x 900 without scrolling. Headings: the home page's printed
title "Piano Tool" is its `h1`; on every other page the annotation heading is the `h1`.
