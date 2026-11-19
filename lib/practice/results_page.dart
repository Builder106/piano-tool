import 'package:flutter/material.dart';

import '../brand/scale.dart';
import '../brand/buttons.dart';
import '../brand/palette.dart';
import '../brand/pencil_loop.dart';
import '../engine/results_observation.dart';
import '../models/engine_models.dart';
import '../models/level_models.dart';

/// What a run came to, in the teacher's terms: notes right first time, and
/// which bars to play again.
class RunSummary {
  const RunSummary({
    required this.right,
    required this.total,
    required this.missedBars,
    required this.worstBar,
    this.attemptDetail,
    this.noteResults = const {},
    this.signedTimingErrors = const [],
    this.missedExpectedCount = 0,
    this.wrongPitchCount = 0,
    this.missedExpectedBars = const [],
    this.wrongPitchBars = const [],
    this.difficultMeasureRange,
    this.specificObservation,
    this.isAbandonedOrEmpty = false,
    this.nextStageId,
    this.nextStageTitle,
  });

  factory RunSummary.of(
    List<NoteState> states,
    List<int> measureOfNote, {
    Map<int, NoteHitResult>? noteResults,
    AttemptDetail? attemptDetail,
    bool isAbandoned = false,
    List<StageModel> allStages = const [],
    Map<String, dynamic> progress = const {},
    String? currentStageId,
  }) {
    var right = 0;
    final misses = <int, int>{};
    for (final (i, s) in states.indexed) {
      switch (s) {
        case NoteState.hitPerfect || NoteState.hitGood || NoteState.hitOkay:
          right++;
        case NoteState.missed:
          if (i < measureOfNote.length) {
            misses[measureOfNote[i]] = (misses[measureOfNote[i]] ?? 0) + 1;
          }
        case NoteState.upcoming || NoteState.active:
          break;
      }
    }
    final bars = misses.keys.toList()..sort();
    int? worst;
    for (final bar in bars) {
      if (worst == null || misses[bar]! > misses[worst]!) worst = bar;
    }

    final resultsMap = noteResults ?? attemptDetail?.noteResultsMap ?? const {};
    final timingErrors =
        attemptDetail?.signedTimingErrors ??
        [
          for (final res in resultsMap.values)
            if (res.timingError != null) res.timingError!,
        ];

    final missedExpectedBars = <int>{};
    final wrongPitchBars = <int>{};
    var missedExpectedCount = 0;
    var wrongPitchCount = 0;

    for (final entry in resultsMap.entries) {
      final idx = entry.key;
      final res = entry.value;
      final bar = idx < measureOfNote.length ? measureOfNote[idx] : null;

      if (res.isMissed) {
        missedExpectedCount++;
        if (bar != null) missedExpectedBars.add(bar);
      } else if (res.isWrongPitch) {
        wrongPitchCount++;
        if (bar != null) wrongPitchBars.add(bar);
      }
    }

    if (resultsMap.isEmpty && attemptDetail != null) {
      missedExpectedCount = attemptDetail.missedNotes;
      wrongPitchCount = attemptDetail.wrongPitchNotes;
      missedExpectedBars.addAll(attemptDetail.missedMeasureIndices);
      wrongPitchBars.addAll(attemptDetail.wrongPitchMeasureIndices);
    }

    final obs = ResultsObservationEvaluator.evaluate(
      noteStates: states,
      measureOfNote: measureOfNote,
      noteResults: resultsMap,
      attemptDetail: attemptDetail,
      isAbandoned: isAbandoned,
      allStages: allStages,
      progress: progress,
      currentStageId: currentStageId,
    );

    return RunSummary(
      right: right,
      total: states.length,
      missedBars: bars,
      worstBar: obs.worstMeasure ?? worst,
      attemptDetail: attemptDetail,
      noteResults: resultsMap,
      signedTimingErrors: timingErrors,
      missedExpectedCount: missedExpectedCount,
      wrongPitchCount: wrongPitchCount,
      missedExpectedBars: missedExpectedBars.toList()..sort(),
      wrongPitchBars: wrongPitchBars.toList()..sort(),
      difficultMeasureRange: obs.difficultMeasureRange,
      specificObservation: obs.observation,
      isAbandonedOrEmpty: obs.isAbandonedOrEmpty,
      nextStageId: obs.nextStageId,
      nextStageTitle: obs.nextStageTitle,
    );
  }

  final int right;
  final int total;

  /// Measure indices, zero-based, that held a missed note.
  final List<int> missedBars;
  final int? worstBar;

  /// Preserved attempt detail, or null if constructed without attempt details.
  final AttemptDetail? attemptDetail;

  /// Per-note hit results preserving attempt performance details.
  final Map<int, NoteHitResult> noteResults;

  /// Signed timing errors from all struck notes in the attempt (beats: negative = early, positive = late).
  final List<double> signedTimingErrors;

  /// Number of missed expected notes (unplayed / expired).
  final int missedExpectedCount;

  /// Number of confirmed wrong pitches.
  final int wrongPitchCount;

  /// Measure indices containing unplayed missed notes.
  final List<int> missedExpectedBars;

  /// Measure indices containing confirmed wrong pitches.
  final List<int> wrongPitchBars;

  /// Contiguous measure range (startMeasure, endMeasure) containing clustered difficulty.
  final (int, int)? difficultMeasureRange;

  /// Specific observation derived from the attempt.
  final String? specificObservation;

  /// Whether the attempt was empty or abandoned before completing.
  final bool isAbandonedOrEmpty;

  /// Next available stage ID if attempt succeeded.
  final String? nextStageId;

  /// Next available stage title if attempt succeeded.
  final String? nextStageTitle;

  /// Whether attempt detail was preserved in this summary.
  bool get hasAttemptDetail => attemptDetail != null || noteResults.isNotEmpty;

  /// Whether any confirmed wrong pitches occurred in this run.
  bool get hasWrongPitches => wrongPitchCount > 0;

  /// Whether any missed expected notes (unplayed) occurred in this run.
  bool get hasMissedExpected => missedExpectedCount > 0;

  /// Whether a difficult measure range was derived.
  bool get hasDifficultRange => difficultMeasureRange != null;

  /// Average signed timing error across played notes, or null if no timing errors exist.
  double? get averageTimingError => signedTimingErrors.isNotEmpty
      ? signedTimingErrors.reduce((a, b) => a + b) / signedTimingErrors.length
      : null;

  int get missed => total - right;

  String get headline {
    if (isAbandonedOrEmpty) return 'Attempt not completed.';
    if (missed == 0) return 'Every note right first time.';
    return missed == 1
        ? 'One note needed another go.'
        : '$missed notes needed another go.';
  }

  String get advice {
    if (isAbandonedOrEmpty) return '';
    if (specificObservation != null && specificObservation!.isNotEmpty) {
      return specificObservation!;
    }
    final bar = worstBar;
    if (bar == null) return 'The next piece in the book is open.';
    return 'Bar ${bar + 1} had the most. Play it slowly a few times and it '
        'will stick.';
  }
}

/// The page handed back marked: the grade circled in red pencil, a plain
/// sentence, and what to do next.
class ResultsPage extends StatelessWidget {
  const ResultsPage({
    super.key,
    required this.summary,
    required this.staff,
    required this.onPractise,
    this.onPractiseRange,
    this.onNextStage,
    required this.onAgain,
    required this.onDone,
  });

  final RunSummary summary;

  /// The piece, marked, shown above the verdict.
  final Widget staff;
  final void Function(int bar) onPractise;
  final void Function(int startBar, int endBar)? onPractiseRange;
  final VoidCallback? onNextStage;
  final VoidCallback onAgain;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final u = unitOf(context);
    final bar = summary.worstBar;
    final range = summary.difficultMeasureRange;
    final adviceText = summary.advice;

    return Padding(
      padding: EdgeInsets.fromLTRB(40 * u, 8 * u, 40 * u, 20 * u),
      child: Column(
        children: [
          Expanded(flex: 5, child: staff),
          Expanded(
            flex: 6,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Grade(summary: summary, u: u),
                SizedBox(width: 48 * u),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.headline,
                          style: TextStyle(
                            fontFamily: Fonts.ui,
                            fontSize: 30 * u,
                            height: 1.1,
                            color: Palette.ink,
                            fontVariations: const [FontVariation('wght', 800)],
                          ),
                        ),
                        if (adviceText.isNotEmpty) ...[
                          SizedBox(height: 8 * u),
                          Text(
                            adviceText,
                            style: TextStyle(
                              fontFamily: Fonts.ui,
                              fontSize: 20 * u,
                              height: 1.35,
                              color: Palette.graphite,
                            ),
                          ),
                        ],
                        SizedBox(height: 22 * u),
                        Wrap(
                          spacing: 14 * u,
                          runSpacing: 12 * u,
                          children: [
                            if (!summary.isAbandonedOrEmpty) ...[
                              if (range != null)
                                StartButton(
                                  label: range.$1 == range.$2
                                      ? 'Practise bar ${range.$1 + 1}'
                                      : 'Practise bars ${range.$1 + 1}–${range.$2 + 1}',
                                  onPressed: () {
                                    if (onPractiseRange != null) {
                                      onPractiseRange!(range.$1, range.$2);
                                    } else {
                                      onPractise(range.$1);
                                    }
                                  },
                                )
                              else if (bar != null)
                                StartButton(
                                  label: 'Practise bar ${bar + 1}',
                                  onPressed: () => onPractise(bar),
                                )
                              else if (onNextStage != null)
                                StartButton(
                                  label: summary.nextStageTitle != null
                                      ? 'Next piece: ${summary.nextStageTitle}'
                                      : 'Next piece',
                                  onPressed: onNextStage,
                                ),
                            ],
                            QuietButton(
                              label: 'Play again',
                              onPressed: onAgain,
                            ),
                            QuietButton(
                              label: 'Back to pieces',
                              onPressed: onDone,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Grade extends StatelessWidget {
  const _Grade({required this.summary, required this.u});

  final RunSummary summary;
  final double u;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${summary.right} of ${summary.total} notes right first time',
      child: ExcludeSemantics(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 44 * u,
                vertical: 30 * u,
              ),
              child: Text(
                '${summary.right}/${summary.total}',
                style: TextStyle(
                  fontFamily: Fonts.ui,
                  fontSize: 96 * u,
                  height: 1,
                  letterSpacing: -4 * u,
                  color: Palette.ink,
                  fontVariations: const [FontVariation('wght', 800)],
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _GradeLoop(width: 5.5 * u.clamp(0.8, 1.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeLoop extends CustomPainter {
  const _GradeLoop({required this.width});

  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    PencilLoopPainter(
      target: (Offset.zero & size).deflate(2),
      color: Palette.pencilRed,
      width: width,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_GradeLoop old) => old.width != width;
}
