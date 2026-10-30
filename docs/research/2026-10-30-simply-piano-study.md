# Simply Piano package study for Piano Tool

Reviewed 30 October 2026. Piano Tool source revision:
`21c5d2e2ae6486a0d23f779e7a39785c57e01bcb`.

Simply Piano's most useful reference is its teaching sequence: introduce a
small skill, demonstrate it, let the learner find the notes, then ask them to
play in time. Piano Tool already has much of the input, import, and visual
foundation. The next investment should make each practice attempt teach
something and give the learner a useful next action.

Keep the current music desk, method books, cool paper, and pencil marks.
These can carry a much clearer learning flow without a visual redesign.

## What was inspected

The source was `Simply+Piano_+Learn+Piano+Fast_7.33.10_APKPure.xapk` in the
user's Documents folder. Its manifest identifies package
`com.joytunes.simplypiano`, version `7.33.10`, version code `5293`.

The outer archive and the base, English, and density APKs were unpacked into
`/private/tmp/simply-piano-study-20261030/`. This is temporary working data;
the original XAPK remains the durable source. Analysis covered bundled JSON,
English localization, original gameplay and notation sprite atlases, and
selected DEX class descriptors. No application code was executed, and DEX
method bodies and native recognition libraries were not decompiled.

The bundle contains 48 course definitions, 6,576 level definitions, 3,197 song
definitions, 3,198 library records, 125 journey files, and 158 workout files.
These include legacy, regional, hidden, and experimental variants. They do
not establish the size of the live catalog or the number of unique courses.

The [evidence summary](2026-10-30-simply-piano-evidence.json) records the
archive hash, counts, configuration keys, sources, and verification limits.
The extracted assets remain outside the application repository.

## Lessons from the package

| Observation | Direct package evidence | Implication for Piano Tool |
| --- | --- | --- |
| Lessons mix distinct activities. | `AllLevels.json` contains 44,235 `note_sequence`, 20,436 `moving`, 377 `video`, and 254 `one_note` stages. | Finding notes and maintaining tempo should be separate activities with separate success criteria. |
| Small skills lead into recognizable music. | `TouchCourse1.journey.json` groups an introduction, first notes, another note, and a simplified song. `PianoBasics2Diffix.journey.json` interleaves rhythm, hand skills, reminders, and songs. | Build a small authored path around the existing exercises before growing a large catalog. |
| A lesson carries its teaching context. | Level stages include `instruction`, `tooltipText`, `preListen`, `numRepeats`, and recap fields; melodies distinguish left and right hands and include fingering annotations. | Put the objective and next hint beside the score. Let learners hear the phrase before trying it. |
| Recovery is planned. | `GameConfig.json` sets `failsBeforePracticeMode` to 2 and `hintInvocationInterval` to 4.0; localization includes practice and wait controls. | Offer a slower, shorter retry when a passage is difficult. Treat these values as bundled defaults, not measured live behavior. |
| Input setup checks an action. | `Onboarding9_V2.obfc.json` connects instrument selection to detector primer, indication, and success screens. The indication config asks for repeated strikes of one central key and distinguishes silence from inconsistent pitches. DEX descriptors include the detector fragment and configs. | Confirm an actual incoming note before starting a scored exercise. Permission alone cannot prove that the piano is audible. |
| Musical symbols and feedback have distinct resources. | The viewed notation atlas contains rests, accidentals, and distinct notehead forms. Gameplay resources include feedback and hint elements; drawable resources also name half, whole, and quarter-note states. | Preserve musical notation while adding performance feedback around it. Asset presence alone does not prove a screen uses it. |
| The library connects songs to practice. | `AllLibrarySongs.json` links records to journey prerequisites and explicit `practiceLevels`; workout files contain custom and pooled exercise lists. | Give each piece a related drill and a clear route back to the full piece. |

There are multiple generations of UI resources in the package. Configuration
also names remote services and content. A bundled control, string, or class
does not prove that a particular Android screen currently exposes it.

Simply's [current navigation documentation](https://piano-help.hellosimply.com/en/articles/16945914-simply-piano-song-library-menu-navigation)
is explicit about platform differences. Android's documented song menu has
play, restart, exit, and tempo controls. The iOS section additionally lists
listen, hand selection, waiting with hints, metronome, and finger-number
controls. It also documents dragging through a song in the Song Library,
with that interaction unavailable in Courses. These are useful design
references; this review did not verify their execution in the supplied APK.

## What Piano Tool already has

The roadmap understates the current source. Avoid scheduling these as wholly
new features:

| Capability present in source | Reference |
| --- | --- |
| Continue desk, score preview, recent stage, and book selection | [home_screen.dart](../../lib/ui/home/home_screen.dart), lines 64, 91, 243, and 327 |
| Saved input choice before microphone permission | [mic_permission_gate.dart](../../lib/ui/practice/mic_permission_gate.dart), lines 25 and 90 |
| Starting speed, timing tolerance, theme, input selection, and MIDI connection controls | [settings_screen.dart](../../lib/ui/settings/settings_screen.dart), lines 33, 53, 79, and 323 |
| Import preview synthesis and pitch, duration, and deletion corrections | [review_screen.dart](../../lib/ui/import/review_screen.dart), lines 128, 355, 384, 414, and 617 |
| Grand and bass staff selection, voice assignment, and beat unit | [level_models.dart](../../lib/models/level_models.dart), lines 38 and 61; [practice_screen.dart](../../lib/ui/practice/practice_screen.dart), line 252 |
| Bravura meter glyphs and differentiated hit styles | [staff_painter.dart](../../lib/ui/staff/staff_painter.dart), line 229; [note_glyph.dart](../../lib/ui/staff/note_glyph.dart), line 15 |
| Backend meter candidates for 4/4, 3/4, and 6/8 | [quantize.py](../../backend/app/quantize.py), line 22 |

These are source findings. They do not establish physical instrument
reliability, completed calibration, transcription quality, or current hosted
availability. In particular, the public build intentionally hides import
when its backend credentials are absent, as recorded in the October 29
journal entry.

## Recommended order

### 1. Make the score musically faithful

This should precede more rhythm content. `LevelNote` carries duration and
rest information, but `PlacedNote` carries only MIDI pitch, start beat, and
performance state. Practice discards the other fields when constructing the
score. `NoteGlyph` always draws a stem, and its filled or hollow head depends
on the scoring state.

That makes performance feedback change the apparent musical duration. A
learner cannot reliably distinguish a half note from a quarter note, and
the renderer cannot faithfully represent rests or eighth-note flags from
the current placed-note data.

Carry duration and rest information through layout. Use conventional heads,
stems, flags, dots, and rests for the supported durations. Keep feedback in
an outline, underline, or small mark beside the note, with shape and text
support so it works without color. Add accidentals and spelling information
before expanding beyond the current simple pitch vocabulary.

Evidence: [staff_painter.dart](../../lib/ui/staff/staff_painter.dart), line 9;
[practice_screen.dart](../../lib/ui/practice/practice_screen.dart), line 243;
[note_glyph.dart](../../lib/ui/staff/note_glyph.dart), lines 15 and 96.

Acceptance: an unplayed half note remains a half note after a hit or miss;
quarter, half, eighth, and rest examples remain distinguishable in every
feedback state.

### 2. Add a short, unscored input check

After the existing instrument choice, show a small setup sheet asking the
learner to play a central key. Display the detected pitch and keyboard key
before the transport starts. Distinguish permission granted, device
connected, and a note actually received. Offer retry and an explicit skip.

Use the selected source. MIDI-only setup should verify incoming MIDI without
requesting a microphone. Microphone setup should distinguish silence, a
weak signal, and unstable pitch. Save successful setup for convenience but
check again when the device or input source changes.

The current settings text infers audibility from permission, while
`StageController.onPitch` ignores idle detections. A dedicated unscored
setup view should consume input without starting or altering a score.

Evidence: [settings_screen.dart](../../lib/ui/settings/settings_screen.dart),
line 291; [stage_controller.dart](../../lib/ui/practice/stage_controller.dart),
line 205.

Acceptance: granting microphone permission without playing never reports
that the instrument was heard; MIDI setup succeeds from a real note event.

### 3. Build one useful phrase-practice flow

Let the learner select a short measure range and choose three actions:
listen, learn the notes, or play in time. The timed version gets a count-in;
the note-learning version waits and offers a hint. Add a clear choice of
left hand, right hand, or both when voice data is available. Keep the
current speed control, but show the resulting BPM alongside its multiplier.

On the desk, draw a bracket under the selected measures and place its
actions on the sheet. Keep transport controls stable while playing; put
less-used choices in the paused state. Reuse the existing synthesizer for
demonstration, with microphone scoring suspended during playback.

Start with explicit user selection. After repeated unsuccessful attempts,
offer to slow down or practise the difficult phrase. Keep assistance
visible and reversible. Store note-learning completion separately from
timed performance so waiting cannot inflate a timing score.

Existing seek support is not a complete loop implementation.
`seekToBeat` changes note states and position but preserves `_noteResults`
and accumulated score. Define a fresh attempt for each loop and restrict
scoring to the selected range before exposing repeat controls.

Evidence: [transport_column.dart](../../lib/ui/practice/transport_column.dart),
line 60; [stage_controller.dart](../../lib/ui/practice/stage_controller.dart),
line 241; [stage_engine.dart](../../lib/engine/stage_engine.dart), lines 213
and 431; [review_screen.dart](../../lib/ui/import/review_screen.dart), line 617.

Acceptance: three repeats produce three valid phrase attempts without
double counting, inherited misses, or scoring excluded measures. The
count-in respects the meter and selected tempo.

### 4. Turn the results sheet into the next lesson

Keep the marked paper and add one useful observation, a miniature view of
the difficult measures, and a primary action to practise that range. On a
successful run, offer the next available stage. Keep replay and the route
back to the desk as secondary actions.

The engine already calculates signed timing errors and emits note results.
`StageResult` retains only aggregate score, accuracy, and note counts. Carry
the minimum note-level information into results and derive a plain-language
observation from that data. For example, identify repeated late entries
only when the events support that claim. Distinguish a missed expected note
from a confirmed wrong pitch; the existing scorer does not classify every
unexpected note as an error.

Evidence: [stage_engine.dart](../../lib/engine/stage_engine.dart), lines 162,
213, and 254; [results_screen.dart](../../lib/ui/results/results_screen.dart),
lines 10, 113, and 164.

Acceptance: the recommended range comes from the completed attempt, and
opening it resets practice correctly. An empty or abandoned attempt does
not generate invented coaching.

### 5. Author a small beginner method book

The current built-in content is a scale, an Ode to Joy excerpt, and a mixed
rhythm study. Add a short path: find middle C, play C-D-E, read a rest, hold
a half note, play a two-bar phrase, then try the existing melody and scale.
Give each activity one objective, a demonstration, and a useful fallback.

Reuse stages and prerequisites first. Add a small lesson-step model only
when mixing demonstrations and exercises requires it. Optional finger hints
can come from authored lesson metadata; imported MIDI pitches cannot
determine correct fingering on their own.

Keep method books on the shelf. Inside a book, show the next activity and a
short contents list with completed and available entries. Keep imported
pieces in their existing visual family, with phrase drills attached to the
piece. A broad genre browser has little value while the catalog is small.

Evidence: [level_repository.dart](../../lib/data/level_repository.dart),
line 471; [level_models.dart](../../lib/models/level_models.dart), line 74.

### 6. Make progress reflect a skill at a tempo

Begin with recent phrase errors and the tempo of successful timed attempts.
Use that to populate one suggested activity on the Continue sheet. A useful
record is the exercise, selected range and hand, mode, tempo, result, and
date. A small bounded history is enough for this first version.

Current progress stores best accuracy, best score, attempts, completion, and
dates. A best score earned slowly cannot establish readiness at the target
tempo. Keep practice completion, assisted performance, and timed performance
distinguishable. Avoid adding a general analytics system for this decision.

Evidence: [progress_repository.dart](../../lib/data/progress_repository.dart),
line 78; [level_models.dart](../../lib/models/level_models.dart), line 92.

Simply's [practice guidance](https://piano-help.hellosimply.com/en/articles/2791126-best-practice-tips)
supports measurable session goals, repeating passages, reducing tempo, and
practising one hand at a time. Piano Tool can make those actions directly
available from its results and Continue screens.

## Scoring constraints before advanced lessons

Repeated notes need fresh-strike handling. The current engine matches pitch
against the current beat; it does not require a new onset. The October 25
journal records that a sustained pitch can still score another occurrence
when its timing window opens. Preserve MIDI note-on identity and evaluate
microphone onset detection before claiming reliable repeated-note drills.

Grand staff rendering and voice metadata do not establish polyphonic
microphone recognition. YIN estimates a fundamental pitch. Verify chord and
simultaneous-note behavior separately before offering scored acoustic
chord lessons. If a future lesson requires MIDI, state that at selection.

Simply's package has retrigger thresholds, device-latency data, and native
audio and inference libraries. Those show that it accommodates input
complexity; they do not reveal a validated algorithm or justify copying its
threshold values into a different audio pipeline.

## Suggested implementation slices

1. **Trust the exercise:** correct duration/rest engraving and add the
   unscored instrument check. Check repeated-note behavior before adding
   repeated-note teaching content.
2. **Practise the difficult passage:** implement clean phrase attempts,
   demonstration, count-in, and results-to-phrase navigation. Add waiting
   with hints after the attempt and transport semantics are sound.
3. **Teach a short path:** author the beginner book and use bounded attempt
   history to choose the next exercise. Add optional fingering and hand
   selection where the content supports them.

These are proposals, not implementation commitments. The application,
roadmap checkboxes, website, and linked worktrees were not changed during
this study. OMR and source separation remain separate ingestion work.

## Verification limits

The package data and cited source were inspected directly. No Simply Piano
Android session was launched, and no active remote configuration, animation
timing, recognition accuracy, or physical instrument behavior was measured.
The existing practice golden was viewed, but it predates the October 29 desk
design and is historical evidence only. The current visual direction is
supported by source and journal, with fresh rendered review still pending.

Future implementation needs rendered checks at phone and tablet sizes,
keyboard and assistive-technology checks, representative musical notation,
and real microphone/MIDI verification. This research did not run builds or
test suites because it changes no application behavior.
