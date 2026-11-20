import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'level_models.freezed.dart';
part 'level_models.g.dart';

/// Practice modes supported by the game engine.
enum PracticeMode {
  /// Timed mode: playhead advances with tempo, scoring timing accuracy.
  @JsonValue('timed')
  timed,

  /// Waiting mode: playhead waits at each note until the correct pitch is struck,
  /// offering contextual hints without awarding timed scores.
  @JsonValue('waiting')
  waiting;

  bool get isTimed => this == timed;
  bool get isWaiting => this == waiting;
  String get label => switch (this) {
    timed => 'Play in time',
    waiting => 'Learn notes (waiting)',
  };
}

/// Hand classification for an individual note or hand assignment.
enum NoteHand {
  @JsonValue('right')
  right,
  @JsonValue('left')
  left,
  @JsonValue('unknown')
  unknown;

  bool get isRight => this == right;
  bool get isLeft => this == left;
  bool get isUnknown => this == unknown;
}

/// Target hand selection for practice.
enum HandSelection {
  @JsonValue('both')
  both,
  @JsonValue('right')
  right,
  @JsonValue('left')
  left;

  bool get isBoth => this == both;
  bool get isRight => this == right;
  bool get isLeft => this == left;

  String get label => switch (this) {
    both => 'Both hands',
    right => 'Right hand',
    left => 'Left hand',
  };

  /// Whether a voice index (0 = right hand, 1+ = left hand) matches this selection.
  bool matchesVoice(int voiceIndex) => switch (this) {
    both => true,
    right => voiceIndex == 0,
    left => voiceIndex > 0,
  };

  /// Whether a note matches this hand selection.
  bool matchesNote(LevelNote note) => matchesVoice(note.voiceIndex);
}

/// Represents a single note in a level
@freezed
sealed class LevelNote with _$LevelNote {
  const factory LevelNote({
    required int midiNote,
    required double startBeat,
    required double durationBeats,
    required int measureIndex,
    required int beatIndex,
    @Default(false) bool isRest,
    @Default(0) int voiceIndex,

    /// Written alteration: -1 flat, 0 natural, 1 sharp. Null lets the
    /// staff spell black keys as sharps.
    int? alter,
  }) = _LevelNote;

  factory LevelNote.fromJson(Map<String, dynamic> json) =>
      _$LevelNoteFromJson(json);
}

/// Represents a measure in a level
@freezed
sealed class LevelMeasure with _$LevelMeasure {
  const factory LevelMeasure({
    required int index,
    required double startBeat,
    required int beatsPerMeasure,
    required List<LevelNote> notes,
  }) = _LevelMeasure;

  factory LevelMeasure.fromJson(Map<String, dynamic> json) =>
      _$LevelMeasureFromJson(json);
}

/// Clef configuration for level presentation
enum LevelClef {
  @JsonValue('treble')
  treble,
  @JsonValue('bass')
  bass,
  @JsonValue('grand')
  grand,
}

/// Represents a complete level/stage
@freezed
sealed class LevelModel with _$LevelModel {
  const factory LevelModel({
    required String id,
    required String title,
    required String description,
    required int tempo,
    required int beatsPerMeasure,
    required int totalMeasures,
    required List<LevelMeasure> measures,
    @Default(4) int clefOctave, // 4 = middle C octave
    @Default(0) int transpose, // semitones to transpose
    @Default(LevelClef.treble) LevelClef clef,
    @Default(4) int beatUnit, // 4 = quarter note, 8 = eighth note
  }) = _LevelModel;

  factory LevelModel.fromJson(Map<String, dynamic> json) =>
      _$LevelModelFromJson(json);
}

/// Difficulty levels for stages
enum Difficulty { beginner, intermediate, advanced, expert }

/// Stage metadata for the game progression
@freezed
sealed class StageModel with _$StageModel {
  const factory StageModel({
    required String id,
    required String title,
    required String description,
    required Difficulty difficulty,
    required LevelModel level,
    @Default(0) int order,
    @Default([]) List<String> prerequisites,
    @Default(0) int xpReward,
    @Default(false) bool requiresMidi,
  }) = _StageModel;

  factory StageModel.fromJson(Map<String, dynamic> json) =>
      _$StageModelFromJson(json);
}

/// Extension providing polyphony detection for [LevelModel].
extension LevelPolyphony on LevelModel {
  /// Whether this level contains chords or simultaneous notes sounding at the
  /// same time.
  ///
  /// The acoustic microphone path uses a YIN fundamental pitch estimator that
  /// estimates a single fundamental pitch. It cannot reliably verify
  /// simultaneous notes or chords.
  bool get isPolyphonic {
    final notes = [
      for (final measure in measures)
        for (final note in measure.notes)
          if (!note.isRest) note,
    ]..sort((a, b) => a.startBeat.compareTo(b.startBeat));

    for (var i = 0; i < notes.length - 1; i++) {
      final current = notes[i];
      final next = notes[i + 1];
      if (next.startBeat < current.startBeat + current.durationBeats) {
        return true;
      }
    }
    return false;
  }
}

/// Extension providing MIDI requirement evaluation and labeling for [StageModel].
extension StageMidiRequirement on StageModel {
  /// Whether this stage requires a digital piano (MIDI) because it includes
  /// polyphonic content or is authored with [requiresMidi].
  ///
  /// The microphone's YIN detector estimates a fundamental pitch and cannot
  /// verify lessons that need polyphony.
  bool get effectiveRequiresMidi => requiresMidi || level.isPolyphonic;

  /// Label describing the input hardware requirement.
  String? get inputRequirementLabel =>
      effectiveRequiresMidi ? 'Digital piano (MIDI) required' : null;
}

/// Extension providing hand assignment inspection and supported hand queries on [LevelModel].
extension LevelHandSupport on LevelModel {
  /// Whether this level has authored voice data distinguishing hands.
  bool get hasAuthoredVoices =>
      measures.any((m) => m.notes.any((n) => !n.isRest && n.voiceIndex > 0));

  /// Whether the hand assignment of notes in this level is known.
  bool get isHandAssignmentKnown => hasAuthoredVoices;

  /// Whether the hand assignment of notes in this level is unknown.
  bool get isHandAssignmentUnknown => !isHandAssignmentKnown;

  /// Returns the hands supported by this level's authored voice data.
  Set<HandSelection> get supportedHands {
    if (!isHandAssignmentKnown) {
      return const {HandSelection.both};
    }
    final hasRight = measures.any(
      (m) => m.notes.any((n) => !n.isRest && n.voiceIndex == 0),
    );
    final hasLeft = measures.any(
      (m) => m.notes.any((n) => !n.isRest && n.voiceIndex > 0),
    );
    if (hasRight && hasLeft) {
      return const {
        HandSelection.both,
        HandSelection.right,
        HandSelection.left,
      };
    } else if (hasRight) {
      return const {HandSelection.right};
    } else if (hasLeft) {
      return const {HandSelection.left};
    }
    return const {HandSelection.both};
  }

  /// Identifies the authored hand for a specific note in this level,
  /// or [NoteHand.unknown] if hand assignment is not authored/known.
  NoteHand handForNote(LevelNote note) {
    if (!isHandAssignmentKnown) return NoteHand.unknown;
    return note.voiceIndex > 0 ? NoteHand.left : NoteHand.right;
  }
}

/// The outcome and scoring of an individual exercise attempt.
@freezed
sealed class AttemptResult with _$AttemptResult {
  const factory AttemptResult({
    required double accuracy,
    required int score,
    @Default(0) int totalNotes,
    @Default(0) int hitNotes,
    @Default(0) int missedNotes,
    @Default(false) bool completed,
    @Default(false) bool passed,
  }) = _AttemptResult;

  factory AttemptResult.fromJson(Map<String, dynamic> json) =>
      _$AttemptResultFromJson(json);
}

/// Record of an individual practice attempt storing exercise, range, hand,
/// mode, tempo, result, and timestamp.
@freezed
sealed class AttemptRecord with _$AttemptRecord {
  const AttemptRecord._();

  const factory AttemptRecord({
    required String exercise,
    int? startMeasure,
    int? endMeasure,
    @Default(HandSelection.both) HandSelection hand,
    @Default(PracticeMode.timed) PracticeMode mode,
    required int tempo,
    int? targetTempo,
    @Default(1.0) double speed,
    required AttemptResult result,
    required DateTime date,
    @Default(false) bool isAssisted,
  }) = _AttemptRecord;

  factory AttemptRecord.fromJson(Map<String, dynamic> json) =>
      _$AttemptRecordFromJson(json);

  String get stageId => exercise;

  (int, int)? get range => (startMeasure != null && endMeasure != null)
      ? (startMeasure!, endMeasure!)
      : null;

  bool get isFullExercise => startMeasure == null || endMeasure == null;

  double get accuracy => result.accuracy;

  int get score => result.score;

  bool get isTimedPerformance =>
      mode == PracticeMode.timed && speed >= 1.0 && !isAssisted;

  bool get isTargetTempo =>
      targetTempo != null ? tempo >= targetTempo! : speed >= 1.0;

  bool get establishesTargetTempoReadiness =>
      isTimedPerformance &&
      isTargetTempo &&
      isFullExercise &&
      (result.passed || result.accuracy >= 0.9);

  bool get isAssistedCompletion =>
      (isAssisted || speed < 1.0 || mode == PracticeMode.waiting) &&
      (result.completed || result.accuracy >= 0.9);
}

/// Game progress for a stage
@freezed
sealed class StageProgress with _$StageProgress {
  const factory StageProgress({
    required String stageId,
    @Default(0) double bestAccuracy,
    @Default(0) int bestScore,
    @Default(0) int attempts,
    @Default(false) bool completed,
    @Default(false) bool unlocked,
    DateTime? completedAt,
    DateTime? lastAttemptAt,
    @Default(false) bool targetTempoReady,
    DateTime? targetTempoReadyAt,
    @Default(0) double bestTargetTempoAccuracy,
    @Default(0) int bestTargetTempoScore,
    @Default(0) int assistedCompletions,
    @Default(0) int timedCompletions,
    @Default([]) List<AttemptRecord> history,
  }) = _StageProgress;

  factory StageProgress.fromJson(Map<String, dynamic> json) =>
      _$StageProgressFromJson(json);
}
