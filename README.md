<picture>
  <source media="(prefers-color-scheme: dark)" srcset="brand/mark-dark.svg">
  <img src="brand/mark.svg" width="72" height="72" alt="Piano Tool mark: middle C circled in pencil">
</picture>

# Piano Tool

> **Interactive piano practice tutor with real-time pitch detection.** Scrolls sheet music, listens via your device's microphone, and scores your notes as you play.

## 💡 What is Piano Tool?

When learning to read sheet music at a piano, feedback on the notes and timing can help guide practice.

Piano Tool is designed as an interactive music coach for a tablet or phone. It displays scrolling musical staves and an on-screen keyboard, listens to an acoustic or digital piano through the microphone, and marks notes as correct or missed while tracking timing.

## Project Status

The interface is being redesigned from scratch. On this branch the old
screens, widgets, theme, art and fonts have been removed, and the app opens to
a blank screen. What remains is the part that does not depend on how the app
looks: pitch detection, MIDI input, the stage engine and scoring, levels and
imports, saved progress and settings, and the stage controller that ties them
together.

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
├── main.dart                     App entry; no interface yet
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
└── practice/
    └── stage_controller.dart     Riverpod glue between StageEngine, input and progress
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
and a `clefOctave` plus `transpose`. It does not carry a clef; the
interface decides which clef to draw.

`NoteState` has six values: `upcoming`, `active`, `hitPerfect`, `hitGood`,
`hitOkay`, `missed`.

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

## Building and testing

Flutter tests and analysis run on the Linux ARM64 verifier, not on the
development Mac. Android APK packaging and emulator checks run in the pinned
x86_64 GitHub Actions job, so no build artifacts land locally.

```bash
verify-on-vm "<path to this repo>" "flutter test"
verify-on-vm "<path to this repo>" "flutter analyze --no-fatal-infos"
```

The current suite is verified in CI and on the remote Linux ARM64 verifier.
Run the complete Flutter suite and analyzer with the commands above. Release
builds require an explicit `INGESTION_API_BASE_URL` and
`INGESTION_API_TOKEN`; release builds require the API URL to use HTTPS.

The ingestion backend is a persistent FastAPI service with a separate worker.
Run the API from `backend` with `python -m uvicorn app.main:app` and the worker
with `python -m app.worker`. Job endpoints require a bearer token; `/health`
is unauthenticated and `/ready` checks runtime dependencies.

## Platform notes

Android needs `RECORD_AUDIO` and a minimum SDK of 24. iOS needs
`NSMicrophoneUsageDescription` and iOS 12.

Android build tooling does not ship for Linux ARM64. The GitHub Actions Android
job builds `piano-tool-debug-apk` and smoke-tests it on an x86_64 emulator.

## Still to build

The whole interface: home, import and review, practice, results and settings.
