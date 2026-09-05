import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/audio_models.dart';
import 'pitch_detector.dart';

class AudioEngine {
  final PitchDetector _pitchDetector;
  StreamSubscription<PitchEvent>? _pitchSubscription;
  final StreamController<PitchEvent> _pitchController =
      StreamController<PitchEvent>.broadcast();

  Stream<PitchEvent> get pitchStream => _pitchController.stream;
  bool get isRunning => _pitchDetector.isRunning;
  Future<void> _lifecycle = Future<void>.value();
  bool _disposed = false;

  AudioEngine({final AudioEngineConfig? config})
      : _pitchDetector = PitchDetector(config: config);

  Future<bool> initialize() async {
    final PermissionStatus status = await Permission.microphone.request();
    if (!status.isGranted) {
      debugPrint('AudioEngine: Microphone permission denied');
      return false;
    }

    debugPrint('AudioEngine: Microphone permission granted');
    return true;
  }

  Future<void> start() async {
    await _enqueueLifecycle(() async {
      if (_disposed || _pitchDetector.isRunning) return;
      await _pitchDetector.start();
      _pitchSubscription = _pitchDetector.pitchStream.listen(
        _pitchController.add,
        onError: (final Object error, final StackTrace stackTrace) {
          debugPrint('AudioEngine: Pitch stream error: $error');
          _pitchController.addError(error, stackTrace);
        },
      );
      debugPrint('AudioEngine: Started');
    });
  }

  Future<void> stop() async {
    await _enqueueLifecycle(() async {
      await _pitchSubscription?.cancel();
      _pitchSubscription = null;
      await _pitchDetector.stop();
      debugPrint('AudioEngine: Stopped');
    });
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _enqueueLifecycle(() async {
      await _pitchSubscription?.cancel();
      _pitchSubscription = null;
      await _pitchDetector.stop();
    });
    await _pitchController.close();
    await _pitchDetector.dispose();
  }

  Future<void> _enqueueLifecycle(Future<void> Function() operation) {
    final next = _lifecycle.then((_) => operation());
    _lifecycle = next.catchError((_) {});
    return next;
  }
}
