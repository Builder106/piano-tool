# Piano-Tool UI revamp, Plan 2: the practice loop

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the legacy practice screen with the one the spec describes, driven by Riverpod instead of per-frame `setState`, and give the app somewhere to store progress.

**Architecture:** `StageEngine` and `AudioEngine` are untouched. A Riverpod notifier wraps the engine and exposes narrow slices, so widgets watch what they need rather than rebuilding the tree on every playback tick. The practice screen is a left control column with a HUD, staff, and keyboard stacked beside it. The keyboard becomes a single `CustomPainter` with no touch handling.

**Tech Stack:** Flutter 3.47, Riverpod 2.4 with codegen, `shared_preferences`, `flutter_test` with goldens.

**Spec:** `docs/specs/2026-08-17-ui-revamp-design.md`

**Predecessor:** `docs/plans/2026-08-17-ui-revamp-foundation.md`, merged. Tokens, theme, fonts, staff geometry, painter, and `StaffView` all exist and are tested.

## Global constraints

- No build artifacts on the Mac. `pub get`, `analyze`, and `test` run on `ampere-dev` via `verify-on-vm` only.
- Baseline that must not regress: **55 tests passing, zero failures, 75 analyze infos.**
- No colour named outside `lib/ui/theme/`. Widgets read `PianoTheme.colorsOf(context)`; painters take an injected `PianoColors`.
- No `Card` elevation and no shadows. Depth is weight and lightness.
- Display type is Cormorant Garamond, roman only. Every changing number uses the `labelLarge` or `labelSmall` metric styles, which already set tabular figures.
- Accent (ink blue) appears only on the playhead, the note currently due, and the primary action. Under 5% of any screen.
- One motion moment: `PianoMotion.micro` (120ms) on a note hit. No hover states; this is a touch device.
- Landscape lock is already applied app-wide in `main.dart`. Do not add per-screen locks.
- Golden tests are skipped off Linux via `skip: !Platform.isLinux`. Follow that pattern for any new golden.
- No status dots, no accent rails, no eyebrow headings, no middle-dot separators.

## Facts established before this plan

Verified by reading the code, not the docs. Several contradict older documentation.

- **Levels are hardcoded in Dart.** `LevelRepository._loadBuiltInLevels` builds three levels (`level_1`, `level_2`, `level_3`) and three stages (`stage_1`, `stage_2`, `stage_3`). `loadAll()` is never called from anywhere, expects a `manifest.json` and `stages.json` that do not exist, and swallows its own failure in a bare `catch`. `assets/levels/twinkle_twinkle.json` is in a format `LevelModel.fromJson` cannot parse and is read by nothing. Task 6 removes the dead path.
- **`StageEngine` public API:** `state` (a `StageEngineStateModel`), `allNotes`, `noteStates`, `events` (a `Stream<StageEvent>`), `start()`, `pause()`, `resume()`, `stop()`, `reset()`, `seekToBeat(double)`, `processPitchEvent(PitchEvent)`, `setPlaybackSpeed(double)`, `dispose()`.
- **`stop()` and `reset()` are different methods.** The legacy screen wired both buttons to `reset()`. Stop halts and holds position; Replay returns to the start and plays.
- **`setPlaybackSpeed` is a stub.** Its body is two comments and it ignores its argument. `_config` is final, so `_config.playbackSpeed` is read by the playback tick and stays 1.0 forever. Task 7 implements it. Wiring the slider to it before then yields a control that still does nothing.
- **`StageEngineStateModel`** carries `engineState`, `level`, `currentBeat`, `noteStates`, `score`, `hitCount`, `missCount`, `perfectCount`, `goodCount`, `okayCount`, plus computed `progress` and `accuracy`.
- **`AudioEngine.initialize()` returns `Future<bool>`**, false when microphone permission is denied. The legacy screen ignored the result.
- **`NoteState`** has six values: `upcoming`, `active`, `hitPerfect`, `hitGood`, `hitOkay`, `missed`.
- **`StaffView`** takes `systems` (a list of `({Clef clef, List<PlacedNote> notes})`), `currentBeat`, `totalBeats`, `beatsPerMeasure`, and `pixelsPerBeat`. `PlacedNote` is `({int midi, double startBeat, NoteState state})`. There is no `leadingBeats`; the header offset is derived internally and exposed as `StaffPainter.headerWidthFor(StaffGeometry)`.

---

### Task 1: ProgressRepository

**Files:**
- Create: `lib/data/progress_repository.dart`
- Test: `test/data/progress_repository_test.dart`
- Modify: `pubspec.yaml` (add `shared_preferences`)

**Interfaces:**
- Consumes: `StageProgress` from `lib/models/level_models.dart`.
- Produces: `ProgressRepository` with `Future<StageProgress?> read(String stageId)`, `Future<void> record({required String stageId, required double accuracy, required int score})`, `Future<Map<String, StageProgress>> readAll()`, `Future<String?> lastPlayedStageId()`, `Future<void> setLastPlayed(String stageId)`; plus `progressRepositoryProvider`.

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, under `dependencies`, after `permission_handler`:

```yaml
  shared_preferences: ^2.2.2
```

Then `verify-on-vm "<repo>" "flutter pub get"`.

- [ ] **Step 2: Write the failing test**

`shared_preferences` ships an in-memory test backend, so no mocking package is needed.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:piano_tool/data/progress_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('an unplayed stage has no progress', () async {
    final repo = ProgressRepository();
    expect(await repo.read('stage_1'), isNull);
  });

  test('recording a run stores accuracy and score', () async {
    final repo = ProgressRepository();
    await repo.record(stageId: 'stage_1', accuracy: 0.8, score: 100);

    final p = (await repo.read('stage_1'))!;
    expect(p.stageId, 'stage_1');
    expect(p.bestAccuracy, closeTo(0.8, 1e-9));
    expect(p.bestScore, 100);
    expect(p.attempts, 1);
  });

  test('a worse run raises attempts but not the bests', () async {
    final repo = ProgressRepository();
    await repo.record(stageId: 'stage_1', accuracy: 0.9, score: 200);
    await repo.record(stageId: 'stage_1', accuracy: 0.4, score: 50);

    final p = (await repo.read('stage_1'))!;
    expect(p.bestAccuracy, closeTo(0.9, 1e-9));
    expect(p.bestScore, 200);
    expect(p.attempts, 2);
  });

  test('a better run raises the bests', () async {
    final repo = ProgressRepository();
    await repo.record(stageId: 'stage_1', accuracy: 0.5, score: 10);
    await repo.record(stageId: 'stage_1', accuracy: 0.95, score: 300);

    final p = (await repo.read('stage_1'))!;
    expect(p.bestAccuracy, closeTo(0.95, 1e-9));
    expect(p.bestScore, 300);
  });

  test('completion latches at 90% accuracy and never un-completes', () async {
    final repo = ProgressRepository();
    await repo.record(stageId: 'stage_1', accuracy: 0.92, score: 100);
    expect((await repo.read('stage_1'))!.completed, isTrue);

    await repo.record(stageId: 'stage_1', accuracy: 0.10, score: 5);
    expect((await repo.read('stage_1'))!.completed, isTrue);
  });

  test('stages are stored independently', () async {
    final repo = ProgressRepository();
    await repo.record(stageId: 'stage_1', accuracy: 0.8, score: 100);
    await repo.record(stageId: 'stage_2', accuracy: 0.6, score: 60);

    final all = await repo.readAll();
    expect(all.keys.toSet(), {'stage_1', 'stage_2'});
    expect(all['stage_2']!.bestScore, 60);
  });

  test('last played round-trips and survives a new repository', () async {
    await ProgressRepository().setLastPlayed('stage_3');
    expect(await ProgressRepository().lastPlayedStageId(), 'stage_3');
  });

  test('corrupt stored JSON is discarded rather than thrown', () async {
    SharedPreferences.setMockInitialValues({
      'progress.stage_1': '{not valid json',
    });
    expect(await ProgressRepository().read('stage_1'), isNull);
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

```bash
verify-on-vm "<repo>" "flutter test test/data/progress_repository_test.dart"
```

Expected: FAIL, URI does not exist.

- [ ] **Step 4: Write the implementation**

```dart
import 'dart:convert';

import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/level_models.dart';

/// Per-stage bests, stored on device. No accounts and no network.
///
/// One key per stage rather than a single blob, so a corrupt entry costs one
/// stage's history instead of all of it.
class ProgressRepository {
  static const _prefix = 'progress.';
  static const _lastPlayedKey = 'progress.lastPlayed';

  /// Accuracy at or above this counts as clearing the stage.
  static const double completionThreshold = 0.9;

  Future<StageProgress?> read(String stageId) async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(stageId, prefs.getString('$_prefix$stageId'));
  }

  Future<Map<String, StageProgress>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final out = <String, StageProgress>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_prefix) || key == _lastPlayedKey) continue;
      final id = key.substring(_prefix.length);
      final progress = _decode(id, prefs.getString(key));
      if (progress != null) out[id] = progress;
    }
    return out;
  }

  Future<void> record({
    required String stageId,
    required double accuracy,
    required int score,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final previous = _decode(stageId, prefs.getString('$_prefix$stageId'));

    // Bests only ever climb; a bad run still counts as an attempt, and
    // clearing a stage once is permanent.
    final next = StageProgress(
      stageId: stageId,
      bestAccuracy:
          accuracy > (previous?.bestAccuracy ?? 0) ? accuracy : (previous?.bestAccuracy ?? 0),
      bestScore: score > (previous?.bestScore ?? 0) ? score : (previous?.bestScore ?? 0),
      attempts: (previous?.attempts ?? 0) + 1,
      completed: (previous?.completed ?? false) || accuracy >= completionThreshold,
      unlocked: true,
      completedAt: previous?.completedAt ??
          (accuracy >= completionThreshold ? DateTime.now() : null),
      lastAttemptAt: DateTime.now(),
    );

    await prefs.setString('$_prefix$stageId', jsonEncode(next.toJson()));
  }

  Future<String?> lastPlayedStageId() async =>
      (await SharedPreferences.getInstance()).getString(_lastPlayedKey);

  Future<void> setLastPlayed(String stageId) async =>
      (await SharedPreferences.getInstance()).setString(_lastPlayedKey, stageId);

  StageProgress? _decode(String stageId, String? raw) {
    if (raw == null) return null;
    try {
      return StageProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // A corrupt entry is treated as no history. Rethrowing here would make
      // one bad write break the level list for good.
      return null;
    }
  }
}

final progressRepositoryProvider =
    Provider<ProgressRepository>((ref) => ProgressRepository());
```

- [ ] **Step 5: Run the test to verify it passes**

```bash
verify-on-vm "<repo>" "flutter test test/data/progress_repository_test.dart"
```

Expected: PASS, 8 tests.

- [ ] **Step 6: Run the whole suite**

```bash
verify-on-vm "<repo>" "flutter test && flutter analyze --no-fatal-infos"
```

Expected: 63 passing, zero failures, analyze at or under 75.

- [ ] **Step 7: Commit**

```bash
git add lib/data/progress_repository.dart test/data/progress_repository_test.dart pubspec.yaml pubspec.lock
git commit -m "Add ProgressRepository for on-device stage progress

One shared_preferences key per stage rather than a single blob, so a corrupt
entry costs one stage's history instead of every stage's. Bests only climb, a
poor run still counts as an attempt, and clearing a stage is permanent.

Corrupt JSON decodes to no-history rather than throwing, because one bad write
should not be able to break the level list."
```

---

### Task 2: Riverpod stage controller

The fix for per-frame `setState`. Widgets watch narrow slices; nothing rebuilds the whole tree on a playback tick.

**Files:**
- Create: `lib/ui/practice/stage_controller.dart`
- Test: `test/ui/practice/stage_controller_test.dart`

**Interfaces:**
- Consumes: `StageEngine`, `StageEngineStateModel`, `StageEvent`, `LevelRepository`, `AudioEngine`, `ProgressRepository`.
- Produces: `stageControllerProvider` (a `StateNotifierProvider.family<StageController, StageUiState, String>` keyed by stage id); `StageUiState`; derived providers `currentBeatProvider`, `scoreProvider`, `accuracyProvider`, `engineStatusProvider`, `noteStatesProvider`, `micPermissionProvider`, `playbackSpeedProvider`.

- [ ] **Step 1: Write the failing test**

The controller must work without a microphone, so audio is injected.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/ui/practice/stage_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer harness() => ProviderContainer(
        overrides: [audioGrantedProvider.overrideWith((ref) async => true)],
      );

  test('starts idle at beat zero with a real level', () {
    final c = harness();
    addTearDown(c.dispose);
    final s = c.read(stageControllerProvider('stage_1'));

    expect(s.currentBeat, 0);
    expect(s.score, 0);
    expect(s.status, StageEngineStatus.idle);
    expect(s.notes, isNotEmpty);
  });

  test('speed changes are held and clamped to the allowed range', () {
    final c = harness();
    addTearDown(c.dispose);
    final ctrl = c.read(stageControllerProvider('stage_1').notifier);

    ctrl.setSpeed(1.5);
    expect(c.read(stageControllerProvider('stage_1')).speed, 1.5);

    ctrl.setSpeed(9.0);
    expect(c.read(stageControllerProvider('stage_1')).speed, 2.0);

    ctrl.setSpeed(0.1);
    expect(c.read(stageControllerProvider('stage_1')).speed, 0.5);
  });

  test('stop holds position while replay returns to the start', () {
    final c = harness();
    addTearDown(c.dispose);
    final ctrl = c.read(stageControllerProvider('stage_1').notifier);

    ctrl.start();
    ctrl.seekTo(4);
    expect(c.read(stageControllerProvider('stage_1')).currentBeat, 4);

    ctrl.stop();
    expect(c.read(stageControllerProvider('stage_1')).currentBeat, 4,
        reason: 'stop must not rewind');

    ctrl.replay();
    expect(c.read(stageControllerProvider('stage_1')).currentBeat, 0);
  });

  test('a denied microphone surfaces as state, not silence', () async {
    final c = ProviderContainer(
      overrides: [audioGrantedProvider.overrideWith((ref) async => false)],
    );
    addTearDown(c.dispose);

    expect(await c.read(audioGrantedProvider.future), isFalse);
  });

  test('derived providers expose slices without the whole state', () {
    final c = harness();
    addTearDown(c.dispose);

    expect(c.read(currentBeatProvider('stage_1')), 0);
    expect(c.read(scoreProvider('stage_1')), 0);
    expect(c.read(engineStatusProvider('stage_1')), StageEngineStatus.idle);
  });

  test('an unknown stage id fails loudly', () {
    final c = harness();
    addTearDown(c.dispose);
    expect(() => c.read(stageControllerProvider('nope')), throwsStateError);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
verify-on-vm "<repo>" "flutter test test/ui/practice/stage_controller_test.dart"
```

Expected: FAIL, URI does not exist.

- [ ] **Step 3: Write the implementation**

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/audio_engine.dart';
import '../../data/level_repository.dart';
import '../../data/progress_repository.dart';
import '../../engine/stage_engine.dart';
import '../../models/engine_models.dart';
import '../../models/level_models.dart';

/// Whether the microphone was granted. Overridden in tests so the controller
/// can run without hardware.
final audioGrantedProvider = FutureProvider<bool>((ref) async {
  final engine = AudioEngine();
  final granted = await engine.initialize();
  if (granted) {
    await engine.start();
    ref.onDispose(engine.dispose);
  } else {
    await engine.dispose();
  }
  return granted;
});

/// Everything the practice screen can show, in one immutable value.
class StageUiState {
  const StageUiState({
    required this.level,
    required this.notes,
    required this.noteStates,
    required this.currentBeat,
    required this.score,
    required this.accuracy,
    required this.status,
    required this.speed,
  });

  final LevelModel level;
  final List<LevelNote> notes;
  final List<NoteState> noteStates;
  final double currentBeat;
  final int score;
  final double accuracy;
  final StageEngineStatus status;
  final double speed;

  double get progress {
    final total = level.totalMeasures * level.beatsPerMeasure;
    return total > 0 ? (currentBeat / total).clamp(0.0, 1.0) : 0.0;
  }

  StageUiState copyWith({
    List<NoteState>? noteStates,
    double? currentBeat,
    int? score,
    double? accuracy,
    StageEngineStatus? status,
    double? speed,
  }) =>
      StageUiState(
        level: level,
        notes: notes,
        noteStates: noteStates ?? this.noteStates,
        currentBeat: currentBeat ?? this.currentBeat,
        score: score ?? this.score,
        accuracy: accuracy ?? this.accuracy,
        status: status ?? this.status,
        speed: speed ?? this.speed,
      );
}

class StageController extends StateNotifier<StageUiState> {
  StageController(this._engine, this._stageId, this._progress, StageUiState initial)
      : super(initial) {
    _sub = _engine.events.listen(_onEvent);
  }

  final StageEngine _engine;
  final String _stageId;
  final ProgressRepository _progress;
  StreamSubscription<StageEvent>? _sub;

  static const double minSpeed = 0.5;
  static const double maxSpeed = 2.0;

  void start() {
    _engine.start();
    _progress.setLastPlayed(_stageId);
    _sync();
  }

  void pause() {
    _engine.pause();
    _sync();
  }

  void resume() {
    _engine.resume();
    _sync();
  }

  /// Halts and holds position. Distinct from [replay], which rewinds.
  void stop() {
    _engine.stop();
    _sync();
  }

  /// Returns to the start and plays again.
  void replay() {
    _engine.reset();
    _engine.start();
    _sync();
  }

  void seekTo(double beat) {
    _engine.seekToBeat(beat);
    _sync();
  }

  void setSpeed(double speed) {
    final clamped = speed.clamp(minSpeed, maxSpeed);
    _engine.setPlaybackSpeed(clamped);
    state = state.copyWith(speed: clamped);
  }

  void _onEvent(StageEvent event) {
    _sync();
    event.whenOrNull(stageCompleted: (accuracy, score, _, __) {
      _progress.record(stageId: _stageId, accuracy: accuracy, score: score);
    });
  }

  void _sync() {
    final s = _engine.state;
    state = state.copyWith(
      noteStates: List.of(s.noteStates),
      currentBeat: s.currentBeat,
      score: s.score,
      accuracy: s.accuracy,
      status: s.engineState,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _engine.dispose();
    super.dispose();
  }
}

final stageControllerProvider =
    StateNotifierProvider.family<StageController, StageUiState, String>((ref, stageId) {
  final stages = ref.read(levelRepositoryProvider).getAllStages();
  final stage = stages.cast<StageModel?>().firstWhere(
        (s) => s?.id == stageId,
        orElse: () => null,
      );
  if (stage == null) {
    // Loud, not silent: a bad id is a routing bug and should not render an
    // empty staff that looks like a loading state.
    throw StateError('No stage with id "$stageId"');
  }

  final engine = StageEngine(level: stage.level);
  final notes = [
    for (final m in stage.level.measures) ...m.notes,
  ]..sort((a, b) => a.startBeat.compareTo(b.startBeat));

  return StageController(
    engine,
    stageId,
    ref.read(progressRepositoryProvider),
    StageUiState(
      level: stage.level,
      notes: notes,
      noteStates: List.of(engine.state.noteStates),
      currentBeat: 0,
      score: 0,
      accuracy: 0,
      status: engine.state.engineState,
      speed: 1.0,
    ),
  );
});

// Narrow slices. A widget watching one of these does not rebuild when an
// unrelated field changes, which is the whole point of this file.
final currentBeatProvider = Provider.family<double, String>(
    (ref, id) => ref.watch(stageControllerProvider(id).select((s) => s.currentBeat)));
final scoreProvider = Provider.family<int, String>(
    (ref, id) => ref.watch(stageControllerProvider(id).select((s) => s.score)));
final accuracyProvider = Provider.family<double, String>(
    (ref, id) => ref.watch(stageControllerProvider(id).select((s) => s.accuracy)));
final engineStatusProvider = Provider.family<StageEngineStatus, String>(
    (ref, id) => ref.watch(stageControllerProvider(id).select((s) => s.status)));
final noteStatesProvider = Provider.family<List<NoteState>, String>(
    (ref, id) => ref.watch(stageControllerProvider(id).select((s) => s.noteStates)));
final playbackSpeedProvider = Provider.family<double, String>(
    (ref, id) => ref.watch(stageControllerProvider(id).select((s) => s.speed)));
```

If `StageEvent.whenOrNull` does not exist with that signature on this freezed version, check `lib/models/engine_models.freezed.dart` for the generated API and use the matching form. Do not change the event model.

- [ ] **Step 4: Run the test to verify it passes**

```bash
verify-on-vm "<repo>" "flutter test test/ui/practice/stage_controller_test.dart"
```

Expected: PASS, 6 tests.

- [ ] **Step 5: Run the whole suite**

```bash
verify-on-vm "<repo>" "flutter test && flutter analyze --no-fatal-infos"
```

Expected: 69 passing, zero failures.

- [ ] **Step 6: Commit**

```bash
git add lib/ui/practice/stage_controller.dart test/ui/practice/stage_controller_test.dart
git commit -m "Wrap StageEngine in a Riverpod controller with narrow slices

The legacy screen called setState on every playbackPosition event and again
inside the active-note update, rebuilding the whole tree every frame. Widgets
now watch a single field each through select, so a beat tick repaints the staff
without touching the HUD or the transport.

Stop and replay are separate methods here because the engine has always had
both; the old screen wired each button to reset(). Speed clamps to 0.5x-2x and
calls setPlaybackSpeed, which is a stub until Task 7 implements it.

An unknown stage id throws rather than rendering an empty staff that would look
like a loading state."
```

---

### Task 3: Keyboard as visualization

Touch handling and the fake `PitchEvent` both go away. A keyboard that never receives taps needs no touch-target width, which is what lets all 61 keys fit across a landscape screen without scrolling.

**Files:**
- Create: `lib/ui/keyboard/keyboard_geometry.dart`
- Create: `lib/ui/keyboard/piano_keyboard_view.dart`
- Test: `test/ui/keyboard/keyboard_geometry_test.dart`
- Test: `test/ui/keyboard/piano_keyboard_view_test.dart`

**Interfaces:**
- Consumes: `PianoColors`, `NoteState`.
- Produces: `KeyboardGeometry` with `const KeyboardGeometry({required double width, required double height})`, getters `whiteKeyWidth`, `blackKeyWidth`, `blackKeyHeight`, and methods `whiteKeyRect(int index)`, `blackKeyRect(int index)`, `isBlack(int midi)`, `whiteIndexFor(int midi)`; `PianoKeyboardView({required Set<int> due, required Set<int> playing})`.

- [ ] **Step 1: Write the failing geometry test**

The keyboard spans MIDI 36 (C2) to 96 (C7): 61 keys, 36 white and 25 black.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/ui/keyboard/keyboard_geometry.dart';

void main() {
  const g = KeyboardGeometry(width: 720, height: 80);

  test('36 white keys divide the full width with none left over', () {
    expect(KeyboardGeometry.whiteKeyCount, 36);
    expect(g.whiteKeyWidth, closeTo(20, 1e-9));
    expect(g.whiteKeyRect(35).right, closeTo(720, 1e-6));
  });

  test('the keyboard spans C2 to C7', () {
    expect(KeyboardGeometry.lowestMidi, 36);
    expect(KeyboardGeometry.highestMidi, 96);
  });

  test('black keys are narrower and shorter than white', () {
    expect(g.blackKeyWidth, lessThan(g.whiteKeyWidth));
    expect(g.blackKeyHeight, lessThan(g.height));
  });

  test('there are 25 black keys and none between B and C or E and F', () {
    var count = 0;
    for (var midi = 36; midi <= 96; midi++) {
      if (g.isBlack(midi)) count++;
    }
    expect(count, 25);

    // B2 to C3 and E2 to F2 are the two semitone steps with no black key.
    expect(g.isBlack(47), isFalse); // B2
    expect(g.isBlack(48), isFalse); // C3
    expect(g.isBlack(40), isFalse); // E2
    expect(g.isBlack(41), isFalse); // F2
  });

  test('white index advances by seven per octave', () {
    expect(g.whiteIndexFor(36), 0);  // C2
    expect(g.whiteIndexFor(48), 7);  // C3
    expect(g.whiteIndexFor(96), 35); // C7
  });

  test('a black key sits astride the boundary of its two white neighbours', () {
    // C#2 straddles C2 and D2, so its centre is the boundary between them.
    final boundary = g.whiteKeyRect(0).right;
    expect(g.blackKeyRect(37).center.dx, closeTo(boundary, 1e-6));
  });

  test('every measurement scales with the given size', () {
    const wide = KeyboardGeometry(width: 1440, height: 80);
    expect(wide.whiteKeyWidth, closeTo(g.whiteKeyWidth * 2, 1e-9));
  });
}
```

- [ ] **Step 2: Run it to verify it fails, then implement**

```bash
verify-on-vm "<repo>" "flutter test test/ui/keyboard/keyboard_geometry_test.dart"
```

Then create `lib/ui/keyboard/keyboard_geometry.dart`:

```dart
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart' show immutable;

/// Key positions for a 61 key keyboard, C2 to C7.
///
/// Sized from the space available rather than a fixed key width. The keyboard
/// is visualization only, so keys do not need a touch target and all 61 fit
/// across a landscape screen without scrolling.
@immutable
class KeyboardGeometry {
  const KeyboardGeometry({required this.width, required this.height});

  final double width;
  final double height;

  static const int lowestMidi = 36;  // C2
  static const int highestMidi = 96; // C7
  static const int whiteKeyCount = 36;

  /// Semitone offsets within an octave that are black keys.
  static const Set<int> _blackOffsets = {1, 3, 6, 8, 10};

  /// White-key ordinal of each natural within an octave.
  static const List<int> _whiteOrdinal = [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6];

  double get whiteKeyWidth => width / whiteKeyCount;
  double get blackKeyWidth => whiteKeyWidth * 0.62;
  double get blackKeyHeight => height * 0.6;

  bool isBlack(int midi) => _blackOffsets.contains(midi % 12);

  /// Index of the white key at or below [midi], counting from C2.
  int whiteIndexFor(int midi) {
    final semitones = midi - lowestMidi;
    final octaves = semitones ~/ 12;
    return octaves * 7 + _whiteOrdinal[midi % 12];
  }

  Rect whiteKeyRect(int index) =>
      Rect.fromLTWH(index * whiteKeyWidth, 0, whiteKeyWidth, height);

  /// A black key is centred on the boundary between the two white keys it
  /// sits between, which is where it lands on a real instrument.
  Rect blackKeyRect(int midi) {
    final boundary = (whiteIndexFor(midi) + 1) * whiteKeyWidth;
    return Rect.fromLTWH(
      boundary - blackKeyWidth / 2,
      0,
      blackKeyWidth,
      blackKeyHeight,
    );
  }
}
```

- [ ] **Step 3: Write the failing widget test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/ui/keyboard/piano_keyboard_view.dart';
import 'package:piano_tool/ui/theme/app_theme.dart';

Widget _harness(ThemeData theme, {Set<int> due = const {}, Set<int> playing = const {}}) =>
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: SizedBox(
          width: 720,
          height: 80,
          child: PianoKeyboardView(due: due, playing: playing),
        ),
      ),
    );

void main() {
  testWidgets('renders without overflow at a narrow landscape width', (tester) async {
    await tester.pumpWidget(_harness(PianoTheme.light()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('has no gesture detector, because it is visualization only',
      (tester) async {
    await tester.pumpWidget(_harness(PianoTheme.light()));
    expect(find.byType(GestureDetector), findsNothing);
  });

  testWidgets('does not scroll', (tester) async {
    await tester.pumpWidget(_harness(PianoTheme.light()));
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.byType(Scrollable), findsNothing);
  });

  testWidgets('repaints when the played set changes', (tester) async {
    await tester.pumpWidget(_harness(PianoTheme.light(), playing: const {60}));
    final first = tester.widget<CustomPaint>(
      find.descendant(of: find.byType(PianoKeyboardView), matching: find.byType(CustomPaint)).first,
    );
    await tester.pumpWidget(_harness(PianoTheme.light(), playing: const {62}));
    final second = tester.widget<CustomPaint>(
      find.descendant(of: find.byType(PianoKeyboardView), matching: find.byType(CustomPaint)).first,
    );
    expect(
      (second.painter as dynamic).shouldRepaint(first.painter),
      isTrue,
    );
  });
}
```

- [ ] **Step 4: Implement the view**

Create `lib/ui/keyboard/piano_keyboard_view.dart`. It draws white keys, then black keys on top, then octave labels at each C. Marks a due key by ground and a playing key by fill, per the "shape before colour" rule.

```dart
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'keyboard_geometry.dart';

/// A 61 key keyboard that shows what is coming and what is being played.
/// It takes no input; scoring comes from the microphone.
class PianoKeyboardView extends StatelessWidget {
  const PianoKeyboardView({super.key, this.due = const {}, this.playing = const {}});

  /// Notes the level expects right now.
  final Set<int> due;

  /// Notes currently detected from audio.
  final Set<int> playing;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.infinite,
        painter: _KeyboardPainter(
          colors: PianoTheme.colorsOf(context),
          due: due,
          playing: playing,
        ),
      );
}

class _KeyboardPainter extends CustomPainter {
  _KeyboardPainter({required this.colors, required this.due, required this.playing});

  final PianoColors colors;
  final Set<int> due;
  final Set<int> playing;

  @override
  void paint(Canvas canvas, Size size) {
    final g = KeyboardGeometry(width: size.width, height: size.height);
    final edge = Paint()
      ..color = colors.rule
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var midi = KeyboardGeometry.lowestMidi; midi <= KeyboardGeometry.highestMidi; midi++) {
      if (g.isBlack(midi)) continue;
      final rect = g.whiteKeyRect(g.whiteIndexFor(midi));
      canvas.drawRect(rect, Paint()..color = _whiteFill(midi));
      canvas.drawRect(rect, edge);
    }

    for (var midi = KeyboardGeometry.lowestMidi; midi <= KeyboardGeometry.highestMidi; midi++) {
      if (!g.isBlack(midi)) continue;
      canvas.drawRect(g.blackKeyRect(midi), Paint()..color = _blackFill(midi));
    }

    _paintOctaveLabels(canvas, g, size);
  }

  Color _whiteFill(int midi) {
    if (playing.contains(midi)) return colors.accent;
    if (due.contains(midi)) return colors.paper3;
    return colors.paper;
  }

  Color _blackFill(int midi) {
    if (playing.contains(midi)) return colors.accent;
    if (due.contains(midi)) return colors.ink2;
    return colors.ink;
  }

  void _paintOctaveLabels(Canvas canvas, KeyboardGeometry g, Size size) {
    for (var octave = 2; octave <= 7; octave++) {
      final midi = 12 * (octave + 1);
      if (midi > KeyboardGeometry.highestMidi) break;
      final rect = g.whiteKeyRect(g.whiteIndexFor(midi));
      final painter = TextPainter(
        text: TextSpan(
          text: 'C$octave',
          style: TextStyle(
            fontFamily: 'IBMPlexSans',
            fontSize: (g.whiteKeyWidth * 0.42).clamp(6.0, 10.0),
            color: colors.muted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(rect.left + (rect.width - painter.width) / 2, size.height - painter.height - 2),
      );
    }
  }

  @override
  bool shouldRepaint(_KeyboardPainter old) =>
      old.colors != colors ||
      !setEquals(old.due, due) ||
      !setEquals(old.playing, playing);
}
```

Import `setEquals` from `package:flutter/foundation.dart`. Comparing the sets by value matters for the same reason it did on the staff painter: a rebuilt set with identical contents would otherwise force a repaint every frame.

- [ ] **Step 5: Run both tests, then the whole suite**

```bash
verify-on-vm "<repo>" "flutter test && flutter analyze --no-fatal-infos"
```

Expected: 80 passing, zero failures.

- [ ] **Step 6: Commit**

```bash
git add lib/ui/keyboard/keyboard_geometry.dart lib/ui/keyboard/piano_keyboard_view.dart test/ui/keyboard
git commit -m "Add a visualization-only keyboard sized to available width

The old keyboard hardcoded 24px keys, so 61 of them needed 1464px on a 1080px
screen and scrolled, with nothing ever scrolling it to the octave in play. Key
width now divides the space available, so all 61 fit across a landscape screen.

Dropping touch input is what makes that possible: a keyboard nobody taps needs
no touch target. It also removes the fake PitchEvent the old screen fabricated
and fed to the engine as though it were played audio.

A due key is marked by ground and a played key by fill, so state is legible
without relying on colour alone."
```

---

### Task 4: Practice screen

The layout from the spec: a fixed control column on the left, with HUD, staff, and keyboard stacked beside it.

**Files:**
- Create: `lib/ui/practice/practice_screen.dart`
- Create: `lib/ui/practice/practice_hud.dart`
- Create: `lib/ui/practice/transport_column.dart`
- Test: `test/ui/practice/practice_screen_test.dart`

**Interfaces:**
- Consumes: everything from Tasks 1 to 3, plus `StaffView`, `PlacedNote`, `Clef`.
- Produces: `PracticeScreen({required String stageId})`.

- [ ] **Step 1: Write the failing test**

The overflow tests are the point of this task. They are what would have caught the original 211px bug.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:piano_tool/ui/practice/practice_screen.dart';
import 'package:piano_tool/ui/practice/stage_controller.dart';
import 'package:piano_tool/ui/keyboard/piano_keyboard_view.dart';
import 'package:piano_tool/ui/staff/staff_view.dart';
import 'package:piano_tool/ui/theme/app_theme.dart';

Widget _harness() => ProviderScope(
      overrides: [audioGrantedProvider.overrideWith((ref) async => true)],
      child: MaterialApp(
        theme: PianoTheme.light(),
        home: const PracticeScreen(stageId: 'stage_1'),
      ),
    );

/// Landscape sizes that bracket real phones, including the narrowest.
const _sizes = [Size(640, 360), Size(740, 360), Size(915, 412)];

void main() {
  for (final size in _sizes) {
    testWidgets('renders without overflow at ${size.width}x${size.height}',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_harness());
      await tester.pump();

      // A RenderFlex overflow surfaces as a thrown exception in tests, which
      // is exactly the failure the old screen shipped.
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shows the staff, the keyboard, and the transport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(740, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_harness());
    await tester.pump();

    expect(find.byType(StaffView), findsOneWidget);
    expect(find.byType(PianoKeyboardView), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('the title yields to the metrics rather than pushing them off',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_harness());
    await tester.pump();

    // Every metric stays on screen even at the narrowest width; the title is
    // the thing that ellipsizes.
    expect(find.textContaining('BPM'), findsOneWidget);
    expect(find.textContaining('Score'), findsOneWidget);
    expect(find.textContaining('Acc'), findsOneWidget);
  });

  testWidgets('all 61 keys fit without a scroll view', (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_harness());
    await tester.pump();

    expect(
      find.descendant(of: find.byType(PianoKeyboardView), matching: find.byType(Scrollable)),
      findsNothing,
    );
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

```bash
verify-on-vm "<repo>" "flutter test test/ui/practice/practice_screen_test.dart"
```

- [ ] **Step 3: Write the transport column**

`lib/ui/practice/transport_column.dart`. Fixed 60dp wide, which is honest for icon buttons at a 48dp touch target on an axis with slack.

```dart
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// The left control column. Fixed width because it holds icon buttons at a
/// real touch target; the horizontal axis has room to spare.
class TransportColumn extends StatelessWidget {
  const TransportColumn({
    super.key,
    required this.isPlaying,
    required this.speed,
    required this.onPlayPause,
    required this.onStop,
    required this.onReplay,
    required this.onSpeedChanged,
  });

  static const double width = 60;

  final bool isPlaying;
  final double speed;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final VoidCallback onReplay;
  final ValueChanged<double> onSpeedChanged;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colors.paper3,
        border: Border(right: BorderSide(color: colors.rule)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onPlayPause,
            iconSize: 22,
            style: IconButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.accentInk,
            ),
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            tooltip: isPlaying ? 'Pause' : 'Play',
          ),
          const SizedBox(height: PianoSpacing.sm),
          IconButton(
            onPressed: onStop,
            iconSize: 18,
            icon: const Icon(Icons.stop),
            tooltip: 'Stop and hold position',
          ),
          IconButton(
            onPressed: onReplay,
            iconSize: 18,
            icon: const Icon(Icons.replay),
            tooltip: 'Replay from the start',
          ),
          const SizedBox(height: PianoSpacing.xs),
          Text('${speed.toStringAsFixed(1)}x',
              style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
```

Stop and Replay carry different tooltips because they now do different things. Do not collapse them.

- [ ] **Step 4: Write the HUD**

`lib/ui/practice/practice_hud.dart`. The title is the element that yields.

```dart
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class PracticeHud extends StatelessWidget {
  const PracticeHud({
    super.key,
    required this.title,
    required this.tempo,
    required this.score,
    required this.accuracy,
    required this.progress,
    this.onBack,
  });

  final String title;
  final int tempo;
  final int score;
  final double accuracy;
  final double progress;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final text = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: PianoSpacing.sm),
          decoration: BoxDecoration(
            color: colors.paper2,
            border: Border(bottom: BorderSide(color: colors.rule)),
          ),
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  iconSize: 18,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Back',
                ),
              // The title yields, never the metrics. This is what stops the
              // header collapsing to "C ..." on a narrow screen.
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleLarge,
                ),
              ),
              const SizedBox(width: PianoSpacing.sm),
              _Metric(label: 'BPM', value: '$tempo'),
              const SizedBox(width: PianoSpacing.md),
              _Metric(label: 'Score', value: '$score'),
              const SizedBox(width: PianoSpacing.md),
              _Metric(label: 'Acc', value: '${(accuracy * 100).toStringAsFixed(1)}%'),
            ],
          ),
        ),
        SizedBox(
          height: 2,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: colors.rule2,
            valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ', style: text.labelSmall),
        Text(value, style: text.labelLarge),
      ],
    );
  }
}
```

- [ ] **Step 5: Write the screen**

`lib/ui/practice/practice_screen.dart`. Sizing rules come straight from the spec: the control column is fixed, the HUD wraps its content, the keyboard is clamped, and the staff takes everything left.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/engine_models.dart';
import '../keyboard/piano_keyboard_view.dart';
import '../staff/staff_geometry.dart';
import '../staff/staff_painter.dart';
import '../staff/staff_view.dart';
import 'practice_hud.dart';
import 'stage_controller.dart';
import 'transport_column.dart';

class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key, required this.stageId});

  final String stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stageControllerProvider(stageId));
    final controller = ref.read(stageControllerProvider(stageId).notifier);

    final notes = <PlacedNote>[
      for (var i = 0; i < state.notes.length; i++)
        (
          midi: state.notes[i].midiNote,
          startBeat: state.notes[i].startBeat,
          state: i < state.noteStates.length ? state.noteStates[i] : NoteState.upcoming,
        ),
    ];

    final due = {
      for (var i = 0; i < notes.length; i++)
        if (notes[i].state == NoteState.active) notes[i].midi,
    };

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            TransportColumn(
              isPlaying: state.status == StageEngineStatus.playing,
              speed: state.speed,
              onPlayPause: () => state.status == StageEngineStatus.playing
                  ? controller.pause()
                  : (state.status == StageEngineStatus.paused
                      ? controller.resume()
                      : controller.start()),
              onStop: controller.stop,
              onReplay: controller.replay,
              onSpeedChanged: controller.setSpeed,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Keyboard takes a fifth of the height, floored and capped so
                  // it stays legible on a short screen without eating a tall one.
                  final keyboardHeight =
                      (constraints.maxHeight * 0.21).clamp(64.0, 88.0);

                  return Column(
                    children: [
                      PracticeHud(
                        title: state.level.title,
                        tempo: state.level.tempo,
                        score: state.score,
                        accuracy: state.accuracy,
                        progress: state.progress,
                        onBack: Navigator.of(context).canPop()
                            ? () => Navigator.of(context).pop()
                            : null,
                      ),
                      // The staff takes the remainder, so it grows on a larger
                      // screen instead of leaving a dead band.
                      Expanded(
                        child: StaffView(
                          systems: [(clef: Clef.treble, notes: notes)],
                          currentBeat: state.currentBeat,
                          totalBeats: (state.level.totalMeasures *
                                  state.level.beatsPerMeasure)
                              .toDouble(),
                          beatsPerMeasure: state.level.beatsPerMeasure,
                          pixelsPerBeat: 70,
                        ),
                      ),
                      SizedBox(
                        height: keyboardHeight,
                        child: PianoKeyboardView(due: due),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

Note what is absent: no fixed-width child anywhere inside a `Row` that lacks slack, which is what structurally prevents the 211px class of bug from returning.

- [ ] **Step 6: Run the suite**

```bash
verify-on-vm "<repo>" "flutter test && flutter analyze --no-fatal-infos"
```

Expected: 86 passing, zero failures.

- [ ] **Step 7: Commit**

```bash
git add lib/ui/practice test/ui/practice/practice_screen_test.dart
git commit -m "Add the practice screen from the spec

A fixed 60dp control column with the HUD, staff, and keyboard stacked beside
it. The control column is the only fixed size, and it sits on a horizontal axis
with slack, so nothing here can reproduce the 211px overflow the old transport
row shipped.

The title ellipsizes instead of the metrics, which is what stops the header
collapsing to \"C ...\". The staff takes the remaining height so it grows rather
than leaving a dead band, and the keyboard is clamped so it stays legible on a
short screen without eating a tall one.

Widget tests assert no overflow at three landscape sizes, including the
narrowest, because that is the failure the old screen shipped."
```

---

### Task 5: Microphone permission, and the audio path

The legacy screen called `initialize()`, ignored the boolean it returned, and did nothing when permission was denied. The app just sat there listening to nothing.

**Files:**
- Create: `lib/ui/practice/mic_permission_gate.dart`
- Modify: `lib/ui/practice/practice_screen.dart`
- Modify: `lib/ui/practice/stage_controller.dart` (feed pitch events to the engine)
- Test: `test/ui/practice/mic_permission_gate_test.dart`

**Interfaces:**
- Consumes: `audioGrantedProvider` from Task 2.
- Produces: `MicPermissionGate({required Widget child})`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:piano_tool/ui/practice/mic_permission_gate.dart';
import 'package:piano_tool/ui/practice/stage_controller.dart';
import 'package:piano_tool/ui/theme/app_theme.dart';

Widget _harness(Future<bool> Function(Ref) grant) => ProviderScope(
      overrides: [audioGrantedProvider.overrideWith(grant)],
      child: MaterialApp(
        theme: PianoTheme.light(),
        home: const Scaffold(
          body: MicPermissionGate(child: Text('practice')),
        ),
      ),
    );

void main() {
  testWidgets('shows the child once the microphone is granted', (tester) async {
    await tester.pumpWidget(_harness((ref) async => true));
    await tester.pumpAndSettle();
    expect(find.text('practice'), findsOneWidget);
  });

  testWidgets('explains the problem and offers a retry when denied',
      (tester) async {
    await tester.pumpWidget(_harness((ref) async => false));
    await tester.pumpAndSettle();

    expect(find.text('practice'), findsNothing);
    expect(find.textContaining('microphone'), findsWidgets);
    expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);
  });

  testWidgets('surfaces a failure instead of hanging', (tester) async {
    await tester.pumpWidget(_harness((ref) async => throw Exception('no device')));
    await tester.pumpAndSettle();
    expect(find.textContaining('microphone'), findsWidgets);
  });

  testWidgets('shows progress while the request is outstanding', (tester) async {
    final completer = Completer<bool>();
    await tester.pumpWidget(_harness((ref) => completer.future));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('practice'), findsOneWidget);
  });
}
```

Add `import 'dart:async';` for `Completer`.

- [ ] **Step 2: Implement the gate**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'stage_controller.dart';

/// Practice needs the microphone, so a denial has to be visible. The previous
/// screen ignored the permission result and simply never scored anything.
class MicPermissionGate extends ConsumerWidget {
  const MicPermissionGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(audioGrantedProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _Denied(
            message: 'The microphone could not be started. '
                'Piano Tool listens for the notes you play, so practice needs it.',
            onRetry: () => ref.invalidate(audioGrantedProvider),
          ),
          data: (granted) => granted
              ? child
              : _Denied(
                  message: 'Piano Tool needs the microphone to hear what you play. '
                      'Without it, notes cannot be scored.',
                  onRetry: () => ref.invalidate(audioGrantedProvider),
                ),
        );
  }
}

class _Denied extends StatelessWidget {
  const _Denied({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No microphone', style: text.headlineSmall),
            const SizedBox(height: PianoSpacing.xs),
            Text(message, style: text.bodyMedium),
            const SizedBox(height: PianoSpacing.md),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Wrap the practice screen**

In `practice_screen.dart`, wrap the `Row` in `MicPermissionGate`. The transport and staff stay reachable only once audio is running, which is honest: without a microphone nothing can be scored.

- [ ] **Step 4: Feed pitch events to the engine**

In `stage_controller.dart`, the controller currently never receives audio. Add a subscription so detected pitches reach the engine, and expose what is sounding for the keyboard.

Add to `StageUiState`: `final Set<int> sounding;` defaulting to `const {}`, carried through `copyWith`.

In the provider, after building the controller, subscribe:

```dart
  // Pitch events only flow once permission was granted; the gate makes sure
  // the screen is not reachable before then.
  ref.listen(audioPitchStreamProvider, (_, next) {
    next.whenData(controller.onPitch);
  });
```

with

```dart
final audioPitchStreamProvider = StreamProvider<PitchEvent>((ref) {
  final engine = AudioEngine();
  ref.onDispose(engine.dispose);
  return engine.pitchStream;
});
```

and on the controller:

```dart
  /// A detected pitch both scores against the level and lights the keyboard.
  void onPitch(PitchEvent event) {
    _engine.processPitchEvent(event);
    state = state.copyWith(sounding: {event.midiNote});
    _sync();
  }
```

Pass `state.sounding` into `PianoKeyboardView(playing: ...)` in the screen.

If wiring the stream through the same `AudioEngine` instance as `audioGrantedProvider` proves awkward, hoist a single `audioEngineProvider` that both depend on, so only one engine is ever created. Say in your report which shape you used.

- [ ] **Step 5: Run the suite and commit**

```bash
verify-on-vm "<repo>" "flutter test && flutter analyze --no-fatal-infos"
```

Expected: 90 passing, zero failures.

```bash
git add lib/ui/practice test/ui/practice/mic_permission_gate_test.dart
git commit -m "Show a real state when the microphone is denied

The old screen called initialize(), discarded the boolean it returned, and did
nothing on refusal, so the app sat there scoring nothing with no explanation.
Permission now gates the practice screen, explains why the microphone is needed,
and offers a retry.

Detected pitches also reach the engine and light the keyboard, which is what
makes the keyboard a display of real input rather than decoration."
```

---

### Task 6: Delete the dead level pipeline and the legacy screen

Cleanup with a real payoff: it removes a silent-failure path that is actively misleading.

**Files:**
- Modify: `lib/data/level_repository.dart`
- Delete: `assets/levels/twinkle_twinkle.json`
- Delete: `lib/ui/game/game_screen.dart`
- Delete: `lib/ui/staff/horizontal_staff.dart`
- Delete: `lib/ui/keyboard/piano_keyboard.dart`
- Modify: `lib/main.dart`
- Modify: `pubspec.yaml`
- Test: `test/data/level_repository_test.dart`

- [ ] **Step 1: Confirm what is actually unreachable**

```bash
grep -rn "loadAll\|GameScreen\|HorizontalStaff\|PianoKeyboard\b" lib/ test/ --include=*.dart | grep -v '\.freezed\.\|\.g\.'
```

`loadAll` should appear only at its definition. `GameScreen` should appear only in `main.dart` and its own file. If anything else references them, stop and report rather than deleting.

- [ ] **Step 2: Write a test pinning the repository's real behaviour**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/data/level_repository.dart';

void main() {
  test('ships three built-in stages, in order', () {
    final stages = LevelRepository().getAllStages();
    expect(stages.map((s) => s.id).toList(), ['stage_1', 'stage_2', 'stage_3']);
    expect(stages.map((s) => s.order).toList(), [1, 2, 3]);
  });

  test('every stage has a level with measures and notes', () {
    for (final stage in LevelRepository().getAllStages()) {
      expect(stage.level.measures, isNotEmpty, reason: stage.id);
      expect(
        stage.level.measures.expand((m) => m.notes),
        isNotEmpty,
        reason: stage.id,
      );
    }
  });

  test('note beats are ordered within each level', () {
    for (final stage in LevelRepository().getAllStages()) {
      final beats = stage.level.measures.expand((m) => m.notes).map((n) => n.startBeat).toList();
      final sorted = [...beats]..sort();
      expect(beats, sorted, reason: stage.id);
    }
  });
}
```

Adapt `getAllStages()` to the repository's real accessor if the name differs.

- [ ] **Step 3: Remove the dead loader**

Delete `loadAll()` from `lib/data/level_repository.dart` along with the now-unused `dart:convert` and `rootBundle` imports. Leave `_loadBuiltInLevels` and the constructor call intact.

Add a comment at the top of the class stating that levels are defined in Dart and that there is no JSON pipeline, so the next person does not go looking for one.

Delete `assets/levels/twinkle_twinkle.json` and remove the `- assets/levels/` entry from `pubspec.yaml`, since no asset remains in that directory.

- [ ] **Step 4: Point main.dart at the practice screen**

Replace `home: const GameScreen()` with `home: const PracticeScreen(stageId: 'stage_1')` and fix the import. Routing across five screens is Plan 3; this plan just makes the app open on the screen it now has.

- [ ] **Step 5: Delete the legacy widgets**

```bash
git rm lib/ui/game/game_screen.dart lib/ui/staff/horizontal_staff.dart lib/ui/keyboard/piano_keyboard.dart
```

Then re-run the reference check from Step 1 to confirm nothing dangles.

- [ ] **Step 6: Run the suite**

```bash
verify-on-vm "<repo>" "flutter test && flutter analyze --no-fatal-infos"
```

Expected: all tests pass, and **analyze should fall well below 75**, because most of the remaining infos live in the files just deleted. Record the new number; it becomes the ceiling for Plan 3.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "Delete the dead level pipeline and the legacy practice screen

LevelRepository.loadAll was never called from anywhere. It read a manifest.json
and a stages.json that do not exist, and caught its own failure so the dead path
never announced itself. The only asset in assets/levels was written in a shape
LevelModel.fromJson cannot parse. All of it is gone; levels are defined in Dart
and now say so.

Also removes the pre-revamp practice screen, the scrolling staff wrapper, and
the touch keyboard, all replaced by this plan. The app opens on the new practice
screen."
```

---

## Self-review

**Spec coverage.** Persistence (Task 1), the Riverpod wrapping that removes per-frame rebuilds (Task 2), keyboard as visualization sized to available width (Task 3), the practice layout with its 60dp control column and yielding title (Task 4), microphone permission as a real state plus the speed slider and the Stop/Replay split (Tasks 2 and 5). Deferred to Plan 3 and stated in the spec as separate screens: home, level select, results, and settings, plus the router that connects them.

**Placeholders.** None. Three steps deliberately verify an assumption against the codebase before acting: the freezed event API in Task 2, the repository accessor name in Task 6 Step 2, and the reachability check in Task 6 Step 1.

**Type consistency.** `StageUiState` is defined in Task 2 and consumed in Tasks 4 and 5; `sounding` is added to it in Task 5 and read in Task 4's screen, so Task 5 must update the screen it touches. `PlacedNote` and `Clef` come from Plan 1 and are used unchanged. `KeyboardGeometry` is defined in Task 3 and used only by its own painter. `audioGrantedProvider` is defined in Task 2 and overridden in the tests of Tasks 2, 4, and 5.

**Known ordering hazard.** Task 5 adds a field to `StageUiState` and changes `practice_screen.dart`, which Task 4 creates. Running them out of order will not compile. They are sequential on purpose.

---

### Task 7: Implement setPlaybackSpeed in the engine

Added after Task 2, when the "already works" claim turned out to be false. This is the one place Plan 2 reaches below `lib/ui/`, and it is unavoidable: wiring a slider to a stub leaves the same dead control with more code behind it.

**Files:**
- Modify: `lib/engine/stage_engine.dart`
- Test: `test/engine/stage_engine_speed_test.dart`

**Interfaces:**
- Produces: a working `StageEngine.setPlaybackSpeed(double)` and a `playbackSpeed` getter.

- [ ] **Step 1: Read the current state of the engine's timing**

```bash
sed -n '240,270p' lib/engine/stage_engine.dart
grep -n '_config\|setPlaybackSpeed' lib/engine/stage_engine.dart
```

`_config` is `final` and assigned once, so `_config.playbackSpeed` can never change. The tick reads it at `_startPlaybackTimer`.

- [ ] **Step 2: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/data/level_repository.dart';
import 'package:piano_tool/engine/stage_engine.dart';

void main() {
  StageEngine engineForStage1() =>
      StageEngine(level: LevelRepository().getAllStages().first.level);

  test('playback speed defaults to 1.0', () {
    final e = engineForStage1();
    addTearDown(e.dispose);
    expect(e.playbackSpeed, 1.0);
  });

  test('setting the speed is retained', () {
    final e = engineForStage1();
    addTearDown(e.dispose);
    e.setPlaybackSpeed(1.5);
    expect(e.playbackSpeed, 1.5);
  });

  test('speed is clamped to a usable range', () {
    final e = engineForStage1();
    addTearDown(e.dispose);
    e.setPlaybackSpeed(99);
    expect(e.playbackSpeed, lessThanOrEqualTo(2.0));
    e.setPlaybackSpeed(0.01);
    expect(e.playbackSpeed, greaterThanOrEqualTo(0.25));
  });

  test('a faster speed advances more beats in the same elapsed time', () async {
    final slow = engineForStage1()..setPlaybackSpeed(0.5);
    final fast = engineForStage1()..setPlaybackSpeed(2.0);
    addTearDown(slow.dispose);
    addTearDown(fast.dispose);

    slow.start();
    fast.start();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(fast.state.currentBeat, greaterThan(slow.state.currentBeat),
        reason: 'speed must affect how fast the playhead moves');
  });

  test('changing speed mid-playback takes effect without restarting the stage',
      () async {
    final e = engineForStage1();
    addTearDown(e.dispose);

    e.start();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final beforeChange = e.state.currentBeat;

    e.setPlaybackSpeed(2.0);
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(e.state.currentBeat, greaterThan(beforeChange),
        reason: 'the playhead must keep moving across a speed change');
    expect(e.state.engineState.toString(), contains('playing'),
        reason: 'changing speed must not stop playback');
  });
}
```

- [ ] **Step 3: Run it to verify it fails**

```bash
verify-on-vm "<repo>" "flutter test test/engine/stage_engine_speed_test.dart"
```

Expected: the retention and speed-effect tests fail, because the setter does nothing.

- [ ] **Step 4: Implement**

Add a mutable field beside `_config`, keeping `_config` final so nothing else changes:

```dart
  /// Playback speed multiplier. Held separately from _config, which is final.
  double _playbackSpeed = 1.0;

  double get playbackSpeed => _playbackSpeed;
```

Initialise it from the config in the constructor body so an explicitly
configured speed is still honoured:

```dart
    _playbackSpeed = _config.playbackSpeed;
```

Replace every read of `_config.playbackSpeed` (the playback tick and
`seekToBeat`) with `_playbackSpeed`.

Then make the setter real:

```dart
  /// Set playback speed. Restarts the tick when playing, so a change takes
  /// effect immediately rather than at the next start.
  void setPlaybackSpeed(double speed) {
    final clamped = speed.clamp(0.25, 2.0);
    if (clamped == _playbackSpeed) return;
    _playbackSpeed = clamped;

    if (_state.engineState == StageEngineStatus.playing) {
      _startPlaybackTimer(); // cancels the existing timer first
    }
    _notifyStateChanged();
  }
```

Confirm `_startPlaybackTimer` calls `_stopPlaybackTimer` first. It does at the
time of writing; if that changes, stop the timer explicitly rather than leaking
a second one.

- [ ] **Step 5: Run the tests and the whole suite**

```bash
verify-on-vm "<repo>" "flutter test && flutter analyze --no-fatal-infos"
```

The timing tests are wall-clock dependent. If one proves flaky on the VM,
widen the delay rather than weakening the assertion, and say so in your report.

- [ ] **Step 6: Commit**

```bash
git add lib/engine/stage_engine.dart test/engine/stage_engine_speed_test.dart
git commit -m "Implement setPlaybackSpeed instead of ignoring it

The method's body was two comments and it discarded its argument. _config is
final, so the playback tick read a speed that was permanently 1.0 no matter what
any caller asked for. Speed now lives in a mutable field, and changing it while
playing restarts the tick so it takes effect immediately.

Documentation in three places claimed this method already worked and only needed
connecting from the UI. It did not, and wiring a control to it would have left
the same dead slider."
```

---

### Task 8: Cap the staff height and follow the playhead

Added after Task 4, when six rendered screenshots showed what 92 passing tests
did not. The staff sizes every glyph from its band height, which was right when
Plan 1's goldens gave it a 220px band and wrong the moment the practice screen
gave it an `Expanded` one. At 640x360 the clef is taller than the keyboard, the
time signature eats a third of the viewport, three of sixteen beats are visible,
and the playhead is a few hundred pixels off the right edge because nothing ever
scrolls. Runs before Task 5.

**Files:**
- Modify: `lib/ui/staff/staff_geometry.dart`
- Modify: `lib/ui/staff/staff_view.dart`
- Modify: `lib/ui/staff/staff_painter.dart`
- Modify: `lib/ui/practice/practice_screen.dart`
- Modify: `test/flutter_test_config.dart`
- Test: `test/ui/staff/staff_scroll_test.dart`

**Interfaces:**
- Produces: a top-level pure function in `staff_geometry.dart`,
  `double staffScrollOffset({required double playheadX, required double
  viewportWidth, required double contentWidth, double anchorFraction = 0.3})`,
  returning the number of pixels the staff content is shifted left; and
  `StaffView` gaining `double maxStaffHeight` (default `120`) and
  `double currentBeat`.

- [ ] **Step 1: Write the failing scroll test**

The function is pure, so it needs no widget. Three behaviours: it does not
scroll before the playhead reaches the anchor, it keeps the playhead pinned at
the anchor through the middle of the piece, and it stops at the end rather than
scrolling past the last note into empty space.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/ui/staff/staff_geometry.dart';

void main() {
  const viewport = 580.0;
  const content = 1400.0;
  const anchor = 0.3 * viewport; // 174

  test('does not scroll while the playhead is left of the anchor', () {
    expect(
      staffScrollOffset(
          playheadX: 0, viewportWidth: viewport, contentWidth: content),
      0,
    );
    expect(
      staffScrollOffset(
          playheadX: anchor - 1, viewportWidth: viewport, contentWidth: content),
      0,
    );
  });

  test('pins the playhead at the anchor through the middle', () {
    expect(
      staffScrollOffset(
          playheadX: 500, viewportWidth: viewport, contentWidth: content),
      closeTo(500 - anchor, 1e-9),
    );
  });

  test('stops when the end of the content reaches the right edge', () {
    expect(
      staffScrollOffset(
          playheadX: 1400, viewportWidth: viewport, contentWidth: content),
      closeTo(content - viewport, 1e-9),
    );
  });

  test('never scrolls when the content is narrower than the viewport', () {
    expect(
      staffScrollOffset(
          playheadX: 300, viewportWidth: viewport, contentWidth: 400),
      0,
    );
  });
}
```

- [ ] **Step 2: Run it and confirm it fails**

```bash
verify-on-vm "<repo>" "flutter test test/ui/staff/staff_scroll_test.dart"
```

Expected: FAIL, `staffScrollOffset` is not defined.

- [ ] **Step 3: Implement the function**

```dart
/// Pixels the staff content is shifted left so the playhead stays visible.
///
/// The playhead sits still at [anchorFraction] of the viewport while the music
/// moves under it, which is what a scrolling score does. Clamped at both ends:
/// no scrolling before the anchor is reached, and none past the final beat.
double staffScrollOffset({
  required double playheadX,
  required double viewportWidth,
  required double contentWidth,
  double anchorFraction = 0.3,
}) {
  final maxOffset = contentWidth - viewportWidth;
  if (maxOffset <= 0) return 0;
  final anchor = viewportWidth * anchorFraction;
  return (playheadX - anchor).clamp(0.0, maxOffset);
}
```

- [ ] **Step 4: Run it green, then cap the staff height**

`StaffView` currently hands the full band height to `StaffGeometry`. Give it a
`maxStaffHeight` (default `120`) and size the geometry from
`min(bandHeight, maxStaffHeight)`, then centre the resulting staff vertically in
whatever band it was given. Every glyph stays in staff-spaces, so nothing else
changes: the clef, the time signature, and the noteheads all shrink together.

Pass `currentBeat` through to the painter and translate the canvas by
`-staffScrollOffset(...)` before drawing notes, leaving the clef and time
signature pinned to the left edge so they do not scroll away.

- [ ] **Step 5: Write the height-cap widget test**

```dart
testWidgets('the staff never grows past its cap in a tall band', (tester) async {
  await tester.pumpWidget(/* StaffView with maxStaffHeight: 120 in a 400dp band */);
  final size = tester.getSize(find.byType(StaffView));
  expect(size.height, 400);
  // The painted staff, not the band, is what is capped.
  // Assert against the geometry the view built, not the widget box.
});
```

Assert the geometry's staff height is 120 and not 400. If `StaffView` does not
expose its geometry, expose it for the test rather than asserting on pixels.

- [ ] **Step 6: Load MaterialIcons in the shared test harness**

`test/flutter_test_config.dart` loads the three bundled fonts but not
`MaterialIcons`, which `flutter test` does not ship. Every transport icon
therefore renders as a tofu box in any golden. This is the same defect that
already shipped once in Plan 1. Load it alongside the other three.

- [ ] **Step 7: Full suite, then look at the pixels**

```bash
verify-on-vm "<repo>" "flutter test && flutter analyze --no-fatal-infos"
```

Then re-render the six practice-screen shots at 640x360, 740x360 and 915x412 in
both themes, mid-playback, and open every one. The playhead must be visible and
roughly a third across, the clef must be a sensible fraction of the band, and no
notehead may cross into the keyboard. A green suite is not evidence here. It has
been wrong three times.

- [ ] **Step 8: Commit**

```bash
git add lib/ui/staff test/ui/staff/staff_scroll_test.dart test/flutter_test_config.dart lib/ui/practice/practice_screen.dart
git commit -m "Cap the staff height and scroll it to follow the playhead"
```
