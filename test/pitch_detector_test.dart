import 'dart:math' as math;
import 'dart:typed_data';
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

    test('Detects A4 (440 Hz) pitch and MIDI note 69 from synthetic sine wave',
        () {
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

    test('uses the configured volume threshold before emitting a pitch', () {
      final quietA4 = List<int>.generate(bufferSize, (i) {
        final t = i / sampleRate;
        return (math.sin(2 * math.pi * 440.0 * t) * 2000).round();
      });
      final permissive = PitchDetector(
        config: const AudioEngineConfig(
          sampleRate: sampleRate,
          bufferSize: bufferSize,
          minVolumeThreshold: 0.01,
          minConfidenceThreshold: 0,
        ),
      );
      final restrictive = PitchDetector(
        config: const AudioEngineConfig(
          sampleRate: sampleRate,
          bufferSize: bufferSize,
          minVolumeThreshold: 0.1,
          minConfidenceThreshold: 0,
        ),
      );

      expect(permissive.processBuffer(quietA4), isNotNull);
      expect(restrictive.processBuffer(quietA4), isNull);
    });

    test('uses the configured reference frequency for MIDI conversion', () {
      final detector = PitchDetector(
        config: const AudioEngineConfig(
          sampleRate: sampleRate,
          bufferSize: bufferSize,
          referenceFrequency: 432.0,
          minConfidenceThreshold: 0.7,
        ),
      );
      final buffer = List<int>.generate(bufferSize, (i) {
        final t = i / sampleRate;
        return (math.sin(2 * math.pi * 432.0 * t) * 20000).round();
      });

      expect(detector.processBuffer(buffer)!.midiNote, 69);
    });

    test('timestamps are zero for buffers processed outside a session', () {
      final buffer = List<int>.generate(bufferSize, (i) {
        final t = i / sampleRate;
        return (math.sin(2 * math.pi * 440.0 * t) * 20000).round();
      });

      expect(detector.processBuffer(buffer)!.timestamp, 0);
    });
  });

  test('failed recorder startup cleans up and can be retried', () async {
    final recorders = <_FakeRecorder>[];
    var shouldFail = true;
    final detector = PitchDetector(
      recorderFactory: () {
        final recorder = _FakeRecorder(shouldFail: shouldFail);
        shouldFail = false;
        recorders.add(recorder);
        return recorder;
      },
    );
    addTearDown(detector.dispose);

    await expectLater(detector.start(), throwsStateError);
    expect(recorders.single.stopCount, 1);
    expect(recorders.single.closeCount, 1);
    await detector.start();
    expect(detector.isRunning, isTrue);
    await detector.stop();
    expect(recorders.last.stopCount, 1);
    expect(recorders.last.closeCount, 1);
  });
}

class _FakeRecorder implements PcmRecorder {
  _FakeRecorder({required this.shouldFail});

  final bool shouldFail;
  int stopCount = 0;
  int closeCount = 0;

  @override
  Future<void> open() async {}

  @override
  Future<void> start({
    required StreamSink<Uint8List> sink,
    required int sampleRate,
  }) async {
    if (shouldFail) throw StateError('startup failed');
  }

  @override
  Future<void> stop() async => stopCount++;

  @override
  Future<void> close() async => closeCount++;
}
