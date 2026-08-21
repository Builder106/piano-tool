import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_models.freezed.dart';
part 'audio_models.g.dart';

/// Pitch detection event from the audio engine
@freezed
sealed class PitchEvent with _$PitchEvent {
  const factory PitchEvent({
    required double frequency, // Hz
    required double confidence, // 0.0 - 1.0
    required int midiNote, // MIDI note number (60 = middle C)
    required double timestamp, // seconds since engine start
    required double volume, // RMS volume 0.0 - 1.0
  }) = _PitchEvent;

  factory PitchEvent.fromJson(Map<String, dynamic> json) =>
      _$PitchEventFromJson(json);
}

/// Audio engine configuration
@freezed
sealed class AudioEngineConfig with _$AudioEngineConfig {
  const factory AudioEngineConfig({
    @Default(44100) int sampleRate,
    @Default(2048) int bufferSize,
    @Default(0.1)
    double minVolumeThreshold, // minimum volume to consider as note
    @Default(0.7)
    double minConfidenceThreshold, // minimum confidence for pitch detection
    @Default(440.0) double referenceFrequency, // A4 reference
  }) = _AudioEngineConfig;

  factory AudioEngineConfig.fromJson(Map<String, dynamic> json) =>
      _$AudioEngineConfigFromJson(json);
}

/// Audio engine state
enum AudioEngineState {
  uninitialized,
  initializing,
  ready,
  listening,
  paused,
  stopped,
  error,
}

/// Audio engine status event
@freezed
sealed class AudioEngineStatus with _$AudioEngineStatus {
  const factory AudioEngineStatus({
    required AudioEngineState state,
    String? errorMessage,
    @Default(0.0) double currentVolume,
    @Default(0.0) double currentPitch,
    @Default(0) int currentMidiNote,
  }) = _AudioEngineStatus;

  factory AudioEngineStatus.fromJson(Map<String, dynamic> json) =>
      _$AudioEngineStatusFromJson(json);
}

/// Result of a pitch detection attempt
@freezed
sealed class PitchDetectionResult with _$PitchDetectionResult {
  const PitchDetectionResult._();

  const factory PitchDetectionResult.success({
    required double frequency,
    required double confidence,
    required int midiNote,
    required double volume,
  }) = _PitchDetectionResultSuccess;

  const factory PitchDetectionResult.failure({
    required String reason,
    @Default(0.0) double volume,
  }) = _PitchDetectionResultFailure;

  factory PitchDetectionResult.fromJson(Map<String, dynamic> json) =>
      _$PitchDetectionResultFromJson(json);

  bool get isSuccess => switch (this) {
        _PitchDetectionResultSuccess() => true,
        _PitchDetectionResultFailure() => false,
      };
}
