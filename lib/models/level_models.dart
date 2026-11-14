import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'level_models.freezed.dart';
part 'level_models.g.dart';

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
  }) = _StageProgress;

  factory StageProgress.fromJson(Map<String, dynamic> json) =>
      _$StageProgressFromJson(json);
}
