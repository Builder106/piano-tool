import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/level_models.dart';
import '../models/audio_models.dart';
import '../models/engine_models.dart';

/// Core game engine that manages stage state and processes pitch events
class StageEngine extends ChangeNotifier {
  final LevelModel _level;
  final StageEngineConfig _config;

  /// Playback speed multiplier. Held separately from _config, which is final.
  double _playbackSpeed = 1.0;

  double get playbackSpeed => _playbackSpeed;

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
  StreamSubscription<PitchEvent>? _pitchSubscription;
  final List<LevelNote> _allNotes = [];
  final Map<int, NoteHitResult> _noteResults = {};
  int _nextNoteIndex = 0;

  StageEngine({
    required LevelModel level,
    StageEngineConfig? config,
  })  : _level = level,
        _config = config ?? const StageEngineConfig() {
    _playbackSpeed = _config.playbackSpeed;
    _initializeNotes();
    _state = _state.copyWith(
      engineState: StageEngineStatus.idle,
      level: _level,
      noteStates: List.filled(_allNotes.length, NoteState.upcoming),
    );
  }

  /// Initialize the flat list of all notes from measures
  void _initializeNotes() {
    _allNotes.clear();
    for (final measure in _level.measures) {
      for (final note in measure.notes) {
        _allNotes.add(note);
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
    if (_state.engineState == StageEngineStatus.playing) return;

    _nextNoteIndex = 0;
    _noteResults.clear();

    final initialNoteStates = List.filled(_allNotes.length, NoteState.upcoming);
    _state = _state.copyWith(
      engineState: StageEngineStatus.playing,
      currentBeat: 0.0,
      noteStates: initialNoteStates,
      score: 0,
      hitCount: 0,
      missCount: 0,
      perfectCount: 0,
      goodCount: 0,
      okayCount: 0,
    );

    _startPlaybackTimer();
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
    _stopPlaybackTimer();
    _state = _state.copyWith(engineState: StageEngineStatus.stopped);
    _notifyStateChanged();
  }

  /// Reset the stage to initial state
  void reset() {
    _stopPlaybackTimer();
    _nextNoteIndex = 0;
    _noteResults.clear();

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
    );
    _notifyStateChanged();
  }

  /// Process a pitch event from the audio engine
  void processPitchEvent(PitchEvent event) {
    if (_state.engineState != StageEngineStatus.playing) return;
    if (event.confidence < 0.7 || event.volume < 0.1) return;

    final currentBeat = _state.currentBeat;
    _tryMatchNote(event.midiNote, currentBeat);
  }

  /// Try to match a detected pitch to an expected note
  void _tryMatchNote(int detectedMidiNote, double currentBeat) {
    // Find the best matching note that's upcoming or active
    int? bestMatchIndex;
    double bestTimingError = double.infinity;

    for (int i = _nextNoteIndex; i < _allNotes.length; i++) {
      final note = _allNotes[i];
      final noteState = _state.noteStates[i];

      // Skip if already hit or missed
      if (noteState != NoteState.upcoming && noteState != NoteState.active)
        continue;

      // Check if this note matches the detected pitch
      if (note.midiNote != detectedMidiNote) continue;

      // Calculate timing error
      final timingError = currentBeat - note.startBeat;
      final absError = timingError.abs();

      // Check if within any hit window
      if (absError <= _config.missWindow) {
        if (absError < bestTimingError) {
          bestTimingError = absError;
          bestMatchIndex = i;
        }
      }
    }

    if (bestMatchIndex != null) {
      _registerHit(
          bestMatchIndex,
          bestTimingError *
              (currentBeat > _allNotes[bestMatchIndex].startBeat ? 1 : -1));
    }
  }

  /// Register a note hit with timing error
  void _registerHit(int noteIndex, double timingError) {
    if (_noteResults.containsKey(noteIndex)) return; // Already processed

    final absError = timingError.abs();
    NoteHitResult result;

    if (absError <= _config.perfectWindow) {
      result =
          NoteHitResult.perfect(noteIndex: noteIndex, timingError: timingError);
      _state = _state.copyWith(perfectCount: _state.perfectCount + 1);
    } else if (absError <= _config.goodWindow) {
      result =
          NoteHitResult.good(noteIndex: noteIndex, timingError: timingError);
      _state = _state.copyWith(goodCount: _state.goodCount + 1);
    } else if (absError <= _config.okayWindow) {
      result =
          NoteHitResult.okay(noteIndex: noteIndex, timingError: timingError);
      _state = _state.copyWith(okayCount: _state.okayCount + 1);
    } else {
      result = NoteHitResult.missed(noteIndex: noteIndex);
    }

    _noteResults[noteIndex] = result;
    _updateNoteState(noteIndex, result.noteState);
    _state = _state.copyWith(
      score: _state.score + result.score.round(),
      hitCount: _state.hitCount + 1,
    );

    _eventController.add(StageEvent.noteHit(
      noteIndex: noteIndex,
      result: result,
      currentBeat: _state.currentBeat,
    ));

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
  void _startPlaybackTimer() {
    _stopPlaybackTimer();

    const tickInterval = Duration(milliseconds: 16); // ~60 FPS
    final beatsPerSecond = _level.tempo / 60.0 * _playbackSpeed;

    _playbackTimer = Timer.periodic(tickInterval, (timer) {
      final deltaBeats =
          beatsPerSecond * (tickInterval.inMilliseconds / 1000.0);
      _updatePlayback(deltaBeats);
    });
  }

  /// Stop the playback timer
  void _stopPlaybackTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
  }

  /// Update playback position
  void _updatePlayback(double deltaBeats) {
    final totalBeats = _level.totalMeasures * _level.beatsPerMeasure;
    double newBeat = _state.currentBeat + deltaBeats;

    // Check for missed notes before advancing
    _checkMissedNotes(newBeat);

    // Clamp to total duration
    if (newBeat >= totalBeats) {
      newBeat = totalBeats.toDouble();
      _completeStage();
    }

    // Update active/upcoming states
    _updateNoteStatesForBeat(newBeat);

    _state = _state.copyWith(currentBeat: newBeat);

    _eventController.add(StageEvent.playbackPosition(
      currentBeat: newBeat,
      progress: newBeat / totalBeats,
      isPlaying: _state.engineState == StageEngineStatus.playing,
    ));

    notifyListeners();
  }

  /// Check for notes that should be marked as missed
  void _checkMissedNotes(double currentBeat) {
    for (int i = 0; i < _allNotes.length; i++) {
      final note = _allNotes[i];
      final noteState = _state.noteStates[i];

      if (noteState != NoteState.upcoming && noteState != NoteState.active)
        continue;

      // Note is missed if we're past its start beat + miss window
      if (currentBeat > note.startBeat + _config.missWindow) {
        _updateNoteState(i, NoteState.missed);
        _noteResults[i] = NoteHitResult.missed(noteIndex: i);
        _state = _state.copyWith(missCount: _state.missCount + 1);

        _eventController.add(StageEvent.noteMissed(
          noteIndex: i,
          currentBeat: currentBeat,
        ));
      }
    }
  }

  /// Update note states based on current beat position
  void _updateNoteStatesForBeat(double currentBeat) {
    final newStates = List<NoteState>.from(_state.noteStates);

    for (int i = 0; i < _allNotes.length; i++) {
      final note = _allNotes[i];
      final currentState = newStates[i];

      if (currentState != NoteState.upcoming &&
          currentState != NoteState.active) continue;

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
    _state = _state.copyWith(engineState: StageEngineStatus.completed);

    final accuracy = _state.accuracy;
    final totalNotes = _allNotes.length;
    final hitNotes = _state.hitCount;

    _eventController.add(StageEvent.stageCompleted(
      accuracy: accuracy,
      score: _state.score,
      totalNotes: totalNotes,
      hitNotes: hitNotes,
    ));

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
    final clampedBeat = beat.clamp(
        0.0, _level.totalMeasures * _level.beatsPerMeasure.toDouble());

    // Reset note states up to the seek position
    final newStates = List<NoteState>.from(_state.noteStates);
    for (int i = 0; i < _allNotes.length; i++) {
      final note = _allNotes[i];
      if (note.startBeat + note.durationBeats <= clampedBeat) {
        // Past this note entirely - mark as missed if not hit
        if (newStates[i] == NoteState.upcoming ||
            newStates[i] == NoteState.active) {
          newStates[i] = NoteState.missed;
        }
      } else if (note.startBeat <= clampedBeat &&
          clampedBeat < note.startBeat + note.durationBeats) {
        // Currently at this note
        newStates[i] = NoteState.active;
      } else {
        // Future note
        newStates[i] = NoteState.upcoming;
      }
    }

    _nextNoteIndex = 0;
    while (_nextNoteIndex < _allNotes.length &&
        (newStates[_nextNoteIndex] != NoteState.upcoming &&
            newStates[_nextNoteIndex] != NoteState.active)) {
      _nextNoteIndex++;
    }

    _state = _state.copyWith(
      currentBeat: clampedBeat,
      noteStates: newStates,
    );

    _eventController.add(StageEvent.playbackPosition(
      currentBeat: clampedBeat,
      progress: clampedBeat / (_level.totalMeasures * _level.beatsPerMeasure),
      isPlaying: _state.engineState == StageEngineStatus.playing,
    ));

    notifyListeners();
  }

  @override
  void dispose() {
    _stopPlaybackTimer();
    _pitchSubscription?.cancel();
    _eventController.close();
    super.dispose();
  }
}
