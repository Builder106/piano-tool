import 'package:freezed_annotation/freezed_annotation.dart';
import 'level_models.dart';

part 'engine_models.freezed.dart';
part 'engine_models.g.dart';

/// State of a note during gameplay
enum NoteState {
  upcoming,
  active,
  hitPerfect,
  hitGood,
  hitOkay,
  missed,
}

/// Result of a note hit attempt
@freezed
sealed class NoteHitResult with _$NoteHitResult {
  const NoteHitResult._();

  const factory NoteHitResult.perfect({
    required int noteIndex,
    required double timingError, // beats (negative = early, positive = late)
  }) = _NoteHitResultPerfect;

  const factory NoteHitResult.good({
    required int noteIndex,
    required double timingError,
  }) = _NoteHitResultGood;

  const factory NoteHitResult.okay({
    required int noteIndex,
    required double timingError,
  }) = _NoteHitResultOkay;

  const factory NoteHitResult.missed({
    required int noteIndex,
  }) = _NoteHitResultMissed;

  factory NoteHitResult.fromJson(Map<String, dynamic> json) =>
      _$NoteHitResultFromJson(json);

  NoteState get noteState => switch (this) {
        _NoteHitResultPerfect() => NoteState.hitPerfect,
        _NoteHitResultGood() => NoteState.hitGood,
        _NoteHitResultOkay() => NoteState.hitOkay,
        _NoteHitResultMissed() => NoteState.missed,
      };

  double get score => switch (this) {
        _NoteHitResultPerfect() => 100.0,
        _NoteHitResultGood() => 75.0,
        _NoteHitResultOkay() => 50.0,
        _NoteHitResultMissed() => 0.0,
      };
}

/// Events emitted by the stage engine
@freezed
sealed class StageEvent with _$StageEvent {
  const factory StageEvent.noteHit({
    required int noteIndex,
    required NoteHitResult result,
    required double currentBeat,
  }) = _StageEventNoteHit;

  const factory StageEvent.noteMissed({
    required int noteIndex,
    required double currentBeat,
  }) = _StageEventNoteMissed;

  const factory StageEvent.stageCompleted({
    required double accuracy,
    required int score,
    required int totalNotes,
    required int hitNotes,
  }) = _StageEventStageCompleted;

  const factory StageEvent.playbackPosition({
    required double currentBeat,
    required double progress, // 0.0 - 1.0
    required bool isPlaying,
  }) = _StageEventPlaybackPosition;

  const factory StageEvent.stateChanged({
    required StageEngineStatus state,
  }) = _StageEventStateChanged;

  factory StageEvent.fromJson(Map<String, dynamic> json) =>
      _$StageEventFromJson(json);
}

/// Stage engine state (enum for internal state machine)
enum StageEngineStatus {
  idle,
  playing,
  paused,
  completed,
  stopped,
}

/// Configuration for the stage engine
@freezed
sealed class StageEngineConfig with _$StageEngineConfig {
  const factory StageEngineConfig({
    @Default(0.1)
    double perfectWindow, // beats (early/late tolerance for perfect)
    @Default(0.2) double goodWindow, // beats for good
    @Default(0.3) double okayWindow, // beats for okay
    @Default(0.5) double missWindow, // beats after which note is missed
    @Default(true) bool autoAdvance, // auto-advance playhead
    @Default(1.0) double playbackSpeed, // speed multiplier
  }) = _StageEngineConfig;

  factory StageEngineConfig.fromJson(Map<String, dynamic> json) =>
      _$StageEngineConfigFromJson(json);
}

/// Current state of the stage engine
@freezed
sealed class StageEngineStateModel with _$StageEngineStateModel {
  const StageEngineStateModel._();

  const factory StageEngineStateModel({
    required StageEngineStatus engineState,
    required LevelModel level,
    required double currentBeat,
    required List<NoteState> noteStates,
    required int score,
    required int hitCount,
    required int missCount,
    @Default(0) int perfectCount,
    @Default(0) int goodCount,
    @Default(0) int okayCount,
  }) = _StageEngineStateModel;

  factory StageEngineStateModel.fromJson(Map<String, dynamic> json) =>
      _$StageEngineStateModelFromJson(json);

  double get progress => level.totalMeasures > 0
      ? (currentBeat / (level.totalMeasures * level.beatsPerMeasure))
          .clamp(0.0, 1.0)
      : 0.0;

  double get accuracy =>
      (hitCount + missCount) > 0 ? hitCount / (hitCount + missCount) : 0.0;
}

/// Provider state for the current game
@freezed
sealed class GameState with _$GameState {
  const GameState._();

  const factory GameState({
    @Default(null) StageModel? currentStage,
    @Default(null) LevelModel? currentLevel,
    @Default(StageEngineStatus.idle) StageEngineStatus engineState,
    @Default(0.0) double currentBeat,
    @Default(0) int score,
    @Default(0.0) double accuracy,
    @Default(1.0) double playbackSpeed,
  }) = _GameState;

  factory GameState.initial() => const GameState();
}
