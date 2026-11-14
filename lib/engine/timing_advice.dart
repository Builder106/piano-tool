import '../models/engine_models.dart';

/// Timing trend observation from practice attempts.
enum TimingTrend { uncalibrated, onTime, rushing, dragging }

/// Evaluates player timing trends against calibrated input latency.
///
/// Uncalibrated hardware latency distorts timing measurements: a learner
/// playing on time can appear late if audio buffer or device latency is not
/// calibrated. Calibrated input latency must be established before generating
/// timing advice. Timing tolerance windows must also remain separate from
/// pitch tuning.
class TimingAdvice {
  const TimingAdvice._({
    required this.trend,
    required this.averageErrorBeats,
    required this.message,
    required this.isCalibrated,
  });

  final TimingTrend trend;
  final double? averageErrorBeats;
  final String message;
  final bool isCalibrated;

  /// Derives timing advice from scored note results.
  ///
  /// If [isCalibrated] is false, timing advice is NOT generated (returns
  /// [TimingTrend.uncalibrated]), preventing hardware latency or uncalibrated
  /// input from being falsely attributed to the learner.
  static TimingAdvice? evaluate({
    required List<NoteHitResult> hitResults,
    required bool isCalibrated,
    double rushingThreshold = -0.05,
    double draggingThreshold = 0.05,
  }) {
    if (!isCalibrated) {
      return const TimingAdvice._(
        trend: TimingTrend.uncalibrated,
        averageErrorBeats: null,
        message: 'Calibrate input latency before generating timing advice.',
        isCalibrated: false,
      );
    }

    final scoredHits = hitResults
        .where((r) => r.noteState != NoteState.missed)
        .toList();
    if (scoredHits.isEmpty) return null;

    final errors = <double>[];
    for (final hit in scoredHits) {
      final err = hit.whenOrNull(
        perfect: (_, error) => error,
        good: (_, error) => error,
        okay: (_, error) => error,
      );
      if (err != null) {
        errors.add(err);
      }
    }
    if (errors.isEmpty) return null;

    final avgError = errors.reduce((a, b) => a + b) / errors.length;

    if (avgError < rushingThreshold) {
      return TimingAdvice._(
        trend: TimingTrend.rushing,
        averageErrorBeats: avgError,
        message:
            'Notes are landing slightly ahead of the beat. Relax and let the beat arrive.',
        isCalibrated: true,
      );
    } else if (avgError > draggingThreshold) {
      return TimingAdvice._(
        trend: TimingTrend.dragging,
        averageErrorBeats: avgError,
        message:
            'Notes are landing slightly behind the beat. Strike a little earlier.',
        isCalibrated: true,
      );
    } else {
      return TimingAdvice._(
        trend: TimingTrend.onTime,
        averageErrorBeats: avgError,
        message: 'Your timing is steady with the beat.',
        isCalibrated: true,
      );
    }
  }
}
