import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';

/// Low-level audio player interface for synthesized tone buffers.
abstract interface class AudioTonePlayer {
  Future<void> open();
  Future<void> playWav(Uint8List wavBytes);
  Future<void> stop();
  Future<void> close();
}

/// Default platform implementation using FlutterSoundPlayer.
class FlutterSoundTonePlayer implements AudioTonePlayer {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isOpen = false;

  @override
  Future<void> open() async {
    if (_isOpen) return;
    try {
      await _player.openPlayer();
      _isOpen = true;
    } catch (e) {
      debugPrint('FlutterSoundTonePlayer open error: $e');
    }
  }

  @override
  Future<void> playWav(Uint8List wavBytes) async {
    try {
      if (!_isOpen) await open();
      if (_player.isPlaying) {
        await _player.stopPlayer();
      }
      await _player.startPlayer(
        fromDataBuffer: wavBytes,
        codec: Codec.pcm16WAV,
        numChannels: 1,
        sampleRate: 44100,
      );
    } catch (e) {
      debugPrint('FlutterSoundTonePlayer play error: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      if (_isOpen && _player.isPlaying) {
        await _player.stopPlayer();
      }
    } catch (e) {
      debugPrint('FlutterSoundTonePlayer stop error: $e');
    }
  }

  @override
  Future<void> close() async {
    try {
      if (_isOpen) {
        await _player.closePlayer();
        _isOpen = false;
      }
    } catch (e) {
      debugPrint('FlutterSoundTonePlayer close error: $e');
    }
  }
}

/// In-memory silent audio tone player for unit and widget tests.
class SilentAudioTonePlayer implements AudioTonePlayer {
  final List<Uint8List> playedBuffers = [];
  bool isOpen = false;
  int playCount = 0;

  @override
  Future<void> open() async {
    isOpen = true;
  }

  @override
  Future<void> playWav(Uint8List wavBytes) async {
    playCount++;
    playedBuffers.add(wavBytes);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> close() async {
    isOpen = false;
  }
}

/// Generates PCM WAV audio buffers with natural piano-like additive harmonic decay.
class ToneGenerator {
  static const int defaultSampleRate = 44100;

  /// Calculates frequency in Hertz for a given MIDI note number (60 = C4, 69 = A4).
  static double midiToFrequency(int midiNote) {
    return 440.0 * math.pow(2.0, (midiNote - 69) / 12.0);
  }

  /// Synthesizes 16-bit PCM WAV bytes for a note with natural piano decay and attack.
  static Uint8List generatePianoToneWav({
    required int midiNote,
    required double durationSeconds,
    int sampleRate = defaultSampleRate,
  }) {
    final duration = durationSeconds.clamp(0.05, 4.0);
    final numSamples = (sampleRate * duration).toInt();
    final pcmBytes = Uint8List(numSamples * 2);
    final byteData = ByteData.sublistView(pcmBytes);

    final freq = midiToFrequency(midiNote);
    final attackSamples = (sampleRate * 0.005)
        .toInt(); // 5ms attack to avoid pops

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final attack = i < attackSamples ? (i / attackSamples) : 1.0;
      final decay = math.exp(-3.5 * t / duration);

      // Additive harmonics: fundamental + 2nd + 3rd harmonic
      final sample =
          (math.sin(2 * math.pi * freq * t) * 0.60 +
              math.sin(4 * math.pi * freq * t) * 0.25 +
              math.sin(6 * math.pi * freq * t) * 0.15) *
          attack *
          decay;

      final int16Val = (sample.clamp(-1.0, 1.0) * 32767).toInt();
      byteData.setInt16(i * 2, int16Val, Endian.little);
    }

    final header = buildWavHeader(
      totalAudioLen: pcmBytes.length,
      sampleRate: sampleRate,
      channels: 1,
      bitsPerSample: 16,
    );

    final wav = Uint8List(header.length + pcmBytes.length);
    wav.setRange(0, header.length, header);
    wav.setRange(header.length, wav.length, pcmBytes);
    return wav;
  }

  /// Builds a standard 44-byte RIFF/WAVE header for mono 16-bit PCM audio.
  static Uint8List buildWavHeader({
    required int totalAudioLen,
    required int sampleRate,
    required int channels,
    required int bitsPerSample,
  }) {
    final byteRate = (sampleRate * channels * bitsPerSample) ~/ 8;
    final totalDataLen = totalAudioLen + 36;
    final blockAlign = (channels * bitsPerSample) ~/ 8;

    final header = Uint8List(44);
    final byteData = ByteData.sublistView(header);

    header.setRange(0, 4, [0x52, 0x49, 0x46, 0x46]); // 'RIFF'
    byteData.setUint32(4, totalDataLen, Endian.little);
    header.setRange(8, 12, [0x57, 0x41, 0x56, 0x45]); // 'WAVE'
    header.setRange(12, 16, [0x66, 0x6d, 0x74, 0x20]); // 'fmt '
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little); // PCM = 1
    byteData.setUint16(22, channels, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, byteRate, Endian.little);
    byteData.setUint16(32, blockAlign, Endian.little);
    byteData.setUint16(34, bitsPerSample, Endian.little);
    header.setRange(36, 40, [0x64, 0x61, 0x74, 0x61]); // 'data'
    byteData.setUint32(40, totalAudioLen, Endian.little);

    return header;
  }
}

/// Coordinates note playback with audio buffering and caching.
class AudioSynthesizer {
  AudioSynthesizer({AudioTonePlayer? player})
    : _player = player ?? FlutterSoundTonePlayer();

  final AudioTonePlayer _player;
  final Map<int, Uint8List> _cachedTones = {};
  bool _isMuted = false;

  bool get isMuted => _isMuted;
  set isMuted(bool value) {
    _isMuted = value;
    if (value) {
      stop();
    }
  }

  Future<void> open() => _player.open();

  Future<void> playNote({
    required int midiNote,
    double durationSeconds = 0.5,
  }) async {
    if (_isMuted) return;

    final cacheKey = (midiNote << 8) | (durationSeconds * 10).toInt();
    final wav = _cachedTones.putIfAbsent(
      cacheKey,
      () => ToneGenerator.generatePianoToneWav(
        midiNote: midiNote,
        durationSeconds: durationSeconds,
      ),
    );

    await _player.playWav(wav);
  }

  Future<void> stop() => _player.stop();

  Future<void> dispose() => _player.close();
}

final audioSynthesizerProvider = Provider<AudioSynthesizer>((ref) {
  final synth = AudioSynthesizer();
  ref.onDispose(synth.dispose);
  return synth;
});
