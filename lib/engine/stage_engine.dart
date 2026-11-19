import 'dart:async';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import '../models/level_models.dart';
import '../models/audio_models.dart';
import '../models/engine_models.dart';
import 'meter_grouping.dart';

/// Core game engine that manages stage state and processes pitch events
class StageEngine extends ChangeNotifier {
  final LevelModel _level;
  final StageEngineConfig _config;

  /// Playback speed multiplier. Held separately from _config, which is final.
  double _playbackSpeed = 1.0;

  double get playbackSpeed => _playbackSpeed;

  /// Effective BPM taking into account the base level tempo and playback speed multiplier.
  double get effectiveBpm => _level.tempo * _playbackSpeed;

  /// Whether metronome beat references are enabled during playback.
  bool _metronomeEnabled = false;
  bool get isMetronomeEnabled => _metronomeEnabled;
  bool get metronomeEnabled => _metronomeEnabled;

  /// Whether count-in before playback is enabled.
  bool _countInEnabled = false;
  bool get isCountInEnabled => _countInEnabled;
  bool get countInEnabled => _countInEnabled;

  /// Whether the engine is currently playing count-in beats prior to measure 0.
  bool _isCountingIn = false;
  bool get isCountingIn => _isCountingIn;

  /// The active 1-based beat within the count-in measure, or null if not counting in.
  int? get countInBeat {
    if (!_isCountingIn || _state.currentBeat >= 0.0) return null;
    final total = _level.beatsPerMeasure > 0 ? _level.beatsPerMeasure : 4;
    final count = (_state.currentBeat + total).floor() + 1;
    return count.clamp(1, total);
  }

  /// Total count-in beats for the piece's meter.
  int? get countInTotalBeats => _isCountingIn
      ? (_level.beatsPerMeasure > 0 ? _level.beatsPerMeasure : 4)
      : null;

  /// Callback fired whenever a metronome or count-in beat boundary is crossed.
  void Function(double beat, MetronomeBeatType beatType, bool isCountIn)?
  onBeat;

  int _lastEmittedBeat = -999999;

  /// Current practice mode: timed (play in time) or waiting (learn notes).
  PracticeMode _practiceMode = PracticeMode.timed;

  PracticeMode get practiceMode => _practiceMode;
  PracticeMode get mode => _practiceMode;

  /// Target hand selection for practice: left, right, or both.
  HandSelection _handSelection = HandSelection.both;
  HandSelection get handSelection => _handSelection;

  /// Whether [note] belongs to the active hand selection for this level.
  bool _isNoteInHand(LevelNote note) {
    if (!_level.isHandAssignmentKnown) return true;
    return _handSelection.matchesVoice(note.voiceIndex);
  }

  StageEngineStateModel _state = const StageEngineStateModel(
    engineState: StageEngineStatus.idle,
    level: LevelModel(
      id: '',
      title: '',
      description: '',
      tempo: 120,
      beatsPerMeasure: 4,
      totalMeasures: 1,
      measures: [],
    ),
    currentBeat: 0.0,
    noteStates: [],
    score: 0,
    hitCount: 0,
    missCount: 0,
  );

  Timer? _playbackTimer;

  /// Real time since the playhead was last anchored at [_anchorBeat]. From
  /// package:clock, so tests that fake time move the playhead too.
  final Stopwatch _playbackClock = clock.stopwatch();
  double _anchorBeat = 0;
  StreamSubscription<PitchEvent>? _pitchSubscription;
  var _disposed = false;
  final List<LevelNote> _allNotes = [];
  final Map<int, NoteHitResult> _noteResults = {};
  AttemptDetail? _attemptDetail;
  int _nextNoteIndex = 0;

  /// Detail of the most recently finished attempt, or null.
  AttemptDetail? get attemptDetail => _attemptDetail;

  /// Immutable snapshot of note hit results for the current attempt.
  Map<int, NoteHitResult> get noteResults => Map.unmodifiable(_noteResults);

  /// Derives attempt detail from note results and active filters.
  AttemptDetail _buildAttemptDetail({({double start, double end})? loopRange}) {
    return AttemptDetail.fromResults(
      allNotes: _allNotes,
      noteResults: _noteResults,
      handSelection: _handSelection,
      loop: loopRange ?? _loop,
      score: _state.score,
    );
  }

  /// Whether the engine is currently demonstrating a phrase using synthesizer audio.
  bool _isDemonstrating = false;
  bool get isDemonstrating => _isDemonstrating;

  /// The active demonstration beat range, or null.
  ({double start, double end})? _demonstrationRange;
  ({double start, double end})? get demonstrationRange => _demonstrationRange;

  void Function(LevelNote note)? _onDemonstrationNote;
  void Function()? _onDemonstrationComplete;
  final Set<int> _demonstratedNoteIndices = {};

  /// The previous microphone frame, to tell a new strike from the same
  /// sound ringing on.
  PitchEvent? _lastHeard;

  /// The beat range played over and over, or null. A loop never reaches the
  /// end of the piece, so practising one bar never completes the stage or
  /// writes progress.
  ({double start, double end})? _loop;
  ({double start, double end})? get loop => _loop;

  /// Seconds without a detection that end a sound.
  static const double _sustainGap = 0.15;

  /// How much louder a frame must be than the one before to count as the
  /// key struck again while it still rings.
  static const double _restrikeSwell = 1.6;

  StageEngine({
    required LevelModel level,
    StageEngineConfig? config,
    PracticeMode? practiceMode,
    HandSelection? handSelection,
  }) : _level = level,
       _config = config ?? const StageEngineConfig(),
       _practiceMode =
           practiceMode ?? config?.practiceMode ?? PracticeMode.timed {
    _playbackSpeed = _config.playbackSpeed;
    _metronomeEnabled = _config.metronomeEnabled;
    _countInEnabled = _config.countInEnabled;
    final requestedHand =
        handSelection ?? config?.handSelection ?? HandSelection.both;
    if (!_level.supportedHands.contains(requestedHand)) {
      _handSelection = HandSelection.both;
    } else {
      _handSelection = requestedHand;
    }
    _initializeNotes();
    _state = _state.copyWith(
      engineState: StageEngineStatus.idle,
      level: _level,
      noteStates: List.filled(_allNotes.length, NoteState.upcoming),
      practiceMode: _practiceMode,
      handSelection: _handSelection,
    );
  }

  /// Sets the active hand selection for practice (left, right, or both).
  ///
  /// Throws [ArgumentError] if [selection] is not supported by the level's
  /// authored voice data.
  void setHandSelection(HandSelection selection) {
    if (_handSelection == selection) return;
    if (!_level.supportedHands.contains(selection)) {
      throw ArgumentError(
        'Hand selection $selection is not supported for level "${_level.id}"',
      );
    }
    _handSelection = selection;

    _noteResults.removeWhere((idx, _) => !_isNoteInHand(_allNotes[idx]));

    final newStates = List<NoteState>.from(_state.noteStates);
    for (int i = 0; i < _allNotes.length; i++) {
      if (!_isNoteInHand(_allNotes[i])) {
        newStates[i] = NoteState.upcoming;
      }
    }

    int score = 0;
    int hitCount = 0;
    int missCount = 0;
    int perfectCount = 0;
    int goodCount = 0;
    int okayCount = 0;

    for (final entry in _noteResults.entries) {
      final idx = entry.key;
      final r = entry.value;
      if (!_isNoteInHand(_allNotes[idx])) continue;
      score += r.score.round();
      switch (r.noteState) {
        case NoteState.missed:
          missCount++;
        case NoteState.hitPerfect:
          hitCount++;
          perfectCount++;
        case NoteState.hitGood:
          hitCount++;
          goodCount++;
        case NoteState.hitOkay:
          hitCount++;
          okayCount++;
        case NoteState.upcoming || NoteState.active:
          break;
      }
    }

    _state = _state.copyWith(
      handSelection: _handSelection,
      noteStates: newStates,
      score: score,
      hitCount: hitCount,
      missCount: missCount,
      perfectCount: perfectCount,
      goodCount: goodCount,
      okayCount: okayCount,
    );

    if (_practiceMode == PracticeMode.waiting &&
        _state.engineState == StageEngineStatus.playing) {
      _syncWaitingPlayheadAndHint();
    } else if (_practiceMode == PracticeMode.timed &&
        _state.engineState == StageEngineStatus.playing) {
      _updateNoteStatesForBeat(_state.currentBeat);
    }
    _notifyStateChanged();
  }

  /// Enables or disables the metronome beat reference.
  void setMetronomeEnabled(bool enabled) {
    if (_metronomeEnabled == enabled) return;
    _metronomeEnabled = enabled;
    notifyListeners();
  }

  /// Enables or disables the count-in before playback begins.
  void setCountInEnabled(bool enabled) {
    if (_countInEnabled == enabled) return;
    _countInEnabled = enabled;
    notifyListeners();
  }

  /// Sets the active practice mode.
  ///
  /// In [PracticeMode.timed], playback auto-advances at the selected tempo and speed,
  /// evaluating timing windows and awarding points.
  /// In [PracticeMode.waiting], the transport holds at each note until the learner
  /// strikes the correct pitch, offering contextual hints without awarding a timed score.
  void setPracticeMode(PracticeMode mode) {
    if (_practiceMode == mode) return;
    _practiceMode = mode;
    if (_state.engineState == StageEngineStatus.playing) {
      if (_practiceMode == PracticeMode.timed) {
        _stopPlaybackTimer();
        _state = _state.copyWith(
          practiceMode: _practiceMode,
          waitingHint: null,
        );
        _updateNoteStatesForBeat(_state.currentBeat);
        _startPlaybackTimer();
      } else {
        _stopPlaybackTimer();
        _state = _state.copyWith(practiceMode: _practiceMode);
        _syncWaitingPlayheadAndHint();
      }
    } else {
      _state = _state.copyWith(practiceMode: _practiceMode);
    }
    _notifyStateChanged();
  }

  /// Initialize the flat list of all notes from measures. Rests are
  /// silence and are never scored.
  void _initializeNotes() {
    _allNotes.clear();
    for (final measure in _level.measures) {
      for (final note in measure.notes) {
        if (!note.isRest) _allNotes.add(note);
      }
    }
    // Sort by start beat
    _allNotes.sort((a, b) => a.startBeat.compareTo(b.startBeat));
  }

  /// Get current engine state
  StageEngineStateModel get state => _state;

  /// Get the level being played
  LevelModel get level => _level;

  /// Get all notes
  List<LevelNote> get allNotes => List.unmodifiable(_allNotes);

  /// Get note states
  List<NoteState> get noteStates => List.unmodifiable(_state.noteStates);

  /// Stream of stage events
  final StreamController<StageEvent> _eventController =
      StreamController<StageEvent>.broadcast();

  Stream<StageEvent> get events => _eventController.stream;

  /// Start the stage
  void start() {
    if (_isDemonstrating) {
      stopDemonstration();
    }
    if (_state.engineState == StageEngineStatus.playing) return;

    _loop = null;
    _nextNoteIndex = 0;
    _noteResults.clear();
    _lastHeard = null;

    final initialNoteStates = List.filled(_allNotes.length, NoteState.upcoming);
    final countInBeats = _level.beatsPerMeasure.toDouble();
    _isCountingIn = _countInEnabled && _practiceMode == PracticeMode.timed;
    final startBeat = _isCountingIn ? -countInBeats : 0.0;
    _lastEmittedBeat = startBeat.floor() - 1;

    _state = _state.copyWith(
      engineState: StageEngineStatus.playing,
      currentBeat: startBeat,
      noteStates: initialNoteStates,
      score: 0,
      hitCount: 0,
      missCount: 0,
      perfectCount: 0,
      goodCount: 0,
      okayCount: 0,
      practiceMode: _practiceMode,
      waitingHint: null,
      isCountingIn: _isCountingIn,
      countInBeat: _isCountingIn ? 1 : null,
      noteResults: Map.of(_noteResults),
    );

    if (_practiceMode == PracticeMode.waiting) {
      _syncWaitingPlayheadAndHint();
    } else {
      _startPlaybackTimer();
      _checkAndEmitBeats(startBeat);
    }
    _notifyStateChanged();
  }

  /// Pause the stage
  void pause() {
    if (_state.engineState != StageEngineStatus.playing) return;

    _stopPlaybackTimer();
    _state = _state.copyWith(engineState: StageEngineStatus.paused);
    _notifyStateChanged();
  }

  /// Resume from pause
  void resume() {
    if (_state.engineState != StageEngineStatus.paused) return;

    _startPlaybackTimer();
    _state = _state.copyWith(engineState: StageEngineStatus.playing);
    _notifyStateChanged();
  }

  /// Stop the stage
  void stop() {
    if (_disposed) return;
    _stopPlaybackTimer();
    _isCountingIn = false;
    _lastEmittedBeat = -999999;
    if (_isDemonstrating) {
      _isDemonstrating = false;
      _demonstrationRange = null;
      _onDemonstrationNote = null;
      _onDemonstrationComplete = null;
      _demonstratedNoteIndices.clear();
    }
    _state = _state.copyWith(
      engineState: StageEngineStatus.stopped,
      isCountingIn: false,
      countInBeat: null,
    );
    _notifyStateChanged();
  }

  /// Reset the stage to initial state
  void reset() {
    _stopPlaybackTimer();
    _isCountingIn = false;
    _lastEmittedBeat = -999999;
    _isDemonstrating = false;
    _demonstrationRange = null;
    _onDemonstrationNote = null;
    _onDemonstrationComplete = null;
    _demonstratedNoteIndices.clear();
    _loop = null;
    _nextNoteIndex = 0;
    _noteResults.clear();
    _attemptDetail = null;
    _lastHeard = null;

    final initialNoteStates = List.filled(_allNotes.length, NoteState.upcoming);
    _state = _state.copyWith(
      engineState: StageEngineStatus.idle,
      currentBeat: 0.0,
      noteStates: initialNoteStates,
      score: 0,
      hitCount: 0,
      missCount: 0,
      perfectCount: 0,
      goodCount: 0,
      okayCount: 0,
      practiceMode: _practiceMode,
      waitingHint: null,
      isCountingIn: false,
      countInBeat: null,
      noteResults: const {},
      attemptDetail: null,
    );
    _notifyStateChanged();
  }

  /// Process a pitch event from the audio engine. Only a fresh strike can
  /// score: a held or decaying pitch must not claim the next repeated note
  /// when its window opens.
  void processPitchEvent(PitchEvent event) {
    if (_state.engineState != StageEngineStatus.playing) return;
    if (_isDemonstrating) return;
    if (_isCountingIn || _state.currentBeat < 0.0) return;
    if (!_isFreshStrike(event)) return;

    if (_practiceMode == PracticeMode.waiting) {
      _processWaitingPitchEvent(event);
      return;
    }

    final beatsPerSecond = _level.tempo / 60.0 * _playbackSpeed;
    final latencyBeats = _config.inputLatency * beatsPerSecond;
    final effectiveBeat = _state.currentBeat - latencyBeats;
    _tryMatchNote(event.midiNote, effectiveBeat);
  }

  /// A MIDI note-on is always a strike. A microphone frame is one when the
  /// pitch changed, the sound stopped and started again, or it swelled the
  /// way a key struck while still ringing does.
  bool _isFreshStrike(PitchEvent event) {
    if (event.struck) return true;
    final last = _lastHeard;
    _lastHeard = event;
    if (last == null) return true;
    final gap = event.timestamp - last.timestamp;
    return last.midiNote != event.midiNote ||
        gap > _sustainGap ||
        gap < 0 ||
        event.volume >= last.volume * _restrikeSwell;
  }

  /// Try to match a detected pitch to an expected note
  void _tryMatchNote(int detectedMidiNote, double currentBeat) {
    // Find the best matching note that's upcoming or active
    int? bestMatchIndex;
    double bestTimingError = double.infinity;
    double bestSignedTimingError = 0.0;

    for (int i = _nextNoteIndex; i < _allNotes.length; i++) {
      final note = _allNotes[i];
      if (_loop case final loop?) {
        if (note.startBeat < loop.start - 1e-9 || note.startBeat >= loop.end) {
          continue;
        }
      }
      if (!_isNoteInHand(note)) {
        continue;
      }
      final noteState = _state.noteStates[i];

      // Skip if already hit or missed
      if (noteState != NoteState.upcoming && noteState != NoteState.active) {
        continue;
      }

      // Check if this note matches the detected pitch
      if (note.midiNote != detectedMidiNote) continue;

      // Calculate timing error
      final timingError = currentBeat - note.startBeat;
      final absError = timingError.abs();

      // An early sound may be the tail of the previous note. Keep this note
      // available for a later pitch event inside its scoring window.
      if (timingError < -_config.okayWindow) continue;

      // Check if within any hit window
      if (absError <= _config.missWindow) {
        if (absError < bestTimingError) {
          bestTimingError = absError;
          bestSignedTimingError = timingError;
          bestMatchIndex = i;
        }
      }
    }

    if (bestMatchIndex != null) {
      _registerHit(bestMatchIndex, bestSignedTimingError);
      return;
    }

    // If no matching pitch was found among active/upcoming notes:
    // Check if an unresolved note in the active hand is within its hit window.
    // The current scorer does NOT classify every unexpected pitch: unexpected
    // pitches occurring when no expected note is in its hit window (such as during
    // rests, before the window opens, or far ahead) are ignored. Only pitches
    // struck within the active hit window of an unresolved expected note are confirmed
    // as wrong pitches.
    int? closestWrongIndex;
    double closestWrongTimingError = double.infinity;
    double closestSignedTimingError = 0.0;

    for (int i = _nextNoteIndex; i < _allNotes.length; i++) {
      final note = _allNotes[i];
      if (_loop case final loop?) {
        if (note.startBeat < loop.start - 1e-9 || note.startBeat >= loop.end) {
          continue;
        }
      }
      if (!_isNoteInHand(note)) {
        continue;
      }
      final noteState = _state.noteStates[i];

      if (noteState != NoteState.upcoming && noteState != NoteState.active) {
        continue;
      }

      final timingError = currentBeat - note.startBeat;
      final absError = timingError.abs();

      if (timingError < -_config.okayWindow) continue;

      if (absError <= _config.missWindow) {
        if (absError < closestWrongTimingError) {
          closestWrongTimingError = absError;
          closestSignedTimingError = timingError;
          closestWrongIndex = i;
        }
      }
    }

    if (closestWrongIndex != null) {
      _registerWrongPitch(
        closestWrongIndex,
        detectedMidiNote,
        closestSignedTimingError,
      );
    }
  }

  /// Register a confirmed wrong pitch for an expected note
  void _registerWrongPitch(
    int noteIndex,
    int playedMidiNote,
    double timingError,
  ) {
    if (_noteResults.containsKey(noteIndex)) return; // Already processed

    final result = NoteHitResult.wrongPitch(
      noteIndex: noteIndex,
      playedMidiNote: playedMidiNote,
      timingError: timingError,
    );

    _noteResults[noteIndex] = result;
    _updateNoteState(noteIndex, NoteState.missed);
    _state = _state.copyWith(
      missCount: _state.missCount + 1,
      noteResults: Map.of(_noteResults),
    );

    _eventController.add(
      StageEvent.noteHit(
        noteIndex: noteIndex,
        result: result,
        currentBeat: _state.currentBeat,
      ),
    );

    // Advance next note index past resolved notes
    while (_nextNoteIndex < _allNotes.length &&
        _state.noteStates[_nextNoteIndex] != NoteState.upcoming &&
        _state.noteStates[_nextNoteIndex] != NoteState.active) {
      _nextNoteIndex++;
    }
  }

  /// Register a note hit with timing error
  void _registerHit(int noteIndex, double timingError) {
    if (_noteResults.containsKey(noteIndex)) return; // Already processed

    final absError = timingError.abs();
    NoteHitResult result;

    if (absError <= _config.perfectWindow) {
      result = NoteHitResult.perfect(
        noteIndex: noteIndex,
        timingError: timingError,
      );
      _state = _state.copyWith(perfectCount: _state.perfectCount + 1);
    } else if (absError <= _config.goodWindow) {
      result = NoteHitResult.good(
        noteIndex: noteIndex,
        timingError: timingError,
      );
      _state = _state.copyWith(goodCount: _state.goodCount + 1);
    } else if (absError <= _config.okayWindow) {
      result = NoteHitResult.okay(
        noteIndex: noteIndex,
        timingError: timingError,
      );
      _state = _state.copyWith(okayCount: _state.okayCount + 1);
    } else {
      result = NoteHitResult.missed(noteIndex: noteIndex);
    }

    _noteResults[noteIndex] = result;
    _updateNoteState(noteIndex, result.noteState);
    _state = _state.copyWith(
      score: _state.score + result.score.round(),
      hitCount: result.noteState == NoteState.missed
          ? _state.hitCount
          : _state.hitCount + 1,
      missCount: result.noteState == NoteState.missed
          ? _state.missCount + 1
          : _state.missCount,
      noteResults: Map.of(_noteResults),
    );

    _eventController.add(
      StageEvent.noteHit(
        noteIndex: noteIndex,
        result: result,
        currentBeat: _state.currentBeat,
      ),
    );

    // Advance next note index
    while (_nextNoteIndex < _allNotes.length &&
        _state.noteStates[_nextNoteIndex] != NoteState.upcoming &&
        _state.noteStates[_nextNoteIndex] != NoteState.active) {
      _nextNoteIndex++;
    }
  }

  /// Update a note's state
  void _updateNoteState(int index, NoteState newState) {
    if (index < 0 || index >= _state.noteStates.length) return;

    final newStates = List<NoteState>.from(_state.noteStates);
    newStates[index] = newState;
    _state = _state.copyWith(noteStates: newStates);
  }

  /// Start the playback timer
  ///
  /// The playhead follows the wall clock from the beat it starts at. A tick
  /// only decides when to look at the clock: when frames run long and ticks
  /// arrive late, the playhead still matches the music the player hears,
  /// instead of losing 16 ms of beat for every tick that never fired.
  void _startPlaybackTimer() {
    _stopPlaybackTimer();

    const tickInterval = Duration(milliseconds: 16); // ~60 FPS
    final beatsPerSecond = _level.tempo / 60.0 * _playbackSpeed;
    _anchorBeat = _state.currentBeat;
    _playbackClock
      ..reset()
      ..start();

    _playbackTimer = Timer.periodic(tickInterval, (timer) {
      final elapsed = _playbackClock.elapsedMicroseconds / 1000000.0;
      final targetBeat = _anchorBeat + beatsPerSecond * elapsed;
      _updatePlayback(targetBeat - _state.currentBeat);
    });
  }

  /// Stop the playback timer
  void _stopPlaybackTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _playbackClock.stop();
  }

  /// Demonstrates the phrase between [start] and [end] beats using synthesizer audio.
  ///
  /// Plays each note as the playhead reaches it without scoring, misses, or progress recording.
  /// When [end] is reached, playback halts, notes in the phrase reset to upcoming,
  /// and [onComplete] is called.
  void playDemonstration(
    double start,
    double end, {
    void Function(LevelNote note)? onNote,
    void Function()? onComplete,
  }) {
    _stopPlaybackTimer();
    _isDemonstrating = true;
    _demonstrationRange = (start: start, end: end);
    _onDemonstrationNote = onNote;
    _onDemonstrationComplete = onComplete;
    _demonstratedNoteIndices.clear();
    _lastHeard = null;

    final states = List<NoteState>.from(_state.noteStates);
    for (var i = 0; i < _allNotes.length; i++) {
      final s = _allNotes[i].startBeat;
      if (s >= start - 1e-9 && s < end) {
        states[i] = NoteState.upcoming;
        _noteResults.remove(i);
      }
    }
    _nextNoteIndex = 0;
    while (_nextNoteIndex < _allNotes.length &&
        _allNotes[_nextNoteIndex].startBeat < start - 1e-9) {
      _nextNoteIndex++;
    }

    _state = _state.copyWith(
      engineState: StageEngineStatus.playing,
      currentBeat: start,
      noteStates: states,
      score: 0,
      hitCount: 0,
      missCount: 0,
      perfectCount: 0,
      goodCount: 0,
      okayCount: 0,
    );

    _soundNotesForBeat(start);
    _updateNoteStatesForBeat(start);
    _startPlaybackTimer();
    _notifyStateChanged();
  }

  void _soundNotesForBeat(double currentBeat) {
    if (!_isDemonstrating || _demonstrationRange == null) return;
    final range = _demonstrationRange!;
    for (int i = 0; i < _allNotes.length; i++) {
      if (_demonstratedNoteIndices.contains(i)) continue;
      final note = _allNotes[i];
      if (!_isNoteInHand(note)) continue;
      if (note.startBeat < range.start - 1e-9 || note.startBeat >= range.end) {
        continue;
      }
      if (note.startBeat <= currentBeat + 1e-6) {
        _demonstratedNoteIndices.add(i);
        _onDemonstrationNote?.call(note);
      }
    }
  }

  /// Stops phrase demonstration and returns to idle at the phrase start.
  void stopDemonstration() {
    if (!_isDemonstrating) return;
    _stopPlaybackTimer();
    _isDemonstrating = false;
    final start = _demonstrationRange?.start ?? 0.0;
    final end =
        _demonstrationRange?.end ??
        (_level.totalMeasures * _level.beatsPerMeasure).toDouble();
    _demonstrationRange = null;
    _onDemonstrationNote = null;
    final onComplete = _onDemonstrationComplete;
    _onDemonstrationComplete = null;
    _demonstratedNoteIndices.clear();

    final states = List<NoteState>.from(_state.noteStates);
    for (var i = 0; i < _allNotes.length; i++) {
      final s = _allNotes[i].startBeat;
      if (s >= start - 1e-9 && s < end) {
        states[i] = NoteState.upcoming;
        _noteResults.remove(i);
      }
    }
    _nextNoteIndex = 0;
    while (_nextNoteIndex < _allNotes.length &&
        _allNotes[_nextNoteIndex].startBeat < start - 1e-9) {
      _nextNoteIndex++;
    }

    _state = _state.copyWith(
      engineState: StageEngineStatus.idle,
      currentBeat: start,
      noteStates: states,
      score: 0,
      hitCount: 0,
      missCount: 0,
      perfectCount: 0,
      goodCount: 0,
      okayCount: 0,
    );
    _updateNoteStatesForBeat(start);
    _notifyStateChanged();
    onComplete?.call();
  }

  /// Plays from [start] to [end] over and over, judging every pass afresh.
  void playLoop(double start, double end) {
    _stopPlaybackTimer();
    _loop = (start: start, end: end);
    _lastHeard = null;
    _state = _state.copyWith(engineState: StageEngineStatus.playing);
    _restartLoop(initialStart: true);
    _notifyStateChanged();
  }

  /// Stops looping; playback carries on from where it is.
  void clearLoop() => _loop = null;

  void _restartLoop({bool initialStart = false}) {
    final loop = _loop!;
    final states = List<NoteState>.from(_state.noteStates);
    for (var i = 0; i < _allNotes.length; i++) {
      final start = _allNotes[i].startBeat;
      if (start >= loop.start - 1e-9 && start < loop.end) {
        states[i] = NoteState.upcoming;
        _noteResults.remove(i);
      }
    }
    _nextNoteIndex = 0;
    while (_nextNoteIndex < _allNotes.length &&
        _allNotes[_nextNoteIndex].startBeat < loop.start - 1e-9) {
      _nextNoteIndex++;
    }
    _lastHeard = null;

    final countInBeats = _level.beatsPerMeasure.toDouble();
    _isCountingIn =
        initialStart && _countInEnabled && _practiceMode == PracticeMode.timed;
    final startBeat = _isCountingIn ? (loop.start - countInBeats) : loop.start;
    _lastEmittedBeat = startBeat.floor() - 1;

    _state = _state.copyWith(
      currentBeat: startBeat,
      noteStates: states,
      score: 0,
      hitCount: 0,
      missCount: 0,
      perfectCount: 0,
      goodCount: 0,
      okayCount: 0,
      isCountingIn: _isCountingIn,
      countInBeat: _isCountingIn ? 1 : null,
      noteResults: Map.of(_noteResults),
    );
    if (_practiceMode == PracticeMode.waiting) {
      _syncWaitingPlayheadAndHint();
    } else {
      _updateNoteStatesForBeat(startBeat);
      _startPlaybackTimer();
      _checkAndEmitBeats(startBeat);
    }
  }

  /// Emits beat events for any beat boundaries crossed up to [currentBeat].
  void _checkAndEmitBeats(double currentBeat) {
    final currentInt = currentBeat.floor();
    if (currentInt <= _lastEmittedBeat) return;

    final beatsPerMeasure = _level.beatsPerMeasure > 0
        ? _level.beatsPerMeasure
        : 4;
    final countInTotal = beatsPerMeasure;

    for (var b = _lastEmittedBeat + 1; b <= currentInt; b++) {
      final isCountIn =
          b < 0 || (_isCountingIn && (_loop == null || b < _loop!.start));
      final MetronomeBeatType beatType;
      final int measureIndex;
      final int beatInMeasure;

      if (b < 0) {
        measureIndex = -1;
        beatInMeasure =
            ((b + countInTotal) % countInTotal + countInTotal) % countInTotal;
        beatType = MeterGrouping.beatType(
          beatsPerMeasure: _level.beatsPerMeasure,
          beatUnit: _level.beatUnit,
          beatInMeasure: beatInMeasure,
        );
      } else {
        measureIndex = b ~/ beatsPerMeasure;
        beatInMeasure = b % beatsPerMeasure;
        beatType = MeterGrouping.beatType(
          beatsPerMeasure: _level.beatsPerMeasure,
          beatUnit: _level.beatUnit,
          beatInMeasure: beatInMeasure,
        );
      }

      _eventController.add(
        StageEvent.beat(
          beat: b.toDouble(),
          beatType: beatType,
          measureIndex: measureIndex,
          beatInMeasure: beatInMeasure,
          isCountIn: isCountIn,
        ),
      );

      onBeat?.call(b.toDouble(), beatType, isCountIn);
    }

    _lastEmittedBeat = currentInt;
  }

  /// Update playback position
  void _updatePlayback(double deltaBeats) {
    final totalBeats = _level.totalMeasures * _level.beatsPerMeasure;
    double newBeat = _state.currentBeat + deltaBeats;

    final demo = _demonstrationRange;
    if (_isDemonstrating && demo != null) {
      _soundNotesForBeat(newBeat);
      _checkAndEmitBeats(newBeat);

      if (newBeat >= demo.end) {
        newBeat = demo.end;
        _stopPlaybackTimer();
        _isDemonstrating = false;
        final start = demo.start;
        final end = demo.end;
        _demonstrationRange = null;
        _onDemonstrationNote = null;
        final onComplete = _onDemonstrationComplete;
        _onDemonstrationComplete = null;
        _demonstratedNoteIndices.clear();

        final states = List<NoteState>.from(_state.noteStates);
        for (var i = 0; i < _allNotes.length; i++) {
          final s = _allNotes[i].startBeat;
          if (s >= start - 1e-9 && s < end) {
            states[i] = NoteState.upcoming;
            _noteResults.remove(i);
          }
        }
        _nextNoteIndex = 0;
        while (_nextNoteIndex < _allNotes.length &&
            _allNotes[_nextNoteIndex].startBeat < start - 1e-9) {
          _nextNoteIndex++;
        }

        _state = _state.copyWith(
          engineState: StageEngineStatus.idle,
          currentBeat: start,
          noteStates: states,
          score: 0,
          hitCount: 0,
          missCount: 0,
          perfectCount: 0,
          goodCount: 0,
          okayCount: 0,
          isCountingIn: false,
          countInBeat: null,
        );
        _updateNoteStatesForBeat(start);
        _eventController.add(
          StageEvent.playbackPosition(
            currentBeat: start,
            progress: totalBeats > 0 ? start / totalBeats : 0.0,
            isPlaying: false,
          ),
        );
        _notifyStateChanged();
        onComplete?.call();
        return;
      }

      _updateNoteStatesForBeat(newBeat);
      _state = _state.copyWith(currentBeat: newBeat);
      _eventController.add(
        StageEvent.playbackPosition(
          currentBeat: newBeat,
          progress: totalBeats > 0 ? newBeat / totalBeats : 0.0,
          isPlaying: true,
        ),
      );
      notifyListeners();
      return;
    }

    final loop = _loop;
    final countInThreshold = loop != null ? loop.start : 0.0;
    if (_isCountingIn && newBeat >= countInThreshold) {
      _isCountingIn = false;
    }

    _checkAndEmitBeats(newBeat);

    if (loop != null && newBeat >= loop.end) {
      _checkMissedNotes(loop.end);
      final loopNotes = _allNotes
          .where(
            (n) =>
                n.startBeat >= loop.start - 1e-9 &&
                n.startBeat < loop.end &&
                _isNoteInHand(n),
          )
          .length;
      final hitNotes = _state.hitCount;
      final totalNotes =
          loopNotes > 0 ? loopNotes : (hitNotes + _state.missCount);
      final accuracy = totalNotes > 0 ? hitNotes / totalNotes : 0.0;
      final detail = _buildAttemptDetail(loopRange: loop);
      _attemptDetail = detail;
      _eventController.add(
        StageEvent.loopPassCompleted(
          accuracy: accuracy,
          score: _state.score,
          totalNotes: totalNotes,
          hitNotes: hitNotes,
          loopStartBeat: loop.start,
          loopEndBeat: loop.end,
          attemptDetail: detail,
        ),
      );
      _restartLoop();
      _eventController.add(
        StageEvent.playbackPosition(
          currentBeat: loop.start,
          progress: loop.start / totalBeats,
          isPlaying: true,
        ),
      );
      notifyListeners();
      return;
    }

    // Check for missed notes before advancing
    _checkMissedNotes(newBeat);

    // Clamp to total duration
    if (newBeat >= totalBeats) {
      newBeat = totalBeats.toDouble();
      _completeStage();
    }

    // Update active/upcoming states
    _updateNoteStatesForBeat(newBeat);

    final progress = totalBeats > 0
        ? (newBeat / totalBeats).clamp(0.0, 1.0)
        : 0.0;
    _state = _state.copyWith(
      currentBeat: newBeat,
      isCountingIn: _isCountingIn,
      countInBeat: countInBeat,
    );

    _eventController.add(
      StageEvent.playbackPosition(
        currentBeat: newBeat,
        progress: progress,
        isPlaying: _state.engineState == StageEngineStatus.playing,
      ),
    );

    notifyListeners();
  }

  /// Check for notes that should be marked as missed
  void _checkMissedNotes(double currentBeat) {
    if (_isCountingIn || currentBeat < 0.0) return;
    for (int i = 0; i < _allNotes.length; i++) {
      final note = _allNotes[i];
      if (_loop case final loop?) {
        if (note.startBeat < loop.start - 1e-9 || note.startBeat >= loop.end) {
          continue;
        }
      }
      if (!_isNoteInHand(note)) {
        continue;
      }
      final noteState = _state.noteStates[i];

      if (noteState != NoteState.upcoming && noteState != NoteState.active) {
        continue;
      }

      // Note is missed if we're past its start beat + miss window
      if (currentBeat > note.startBeat + _config.missWindow) {
        _updateNoteState(i, NoteState.missed);
        _noteResults[i] = NoteHitResult.missed(noteIndex: i);
        _state = _state.copyWith(
          missCount: _state.missCount + 1,
          noteResults: Map.of(_noteResults),
        );

        _eventController.add(
          StageEvent.noteMissed(noteIndex: i, currentBeat: currentBeat),
        );
      }
    }

    // Advance next note index past resolved (hit or missed) notes or unselected notes past miss window
    while (_nextNoteIndex < _allNotes.length &&
        ((_state.noteStates[_nextNoteIndex] != NoteState.upcoming &&
                _state.noteStates[_nextNoteIndex] != NoteState.active) ||
            (!_isNoteInHand(_allNotes[_nextNoteIndex]) &&
                currentBeat >
                    _allNotes[_nextNoteIndex].startBeat +
                        _config.missWindow))) {
      _nextNoteIndex++;
    }
  }

  /// Update note states based on current beat position
  void _updateNoteStatesForBeat(double currentBeat) {
    final newStates = List<NoteState>.from(_state.noteStates);

    for (int i = 0; i < _allNotes.length; i++) {
      final note = _allNotes[i];
      if (_loop case final loop?) {
        if (note.startBeat < loop.start - 1e-9 || note.startBeat >= loop.end) {
          continue;
        }
      }
      if (!_isNoteInHand(note)) {
        continue;
      }
      final currentState = newStates[i];

      if (currentState != NoteState.upcoming &&
          currentState != NoteState.active) {
        continue;
      }

      final noteEndBeat = note.startBeat + note.durationBeats;

      if (currentBeat >= note.startBeat - 0.5 && currentBeat < noteEndBeat) {
        // Note is active (within half beat before start to end)
        newStates[i] = NoteState.active;
      } else if (currentBeat < note.startBeat - 0.5) {
        // Note is still upcoming
        newStates[i] = NoteState.upcoming;
      }
      // If past end beat and not hit, it will be caught by _checkMissedNotes
    }

    _state = _state.copyWith(noteStates: newStates);
  }

  /// Complete the stage
  void _completeStage() {
    _stopPlaybackTimer();
    final detail = _buildAttemptDetail();
    _attemptDetail = detail;
    _state = _state.copyWith(
      engineState: StageEngineStatus.completed,
      waitingHint: null,
      noteResults: Map.of(_noteResults),
      attemptDetail: detail,
    );

    final totalNotes = _allNotes.where(_isNoteInHand).length;
    final hitNotes = _state.hitCount;
    final accuracy = totalNotes > 0 ? hitNotes / totalNotes : 0.0;

    _eventController.add(
      StageEvent.stageCompleted(
        accuracy: accuracy,
        score: _state.score,
        totalNotes: totalNotes,
        hitNotes: hitNotes,
        attemptDetail: detail,
      ),
    );

    _notifyStateChanged();
  }

  /// Notify state changed event
  void _notifyStateChanged() {
    _eventController.add(StageEvent.stateChanged(state: _state.engineState));
    notifyListeners();
  }

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

  /// Seek to a specific beat position (for scrubbing)
  void seekToBeat(double beat) {
    final demo = _demonstrationRange;
    if (_isDemonstrating && demo != null) {
      final clampedBeat = beat.clamp(demo.start, demo.end);
      _demonstratedNoteIndices.removeWhere(
        (idx) => _allNotes[idx].startBeat > clampedBeat,
      );
      _updateNoteStatesForBeat(clampedBeat);
      _state = _state.copyWith(currentBeat: clampedBeat);
      if (_state.engineState == StageEngineStatus.playing) {
        _startPlaybackTimer();
      }
      final totalBeats = _level.totalMeasures * _level.beatsPerMeasure;
      _eventController.add(
        StageEvent.playbackPosition(
          currentBeat: clampedBeat,
          progress: totalBeats > 0 ? clampedBeat / totalBeats : 0.0,
          isPlaying: true,
        ),
      );
      notifyListeners();
      return;
    }

    final loop = _loop;
    final minBeat = loop != null ? loop.start : 0.0;
    final maxBeat = loop != null
        ? loop.end
        : (_level.totalMeasures * _level.beatsPerMeasure).toDouble();
    final clampedBeat = beat.clamp(minBeat, maxBeat);

    _isCountingIn = false;
    _lastEmittedBeat = clampedBeat.floor();

    if (_practiceMode == PracticeMode.waiting) {
      final newStates = List<NoteState>.from(_state.noteStates);
      for (int i = 0; i < _allNotes.length; i++) {
        final note = _allNotes[i];
        if (loop != null &&
            (note.startBeat < loop.start - 1e-9 ||
                note.startBeat >= loop.end)) {
          continue;
        }
        if (note.startBeat >= clampedBeat - 1e-9) {
          newStates[i] = NoteState.upcoming;
          _noteResults.remove(i);
        }
      }
      int hitCount = 0;
      for (final entry in _noteResults.entries) {
        final idx = entry.key;
        final start = _allNotes[idx].startBeat;
        if (loop != null && (start < loop.start - 1e-9 || start >= loop.end)) {
          continue;
        }
        hitCount++;
      }
      _state = _state.copyWith(
        currentBeat: clampedBeat,
        noteStates: newStates,
        score: 0,
        hitCount: hitCount,
        missCount: 0,
      );
      _syncWaitingPlayheadAndHint();
      _notifyStateChanged();
      return;
    }

    // Reset note states up to the seek position
    final newStates = List<NoteState>.from(_state.noteStates);
    for (int i = 0; i < _allNotes.length; i++) {
      final note = _allNotes[i];
      if (loop != null &&
          (note.startBeat < loop.start - 1e-9 || note.startBeat >= loop.end)) {
        continue;
      }
      if (!_isNoteInHand(note)) {
        continue;
      }

      if (clampedBeat > note.startBeat + _config.missWindow) {
        // Past the hit window - mark as missed if not hit
        if (newStates[i] == NoteState.upcoming ||
            newStates[i] == NoteState.active) {
          newStates[i] = NoteState.missed;
          _noteResults[i] = NoteHitResult.missed(noteIndex: i);
        }
      } else if (clampedBeat >= note.startBeat - 0.5 &&
          clampedBeat < note.startBeat + note.durationBeats) {
        // Currently at this note
        if (loop != null) {
          if (clampedBeat <= note.startBeat + _config.perfectWindow) {
            newStates[i] = NoteState.active;
            _noteResults.remove(i);
          } else if (newStates[i] == NoteState.upcoming) {
            newStates[i] = NoteState.active;
          }
        } else {
          if (newStates[i] == NoteState.upcoming) {
            newStates[i] = NoteState.active;
          }
        }
      } else if (clampedBeat < note.startBeat - 0.5) {
        // Future note
        if (loop != null) {
          newStates[i] = NoteState.upcoming;
          _noteResults.remove(i);
        } else {
          if (newStates[i] == NoteState.active) {
            newStates[i] = NoteState.upcoming;
          }
        }
      }
    }

    _nextNoteIndex = 0;
    while (_nextNoteIndex < _allNotes.length &&
        ((loop != null &&
                _allNotes[_nextNoteIndex].startBeat < loop.start - 1e-9) ||
            (newStates[_nextNoteIndex] != NoteState.upcoming &&
                newStates[_nextNoteIndex] != NoteState.active))) {
      _nextNoteIndex++;
    }

    if (loop != null) {
      int score = 0;
      int hitCount = 0;
      int missCount = 0;
      int perfectCount = 0;
      int goodCount = 0;
      int okayCount = 0;

      for (final entry in _noteResults.entries) {
        final idx = entry.key;
        final r = entry.value;
        if (!_isNoteInHand(_allNotes[idx])) continue;
        final start = _allNotes[idx].startBeat;
        if (start < loop.start - 1e-9 || start >= loop.end) continue;
        score += r.score.round();
        switch (r.noteState) {
          case NoteState.missed:
            missCount++;
          case NoteState.hitPerfect:
            hitCount++;
            perfectCount++;
          case NoteState.hitGood:
            hitCount++;
            goodCount++;
          case NoteState.hitOkay:
            hitCount++;
            okayCount++;
          case NoteState.upcoming || NoteState.active:
            break;
        }
      }

      _state = _state.copyWith(
        currentBeat: clampedBeat,
        noteStates: newStates,
        score: score,
        hitCount: hitCount,
        missCount: missCount,
        perfectCount: perfectCount,
        goodCount: goodCount,
        okayCount: okayCount,
        noteResults: Map.of(_noteResults),
      );
    } else {
      final missCount = newStates.indexed
          .where(
            (e) => e.$2 == NoteState.missed && _isNoteInHand(_allNotes[e.$1]),
          )
          .length;
      _state = _state.copyWith(
        currentBeat: clampedBeat,
        noteStates: newStates,
        missCount: missCount,
        noteResults: Map.of(_noteResults),
      );
    }

    // Re-anchor the clock, or the next tick would pull the playhead back to
    // where it was before the seek.
    if (_state.engineState == StageEngineStatus.playing) {
      _startPlaybackTimer();
    }

    final totalBeats = _level.totalMeasures * _level.beatsPerMeasure;
    _eventController.add(
      StageEvent.playbackPosition(
        currentBeat: clampedBeat,
        progress: totalBeats > 0 ? clampedBeat / totalBeats : 0.0,
        isPlaying: _state.engineState == StageEngineStatus.playing,
      ),
    );

    notifyListeners();
  }

  /// Returns the notes at the next unhit beat position currently awaited in waiting mode.
  List<LevelNote> _getAwaitedNotes() {
    if (_allNotes.isEmpty) return const [];
    final loop = _loop;

    for (int i = 0; i < _allNotes.length; i++) {
      final note = _allNotes[i];
      if (loop != null &&
          (note.startBeat < loop.start - 1e-9 || note.startBeat >= loop.end)) {
        continue;
      }
      if (!_isNoteInHand(note)) {
        continue;
      }
      final state = _state.noteStates[i];
      if (state != NoteState.hitPerfect &&
          state != NoteState.hitGood &&
          state != NoteState.hitOkay) {
        final targetBeat = note.startBeat;
        final awaited = <LevelNote>[];
        for (int j = i; j < _allNotes.length; j++) {
          final n = _allNotes[j];
          if (loop != null &&
              (n.startBeat < loop.start - 1e-9 || n.startBeat >= loop.end)) {
            continue;
          }
          if (!_isNoteInHand(n)) {
            continue;
          }
          if ((n.startBeat - targetBeat).abs() < 1e-6) {
            final s = _state.noteStates[j];
            if (s != NoteState.hitPerfect &&
                s != NoteState.hitGood &&
                s != NoteState.hitOkay) {
              awaited.add(n);
            }
          } else if (n.startBeat > targetBeat + 1e-6) {
            break;
          }
        }
        return awaited;
      }
    }
    return const [];
  }

  /// Creates a contextual [WaitingHint] describing the awaited note(s) or feedback on wrong input.
  WaitingHint _createWaitingHint(
    List<LevelNote> awaited,
    double targetBeat, {
    int? heardWrongMidiNote,
  }) {
    final targetMidis = awaited.map((n) => n.midiNote).toList();
    final noteNames = targetMidis.map((m) => formatPitch(m)).toList();
    final first = awaited.first;
    final measureIdx = first.measureIndex;
    final beatIdx = first.beatIndex;

    String expectedDesc;
    if (noteNames.length == 1) {
      expectedDesc = noteNames.first;
    } else if (noteNames.length == 2) {
      expectedDesc = '${noteNames[0]} and ${noteNames[1]}';
    } else {
      final initial = noteNames.sublist(0, noteNames.length - 1).join(', ');
      expectedDesc = '$initial, and ${noteNames.last}';
    }

    String hintText;
    if (heardWrongMidiNote != null) {
      final heardName = formatPitch(heardWrongMidiNote, clarifyMiddleC: false);
      hintText = 'Heard $heardName. Waiting for $expectedDesc.';
    } else {
      hintText = 'Play $expectedDesc';
    }

    return WaitingHint(
      targetBeat: targetBeat,
      targetMidiNotes: targetMidis,
      noteNames: noteNames,
      hintText: hintText,
      measureIndex: measureIdx,
      beatIndex: beatIdx,
      heardWrongMidiNote: heardWrongMidiNote,
    );
  }

  /// Synchronizes playhead position, note states, and contextual hint in waiting mode.
  void _syncWaitingPlayheadAndHint({int? heardWrongMidiNote}) {
    if (_practiceMode != PracticeMode.waiting) return;
    if (_state.engineState != StageEngineStatus.playing) {
      if (_state.waitingHint != null) {
        _state = _state.copyWith(waitingHint: null);
      }
      return;
    }

    final awaited = _getAwaitedNotes();
    if (awaited.isEmpty) {
      if (_loop != null) {
        final loop = _loop!;
        final loopNotes = _allNotes
            .where(
              (n) =>
                  n.startBeat >= loop.start - 1e-9 &&
                  n.startBeat < loop.end &&
                  _isNoteInHand(n),
            )
            .length;
        final detail = _buildAttemptDetail(loopRange: loop);
        _attemptDetail = detail;
        _eventController.add(
          StageEvent.loopPassCompleted(
            accuracy: 1.0,
            score: 0,
            totalNotes: loopNotes,
            hitNotes: loopNotes,
            loopStartBeat: loop.start,
            loopEndBeat: loop.end,
            attemptDetail: detail,
          ),
        );
        _restartLoop();
        return;
      } else {
        _completeStage();
        return;
      }
    }

    final targetBeat = awaited.first.startBeat;
    final newStates = List<NoteState>.from(_state.noteStates);
    final loop = _loop;

    for (int i = 0; i < _allNotes.length; i++) {
      final note = _allNotes[i];
      if (loop != null &&
          (note.startBeat < loop.start - 1e-9 || note.startBeat >= loop.end)) {
        continue;
      }
      if (!_isNoteInHand(note)) {
        continue;
      }
      if (newStates[i] == NoteState.hitPerfect ||
          newStates[i] == NoteState.hitGood ||
          newStates[i] == NoteState.hitOkay) {
        continue;
      }
      if ((note.startBeat - targetBeat).abs() < 1e-6) {
        newStates[i] = NoteState.active;
      } else {
        newStates[i] = NoteState.upcoming;
      }
    }

    final hint = _createWaitingHint(
      awaited,
      targetBeat,
      heardWrongMidiNote: heardWrongMidiNote,
    );

    _state = _state.copyWith(
      currentBeat: targetBeat,
      noteStates: newStates,
      waitingHint: hint,
    );

    _nextNoteIndex = 0;
    while (_nextNoteIndex < _allNotes.length &&
        ((_state.noteStates[_nextNoteIndex] != NoteState.upcoming &&
                _state.noteStates[_nextNoteIndex] != NoteState.active) ||
            !_isNoteInHand(_allNotes[_nextNoteIndex]))) {
      _nextNoteIndex++;
    }

    final totalBeats = _level.totalMeasures * _level.beatsPerMeasure;
    _eventController.add(
      StageEvent.playbackPosition(
        currentBeat: targetBeat,
        progress: totalBeats > 0 ? targetBeat / totalBeats : 0.0,
        isPlaying: true,
      ),
    );
  }

  /// Handles pitch events in waiting mode. Correct pitch registers a hit without timed scoring;
  /// wrong pitch updates contextual hint with feedback without miss penalties.
  void _processWaitingPitchEvent(PitchEvent event) {
    final awaited = _getAwaitedNotes();
    if (awaited.isEmpty) return;

    final matchIdx = awaited.indexWhere((n) => n.midiNote == event.midiNote);
    if (matchIdx != -1) {
      final matchedNote = awaited[matchIdx];
      final noteIndex = _allNotes.indexOf(matchedNote);
      _registerWaitingHit(noteIndex);
    } else {
      _registerWaitingWrongNote(event.midiNote);
    }
  }

  void _registerWaitingHit(int noteIndex) {
    if (_noteResults.containsKey(noteIndex)) return;

    final result = NoteHitResult.waiting(noteIndex: noteIndex);
    _noteResults[noteIndex] = result;
    _updateNoteState(noteIndex, NoteState.hitPerfect);

    _state = _state.copyWith(
      hitCount: _state.hitCount + 1,
      noteResults: Map.of(_noteResults),
      // score is untouched (no timed score awarded)
    );

    _eventController.add(
      StageEvent.noteHit(
        noteIndex: noteIndex,
        result: result,
        currentBeat: _state.currentBeat,
      ),
    );

    _syncWaitingPlayheadAndHint();
    _notifyStateChanged();
  }

  void _registerWaitingWrongNote(int heardMidi) {
    _syncWaitingPlayheadAndHint(heardWrongMidiNote: heardMidi);
    _notifyStateChanged();
  }

  @override
  void dispose() {
    _disposed = true;
    _isDemonstrating = false;
    _demonstrationRange = null;
    _onDemonstrationNote = null;
    _onDemonstrationComplete = null;
    _demonstratedNoteIndices.clear();
    _stopPlaybackTimer();
    _pitchSubscription?.cancel();
    _eventController.close();
    super.dispose();
  }
}
