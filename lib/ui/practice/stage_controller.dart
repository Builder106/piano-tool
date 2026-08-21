import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/audio_engine.dart';
import '../../data/level_repository.dart';
import '../../data/progress_repository.dart';
import '../../engine/stage_engine.dart';
import '../../models/audio_models.dart';
import '../../models/engine_models.dart';
import '../../models/level_models.dart';

/// One engine for the whole app. Permission and the pitch stream both hang off
/// it, so a single microphone is opened rather than one per provider.
final audioEngineProvider = Provider<AudioEngine>((ref) {
  final engine = AudioEngine();
  ref.onDispose(engine.dispose);
  return engine;
});

/// Whether the microphone was granted. Overridden in tests so the controller
/// can run without hardware.
final audioGrantedProvider = FutureProvider<bool>((ref) async {
  final engine = ref.watch(audioEngineProvider);
  final granted = await engine.initialize();
  if (granted) await engine.start();
  return granted;
});

/// Detected pitches. The engine only produces events after [audioGrantedProvider]
/// started it, so listening before permission is granted is simply quiet.
final audioPitchStreamProvider = StreamProvider<PitchEvent>(
    (ref) => ref.watch(audioEngineProvider).pitchStream);

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
    this.sounding = const {},
  });

  final LevelModel level;
  final List<LevelNote> notes;
  final List<NoteState> noteStates;
  final double currentBeat;
  final int score;
  final double accuracy;
  final StageEngineStatus status;
  final double speed;

  /// MIDI notes the microphone is hearing right now.
  final Set<int> sounding;

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
    Set<int>? sounding,
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
        sounding: sounding ?? this.sounding,
      );
}

class StageController extends StateNotifier<StageUiState> {
  StageController(
      this._engine, this._stageId, this._progress, StageUiState initial)
      : super(initial) {
    _sub = _engine.events.listen(_onEvent);
  }

  final StageEngine _engine;
  final String _stageId;
  final ProgressRepository _progress;
  StreamSubscription<StageEvent>? _sub;

  /// The engine's own event stream, exposed so the screen can react to the
  /// same completion signal that [_onEvent] already uses to write progress,
  /// rather than inventing a second way to detect it.
  Stream<StageEvent> get events => _engine.events;

  /// One decay timer per lit key. [PitchDetector] only emits an event while
  /// it hears a pitch -- silence produces nothing -- so without a decay a
  /// note would stay lit forever once heard once. Each detection of a note
  /// resets its own timer; if the note is not heard again within the decay
  /// window, it drops out of [StageUiState.sounding].
  final Map<int, Timer> _soundingTimers = {};
  static const Duration _soundingDecay = Duration(milliseconds: 350);

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
    // A paused transport should not show a lit key either.
    _clearSounding();
  }

  void resume() {
    _engine.resume();
    _sync();
  }

  /// Halts and holds position. Distinct from [replay], which rewinds.
  void stop() {
    _engine.stop();
    _sync();
    // Nothing is being listened for once stopped, so no key should stay lit.
    _clearSounding();
  }

  /// A detected pitch both scores against the level and lights the keyboard.
  ///
  /// The microphone keeps listening across Stop and Pause -- [stop] only
  /// halts the [StageEngine], not the audio engine -- so without this guard a
  /// stray tail of a decaying note (or a hand still on the keys) would relight
  /// a key on a keyboard whose transport reads "stopped." Mirrors the same
  /// check [StageEngine.processPitchEvent] already applies internally.
  void onPitch(PitchEvent event) {
    if (state.status != StageEngineStatus.playing) return;
    _engine.processPitchEvent(event);

    final note = event.midiNote;
    _soundingTimers[note]?.cancel();
    _soundingTimers[note] = Timer(_soundingDecay, () => _dropSounding(note));
    state = state.copyWith(sounding: {...state.sounding, note});
    _sync();
  }

  /// Drops a single note out of [StageUiState.sounding] once its decay timer
  /// fires without a fresh detection refreshing it.
  void _dropSounding(int note) {
    _soundingTimers.remove(note);
    if (!state.sounding.contains(note)) return;
    state = state.copyWith(sounding: {...state.sounding}..remove(note));
  }

  void _clearSounding() {
    for (final timer in _soundingTimers.values) {
      timer.cancel();
    }
    _soundingTimers.clear();
    state = state.copyWith(sounding: const {});
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
    event.whenOrNull(stageCompleted: (accuracy, score, totalNotes, hitNotes) {
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
    for (final timer in _soundingTimers.values) {
      timer.cancel();
    }
    _soundingTimers.clear();
    _sub?.cancel();
    _engine.dispose();
    super.dispose();
  }
}

final stageControllerProvider =
    StateNotifierProvider.family<StageController, StageUiState, String>(
        (ref, stageId) {
  // By the time a practice route is reachable, LevelListScreen has already
  // awaited levelRepositoryProvider to render the stage list the user tapped
  // -- requireValue asserts that instead of silently falling back to an
  // empty catalog.
  final stages = ref.read(levelRepositoryProvider).requireValue.getAllStages();
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

  final controller = StageController(
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
      speed: engine.playbackSpeed,
    ),
  );

  // Pitch events only flow once permission was granted; the gate makes sure
  // the screen is not reachable before then.
  //
  // This subscription lives as long as the provider does, same as the
  // engine's own event subscription cancelled in StageController.dispose --
  // the provider is not autoDispose, so both share the same accepted
  // lifetime tradeoff documented where the screen stops the controller.
  ref.listen(audioPitchStreamProvider, (_, next) {
    next.when(
      data: controller.onPitch,
      // A stream error (a device hiccup, the mic disconnecting mid-session)
      // does not stop the transport or unmount the screen; only this one
      // pitch is lost. There is no existing error surface for a mid-session
      // event this rare -- the permission gate only speaks to the initial
      // grant -- so this is logged rather than given a new UI state.
      error: (error, stackTrace) =>
          debugPrint('audioPitchStreamProvider error: $error'),
      loading: () {},
    );
  });

  return controller;
});

// Narrow slices. A widget watching one of these does not rebuild when an
// unrelated field changes, which is the whole point of this file.
final currentBeatProvider = Provider.family<double, String>((ref, id) =>
    ref.watch(stageControllerProvider(id).select((s) => s.currentBeat)));
final scoreProvider = Provider.family<int, String>(
    (ref, id) => ref.watch(stageControllerProvider(id).select((s) => s.score)));
final accuracyProvider = Provider.family<double, String>((ref, id) =>
    ref.watch(stageControllerProvider(id).select((s) => s.accuracy)));
final engineStatusProvider = Provider.family<StageEngineStatus, String>(
    (ref, id) =>
        ref.watch(stageControllerProvider(id).select((s) => s.status)));
final noteStatesProvider = Provider.family<List<NoteState>, String>((ref, id) =>
    ref.watch(stageControllerProvider(id).select((s) => s.noteStates)));
final playbackSpeedProvider = Provider.family<double, String>(
    (ref, id) => ref.watch(stageControllerProvider(id).select((s) => s.speed)));
final soundingProvider = Provider.family<Set<int>, String>((ref, id) =>
    ref.watch(stageControllerProvider(id).select((s) => s.sounding)));
