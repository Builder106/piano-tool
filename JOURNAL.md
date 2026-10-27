# Journal

## 2026-10-27: Check and build the Astro site in CI #ci #decision

The Flutter CI job now runs `npm ci`, a production dependency audit, `npm run check`, and `npm run build` in `site/`. A macOS job also builds the iOS target without code signing.

## 2026-10-26: bound CI job runtimes #ci #deployment

Dependabot PR #23 was the first bot merge after the deployment handoff landed.
Auto-Merge dispatched CI for merge `a5ff746` as designed. That run then stalled
for over 20 minutes in the Python job's `apt-get` step, which normally takes
under a minute. The job had no timeout, so it could have held deployment for
GitHub's six-hour default. After a cancel and rerun, the dispatched run passed
and its deploy hook published `a5ff746`. Vercel reports that deployment ready.
The handoff now has a live end-to-end check.

Every CI and Auto-Merge job now has a timeout. Flutter and Python get 15
minutes, and both usually finish in two. The short jobs get 5. Android keeps 20
and deploy keeps 10. A stalled step now fails the run in minutes.

The dispatch call logs a REST API deprecation notice for the 2022-11-28 API
version, with removal scheduled for 10 March 2028.

On Linux ARM64, actionlint and all 15 workflow regression tests passed.

## 2026-10-26: verify bot merges before deployment #ci #deployment #decision

PR #26 merged through the repository's `GITHUB_TOKEN`. GitHub suppresses push
workflows caused by that token, so the merge never reached the CI job that
calls the production deploy hook. Production was deployed separately at
`fe561fc` and its app route returned HTTP 200.

Auto-Merge now handles successful PR CI completion as well. It waits briefly
for auto-merge, confirms that the tested PR belongs to this repository and its
merge is still the default-branch head, then requests CI
with `workflow_dispatch`. GitHub permits that event with `GITHUB_TOKEN`.
An existing push or manual CI run for the merge prevents another dispatch.
Failed checks, forked PRs, updated heads and older merges cannot dispatch it.

The handler checks out only the default branch and does not consume PR code or
artifacts with its write token. No additional credential is required. The CI
summary now waits for the Android build and emulator check, plus workflow
regression checks, before permitting a production deployment.

On Linux ARM64, all 15 workflow regression tests and 262 Flutter tests passed.
The Flutter analyzer, Dart formatting check and actionlint also passed. The
live handoff still needs a published merge to verify it end to end.

A production browser check opened MIDI-only practice with microphone access
deliberately unavailable. The Play button appeared with zero microphone
requests and no browser errors. The capture is in `docs/evidence/web-mic-midi/`.
Physical input verification remains pending because no instrument is available
for this session.

## 2026-10-25: finish MIDI-only and repeated-note practice #audio #midi #decision

MIDI-only practice still required microphone permission, so a denied microphone
blocked an otherwise connected keyboard. The practice gate now skips microphone
setup in MIDI-only mode. Microphone and dual-input modes still request access.

The audio engine also used its default volume threshold and reference frequency
even though settings stored both values. It now reads the settings-derived audio
configuration. The app loads saved settings before building its providers, so a
saved MIDI-only choice cannot trigger an early microphone request and the audio
engine starts with the saved threshold.

A held pitch could mark the next note of the same pitch missed before its beat.
The scorer now ignores events earlier than the playable window, leaving the
note available when its window opens. The pitch stream has no note-onset signal,
so a held pitch can still score the next note once that window opens.

On Linux ARM64, the Flutter analyzer, formatting check, all 262 Flutter tests,
and release web build passed. Hardware input was not retested.

## 2026-10-25: real microphone and MIDI input on the web and devices #audio #midi #web #decision

The hosted web app never reached a practice screen. The build has no
`INGESTION_API_TOKEN`, so `ingestionRepositoryProvider` throws a
`FormatException`, and Riverpod 3 retries a failed provider up to 10 times,
about 38 seconds in all. `levelRepositoryProvider` awaits it, so the first
screen showed a spinner the whole time. A missing build setting won't fix
itself on retry, so the ingestion provider now sets `retry` to return null.

flutter_sound's web recorder does not give usable 16-bit PCM at the requested
rate. In headless Chromium, with a fake microphone playing the stage 1 scale, it
scored nothing and lit the wrong key. The web build now uses `WebPcmRecorder`.
It opens the microphone with getUserMedia, with echo cancellation, noise
suppression and gain control turned off. An AudioWorklet loaded from a Blob URL
posts 1024-frame batches, and `PcmFrameConverter` resamples them to the
detector's 44.1 kHz. Without the resample, 48 kHz audio reads 1.5 semitones
flat and C4 comes out as B3. A conditional import picks the recorder, so phones
and desktops keep `FlutterSoundPcmRecorder`. The YIN code is unchanged.

`StageEngine` used to add 16 ms of beat on every timer tick. A late tick lost
time, so the playhead fell behind the music whenever frames ran long. On the
verifier the transport ran at half speed or less. The playhead now follows a
`clock.stopwatch()` from the beat it starts at, and a seek during playback
re-anchors it. package:clock means fake time in widget tests moves the playhead
too.

MIDI input uses flutter_midi_command 1.4.0 with flutter_midi_command_ble. Both
are BSD-3-Clause from a verified publisher, released 2026-10-09. They cover
CoreMIDI on iOS and macOS, Android MIDI, and Bluetooth LE through universal_ble.
On the web, `WebMidiTransport` calls `navigator.requestMIDIAccess` through
package:web. A browser can't pair Bluetooth MIDI, so a keyboard has to be paired
in the system settings first. Safari has no Web MIDI. The plugin delivers one
complete message per packet, and each one goes straight to `handleMidiBytes`.
Nothing is opened until the player presses Scan.

`midiPitchStreamProvider` watched the whole `MidiService`. Every message calls
`notifyListeners` before its pitch is emitted, so the provider rebuilt and
dropped the note that caused the rebuild. No MIDI key could ever score. The
provider now selects the stream.

macOS had no microphone usage description or audio-input entitlement. Both are
added, along with the Bluetooth keys the BLE package asks for on iOS and macOS.

Verification ran in headless Chromium on the Linux ARM64 verifier. Web MIDI
scored 16 of 16 from a virtual ALSA keyboard. The microphone scored between 7
and 15 of 16 across four runs. The host has no GPU, so software rendering fills
the main thread, and the notes that miss are the ones queued behind it. A silent
control run showed the same backlog. Real Bluetooth and USB keyboards have not
been tested.

## 2026-10-25: host showcase at root and flutter web at /app/ #deployment #web #decision

Consolidated deployment into the primary `piano-tool` project on Vercel to serve the Astro showcase at `/` and the Flutter web app under `/app/`. Switched the HTTPS gate in `ingestion_repository.dart` from `bool.fromEnvironment('dart.vm.product')` to `kReleaseMode`, which fixes the web startup exception. Made ingestion initialization optional so web visitors can practice built-in stages without backend service credentials. Updated `scripts/build_web.sh` to assemble both builds into `build/web` and added an SPA rewrite in `vercel.json` for `/app/`.

## 2026-10-25: add the showcase site in site/ #web #design #decision

Added a showcase site under `site/`, built with Astro 7 and GSAP. It is separate
from the Flutter web build that Vercel serves from the repository root. The site
is stage one of the app: the C major scale from `level_1`, with one page per
note. You move to the next page by playing the next note. That can be a click on
the keyboard, the letters A to K, a Web MIDI keyboard, or your own piano through
the microphone, heard by a browser port of the YIN code in `PitchDetector`. The
staff draws noteheads with the rules in `note_glyph.dart`, so a note you have
played turns into a filled head.

The keyboard is a Blender render of the app's 61 key range, C2 to C7, built by
`site/design/blender/keyboard.py`. Each key of the stage octave also has a
pressed render, and a geometry file places the hit areas on the right pixels.
The noteheads and figures were drawn in Glaxnimate and sit in
`site/design/glaxnimate/`. The YIN figure on the D4 page is real output:
`yin_figure_data.py` runs the same algorithm on a synthesized 440 Hz tone.

The browser detector gates volume at an RMS of 0.01 instead of the app's 0.1.
Browser microphones arrive quieter than the app's recorder, and the level
depends on the device. Every other threshold matches the app.

Builds and QA ran on the Linux ARM64 verifier, with output kept outside the
checkout. The last pass had no audit failures, no axe violations and no
horizontal overflow, a mobile CLS of 0.001, and 60 fps scrolling on the
throttled phone profile. The production URL in `site/src/data/site.ts` is a
placeholder until there is a deploy target.

## 2026-10-21: implement v1.2 musical notation and meter expansion #ui #music #backend #decision

Delivered all four milestones for roadmap version v1.2:

1. Grand Staff & Bass Clef Notation: Added dual-system grand staff support
   across `StaffView`, `PracticeScreen`, and `ReviewScreen`. `StaffView`
   renders an initial vertical connector barline and the standard Bravura
   brace glyph (`U+E000`) for multi-system configurations. Added `LevelClef`
   (`treble`, `bass`, `grand`) and `beatUnit` to level models and SMuFL time
   signature painters.
2. Variable Meter Detection & Quantization: Replaced the fixed 4/4 quantizer in
   `backend/app/quantize.py` with multi-meter detection and quantization.
   `detect_meter` calculates downbeat autocorrelation and triplet energy to
   classify recordings into 3/4 waltz, 6/8 compound, or 4/4 time, while
   partitioning multi-octave transcriptions across grand staff systems.
3. Note-Level Ingestion Correction: Added an interactive Note Correction
   Inspector to `ReviewScreen`. Users can inspect transcribed notes, adjust
   pitches in semitone increments, trim or extend durations by quarter beats,
   and delete false detections with instantaneous updates to the staff preview
   and review audio synthesizer.
4. USB & Bluetooth MIDI Input: Built `MidiService` to support hardware
   digital piano connectivity over USB-MIDI and Bluetooth LE MIDI interfaces.
   Decoded MIDI Note On/Off bytes stream directly into `StageController` as
   confidence-1.0 pitch events, configurable via `SettingsScreen` as
   microphone-only, MIDI-only, or simultaneous dual input.

Verified across the complete test matrix on Linux ARM64 with 240 passing Flutter
tests (including golden tests) and 73 passing backend pytest unit tests.

## 2026-10-21: polish smufl glyphs and hit timing differentiation #ui #music #decision

Delivered the SMuFL glyph polish milestone from the v1.1 roadmap. Replaced
Cormorant roman digits for time signatures with native Bravura SMuFL glyphs
(`0xE080..0xE089`) in `StaffPainter._paintTimeSignature`, positioning numerator
and denominator baselines on staff line indices 2 and 4 at the standard 4-space
em font size. Added visual differentiation for hit timing quality across
`NoteState`: `hitPerfect` displays filled solid noteheads with a precision
success halo ring, `hitGood` renders solid success green noteheads, and
`hitOkay` renders warning-amber filled noteheads. Updated unit and widget tests
in `test/ui/staff/note_glyph_test.dart` and regenerated golden reference tests.

## 2026-10-21: add home navigation and continue hub #ui #navigation #decision

Implemented dedicated root landing route (`/`) with `HomeScreen` serving as
the primary practice launchpad and continue hub per the v1.1 roadmap.
Moved `LevelListScreen` to `/levels` with back navigation. `HomeScreen`
features a landscape-optimized two-column layout: a prominent "Continue Practice"
hero card highlighting the last played stage (or next unlocked stage) with
real-time progress metrics and instant resume action, alongside quick hub cards
for level library completion overview and audio ingestion. Wired `lastPlayedStageIdProvider`
and stage tracking to `StageController`, ensuring continuous session persistence.
Verified across landscape form factors with 0 analyzer issues, clean `dart format`,
and passing test suites on `ampere-dev`.

## 2026-10-21: add audio review synthesizer #audio #ui #decision

Implemented `AudioSynthesizer` and `ToneGenerator` in `lib/audio/tone_synthesizer.dart`
to provide auditory feedback during `ReviewScreen` preview. Synthesizes 16-bit
PCM WAV audio using additive harmonic decay (fundamental plus 2nd and 3rd
harmonics) with a 5ms attack envelope to prevent pops, played via `FlutterSoundPlayer`.
Integrated playback into `ReviewScreen` note timings, added a mute/unmute preview
toggle, and decoupled audio players with `SilentAudioTonePlayer` for deterministic
widget testing. Verification passed on `ampere-dev` with clean `dart format`,
0 analyzer warnings, 221 passing Flutter tests, and all 68 backend tests passing.

## 2026-10-21: add settings and calibration hub #decision #ui

Delivered `SettingsScreen` and `SettingsRepository` to fulfill the first milestone
of the v1.1 roadmap. Implemented user preference persistence for theme modes
(System, Recital Light, Recital Dark), default practice playback speed, scoring
timing accuracy tolerance levels (relaxed, normal, strict), microphone permission
and audio engine hardware diagnostics, and ingestion backend service inspection.
Wired `themeModeProvider` to `PianoToolApp` for live theme toggling and threaded
user practice preferences into `StageController` and `StageEngineConfig`.
Verification passed on `ampere-dev` with 0 analyzer issues, clean `dart format`,
213 passing Flutter tests (including all golden tests), and 68 passing backend
pytest unit tests.

## 2026-09-20: resolve major Flutter dependency updates #decision

Migrated the open major Dependabot updates for Riverpod, Freezed, the file
picker, and their generators. File selection now uses the static
`FilePicker.pickFile` API. The practice controller keeps its existing
StateNotifier implementation through Riverpod's legacy compatibility export
and handles Riverpod 3 retrying stream errors explicitly. The Dart SDK floor
is 3.8.0, with the lockfile and generated sources refreshed accordingly.

Verification passed for Flutter analysis, formatting, all 197 Flutter tests,
and the release web build. Android debug packaging remains unverified in the
Linux ARM64 verification environment because no Android SDK is installed; the
x86_64 GitHub Actions Android job remains authoritative for that gate.

## 2026-09-14: configure Vercel for Flutter Web release hosting #decision #deployment

Replaced the decommissioned FastAPI preset on Vercel with Flutter Web release hosting. Reset the project root directory from the obsolete monorepo `apps/piano-tool` path to the repository root, cleared serverless install commands, and configured `scripts/build_web.sh` to compile release web assets to `build/web`. Maintained automatic git deployment gating behind GitHub Actions quality suites before production deploy hook dispatch.

## 2026-09-12: Added x86_64 Android packaging CI #decision

Flutter tests and analysis remain on the ARM64 verifier, while Android debug
APK packaging and emulator smoke testing run on x86_64 GitHub Actions. The Mac
checkout remains source-only and CI publishes a seven-day debug APK artifact.

A dated log of decisions and the reasoning behind them, especially the ones that
are not obvious from the code.

## 2026-09-06: retire the repository staging branch

The standalone repository now runs CI and deploys through `main` only. The
staging branch contained no commits absent from `main`, and the Vercel project
uses `main` as its production branch. Repository workflow references to the
staging branch and staging deploy hook were removed as part of its retirement.

## 2026-09-06: CI dependency check and linter alignment

Basic Pitch intentionally omits TensorFlow in favor of ONNX runtime. CI dependency check (`pip check`) now tolerates this deliberate omission while retaining full validation of all other runtime dependencies. Backend Ruff configuration is upgraded to `[tool.ruff.lint]` with `pylint.max-args = 8` to support ingestion pipeline functions, and `routes.py` and `import_screen.dart` control flow lints are resolved. Verification passed with 197 Flutter tests, 0 analyze issues, clean formatting, and 100% backend branch coverage.

## 2026-09-05: durable ingestion and lifecycle correctness

Ingestion now uses a persistent FastAPI process and a separately supervised
SQLite-WAL worker with a filesystem spool. Job endpoints require a bearer token,
uploads and queue depth are bounded, leases recover abandoned work, cancellation
uses tombstones, and terminal results expire after the configured retention
period. YouTube acquisition is HTTPS-only and bounded; `/ready` checks binaries,
model availability, storage, and SQLite access. Vercel no longer hosts backend
execution.

The Flutter client now submits YouTube jobs as multipart requests, validates
configured HTTPS endpoints, sends bearer and idempotency headers, serializes
polling, and ignores stale responses. Practice audio is route-scoped and its
start/stop lifecycle is serialized. Stage timing distinguishes hits from misses,
and progression derives unlocks from prerequisites and completed progress.

Final remote verification: 197 Flutter tests passed, the analyzer and formatter
passed, and the release web build passed. Backend Ruff, Black, strict mypy, and
pytest with branch coverage enforcement at 100% passed with exit code 0.

## 2026-08-28: finish the piano-tool practice flow

The `piano-tool` branch had the practice loop but no results route. It now
records completion metrics, routes to a results screen, and lets the learner
replay the stage or return to the level list.

Persisted imported levels are hydrated before the level list renders, and save
and delete actions invalidate that catalog after changing storage. The branch
also declares the Flutter packages already used by its source and keeps its
Vercel deployment gate open only for the `piano-tool` branch.

Remote verification passed with 166 Flutter tests and 39 backend tests.
`flutter analyze --no-fatal-infos` reports 61 performance infos and no
warnings.

## 2026-08-28: keep the Vercel backend under its function limit

The first successful Vercel dependency install still produced a 522.97 MB
Python function bundle, over Vercel's 500 MB limit. The deployed path uses
basic-pitch's ONNX backend; it does not need scikit-learn or uvicorn's optional
server extensions. Production installation therefore uses plain `uvicorn`,
removes scikit-learn after dependency resolution, and excludes backend tests
and documentation from the function bundle. The full backend test stack
remains in `backend/requirements.txt`.

The production-shaped Python 3.12 environment reached 480,344 KB, and the
FastAPI and transcription imports succeeded without scikit-learn. The full
backend suite had already passed with that package removed: 39 tests passed
with three existing warnings.

## 2026-08-21: Results flow and Python 3.12 verification

Added a results screen after stage completion, a replay path, an idle practice
golden, and lifecycle-safe controller shutdown. The backend now accepts the
optional upload field for YouTube jobs and returns the API's explicit 400
validation errors instead of FastAPI's 422 errors. Python 3.12 is pinned for
the backend and CI, with Basic Pitch installed separately through the ONNX
setup script and setuptools capped for resampy compatibility.

Verification passed on `ampere-dev`:
- `flutter test`: 187 tests passed
- backend `pytest`: 39 tests passed
- `git diff --check`: clean

## 2026-08-21: MVP cleanup and coverage

Updated the README to match the current routed import and practice flow. Added
scroll and transport coverage, plus tests for the detector threshold and the
engine's canonical note order. The controller now waits for progress writes,
and pitch-quality filtering lives in the audio layer instead of being repeated
in the scoring engine. The Flutter suite passes 182 tests on `ampere-dev`.

## 2026-08-20: Audio ingestion backend and app-side flow merged to main

Branch `audio-ingestion-backend` merged into `main` in the standalone
`Builder106/piano-tool` repository. The app now has a complete ingestion flow:
`IngestionRepository`, `ImportScreen`, `ReviewScreen`, `LevelListScreen`, and
`go_router` navigation, backed by a Python FastAPI service in `backend/`.

Verification passed on `ampere-dev`:
- `flutter test`: 176 tests passed
- strict `flutter analyze`: no issues

The `code-wes-projects` monorepo consumes this project as a git subtree at
`apps/piano-tool/`. The canonical source of truth is the standalone repo; the
monorepo copy is re-imported from `main` when a releaseable milestone is ready.

## 2026-08-18: UI revamp, phase 2 (the practice screen)

Branch `readme-and-phase-2`, 8 tasks, each reviewed and merged individually
before this final whole-branch pass. Replaced the pre-revamp single-screen
prototype with `PracticeScreen` and the Riverpod glue in
`lib/ui/practice/stage_controller.dart`, deleted the dead JSON level pipeline
and the legacy screen it fed, and closed out the phase-1 punch list: the
speed control works, Stop and Replay are distinct, and a denied microphone
gets a real UI state.

### `stageControllerProvider` is not `.autoDispose`, on purpose

This came up during task review twice and was deferred both times. Nothing
in the app navigates between stages yet -- `PracticeScreen` is reachable only
by passing a `stageId` directly, with no router in front of it -- so there is
no point in the app's lifecycle where a stage's controller should actually be
torn down and rebuilt. Making the provider `.autoDispose` now would change
what `container.read(stageControllerProvider(id))` means across a rebuild
(a fresh controller instead of the same one) for a scenario that cannot
happen yet, and would need to be revisited anyway once Plan 3's router
exists and defines when a stage screen actually unmounts for good. Decide it
there, with a real navigation flow to test it against, not here against a
hypothetical one.

### One audio engine, not one per consumer

`audioEngineProvider` is a single `Provider<AudioEngine>` that both
`audioGrantedProvider` (permission and the initial `start()`) and
`audioPitchStreamProvider` (the live pitch stream) read from. Two separate
engines were considered and rejected: opening the microphone twice is worse
than opening it once, and a retry-after-denial flow only works if the same
engine instance that failed to initialize is the one asked to try again. A
second engine created fresh at retry time would not carry that failure
state, and the permission gate would have no way to tell whether a retry was
really retrying anything.

### Two tasks were added mid-plan, not in the original scope

**Task 7, `StageEngine.setPlaybackSpeed`.** The phase-1 journal already
corrected the record on this once: the spec had claimed the speed slider
just needed wiring to an engine method that already worked. It didn't --
`setPlaybackSpeed` was two comments and an ignored argument, and `_config`
being `final` meant the playback tick could never see a changed speed. The
UI-only task became an engine task once that was discovered.

**Task 8, the staff height cap and scroll.** Ninety-two passing tests gave no
signal that anything was wrong. A rendered screenshot did: on a tall band the
staff overflowed its own container, because nothing had ever capped how much
of the band the staff geometry was allowed to claim. `staffGeometryForBand`
in `lib/ui/staff/staff_geometry.dart` and `kDefaultMaxStaffHeight` came out of
that screenshot, not out of a failing test. The lesson carried over from
phase 1 held again: a passing test suite is not evidence the thing looks
right, only that it does what the tests happened to check.

### Left from this final review for Plan 3

Test coverage for the scroll path (no pixel or integration test), a
practice-screen golden, and `main.dart`. `seekTo` has no caller from the UI.
Stop and Replay both rewind to the start of the *transport*, so the
difference between them is only in what they do to playback state, not to
position on screen -- worth revisiting once there is a results screen to
navigate back from. `onPitch`'s volume/confidence gate does not match
`StageEngine.processPitchEvent`'s own gate, which is a duplicated-condition
risk rather than a known bug. The note-index duplication between the
controller and the engine, and the fire-and-forget `record()` /
`setLastPlayed()` calls on `ProgressRepository`, are both still there.
`test/_startup_screenshot_test.dart` is an untracked scratch file, kept
deliberately; leave it alone.

## 2026-08-17: UI revamp, phase 1 (visual foundation)

Branch `ui-revamp-foundation`, 13 commits. Spec in
`docs/specs/2026-08-17-ui-revamp-design.md`, plan in
`docs/plans/2026-08-17-ui-revamp-foundation.md`.

Delivered a token layer, a Material 3 theme, three bundled fonts, staff geometry
in staff-space units, a rewritten staff painter, a `StaffView`, and three golden
images. The tests went from 7 passing with 1 failing to 55 passing with none,
and `flutter analyze` dropped from 83 infos to 75.

### Why the app looked broken

The single screen was laid out for a wide desktop window and was running
portrait on a phone. The transport row hard-coded a 100px slider and a 200px
progress bar inside a `Row` with two `Spacer`s, which overflowed a 1080px screen
by 211px. Three `AppBar` actions squeezed the title to `"C ..."`. Sixty-one keys
at a fixed 24px needed 1464px. A 70/30 flex split gave the staff a thousand
pixels of column for four hundred of content.

### Decisions worth remembering

**The README does not describe this codebase.** It documents a level format with
a nested `pitch` object and a `clef` field. The real `LevelNote` uses a flat
`midiNote` int, and there is no clef type anywhere in `lib/`. `LevelModel`
carries `clefOctave` and `transpose` instead. The spec was written partly from
the README and inherited the error, which surfaced only when a task tried to
import `Clef`. Read the models, not the README. The README still needs fixing.

**`Clef` is a UI-layer concept, for now.** Defined in
`lib/ui/staff/staff_geometry.dart` because the models have no clef. `StaffView`
takes a list of systems, each naming its own clef, so the caller decides whether
to draw one staff or two. Moving it into the level format belongs with the
practice screen that would read it.

**`NoteState` has six values, not four.** `upcoming, active, hitPerfect,
hitGood, hitOkay, missed`. All three hit gradations render as the same filled
notehead. Encoding hit quality visually is a scoring-feedback decision nobody has
made yet, and inventing one during a layout fix would have been scope creep.

**Note state is a shape before it is a colour.** Filled, hollow, ringed, or
struck through. The previous build distinguished hit from missed only by green
against red, which is invisible to red-green colour blindness. Filled against
hollow noteheads is real notation, so the fix costs nothing and reads as more
musical rather than less.

**Fonts are bundled, not fetched.** `google_fonts` was removed. Runtime fetching
made golden tests depend on the network and left the app with no offline
guarantee. Cormorant Garamond and IBM Plex Sans are variable fonts registered
with one asset each and no `weight:` keys, so weight is driven by
`fontVariations` on the `wght` axis. An earlier attempt registered the same
variable font under five static-looking filenames, which meant every weight
resolved to identical bytes and there was no weight contrast at all.

**Clefs come from Bravura.** Unicode `U+1D11E` and `U+1D122` render from
whatever font the OS supplies, land in the wrong vertical position, and are
missing entirely on some Android builds. Bravura is the SMuFL reference font and
is free under the OFL. This is what the empty `assets/fonts/` entry in
`pubspec.yaml` had always been declared for.

**Everything on the staff is sized in staff-spaces.** One space is a quarter of
the staff height. Noteheads are one space, the time signature is four, stems are
about two. This is what makes a grand staff free: halve the band and every glyph
scales with it, with no second code path.

**`test/flutter_test_config.dart` is load-bearing.** Flutter test harnesses do
not load fonts declared in `pubspec.yaml`. Without that file, text renders as
tofu boxes and the golden images bake missing glyphs in as expected output. The
first set of goldens passed 51 of 51 tests while showing black rectangles where
the clef and time signature belong.

**Golden tests are skipped off Linux.** Font rasterisation differs by host and
the default comparator is byte-exact, so the images are generated and verified
on the Linux VM. The two non-golden layout tests still run everywhere.

### The bug that came back

The original overflow was a content-derived size combined with a fixed offset.
The rewritten painter reintroduced exactly that shape: the clef and time
signature were sized in staff-spaces, which scale with staff height, while notes
started at a fixed `leadingBeats * pixelsPerBeat`. The two agreed on a short
staff and collided on a tall one, putting the time signature on top of the first
two notes. `leadingBeats` is gone and the note origin now derives from the
header width, so there is only one way to express the offset.

### What the tests did not catch

Both visual defects in the golden images, the tofu glyphs and the collision,
passed every test. A golden that captures a broken rendering locks the defect in
as expected output, so every later run confirms the bug rather than finding it.
Look at the images.

### Deliberately left for phase 2

The five screens and routing, `ProgressRepository` on `shared_preferences`, the
Riverpod wrapping of `StageEngine`, the practice-screen layout with its 60dp
control column, the keyboard rewrite as visualization only, the
microphone-permission state, wiring the speed slider to
`StageEngine.setPlaybackSpeed`, and giving Stop and Replay distinct behaviour.

Correction to an earlier note above: `setPlaybackSpeed` does not work and never
did. Its body is two comments, it ignores its argument, and `_config` is final,
so the playback tick reads a speed that is permanently 1.0. Making the slider
work needs a small engine change, not just a UI connection.

Also carried forward: the brace on the grand staff, which is unreachable until
the level format carries a second staff; time-signature digits drawn in Cormorant
rather than Bravura's own glyphs; and `lib/ui/game/game_screen.dart`, which is
still the pre-revamp screen and is replaced wholesale in phase 2.
