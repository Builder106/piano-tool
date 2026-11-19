// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'engine_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WaitingHint {

 double get targetBeat; List<int> get targetMidiNotes; String get hintText; List<String> get noteNames; int? get measureIndex; int? get beatIndex; int? get heardWrongMidiNote;
/// Create a copy of WaitingHint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WaitingHintCopyWith<WaitingHint> get copyWith => _$WaitingHintCopyWithImpl<WaitingHint>(this as WaitingHint, _$identity);

  /// Serializes this WaitingHint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WaitingHint&&(identical(other.targetBeat, targetBeat) || other.targetBeat == targetBeat)&&const DeepCollectionEquality().equals(other.targetMidiNotes, targetMidiNotes)&&(identical(other.hintText, hintText) || other.hintText == hintText)&&const DeepCollectionEquality().equals(other.noteNames, noteNames)&&(identical(other.measureIndex, measureIndex) || other.measureIndex == measureIndex)&&(identical(other.beatIndex, beatIndex) || other.beatIndex == beatIndex)&&(identical(other.heardWrongMidiNote, heardWrongMidiNote) || other.heardWrongMidiNote == heardWrongMidiNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetBeat,const DeepCollectionEquality().hash(targetMidiNotes),hintText,const DeepCollectionEquality().hash(noteNames),measureIndex,beatIndex,heardWrongMidiNote);

@override
String toString() {
  return 'WaitingHint(targetBeat: $targetBeat, targetMidiNotes: $targetMidiNotes, hintText: $hintText, noteNames: $noteNames, measureIndex: $measureIndex, beatIndex: $beatIndex, heardWrongMidiNote: $heardWrongMidiNote)';
}


}

/// @nodoc
abstract mixin class $WaitingHintCopyWith<$Res>  {
  factory $WaitingHintCopyWith(WaitingHint value, $Res Function(WaitingHint) _then) = _$WaitingHintCopyWithImpl;
@useResult
$Res call({
 double targetBeat, List<int> targetMidiNotes, String hintText, List<String> noteNames, int? measureIndex, int? beatIndex, int? heardWrongMidiNote
});




}
/// @nodoc
class _$WaitingHintCopyWithImpl<$Res>
    implements $WaitingHintCopyWith<$Res> {
  _$WaitingHintCopyWithImpl(this._self, this._then);

  final WaitingHint _self;
  final $Res Function(WaitingHint) _then;

/// Create a copy of WaitingHint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? targetBeat = null,Object? targetMidiNotes = null,Object? hintText = null,Object? noteNames = null,Object? measureIndex = freezed,Object? beatIndex = freezed,Object? heardWrongMidiNote = freezed,}) {
  return _then(_self.copyWith(
targetBeat: null == targetBeat ? _self.targetBeat : targetBeat // ignore: cast_nullable_to_non_nullable
as double,targetMidiNotes: null == targetMidiNotes ? _self.targetMidiNotes : targetMidiNotes // ignore: cast_nullable_to_non_nullable
as List<int>,hintText: null == hintText ? _self.hintText : hintText // ignore: cast_nullable_to_non_nullable
as String,noteNames: null == noteNames ? _self.noteNames : noteNames // ignore: cast_nullable_to_non_nullable
as List<String>,measureIndex: freezed == measureIndex ? _self.measureIndex : measureIndex // ignore: cast_nullable_to_non_nullable
as int?,beatIndex: freezed == beatIndex ? _self.beatIndex : beatIndex // ignore: cast_nullable_to_non_nullable
as int?,heardWrongMidiNote: freezed == heardWrongMidiNote ? _self.heardWrongMidiNote : heardWrongMidiNote // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [WaitingHint].
extension WaitingHintPatterns on WaitingHint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WaitingHint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WaitingHint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WaitingHint value)  $default,){
final _that = this;
switch (_that) {
case _WaitingHint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WaitingHint value)?  $default,){
final _that = this;
switch (_that) {
case _WaitingHint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double targetBeat,  List<int> targetMidiNotes,  String hintText,  List<String> noteNames,  int? measureIndex,  int? beatIndex,  int? heardWrongMidiNote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WaitingHint() when $default != null:
return $default(_that.targetBeat,_that.targetMidiNotes,_that.hintText,_that.noteNames,_that.measureIndex,_that.beatIndex,_that.heardWrongMidiNote);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double targetBeat,  List<int> targetMidiNotes,  String hintText,  List<String> noteNames,  int? measureIndex,  int? beatIndex,  int? heardWrongMidiNote)  $default,) {final _that = this;
switch (_that) {
case _WaitingHint():
return $default(_that.targetBeat,_that.targetMidiNotes,_that.hintText,_that.noteNames,_that.measureIndex,_that.beatIndex,_that.heardWrongMidiNote);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double targetBeat,  List<int> targetMidiNotes,  String hintText,  List<String> noteNames,  int? measureIndex,  int? beatIndex,  int? heardWrongMidiNote)?  $default,) {final _that = this;
switch (_that) {
case _WaitingHint() when $default != null:
return $default(_that.targetBeat,_that.targetMidiNotes,_that.hintText,_that.noteNames,_that.measureIndex,_that.beatIndex,_that.heardWrongMidiNote);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WaitingHint extends WaitingHint {
  const _WaitingHint({required this.targetBeat, required final  List<int> targetMidiNotes, required this.hintText, final  List<String> noteNames = const [], this.measureIndex, this.beatIndex, this.heardWrongMidiNote}): _targetMidiNotes = targetMidiNotes,_noteNames = noteNames,super._();
  factory _WaitingHint.fromJson(Map<String, dynamic> json) => _$WaitingHintFromJson(json);

@override final  double targetBeat;
 final  List<int> _targetMidiNotes;
@override List<int> get targetMidiNotes {
  if (_targetMidiNotes is EqualUnmodifiableListView) return _targetMidiNotes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_targetMidiNotes);
}

@override final  String hintText;
 final  List<String> _noteNames;
@override@JsonKey() List<String> get noteNames {
  if (_noteNames is EqualUnmodifiableListView) return _noteNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_noteNames);
}

@override final  int? measureIndex;
@override final  int? beatIndex;
@override final  int? heardWrongMidiNote;

/// Create a copy of WaitingHint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WaitingHintCopyWith<_WaitingHint> get copyWith => __$WaitingHintCopyWithImpl<_WaitingHint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WaitingHintToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WaitingHint&&(identical(other.targetBeat, targetBeat) || other.targetBeat == targetBeat)&&const DeepCollectionEquality().equals(other._targetMidiNotes, _targetMidiNotes)&&(identical(other.hintText, hintText) || other.hintText == hintText)&&const DeepCollectionEquality().equals(other._noteNames, _noteNames)&&(identical(other.measureIndex, measureIndex) || other.measureIndex == measureIndex)&&(identical(other.beatIndex, beatIndex) || other.beatIndex == beatIndex)&&(identical(other.heardWrongMidiNote, heardWrongMidiNote) || other.heardWrongMidiNote == heardWrongMidiNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetBeat,const DeepCollectionEquality().hash(_targetMidiNotes),hintText,const DeepCollectionEquality().hash(_noteNames),measureIndex,beatIndex,heardWrongMidiNote);

@override
String toString() {
  return 'WaitingHint(targetBeat: $targetBeat, targetMidiNotes: $targetMidiNotes, hintText: $hintText, noteNames: $noteNames, measureIndex: $measureIndex, beatIndex: $beatIndex, heardWrongMidiNote: $heardWrongMidiNote)';
}


}

/// @nodoc
abstract mixin class _$WaitingHintCopyWith<$Res> implements $WaitingHintCopyWith<$Res> {
  factory _$WaitingHintCopyWith(_WaitingHint value, $Res Function(_WaitingHint) _then) = __$WaitingHintCopyWithImpl;
@override @useResult
$Res call({
 double targetBeat, List<int> targetMidiNotes, String hintText, List<String> noteNames, int? measureIndex, int? beatIndex, int? heardWrongMidiNote
});




}
/// @nodoc
class __$WaitingHintCopyWithImpl<$Res>
    implements _$WaitingHintCopyWith<$Res> {
  __$WaitingHintCopyWithImpl(this._self, this._then);

  final _WaitingHint _self;
  final $Res Function(_WaitingHint) _then;

/// Create a copy of WaitingHint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetBeat = null,Object? targetMidiNotes = null,Object? hintText = null,Object? noteNames = null,Object? measureIndex = freezed,Object? beatIndex = freezed,Object? heardWrongMidiNote = freezed,}) {
  return _then(_WaitingHint(
targetBeat: null == targetBeat ? _self.targetBeat : targetBeat // ignore: cast_nullable_to_non_nullable
as double,targetMidiNotes: null == targetMidiNotes ? _self._targetMidiNotes : targetMidiNotes // ignore: cast_nullable_to_non_nullable
as List<int>,hintText: null == hintText ? _self.hintText : hintText // ignore: cast_nullable_to_non_nullable
as String,noteNames: null == noteNames ? _self._noteNames : noteNames // ignore: cast_nullable_to_non_nullable
as List<String>,measureIndex: freezed == measureIndex ? _self.measureIndex : measureIndex // ignore: cast_nullable_to_non_nullable
as int?,beatIndex: freezed == beatIndex ? _self.beatIndex : beatIndex // ignore: cast_nullable_to_non_nullable
as int?,heardWrongMidiNote: freezed == heardWrongMidiNote ? _self.heardWrongMidiNote : heardWrongMidiNote // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

NoteHitResult _$NoteHitResultFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'perfect':
          return _NoteHitResultPerfect.fromJson(
            json
          );
                case 'good':
          return _NoteHitResultGood.fromJson(
            json
          );
                case 'okay':
          return _NoteHitResultOkay.fromJson(
            json
          );
                case 'missed':
          return _NoteHitResultMissed.fromJson(
            json
          );
                case 'waiting':
          return _NoteHitResultWaiting.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'NoteHitResult',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$NoteHitResult {

 int get noteIndex;
/// Create a copy of NoteHitResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoteHitResultCopyWith<NoteHitResult> get copyWith => _$NoteHitResultCopyWithImpl<NoteHitResult>(this as NoteHitResult, _$identity);

  /// Serializes this NoteHitResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoteHitResult&&(identical(other.noteIndex, noteIndex) || other.noteIndex == noteIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,noteIndex);

@override
String toString() {
  return 'NoteHitResult(noteIndex: $noteIndex)';
}


}

/// @nodoc
abstract mixin class $NoteHitResultCopyWith<$Res>  {
  factory $NoteHitResultCopyWith(NoteHitResult value, $Res Function(NoteHitResult) _then) = _$NoteHitResultCopyWithImpl;
@useResult
$Res call({
 int noteIndex
});




}
/// @nodoc
class _$NoteHitResultCopyWithImpl<$Res>
    implements $NoteHitResultCopyWith<$Res> {
  _$NoteHitResultCopyWithImpl(this._self, this._then);

  final NoteHitResult _self;
  final $Res Function(NoteHitResult) _then;

/// Create a copy of NoteHitResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? noteIndex = null,}) {
  return _then(_self.copyWith(
noteIndex: null == noteIndex ? _self.noteIndex : noteIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [NoteHitResult].
extension NoteHitResultPatterns on NoteHitResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _NoteHitResultPerfect value)?  perfect,TResult Function( _NoteHitResultGood value)?  good,TResult Function( _NoteHitResultOkay value)?  okay,TResult Function( _NoteHitResultMissed value)?  missed,TResult Function( _NoteHitResultWaiting value)?  waiting,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NoteHitResultPerfect() when perfect != null:
return perfect(_that);case _NoteHitResultGood() when good != null:
return good(_that);case _NoteHitResultOkay() when okay != null:
return okay(_that);case _NoteHitResultMissed() when missed != null:
return missed(_that);case _NoteHitResultWaiting() when waiting != null:
return waiting(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _NoteHitResultPerfect value)  perfect,required TResult Function( _NoteHitResultGood value)  good,required TResult Function( _NoteHitResultOkay value)  okay,required TResult Function( _NoteHitResultMissed value)  missed,required TResult Function( _NoteHitResultWaiting value)  waiting,}){
final _that = this;
switch (_that) {
case _NoteHitResultPerfect():
return perfect(_that);case _NoteHitResultGood():
return good(_that);case _NoteHitResultOkay():
return okay(_that);case _NoteHitResultMissed():
return missed(_that);case _NoteHitResultWaiting():
return waiting(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _NoteHitResultPerfect value)?  perfect,TResult? Function( _NoteHitResultGood value)?  good,TResult? Function( _NoteHitResultOkay value)?  okay,TResult? Function( _NoteHitResultMissed value)?  missed,TResult? Function( _NoteHitResultWaiting value)?  waiting,}){
final _that = this;
switch (_that) {
case _NoteHitResultPerfect() when perfect != null:
return perfect(_that);case _NoteHitResultGood() when good != null:
return good(_that);case _NoteHitResultOkay() when okay != null:
return okay(_that);case _NoteHitResultMissed() when missed != null:
return missed(_that);case _NoteHitResultWaiting() when waiting != null:
return waiting(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int noteIndex,  double timingError)?  perfect,TResult Function( int noteIndex,  double timingError)?  good,TResult Function( int noteIndex,  double timingError)?  okay,TResult Function( int noteIndex)?  missed,TResult Function( int noteIndex)?  waiting,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NoteHitResultPerfect() when perfect != null:
return perfect(_that.noteIndex,_that.timingError);case _NoteHitResultGood() when good != null:
return good(_that.noteIndex,_that.timingError);case _NoteHitResultOkay() when okay != null:
return okay(_that.noteIndex,_that.timingError);case _NoteHitResultMissed() when missed != null:
return missed(_that.noteIndex);case _NoteHitResultWaiting() when waiting != null:
return waiting(_that.noteIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int noteIndex,  double timingError)  perfect,required TResult Function( int noteIndex,  double timingError)  good,required TResult Function( int noteIndex,  double timingError)  okay,required TResult Function( int noteIndex)  missed,required TResult Function( int noteIndex)  waiting,}) {final _that = this;
switch (_that) {
case _NoteHitResultPerfect():
return perfect(_that.noteIndex,_that.timingError);case _NoteHitResultGood():
return good(_that.noteIndex,_that.timingError);case _NoteHitResultOkay():
return okay(_that.noteIndex,_that.timingError);case _NoteHitResultMissed():
return missed(_that.noteIndex);case _NoteHitResultWaiting():
return waiting(_that.noteIndex);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int noteIndex,  double timingError)?  perfect,TResult? Function( int noteIndex,  double timingError)?  good,TResult? Function( int noteIndex,  double timingError)?  okay,TResult? Function( int noteIndex)?  missed,TResult? Function( int noteIndex)?  waiting,}) {final _that = this;
switch (_that) {
case _NoteHitResultPerfect() when perfect != null:
return perfect(_that.noteIndex,_that.timingError);case _NoteHitResultGood() when good != null:
return good(_that.noteIndex,_that.timingError);case _NoteHitResultOkay() when okay != null:
return okay(_that.noteIndex,_that.timingError);case _NoteHitResultMissed() when missed != null:
return missed(_that.noteIndex);case _NoteHitResultWaiting() when waiting != null:
return waiting(_that.noteIndex);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NoteHitResultPerfect extends NoteHitResult {
  const _NoteHitResultPerfect({required this.noteIndex, required this.timingError, final  String? $type}): $type = $type ?? 'perfect',super._();
  factory _NoteHitResultPerfect.fromJson(Map<String, dynamic> json) => _$NoteHitResultPerfectFromJson(json);

@override final  int noteIndex;
 final  double timingError;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of NoteHitResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NoteHitResultPerfectCopyWith<_NoteHitResultPerfect> get copyWith => __$NoteHitResultPerfectCopyWithImpl<_NoteHitResultPerfect>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NoteHitResultPerfectToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NoteHitResultPerfect&&(identical(other.noteIndex, noteIndex) || other.noteIndex == noteIndex)&&(identical(other.timingError, timingError) || other.timingError == timingError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,noteIndex,timingError);

@override
String toString() {
  return 'NoteHitResult.perfect(noteIndex: $noteIndex, timingError: $timingError)';
}


}

/// @nodoc
abstract mixin class _$NoteHitResultPerfectCopyWith<$Res> implements $NoteHitResultCopyWith<$Res> {
  factory _$NoteHitResultPerfectCopyWith(_NoteHitResultPerfect value, $Res Function(_NoteHitResultPerfect) _then) = __$NoteHitResultPerfectCopyWithImpl;
@override @useResult
$Res call({
 int noteIndex, double timingError
});




}
/// @nodoc
class __$NoteHitResultPerfectCopyWithImpl<$Res>
    implements _$NoteHitResultPerfectCopyWith<$Res> {
  __$NoteHitResultPerfectCopyWithImpl(this._self, this._then);

  final _NoteHitResultPerfect _self;
  final $Res Function(_NoteHitResultPerfect) _then;

/// Create a copy of NoteHitResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? noteIndex = null,Object? timingError = null,}) {
  return _then(_NoteHitResultPerfect(
noteIndex: null == noteIndex ? _self.noteIndex : noteIndex // ignore: cast_nullable_to_non_nullable
as int,timingError: null == timingError ? _self.timingError : timingError // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
@JsonSerializable()

class _NoteHitResultGood extends NoteHitResult {
  const _NoteHitResultGood({required this.noteIndex, required this.timingError, final  String? $type}): $type = $type ?? 'good',super._();
  factory _NoteHitResultGood.fromJson(Map<String, dynamic> json) => _$NoteHitResultGoodFromJson(json);

@override final  int noteIndex;
 final  double timingError;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of NoteHitResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NoteHitResultGoodCopyWith<_NoteHitResultGood> get copyWith => __$NoteHitResultGoodCopyWithImpl<_NoteHitResultGood>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NoteHitResultGoodToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NoteHitResultGood&&(identical(other.noteIndex, noteIndex) || other.noteIndex == noteIndex)&&(identical(other.timingError, timingError) || other.timingError == timingError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,noteIndex,timingError);

@override
String toString() {
  return 'NoteHitResult.good(noteIndex: $noteIndex, timingError: $timingError)';
}


}

/// @nodoc
abstract mixin class _$NoteHitResultGoodCopyWith<$Res> implements $NoteHitResultCopyWith<$Res> {
  factory _$NoteHitResultGoodCopyWith(_NoteHitResultGood value, $Res Function(_NoteHitResultGood) _then) = __$NoteHitResultGoodCopyWithImpl;
@override @useResult
$Res call({
 int noteIndex, double timingError
});




}
/// @nodoc
class __$NoteHitResultGoodCopyWithImpl<$Res>
    implements _$NoteHitResultGoodCopyWith<$Res> {
  __$NoteHitResultGoodCopyWithImpl(this._self, this._then);

  final _NoteHitResultGood _self;
  final $Res Function(_NoteHitResultGood) _then;

/// Create a copy of NoteHitResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? noteIndex = null,Object? timingError = null,}) {
  return _then(_NoteHitResultGood(
noteIndex: null == noteIndex ? _self.noteIndex : noteIndex // ignore: cast_nullable_to_non_nullable
as int,timingError: null == timingError ? _self.timingError : timingError // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
@JsonSerializable()

class _NoteHitResultOkay extends NoteHitResult {
  const _NoteHitResultOkay({required this.noteIndex, required this.timingError, final  String? $type}): $type = $type ?? 'okay',super._();
  factory _NoteHitResultOkay.fromJson(Map<String, dynamic> json) => _$NoteHitResultOkayFromJson(json);

@override final  int noteIndex;
 final  double timingError;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of NoteHitResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NoteHitResultOkayCopyWith<_NoteHitResultOkay> get copyWith => __$NoteHitResultOkayCopyWithImpl<_NoteHitResultOkay>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NoteHitResultOkayToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NoteHitResultOkay&&(identical(other.noteIndex, noteIndex) || other.noteIndex == noteIndex)&&(identical(other.timingError, timingError) || other.timingError == timingError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,noteIndex,timingError);

@override
String toString() {
  return 'NoteHitResult.okay(noteIndex: $noteIndex, timingError: $timingError)';
}


}

/// @nodoc
abstract mixin class _$NoteHitResultOkayCopyWith<$Res> implements $NoteHitResultCopyWith<$Res> {
  factory _$NoteHitResultOkayCopyWith(_NoteHitResultOkay value, $Res Function(_NoteHitResultOkay) _then) = __$NoteHitResultOkayCopyWithImpl;
@override @useResult
$Res call({
 int noteIndex, double timingError
});




}
/// @nodoc
class __$NoteHitResultOkayCopyWithImpl<$Res>
    implements _$NoteHitResultOkayCopyWith<$Res> {
  __$NoteHitResultOkayCopyWithImpl(this._self, this._then);

  final _NoteHitResultOkay _self;
  final $Res Function(_NoteHitResultOkay) _then;

/// Create a copy of NoteHitResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? noteIndex = null,Object? timingError = null,}) {
  return _then(_NoteHitResultOkay(
noteIndex: null == noteIndex ? _self.noteIndex : noteIndex // ignore: cast_nullable_to_non_nullable
as int,timingError: null == timingError ? _self.timingError : timingError // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
@JsonSerializable()

class _NoteHitResultMissed extends NoteHitResult {
  const _NoteHitResultMissed({required this.noteIndex, final  String? $type}): $type = $type ?? 'missed',super._();
  factory _NoteHitResultMissed.fromJson(Map<String, dynamic> json) => _$NoteHitResultMissedFromJson(json);

@override final  int noteIndex;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of NoteHitResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NoteHitResultMissedCopyWith<_NoteHitResultMissed> get copyWith => __$NoteHitResultMissedCopyWithImpl<_NoteHitResultMissed>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NoteHitResultMissedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NoteHitResultMissed&&(identical(other.noteIndex, noteIndex) || other.noteIndex == noteIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,noteIndex);

@override
String toString() {
  return 'NoteHitResult.missed(noteIndex: $noteIndex)';
}


}

/// @nodoc
abstract mixin class _$NoteHitResultMissedCopyWith<$Res> implements $NoteHitResultCopyWith<$Res> {
  factory _$NoteHitResultMissedCopyWith(_NoteHitResultMissed value, $Res Function(_NoteHitResultMissed) _then) = __$NoteHitResultMissedCopyWithImpl;
@override @useResult
$Res call({
 int noteIndex
});




}
/// @nodoc
class __$NoteHitResultMissedCopyWithImpl<$Res>
    implements _$NoteHitResultMissedCopyWith<$Res> {
  __$NoteHitResultMissedCopyWithImpl(this._self, this._then);

  final _NoteHitResultMissed _self;
  final $Res Function(_NoteHitResultMissed) _then;

/// Create a copy of NoteHitResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? noteIndex = null,}) {
  return _then(_NoteHitResultMissed(
noteIndex: null == noteIndex ? _self.noteIndex : noteIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class _NoteHitResultWaiting extends NoteHitResult {
  const _NoteHitResultWaiting({required this.noteIndex, final  String? $type}): $type = $type ?? 'waiting',super._();
  factory _NoteHitResultWaiting.fromJson(Map<String, dynamic> json) => _$NoteHitResultWaitingFromJson(json);

@override final  int noteIndex;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of NoteHitResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NoteHitResultWaitingCopyWith<_NoteHitResultWaiting> get copyWith => __$NoteHitResultWaitingCopyWithImpl<_NoteHitResultWaiting>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NoteHitResultWaitingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NoteHitResultWaiting&&(identical(other.noteIndex, noteIndex) || other.noteIndex == noteIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,noteIndex);

@override
String toString() {
  return 'NoteHitResult.waiting(noteIndex: $noteIndex)';
}


}

/// @nodoc
abstract mixin class _$NoteHitResultWaitingCopyWith<$Res> implements $NoteHitResultCopyWith<$Res> {
  factory _$NoteHitResultWaitingCopyWith(_NoteHitResultWaiting value, $Res Function(_NoteHitResultWaiting) _then) = __$NoteHitResultWaitingCopyWithImpl;
@override @useResult
$Res call({
 int noteIndex
});




}
/// @nodoc
class __$NoteHitResultWaitingCopyWithImpl<$Res>
    implements _$NoteHitResultWaitingCopyWith<$Res> {
  __$NoteHitResultWaitingCopyWithImpl(this._self, this._then);

  final _NoteHitResultWaiting _self;
  final $Res Function(_NoteHitResultWaiting) _then;

/// Create a copy of NoteHitResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? noteIndex = null,}) {
  return _then(_NoteHitResultWaiting(
noteIndex: null == noteIndex ? _self.noteIndex : noteIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

StageEvent _$StageEventFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'noteHit':
          return _StageEventNoteHit.fromJson(
            json
          );
                case 'noteMissed':
          return _StageEventNoteMissed.fromJson(
            json
          );
                case 'stageCompleted':
          return _StageEventStageCompleted.fromJson(
            json
          );
                case 'playbackPosition':
          return _StageEventPlaybackPosition.fromJson(
            json
          );
                case 'stateChanged':
          return _StageEventStateChanged.fromJson(
            json
          );
                case 'beat':
          return _StageEventBeat.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'StageEvent',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$StageEvent {



  /// Serializes this StageEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StageEvent);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StageEvent()';
}


}

/// @nodoc
class $StageEventCopyWith<$Res>  {
$StageEventCopyWith(StageEvent _, $Res Function(StageEvent) __);
}


/// Adds pattern-matching-related methods to [StageEvent].
extension StageEventPatterns on StageEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _StageEventNoteHit value)?  noteHit,TResult Function( _StageEventNoteMissed value)?  noteMissed,TResult Function( _StageEventStageCompleted value)?  stageCompleted,TResult Function( _StageEventPlaybackPosition value)?  playbackPosition,TResult Function( _StageEventStateChanged value)?  stateChanged,TResult Function( _StageEventBeat value)?  beat,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StageEventNoteHit() when noteHit != null:
return noteHit(_that);case _StageEventNoteMissed() when noteMissed != null:
return noteMissed(_that);case _StageEventStageCompleted() when stageCompleted != null:
return stageCompleted(_that);case _StageEventPlaybackPosition() when playbackPosition != null:
return playbackPosition(_that);case _StageEventStateChanged() when stateChanged != null:
return stateChanged(_that);case _StageEventBeat() when beat != null:
return beat(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _StageEventNoteHit value)  noteHit,required TResult Function( _StageEventNoteMissed value)  noteMissed,required TResult Function( _StageEventStageCompleted value)  stageCompleted,required TResult Function( _StageEventPlaybackPosition value)  playbackPosition,required TResult Function( _StageEventStateChanged value)  stateChanged,required TResult Function( _StageEventBeat value)  beat,}){
final _that = this;
switch (_that) {
case _StageEventNoteHit():
return noteHit(_that);case _StageEventNoteMissed():
return noteMissed(_that);case _StageEventStageCompleted():
return stageCompleted(_that);case _StageEventPlaybackPosition():
return playbackPosition(_that);case _StageEventStateChanged():
return stateChanged(_that);case _StageEventBeat():
return beat(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _StageEventNoteHit value)?  noteHit,TResult? Function( _StageEventNoteMissed value)?  noteMissed,TResult? Function( _StageEventStageCompleted value)?  stageCompleted,TResult? Function( _StageEventPlaybackPosition value)?  playbackPosition,TResult? Function( _StageEventStateChanged value)?  stateChanged,TResult? Function( _StageEventBeat value)?  beat,}){
final _that = this;
switch (_that) {
case _StageEventNoteHit() when noteHit != null:
return noteHit(_that);case _StageEventNoteMissed() when noteMissed != null:
return noteMissed(_that);case _StageEventStageCompleted() when stageCompleted != null:
return stageCompleted(_that);case _StageEventPlaybackPosition() when playbackPosition != null:
return playbackPosition(_that);case _StageEventStateChanged() when stateChanged != null:
return stateChanged(_that);case _StageEventBeat() when beat != null:
return beat(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int noteIndex,  NoteHitResult result,  double currentBeat)?  noteHit,TResult Function( int noteIndex,  double currentBeat)?  noteMissed,TResult Function( double accuracy,  int score,  int totalNotes,  int hitNotes)?  stageCompleted,TResult Function( double currentBeat,  double progress,  bool isPlaying)?  playbackPosition,TResult Function( StageEngineStatus state)?  stateChanged,TResult Function( double beat,  MetronomeBeatType beatType,  int measureIndex,  int beatInMeasure,  bool isCountIn)?  beat,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StageEventNoteHit() when noteHit != null:
return noteHit(_that.noteIndex,_that.result,_that.currentBeat);case _StageEventNoteMissed() when noteMissed != null:
return noteMissed(_that.noteIndex,_that.currentBeat);case _StageEventStageCompleted() when stageCompleted != null:
return stageCompleted(_that.accuracy,_that.score,_that.totalNotes,_that.hitNotes);case _StageEventPlaybackPosition() when playbackPosition != null:
return playbackPosition(_that.currentBeat,_that.progress,_that.isPlaying);case _StageEventStateChanged() when stateChanged != null:
return stateChanged(_that.state);case _StageEventBeat() when beat != null:
return beat(_that.beat,_that.beatType,_that.measureIndex,_that.beatInMeasure,_that.isCountIn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int noteIndex,  NoteHitResult result,  double currentBeat)  noteHit,required TResult Function( int noteIndex,  double currentBeat)  noteMissed,required TResult Function( double accuracy,  int score,  int totalNotes,  int hitNotes)  stageCompleted,required TResult Function( double currentBeat,  double progress,  bool isPlaying)  playbackPosition,required TResult Function( StageEngineStatus state)  stateChanged,required TResult Function( double beat,  MetronomeBeatType beatType,  int measureIndex,  int beatInMeasure,  bool isCountIn)  beat,}) {final _that = this;
switch (_that) {
case _StageEventNoteHit():
return noteHit(_that.noteIndex,_that.result,_that.currentBeat);case _StageEventNoteMissed():
return noteMissed(_that.noteIndex,_that.currentBeat);case _StageEventStageCompleted():
return stageCompleted(_that.accuracy,_that.score,_that.totalNotes,_that.hitNotes);case _StageEventPlaybackPosition():
return playbackPosition(_that.currentBeat,_that.progress,_that.isPlaying);case _StageEventStateChanged():
return stateChanged(_that.state);case _StageEventBeat():
return beat(_that.beat,_that.beatType,_that.measureIndex,_that.beatInMeasure,_that.isCountIn);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int noteIndex,  NoteHitResult result,  double currentBeat)?  noteHit,TResult? Function( int noteIndex,  double currentBeat)?  noteMissed,TResult? Function( double accuracy,  int score,  int totalNotes,  int hitNotes)?  stageCompleted,TResult? Function( double currentBeat,  double progress,  bool isPlaying)?  playbackPosition,TResult? Function( StageEngineStatus state)?  stateChanged,TResult? Function( double beat,  MetronomeBeatType beatType,  int measureIndex,  int beatInMeasure,  bool isCountIn)?  beat,}) {final _that = this;
switch (_that) {
case _StageEventNoteHit() when noteHit != null:
return noteHit(_that.noteIndex,_that.result,_that.currentBeat);case _StageEventNoteMissed() when noteMissed != null:
return noteMissed(_that.noteIndex,_that.currentBeat);case _StageEventStageCompleted() when stageCompleted != null:
return stageCompleted(_that.accuracy,_that.score,_that.totalNotes,_that.hitNotes);case _StageEventPlaybackPosition() when playbackPosition != null:
return playbackPosition(_that.currentBeat,_that.progress,_that.isPlaying);case _StageEventStateChanged() when stateChanged != null:
return stateChanged(_that.state);case _StageEventBeat() when beat != null:
return beat(_that.beat,_that.beatType,_that.measureIndex,_that.beatInMeasure,_that.isCountIn);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StageEventNoteHit implements StageEvent {
  const _StageEventNoteHit({required this.noteIndex, required this.result, required this.currentBeat, final  String? $type}): $type = $type ?? 'noteHit';
  factory _StageEventNoteHit.fromJson(Map<String, dynamic> json) => _$StageEventNoteHitFromJson(json);

 final  int noteIndex;
 final  NoteHitResult result;
 final  double currentBeat;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of StageEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StageEventNoteHitCopyWith<_StageEventNoteHit> get copyWith => __$StageEventNoteHitCopyWithImpl<_StageEventNoteHit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StageEventNoteHitToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StageEventNoteHit&&(identical(other.noteIndex, noteIndex) || other.noteIndex == noteIndex)&&(identical(other.result, result) || other.result == result)&&(identical(other.currentBeat, currentBeat) || other.currentBeat == currentBeat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,noteIndex,result,currentBeat);

@override
String toString() {
  return 'StageEvent.noteHit(noteIndex: $noteIndex, result: $result, currentBeat: $currentBeat)';
}


}

/// @nodoc
abstract mixin class _$StageEventNoteHitCopyWith<$Res> implements $StageEventCopyWith<$Res> {
  factory _$StageEventNoteHitCopyWith(_StageEventNoteHit value, $Res Function(_StageEventNoteHit) _then) = __$StageEventNoteHitCopyWithImpl;
@useResult
$Res call({
 int noteIndex, NoteHitResult result, double currentBeat
});


$NoteHitResultCopyWith<$Res> get result;

}
/// @nodoc
class __$StageEventNoteHitCopyWithImpl<$Res>
    implements _$StageEventNoteHitCopyWith<$Res> {
  __$StageEventNoteHitCopyWithImpl(this._self, this._then);

  final _StageEventNoteHit _self;
  final $Res Function(_StageEventNoteHit) _then;

/// Create a copy of StageEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? noteIndex = null,Object? result = null,Object? currentBeat = null,}) {
  return _then(_StageEventNoteHit(
noteIndex: null == noteIndex ? _self.noteIndex : noteIndex // ignore: cast_nullable_to_non_nullable
as int,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as NoteHitResult,currentBeat: null == currentBeat ? _self.currentBeat : currentBeat // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

/// Create a copy of StageEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NoteHitResultCopyWith<$Res> get result {
  
  return $NoteHitResultCopyWith<$Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class _StageEventNoteMissed implements StageEvent {
  const _StageEventNoteMissed({required this.noteIndex, required this.currentBeat, final  String? $type}): $type = $type ?? 'noteMissed';
  factory _StageEventNoteMissed.fromJson(Map<String, dynamic> json) => _$StageEventNoteMissedFromJson(json);

 final  int noteIndex;
 final  double currentBeat;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of StageEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StageEventNoteMissedCopyWith<_StageEventNoteMissed> get copyWith => __$StageEventNoteMissedCopyWithImpl<_StageEventNoteMissed>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StageEventNoteMissedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StageEventNoteMissed&&(identical(other.noteIndex, noteIndex) || other.noteIndex == noteIndex)&&(identical(other.currentBeat, currentBeat) || other.currentBeat == currentBeat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,noteIndex,currentBeat);

@override
String toString() {
  return 'StageEvent.noteMissed(noteIndex: $noteIndex, currentBeat: $currentBeat)';
}


}

/// @nodoc
abstract mixin class _$StageEventNoteMissedCopyWith<$Res> implements $StageEventCopyWith<$Res> {
  factory _$StageEventNoteMissedCopyWith(_StageEventNoteMissed value, $Res Function(_StageEventNoteMissed) _then) = __$StageEventNoteMissedCopyWithImpl;
@useResult
$Res call({
 int noteIndex, double currentBeat
});




}
/// @nodoc
class __$StageEventNoteMissedCopyWithImpl<$Res>
    implements _$StageEventNoteMissedCopyWith<$Res> {
  __$StageEventNoteMissedCopyWithImpl(this._self, this._then);

  final _StageEventNoteMissed _self;
  final $Res Function(_StageEventNoteMissed) _then;

/// Create a copy of StageEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? noteIndex = null,Object? currentBeat = null,}) {
  return _then(_StageEventNoteMissed(
noteIndex: null == noteIndex ? _self.noteIndex : noteIndex // ignore: cast_nullable_to_non_nullable
as int,currentBeat: null == currentBeat ? _self.currentBeat : currentBeat // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
@JsonSerializable()

class _StageEventStageCompleted implements StageEvent {
  const _StageEventStageCompleted({required this.accuracy, required this.score, required this.totalNotes, required this.hitNotes, final  String? $type}): $type = $type ?? 'stageCompleted';
  factory _StageEventStageCompleted.fromJson(Map<String, dynamic> json) => _$StageEventStageCompletedFromJson(json);

 final  double accuracy;
 final  int score;
 final  int totalNotes;
 final  int hitNotes;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of StageEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StageEventStageCompletedCopyWith<_StageEventStageCompleted> get copyWith => __$StageEventStageCompletedCopyWithImpl<_StageEventStageCompleted>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StageEventStageCompletedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StageEventStageCompleted&&(identical(other.accuracy, accuracy) || other.accuracy == accuracy)&&(identical(other.score, score) || other.score == score)&&(identical(other.totalNotes, totalNotes) || other.totalNotes == totalNotes)&&(identical(other.hitNotes, hitNotes) || other.hitNotes == hitNotes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accuracy,score,totalNotes,hitNotes);

@override
String toString() {
  return 'StageEvent.stageCompleted(accuracy: $accuracy, score: $score, totalNotes: $totalNotes, hitNotes: $hitNotes)';
}


}

/// @nodoc
abstract mixin class _$StageEventStageCompletedCopyWith<$Res> implements $StageEventCopyWith<$Res> {
  factory _$StageEventStageCompletedCopyWith(_StageEventStageCompleted value, $Res Function(_StageEventStageCompleted) _then) = __$StageEventStageCompletedCopyWithImpl;
@useResult
$Res call({
 double accuracy, int score, int totalNotes, int hitNotes
});




}
/// @nodoc
class __$StageEventStageCompletedCopyWithImpl<$Res>
    implements _$StageEventStageCompletedCopyWith<$Res> {
  __$StageEventStageCompletedCopyWithImpl(this._self, this._then);

  final _StageEventStageCompleted _self;
  final $Res Function(_StageEventStageCompleted) _then;

/// Create a copy of StageEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? accuracy = null,Object? score = null,Object? totalNotes = null,Object? hitNotes = null,}) {
  return _then(_StageEventStageCompleted(
accuracy: null == accuracy ? _self.accuracy : accuracy // ignore: cast_nullable_to_non_nullable
as double,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,totalNotes: null == totalNotes ? _self.totalNotes : totalNotes // ignore: cast_nullable_to_non_nullable
as int,hitNotes: null == hitNotes ? _self.hitNotes : hitNotes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class _StageEventPlaybackPosition implements StageEvent {
  const _StageEventPlaybackPosition({required this.currentBeat, required this.progress, required this.isPlaying, final  String? $type}): $type = $type ?? 'playbackPosition';
  factory _StageEventPlaybackPosition.fromJson(Map<String, dynamic> json) => _$StageEventPlaybackPositionFromJson(json);

 final  double currentBeat;
 final  double progress;
// 0.0 - 1.0
 final  bool isPlaying;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of StageEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StageEventPlaybackPositionCopyWith<_StageEventPlaybackPosition> get copyWith => __$StageEventPlaybackPositionCopyWithImpl<_StageEventPlaybackPosition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StageEventPlaybackPositionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StageEventPlaybackPosition&&(identical(other.currentBeat, currentBeat) || other.currentBeat == currentBeat)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currentBeat,progress,isPlaying);

@override
String toString() {
  return 'StageEvent.playbackPosition(currentBeat: $currentBeat, progress: $progress, isPlaying: $isPlaying)';
}


}

/// @nodoc
abstract mixin class _$StageEventPlaybackPositionCopyWith<$Res> implements $StageEventCopyWith<$Res> {
  factory _$StageEventPlaybackPositionCopyWith(_StageEventPlaybackPosition value, $Res Function(_StageEventPlaybackPosition) _then) = __$StageEventPlaybackPositionCopyWithImpl;
@useResult
$Res call({
 double currentBeat, double progress, bool isPlaying
});




}
/// @nodoc
class __$StageEventPlaybackPositionCopyWithImpl<$Res>
    implements _$StageEventPlaybackPositionCopyWith<$Res> {
  __$StageEventPlaybackPositionCopyWithImpl(this._self, this._then);

  final _StageEventPlaybackPosition _self;
  final $Res Function(_StageEventPlaybackPosition) _then;

/// Create a copy of StageEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? currentBeat = null,Object? progress = null,Object? isPlaying = null,}) {
  return _then(_StageEventPlaybackPosition(
currentBeat: null == currentBeat ? _self.currentBeat : currentBeat // ignore: cast_nullable_to_non_nullable
as double,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
@JsonSerializable()

class _StageEventStateChanged implements StageEvent {
  const _StageEventStateChanged({required this.state, final  String? $type}): $type = $type ?? 'stateChanged';
  factory _StageEventStateChanged.fromJson(Map<String, dynamic> json) => _$StageEventStateChangedFromJson(json);

 final  StageEngineStatus state;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of StageEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StageEventStateChangedCopyWith<_StageEventStateChanged> get copyWith => __$StageEventStateChangedCopyWithImpl<_StageEventStateChanged>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StageEventStateChangedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StageEventStateChanged&&(identical(other.state, state) || other.state == state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,state);

@override
String toString() {
  return 'StageEvent.stateChanged(state: $state)';
}


}

/// @nodoc
abstract mixin class _$StageEventStateChangedCopyWith<$Res> implements $StageEventCopyWith<$Res> {
  factory _$StageEventStateChangedCopyWith(_StageEventStateChanged value, $Res Function(_StageEventStateChanged) _then) = __$StageEventStateChangedCopyWithImpl;
@useResult
$Res call({
 StageEngineStatus state
});




}
/// @nodoc
class __$StageEventStateChangedCopyWithImpl<$Res>
    implements _$StageEventStateChangedCopyWith<$Res> {
  __$StageEventStateChangedCopyWithImpl(this._self, this._then);

  final _StageEventStateChanged _self;
  final $Res Function(_StageEventStateChanged) _then;

/// Create a copy of StageEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? state = null,}) {
  return _then(_StageEventStateChanged(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as StageEngineStatus,
  ));
}


}

/// @nodoc
@JsonSerializable()

class _StageEventBeat implements StageEvent {
  const _StageEventBeat({required this.beat, required this.beatType, required this.measureIndex, required this.beatInMeasure, this.isCountIn = false, final  String? $type}): $type = $type ?? 'beat';
  factory _StageEventBeat.fromJson(Map<String, dynamic> json) => _$StageEventBeatFromJson(json);

 final  double beat;
 final  MetronomeBeatType beatType;
 final  int measureIndex;
 final  int beatInMeasure;
@JsonKey() final  bool isCountIn;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of StageEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StageEventBeatCopyWith<_StageEventBeat> get copyWith => __$StageEventBeatCopyWithImpl<_StageEventBeat>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StageEventBeatToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StageEventBeat&&(identical(other.beat, beat) || other.beat == beat)&&(identical(other.beatType, beatType) || other.beatType == beatType)&&(identical(other.measureIndex, measureIndex) || other.measureIndex == measureIndex)&&(identical(other.beatInMeasure, beatInMeasure) || other.beatInMeasure == beatInMeasure)&&(identical(other.isCountIn, isCountIn) || other.isCountIn == isCountIn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,beat,beatType,measureIndex,beatInMeasure,isCountIn);

@override
String toString() {
  return 'StageEvent.beat(beat: $beat, beatType: $beatType, measureIndex: $measureIndex, beatInMeasure: $beatInMeasure, isCountIn: $isCountIn)';
}


}

/// @nodoc
abstract mixin class _$StageEventBeatCopyWith<$Res> implements $StageEventCopyWith<$Res> {
  factory _$StageEventBeatCopyWith(_StageEventBeat value, $Res Function(_StageEventBeat) _then) = __$StageEventBeatCopyWithImpl;
@useResult
$Res call({
 double beat, MetronomeBeatType beatType, int measureIndex, int beatInMeasure, bool isCountIn
});




}
/// @nodoc
class __$StageEventBeatCopyWithImpl<$Res>
    implements _$StageEventBeatCopyWith<$Res> {
  __$StageEventBeatCopyWithImpl(this._self, this._then);

  final _StageEventBeat _self;
  final $Res Function(_StageEventBeat) _then;

/// Create a copy of StageEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? beat = null,Object? beatType = null,Object? measureIndex = null,Object? beatInMeasure = null,Object? isCountIn = null,}) {
  return _then(_StageEventBeat(
beat: null == beat ? _self.beat : beat // ignore: cast_nullable_to_non_nullable
as double,beatType: null == beatType ? _self.beatType : beatType // ignore: cast_nullable_to_non_nullable
as MetronomeBeatType,measureIndex: null == measureIndex ? _self.measureIndex : measureIndex // ignore: cast_nullable_to_non_nullable
as int,beatInMeasure: null == beatInMeasure ? _self.beatInMeasure : beatInMeasure // ignore: cast_nullable_to_non_nullable
as int,isCountIn: null == isCountIn ? _self.isCountIn : isCountIn // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$StageEngineConfig {

 double get perfectWindow;// beats (early/late tolerance for perfect)
 double get goodWindow;// beats for good
 double get okayWindow;// beats for okay
 double get missWindow;// beats after which note is missed
 bool get autoAdvance;// auto-advance playhead
 double get playbackSpeed;// speed multiplier
 double get inputLatency;// seconds of input/buffer latency compensation
 PracticeMode get practiceMode; bool get metronomeEnabled; bool get countInEnabled;
/// Create a copy of StageEngineConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StageEngineConfigCopyWith<StageEngineConfig> get copyWith => _$StageEngineConfigCopyWithImpl<StageEngineConfig>(this as StageEngineConfig, _$identity);

  /// Serializes this StageEngineConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StageEngineConfig&&(identical(other.perfectWindow, perfectWindow) || other.perfectWindow == perfectWindow)&&(identical(other.goodWindow, goodWindow) || other.goodWindow == goodWindow)&&(identical(other.okayWindow, okayWindow) || other.okayWindow == okayWindow)&&(identical(other.missWindow, missWindow) || other.missWindow == missWindow)&&(identical(other.autoAdvance, autoAdvance) || other.autoAdvance == autoAdvance)&&(identical(other.playbackSpeed, playbackSpeed) || other.playbackSpeed == playbackSpeed)&&(identical(other.inputLatency, inputLatency) || other.inputLatency == inputLatency)&&(identical(other.practiceMode, practiceMode) || other.practiceMode == practiceMode)&&(identical(other.metronomeEnabled, metronomeEnabled) || other.metronomeEnabled == metronomeEnabled)&&(identical(other.countInEnabled, countInEnabled) || other.countInEnabled == countInEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,perfectWindow,goodWindow,okayWindow,missWindow,autoAdvance,playbackSpeed,inputLatency,practiceMode,metronomeEnabled,countInEnabled);

@override
String toString() {
  return 'StageEngineConfig(perfectWindow: $perfectWindow, goodWindow: $goodWindow, okayWindow: $okayWindow, missWindow: $missWindow, autoAdvance: $autoAdvance, playbackSpeed: $playbackSpeed, inputLatency: $inputLatency, practiceMode: $practiceMode, metronomeEnabled: $metronomeEnabled, countInEnabled: $countInEnabled)';
}


}

/// @nodoc
abstract mixin class $StageEngineConfigCopyWith<$Res>  {
  factory $StageEngineConfigCopyWith(StageEngineConfig value, $Res Function(StageEngineConfig) _then) = _$StageEngineConfigCopyWithImpl;
@useResult
$Res call({
 double perfectWindow, double goodWindow, double okayWindow, double missWindow, bool autoAdvance, double playbackSpeed, double inputLatency, PracticeMode practiceMode, bool metronomeEnabled, bool countInEnabled
});




}
/// @nodoc
class _$StageEngineConfigCopyWithImpl<$Res>
    implements $StageEngineConfigCopyWith<$Res> {
  _$StageEngineConfigCopyWithImpl(this._self, this._then);

  final StageEngineConfig _self;
  final $Res Function(StageEngineConfig) _then;

/// Create a copy of StageEngineConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? perfectWindow = null,Object? goodWindow = null,Object? okayWindow = null,Object? missWindow = null,Object? autoAdvance = null,Object? playbackSpeed = null,Object? inputLatency = null,Object? practiceMode = null,Object? metronomeEnabled = null,Object? countInEnabled = null,}) {
  return _then(_self.copyWith(
perfectWindow: null == perfectWindow ? _self.perfectWindow : perfectWindow // ignore: cast_nullable_to_non_nullable
as double,goodWindow: null == goodWindow ? _self.goodWindow : goodWindow // ignore: cast_nullable_to_non_nullable
as double,okayWindow: null == okayWindow ? _self.okayWindow : okayWindow // ignore: cast_nullable_to_non_nullable
as double,missWindow: null == missWindow ? _self.missWindow : missWindow // ignore: cast_nullable_to_non_nullable
as double,autoAdvance: null == autoAdvance ? _self.autoAdvance : autoAdvance // ignore: cast_nullable_to_non_nullable
as bool,playbackSpeed: null == playbackSpeed ? _self.playbackSpeed : playbackSpeed // ignore: cast_nullable_to_non_nullable
as double,inputLatency: null == inputLatency ? _self.inputLatency : inputLatency // ignore: cast_nullable_to_non_nullable
as double,practiceMode: null == practiceMode ? _self.practiceMode : practiceMode // ignore: cast_nullable_to_non_nullable
as PracticeMode,metronomeEnabled: null == metronomeEnabled ? _self.metronomeEnabled : metronomeEnabled // ignore: cast_nullable_to_non_nullable
as bool,countInEnabled: null == countInEnabled ? _self.countInEnabled : countInEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [StageEngineConfig].
extension StageEngineConfigPatterns on StageEngineConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StageEngineConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StageEngineConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StageEngineConfig value)  $default,){
final _that = this;
switch (_that) {
case _StageEngineConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StageEngineConfig value)?  $default,){
final _that = this;
switch (_that) {
case _StageEngineConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double perfectWindow,  double goodWindow,  double okayWindow,  double missWindow,  bool autoAdvance,  double playbackSpeed,  double inputLatency,  PracticeMode practiceMode,  bool metronomeEnabled,  bool countInEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StageEngineConfig() when $default != null:
return $default(_that.perfectWindow,_that.goodWindow,_that.okayWindow,_that.missWindow,_that.autoAdvance,_that.playbackSpeed,_that.inputLatency,_that.practiceMode,_that.metronomeEnabled,_that.countInEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double perfectWindow,  double goodWindow,  double okayWindow,  double missWindow,  bool autoAdvance,  double playbackSpeed,  double inputLatency,  PracticeMode practiceMode,  bool metronomeEnabled,  bool countInEnabled)  $default,) {final _that = this;
switch (_that) {
case _StageEngineConfig():
return $default(_that.perfectWindow,_that.goodWindow,_that.okayWindow,_that.missWindow,_that.autoAdvance,_that.playbackSpeed,_that.inputLatency,_that.practiceMode,_that.metronomeEnabled,_that.countInEnabled);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double perfectWindow,  double goodWindow,  double okayWindow,  double missWindow,  bool autoAdvance,  double playbackSpeed,  double inputLatency,  PracticeMode practiceMode,  bool metronomeEnabled,  bool countInEnabled)?  $default,) {final _that = this;
switch (_that) {
case _StageEngineConfig() when $default != null:
return $default(_that.perfectWindow,_that.goodWindow,_that.okayWindow,_that.missWindow,_that.autoAdvance,_that.playbackSpeed,_that.inputLatency,_that.practiceMode,_that.metronomeEnabled,_that.countInEnabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StageEngineConfig implements StageEngineConfig {
  const _StageEngineConfig({this.perfectWindow = 0.1, this.goodWindow = 0.2, this.okayWindow = 0.3, this.missWindow = 0.5, this.autoAdvance = true, this.playbackSpeed = 1.0, this.inputLatency = 0.0, this.practiceMode = PracticeMode.timed, this.metronomeEnabled = false, this.countInEnabled = false});
  factory _StageEngineConfig.fromJson(Map<String, dynamic> json) => _$StageEngineConfigFromJson(json);

@override@JsonKey() final  double perfectWindow;
// beats (early/late tolerance for perfect)
@override@JsonKey() final  double goodWindow;
// beats for good
@override@JsonKey() final  double okayWindow;
// beats for okay
@override@JsonKey() final  double missWindow;
// beats after which note is missed
@override@JsonKey() final  bool autoAdvance;
// auto-advance playhead
@override@JsonKey() final  double playbackSpeed;
// speed multiplier
@override@JsonKey() final  double inputLatency;
// seconds of input/buffer latency compensation
@override@JsonKey() final  PracticeMode practiceMode;
@override@JsonKey() final  bool metronomeEnabled;
@override@JsonKey() final  bool countInEnabled;

/// Create a copy of StageEngineConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StageEngineConfigCopyWith<_StageEngineConfig> get copyWith => __$StageEngineConfigCopyWithImpl<_StageEngineConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StageEngineConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StageEngineConfig&&(identical(other.perfectWindow, perfectWindow) || other.perfectWindow == perfectWindow)&&(identical(other.goodWindow, goodWindow) || other.goodWindow == goodWindow)&&(identical(other.okayWindow, okayWindow) || other.okayWindow == okayWindow)&&(identical(other.missWindow, missWindow) || other.missWindow == missWindow)&&(identical(other.autoAdvance, autoAdvance) || other.autoAdvance == autoAdvance)&&(identical(other.playbackSpeed, playbackSpeed) || other.playbackSpeed == playbackSpeed)&&(identical(other.inputLatency, inputLatency) || other.inputLatency == inputLatency)&&(identical(other.practiceMode, practiceMode) || other.practiceMode == practiceMode)&&(identical(other.metronomeEnabled, metronomeEnabled) || other.metronomeEnabled == metronomeEnabled)&&(identical(other.countInEnabled, countInEnabled) || other.countInEnabled == countInEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,perfectWindow,goodWindow,okayWindow,missWindow,autoAdvance,playbackSpeed,inputLatency,practiceMode,metronomeEnabled,countInEnabled);

@override
String toString() {
  return 'StageEngineConfig(perfectWindow: $perfectWindow, goodWindow: $goodWindow, okayWindow: $okayWindow, missWindow: $missWindow, autoAdvance: $autoAdvance, playbackSpeed: $playbackSpeed, inputLatency: $inputLatency, practiceMode: $practiceMode, metronomeEnabled: $metronomeEnabled, countInEnabled: $countInEnabled)';
}


}

/// @nodoc
abstract mixin class _$StageEngineConfigCopyWith<$Res> implements $StageEngineConfigCopyWith<$Res> {
  factory _$StageEngineConfigCopyWith(_StageEngineConfig value, $Res Function(_StageEngineConfig) _then) = __$StageEngineConfigCopyWithImpl;
@override @useResult
$Res call({
 double perfectWindow, double goodWindow, double okayWindow, double missWindow, bool autoAdvance, double playbackSpeed, double inputLatency, PracticeMode practiceMode, bool metronomeEnabled, bool countInEnabled
});




}
/// @nodoc
class __$StageEngineConfigCopyWithImpl<$Res>
    implements _$StageEngineConfigCopyWith<$Res> {
  __$StageEngineConfigCopyWithImpl(this._self, this._then);

  final _StageEngineConfig _self;
  final $Res Function(_StageEngineConfig) _then;

/// Create a copy of StageEngineConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? perfectWindow = null,Object? goodWindow = null,Object? okayWindow = null,Object? missWindow = null,Object? autoAdvance = null,Object? playbackSpeed = null,Object? inputLatency = null,Object? practiceMode = null,Object? metronomeEnabled = null,Object? countInEnabled = null,}) {
  return _then(_StageEngineConfig(
perfectWindow: null == perfectWindow ? _self.perfectWindow : perfectWindow // ignore: cast_nullable_to_non_nullable
as double,goodWindow: null == goodWindow ? _self.goodWindow : goodWindow // ignore: cast_nullable_to_non_nullable
as double,okayWindow: null == okayWindow ? _self.okayWindow : okayWindow // ignore: cast_nullable_to_non_nullable
as double,missWindow: null == missWindow ? _self.missWindow : missWindow // ignore: cast_nullable_to_non_nullable
as double,autoAdvance: null == autoAdvance ? _self.autoAdvance : autoAdvance // ignore: cast_nullable_to_non_nullable
as bool,playbackSpeed: null == playbackSpeed ? _self.playbackSpeed : playbackSpeed // ignore: cast_nullable_to_non_nullable
as double,inputLatency: null == inputLatency ? _self.inputLatency : inputLatency // ignore: cast_nullable_to_non_nullable
as double,practiceMode: null == practiceMode ? _self.practiceMode : practiceMode // ignore: cast_nullable_to_non_nullable
as PracticeMode,metronomeEnabled: null == metronomeEnabled ? _self.metronomeEnabled : metronomeEnabled // ignore: cast_nullable_to_non_nullable
as bool,countInEnabled: null == countInEnabled ? _self.countInEnabled : countInEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$StageEngineStateModel {

 StageEngineStatus get engineState; LevelModel get level; double get currentBeat; List<NoteState> get noteStates; int get score; int get hitCount; int get missCount; int get perfectCount; int get goodCount; int get okayCount; PracticeMode get practiceMode; WaitingHint? get waitingHint; bool get isCountingIn; int? get countInBeat;
/// Create a copy of StageEngineStateModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StageEngineStateModelCopyWith<StageEngineStateModel> get copyWith => _$StageEngineStateModelCopyWithImpl<StageEngineStateModel>(this as StageEngineStateModel, _$identity);

  /// Serializes this StageEngineStateModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StageEngineStateModel&&(identical(other.engineState, engineState) || other.engineState == engineState)&&(identical(other.level, level) || other.level == level)&&(identical(other.currentBeat, currentBeat) || other.currentBeat == currentBeat)&&const DeepCollectionEquality().equals(other.noteStates, noteStates)&&(identical(other.score, score) || other.score == score)&&(identical(other.hitCount, hitCount) || other.hitCount == hitCount)&&(identical(other.missCount, missCount) || other.missCount == missCount)&&(identical(other.perfectCount, perfectCount) || other.perfectCount == perfectCount)&&(identical(other.goodCount, goodCount) || other.goodCount == goodCount)&&(identical(other.okayCount, okayCount) || other.okayCount == okayCount)&&(identical(other.practiceMode, practiceMode) || other.practiceMode == practiceMode)&&(identical(other.waitingHint, waitingHint) || other.waitingHint == waitingHint)&&(identical(other.isCountingIn, isCountingIn) || other.isCountingIn == isCountingIn)&&(identical(other.countInBeat, countInBeat) || other.countInBeat == countInBeat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,engineState,level,currentBeat,const DeepCollectionEquality().hash(noteStates),score,hitCount,missCount,perfectCount,goodCount,okayCount,practiceMode,waitingHint,isCountingIn,countInBeat);

@override
String toString() {
  return 'StageEngineStateModel(engineState: $engineState, level: $level, currentBeat: $currentBeat, noteStates: $noteStates, score: $score, hitCount: $hitCount, missCount: $missCount, perfectCount: $perfectCount, goodCount: $goodCount, okayCount: $okayCount, practiceMode: $practiceMode, waitingHint: $waitingHint, isCountingIn: $isCountingIn, countInBeat: $countInBeat)';
}


}

/// @nodoc
abstract mixin class $StageEngineStateModelCopyWith<$Res>  {
  factory $StageEngineStateModelCopyWith(StageEngineStateModel value, $Res Function(StageEngineStateModel) _then) = _$StageEngineStateModelCopyWithImpl;
@useResult
$Res call({
 StageEngineStatus engineState, LevelModel level, double currentBeat, List<NoteState> noteStates, int score, int hitCount, int missCount, int perfectCount, int goodCount, int okayCount, PracticeMode practiceMode, WaitingHint? waitingHint, bool isCountingIn, int? countInBeat
});


$LevelModelCopyWith<$Res> get level;$WaitingHintCopyWith<$Res>? get waitingHint;

}
/// @nodoc
class _$StageEngineStateModelCopyWithImpl<$Res>
    implements $StageEngineStateModelCopyWith<$Res> {
  _$StageEngineStateModelCopyWithImpl(this._self, this._then);

  final StageEngineStateModel _self;
  final $Res Function(StageEngineStateModel) _then;

/// Create a copy of StageEngineStateModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? engineState = null,Object? level = null,Object? currentBeat = null,Object? noteStates = null,Object? score = null,Object? hitCount = null,Object? missCount = null,Object? perfectCount = null,Object? goodCount = null,Object? okayCount = null,Object? practiceMode = null,Object? waitingHint = freezed,Object? isCountingIn = null,Object? countInBeat = freezed,}) {
  return _then(_self.copyWith(
engineState: null == engineState ? _self.engineState : engineState // ignore: cast_nullable_to_non_nullable
as StageEngineStatus,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as LevelModel,currentBeat: null == currentBeat ? _self.currentBeat : currentBeat // ignore: cast_nullable_to_non_nullable
as double,noteStates: null == noteStates ? _self.noteStates : noteStates // ignore: cast_nullable_to_non_nullable
as List<NoteState>,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,hitCount: null == hitCount ? _self.hitCount : hitCount // ignore: cast_nullable_to_non_nullable
as int,missCount: null == missCount ? _self.missCount : missCount // ignore: cast_nullable_to_non_nullable
as int,perfectCount: null == perfectCount ? _self.perfectCount : perfectCount // ignore: cast_nullable_to_non_nullable
as int,goodCount: null == goodCount ? _self.goodCount : goodCount // ignore: cast_nullable_to_non_nullable
as int,okayCount: null == okayCount ? _self.okayCount : okayCount // ignore: cast_nullable_to_non_nullable
as int,practiceMode: null == practiceMode ? _self.practiceMode : practiceMode // ignore: cast_nullable_to_non_nullable
as PracticeMode,waitingHint: freezed == waitingHint ? _self.waitingHint : waitingHint // ignore: cast_nullable_to_non_nullable
as WaitingHint?,isCountingIn: null == isCountingIn ? _self.isCountingIn : isCountingIn // ignore: cast_nullable_to_non_nullable
as bool,countInBeat: freezed == countInBeat ? _self.countInBeat : countInBeat // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of StageEngineStateModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LevelModelCopyWith<$Res> get level {
  
  return $LevelModelCopyWith<$Res>(_self.level, (value) {
    return _then(_self.copyWith(level: value));
  });
}/// Create a copy of StageEngineStateModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WaitingHintCopyWith<$Res>? get waitingHint {
    if (_self.waitingHint == null) {
    return null;
  }

  return $WaitingHintCopyWith<$Res>(_self.waitingHint!, (value) {
    return _then(_self.copyWith(waitingHint: value));
  });
}
}


/// Adds pattern-matching-related methods to [StageEngineStateModel].
extension StageEngineStateModelPatterns on StageEngineStateModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StageEngineStateModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StageEngineStateModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StageEngineStateModel value)  $default,){
final _that = this;
switch (_that) {
case _StageEngineStateModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StageEngineStateModel value)?  $default,){
final _that = this;
switch (_that) {
case _StageEngineStateModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( StageEngineStatus engineState,  LevelModel level,  double currentBeat,  List<NoteState> noteStates,  int score,  int hitCount,  int missCount,  int perfectCount,  int goodCount,  int okayCount,  PracticeMode practiceMode,  WaitingHint? waitingHint,  bool isCountingIn,  int? countInBeat)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StageEngineStateModel() when $default != null:
return $default(_that.engineState,_that.level,_that.currentBeat,_that.noteStates,_that.score,_that.hitCount,_that.missCount,_that.perfectCount,_that.goodCount,_that.okayCount,_that.practiceMode,_that.waitingHint,_that.isCountingIn,_that.countInBeat);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( StageEngineStatus engineState,  LevelModel level,  double currentBeat,  List<NoteState> noteStates,  int score,  int hitCount,  int missCount,  int perfectCount,  int goodCount,  int okayCount,  PracticeMode practiceMode,  WaitingHint? waitingHint,  bool isCountingIn,  int? countInBeat)  $default,) {final _that = this;
switch (_that) {
case _StageEngineStateModel():
return $default(_that.engineState,_that.level,_that.currentBeat,_that.noteStates,_that.score,_that.hitCount,_that.missCount,_that.perfectCount,_that.goodCount,_that.okayCount,_that.practiceMode,_that.waitingHint,_that.isCountingIn,_that.countInBeat);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( StageEngineStatus engineState,  LevelModel level,  double currentBeat,  List<NoteState> noteStates,  int score,  int hitCount,  int missCount,  int perfectCount,  int goodCount,  int okayCount,  PracticeMode practiceMode,  WaitingHint? waitingHint,  bool isCountingIn,  int? countInBeat)?  $default,) {final _that = this;
switch (_that) {
case _StageEngineStateModel() when $default != null:
return $default(_that.engineState,_that.level,_that.currentBeat,_that.noteStates,_that.score,_that.hitCount,_that.missCount,_that.perfectCount,_that.goodCount,_that.okayCount,_that.practiceMode,_that.waitingHint,_that.isCountingIn,_that.countInBeat);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StageEngineStateModel extends StageEngineStateModel {
  const _StageEngineStateModel({required this.engineState, required this.level, required this.currentBeat, required final  List<NoteState> noteStates, required this.score, required this.hitCount, required this.missCount, this.perfectCount = 0, this.goodCount = 0, this.okayCount = 0, this.practiceMode = PracticeMode.timed, this.waitingHint = null, this.isCountingIn = false, this.countInBeat}): _noteStates = noteStates,super._();
  factory _StageEngineStateModel.fromJson(Map<String, dynamic> json) => _$StageEngineStateModelFromJson(json);

@override final  StageEngineStatus engineState;
@override final  LevelModel level;
@override final  double currentBeat;
 final  List<NoteState> _noteStates;
@override List<NoteState> get noteStates {
  if (_noteStates is EqualUnmodifiableListView) return _noteStates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_noteStates);
}

@override final  int score;
@override final  int hitCount;
@override final  int missCount;
@override@JsonKey() final  int perfectCount;
@override@JsonKey() final  int goodCount;
@override@JsonKey() final  int okayCount;
@override@JsonKey() final  PracticeMode practiceMode;
@override@JsonKey() final  WaitingHint? waitingHint;
@override@JsonKey() final  bool isCountingIn;
@override final  int? countInBeat;

/// Create a copy of StageEngineStateModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StageEngineStateModelCopyWith<_StageEngineStateModel> get copyWith => __$StageEngineStateModelCopyWithImpl<_StageEngineStateModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StageEngineStateModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StageEngineStateModel&&(identical(other.engineState, engineState) || other.engineState == engineState)&&(identical(other.level, level) || other.level == level)&&(identical(other.currentBeat, currentBeat) || other.currentBeat == currentBeat)&&const DeepCollectionEquality().equals(other._noteStates, _noteStates)&&(identical(other.score, score) || other.score == score)&&(identical(other.hitCount, hitCount) || other.hitCount == hitCount)&&(identical(other.missCount, missCount) || other.missCount == missCount)&&(identical(other.perfectCount, perfectCount) || other.perfectCount == perfectCount)&&(identical(other.goodCount, goodCount) || other.goodCount == goodCount)&&(identical(other.okayCount, okayCount) || other.okayCount == okayCount)&&(identical(other.practiceMode, practiceMode) || other.practiceMode == practiceMode)&&(identical(other.waitingHint, waitingHint) || other.waitingHint == waitingHint)&&(identical(other.isCountingIn, isCountingIn) || other.isCountingIn == isCountingIn)&&(identical(other.countInBeat, countInBeat) || other.countInBeat == countInBeat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,engineState,level,currentBeat,const DeepCollectionEquality().hash(_noteStates),score,hitCount,missCount,perfectCount,goodCount,okayCount,practiceMode,waitingHint,isCountingIn,countInBeat);

@override
String toString() {
  return 'StageEngineStateModel(engineState: $engineState, level: $level, currentBeat: $currentBeat, noteStates: $noteStates, score: $score, hitCount: $hitCount, missCount: $missCount, perfectCount: $perfectCount, goodCount: $goodCount, okayCount: $okayCount, practiceMode: $practiceMode, waitingHint: $waitingHint, isCountingIn: $isCountingIn, countInBeat: $countInBeat)';
}


}

/// @nodoc
abstract mixin class _$StageEngineStateModelCopyWith<$Res> implements $StageEngineStateModelCopyWith<$Res> {
  factory _$StageEngineStateModelCopyWith(_StageEngineStateModel value, $Res Function(_StageEngineStateModel) _then) = __$StageEngineStateModelCopyWithImpl;
@override @useResult
$Res call({
 StageEngineStatus engineState, LevelModel level, double currentBeat, List<NoteState> noteStates, int score, int hitCount, int missCount, int perfectCount, int goodCount, int okayCount, PracticeMode practiceMode, WaitingHint? waitingHint, bool isCountingIn, int? countInBeat
});


@override $LevelModelCopyWith<$Res> get level;@override $WaitingHintCopyWith<$Res>? get waitingHint;

}
/// @nodoc
class __$StageEngineStateModelCopyWithImpl<$Res>
    implements _$StageEngineStateModelCopyWith<$Res> {
  __$StageEngineStateModelCopyWithImpl(this._self, this._then);

  final _StageEngineStateModel _self;
  final $Res Function(_StageEngineStateModel) _then;

/// Create a copy of StageEngineStateModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? engineState = null,Object? level = null,Object? currentBeat = null,Object? noteStates = null,Object? score = null,Object? hitCount = null,Object? missCount = null,Object? perfectCount = null,Object? goodCount = null,Object? okayCount = null,Object? practiceMode = null,Object? waitingHint = freezed,Object? isCountingIn = null,Object? countInBeat = freezed,}) {
  return _then(_StageEngineStateModel(
engineState: null == engineState ? _self.engineState : engineState // ignore: cast_nullable_to_non_nullable
as StageEngineStatus,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as LevelModel,currentBeat: null == currentBeat ? _self.currentBeat : currentBeat // ignore: cast_nullable_to_non_nullable
as double,noteStates: null == noteStates ? _self._noteStates : noteStates // ignore: cast_nullable_to_non_nullable
as List<NoteState>,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,hitCount: null == hitCount ? _self.hitCount : hitCount // ignore: cast_nullable_to_non_nullable
as int,missCount: null == missCount ? _self.missCount : missCount // ignore: cast_nullable_to_non_nullable
as int,perfectCount: null == perfectCount ? _self.perfectCount : perfectCount // ignore: cast_nullable_to_non_nullable
as int,goodCount: null == goodCount ? _self.goodCount : goodCount // ignore: cast_nullable_to_non_nullable
as int,okayCount: null == okayCount ? _self.okayCount : okayCount // ignore: cast_nullable_to_non_nullable
as int,practiceMode: null == practiceMode ? _self.practiceMode : practiceMode // ignore: cast_nullable_to_non_nullable
as PracticeMode,waitingHint: freezed == waitingHint ? _self.waitingHint : waitingHint // ignore: cast_nullable_to_non_nullable
as WaitingHint?,isCountingIn: null == isCountingIn ? _self.isCountingIn : isCountingIn // ignore: cast_nullable_to_non_nullable
as bool,countInBeat: freezed == countInBeat ? _self.countInBeat : countInBeat // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of StageEngineStateModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LevelModelCopyWith<$Res> get level {
  
  return $LevelModelCopyWith<$Res>(_self.level, (value) {
    return _then(_self.copyWith(level: value));
  });
}/// Create a copy of StageEngineStateModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WaitingHintCopyWith<$Res>? get waitingHint {
    if (_self.waitingHint == null) {
    return null;
  }

  return $WaitingHintCopyWith<$Res>(_self.waitingHint!, (value) {
    return _then(_self.copyWith(waitingHint: value));
  });
}
}

/// @nodoc
mixin _$GameState {

 StageModel? get currentStage; LevelModel? get currentLevel; StageEngineStatus get engineState; double get currentBeat; int get score; double get accuracy; double get playbackSpeed;
/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameStateCopyWith<GameState> get copyWith => _$GameStateCopyWithImpl<GameState>(this as GameState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameState&&(identical(other.currentStage, currentStage) || other.currentStage == currentStage)&&(identical(other.currentLevel, currentLevel) || other.currentLevel == currentLevel)&&(identical(other.engineState, engineState) || other.engineState == engineState)&&(identical(other.currentBeat, currentBeat) || other.currentBeat == currentBeat)&&(identical(other.score, score) || other.score == score)&&(identical(other.accuracy, accuracy) || other.accuracy == accuracy)&&(identical(other.playbackSpeed, playbackSpeed) || other.playbackSpeed == playbackSpeed));
}


@override
int get hashCode => Object.hash(runtimeType,currentStage,currentLevel,engineState,currentBeat,score,accuracy,playbackSpeed);

@override
String toString() {
  return 'GameState(currentStage: $currentStage, currentLevel: $currentLevel, engineState: $engineState, currentBeat: $currentBeat, score: $score, accuracy: $accuracy, playbackSpeed: $playbackSpeed)';
}


}

/// @nodoc
abstract mixin class $GameStateCopyWith<$Res>  {
  factory $GameStateCopyWith(GameState value, $Res Function(GameState) _then) = _$GameStateCopyWithImpl;
@useResult
$Res call({
 StageModel? currentStage, LevelModel? currentLevel, StageEngineStatus engineState, double currentBeat, int score, double accuracy, double playbackSpeed
});


$StageModelCopyWith<$Res>? get currentStage;$LevelModelCopyWith<$Res>? get currentLevel;

}
/// @nodoc
class _$GameStateCopyWithImpl<$Res>
    implements $GameStateCopyWith<$Res> {
  _$GameStateCopyWithImpl(this._self, this._then);

  final GameState _self;
  final $Res Function(GameState) _then;

/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentStage = freezed,Object? currentLevel = freezed,Object? engineState = null,Object? currentBeat = null,Object? score = null,Object? accuracy = null,Object? playbackSpeed = null,}) {
  return _then(_self.copyWith(
currentStage: freezed == currentStage ? _self.currentStage : currentStage // ignore: cast_nullable_to_non_nullable
as StageModel?,currentLevel: freezed == currentLevel ? _self.currentLevel : currentLevel // ignore: cast_nullable_to_non_nullable
as LevelModel?,engineState: null == engineState ? _self.engineState : engineState // ignore: cast_nullable_to_non_nullable
as StageEngineStatus,currentBeat: null == currentBeat ? _self.currentBeat : currentBeat // ignore: cast_nullable_to_non_nullable
as double,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,accuracy: null == accuracy ? _self.accuracy : accuracy // ignore: cast_nullable_to_non_nullable
as double,playbackSpeed: null == playbackSpeed ? _self.playbackSpeed : playbackSpeed // ignore: cast_nullable_to_non_nullable
as double,
  ));
}
/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StageModelCopyWith<$Res>? get currentStage {
    if (_self.currentStage == null) {
    return null;
  }

  return $StageModelCopyWith<$Res>(_self.currentStage!, (value) {
    return _then(_self.copyWith(currentStage: value));
  });
}/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LevelModelCopyWith<$Res>? get currentLevel {
    if (_self.currentLevel == null) {
    return null;
  }

  return $LevelModelCopyWith<$Res>(_self.currentLevel!, (value) {
    return _then(_self.copyWith(currentLevel: value));
  });
}
}


/// Adds pattern-matching-related methods to [GameState].
extension GameStatePatterns on GameState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameState value)  $default,){
final _that = this;
switch (_that) {
case _GameState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameState value)?  $default,){
final _that = this;
switch (_that) {
case _GameState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( StageModel? currentStage,  LevelModel? currentLevel,  StageEngineStatus engineState,  double currentBeat,  int score,  double accuracy,  double playbackSpeed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameState() when $default != null:
return $default(_that.currentStage,_that.currentLevel,_that.engineState,_that.currentBeat,_that.score,_that.accuracy,_that.playbackSpeed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( StageModel? currentStage,  LevelModel? currentLevel,  StageEngineStatus engineState,  double currentBeat,  int score,  double accuracy,  double playbackSpeed)  $default,) {final _that = this;
switch (_that) {
case _GameState():
return $default(_that.currentStage,_that.currentLevel,_that.engineState,_that.currentBeat,_that.score,_that.accuracy,_that.playbackSpeed);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( StageModel? currentStage,  LevelModel? currentLevel,  StageEngineStatus engineState,  double currentBeat,  int score,  double accuracy,  double playbackSpeed)?  $default,) {final _that = this;
switch (_that) {
case _GameState() when $default != null:
return $default(_that.currentStage,_that.currentLevel,_that.engineState,_that.currentBeat,_that.score,_that.accuracy,_that.playbackSpeed);case _:
  return null;

}
}

}

/// @nodoc


class _GameState extends GameState {
  const _GameState({this.currentStage = null, this.currentLevel = null, this.engineState = StageEngineStatus.idle, this.currentBeat = 0.0, this.score = 0, this.accuracy = 0.0, this.playbackSpeed = 1.0}): super._();
  

@override@JsonKey() final  StageModel? currentStage;
@override@JsonKey() final  LevelModel? currentLevel;
@override@JsonKey() final  StageEngineStatus engineState;
@override@JsonKey() final  double currentBeat;
@override@JsonKey() final  int score;
@override@JsonKey() final  double accuracy;
@override@JsonKey() final  double playbackSpeed;

/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameStateCopyWith<_GameState> get copyWith => __$GameStateCopyWithImpl<_GameState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameState&&(identical(other.currentStage, currentStage) || other.currentStage == currentStage)&&(identical(other.currentLevel, currentLevel) || other.currentLevel == currentLevel)&&(identical(other.engineState, engineState) || other.engineState == engineState)&&(identical(other.currentBeat, currentBeat) || other.currentBeat == currentBeat)&&(identical(other.score, score) || other.score == score)&&(identical(other.accuracy, accuracy) || other.accuracy == accuracy)&&(identical(other.playbackSpeed, playbackSpeed) || other.playbackSpeed == playbackSpeed));
}


@override
int get hashCode => Object.hash(runtimeType,currentStage,currentLevel,engineState,currentBeat,score,accuracy,playbackSpeed);

@override
String toString() {
  return 'GameState(currentStage: $currentStage, currentLevel: $currentLevel, engineState: $engineState, currentBeat: $currentBeat, score: $score, accuracy: $accuracy, playbackSpeed: $playbackSpeed)';
}


}

/// @nodoc
abstract mixin class _$GameStateCopyWith<$Res> implements $GameStateCopyWith<$Res> {
  factory _$GameStateCopyWith(_GameState value, $Res Function(_GameState) _then) = __$GameStateCopyWithImpl;
@override @useResult
$Res call({
 StageModel? currentStage, LevelModel? currentLevel, StageEngineStatus engineState, double currentBeat, int score, double accuracy, double playbackSpeed
});


@override $StageModelCopyWith<$Res>? get currentStage;@override $LevelModelCopyWith<$Res>? get currentLevel;

}
/// @nodoc
class __$GameStateCopyWithImpl<$Res>
    implements _$GameStateCopyWith<$Res> {
  __$GameStateCopyWithImpl(this._self, this._then);

  final _GameState _self;
  final $Res Function(_GameState) _then;

/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentStage = freezed,Object? currentLevel = freezed,Object? engineState = null,Object? currentBeat = null,Object? score = null,Object? accuracy = null,Object? playbackSpeed = null,}) {
  return _then(_GameState(
currentStage: freezed == currentStage ? _self.currentStage : currentStage // ignore: cast_nullable_to_non_nullable
as StageModel?,currentLevel: freezed == currentLevel ? _self.currentLevel : currentLevel // ignore: cast_nullable_to_non_nullable
as LevelModel?,engineState: null == engineState ? _self.engineState : engineState // ignore: cast_nullable_to_non_nullable
as StageEngineStatus,currentBeat: null == currentBeat ? _self.currentBeat : currentBeat // ignore: cast_nullable_to_non_nullable
as double,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,accuracy: null == accuracy ? _self.accuracy : accuracy // ignore: cast_nullable_to_non_nullable
as double,playbackSpeed: null == playbackSpeed ? _self.playbackSpeed : playbackSpeed // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StageModelCopyWith<$Res>? get currentStage {
    if (_self.currentStage == null) {
    return null;
  }

  return $StageModelCopyWith<$Res>(_self.currentStage!, (value) {
    return _then(_self.copyWith(currentStage: value));
  });
}/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LevelModelCopyWith<$Res>? get currentLevel {
    if (_self.currentLevel == null) {
    return null;
  }

  return $LevelModelCopyWith<$Res>(_self.currentLevel!, (value) {
    return _then(_self.copyWith(currentLevel: value));
  });
}
}

// dart format on
