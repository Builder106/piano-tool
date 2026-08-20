// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PitchEventImpl _$$PitchEventImplFromJson(Map<String, dynamic> json) =>
    _$PitchEventImpl(
      frequency: (json['frequency'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      midiNote: (json['midiNote'] as num).toInt(),
      timestamp: (json['timestamp'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
    );

Map<String, dynamic> _$$PitchEventImplToJson(_$PitchEventImpl instance) =>
    <String, dynamic>{
      'frequency': instance.frequency,
      'confidence': instance.confidence,
      'midiNote': instance.midiNote,
      'timestamp': instance.timestamp,
      'volume': instance.volume,
    };

_$AudioEngineConfigImpl _$$AudioEngineConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$AudioEngineConfigImpl(
      sampleRate: (json['sampleRate'] as num?)?.toInt() ?? 44100,
      bufferSize: (json['bufferSize'] as num?)?.toInt() ?? 2048,
      minVolumeThreshold:
          (json['minVolumeThreshold'] as num?)?.toDouble() ?? 0.1,
      minConfidenceThreshold:
          (json['minConfidenceThreshold'] as num?)?.toDouble() ?? 0.7,
      referenceFrequency:
          (json['referenceFrequency'] as num?)?.toDouble() ?? 440.0,
    );

Map<String, dynamic> _$$AudioEngineConfigImplToJson(
        _$AudioEngineConfigImpl instance) =>
    <String, dynamic>{
      'sampleRate': instance.sampleRate,
      'bufferSize': instance.bufferSize,
      'minVolumeThreshold': instance.minVolumeThreshold,
      'minConfidenceThreshold': instance.minConfidenceThreshold,
      'referenceFrequency': instance.referenceFrequency,
    };

_$AudioEngineStatusImpl _$$AudioEngineStatusImplFromJson(
        Map<String, dynamic> json) =>
    _$AudioEngineStatusImpl(
      state: $enumDecode(_$AudioEngineStateEnumMap, json['state']),
      errorMessage: json['errorMessage'] as String?,
      currentVolume: (json['currentVolume'] as num?)?.toDouble() ?? 0.0,
      currentPitch: (json['currentPitch'] as num?)?.toDouble() ?? 0.0,
      currentMidiNote: (json['currentMidiNote'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$AudioEngineStatusImplToJson(
        _$AudioEngineStatusImpl instance) =>
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

_$PitchDetectionResultSuccessImpl _$$PitchDetectionResultSuccessImplFromJson(
        Map<String, dynamic> json) =>
    _$PitchDetectionResultSuccessImpl(
      frequency: (json['frequency'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      midiNote: (json['midiNote'] as num).toInt(),
      volume: (json['volume'] as num).toDouble(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$PitchDetectionResultSuccessImplToJson(
        _$PitchDetectionResultSuccessImpl instance) =>
    <String, dynamic>{
      'frequency': instance.frequency,
      'confidence': instance.confidence,
      'midiNote': instance.midiNote,
      'volume': instance.volume,
      'runtimeType': instance.$type,
    };

_$PitchDetectionResultFailureImpl _$$PitchDetectionResultFailureImplFromJson(
        Map<String, dynamic> json) =>
    _$PitchDetectionResultFailureImpl(
      reason: json['reason'] as String,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.0,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$PitchDetectionResultFailureImplToJson(
        _$PitchDetectionResultFailureImpl instance) =>
    <String, dynamic>{
      'reason': instance.reason,
      'volume': instance.volume,
      'runtimeType': instance.$type,
    };
