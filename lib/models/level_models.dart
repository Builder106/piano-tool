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
  }) = _LevelNote;

  factory LevelNote.fromJson(Map<String, dynamic> json) => _$LevelNoteFromJson(json);
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

  factory LevelMeasure.fromJson(Map<String, dynamic> json) => _$LevelMeasureFromJson(json);
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
  }) = _LevelModel;

  factory LevelModel.fromJson(Map<String, dynamic> json) => _$LevelModelFromJson(json);
}

/// Difficulty levels for stages
enum Difficulty {
  beginner,
  intermediate,
  advanced,
  expert,
}

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
  }) = _StageModel;

  factory StageModel.fromJson(Map<String, dynamic> json) => _$StageModelFromJson(json);
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

  factory StageProgress.fromJson(Map<String, dynamic> json) => _$StageProgressFromJson(json);
}