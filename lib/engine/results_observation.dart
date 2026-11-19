import '../models/engine_models.dart';
import '../models/level_models.dart';

/// The derived observation and guidance outcome from an attempt.
class AttemptObservation {
  const AttemptObservation({
    required this.observation,
    required this.difficultMeasureRange,
    required this.isAbandonedOrEmpty,
    this.worstMeasure,
    this.nextStageId,
    this.nextStageTitle,
  });

  /// Specific observation derived from the attempt. Empty if [isAbandonedOrEmpty] is true.
  final String observation;

  /// The 0-indexed contiguous measure range (startMeasure, endMeasure) containing clustered difficulty.
  /// Null if no errors occurred or if [isAbandonedOrEmpty] is true.
  final (int, int)? difficultMeasureRange;

  /// The single measure index with the highest error count, or null.
  final int? worstMeasure;

  /// Whether the attempt was empty (no notes struck/evaluated) or abandoned prematurely.
  final bool isAbandonedOrEmpty;

  /// ID of the next available stage unlocked after success, or null.
  final String? nextStageId;

  /// Title of the next available stage unlocked after success, or null.
  final String? nextStageTitle;

  bool get hasDifficultRange => difficultMeasureRange != null;
  bool get hasNextStage => nextStageId != null;
}

/// Derives specific observations, difficult measure ranges, and next-step actions
/// from completed attempts.
///
/// Empty or abandoned attempts must not invent advice.
class ResultsObservationEvaluator {
  const ResultsObservationEvaluator._();

  /// Evaluates an attempt to derive specific observations, difficult measure range,
  /// and progression guidance.
  static AttemptObservation evaluate({
    required List<NoteState> noteStates,
    required List<int> measureOfNote,
    Map<int, NoteHitResult> noteResults = const {},
    AttemptDetail? attemptDetail,
    bool isAbandoned = false,
    List<StageModel> allStages = const [],
    Map<String, dynamic> progress = const {},
    String? currentStageId,
    double passingAccuracyThreshold = 0.8,
  }) {
    // 1. Guard against empty or abandoned attempts: must not invent advice.
    final totalNotes = noteStates.length;
    final hasResolvedNotes = noteStates.any(
      (s) =>
          s == NoteState.hitPerfect ||
          s == NoteState.hitGood ||
          s == NoteState.hitOkay ||
          s == NoteState.missed,
    );
    final hasAttemptResults = noteResults.isNotEmpty ||
        (attemptDetail != null && attemptDetail.totalNotes > 0);

    if (isAbandoned || totalNotes == 0 || (!hasResolvedNotes && !hasAttemptResults)) {
      return const AttemptObservation(
        observation: '',
        difficultMeasureRange: null,
        isAbandonedOrEmpty: true,
        worstMeasure: null,
        nextStageId: null,
        nextStageTitle: null,
      );
    }

    // 2. Tally errors per measure.
    final missesPerMeasure = <int, int>{};
    final wrongPitchesPerMeasure = <int, int>{};
    final totalErrorsPerMeasure = <int, int>{};
    final timingErrorsPerMeasure = <int, List<double>>{};
    final allTimingErrors = <double>[];

    var rightCount = 0;
    for (final s in noteStates) {
      if (s == NoteState.hitPerfect || s == NoteState.hitGood || s == NoteState.hitOkay) {
        rightCount++;
      }
    }

    // Process per-note results map if present
    for (final entry in noteResults.entries) {
      final idx = entry.key;
      final res = entry.value;
      final measure = idx < measureOfNote.length ? measureOfNote[idx] : null;

      if (res.timingError != null) {
        allTimingErrors.add(res.timingError!);
        if (measure != null) {
          timingErrorsPerMeasure.putIfAbsent(measure, () => []).add(res.timingError!);
        }
      }

      if (res.isMissed) {
        if (measure != null) {
          missesPerMeasure[measure] = (missesPerMeasure[measure] ?? 0) + 1;
          totalErrorsPerMeasure[measure] = (totalErrorsPerMeasure[measure] ?? 0) + 1;
        }
      } else if (res.isWrongPitch) {
        if (measure != null) {
          wrongPitchesPerMeasure[measure] = (wrongPitchesPerMeasure[measure] ?? 0) + 1;
          totalErrorsPerMeasure[measure] = (totalErrorsPerMeasure[measure] ?? 0) + 1;
        }
      }
    }

    // If noteResults was empty, fallback to noteStates
    if (noteResults.isEmpty) {
      for (var i = 0; i < noteStates.length; i++) {
        final state = noteStates[i];
        final measure = i < measureOfNote.length ? measureOfNote[i] : null;
        if (state == NoteState.missed && measure != null) {
          missesPerMeasure[measure] = (missesPerMeasure[measure] ?? 0) + 1;
          totalErrorsPerMeasure[measure] = (totalErrorsPerMeasure[measure] ?? 0) + 1;
        }
      }
    }

    // Integrate attempt detail if noteResults was empty
    if (noteResults.isEmpty && attemptDetail != null) {
      if (allTimingErrors.isEmpty) {
        allTimingErrors.addAll(attemptDetail.signedTimingErrors);
      }
      for (final m in attemptDetail.missedMeasureIndices) {
        missesPerMeasure[m] = (missesPerMeasure[m] ?? 0) + 1;
        totalErrorsPerMeasure[m] = (totalErrorsPerMeasure[m] ?? 0) + 1;
      }
      for (final m in attemptDetail.wrongPitchMeasureIndices) {
        wrongPitchesPerMeasure[m] = (wrongPitchesPerMeasure[m] ?? 0) + 1;
        totalErrorsPerMeasure[m] = (totalErrorsPerMeasure[m] ?? 0) + 1;
      }
    }

    // 3. Find worst measure and contiguous difficult measure range
    int? worstMeasure;
    int maxErrors = 0;
    for (final entry in totalErrorsPerMeasure.entries) {
      if (entry.value > maxErrors) {
        maxErrors = entry.value;
        worstMeasure = entry.key;
      }
    }

    (int, int)? difficultRange;
    if (worstMeasure != null && maxErrors > 0) {
      var start = worstMeasure;
      var end = worstMeasure;

      // Expand left to contiguous measures with errors
      while (start > 0 && totalErrorsPerMeasure.containsKey(start - 1)) {
        start--;
      }
      // Expand right to contiguous measures with errors
      final maxMeasureInLevel = measureOfNote.isNotEmpty
          ? measureOfNote.reduce((a, b) => a > b ? a : b)
          : worstMeasure;
      while (end < maxMeasureInLevel && totalErrorsPerMeasure.containsKey(end + 1)) {
        end++;
      }
      difficultRange = (start, end);
    }

    final accuracy = totalNotes > 0 ? (rightCount / totalNotes) : 0.0;
    final isSuccess = totalErrorsPerMeasure.isEmpty || accuracy >= passingAccuracyThreshold;

    // 4. Derive next stage if successful
    String? nextStageId;
    String? nextStageTitle;
    if (isSuccess && currentStageId != null && allStages.isNotEmpty) {
      final sortedStages = [...allStages]..sort((a, b) => a.order.compareTo(b.order));
      final currentIndex = sortedStages.indexWhere((s) => s.id == currentStageId);
      if (currentIndex != -1 && currentIndex + 1 < sortedStages.length) {
        final candidate = sortedStages[currentIndex + 1];
        nextStageId = candidate.id;
        nextStageTitle = candidate.title;
      }
    }

    // 5. Derive specific observation
    final double? avgTimingError = allTimingErrors.isNotEmpty
        ? allTimingErrors.reduce((a, b) => a + b) / allTimingErrors.length
        : null;

    final String observation;
    if (difficultRange != null) {
      final rangeStr = difficultRange.$1 == difficultRange.$2
          ? 'Bar ${difficultRange.$1 + 1}'
          : 'Bars ${difficultRange.$1 + 1}–${difficultRange.$2 + 1}';

      var wrongInSpan = 0;
      var missedInSpan = 0;
      for (var b = difficultRange.$1; b <= difficultRange.$2; b++) {
        wrongInSpan += wrongPitchesPerMeasure[b] ?? 0;
        missedInSpan += missesPerMeasure[b] ?? 0;
      }

      if (wrongInSpan > 0 && missedInSpan == 0) {
        observation =
            '$rangeStr had unexpected pitches. Check your hand position and take time to find each key.';
      } else if (wrongInSpan == 0 && missedInSpan > 0) {
        if (avgTimingError != null && avgTimingError < -0.05) {
          observation =
              'Notes in $rangeStr were missed while rushing ahead of the beat. Relax and let the pulse arrive.';
        } else if (avgTimingError != null && avgTimingError > 0.05) {
          observation =
              'Notes in $rangeStr were missed while lagging behind the beat. Strike a little earlier.';
        } else {
          observation =
              'Notes were missed in $rangeStr. Play it slowly a few times to get the rhythm.';
        }
      } else {
        observation =
            '$rangeStr had unexpected pitches and missed notes. Focus on this passage slowly.';
      }
    } else {
      // Clean attempt without difficult range
      if (avgTimingError != null && avgTimingError < -0.05) {
        observation =
            'Every note right! Your timing rushed slightly ahead of the beat. Relax and let the pulse arrive.';
      } else if (avgTimingError != null && avgTimingError > 0.05) {
        observation =
            'Every note right! Your timing lagged slightly behind the beat. Strike a little earlier.';
      } else if (nextStageTitle != null) {
        observation =
            'Clean run with steady timing. Ready for $nextStageTitle.';
      } else {
        observation =
            'Every note right first time. The next piece in the book is open.';
      }
    }

    return AttemptObservation(
      observation: observation,
      difficultMeasureRange: difficultRange,
      worstMeasure: worstMeasure,
      isAbandonedOrEmpty: false,
      nextStageId: isSuccess ? nextStageId : null,
      nextStageTitle: isSuccess ? nextStageTitle : null,
    );
  }
}
