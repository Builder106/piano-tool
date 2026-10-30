// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PitchEvent _$PitchEventFromJson(Map<String, dynamic> json) => _PitchEvent(
  frequency: (json['frequency'] as num).toDouble(),
  confidence: (json['confidence'] as num).toDouble(),
  midiNote: (json['midiNote'] as num).toInt(),
  timestamp: (json['timestamp'] as num).toDouble(),
  volume: (json['volume'] as num).toDouble(),
  struck: json['struck'] as bool? ?? false,
);

Map<String, dynamic> _$PitchEventToJson(_PitchEvent instance) =>
    <String, dynamic>{
      'frequency': instance.frequency,
      'confidence': instance.confidence,
      'midiNote': instance.midiNote,
      'timestamp': instance.timestamp,
      'volume': instance.volume,
      'struck': instance.struck,
    };

_AudioEngineConfig _$AudioEngineConfigFromJson(
  Map<String, dynamic> json,
) => _AudioEngineConfig(
  sampleRate: (json['sampleRate'] as num?)?.toInt() ?? 44100,
  bufferSize: (json['bufferSize'] as num?)?.toInt() ?? 2048,
  minVolumeThreshold: (json['minVolumeThreshold'] as num?)?.toDouble() ?? 0.1,
  minConfidenceThreshold:
      (json['minConfidenceThreshold'] as num?)?.toDouble() ?? 0.7,
  referenceFrequency: (json['referenceFrequency'] as num?)?.toDouble() ?? 440.0,
);

Map<String, dynamic> _$AudioEngineConfigToJson(_AudioEngineConfig instance) =>
    <String, dynamic>{
      'sampleRate': instance.sampleRate,
      'bufferSize': instance.bufferSize,
      'minVolumeThreshold': instance.minVolumeThreshold,
      'minConfidenceThreshold': instance.minConfidenceThreshold,
      'referenceFrequency': instance.referenceFrequency,
    };

_AudioEngineStatus _$AudioEngineStatusFromJson(Map<String, dynamic> json) =>
    _AudioEngineStatus(
      state: $enumDecode(_$AudioEngineStateEnumMap, json['state']),
      errorMessage: json['errorMessage'] as String?,
      currentVolume: (json['currentVolume'] as num?)?.toDouble() ?? 0.0,
      currentPitch: (json['currentPitch'] as num?)?.toDouble() ?? 0.0,
      currentMidiNote: (json['currentMidiNote'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$AudioEngineStatusToJson(_AudioEngineStatus instance) =>
    <String, dynamic>{
      'state': _$AudioEngineStateEnumMap[instance.state]!,
      'errorMessage': instance.errorMessage,
      'currentVolume': instance.currentVolume,
      'currentPitch': instance.currentPitch,
      'currentMidiNote': instance.currentMidiNote,
    };

const _$AudioEngineStateEnumMap = {
  AudioEngineState.uninitialized: 'uninitialized',
  AudioEngineState.initializing: 'initializing',
  AudioEngineState.ready: 'ready',
  AudioEngineState.listening: 'listening',
  AudioEngineState.paused: 'paused',
  AudioEngineState.stopped: 'stopped',
  AudioEngineState.error: 'error',
};

_PitchDetectionResultSuccess _$PitchDetectionResultSuccessFromJson(
  Map<String, dynamic> json,
) => _PitchDetectionResultSuccess(
  frequency: (json['frequency'] as num).toDouble(),
  confidence: (json['confidence'] as num).toDouble(),
  midiNote: (json['midiNote'] as num).toInt(),
  volume: (json['volume'] as num).toDouble(),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$PitchDetectionResultSuccessToJson(
  _PitchDetectionResultSuccess instance,
) => <String, dynamic>{
  'frequency': instance.frequency,
  'confidence': instance.confidence,
  'midiNote': instance.midiNote,
  'volume': instance.volume,
  'runtimeType': instance.$type,
};

_PitchDetectionResultFailure _$PitchDetectionResultFailureFromJson(
  Map<String, dynamic> json,
) => _PitchDetectionResultFailure(
  reason: json['reason'] as String,
  volume: (json['volume'] as num?)?.toDouble() ?? 0.0,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$PitchDetectionResultFailureToJson(
  _PitchDetectionResultFailure instance,
) => <String, dynamic>{
  'reason': instance.reason,
  'volume': instance.volume,
  'runtimeType': instance.$type,
};
