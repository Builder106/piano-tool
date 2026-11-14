import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/engine/timing_advice.dart';
import 'package:piano_tool/models/engine_models.dart';

void main() {
  group('TimingAdvice', () {
    test(
      'refuses to generate timing advice when input latency is uncalibrated',
      () {
        final results = [
          const NoteHitResult.good(noteIndex: 0, timingError: 0.15),
          const NoteHitResult.okay(noteIndex: 1, timingError: 0.25),
        ];

        final advice = TimingAdvice.evaluate(
          hitResults: results,
          isCalibrated: false,
        );

        expect(advice, isNotNull);
        expect(advice!.isCalibrated, isFalse);
        expect(advice.trend, TimingTrend.uncalibrated);
        expect(advice.averageErrorBeats, isNull);
        expect(
          advice.message,
          'Calibrate input latency before generating timing advice.',
        );
      },
    );

    test('detects rushing when player consistently strikes ahead of beat', () {
      final results = [
        const NoteHitResult.good(noteIndex: 0, timingError: -0.12),
        const NoteHitResult.good(noteIndex: 1, timingError: -0.10),
        const NoteHitResult.perfect(noteIndex: 2, timingError: -0.06),
      ];

      final advice = TimingAdvice.evaluate(
        hitResults: results,
        isCalibrated: true,
      );

      expect(advice, isNotNull);
      expect(advice!.isCalibrated, isTrue);
      expect(advice.trend, TimingTrend.rushing);
      expect(advice.averageErrorBeats, closeTo(-0.0933, 0.001));
      expect(advice.message, contains('ahead of the beat'));
    });

    test('detects dragging when player consistently strikes behind beat', () {
      final results = [
        const NoteHitResult.good(noteIndex: 0, timingError: 0.14),
        const NoteHitResult.good(noteIndex: 1, timingError: 0.11),
        const NoteHitResult.okay(noteIndex: 2, timingError: 0.22),
      ];

      final advice = TimingAdvice.evaluate(
        hitResults: results,
        isCalibrated: true,
      );

      expect(advice, isNotNull);
      expect(advice!.isCalibrated, isTrue);
      expect(advice.trend, TimingTrend.dragging);
      expect(advice.averageErrorBeats, closeTo(0.1566, 0.001));
      expect(advice.message, contains('behind the beat'));
    });

    test('detects on-time performance when average error is near zero', () {
      final results = [
        const NoteHitResult.perfect(noteIndex: 0, timingError: 0.02),
        const NoteHitResult.perfect(noteIndex: 1, timingError: -0.01),
        const NoteHitResult.perfect(noteIndex: 2, timingError: 0.01),
      ];

      final advice = TimingAdvice.evaluate(
        hitResults: results,
        isCalibrated: true,
      );

      expect(advice, isNotNull);
      expect(advice!.isCalibrated, isTrue);
      expect(advice.trend, TimingTrend.onTime);
      expect(advice.message, contains('steady'));
    });

    test('ignores missed notes when evaluating timing trend', () {
      final results = [
        const NoteHitResult.missed(noteIndex: 0),
        const NoteHitResult.perfect(noteIndex: 1, timingError: -0.12),
        const NoteHitResult.good(noteIndex: 2, timingError: -0.10),
      ];

      final advice = TimingAdvice.evaluate(
        hitResults: results,
        isCalibrated: true,
      );

      expect(advice, isNotNull);
      expect(advice!.trend, TimingTrend.rushing);
      expect(advice.averageErrorBeats, closeTo(-0.11, 0.001));
    });

    test('returns null when no notes were hit', () {
      final results = [
        const NoteHitResult.missed(noteIndex: 0),
        const NoteHitResult.missed(noteIndex: 1),
      ];

      final advice = TimingAdvice.evaluate(
        hitResults: results,
        isCalibrated: true,
      );

      expect(advice, isNull);
    });
  });
}
