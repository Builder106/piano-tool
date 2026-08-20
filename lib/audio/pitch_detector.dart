import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:piano_tool/models/audio_models.dart';

class PitchDetector {
  final AudioEngineConfig config;
  final _pitchController = StreamController<PitchEvent>.broadcast();
  bool _isRunning = false;
  FlutterSoundRecorder? _recorder;
  StreamController<Uint8List>? _recordingDataController;
  StreamSubscription? _recordingSubscription;
  final List<int> _sampleBuffer = [];

  Stream<PitchEvent> get pitchStream => _pitchController.stream;
  bool get isRunning => _isRunning;

  PitchDetector({AudioEngineConfig? config}) : config = config ?? const AudioEngineConfig();

  Future<void> start() async {
    if (_isRunning) return;

    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();

    _sampleBuffer.clear();
    _recordingDataController = StreamController<Uint8List>();

    _recordingSubscription = _recordingDataController!.stream.listen((bytes) {
      _handleIncomingPcmBytes(bytes);
    });

    await _recorder!.startRecorder(
      toStream: _recordingDataController!.sink,
      codec: Codec.pcm16,
      sampleRate: config.sampleRate,
      numChannels: 1,
    );

    _isRunning = true;
    debugPrint('PitchDetector: Started audio streaming at ${config.sampleRate}Hz');
  }

  void _handleIncomingPcmBytes(Uint8List bytes) {
    if (!_isRunning || bytes.isEmpty) return;

    try {
      final byteData = ByteData.sublistView(bytes);
      final sampleCount = bytes.length ~/ 2;
      for (int i = 0; i < sampleCount; i++) {
        _sampleBuffer.add(byteData.getInt16(i * 2, Endian.little));
      }

      final bufferSize = config.bufferSize;
      final hopSize = bufferSize ~/ 2;

      while (_sampleBuffer.length >= bufferSize) {
        final chunk = _sampleBuffer.sublist(0, bufferSize);
        final event = processBuffer(chunk);
        if (event != null) {
          _pitchController.add(event);
        }
        if (_sampleBuffer.length >= hopSize) {
          _sampleBuffer.removeRange(0, hopSize);
        } else {
          _sampleBuffer.clear();
        }
      }
    } catch (e) {
      debugPrint('PitchDetector: Error processing audio chunk: $e');
    }
  }

  Future<void> stop() async {
    if (!_isRunning) return;

    await _recordingSubscription?.cancel();
    _recordingSubscription = null;
    await _recordingDataController?.close();
    _recordingDataController = null;
    _sampleBuffer.clear();

    await _recorder?.stopRecorder();
    await _recorder?.closeRecorder();
    _recorder = null;
    _isRunning = false;
    debugPrint('PitchDetector: Stopped');
  }

  /// Process raw PCM buffer for pitch detection using YIN algorithm
  PitchEvent? processBuffer(List<int> buffer) {
    if (buffer.length < config.bufferSize) return null;

    final samples = buffer
        .take(config.bufferSize)
        .map((v) => v / 32768.0)
        .toList();

    final rms = math.sqrt(samples.map((s) => s * s).reduce((a, b) => a + b) / samples.length);

    if (rms < 0.01) return null;

    final frequency = _yin(samples, config.sampleRate);

    if (frequency == null || frequency < 80.0 || frequency > 1000.0) {
      return null;
    }

    final confidence = _calculateConfidence(samples, frequency, config.sampleRate);

    if (confidence < config.minConfidenceThreshold) return null;

    // Convert frequency to MIDI note
    final midiNote = (69 + 12 * math.log(frequency / 440.0) / math.ln2).round();

    return PitchEvent(
      frequency: frequency,
      confidence: confidence,
      midiNote: midiNote,
      timestamp: DateTime.now().millisecondsSinceEpoch / 1000.0,
      volume: rms,
    );
  }

  static double? _yin(List<double> signal, int sampleRate) {
    final bufferSize = signal.length;
    final halfSize = bufferSize ~/ 2;
    final tauMax = halfSize;

    final difference = List<double>.filled(tauMax, 0.0);
    for (int tau = 1; tau < tauMax; tau++) {
      double sum = 0.0;
      for (int i = 0; i < halfSize; i++) {
        final delta = signal[i] - signal[i + tau];
        sum += delta * delta;
      }
      difference[tau] = sum;
    }

    final cmnd = List<double>.filled(tauMax, 1.0);
    double runningSum = 0.0;
    for (int tau = 1; tau < tauMax; tau++) {
      runningSum += difference[tau];
      cmnd[tau] = difference[tau] * tau / runningSum;
    }

    const threshold = 0.1;
    int tau = 1;
    while (tau < tauMax) {
      if (cmnd[tau] < threshold) {
        while (tau + 1 < tauMax && cmnd[tau + 1] < cmnd[tau]) {
          tau++;
        }
        break;
      }
      tau++;
    }

    if (tau >= tauMax) return null;

    double betterTau;
    if (tau > 0 && tau < tauMax - 1) {
      final alpha = cmnd[tau - 1];
      final beta = cmnd[tau];
      final gamma = cmnd[tau + 1];
      final p = (alpha - gamma) / (2 * (alpha - 2 * beta + gamma));
      betterTau = tau + p;
    } else {
      betterTau = tau.toDouble();
    }

    if (betterTau <= 0) return null;

    return sampleRate / betterTau;
  }

  static double _calculateConfidence(List<double> signal, double frequency, int sampleRate) {
    final period = sampleRate / frequency;
    if (period < 2 || period > signal.length / 2) return 0.0;

    int tau = period.round();
    double sum = 0.0;
    double sumSq = 0.0;

    for (int i = 0; i + tau < signal.length; i++) {
      sum += signal[i] * signal[i + tau];
      sumSq += signal[i] * signal[i];
    }

    if (sumSq == 0) return 0.0;
    return (sum / sumSq).clamp(0.0, 1.0);
  }

  void dispose() {
    stop();
    _pitchController.close();
  }
}