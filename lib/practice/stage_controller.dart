import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../audio/audio_engine.dart';
import '../audio/tone_synthesizer.dart';
import '../data/level_repository.dart';
import '../data/progress_repository.dart';
import '../data/settings_repository.dart';
import '../engine/stage_engine.dart';
import '../models/audio_models.dart';
import '../models/engine_models.dart';
import '../models/level_models.dart';
import '../services/midi_service.dart';
import '../services/touch_keys.dart';

/// One engine for the whole app. Permission and the pitch stream both hang off
/// it, so a single microphone is opened rather than one per provider.
final audioEngineProvider = Provider<AudioEngine>((ref) {
  final config = ref.watch(
    settingsProvider.select((settings) => settings.toAudioEngineConfig()),
  );
  final engine = AudioEngine(config: config);
  ref.onDispose(engine.dispose);
  return engine;
});

/// Whether the microphone was granted. Overridden in tests so the controller
/// can run without hardware.
final audioGrantedProvider = FutureProvider<bool>((ref) async {
  final engine = ref.watch(audioEngineProvider);
  return engine.initialize();
});

/// Owns the microphone for exactly as long as a practice route is mounted.
final practiceAudioSessionProvider = FutureProvider.autoDispose<void>((
  ref,
) async {
  final granted = await ref.watch(audioGrantedProvider.future);
  if (!granted) throw StateError('Microphone permission was not granted');
  final engine = ref.read(audioEngineProvider);
  var disposed = false;
  ref.onDispose(() {
    disposed = true;
    unawaited(engine.stop());
  });
  await engine.start();
  if (disposed) await engine.stop();
});

/// Detected pitches. The route-scoped session starts and stops the engine.
final audioPitchStreamProvider = StreamProvider<PitchEvent>(
  (ref) => ref.watch(audioEngineProvider).pitchStream,
);

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
    this.loopRange,
    int? loopMeasure,
    this.isDemonstrating = false,
    this.isMicrophoneSuspended = false,
    this.selectedInputSource = PracticeInputSource.both,
    this.practiceMode = PracticeMode.timed,
    this.waitingHint,
    this.isMetronomeEnabled = false,
    this.isCountInEnabled = false,
    this.handSelection = HandSelection.both,
  }) : _loopMeasure = loopMeasure;

  final LevelModel level;
  final List<LevelNote> notes;
  final List<NoteState> noteStates;
  final double currentBeat;
  final int score;
  final double accuracy;
  final StageEngineStatus status;
  final double speed;

  /// Active hand selection for practice: both, right, or left.
  final HandSelection handSelection;

  /// Whether the hand assignment of the active level is known from authored voice data.
  bool get isHandAssignmentKnown => level.isHandAssignmentKnown;

  /// Whether the hand assignment of the active level is unknown.
  bool get isHandAssignmentUnknown => level.isHandAssignmentUnknown;

  /// The set of hand selections supported by the active level's authored voice data.
  Set<HandSelection> get supportedHands => level.supportedHands;

  /// MIDI notes the microphone is hearing right now.
  final Set<int> sounding;

  /// The measure range (startMeasure, endMeasure) being played over and over, or null.
  final (int, int)? loopRange;

  final int? _loopMeasure;

  /// The bar being played over and over, or null.
  int? get loopMeasure =>
      _loopMeasure ??
      (loopRange != null && loopRange!.$1 == loopRange!.$2
          ? loopRange!.$1
          : loopRange?.$1);

  /// Whether a phrase demonstration is currently playing via the synthesizer.
  final bool isDemonstrating;

  /// Whether microphone scoring is currently suspended (e.g. during phrase demonstration).
  final bool isMicrophoneSuspended;

  /// The learner's configured input source.
  final PracticeInputSource selectedInputSource;

  /// Current practice mode: timed or waiting.
  final PracticeMode practiceMode;

  /// Active contextual hint when waiting for input in waiting mode.
  final WaitingHint? waitingHint;

  /// Whether the metronome beat reference is enabled.
  final bool isMetronomeEnabled;

  /// Whether count-in before playback is enabled.
  final bool isCountInEnabled;

  /// Whether the practice is currently in waiting (learn notes) mode.
  bool get isWaitingMode => practiceMode == PracticeMode.waiting;

  /// Whether the practice is currently in timed (play in time) mode.
  bool get isTimedMode => practiceMode == PracticeMode.timed;

  /// Whether the stage is currently playing count-in beats prior to measure 0.
  bool get isCountingIn => currentBeat < 0.0;

  /// Active 1-based count-in beat number (e.g. 1, 2, 3, 4), or null when not counting in.
  int? get countInBeat {
    if (currentBeat >= 0.0) return null;
    final total = level.beatsPerMeasure > 0 ? level.beatsPerMeasure : 4;
    final count = (currentBeat + total).floor() + 1;
    return count.clamp(1, total);
  }

  /// Total count-in beats for the piece's meter.
  int? get countInTotalBeats => currentBeat < 0.0
      ? (level.beatsPerMeasure > 0 ? level.beatsPerMeasure : 4)
      : null;

  /// Effective BPM taking into account the base level tempo and playback speed multiplier.
  int get effectiveBpm => (level.tempo * speed).round();

  /// Effective double tempo.
  double get effectiveTempo => level.tempo * speed;

  /// Human-readable label showing speed multiplier and effective BPM.
  String get speedMultiplierLabel =>
      'Speed ${(speed * 100).round()}% ($effectiveBpm BPM)';

  /// Semantic / accessible representation of the stage state for assistive technology in both modes.
  String get accessibleDescription {
    final modeStr = switch (practiceMode) {
      PracticeMode.waiting => 'Waiting mode',
      PracticeMode.timed => 'Timed mode',
    };
    final statusStr = switch (status) {
      StageEngineStatus.idle => 'Ready',
      StageEngineStatus.playing => 'Playing',
      StageEngineStatus.paused => 'Paused',
      StageEngineStatus.completed => 'Completed',
      StageEngineStatus.stopped => 'Stopped',
    };
    final beatsPerMeasure = level.beatsPerMeasure > 0
        ? level.beatsPerMeasure
        : 4;
    final measure = (currentBeat ~/ beatsPerMeasure) + 1;
    final beatInMeasure = ((currentBeat % beatsPerMeasure).floor()) + 1;
    final posStr = 'Measure $measure, beat $beatInMeasure';

    final handPrefix = switch (handSelection) {
      HandSelection.both => '',
      HandSelection.right => 'Right hand. ',
      HandSelection.left => 'Left hand. ',
    };

    if (isCountingIn && countInBeat != null) {
      return '${handPrefix}Count-in: Beat $countInBeat of $countInTotalBeats. Speed ${(speed * 100).round()}% ($effectiveBpm BPM).';
    } else if (practiceMode == PracticeMode.waiting && waitingHint != null) {
      return '$handPrefix$modeStr: $statusStr. $posStr. ${waitingHint!.hintText}';
    } else if (practiceMode == PracticeMode.timed) {
      return '$handPrefix$modeStr: $statusStr. $posStr. Speed ${(speed * 100).round()}% ($effectiveBpm BPM). Score: $score, accuracy: ${(accuracy * 100).round()}%';
    } else {
      return '$handPrefix$modeStr: $statusStr. $posStr.';
    }
  }

  /// Effective input source during practice, accounting for microphone suspension.
  PracticeInputSource get effectiveInputSource {
    if (isMicrophoneSuspended) {
      return switch (selectedInputSource) {
        PracticeInputSource.microphone => PracticeInputSource.touch,
        PracticeInputSource.both => PracticeInputSource.midi,
        final other => other,
      };
    }
    return selectedInputSource;
  }

  /// Whether the microphone is currently actively scoring player input.
  bool get isMicrophoneScoringActive =>
      !isMicrophoneSuspended &&
      !isCountingIn &&
      selectedInputSource.usesMicrophone;

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
    int? loopMeasure,
    (int, int)? loopRange,
    bool clearLoop = false,
    bool? isDemonstrating,
    bool? isMicrophoneSuspended,
    PracticeInputSource? selectedInputSource,
    PracticeMode? practiceMode,
    WaitingHint? waitingHint,
    bool clearWaitingHint = false,
    bool? isMetronomeEnabled,
    bool? isCountInEnabled,
    HandSelection? handSelection,
  }) {
    final effectiveRange = clearLoop
        ? null
        : (loopRange ??
              (loopMeasure != null
                  ? (loopMeasure, loopMeasure)
                  : this.loopRange));
    final effectiveMeasure = clearLoop
        ? null
        : (loopMeasure ??
              (effectiveRange != null ? effectiveRange.$1 : _loopMeasure));
    return StageUiState(
      level: level,
      notes: notes,
      noteStates: noteStates ?? this.noteStates,
      currentBeat: currentBeat ?? this.currentBeat,
      score: score ?? this.score,
      accuracy: accuracy ?? this.accuracy,
      status: status ?? this.status,
      speed: speed ?? this.speed,
      sounding: sounding ?? this.sounding,
      loopRange: effectiveRange,
      loopMeasure: effectiveMeasure,
      isDemonstrating: isDemonstrating ?? this.isDemonstrating,
      isMicrophoneSuspended:
          isMicrophoneSuspended ?? this.isMicrophoneSuspended,
      selectedInputSource: selectedInputSource ?? this.selectedInputSource,
      practiceMode: practiceMode ?? this.practiceMode,
      waitingHint: clearWaitingHint ? null : (waitingHint ?? this.waitingHint),
      isMetronomeEnabled: isMetronomeEnabled ?? this.isMetronomeEnabled,
      isCountInEnabled: isCountInEnabled ?? this.isCountInEnabled,
      handSelection: handSelection ?? this.handSelection,
    );
  }
}

class StageController extends StateNotifier<StageUiState> {
  StageController(
    this._engine,
    this._stageId,
    this._progress,
    StageUiState initial, {
    AudioSynthesizer? synth,
    PracticeInputSource? selectedInputSource,
  }) : _synth = synth ?? AudioSynthesizer(player: SilentAudioTonePlayer()),
       super(
         selectedInputSource != null &&
                 initial.selectedInputSource != selectedInputSource
             ? initial.copyWith(selectedInputSource: selectedInputSource)
             : initial,
       ) {
    _sub = _engine.events.listen(_onEvent);
    _progress.setLastPlayed(_stageId).catchError((_) {});
  }

  final StageEngine _engine;
  final String _stageId;
  final ProgressRepository _progress;
  final AudioSynthesizer _synth;
  StreamSubscription<StageEvent>? _sub;
  Future<void> _progressWrites = Future<void>.value();
  bool _syncEngineEvents = true;
  bool _disposed = false;

  /// The engine's own event stream, exposed so the screen can react to the
  /// same completion signal that [_onEvent] already uses to write progress,
  /// rather than inventing a second way to detect it.
  Stream<StageEvent> get events => _engine.events;

  String get levelTitle => state.level.title;

  bool get isCompleted => state.status == StageEngineStatus.completed;

  bool get isDemonstrating => state.isDemonstrating;
  bool get isMicrophoneSuspended => state.isMicrophoneSuspended;
  bool get isMicrophoneScoringActive => state.isMicrophoneScoringActive;
  PracticeInputSource get selectedInputSource => state.selectedInputSource;
  PracticeInputSource get effectiveInputSource => state.effectiveInputSource;
  PracticeMode get practiceMode => _engine.practiceMode;
  WaitingHint? get waitingHint => state.waitingHint;

  void setPracticeMode(PracticeMode mode) {
    if (_disposed || !mounted) return;
    _syncEngineEvents = true;
    _engine.setPracticeMode(mode);
    _sync();
  }

  void togglePracticeMode() {
    setPracticeMode(
      practiceMode == PracticeMode.timed
          ? PracticeMode.waiting
          : PracticeMode.timed,
    );
  }

  bool get isMetronomeEnabled => _engine.isMetronomeEnabled;
  bool get isCountInEnabled => _engine.isCountInEnabled;
  bool get isCountingIn => _engine.isCountingIn;
  double get effectiveBpm => _engine.effectiveBpm;

  /// Enables or disables the metronome beat reference.
  void setMetronome(bool enabled) {
    if (_disposed || !mounted) return;
    _engine.setMetronomeEnabled(enabled);
    _sync();
  }

  /// Toggles the metronome beat reference.
  void toggleMetronome() => setMetronome(!isMetronomeEnabled);

  /// Enables or disables the count-in before playback begins.
  void setCountIn(bool enabled) {
    if (_disposed || !mounted) return;
    _engine.setCountInEnabled(enabled);
    _sync();
  }

  /// Toggles the count-in before playback begins.
  void toggleCountIn() => setCountIn(!isCountInEnabled);

  HandSelection get handSelection => _engine.handSelection;
  Set<HandSelection> get supportedHands => state.supportedHands;
  bool get isHandAssignmentKnown => state.isHandAssignmentKnown;
  bool get isHandAssignmentUnknown => state.isHandAssignmentUnknown;

  /// Sets the active hand selection for practice (left, right, or both).
  void setHandSelection(HandSelection selection) {
    if (_disposed || !mounted) return;
    _engine.setHandSelection(selection);
    _sync();
  }

  void updateSelectedInputSource(PracticeInputSource source) {
    if (_disposed || !mounted) return;
    state = state.copyWith(selectedInputSource: source);
  }

  /// One decay timer per lit key. [PitchDetector] only emits an event while
  /// it hears a pitch -- silence produces nothing -- so without a decay a
  /// note would stay lit forever once heard once. Each detection of a note
  /// resets its own timer; if the note is not heard again within the decay
  /// window, it drops out of [StageUiState.sounding].
  final Map<int, Timer> _soundingTimers = {};
  static const Duration _soundingDecay = Duration(milliseconds: 350);

  static const double minSpeed = 0.5;
  static const double maxSpeed = 2.0;

  Future<void> start() async {
    if (state.isDemonstrating) {
      stopDemonstration();
    }
    _syncEngineEvents = true;
    _engine.start();
    _sync();
    await _progress.setLastPlayed(_stageId);
  }

  void pause() {
    _syncEngineEvents = true;
    _engine.pause();
    _sync();
    // A paused transport should not show a lit key either.
    _clearSounding();
    unawaited(_synth.stop());
  }

  void resume() {
    _syncEngineEvents = true;
    _engine.resume();
    _sync();
  }

  /// Halts and holds position. Distinct from [replay], which rewinds.
  void stop({
    final bool syncEvents = true,
    final bool notifyState = true,
    final bool syncState = true,
  }) {
    if (state.isDemonstrating) {
      _engine.stopDemonstration();
      unawaited(_synth.stop());
      state = state.copyWith(
        isDemonstrating: false,
        isMicrophoneSuspended: false,
      );
    }
    _syncEngineEvents = syncEvents;
    _engine.stop();
    if (!syncState) {
      // The engine is already completed when the results route replaces this
      // screen; preserve that state for the results action and only stop its
      // transport.
    } else if (!notifyState) {
      _clearSounding(notify: false);
    } else {
      _sync();
    }
    // Nothing is being listened for once stopped, so no key should stay lit.
    if (syncState && notifyState) {
      _clearSounding();
    }
  }

  /// Publishes the stopped engine state after a caller deferred notification
  /// from a widget lifecycle callback.
  void publishStoppedState() {
    _syncEngineEvents = true;
    _sync();
    _clearSounding();
  }

  /// A detected pitch both scores against the level and lights the keyboard.
  ///
  /// The microphone keeps listening across Stop and Pause -- [stop] only
  /// halts the [StageEngine], not the audio engine -- so without this guard a
  /// stray tail of a decaying note (or a hand still on the keys) would relight
  /// a key on a keyboard whose transport reads "stopped."
  void onPitch(PitchEvent event) {
    if (state.status != StageEngineStatus.playing) return;
    if (state.isDemonstrating) return;
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
    if (_disposed || !mounted || !state.sounding.contains(note)) return;
    state = state.copyWith(sounding: {...state.sounding}..remove(note));
  }

  void _clearSounding({final bool notify = true}) {
    for (final timer in _soundingTimers.values) {
      timer.cancel();
    }
    _soundingTimers.clear();
    if (!notify || _disposed || !mounted) return;
    state = state.copyWith(sounding: const {});
  }

  /// Returns to the start and plays again.
  void replay() {
    if (state.isDemonstrating) {
      stopDemonstration();
    }
    _syncEngineEvents = true;
    _engine.reset();
    _engine.start();
    _sync();
  }

  /// Plays bar [measure] over and over, every pass judged afresh. Looping
  /// never completes the piece, so it never writes progress.
  void loopBar(int measure) => loopRange(measure, measure);

  /// Plays measures from [startMeasure] to [endMeasure] (inclusive) over and over,
  /// judging every repeat pass as a fresh attempt scoped to that range.
  void loopRange(int startMeasure, int endMeasure) {
    final measures = state.level.measures;
    if (measures.isEmpty) return;
    final start = startMeasure.clamp(0, measures.length - 1);
    final end = endMeasure.clamp(start, measures.length - 1);
    final mStart = measures[start];
    final mEnd = measures[end];
    final startBeat = mStart.startBeat;
    final endBeat = mEnd.startBeat + mEnd.beatsPerMeasure;

    _syncEngineEvents = true;
    _engine.playLoop(startBeat, endBeat);
    _sync();
    state = state.copyWith(loopMeasure: start, loopRange: (start, end));
  }

  /// Stops looping and returns to the start of the piece.
  void stopLoop() {
    _engine.clearLoop();
    _engine.reset();
    _clearSounding(notify: false);
    _sync();
    state = state.copyWith(clearLoop: true);
  }

  /// Demonstrates a selected phrase using the synthesizer without scoring.
  ///
  /// If [startMeasure] and [endMeasure] are provided, demonstrates that measure range.
  /// Otherwise, if a loop range is active, demonstrates that loop range.
  /// If no range is specified or active, demonstrates the entire level.
  ///
  /// Suspend microphone scoring during demonstration so playback cannot
  /// score itself; restores the learner's selected input when finished.
  Future<void> demonstratePhrase({int? startMeasure, int? endMeasure}) async {
    final measures = state.level.measures;
    if (measures.isEmpty) return;

    int startIdx;
    int endIdx;
    if (startMeasure != null && endMeasure != null) {
      startIdx = startMeasure.clamp(0, measures.length - 1);
      endIdx = endMeasure.clamp(startIdx, measures.length - 1);
    } else if (state.loopRange != null) {
      startIdx = state.loopRange!.$1.clamp(0, measures.length - 1);
      endIdx = state.loopRange!.$2.clamp(startIdx, measures.length - 1);
    } else {
      startIdx = 0;
      endIdx = measures.length - 1;
    }

    final mStart = measures[startIdx];
    final mEnd = measures[endIdx];
    final startBeat = mStart.startBeat;
    final endBeat = mEnd.startBeat + mEnd.beatsPerMeasure;

    _syncEngineEvents = true;
    _clearSounding();
    state = state.copyWith(isDemonstrating: true, isMicrophoneSuspended: true);

    await _synth.open();

    _engine.playDemonstration(
      startBeat,
      endBeat,
      onNote: _onDemonstrationNote,
      onComplete: _onDemonstrationComplete,
    );
    _sync();
  }

  /// Alias for [demonstratePhrase].
  Future<void> demonstrate({int? startMeasure, int? endMeasure}) =>
      demonstratePhrase(startMeasure: startMeasure, endMeasure: endMeasure);

  /// Stops phrase demonstration, halts synthesizer audio,
  /// and restores the learner's selected input.
  void stopDemonstration() {
    if (!state.isDemonstrating) return;
    _engine.stopDemonstration();
    unawaited(_synth.stop());
    _clearSounding();
    state = state.copyWith(
      isDemonstrating: false,
      isMicrophoneSuspended: false,
    );
    _sync();
  }

  void _onDemonstrationNote(LevelNote note) {
    if (_disposed || !mounted) return;
    final speed = _engine.playbackSpeed > 0 ? _engine.playbackSpeed : 1.0;
    final tempo = _engine.level.tempo > 0 ? _engine.level.tempo : 120.0;
    final durationSeconds = (note.durationBeats * 60.0) / (tempo * speed);
    unawaited(
      _synth.playNote(
        midiNote: note.midiNote,
        durationSeconds: durationSeconds,
      ),
    );

    final noteMidi = note.midiNote;
    _soundingTimers[noteMidi]?.cancel();
    _soundingTimers[noteMidi] = Timer(
      _soundingDecay,
      () => _dropSounding(noteMidi),
    );
    state = state.copyWith(sounding: {...state.sounding, noteMidi});
  }

  void _onDemonstrationComplete() {
    if (_disposed || !mounted) return;
    unawaited(_synth.stop());
    _clearSounding();
    state = state.copyWith(
      isDemonstrating: false,
      isMicrophoneSuspended: false,
    );
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
    if (!_syncEngineEvents) return;
    _sync();
    event.whenOrNull(
      stageCompleted: (accuracy, score, totalNotes, hitNotes) =>
          _progressWrites = _progressWrites.then((_) async {
            await _progress
                .record(stageId: _stageId, accuracy: accuracy, score: score)
                .catchError((_) {});
            await _progress.setLastPlayed(_stageId).catchError((_) {});
          }),
      beat: (beat, beatType, measureIndex, beatInMeasure, isCountIn) {
        if (_engine.isMetronomeEnabled || isCountIn) {
          unawaited(_synth.playMetronomeClick(type: beatType));
        }
      },
    );
  }

  void _sync() {
    if (_disposed || !mounted) return;
    final s = _engine.state;
    state = state.copyWith(
      noteStates: List.of(s.noteStates),
      currentBeat: s.currentBeat,
      score: s.score,
      accuracy: s.accuracy,
      status: s.engineState,
      clearLoop: _engine.loop == null,
      isDemonstrating: _engine.isDemonstrating,
      isMicrophoneSuspended: _engine.isDemonstrating,
      practiceMode: _engine.practiceMode,
      waitingHint: s.waitingHint,
      clearWaitingHint: s.waitingHint == null,
      isMetronomeEnabled: _engine.isMetronomeEnabled,
      isCountInEnabled: _engine.isCountInEnabled,
      handSelection: _engine.handSelection,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    if (state.isDemonstrating) {
      _engine.stopDemonstration();
      unawaited(_synth.stop());
    }
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
    StateNotifierProvider.family<StageController, StageUiState, String>((
      ref,
      stageId,
    ) {
      // By the time a practice route is reachable, LevelListScreen has already
      // awaited levelRepositoryProvider to render the stage list the user tapped
      // -- requireValue asserts that instead of silently falling back to an
      // empty catalog.
      final stages = ref
          .read(levelRepositoryProvider)
          .requireValue
          .getAllStages();
      final stage = stages.cast<StageModel?>().firstWhere(
        (s) => s?.id == stageId,
        orElse: () => null,
      );
      if (stage == null) {
        // Loud, not silent: a bad id is a routing bug and should not render an
        // empty staff that looks like a loading state.
        throw StateError('No stage with id "$stageId"');
      }

      final settings = ref.read(settingsProvider);
      final synth = ref.read(audioSynthesizerProvider);
      final engine = StageEngine(
        level: stage.level,
        config: settings.toStageEngineConfig(),
      );
      final controller = StageController(
        engine,
        stageId,
        ref.read(progressRepositoryProvider),
        StageUiState(
          level: stage.level,
          notes: engine.allNotes,
          noteStates: List.of(engine.state.noteStates),
          currentBeat: 0,
          score: 0,
          accuracy: 0,
          status: engine.state.engineState,
          speed: engine.playbackSpeed,
          selectedInputSource: settings.inputSource,
          practiceMode: engine.practiceMode,
          waitingHint: engine.state.waitingHint,
          isMetronomeEnabled: engine.isMetronomeEnabled,
          isCountInEnabled: engine.isCountInEnabled,
          handSelection: engine.handSelection,
        ),
        synth: synth,
        selectedInputSource: settings.inputSource,
      );

      // Pitch events only flow once permission was granted; the gate makes sure
      // the screen is not reachable before then.
      //
      // This subscription lives as long as the provider does, same as the
      // engine's own event subscription cancelled in StageController.dispose --
      // the provider is not autoDispose, so both share the same accepted
      // lifetime tradeoff documented where the screen stops the controller.
      ref.listen(
        audioPitchStreamProvider,
        (_, next) {
          final settings = ref.read(settingsProvider);
          if (!settings.inputSource.usesMicrophone) return;
          if (!controller.isMicrophoneScoringActive) return;
          if (stage.effectiveRequiresMidi) return;
          if (next.hasError) {
            _logAudioStreamError(next.error);
            return;
          }
          next.whenOrNull(data: controller.onPitch);
        },
        onError: (error, _) => _logAudioStreamError(error),
        fireImmediately: true,
      );

      ref.listen(midiPitchStreamProvider, (_, next) {
        final settings = ref.read(settingsProvider);
        if (!settings.inputSource.usesMidi) return;
        if (next.hasError) return;
        next.whenOrNull(data: controller.onPitch);
      }, fireImmediately: true);

      ref.listen(touchPitchStreamProvider, (_, next) {
        if (!ref.read(settingsProvider).inputSource.usesTouch) return;
        next.whenOrNull(data: controller.onPitch);
      }, fireImmediately: true);

      ref.listen(
        settingsProvider.select((s) => s.inputSource),
        (_, next) => controller.updateSelectedInputSource(next),
      );

      return controller;
    });

void _logAudioStreamError(Object? error) {
  // A stream error (a device hiccup, the mic disconnecting mid-session) does
  // not stop the transport or unmount the screen; only this one pitch is
  // lost. There is no existing error surface for a mid-session event this
  // rare -- the permission gate only speaks to the initial grant -- so this
  // is logged rather than given a new UI state.
  debugPrint('audioPitchStreamProvider error: $error');
}

// Narrow slices. A widget watching one of these does not rebuild when an
// unrelated field changes, which is the whole point of this file.
final currentBeatProvider = Provider.autoDispose.family<double, String>(
  (ref, id) =>
      ref.watch(stageControllerProvider(id).select((s) => s.currentBeat)),
);
final scoreProvider = Provider.autoDispose.family<int, String>(
  (ref, id) => ref.watch(stageControllerProvider(id).select((s) => s.score)),
);
final accuracyProvider = Provider.autoDispose.family<double, String>(
  (ref, id) => ref.watch(stageControllerProvider(id).select((s) => s.accuracy)),
);
final engineStatusProvider = Provider.autoDispose
    .family<StageEngineStatus, String>(
      (ref, id) =>
          ref.watch(stageControllerProvider(id).select((s) => s.status)),
    );
final noteStatesProvider = Provider.autoDispose.family<List<NoteState>, String>(
  (ref, id) =>
      ref.watch(stageControllerProvider(id).select((s) => s.noteStates)),
);
final playbackSpeedProvider = Provider.autoDispose.family<double, String>(
  (ref, id) => ref.watch(stageControllerProvider(id).select((s) => s.speed)),
);
final soundingProvider = Provider.autoDispose.family<Set<int>, String>(
  (ref, id) => ref.watch(stageControllerProvider(id).select((s) => s.sounding)),
);
final isDemonstratingProvider = Provider.autoDispose.family<bool, String>(
  (ref, id) =>
      ref.watch(stageControllerProvider(id).select((s) => s.isDemonstrating)),
);
final isMicrophoneSuspendedProvider = Provider.autoDispose.family<bool, String>(
  (ref, id) => ref.watch(
    stageControllerProvider(id).select((s) => s.isMicrophoneSuspended),
  ),
);
final effectiveInputSourceProvider = Provider.autoDispose
    .family<PracticeInputSource, String>(
      (ref, id) => ref.watch(
        stageControllerProvider(id).select((s) => s.effectiveInputSource),
      ),
    );
final practiceModeProvider = Provider.autoDispose.family<PracticeMode, String>(
  (ref, id) =>
      ref.watch(stageControllerProvider(id).select((s) => s.practiceMode)),
);
final waitingHintProvider = Provider.autoDispose.family<WaitingHint?, String>(
  (ref, id) =>
      ref.watch(stageControllerProvider(id).select((s) => s.waitingHint)),
);
final accessibleDescriptionProvider = Provider.autoDispose
    .family<String, String>(
      (ref, id) => ref.watch(
        stageControllerProvider(id).select((s) => s.accessibleDescription),
      ),
    );
final effectiveBpmProvider = Provider.autoDispose.family<int, String>(
  (ref, id) =>
      ref.watch(stageControllerProvider(id).select((s) => s.effectiveBpm)),
);
final isMetronomeEnabledProvider = Provider.autoDispose.family<bool, String>(
  (ref, id) => ref.watch(
    stageControllerProvider(id).select((s) => s.isMetronomeEnabled),
  ),
);
final isCountInEnabledProvider = Provider.autoDispose.family<bool, String>(
  (ref, id) =>
      ref.watch(stageControllerProvider(id).select((s) => s.isCountInEnabled)),
);
final isCountingInProvider = Provider.autoDispose.family<bool, String>(
  (ref, id) =>
      ref.watch(stageControllerProvider(id).select((s) => s.isCountingIn)),
);
final countInBeatProvider = Provider.autoDispose.family<int?, String>(
  (ref, id) =>
      ref.watch(stageControllerProvider(id).select((s) => s.countInBeat)),
);

final handSelectionProvider = Provider.autoDispose
    .family<HandSelection, String>(
      (ref, id) =>
          ref.watch(stageControllerProvider(id).select((s) => s.handSelection)),
    );

final supportedHandsProvider = Provider.autoDispose
    .family<Set<HandSelection>, String>(
      (ref, id) => ref.watch(
        stageControllerProvider(id).select((s) => s.supportedHands),
      ),
    );

final isHandAssignmentKnownProvider = Provider.autoDispose.family<bool, String>(
  (ref, id) => ref.watch(
    stageControllerProvider(id).select((s) => s.isHandAssignmentKnown),
  ),
);
