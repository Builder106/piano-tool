import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:piano_tool/audio/tone_synthesizer.dart';

void main() {
  group('ToneGenerator', () {
    test('calculates correct frequencies for MIDI notes', () {
      expect(ToneGenerator.midiToFrequency(69), 440.0); // A4
      expect(ToneGenerator.midiToFrequency(57), 220.0); // A3
      expect(ToneGenerator.midiToFrequency(81), 880.0); // A5

      // Middle C (C4 = 60) is ~261.63 Hz
      final c4 = ToneGenerator.midiToFrequency(60);
      expect((c4 - 261.63).abs(), lessThan(0.01));
    });

    test('builds valid 44-byte RIFF WAVE header', () {
      final header = ToneGenerator.buildWavHeader(
        totalAudioLen: 1000,
        sampleRate: 44100,
        channels: 1,
        bitsPerSample: 16,
      );

      expect(header.length, 44);

      // Check ASCII markers: 'RIFF', 'WAVE', 'fmt ', 'data'
      final tagRiff = String.fromCharCodes(header.sublist(0, 4));
      final tagWave = String.fromCharCodes(header.sublist(8, 12));
      final tagFmt = String.fromCharCodes(header.sublist(12, 16));
      final tagData = String.fromCharCodes(header.sublist(36, 40));

      expect(tagRiff, 'RIFF');
      expect(tagWave, 'WAVE');
      expect(tagFmt, 'fmt ');
      expect(tagData, 'data');

      final view = ByteData.sublistView(header);
      expect(view.getUint16(20, Endian.little), 1); // PCM
      expect(view.getUint16(22, Endian.little), 1); // Mono
      expect(view.getUint32(24, Endian.little), 44100); // Sample rate
      expect(view.getUint16(34, Endian.little), 16); // 16-bit
      expect(view.getUint32(40, Endian.little), 1000); // Audio length
    });

    test('generates valid WAV buffer for piano tone', () {
      final wav = ToneGenerator.generatePianoToneWav(
        midiNote: 60,
        durationSeconds: 0.1,
        sampleRate: 44100,
      );

      // Header is 44 bytes + 4410 samples * 2 bytes = 8864 bytes
      expect(wav.length, greaterThan(44));

      final tag = String.fromCharCodes(wav.sublist(0, 4));
      expect(tag, 'RIFF');

      // Verify samples are non-zero
      final samples = ByteData.sublistView(wav, 44);
      var hasNonZero = false;
      for (int i = 0; i < samples.lengthInBytes; i += 2) {
        if (samples.getInt16(i, Endian.little) != 0) {
          hasNonZero = true;
          break;
        }
      }
      expect(hasNonZero, isTrue);
    });
  });

  group('AudioSynthesizer', () {
    test('plays note using player and caches buffer', () async {
      final player = SilentAudioTonePlayer();
      final synth = AudioSynthesizer(player: player);

      await synth.playNote(midiNote: 60, durationSeconds: 0.2);

      expect(player.playCount, 1);
      expect(player.playedBuffers.length, 1);
      final firstBuf = player.playedBuffers.first;

      // Repeat should hit cache
      await synth.playNote(midiNote: 60, durationSeconds: 0.2);
      expect(player.playCount, 2);
      expect(identical(player.playedBuffers.last, firstBuf), isTrue);
    });

    test('does not play notes when muted', () async {
      final player = SilentAudioTonePlayer();
      final synth = AudioSynthesizer(player: player);

      synth.isMuted = true;
      await synth.playNote(midiNote: 64, durationSeconds: 0.3);

      expect(player.playCount, 0);
      expect(player.playedBuffers, isEmpty);

      synth.isMuted = false;
      await synth.playNote(midiNote: 64, durationSeconds: 0.3);

      expect(player.playCount, 1);
    });

    test('stop and dispose lifecycle delegate to player', () async {
      final player = SilentAudioTonePlayer();
      final synth = AudioSynthesizer(player: player);

      await synth.open();
      expect(player.isOpen, isTrue);

      await synth.stop();
      await synth.dispose();
      expect(player.isOpen, isFalse);
    });
  });
}
