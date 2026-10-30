# Piano Tool Roadmap

Piano Tool should feel like an expressive music desk that helps a learner
understand the score, practise a difficult passage, and know what to try next.

Updated 30 October 2026 from the
[Simply Piano study](docs/research/2026-10-30-simply-piano-study.md), its
[evidence summary](docs/research/2026-10-30-simply-piano-evidence.json), and
the follow-up UI review. Keep the music desk, method books, cool paper,
lacquer, and blue pencil identity. Improve composition, tactile response,
and continuity throughout the practice journey.

## Implemented foundation

These capabilities are present in the reviewed source. Checked items record
implementation; they do not certify current hosted behavior, physical input
reliability, or completed musical validation.

- [x] **Continue desk and navigation:** Current lesson, opening score preview,
  recent progress, method-book selection, and conditional import access.
- [x] **Learner settings and input choice:** Saved starting speed, timing
  tolerance, light/dark appearance, and microphone or digital piano selection
  before requesting input access.
- [x] **Microphone and MIDI input implementations:** Web audio capture,
  native recording, Web MIDI, and native USB/Bluetooth MIDI integration.
- [x] **Import review playback and corrections:** Synthesized preview,
  pitch and duration editing, and false-note deletion.
- [x] **Staff foundation:** Grand and bass staff selection, brace, voice
  assignment, Bravura time signatures, and differentiated hit feedback.
- [x] **Meter candidates:** Backend quantization supports 4/4, 3/4, and 6/8.
- [x] **Visual foundation:** Rendered keyboard and cloth covers, paper
  surfaces, pencil marks, book lift interactions, and pencil draw animations.

## v1.1: Trust the exercise and bring practice to life

Start with one complete journey: select a book, play a phrase, and receive a
marked sheet. Develop the visual improvements alongside notation and input
reliability so the interaction is both expressive and accurate.

### Musical notation and scoring

- [x] **Faithful rhythm engraving:** Carry `durationBeats` and `isRest`
  through `PlacedNote` and staff layout. Draw conventional whole, half,
  quarter, and eighth notes, dots, flags, and rests for supported content.
  Rests are derived from the gaps in each measure. Ties across a barline
  are not engraved yet; such a note is written up to the barline.
- [x] **Separate notation from feedback:** Keep the musical notehead intact
  when a note becomes active, hit, or missed. Use an outline, underline, or
  adjacent mark for performance state, with shape/text support beyond color.
  A half note must remain recognizable before and after scoring.
- [x] **Accidentals and note spelling:** Preserve the written pitch needed
  for sharps, flats, and later key signatures before expanding the lesson
  vocabulary. MIDI pitch alone does not encode enharmonic spelling.
  `LevelNote.alter` carries an authored spelling; black keys default to
  sharps. Key signatures remain.
- [ ] **Fresh strikes for repeated notes:** Preserve MIDI note-on identity
  and evaluate microphone onset detection. A held or decaying pitch must not
  score the next repeated note solely because its timing window opens.
  Implemented: MIDI note-ons are strikes, and microphone frames start a
  strike on a pitch change, a silence, or a swell. The microphone
  thresholds still need evaluation on real pianos.
- [ ] **Honest polyphony support:** Verify simultaneous-note matching and
  chord behavior separately from grand staff rendering. The microphone's
  YIN detector estimates a fundamental pitch; require and label MIDI for
  lessons that need capabilities the acoustic path cannot yet verify.

### Instrument setup and calibration

- [x] **Unscored input check:** After the existing source choice, ask for a
  central key and show the incoming pitch and corresponding keyboard key.
  Distinguish permission granted, a device connected, and a note received.
  Provide retry and explicit skip; repeat the check after device changes.
- [x] **Useful input diagnostics:** Distinguish silence, weak signal, and
  unstable pitch. MIDI-only setup must remain free of microphone requests.
  Permission alone must not display a claim that the piano was heard.
- [ ] **Measured calibration:** Validate input latency, microphone threshold,
  and reference tuning with representative hardware. Keep timing tolerance
  separate from pitch tuning, and calibrate before generating timing advice.
  Do not copy another app's device offsets or recognition thresholds.

### UI composition and response

- [x] **A stronger home composition:** Make the current lesson an open
  method book with its score visible; arrange the remaining books as a
  smaller collection. Use deliberate scale and spacing. Retain the
  distinction for imported pieces and avoid an equal-card dashboard.
- [ ] **Lesson illustrations:** Original artwork tied to each lesson,
  authored in Blender or Glaxnimate, for the open book's pages.
- [x] **Clearer material and color hierarchy:** Strengthen separation between
  lacquer, cool neutral paper, cloth covers, and blue pencil actions. Give
  the current lesson the richest emphasis. Preserve contrast and avoid
  cream surfaces or decoration that competes with reading.
- [x] **A practice composition built around playing:** Rebalance the existing
  control column, metrics strip, score, and keyboard. Give the current
  musical task priority; keep controls stable while playing and move
  secondary choices into the paused state.
- [x] **Book-to-score continuity:** Carry the selected book into its practice
  sheet; mark that sheet on completion and reflect the result on the book
  when returning to the desk. Keep navigation usable throughout and provide
  immediate equivalent states with reduced motion.
- [x] **Tactile musical feedback:** Add a brief press/release response to
  detected keys, a restrained completion treatment around notes, and a
  pencil acknowledgement when a measure is resolved successfully. Keep
  notation steady and distinguish completion from successful playing.
- [x] **A readable keyboard range:** Offer a closer view of the relevant
  octave or two, clear target/played-key states, and optional note labels.
  Retain full-keyboard orientation and explicit range navigation. Avoid
  automatic viewport shifts while the learner is reading.
- [x] **An expressive results sheet:** Draw the accuracy circle and place a
  completion star once when earned. Annotate the actual difficult passage
  and carry the marked score into the next action. Keep summary text visible
  without waiting for animation; avoid persistent celebratory loops.

## v1.2: Short phrase practice and useful results

### Practice transport and assistance

- [ ] **Measure selection and repeat:** Let learners select a short range,
  seek within it, and repeat it. Scope scoring to that range and define a
  fresh attempt for each repeat. `seekToBeat` currently preserves note
  results and accumulated score, so wiring it directly to a loop is unsafe.
- [ ] **Listen first:** Reuse the existing synthesizer to demonstrate a
  selected phrase. Suspend microphone scoring during demonstration so
  playback cannot score itself; restore the learner's selected input.
- [ ] **Learn notes and play in time:** Provide distinct waiting and timed
  modes. Waiting offers contextual hints without awarding a timed score.
  Preserve notation and accessible state information in both modes.
- [ ] **Count-in and metronome:** Add an optional count-in and beat reference
  that follow the selected tempo and meter, including appropriate 6/8
  grouping. Show effective BPM alongside the existing speed multiplier.
- [ ] **Hand selection:** Offer left, right, or both hands where authored
  voice data supports it. Filter playback, hints, and scoring consistently;
  identify content whose hand assignment is unknown.
- [ ] **Assistance after difficulty:** After repeated unsuccessful attempts,
  offer a shorter phrase or slower speed with a clear way back. Keep the
  change visible and reversible; do not silently change mode or tempo.

### Coaching and progress

- [ ] **Preserve attempt detail:** Carry note results and signed timing errors
  into the results flow. Separate a missed expected note from a confirmed
  wrong pitch; the current scorer does not classify every unexpected pitch.
- [ ] **Results that lead somewhere:** Derive a specific observation and
  difficult measure range from the completed attempt. Offer practice of
  that range, or the next available stage after success. Keep replay and
  return-to-desk actions. Empty or abandoned attempts must not invent advice.
- [ ] **Mastery at a tempo:** Store a bounded history of exercise, range,
  hand, mode, tempo, result, and date. Distinguish assisted completion from
  timed performance; a high score earned slowly does not establish target
  tempo readiness. Preserve existing bests during any storage migration.
- [ ] **A useful Continue suggestion:** Use recent phrase errors and
  successful tempos to suggest one activity on the current lesson sheet.
  Start with a small deterministic rule and a measurable session goal.

## v1.3: A small authored learning path

- [ ] **Beginner method book:** Teach middle C, C-D-E, a rest, a half note,
  and a two-bar phrase before the existing melody and scale. Each activity
  gets one objective, a demonstration, and a useful fallback.
- [ ] **Lessons inside the books:** Show the next activity and a short
  contents list with completed and available entries. Reuse existing stages
  and prerequisites before adding a more general lesson-step model.
- [ ] **Contextual hints and fingering:** Provide optional authored finger
  numbers, hand-position guidance, and an explanation beside the score.
  Let learners hide hints as they progress. Do not infer correct fingering
  from imported pitches alone.
- [ ] **Piece-to-drill links:** Attach useful short exercises to a piece and
  return learners to the full piece afterward. Keep imported pieces distinct
  and defer a broad genre browser until the catalog warrants it.
- [ ] **Broader meter validation:** Check notation, count-in, quantization,
  and scoring together for 3/4 and 6/8 before adding other compound meters.
- [ ] **Retention and ear training:** Add spaced repetition and interval
  exercises after phrase attempts and tempo-aware history provide a useful
  foundation. Prefer clear recall goals over streak pressure.

## v2.0: Sheet music OMR and advanced ingestion

- [ ] **Optical music recognition:** Extend the feasibility work into a
  photograph/scan-to-level pipeline using Audiveris and MusicXML, with review
  and correction before practice.
- [ ] **Source separation:** Evaluate piano isolation from mixed recordings
  before Basic Pitch inference. Compare transcription quality with and
  without separation on representative examples.
- [ ] **Import editing beyond current controls:** Evaluate start-time,
  measure-boundary, hand/voice, and notation corrections as real imports
  expose gaps. Pitch, duration, and deletion controls already exist.

## Validation and delivery gates

- [ ] **Rendered UI review:** Capture the book-to-practice-to-results journey
  on current builds at phone and tablet sizes, including 320, 375, 414, and
  768 px widths, landscape layouts, and larger text. Assess hierarchy,
  keyboard legibility, clipping, material contrast, and transition continuity.
  Done so far: Chromium captures at 1280x800, 844x390 and 375x812 in light
  and dark. The sheet's flight between screens is covered by widget tests
  only; headless rendering without a GPU drops every frame of it.
- [ ] **Accessible interaction and motion:** Verify keyboard/focus behavior,
  assistive-technology labels, non-color feedback, contrast, and reduced
  motion. Every animation needs a useful static equivalent. Use existing
  Flutter motion support where it fits; author original 3D assets in Blender
  and vector art/animation in Glaxnimate.
- [ ] **Musical and attempt checks:** Cover duration/rest engraving through
  every feedback state, repeated notes, range boundaries, replay resets,
  tempo changes, hand filtering, and waiting versus timed scoring. Repeating
  a phrase must not inherit results or double count earlier hits.
- [ ] **Physical input checks:** Verify acoustic microphone, USB MIDI, and
  Bluetooth MIDI on supported devices/browsers. Record platform limits,
  denied access, disconnect/reconnect behavior, and background/resume cases.
  Synthetic input proof does not establish physical instrument reliability.

The current research is static package and source inspection. The supplied
Android app was not launched. Bundled variants do not establish active
features, and Simply's documentation distinguishes Android and iOS controls.
Fresh hosted UI capture failed during the follow-up review; the older
practice golden predates the current desk treatment. Fresh rendering and
motion review remain required before accepting the proposed UI work.

## Out of scope

- Real-time client-side neural transcription; Basic Pitch remains a backend
  ingestion capability.
- Public cloud multi-tenant hosting, commercial microtransactions, and public
  social leaderboards.
- Reintroducing backend tokens or engine internals into learner settings.
  Backend configuration remains separate from instrument setup.
- Replacing the existing identity with Simply Piano's artwork, a copied
  screen structure, or a generic colorful course dashboard.
- A large catalog, generalized analytics framework, or extra animation
  dependencies before concrete content and interaction needs justify them.

For technical specifications, see [docs/specs/](docs/specs/). The October 29
journal decisions supersede the original UI specification's warm palette
and engine-heavy settings direction.
