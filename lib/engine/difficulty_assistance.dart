import '../models/engine_models.dart';
import '../models/level_models.dart';

/// Evaluates learner performance difficulty and computes visible, reversible assistance offers.
///
/// After repeated unsuccessful attempts at full tempo or across a full piece,
/// this evaluator offers a slower playback speed or a shorter phrase (e.g. single
/// measure drill of the most difficult passage), with a clear way back to the
/// original baseline settings. Modes and tempos are never silently changed.
class DifficultyAssistanceEvaluator {
  const DifficultyAssistanceEvaluator._();

  /// Default accuracy threshold below which an attempt is considered unsuccessful.
  static const double defaultDifficultyAccuracyThreshold = 0.8;

  /// Default number of consecutive unsuccessful attempts required to offer assistance.
  static const int defaultRepeatedAttemptsThreshold = 2;

  /// Suggests a slower playback speed based on the current speed multiplier.
  ///
  /// Steps down through standard speeds: 1.0 -> 0.75 -> 0.5.
  /// Speeds above 1.0 step down to 1.0.
  /// Speeds at or below 0.5 cannot be slowed down further (returns null).
  static double? suggestSlowerSpeed(double currentSpeed) {
    if (currentSpeed > 1.0 + 1e-6) {
      return 1.0;
    } else if (currentSpeed > 0.75 + 1e-6) {
      return 0.75;
    } else if (currentSpeed > 0.5 + 1e-6) {
      return 0.5;
    }
    return null;
  }

  /// Finds the measure index with the highest count of missed notes in the active hand.
  static int? findMostMissedMeasure({
    required List<LevelNote> allNotes,
    required List<NoteState> noteStates,
    HandSelection handSelection = HandSelection.both,
    (int, int)? withinLoopRange,
  }) {
    final missesPerMeasure = <int, int>{};
    for (var i = 0; i < allNotes.length; i++) {
      if (i >= noteStates.length) break;
      final note = allNotes[i];
      if (!handSelection.matchesNote(note) || note.isRest) continue;
      if (withinLoopRange != null) {
        if (note.measureIndex < withinLoopRange.$1 ||
            note.measureIndex > withinLoopRange.$2) {
          continue;
        }
      }
      if (noteStates[i] == NoteState.missed) {
        missesPerMeasure[note.measureIndex] =
            (missesPerMeasure[note.measureIndex] ?? 0) + 1;
      }
    }

    if (missesPerMeasure.isEmpty) return null;

    int? worstMeasure;
    int maxMisses = 0;
    for (final entry in missesPerMeasure.entries) {
      if (entry.value > maxMisses) {
        maxMisses = entry.value;
        worstMeasure = entry.key;
      }
    }
    return worstMeasure;
  }

  /// Suggests a shorter phrase range based on level measures, current loop, and missed notes.
  ///
  /// If whole piece is active:
  /// - Suggests a 1-measure loop of the most-missed measure (or measure 0 if 2 measures).
  /// - Returns null if the level only contains a single measure.
  /// If a multi-measure loop is already active:
  /// - Suggests narrowing to the most-missed measure within the loop, or halving the range.
  /// - Returns null if already looping a single measure.
  static (int, int)? suggestShorterPhrase({
    required LevelModel level,
    (int, int)? currentLoopRange,
    required List<LevelNote> allNotes,
    required List<NoteState> noteStates,
    HandSelection handSelection = HandSelection.both,
  }) {
    final totalMeasures = level.totalMeasures;
    if (totalMeasures <= 0) return null;

    final mostMissed = findMostMissedMeasure(
      allNotes: allNotes,
      noteStates: noteStates,
      handSelection: handSelection,
      withinLoopRange: currentLoopRange,
    );

    if (currentLoopRange == null) {
      if (totalMeasures <= 1) {
        return null; // Cannot shorten a 1-measure piece
      }
      if (mostMissed != null) {
        final clamped = mostMissed.clamp(0, totalMeasures - 1);
        return (clamped, clamped);
      }
      // If no specific measure had misses, offer the first measure
      return (0, 0);
    } else {
      final start = currentLoopRange.$1.clamp(0, totalMeasures - 1);
      final end = currentLoopRange.$2.clamp(start, totalMeasures - 1);
      if (start == end) {
        return null; // Already a single measure loop
      }

      if (mostMissed != null && mostMissed >= start && mostMissed <= end) {
        return (mostMissed, mostMissed);
      }
      // Halve the range
      final half = start + ((end - start) ~/ 2);
      return (start, half);
    }
  }

  /// Evaluates attempt results and formulates an [AssistanceOffer] if difficulty criteria are met.
  ///
  /// Returns null if:
  /// - [unsuccessfulAttempts] is less than [repeatedAttemptsThreshold], or
  /// - Neither a slower speed nor a shorter phrase can be offered.
  static AssistanceOffer? evaluate({
    required LevelModel level,
    required double currentSpeed,
    (int, int)? currentLoopRange,
    required List<LevelNote> allNotes,
    required List<NoteState> noteStates,
    required int unsuccessfulAttempts,
    HandSelection handSelection = HandSelection.both,
    int repeatedAttemptsThreshold = defaultRepeatedAttemptsThreshold,
  }) {
    if (unsuccessfulAttempts < repeatedAttemptsThreshold) {
      return null;
    }

    final suggestedSpeed = suggestSlowerSpeed(currentSpeed);
    final suggestedPhrase = suggestShorterPhrase(
      level: level,
      currentLoopRange: currentLoopRange,
      allNotes: allNotes,
      noteStates: noteStates,
      handSelection: handSelection,
    );

    if (suggestedSpeed == null && suggestedPhrase == null) {
      return null;
    }

    final mostMissed = findMostMissedMeasure(
      allNotes: allNotes,
      noteStates: noteStates,
      handSelection: handSelection,
      withinLoopRange: currentLoopRange,
    );

    final String message;
    if (suggestedSpeed != null && suggestedPhrase != null) {
      final rangeStr = suggestedPhrase.$1 == suggestedPhrase.$2
          ? 'measure ${suggestedPhrase.$1 + 1}'
          : 'measures ${suggestedPhrase.$1 + 1} to ${suggestedPhrase.$2 + 1}';
      message =
          'Try practicing at ${(suggestedSpeed * 100).round()}% speed or focusing on $rangeStr.';
    } else if (suggestedSpeed != null) {
      message =
          'Try slowing down to ${(suggestedSpeed * 100).round()}% speed.';
    } else {
      final rangeStr = suggestedPhrase!.$1 == suggestedPhrase.$2
          ? 'measure ${suggestedPhrase.$1 + 1}'
          : 'measures ${suggestedPhrase.$1 + 1} to ${suggestedPhrase.$2 + 1}';
      message = 'Try focusing on $rangeStr.';
    }

    final reason =
        'After $unsuccessfulAttempts unsuccessful attempts, assistance is available with a clear way back.';

    return AssistanceOffer(
      unsuccessfulAttempts: unsuccessfulAttempts,
      currentSpeed: currentSpeed,
      suggestedSpeed: suggestedSpeed,
      currentStartMeasure: currentLoopRange?.$1,
      currentEndMeasure: currentLoopRange?.$2,
      suggestedStartMeasure: suggestedPhrase?.$1,
      suggestedEndMeasure: suggestedPhrase?.$2,
      mostMissedMeasure: mostMissed,
      reason: reason,
      message: message,
    );
  }
}
