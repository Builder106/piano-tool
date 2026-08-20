import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/audio/pitch_detector.dart';
import 'package:piano_tool/models/audio_models.dart';

void main() {
  group('PitchDetector YIN algorithm tests', () {
    const sampleRate = 44100;
    const bufferSize = 2048;
    final detector = PitchDetector(
      config: const AudioEngineConfig(
        sampleRate: sampleRate,
        bufferSize: bufferSize,
        minConfidenceThreshold: 0.7,
      ),
    );

    test('Detects A4 (440 Hz) pitch and MIDI note 69 from synthetic sine wave', () {
      final buffer = List<int>.generate(bufferSize, (i) {
        final t = i / sampleRate;
        final sample = math.sin(2 * math.pi * 440.0 * t);
        return (sample * 20000).round();
      });

      final event = detector.processBuffer(buffer);
      expect(event, isNotNull);
      expect(event!.frequency, closeTo(440.0, 5.0));
      expect(event.midiNote, equals(69));
      expect(event.confidence, greaterThanOrEqualTo(0.7));
    });

    test('Detects Middle C / C4 (261.63 Hz) pitch and MIDI note 60', () {
      final buffer = List<int>.generate(bufferSize, (i) {
        final t = i / sampleRate;
        final sample = math.sin(2 * math.pi * 261.63 * t);
        return (sample * 20000).round();
      });

      final event = detector.processBuffer(buffer);
      expect(event, isNotNull);
      expect(event!.frequency, closeTo(261.63, 5.0));
      expect(event.midiNote, equals(60));
    });

    test('Rejects silence / very low RMS volume', () {
      final silentBuffer = List<int>.filled(bufferSize, 0);
      final event = detector.processBuffer(silentBuffer);
      expect(event, isNull);
    });
  });
}
