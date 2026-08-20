# Piano Tool

> **Interactive piano practice tutor with real-time pitch detection.** Scrolls sheet music, listens via your device's microphone, and scores your notes as you play.

## 💡 What is Piano Tool?

Learning to read sheet music on a real piano requires immediate feedback on whether you hit the right key at the right tempo. 

Piano Tool acts as an interactive music coach on your tablet or phone. It displays scrolling musical staves and an on-screen keyboard, listens to your acoustic or digital piano through the microphone, and instantly marks notes as correct or missed while tracking your timing accuracy.

## Project Status

The core practice foundation is fully functional:
- **Scrolling Staff Renderer**: Clean musical notation rendering notes, measures, and active playheads.
- **Audio Pitch Detection**: Real-time microphone listening that matches played frequencies to musical notes.
- **Practice Screen & Transport**: Interactive controls for tempo adjustment, replay, score calculation, and keyboard visualization.

## Where the levels actually come from

Read this before touching level content, because the obvious answer is wrong.

Levels are **hardcoded in Dart**, in `lib/data/level_repository.dart`
(`_loadBuiltInLevels`). There is no JSON asset pipeline: an earlier version of
this app read `manifest.json` and `stages.json` from `assets/levels/`, neither
of which ever existed, and silently fell back to these same built-in levels
every time. That dead code path, and the `assets/levels/twinkle_twinkle.json`
fixture that went with it, are gone.

`LevelRepository` exposes three stages through `getAllStages()`: `stage_1`,
`stage_2`, and `stage_3`, a C major scale, a simple melody, and a mixed rhythm
study, with `stage_2` and `stage_3` gated behind their predecessor via
`prerequisites`. Trust `lib/models/level_models.dart` for the data model and
`lib/data/level_repository.dart` for the actual content.

## Architecture

```text
lib/
├── main.dart                     App entry, theme, landscape lock
├── models/                       Freezed data models and JSON serialisation
│   ├── level_models.dart         LevelNote, LevelMeasure, LevelModel, StageModel
│   ├── audio_models.dart         PitchEvent, AudioEngineConfig
│   └── engine_models.dart        NoteState, StageEvent, StageEngineStateModel
├── data/
│   ├── level_repository.dart     Hardcoded levels (see the section above)
│   └── progress_repository.dart  Per-stage score/accuracy, via shared_preferences
├── audio/
│   ├── pitch_detector.dart       YIN fundamental frequency estimator
│   └── audio_engine.dart         Microphone permission and pitch stream
├── engine/
│   └── stage_engine.dart         Pitch matching, scoring, playback state
└── ui/
    ├── theme/
    │   ├── tokens.dart           Colour, spacing, and motion tokens
    │   └── app_theme.dart        Material 3 themes built from the tokens
    ├── staff/
    │   ├── staff_geometry.dart   Clef, and every measurement in staff-spaces
    │   ├── note_glyph.dart       Notehead shapes per note state
    │   ├── staff_painter.dart    One staff system: lines, clef, notes, playhead
    │   └── staff_view.dart       One or more systems stacked
    ├── keyboard/
    │   ├── keyboard_geometry.dart    Key layout math, independent of widgets
    │   └── piano_keyboard_view.dart  The 61 key visualisation
    └── practice/
        ├── practice_screen.dart      The practice loop: HUD, staff, keyboard, transport
        ├── stage_controller.dart     Riverpod glue between StageEngine and the screen
        ├── mic_permission_gate.dart  Blocks the screen until the microphone is granted
        ├── practice_hud.dart         Title, tempo, score, accuracy, progress
        └── transport_column.dart     Play/pause, Stop, Replay, speed control
```

## The data model

A note is a MIDI number and a position in beats. There is no pitch name, no
octave field, and no clef.

```dart
LevelNote(
  midiNote: 60,        // C4
  startBeat: 0,
  durationBeats: 1,
  measureIndex: 0,
  beatIndex: 0,
)
```

`LevelModel` carries `tempo`, `beatsPerMeasure`, `totalMeasures`, its measures,
and a `clefOctave` plus `transpose`. It does not carry a clef. `Clef` is a
rendering concept and lives in `lib/ui/staff/staff_geometry.dart`, because the
renderer is told which clef to draw rather than reading it from the level.

`NoteState` has six values: `upcoming`, `active`, `hitPerfect`, `hitGood`,
`hitOkay`, `missed`. The staff draws the three hit gradations identically.

## How notes are drawn

Every measurement derives from the staff's own height. One staff space is a
quarter of it. Noteheads are one space tall, the time signature is four, stems
are about two. Halving the staff halves everything, which is why a grand staff
needs no separate code path: it is two systems, not a special case.

Note state is carried by shape before colour. Upcoming is a hollow hairline,
the note currently due is filled with a ring, a hit is filled solid, and a miss
is hollow with a slash struck through it. Filled against hollow noteheads is
real notation, and it means the display still works for red-green colour
blindness, which affects roughly one man in twelve.

Clefs are drawn from bundled Bravura, the SMuFL reference font. Unicode clef
codepoints render from whatever font the operating system supplies, land in the
wrong vertical position, and are missing outright on some Android builds.

## Pitch detection

`PitchDetector` implements the YIN estimator: a difference function, cumulative
mean normalisation, the first dip below a 0.1 threshold, parabolic interpolation
for sub-sample accuracy, and an autocorrelation confidence score.

Defaults live in `AudioEngineConfig` (`lib/models/audio_models.dart`): 44.1kHz
and a 2048 sample buffer. The 80Hz to 1000Hz detection gate is not one of
those defaults; it is hardcoded in `PitchDetector.processBuffer`
(`lib/audio/pitch_detector.dart`), not configurable through `AudioEngineConfig`
at all. There is no cent-tolerance field anywhere in the config; pitch
matching accuracy is a property of the scoring engine, not of detection.

## Fonts

Three families are bundled under `assets/fonts/`, all free under the OFL.
Cormorant Garamond carries titles, IBM Plex Sans carries body text and every
metric, and Bravura carries music glyphs. Cormorant and Plex are variable fonts
registered with one asset each and no weight entries, so weight is selected
through `fontVariations` on the `wght` axis rather than by file.

They are bundled rather than fetched through `google_fonts` so that golden tests
do not depend on the network and the app works offline from first launch.

## Building and testing

Builds and tests run on a Linux ARM64 VM, not on the development Mac, so no
build artifacts land locally.

```bash
verify-on-vm "<path to this repo>" "flutter test"
verify-on-vm "<path to this repo>" "flutter analyze --no-fatal-infos"
```

119 tests pass. `flutter analyze` reports 63 infos and 1 pre-existing warning,
64 issues in total.

Golden tests are skipped off Linux. Font rasterisation differs by host and
Flutter's default comparator is byte exact, so the images are generated and
checked on the same platform.

`test/flutter_test_config.dart` loads four fonts before any test runs: the
three bundled families above, plus the Flutter SDK's own MaterialIcons, read
from disk since it ships with the SDK rather than this package's assets.
Without it, Flutter renders text as empty boxes and golden images silently bake
in missing glyphs. An earlier set of goldens passed every test while showing
black rectangles where the clef and time signature belonged.

Regenerating goldens, in this order, because the sync to the VM deletes first:

```bash
verify-on-vm "<repo>" "flutter test --update-goldens"
rsync -a ampere-dev:work/verify/piano-tool/test/ui/staff/goldens/ test/ui/staff/goldens/
verify-on-vm "<repo>" "flutter test"
```

Then look at the images. Twice now, a defect that every test passed was caught
only by opening the PNG.

## Platform notes

Android needs `RECORD_AUDIO` and a minimum SDK of 24. iOS needs
`NSMicrophoneUsageDescription` and iOS 12.

Android build tooling does not ship for Linux ARM64, so the VM can run every
test but cannot currently produce an APK.

## Still to build

Home, level select, results, and settings screens, and the router that
connects them to the practice screen. Nothing navigates between stages yet;
`PracticeScreen` is reachable today only by passing a `stageId` directly.
