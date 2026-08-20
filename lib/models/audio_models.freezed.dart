// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audio_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PitchEvent _$PitchEventFromJson(Map<String, dynamic> json) {
  return _PitchEvent.fromJson(json);
}

/// @nodoc
mixin _$PitchEvent {
  double get frequency => throw _privateConstructorUsedError; // Hz
  double get confidence => throw _privateConstructorUsedError; // 0.0 - 1.0
  int get midiNote =>
      throw _privateConstructorUsedError; // MIDI note number (60 = middle C)
  double get timestamp =>
      throw _privateConstructorUsedError; // seconds since engine start
  double get volume => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PitchEventCopyWith<PitchEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PitchEventCopyWith<$Res> {
  factory $PitchEventCopyWith(
          PitchEvent value, $Res Function(PitchEvent) then) =
      _$PitchEventCopyWithImpl<$Res, PitchEvent>;
  @useResult
  $Res call(
      {double frequency,
      double confidence,
      int midiNote,
      double timestamp,
      double volume});
}

/// @nodoc
class _$PitchEventCopyWithImpl<$Res, $Val extends PitchEvent>
    implements $PitchEventCopyWith<$Res> {
  _$PitchEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frequency = null,
    Object? confidence = null,
    Object? midiNote = null,
    Object? timestamp = null,
    Object? volume = null,
  }) {
    return _then(_value.copyWith(
      frequency: null == frequency
          ? _value.frequency
          : frequency // ignore: cast_nullable_to_non_nullable
              as double,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      midiNote: null == midiNote
          ? _value.midiNote
          : midiNote // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as double,
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PitchEventImplCopyWith<$Res>
    implements $PitchEventCopyWith<$Res> {
  factory _$$PitchEventImplCopyWith(
          _$PitchEventImpl value, $Res Function(_$PitchEventImpl) then) =
      __$$PitchEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double frequency,
      double confidence,
      int midiNote,
      double timestamp,
      double volume});
}

/// @nodoc
class __$$PitchEventImplCopyWithImpl<$Res>
    extends _$PitchEventCopyWithImpl<$Res, _$PitchEventImpl>
    implements _$$PitchEventImplCopyWith<$Res> {
  __$$PitchEventImplCopyWithImpl(
      _$PitchEventImpl _value, $Res Function(_$PitchEventImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frequency = null,
    Object? confidence = null,
    Object? midiNote = null,
    Object? timestamp = null,
    Object? volume = null,
  }) {
    return _then(_$PitchEventImpl(
      frequency: null == frequency
          ? _value.frequency
          : frequency // ignore: cast_nullable_to_non_nullable
              as double,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      midiNote: null == midiNote
          ? _value.midiNote
          : midiNote // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as double,
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PitchEventImpl implements _PitchEvent {
  const _$PitchEventImpl(
      {required this.frequency,
      required this.confidence,
      required this.midiNote,
      required this.timestamp,
      required this.volume});

  factory _$PitchEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$PitchEventImplFromJson(json);

  @override
  final double frequency;
// Hz
  @override
  final double confidence;
// 0.0 - 1.0
  @override
  final int midiNote;
// MIDI note number (60 = middle C)
  @override
  final double timestamp;
// seconds since engine start
  @override
  final double volume;

  @override
  String toString() {
    return 'PitchEvent(frequency: $frequency, confidence: $confidence, midiNote: $midiNote, timestamp: $timestamp, volume: $volume)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PitchEventImpl &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.midiNote, midiNote) ||
                other.midiNote == midiNote) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.volume, volume) || other.volume == volume));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, frequency, confidence, midiNote, timestamp, volume);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PitchEventImplCopyWith<_$PitchEventImpl> get copyWith =>
      __$$PitchEventImplCopyWithImpl<_$PitchEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PitchEventImplToJson(
      this,
    );
  }
}

abstract class _PitchEvent implements PitchEvent {
  const factory _PitchEvent(
      {required final double frequency,
      required final double confidence,
      required final int midiNote,
      required final double timestamp,
      required final double volume}) = _$PitchEventImpl;

  factory _PitchEvent.fromJson(Map<String, dynamic> json) =
      _$PitchEventImpl.fromJson;

  @override
  double get frequency;
  @override // Hz
  double get confidence;
  @override // 0.0 - 1.0
  int get midiNote;
  @override // MIDI note number (60 = middle C)
  double get timestamp;
  @override // seconds since engine start
  double get volume;
  @override
  @JsonKey(ignore: true)
  _$$PitchEventImplCopyWith<_$PitchEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AudioEngineConfig _$AudioEngineConfigFromJson(Map<String, dynamic> json) {
  return _AudioEngineConfig.fromJson(json);
}

/// @nodoc
mixin _$AudioEngineConfig {
  int get sampleRate => throw _privateConstructorUsedError;
  int get bufferSize => throw _privateConstructorUsedError;
  double get minVolumeThreshold =>
      throw _privateConstructorUsedError; // minimum volume to consider as note
  double get minConfidenceThreshold =>
      throw _privateConstructorUsedError; // minimum confidence for pitch detection
  double get referenceFrequency => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AudioEngineConfigCopyWith<AudioEngineConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AudioEngineConfigCopyWith<$Res> {
  factory $AudioEngineConfigCopyWith(
          AudioEngineConfig value, $Res Function(AudioEngineConfig) then) =
      _$AudioEngineConfigCopyWithImpl<$Res, AudioEngineConfig>;
  @useResult
  $Res call(
      {int sampleRate,
      int bufferSize,
      double minVolumeThreshold,
      double minConfidenceThreshold,
      double referenceFrequency});
}

/// @nodoc
class _$AudioEngineConfigCopyWithImpl<$Res, $Val extends AudioEngineConfig>
    implements $AudioEngineConfigCopyWith<$Res> {
  _$AudioEngineConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sampleRate = null,
    Object? bufferSize = null,
    Object? minVolumeThreshold = null,
    Object? minConfidenceThreshold = null,
    Object? referenceFrequency = null,
  }) {
    return _then(_value.copyWith(
      sampleRate: null == sampleRate
          ? _value.sampleRate
          : sampleRate // ignore: cast_nullable_to_non_nullable
              as int,
      bufferSize: null == bufferSize
          ? _value.bufferSize
          : bufferSize // ignore: cast_nullable_to_non_nullable
              as int,
      minVolumeThreshold: null == minVolumeThreshold
          ? _value.minVolumeThreshold
          : minVolumeThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      minConfidenceThreshold: null == minConfidenceThreshold
          ? _value.minConfidenceThreshold
          : minConfidenceThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      referenceFrequency: null == referenceFrequency
          ? _value.referenceFrequency
          : referenceFrequency // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AudioEngineConfigImplCopyWith<$Res>
    implements $AudioEngineConfigCopyWith<$Res> {
  factory _$$AudioEngineConfigImplCopyWith(_$AudioEngineConfigImpl value,
          $Res Function(_$AudioEngineConfigImpl) then) =
      __$$AudioEngineConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int sampleRate,
      int bufferSize,
      double minVolumeThreshold,
      double minConfidenceThreshold,
      double referenceFrequency});
}

/// @nodoc
class __$$AudioEngineConfigImplCopyWithImpl<$Res>
    extends _$AudioEngineConfigCopyWithImpl<$Res, _$AudioEngineConfigImpl>
    implements _$$AudioEngineConfigImplCopyWith<$Res> {
  __$$AudioEngineConfigImplCopyWithImpl(_$AudioEngineConfigImpl _value,
      $Res Function(_$AudioEngineConfigImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sampleRate = null,
    Object? bufferSize = null,
    Object? minVolumeThreshold = null,
    Object? minConfidenceThreshold = null,
    Object? referenceFrequency = null,
  }) {
    return _then(_$AudioEngineConfigImpl(
      sampleRate: null == sampleRate
          ? _value.sampleRate
          : sampleRate // ignore: cast_nullable_to_non_nullable
              as int,
      bufferSize: null == bufferSize
          ? _value.bufferSize
          : bufferSize // ignore: cast_nullable_to_non_nullable
              as int,
      minVolumeThreshold: null == minVolumeThreshold
          ? _value.minVolumeThreshold
          : minVolumeThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      minConfidenceThreshold: null == minConfidenceThreshold
          ? _value.minConfidenceThreshold
          : minConfidenceThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      referenceFrequency: null == referenceFrequency
          ? _value.referenceFrequency
          : referenceFrequency // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AudioEngineConfigImpl implements _AudioEngineConfig {
  const _$AudioEngineConfigImpl(
      {this.sampleRate = 44100,
      this.bufferSize = 2048,
      this.minVolumeThreshold = 0.1,
      this.minConfidenceThreshold = 0.7,
      this.referenceFrequency = 440.0});

  factory _$AudioEngineConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$AudioEngineConfigImplFromJson(json);

  @override
  @JsonKey()
  final int sampleRate;
  @override
  @JsonKey()
  final int bufferSize;
  @override
  @JsonKey()
  final double minVolumeThreshold;
// minimum volume to consider as note
  @override
  @JsonKey()
  final double minConfidenceThreshold;
// minimum confidence for pitch detection
  @override
  @JsonKey()
  final double referenceFrequency;

  @override
  String toString() {
    return 'AudioEngineConfig(sampleRate: $sampleRate, bufferSize: $bufferSize, minVolumeThreshold: $minVolumeThreshold, minConfidenceThreshold: $minConfidenceThreshold, referenceFrequency: $referenceFrequency)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AudioEngineConfigImpl &&
            (identical(other.sampleRate, sampleRate) ||
                other.sampleRate == sampleRate) &&
            (identical(other.bufferSize, bufferSize) ||
                other.bufferSize == bufferSize) &&
            (identical(other.minVolumeThreshold, minVolumeThreshold) ||
                other.minVolumeThreshold == minVolumeThreshold) &&
            (identical(other.minConfidenceThreshold, minConfidenceThreshold) ||
                other.minConfidenceThreshold == minConfidenceThreshold) &&
            (identical(other.referenceFrequency, referenceFrequency) ||
                other.referenceFrequency == referenceFrequency));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, sampleRate, bufferSize,
      minVolumeThreshold, minConfidenceThreshold, referenceFrequency);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AudioEngineConfigImplCopyWith<_$AudioEngineConfigImpl> get copyWith =>
      __$$AudioEngineConfigImplCopyWithImpl<_$AudioEngineConfigImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AudioEngineConfigImplToJson(
      this,
    );
  }
}

abstract class _AudioEngineConfig implements AudioEngineConfig {
  const factory _AudioEngineConfig(
      {final int sampleRate,
      final int bufferSize,
      final double minVolumeThreshold,
      final double minConfidenceThreshold,
      final double referenceFrequency}) = _$AudioEngineConfigImpl;

  factory _AudioEngineConfig.fromJson(Map<String, dynamic> json) =
      _$AudioEngineConfigImpl.fromJson;

  @override
  int get sampleRate;
  @override
  int get bufferSize;
  @override
  double get minVolumeThreshold;
  @override // minimum volume to consider as note
  double get minConfidenceThreshold;
  @override // minimum confidence for pitch detection
  double get referenceFrequency;
  @override
  @JsonKey(ignore: true)
  _$$AudioEngineConfigImplCopyWith<_$AudioEngineConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AudioEngineStatus _$AudioEngineStatusFromJson(Map<String, dynamic> json) {
  return _AudioEngineStatus.fromJson(json);
}

/// @nodoc
mixin _$AudioEngineStatus {
  AudioEngineState get state => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  double get currentVolume => throw _privateConstructorUsedError;
  double get currentPitch => throw _privateConstructorUsedError;
  int get currentMidiNote => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AudioEngineStatusCopyWith<AudioEngineStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AudioEngineStatusCopyWith<$Res> {
  factory $AudioEngineStatusCopyWith(
          AudioEngineStatus value, $Res Function(AudioEngineStatus) then) =
      _$AudioEngineStatusCopyWithImpl<$Res, AudioEngineStatus>;
  @useResult
  $Res call(
      {AudioEngineState state,
      String? errorMessage,
      double currentVolume,
      double currentPitch,
      int currentMidiNote});
}

/// @nodoc
class _$AudioEngineStatusCopyWithImpl<$Res, $Val extends AudioEngineStatus>
    implements $AudioEngineStatusCopyWith<$Res> {
  _$AudioEngineStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? state = null,
    Object? errorMessage = freezed,
    Object? currentVolume = null,
    Object? currentPitch = null,
    Object? currentMidiNote = null,
  }) {
    return _then(_value.copyWith(
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as AudioEngineState,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      currentVolume: null == currentVolume
          ? _value.currentVolume
          : currentVolume // ignore: cast_nullable_to_non_nullable
              as double,
      currentPitch: null == currentPitch
          ? _value.currentPitch
          : currentPitch // ignore: cast_nullable_to_non_nullable
              as double,
      currentMidiNote: null == currentMidiNote
          ? _value.currentMidiNote
          : currentMidiNote // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AudioEngineStatusImplCopyWith<$Res>
    implements $AudioEngineStatusCopyWith<$Res> {
  factory _$$AudioEngineStatusImplCopyWith(_$AudioEngineStatusImpl value,
          $Res Function(_$AudioEngineStatusImpl) then) =
      __$$AudioEngineStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {AudioEngineState state,
      String? errorMessage,
      double currentVolume,
      double currentPitch,
      int currentMidiNote});
}

/// @nodoc
class __$$AudioEngineStatusImplCopyWithImpl<$Res>
    extends _$AudioEngineStatusCopyWithImpl<$Res, _$AudioEngineStatusImpl>
    implements _$$AudioEngineStatusImplCopyWith<$Res> {
  __$$AudioEngineStatusImplCopyWithImpl(_$AudioEngineStatusImpl _value,
      $Res Function(_$AudioEngineStatusImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? state = null,
    Object? errorMessage = freezed,
    Object? currentVolume = null,
    Object? currentPitch = null,
    Object? currentMidiNote = null,
  }) {
    return _then(_$AudioEngineStatusImpl(
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as AudioEngineState,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      currentVolume: null == currentVolume
          ? _value.currentVolume
          : currentVolume // ignore: cast_nullable_to_non_nullable
              as double,
      currentPitch: null == currentPitch
          ? _value.currentPitch
          : currentPitch // ignore: cast_nullable_to_non_nullable
              as double,
      currentMidiNote: null == currentMidiNote
          ? _value.currentMidiNote
          : currentMidiNote // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AudioEngineStatusImpl implements _AudioEngineStatus {
  const _$AudioEngineStatusImpl(
      {required this.state,
      this.errorMessage,
      this.currentVolume = 0.0,
      this.currentPitch = 0.0,
      this.currentMidiNote = 0});

  factory _$AudioEngineStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$AudioEngineStatusImplFromJson(json);

  @override
  final AudioEngineState state;
  @override
  final String? errorMessage;
  @override
  @JsonKey()
  final double currentVolume;
  @override
  @JsonKey()
  final double currentPitch;
  @override
  @JsonKey()
  final int currentMidiNote;

  @override
  String toString() {
    return 'AudioEngineStatus(state: $state, errorMessage: $errorMessage, currentVolume: $currentVolume, currentPitch: $currentPitch, currentMidiNote: $currentMidiNote)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AudioEngineStatusImpl &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.currentVolume, currentVolume) ||
                other.currentVolume == currentVolume) &&
            (identical(other.currentPitch, currentPitch) ||
                other.currentPitch == currentPitch) &&
            (identical(other.currentMidiNote, currentMidiNote) ||
                other.currentMidiNote == currentMidiNote));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, state, errorMessage,
      currentVolume, currentPitch, currentMidiNote);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AudioEngineStatusImplCopyWith<_$AudioEngineStatusImpl> get copyWith =>
      __$$AudioEngineStatusImplCopyWithImpl<_$AudioEngineStatusImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AudioEngineStatusImplToJson(
      this,
    );
  }
}

abstract class _AudioEngineStatus implements AudioEngineStatus {
  const factory _AudioEngineStatus(
      {required final AudioEngineState state,
      final String? errorMessage,
      final double currentVolume,
      final double currentPitch,
      final int currentMidiNote}) = _$AudioEngineStatusImpl;

  factory _AudioEngineStatus.fromJson(Map<String, dynamic> json) =
      _$AudioEngineStatusImpl.fromJson;

  @override
  AudioEngineState get state;
  @override
  String? get errorMessage;
  @override
  double get currentVolume;
  @override
  double get currentPitch;
  @override
  int get currentMidiNote;
  @override
  @JsonKey(ignore: true)
  _$$AudioEngineStatusImplCopyWith<_$AudioEngineStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PitchDetectionResult _$PitchDetectionResultFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'success':
      return _PitchDetectionResultSuccess.fromJson(json);
    case 'failure':
      return _PitchDetectionResultFailure.fromJson(json);

    default:
      throw CheckedFromJsonException(
          json,
          'runtimeType',
          'PitchDetectionResult',
          'Invalid union type "${json['runtimeType']}"!');
  }
}

/// @nodoc
mixin _$PitchDetectionResult {
  double get volume => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            double frequency, double confidence, int midiNote, double volume)
        success,
    required TResult Function(String reason, double volume) failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            double frequency, double confidence, int midiNote, double volume)?
        success,
    TResult? Function(String reason, double volume)? failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            double frequency, double confidence, int midiNote, double volume)?
        success,
    TResult Function(String reason, double volume)? failure,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_PitchDetectionResultSuccess value) success,
    required TResult Function(_PitchDetectionResultFailure value) failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_PitchDetectionResultSuccess value)? success,
    TResult? Function(_PitchDetectionResultFailure value)? failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_PitchDetectionResultSuccess value)? success,
    TResult Function(_PitchDetectionResultFailure value)? failure,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PitchDetectionResultCopyWith<PitchDetectionResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PitchDetectionResultCopyWith<$Res> {
  factory $PitchDetectionResultCopyWith(PitchDetectionResult value,
          $Res Function(PitchDetectionResult) then) =
      _$PitchDetectionResultCopyWithImpl<$Res, PitchDetectionResult>;
  @useResult
  $Res call({double volume});
}

/// @nodoc
class _$PitchDetectionResultCopyWithImpl<$Res,
        $Val extends PitchDetectionResult>
    implements $PitchDetectionResultCopyWith<$Res> {
  _$PitchDetectionResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? volume = null,
  }) {
    return _then(_value.copyWith(
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PitchDetectionResultSuccessImplCopyWith<$Res>
    implements $PitchDetectionResultCopyWith<$Res> {
  factory _$$PitchDetectionResultSuccessImplCopyWith(
          _$PitchDetectionResultSuccessImpl value,
          $Res Function(_$PitchDetectionResultSuccessImpl) then) =
      __$$PitchDetectionResultSuccessImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double frequency, double confidence, int midiNote, double volume});
}

/// @nodoc
class __$$PitchDetectionResultSuccessImplCopyWithImpl<$Res>
    extends _$PitchDetectionResultCopyWithImpl<$Res,
        _$PitchDetectionResultSuccessImpl>
    implements _$$PitchDetectionResultSuccessImplCopyWith<$Res> {
  __$$PitchDetectionResultSuccessImplCopyWithImpl(
      _$PitchDetectionResultSuccessImpl _value,
      $Res Function(_$PitchDetectionResultSuccessImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frequency = null,
    Object? confidence = null,
    Object? midiNote = null,
    Object? volume = null,
  }) {
    return _then(_$PitchDetectionResultSuccessImpl(
      frequency: null == frequency
          ? _value.frequency
          : frequency // ignore: cast_nullable_to_non_nullable
              as double,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      midiNote: null == midiNote
          ? _value.midiNote
          : midiNote // ignore: cast_nullable_to_non_nullable
              as int,
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PitchDetectionResultSuccessImpl extends _PitchDetectionResultSuccess {
  const _$PitchDetectionResultSuccessImpl(
      {required this.frequency,
      required this.confidence,
      required this.midiNote,
      required this.volume,
      final String? $type})
      : $type = $type ?? 'success',
        super._();

  factory _$PitchDetectionResultSuccessImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PitchDetectionResultSuccessImplFromJson(json);

  @override
  final double frequency;
  @override
  final double confidence;
  @override
  final int midiNote;
  @override
  final double volume;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'PitchDetectionResult.success(frequency: $frequency, confidence: $confidence, midiNote: $midiNote, volume: $volume)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PitchDetectionResultSuccessImpl &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.midiNote, midiNote) ||
                other.midiNote == midiNote) &&
            (identical(other.volume, volume) || other.volume == volume));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, frequency, confidence, midiNote, volume);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PitchDetectionResultSuccessImplCopyWith<_$PitchDetectionResultSuccessImpl>
      get copyWith => __$$PitchDetectionResultSuccessImplCopyWithImpl<
          _$PitchDetectionResultSuccessImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            double frequency, double confidence, int midiNote, double volume)
        success,
    required TResult Function(String reason, double volume) failure,
  }) {
    return success(frequency, confidence, midiNote, volume);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            double frequency, double confidence, int midiNote, double volume)?
        success,
    TResult? Function(String reason, double volume)? failure,
  }) {
    return success?.call(frequency, confidence, midiNote, volume);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            double frequency, double confidence, int midiNote, double volume)?
        success,
    TResult Function(String reason, double volume)? failure,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(frequency, confidence, midiNote, volume);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_PitchDetectionResultSuccess value) success,
    required TResult Function(_PitchDetectionResultFailure value) failure,
  }) {
    return success(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_PitchDetectionResultSuccess value)? success,
    TResult? Function(_PitchDetectionResultFailure value)? failure,
  }) {
    return success?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_PitchDetectionResultSuccess value)? success,
    TResult Function(_PitchDetectionResultFailure value)? failure,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PitchDetectionResultSuccessImplToJson(
      this,
    );
  }
}

abstract class _PitchDetectionResultSuccess extends PitchDetectionResult {
  const factory _PitchDetectionResultSuccess(
      {required final double frequency,
      required final double confidence,
      required final int midiNote,
      required final double volume}) = _$PitchDetectionResultSuccessImpl;
  const _PitchDetectionResultSuccess._() : super._();

  factory _PitchDetectionResultSuccess.fromJson(Map<String, dynamic> json) =
      _$PitchDetectionResultSuccessImpl.fromJson;

  double get frequency;
  double get confidence;
  int get midiNote;
  @override
  double get volume;
  @override
  @JsonKey(ignore: true)
  _$$PitchDetectionResultSuccessImplCopyWith<_$PitchDetectionResultSuccessImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PitchDetectionResultFailureImplCopyWith<$Res>
    implements $PitchDetectionResultCopyWith<$Res> {
  factory _$$PitchDetectionResultFailureImplCopyWith(
          _$PitchDetectionResultFailureImpl value,
          $Res Function(_$PitchDetectionResultFailureImpl) then) =
      __$$PitchDetectionResultFailureImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String reason, double volume});
}

/// @nodoc
class __$$PitchDetectionResultFailureImplCopyWithImpl<$Res>
    extends _$PitchDetectionResultCopyWithImpl<$Res,
        _$PitchDetectionResultFailureImpl>
    implements _$$PitchDetectionResultFailureImplCopyWith<$Res> {
  __$$PitchDetectionResultFailureImplCopyWithImpl(
      _$PitchDetectionResultFailureImpl _value,
      $Res Function(_$PitchDetectionResultFailureImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reason = null,
    Object? volume = null,
  }) {
    return _then(_$PitchDetectionResultFailureImpl(
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PitchDetectionResultFailureImpl extends _PitchDetectionResultFailure {
  const _$PitchDetectionResultFailureImpl(
      {required this.reason, this.volume = 0.0, final String? $type})
      : $type = $type ?? 'failure',
        super._();

  factory _$PitchDetectionResultFailureImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PitchDetectionResultFailureImplFromJson(json);

  @override
  final String reason;
  @override
  @JsonKey()
  final double volume;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'PitchDetectionResult.failure(reason: $reason, volume: $volume)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PitchDetectionResultFailureImpl &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.volume, volume) || other.volume == volume));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, reason, volume);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PitchDetectionResultFailureImplCopyWith<_$PitchDetectionResultFailureImpl>
      get copyWith => __$$PitchDetectionResultFailureImplCopyWithImpl<
          _$PitchDetectionResultFailureImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            double frequency, double confidence, int midiNote, double volume)
        success,
    required TResult Function(String reason, double volume) failure,
  }) {
    return failure(reason, volume);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            double frequency, double confidence, int midiNote, double volume)?
        success,
    TResult? Function(String reason, double volume)? failure,
  }) {
    return failure?.call(reason, volume);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            double frequency, double confidence, int midiNote, double volume)?
        success,
    TResult Function(String reason, double volume)? failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(reason, volume);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_PitchDetectionResultSuccess value) success,
    required TResult Function(_PitchDetectionResultFailure value) failure,
  }) {
    return failure(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_PitchDetectionResultSuccess value)? success,
    TResult? Function(_PitchDetectionResultFailure value)? failure,
  }) {
    return failure?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_PitchDetectionResultSuccess value)? success,
    TResult Function(_PitchDetectionResultFailure value)? failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PitchDetectionResultFailureImplToJson(
      this,
    );
  }
}

abstract class _PitchDetectionResultFailure extends PitchDetectionResult {
  const factory _PitchDetectionResultFailure(
      {required final String reason,
      final double volume}) = _$PitchDetectionResultFailureImpl;
  const _PitchDetectionResultFailure._() : super._();

  factory _PitchDetectionResultFailure.fromJson(Map<String, dynamic> json) =
      _$PitchDetectionResultFailureImpl.fromJson;

  String get reason;
  @override
  double get volume;
  @override
  @JsonKey(ignore: true)
  _$$PitchDetectionResultFailureImplCopyWith<_$PitchDetectionResultFailureImpl>
      get copyWith => throw _privateConstructorUsedError;
}
