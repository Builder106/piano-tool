import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/audio/pcm_frame_converter.dart';
import 'package:piano_tool/audio/pitch_detector.dart';
import 'package:piano_tool/models/audio_models.dart';

List<int> _int16(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  return [
    for (var i = 0; i < bytes.length ~/ 2; i++)
      data.getInt16(i * 2, Endian.little),
  ];
}

Float32List _sine(double hz, int rate, int length, {int offset = 0}) =>
    Float32List.fromList([
      for (var i = offset; i < offset + length; i++)
        0.6 * math.sin(2 * math.pi * hz * i / rate),
    ]);

/// Feeds a browser-rate sine through [PcmFrameConverter] in worklet-sized
/// frames, the way [WebPcmRecorder] does, so the detector sees the bytes the
/// web build would give it.
class _ConvertedSineRecorder implements PcmRecorder {
  _ConvertedSineRecorder(this.hz, this.sourceRate);

  final double hz;
  final int sourceRate;

  @override
  Future<void> open() async {}

  @override
  Future<void> start({
    required StreamSink<Uint8List> sink,
    required int sampleRate,
  }) async {
    final converter = PcmFrameConverter(
      sourceRate: sourceRate.toDouble(),
      targetRate: sampleRate,
    );
    // Frames arrive after start returns, as they do from a real microphone.
    Timer.run(() {
      for (var offset = 0; offset < sourceRate ~/ 4; offset += 1024) {
        sink.add(
          converter.convert(_sine(hz, sourceRate, 1024, offset: offset)),
        );
      }
    });
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> close() async {}
}

void main() {
  group('PcmFrameConverter', () {
    test('writes 16-bit little-endian samples at an equal rate', () {
      final converter = PcmFrameConverter(sourceRate: 44100, targetRate: 44100);
      final bytes = converter.convert(
        Float32List.fromList([0, 0.5, -0.5, 1, -1]),
      );

      expect(bytes.length, 10);
      expect(_int16(bytes), [0, 16384, -16384, 32767, -32767]);
      expect(bytes.sublist(2, 4), [0x00, 0x40]);
    });

    test('clamps samples outside -1 to 1', () {
      final converter = PcmFrameConverter(sourceRate: 44100, targetRate: 44100);
      expect(_int16(converter.convert(Float32List.fromList([1.7, -3]))), [
        32767,
        -32767,
      ]);
    });

    test('returns no bytes for an empty frame', () {
      final converter = PcmFrameConverter(sourceRate: 48000, targetRate: 44100);
      expect(converter.convert(Float32List(0)), isEmpty);
    });

    test('resamples one second of 48 kHz frames to 44.1 kHz', () {
      final converter = PcmFrameConverter(sourceRate: 48000, targetRate: 44100);
      var samples = 0;
      for (var offset = 0; offset < 48000; offset += 1024) {
        final length = math.min(1024, 48000 - offset);
        samples += converter.convert(Float32List(length)).length ~/ 2;
      }
      expect(samples, closeTo(44100, 1));
    });

    test('frame boundaries leave no seam', () {
      final signal = _sine(440, 48000, 4096);
      final whole = _int16(
        PcmFrameConverter(sourceRate: 48000, targetRate: 44100).convert(signal),
      );

      final chunked = PcmFrameConverter(sourceRate: 48000, targetRate: 44100);
      final pieces = <int>[];
      for (var offset = 0; offset < signal.length; offset += 128) {
        pieces.addAll(
          _int16(
            chunked.convert(
              Float32List.sublistView(signal, offset, offset + 128),
            ),
          ),
        );
      }

      expect(pieces.length, whole.length);
      for (var i = 0; i < whole.length; i++) {
        expect(pieces[i], closeTo(whole[i], 1), reason: 'sample $i');
      }
    });
  });

  group('PitchDetector fed by the web recorder path', () {
    const config = AudioEngineConfig();

    Future<List<PitchEvent>> detect(double hz, int browserRate) async {
      final detector = PitchDetector(
        config: config,
        recorderFactory: () => _ConvertedSineRecorder(hz, browserRate),
      );
      final events = <PitchEvent>[];
      final sub = detector.pitchStream.listen(events.add);
      await detector.start();
      await pumpEventQueue();
      await sub.cancel();
      await detector.dispose();
      return events;
    }

    for (final rate in [44100, 48000]) {
      test('hears C4 from a $rate Hz browser graph as MIDI 60', () async {
        final events = await detect(261.63, rate);
        expect(events, isNotEmpty);
        expect(events.map((e) => e.midiNote).toSet(), {60});
      });
    }

    test('without resampling, 48 kHz C4 would be heard as B3', () {
      final detector = PitchDetector(config: config);
      final raw = _sine(261.63, 48000, config.bufferSize);
      final event = detector.processBuffer([
        for (final s in raw) (s * 32767).round(),
      ]);
      expect(event?.midiNote, 59);
    });
  });
}
