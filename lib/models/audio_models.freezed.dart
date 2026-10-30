// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audio_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PitchEvent {

 double get frequency;// Hz
 double get confidence;// 0.0 - 1.0
 int get midiNote;// MIDI note number (60 = middle C)
 double get timestamp;// seconds since engine start
 double get volume;// RMS volume 0.0 - 1.0
/// True for a key strike reported by the instrument itself (a MIDI
/// note-on). Microphone events are frames of a sound, so the engine
/// works out where a new strike begins.
 bool get struck;
/// Create a copy of PitchEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PitchEventCopyWith<PitchEvent> get copyWith => _$PitchEventCopyWithImpl<PitchEvent>(this as PitchEvent, _$identity);

  /// Serializes this PitchEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PitchEvent&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.midiNote, midiNote) || other.midiNote == midiNote)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.struck, struck) || other.struck == struck));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,frequency,confidence,midiNote,timestamp,volume,struck);

@override
String toString() {
  return 'PitchEvent(frequency: $frequency, confidence: $confidence, midiNote: $midiNote, timestamp: $timestamp, volume: $volume, struck: $struck)';
}


}

/// @nodoc
abstract mixin class $PitchEventCopyWith<$Res>  {
  factory $PitchEventCopyWith(PitchEvent value, $Res Function(PitchEvent) _then) = _$PitchEventCopyWithImpl;
@useResult
$Res call({
 double frequency, double confidence, int midiNote, double timestamp, double volume, bool struck
});




}
/// @nodoc
class _$PitchEventCopyWithImpl<$Res>
    implements $PitchEventCopyWith<$Res> {
  _$PitchEventCopyWithImpl(this._self, this._then);

  final PitchEvent _self;
  final $Res Function(PitchEvent) _then;

/// Create a copy of PitchEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? frequency = null,Object? confidence = null,Object? midiNote = null,Object? timestamp = null,Object? volume = null,Object? struck = null,}) {
  return _then(_self.copyWith(
frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as double,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,midiNote: null == midiNote ? _self.midiNote : midiNote // ignore: cast_nullable_to_non_nullable
as int,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as double,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,struck: null == struck ? _self.struck : struck // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PitchEvent].
extension PitchEventPatterns on PitchEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PitchEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PitchEvent() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PitchEvent value)  $default,){
final _that = this;
switch (_that) {
case _PitchEvent():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PitchEvent value)?  $default,){
final _that = this;
switch (_that) {
case _PitchEvent() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double frequency,  double confidence,  int midiNote,  double timestamp,  double volume,  bool struck)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PitchEvent() when $default != null:
return $default(_that.frequency,_that.confidence,_that.midiNote,_that.timestamp,_that.volume,_that.struck);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double frequency,  double confidence,  int midiNote,  double timestamp,  double volume,  bool struck)  $default,) {final _that = this;
switch (_that) {
case _PitchEvent():
return $default(_that.frequency,_that.confidence,_that.midiNote,_that.timestamp,_that.volume,_that.struck);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double frequency,  double confidence,  int midiNote,  double timestamp,  double volume,  bool struck)?  $default,) {final _that = this;
switch (_that) {
case _PitchEvent() when $default != null:
return $default(_that.frequency,_that.confidence,_that.midiNote,_that.timestamp,_that.volume,_that.struck);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PitchEvent implements PitchEvent {
  const _PitchEvent({required this.frequency, required this.confidence, required this.midiNote, required this.timestamp, required this.volume, this.struck = false});
  factory _PitchEvent.fromJson(Map<String, dynamic> json) => _$PitchEventFromJson(json);

@override final  double frequency;
// Hz
@override final  double confidence;
// 0.0 - 1.0
@override final  int midiNote;
// MIDI note number (60 = middle C)
@override final  double timestamp;
// seconds since engine start
@override final  double volume;
// RMS volume 0.0 - 1.0
/// True for a key strike reported by the instrument itself (a MIDI
/// note-on). Microphone events are frames of a sound, so the engine
/// works out where a new strike begins.
@override@JsonKey() final  bool struck;

/// Create a copy of PitchEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PitchEventCopyWith<_PitchEvent> get copyWith => __$PitchEventCopyWithImpl<_PitchEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PitchEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PitchEvent&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.midiNote, midiNote) || other.midiNote == midiNote)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.struck, struck) || other.struck == struck));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,frequency,confidence,midiNote,timestamp,volume,struck);

@override
String toString() {
  return 'PitchEvent(frequency: $frequency, confidence: $confidence, midiNote: $midiNote, timestamp: $timestamp, volume: $volume, struck: $struck)';
}


}

/// @nodoc
abstract mixin class _$PitchEventCopyWith<$Res> implements $PitchEventCopyWith<$Res> {
  factory _$PitchEventCopyWith(_PitchEvent value, $Res Function(_PitchEvent) _then) = __$PitchEventCopyWithImpl;
@override @useResult
$Res call({
 double frequency, double confidence, int midiNote, double timestamp, double volume, bool struck
});




}
/// @nodoc
class __$PitchEventCopyWithImpl<$Res>
    implements _$PitchEventCopyWith<$Res> {
  __$PitchEventCopyWithImpl(this._self, this._then);

  final _PitchEvent _self;
  final $Res Function(_PitchEvent) _then;

/// Create a copy of PitchEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? frequency = null,Object? confidence = null,Object? midiNote = null,Object? timestamp = null,Object? volume = null,Object? struck = null,}) {
  return _then(_PitchEvent(
frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as double,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,midiNote: null == midiNote ? _self.midiNote : midiNote // ignore: cast_nullable_to_non_nullable
as int,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as double,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,struck: null == struck ? _self.struck : struck // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$AudioEngineConfig {

 int get sampleRate; int get bufferSize; double get minVolumeThreshold;// minimum volume to consider as note
 double get minConfidenceThreshold;// minimum confidence for pitch detection
 double get referenceFrequency;
/// Create a copy of AudioEngineConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AudioEngineConfigCopyWith<AudioEngineConfig> get copyWith => _$AudioEngineConfigCopyWithImpl<AudioEngineConfig>(this as AudioEngineConfig, _$identity);

  /// Serializes this AudioEngineConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AudioEngineConfig&&(identical(other.sampleRate, sampleRate) || other.sampleRate == sampleRate)&&(identical(other.bufferSize, bufferSize) || other.bufferSize == bufferSize)&&(identical(other.minVolumeThreshold, minVolumeThreshold) || other.minVolumeThreshold == minVolumeThreshold)&&(identical(other.minConfidenceThreshold, minConfidenceThreshold) || other.minConfidenceThreshold == minConfidenceThreshold)&&(identical(other.referenceFrequency, referenceFrequency) || other.referenceFrequency == referenceFrequency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sampleRate,bufferSize,minVolumeThreshold,minConfidenceThreshold,referenceFrequency);

@override
String toString() {
  return 'AudioEngineConfig(sampleRate: $sampleRate, bufferSize: $bufferSize, minVolumeThreshold: $minVolumeThreshold, minConfidenceThreshold: $minConfidenceThreshold, referenceFrequency: $referenceFrequency)';
}


}

/// @nodoc
abstract mixin class $AudioEngineConfigCopyWith<$Res>  {
  factory $AudioEngineConfigCopyWith(AudioEngineConfig value, $Res Function(AudioEngineConfig) _then) = _$AudioEngineConfigCopyWithImpl;
@useResult
$Res call({
 int sampleRate, int bufferSize, double minVolumeThreshold, double minConfidenceThreshold, double referenceFrequency
});




}
/// @nodoc
class _$AudioEngineConfigCopyWithImpl<$Res>
    implements $AudioEngineConfigCopyWith<$Res> {
  _$AudioEngineConfigCopyWithImpl(this._self, this._then);

  final AudioEngineConfig _self;
  final $Res Function(AudioEngineConfig) _then;

/// Create a copy of AudioEngineConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sampleRate = null,Object? bufferSize = null,Object? minVolumeThreshold = null,Object? minConfidenceThreshold = null,Object? referenceFrequency = null,}) {
  return _then(_self.copyWith(
sampleRate: null == sampleRate ? _self.sampleRate : sampleRate // ignore: cast_nullable_to_non_nullable
as int,bufferSize: null == bufferSize ? _self.bufferSize : bufferSize // ignore: cast_nullable_to_non_nullable
as int,minVolumeThreshold: null == minVolumeThreshold ? _self.minVolumeThreshold : minVolumeThreshold // ignore: cast_nullable_to_non_nullable
as double,minConfidenceThreshold: null == minConfidenceThreshold ? _self.minConfidenceThreshold : minConfidenceThreshold // ignore: cast_nullable_to_non_nullable
as double,referenceFrequency: null == referenceFrequency ? _self.referenceFrequency : referenceFrequency // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [AudioEngineConfig].
extension AudioEngineConfigPatterns on AudioEngineConfig {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AudioEngineConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AudioEngineConfig() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AudioEngineConfig value)  $default,){
final _that = this;
switch (_that) {
case _AudioEngineConfig():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AudioEngineConfig value)?  $default,){
final _that = this;
switch (_that) {
case _AudioEngineConfig() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int sampleRate,  int bufferSize,  double minVolumeThreshold,  double minConfidenceThreshold,  double referenceFrequency)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AudioEngineConfig() when $default != null:
return $default(_that.sampleRate,_that.bufferSize,_that.minVolumeThreshold,_that.minConfidenceThreshold,_that.referenceFrequency);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int sampleRate,  int bufferSize,  double minVolumeThreshold,  double minConfidenceThreshold,  double referenceFrequency)  $default,) {final _that = this;
switch (_that) {
case _AudioEngineConfig():
return $default(_that.sampleRate,_that.bufferSize,_that.minVolumeThreshold,_that.minConfidenceThreshold,_that.referenceFrequency);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int sampleRate,  int bufferSize,  double minVolumeThreshold,  double minConfidenceThreshold,  double referenceFrequency)?  $default,) {final _that = this;
switch (_that) {
case _AudioEngineConfig() when $default != null:
return $default(_that.sampleRate,_that.bufferSize,_that.minVolumeThreshold,_that.minConfidenceThreshold,_that.referenceFrequency);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AudioEngineConfig implements AudioEngineConfig {
  const _AudioEngineConfig({this.sampleRate = 44100, this.bufferSize = 2048, this.minVolumeThreshold = 0.1, this.minConfidenceThreshold = 0.7, this.referenceFrequency = 440.0});
  factory _AudioEngineConfig.fromJson(Map<String, dynamic> json) => _$AudioEngineConfigFromJson(json);

@override@JsonKey() final  int sampleRate;
@override@JsonKey() final  int bufferSize;
@override@JsonKey() final  double minVolumeThreshold;
// minimum volume to consider as note
@override@JsonKey() final  double minConfidenceThreshold;
// minimum confidence for pitch detection
@override@JsonKey() final  double referenceFrequency;

/// Create a copy of AudioEngineConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AudioEngineConfigCopyWith<_AudioEngineConfig> get copyWith => __$AudioEngineConfigCopyWithImpl<_AudioEngineConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AudioEngineConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AudioEngineConfig&&(identical(other.sampleRate, sampleRate) || other.sampleRate == sampleRate)&&(identical(other.bufferSize, bufferSize) || other.bufferSize == bufferSize)&&(identical(other.minVolumeThreshold, minVolumeThreshold) || other.minVolumeThreshold == minVolumeThreshold)&&(identical(other.minConfidenceThreshold, minConfidenceThreshold) || other.minConfidenceThreshold == minConfidenceThreshold)&&(identical(other.referenceFrequency, referenceFrequency) || other.referenceFrequency == referenceFrequency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sampleRate,bufferSize,minVolumeThreshold,minConfidenceThreshold,referenceFrequency);

@override
String toString() {
  return 'AudioEngineConfig(sampleRate: $sampleRate, bufferSize: $bufferSize, minVolumeThreshold: $minVolumeThreshold, minConfidenceThreshold: $minConfidenceThreshold, referenceFrequency: $referenceFrequency)';
}


}

/// @nodoc
abstract mixin class _$AudioEngineConfigCopyWith<$Res> implements $AudioEngineConfigCopyWith<$Res> {
  factory _$AudioEngineConfigCopyWith(_AudioEngineConfig value, $Res Function(_AudioEngineConfig) _then) = __$AudioEngineConfigCopyWithImpl;
@override @useResult
$Res call({
 int sampleRate, int bufferSize, double minVolumeThreshold, double minConfidenceThreshold, double referenceFrequency
});




}
/// @nodoc
class __$AudioEngineConfigCopyWithImpl<$Res>
    implements _$AudioEngineConfigCopyWith<$Res> {
  __$AudioEngineConfigCopyWithImpl(this._self, this._then);

  final _AudioEngineConfig _self;
  final $Res Function(_AudioEngineConfig) _then;

/// Create a copy of AudioEngineConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sampleRate = null,Object? bufferSize = null,Object? minVolumeThreshold = null,Object? minConfidenceThreshold = null,Object? referenceFrequency = null,}) {
  return _then(_AudioEngineConfig(
sampleRate: null == sampleRate ? _self.sampleRate : sampleRate // ignore: cast_nullable_to_non_nullable
as int,bufferSize: null == bufferSize ? _self.bufferSize : bufferSize // ignore: cast_nullable_to_non_nullable
as int,minVolumeThreshold: null == minVolumeThreshold ? _self.minVolumeThreshold : minVolumeThreshold // ignore: cast_nullable_to_non_nullable
as double,minConfidenceThreshold: null == minConfidenceThreshold ? _self.minConfidenceThreshold : minConfidenceThreshold // ignore: cast_nullable_to_non_nullable
as double,referenceFrequency: null == referenceFrequency ? _self.referenceFrequency : referenceFrequency // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$AudioEngineStatus {

 AudioEngineState get state; String? get errorMessage; double get currentVolume; double get currentPitch; int get currentMidiNote;
/// Create a copy of AudioEngineStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AudioEngineStatusCopyWith<AudioEngineStatus> get copyWith => _$AudioEngineStatusCopyWithImpl<AudioEngineStatus>(this as AudioEngineStatus, _$identity);

  /// Serializes this AudioEngineStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AudioEngineStatus&&(identical(other.state, state) || other.state == state)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.currentVolume, currentVolume) || other.currentVolume == currentVolume)&&(identical(other.currentPitch, currentPitch) || other.currentPitch == currentPitch)&&(identical(other.currentMidiNote, currentMidiNote) || other.currentMidiNote == currentMidiNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,state,errorMessage,currentVolume,currentPitch,currentMidiNote);

@override
String toString() {
  return 'AudioEngineStatus(state: $state, errorMessage: $errorMessage, currentVolume: $currentVolume, currentPitch: $currentPitch, currentMidiNote: $currentMidiNote)';
}


}

/// @nodoc
abstract mixin class $AudioEngineStatusCopyWith<$Res>  {
  factory $AudioEngineStatusCopyWith(AudioEngineStatus value, $Res Function(AudioEngineStatus) _then) = _$AudioEngineStatusCopyWithImpl;
@useResult
$Res call({
 AudioEngineState state, String? errorMessage, double currentVolume, double currentPitch, int currentMidiNote
});




}
/// @nodoc
class _$AudioEngineStatusCopyWithImpl<$Res>
    implements $AudioEngineStatusCopyWith<$Res> {
  _$AudioEngineStatusCopyWithImpl(this._self, this._then);

  final AudioEngineStatus _self;
  final $Res Function(AudioEngineStatus) _then;

/// Create a copy of AudioEngineStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? state = null,Object? errorMessage = freezed,Object? currentVolume = null,Object? currentPitch = null,Object? currentMidiNote = null,}) {
  return _then(_self.copyWith(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as AudioEngineState,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,currentVolume: null == currentVolume ? _self.currentVolume : currentVolume // ignore: cast_nullable_to_non_nullable
as double,currentPitch: null == currentPitch ? _self.currentPitch : currentPitch // ignore: cast_nullable_to_non_nullable
as double,currentMidiNote: null == currentMidiNote ? _self.currentMidiNote : currentMidiNote // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AudioEngineStatus].
extension AudioEngineStatusPatterns on AudioEngineStatus {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AudioEngineStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AudioEngineStatus() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AudioEngineStatus value)  $default,){
final _that = this;
switch (_that) {
case _AudioEngineStatus():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AudioEngineStatus value)?  $default,){
final _that = this;
switch (_that) {
case _AudioEngineStatus() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AudioEngineState state,  String? errorMessage,  double currentVolume,  double currentPitch,  int currentMidiNote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AudioEngineStatus() when $default != null:
return $default(_that.state,_that.errorMessage,_that.currentVolume,_that.currentPitch,_that.currentMidiNote);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AudioEngineState state,  String? errorMessage,  double currentVolume,  double currentPitch,  int currentMidiNote)  $default,) {final _that = this;
switch (_that) {
case _AudioEngineStatus():
return $default(_that.state,_that.errorMessage,_that.currentVolume,_that.currentPitch,_that.currentMidiNote);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AudioEngineState state,  String? errorMessage,  double currentVolume,  double currentPitch,  int currentMidiNote)?  $default,) {final _that = this;
switch (_that) {
case _AudioEngineStatus() when $default != null:
return $default(_that.state,_that.errorMessage,_that.currentVolume,_that.currentPitch,_that.currentMidiNote);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AudioEngineStatus implements AudioEngineStatus {
  const _AudioEngineStatus({required this.state, this.errorMessage, this.currentVolume = 0.0, this.currentPitch = 0.0, this.currentMidiNote = 0});
  factory _AudioEngineStatus.fromJson(Map<String, dynamic> json) => _$AudioEngineStatusFromJson(json);

@override final  AudioEngineState state;
@override final  String? errorMessage;
@override@JsonKey() final  double currentVolume;
@override@JsonKey() final  double currentPitch;
@override@JsonKey() final  int currentMidiNote;

/// Create a copy of AudioEngineStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AudioEngineStatusCopyWith<_AudioEngineStatus> get copyWith => __$AudioEngineStatusCopyWithImpl<_AudioEngineStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AudioEngineStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AudioEngineStatus&&(identical(other.state, state) || other.state == state)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.currentVolume, currentVolume) || other.currentVolume == currentVolume)&&(identical(other.currentPitch, currentPitch) || other.currentPitch == currentPitch)&&(identical(other.currentMidiNote, currentMidiNote) || other.currentMidiNote == currentMidiNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,state,errorMessage,currentVolume,currentPitch,currentMidiNote);

@override
String toString() {
  return 'AudioEngineStatus(state: $state, errorMessage: $errorMessage, currentVolume: $currentVolume, currentPitch: $currentPitch, currentMidiNote: $currentMidiNote)';
}


}

/// @nodoc
abstract mixin class _$AudioEngineStatusCopyWith<$Res> implements $AudioEngineStatusCopyWith<$Res> {
  factory _$AudioEngineStatusCopyWith(_AudioEngineStatus value, $Res Function(_AudioEngineStatus) _then) = __$AudioEngineStatusCopyWithImpl;
@override @useResult
$Res call({
 AudioEngineState state, String? errorMessage, double currentVolume, double currentPitch, int currentMidiNote
});




}
/// @nodoc
class __$AudioEngineStatusCopyWithImpl<$Res>
    implements _$AudioEngineStatusCopyWith<$Res> {
  __$AudioEngineStatusCopyWithImpl(this._self, this._then);

  final _AudioEngineStatus _self;
  final $Res Function(_AudioEngineStatus) _then;

/// Create a copy of AudioEngineStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? state = null,Object? errorMessage = freezed,Object? currentVolume = null,Object? currentPitch = null,Object? currentMidiNote = null,}) {
  return _then(_AudioEngineStatus(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as AudioEngineState,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,currentVolume: null == currentVolume ? _self.currentVolume : currentVolume // ignore: cast_nullable_to_non_nullable
as double,currentPitch: null == currentPitch ? _self.currentPitch : currentPitch // ignore: cast_nullable_to_non_nullable
as double,currentMidiNote: null == currentMidiNote ? _self.currentMidiNote : currentMidiNote // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

PitchDetectionResult _$PitchDetectionResultFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'success':
          return _PitchDetectionResultSuccess.fromJson(
            json
          );
                case 'failure':
          return _PitchDetectionResultFailure.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'PitchDetectionResult',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$PitchDetectionResult {

 double get volume;
/// Create a copy of PitchDetectionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PitchDetectionResultCopyWith<PitchDetectionResult> get copyWith => _$PitchDetectionResultCopyWithImpl<PitchDetectionResult>(this as PitchDetectionResult, _$identity);

  /// Serializes this PitchDetectionResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PitchDetectionResult&&(identical(other.volume, volume) || other.volume == volume));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,volume);

@override
String toString() {
  return 'PitchDetectionResult(volume: $volume)';
}


}

/// @nodoc
abstract mixin class $PitchDetectionResultCopyWith<$Res>  {
  factory $PitchDetectionResultCopyWith(PitchDetectionResult value, $Res Function(PitchDetectionResult) _then) = _$PitchDetectionResultCopyWithImpl;
@useResult
$Res call({
 double volume
});




}
/// @nodoc
class _$PitchDetectionResultCopyWithImpl<$Res>
    implements $PitchDetectionResultCopyWith<$Res> {
  _$PitchDetectionResultCopyWithImpl(this._self, this._then);

  final PitchDetectionResult _self;
  final $Res Function(PitchDetectionResult) _then;

/// Create a copy of PitchDetectionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? volume = null,}) {
  return _then(_self.copyWith(
volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PitchDetectionResult].
extension PitchDetectionResultPatterns on PitchDetectionResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _PitchDetectionResultSuccess value)?  success,TResult Function( _PitchDetectionResultFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PitchDetectionResultSuccess() when success != null:
return success(_that);case _PitchDetectionResultFailure() when failure != null:
return failure(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _PitchDetectionResultSuccess value)  success,required TResult Function( _PitchDetectionResultFailure value)  failure,}){
final _that = this;
switch (_that) {
case _PitchDetectionResultSuccess():
return success(_that);case _PitchDetectionResultFailure():
return failure(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _PitchDetectionResultSuccess value)?  success,TResult? Function( _PitchDetectionResultFailure value)?  failure,}){
final _that = this;
switch (_that) {
case _PitchDetectionResultSuccess() when success != null:
return success(_that);case _PitchDetectionResultFailure() when failure != null:
return failure(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( double frequency,  double confidence,  int midiNote,  double volume)?  success,TResult Function( String reason,  double volume)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PitchDetectionResultSuccess() when success != null:
return success(_that.frequency,_that.confidence,_that.midiNote,_that.volume);case _PitchDetectionResultFailure() when failure != null:
return failure(_that.reason,_that.volume);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( double frequency,  double confidence,  int midiNote,  double volume)  success,required TResult Function( String reason,  double volume)  failure,}) {final _that = this;
switch (_that) {
case _PitchDetectionResultSuccess():
return success(_that.frequency,_that.confidence,_that.midiNote,_that.volume);case _PitchDetectionResultFailure():
return failure(_that.reason,_that.volume);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( double frequency,  double confidence,  int midiNote,  double volume)?  success,TResult? Function( String reason,  double volume)?  failure,}) {final _that = this;
switch (_that) {
case _PitchDetectionResultSuccess() when success != null:
return success(_that.frequency,_that.confidence,_that.midiNote,_that.volume);case _PitchDetectionResultFailure() when failure != null:
return failure(_that.reason,_that.volume);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PitchDetectionResultSuccess extends PitchDetectionResult {
  const _PitchDetectionResultSuccess({required this.frequency, required this.confidence, required this.midiNote, required this.volume, final  String? $type}): $type = $type ?? 'success',super._();
  factory _PitchDetectionResultSuccess.fromJson(Map<String, dynamic> json) => _$PitchDetectionResultSuccessFromJson(json);

 final  double frequency;
 final  double confidence;
 final  int midiNote;
@override final  double volume;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of PitchDetectionResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PitchDetectionResultSuccessCopyWith<_PitchDetectionResultSuccess> get copyWith => __$PitchDetectionResultSuccessCopyWithImpl<_PitchDetectionResultSuccess>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PitchDetectionResultSuccessToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PitchDetectionResultSuccess&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.midiNote, midiNote) || other.midiNote == midiNote)&&(identical(other.volume, volume) || other.volume == volume));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,frequency,confidence,midiNote,volume);

@override
String toString() {
  return 'PitchDetectionResult.success(frequency: $frequency, confidence: $confidence, midiNote: $midiNote, volume: $volume)';
}


}

/// @nodoc
abstract mixin class _$PitchDetectionResultSuccessCopyWith<$Res> implements $PitchDetectionResultCopyWith<$Res> {
  factory _$PitchDetectionResultSuccessCopyWith(_PitchDetectionResultSuccess value, $Res Function(_PitchDetectionResultSuccess) _then) = __$PitchDetectionResultSuccessCopyWithImpl;
@override @useResult
$Res call({
 double frequency, double confidence, int midiNote, double volume
});




}
/// @nodoc
class __$PitchDetectionResultSuccessCopyWithImpl<$Res>
    implements _$PitchDetectionResultSuccessCopyWith<$Res> {
  __$PitchDetectionResultSuccessCopyWithImpl(this._self, this._then);

  final _PitchDetectionResultSuccess _self;
  final $Res Function(_PitchDetectionResultSuccess) _then;

/// Create a copy of PitchDetectionResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? frequency = null,Object? confidence = null,Object? midiNote = null,Object? volume = null,}) {
  return _then(_PitchDetectionResultSuccess(
frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as double,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,midiNote: null == midiNote ? _self.midiNote : midiNote // ignore: cast_nullable_to_non_nullable
as int,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
@JsonSerializable()

class _PitchDetectionResultFailure extends PitchDetectionResult {
  const _PitchDetectionResultFailure({required this.reason, this.volume = 0.0, final  String? $type}): $type = $type ?? 'failure',super._();
  factory _PitchDetectionResultFailure.fromJson(Map<String, dynamic> json) => _$PitchDetectionResultFailureFromJson(json);

 final  String reason;
@override@JsonKey() final  double volume;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of PitchDetectionResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PitchDetectionResultFailureCopyWith<_PitchDetectionResultFailure> get copyWith => __$PitchDetectionResultFailureCopyWithImpl<_PitchDetectionResultFailure>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PitchDetectionResultFailureToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PitchDetectionResultFailure&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.volume, volume) || other.volume == volume));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reason,volume);

@override
String toString() {
  return 'PitchDetectionResult.failure(reason: $reason, volume: $volume)';
}


}

/// @nodoc
abstract mixin class _$PitchDetectionResultFailureCopyWith<$Res> implements $PitchDetectionResultCopyWith<$Res> {
  factory _$PitchDetectionResultFailureCopyWith(_PitchDetectionResultFailure value, $Res Function(_PitchDetectionResultFailure) _then) = __$PitchDetectionResultFailureCopyWithImpl;
@override @useResult
$Res call({
 String reason, double volume
});




}
/// @nodoc
class __$PitchDetectionResultFailureCopyWithImpl<$Res>
    implements _$PitchDetectionResultFailureCopyWith<$Res> {
  __$PitchDetectionResultFailureCopyWithImpl(this._self, this._then);

  final _PitchDetectionResultFailure _self;
  final $Res Function(_PitchDetectionResultFailure) _then;

/// Create a copy of PitchDetectionResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reason = null,Object? volume = null,}) {
  return _then(_PitchDetectionResultFailure(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
