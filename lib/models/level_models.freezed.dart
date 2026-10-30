// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'level_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LevelNote implements DiagnosticableTreeMixin {

 int get midiNote; double get startBeat; double get durationBeats; int get measureIndex; int get beatIndex; bool get isRest; int get voiceIndex;/// Written alteration: -1 flat, 0 natural, 1 sharp. Null lets the
/// staff spell black keys as sharps.
 int? get alter;
/// Create a copy of LevelNote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LevelNoteCopyWith<LevelNote> get copyWith => _$LevelNoteCopyWithImpl<LevelNote>(this as LevelNote, _$identity);

  /// Serializes this LevelNote to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'LevelNote'))
    ..add(DiagnosticsProperty('midiNote', midiNote))..add(DiagnosticsProperty('startBeat', startBeat))..add(DiagnosticsProperty('durationBeats', durationBeats))..add(DiagnosticsProperty('measureIndex', measureIndex))..add(DiagnosticsProperty('beatIndex', beatIndex))..add(DiagnosticsProperty('isRest', isRest))..add(DiagnosticsProperty('voiceIndex', voiceIndex))..add(DiagnosticsProperty('alter', alter));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LevelNote&&(identical(other.midiNote, midiNote) || other.midiNote == midiNote)&&(identical(other.startBeat, startBeat) || other.startBeat == startBeat)&&(identical(other.durationBeats, durationBeats) || other.durationBeats == durationBeats)&&(identical(other.measureIndex, measureIndex) || other.measureIndex == measureIndex)&&(identical(other.beatIndex, beatIndex) || other.beatIndex == beatIndex)&&(identical(other.isRest, isRest) || other.isRest == isRest)&&(identical(other.voiceIndex, voiceIndex) || other.voiceIndex == voiceIndex)&&(identical(other.alter, alter) || other.alter == alter));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,midiNote,startBeat,durationBeats,measureIndex,beatIndex,isRest,voiceIndex,alter);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'LevelNote(midiNote: $midiNote, startBeat: $startBeat, durationBeats: $durationBeats, measureIndex: $measureIndex, beatIndex: $beatIndex, isRest: $isRest, voiceIndex: $voiceIndex, alter: $alter)';
}


}

/// @nodoc
abstract mixin class $LevelNoteCopyWith<$Res>  {
  factory $LevelNoteCopyWith(LevelNote value, $Res Function(LevelNote) _then) = _$LevelNoteCopyWithImpl;
@useResult
$Res call({
 int midiNote, double startBeat, double durationBeats, int measureIndex, int beatIndex, bool isRest, int voiceIndex, int? alter
});




}
/// @nodoc
class _$LevelNoteCopyWithImpl<$Res>
    implements $LevelNoteCopyWith<$Res> {
  _$LevelNoteCopyWithImpl(this._self, this._then);

  final LevelNote _self;
  final $Res Function(LevelNote) _then;

/// Create a copy of LevelNote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? midiNote = null,Object? startBeat = null,Object? durationBeats = null,Object? measureIndex = null,Object? beatIndex = null,Object? isRest = null,Object? voiceIndex = null,Object? alter = freezed,}) {
  return _then(_self.copyWith(
midiNote: null == midiNote ? _self.midiNote : midiNote // ignore: cast_nullable_to_non_nullable
as int,startBeat: null == startBeat ? _self.startBeat : startBeat // ignore: cast_nullable_to_non_nullable
as double,durationBeats: null == durationBeats ? _self.durationBeats : durationBeats // ignore: cast_nullable_to_non_nullable
as double,measureIndex: null == measureIndex ? _self.measureIndex : measureIndex // ignore: cast_nullable_to_non_nullable
as int,beatIndex: null == beatIndex ? _self.beatIndex : beatIndex // ignore: cast_nullable_to_non_nullable
as int,isRest: null == isRest ? _self.isRest : isRest // ignore: cast_nullable_to_non_nullable
as bool,voiceIndex: null == voiceIndex ? _self.voiceIndex : voiceIndex // ignore: cast_nullable_to_non_nullable
as int,alter: freezed == alter ? _self.alter : alter // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [LevelNote].
extension LevelNotePatterns on LevelNote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LevelNote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LevelNote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LevelNote value)  $default,){
final _that = this;
switch (_that) {
case _LevelNote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LevelNote value)?  $default,){
final _that = this;
switch (_that) {
case _LevelNote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int midiNote,  double startBeat,  double durationBeats,  int measureIndex,  int beatIndex,  bool isRest,  int voiceIndex,  int? alter)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LevelNote() when $default != null:
return $default(_that.midiNote,_that.startBeat,_that.durationBeats,_that.measureIndex,_that.beatIndex,_that.isRest,_that.voiceIndex,_that.alter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int midiNote,  double startBeat,  double durationBeats,  int measureIndex,  int beatIndex,  bool isRest,  int voiceIndex,  int? alter)  $default,) {final _that = this;
switch (_that) {
case _LevelNote():
return $default(_that.midiNote,_that.startBeat,_that.durationBeats,_that.measureIndex,_that.beatIndex,_that.isRest,_that.voiceIndex,_that.alter);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int midiNote,  double startBeat,  double durationBeats,  int measureIndex,  int beatIndex,  bool isRest,  int voiceIndex,  int? alter)?  $default,) {final _that = this;
switch (_that) {
case _LevelNote() when $default != null:
return $default(_that.midiNote,_that.startBeat,_that.durationBeats,_that.measureIndex,_that.beatIndex,_that.isRest,_that.voiceIndex,_that.alter);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LevelNote with DiagnosticableTreeMixin implements LevelNote {
  const _LevelNote({required this.midiNote, required this.startBeat, required this.durationBeats, required this.measureIndex, required this.beatIndex, this.isRest = false, this.voiceIndex = 0, this.alter});
  factory _LevelNote.fromJson(Map<String, dynamic> json) => _$LevelNoteFromJson(json);

@override final  int midiNote;
@override final  double startBeat;
@override final  double durationBeats;
@override final  int measureIndex;
@override final  int beatIndex;
@override@JsonKey() final  bool isRest;
@override@JsonKey() final  int voiceIndex;
/// Written alteration: -1 flat, 0 natural, 1 sharp. Null lets the
/// staff spell black keys as sharps.
@override final  int? alter;

/// Create a copy of LevelNote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LevelNoteCopyWith<_LevelNote> get copyWith => __$LevelNoteCopyWithImpl<_LevelNote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LevelNoteToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'LevelNote'))
    ..add(DiagnosticsProperty('midiNote', midiNote))..add(DiagnosticsProperty('startBeat', startBeat))..add(DiagnosticsProperty('durationBeats', durationBeats))..add(DiagnosticsProperty('measureIndex', measureIndex))..add(DiagnosticsProperty('beatIndex', beatIndex))..add(DiagnosticsProperty('isRest', isRest))..add(DiagnosticsProperty('voiceIndex', voiceIndex))..add(DiagnosticsProperty('alter', alter));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LevelNote&&(identical(other.midiNote, midiNote) || other.midiNote == midiNote)&&(identical(other.startBeat, startBeat) || other.startBeat == startBeat)&&(identical(other.durationBeats, durationBeats) || other.durationBeats == durationBeats)&&(identical(other.measureIndex, measureIndex) || other.measureIndex == measureIndex)&&(identical(other.beatIndex, beatIndex) || other.beatIndex == beatIndex)&&(identical(other.isRest, isRest) || other.isRest == isRest)&&(identical(other.voiceIndex, voiceIndex) || other.voiceIndex == voiceIndex)&&(identical(other.alter, alter) || other.alter == alter));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,midiNote,startBeat,durationBeats,measureIndex,beatIndex,isRest,voiceIndex,alter);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'LevelNote(midiNote: $midiNote, startBeat: $startBeat, durationBeats: $durationBeats, measureIndex: $measureIndex, beatIndex: $beatIndex, isRest: $isRest, voiceIndex: $voiceIndex, alter: $alter)';
}


}

/// @nodoc
abstract mixin class _$LevelNoteCopyWith<$Res> implements $LevelNoteCopyWith<$Res> {
  factory _$LevelNoteCopyWith(_LevelNote value, $Res Function(_LevelNote) _then) = __$LevelNoteCopyWithImpl;
@override @useResult
$Res call({
 int midiNote, double startBeat, double durationBeats, int measureIndex, int beatIndex, bool isRest, int voiceIndex, int? alter
});




}
/// @nodoc
class __$LevelNoteCopyWithImpl<$Res>
    implements _$LevelNoteCopyWith<$Res> {
  __$LevelNoteCopyWithImpl(this._self, this._then);

  final _LevelNote _self;
  final $Res Function(_LevelNote) _then;

/// Create a copy of LevelNote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? midiNote = null,Object? startBeat = null,Object? durationBeats = null,Object? measureIndex = null,Object? beatIndex = null,Object? isRest = null,Object? voiceIndex = null,Object? alter = freezed,}) {
  return _then(_LevelNote(
midiNote: null == midiNote ? _self.midiNote : midiNote // ignore: cast_nullable_to_non_nullable
as int,startBeat: null == startBeat ? _self.startBeat : startBeat // ignore: cast_nullable_to_non_nullable
as double,durationBeats: null == durationBeats ? _self.durationBeats : durationBeats // ignore: cast_nullable_to_non_nullable
as double,measureIndex: null == measureIndex ? _self.measureIndex : measureIndex // ignore: cast_nullable_to_non_nullable
as int,beatIndex: null == beatIndex ? _self.beatIndex : beatIndex // ignore: cast_nullable_to_non_nullable
as int,isRest: null == isRest ? _self.isRest : isRest // ignore: cast_nullable_to_non_nullable
as bool,voiceIndex: null == voiceIndex ? _self.voiceIndex : voiceIndex // ignore: cast_nullable_to_non_nullable
as int,alter: freezed == alter ? _self.alter : alter // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$LevelMeasure implements DiagnosticableTreeMixin {

 int get index; double get startBeat; int get beatsPerMeasure; List<LevelNote> get notes;
/// Create a copy of LevelMeasure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LevelMeasureCopyWith<LevelMeasure> get copyWith => _$LevelMeasureCopyWithImpl<LevelMeasure>(this as LevelMeasure, _$identity);

  /// Serializes this LevelMeasure to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'LevelMeasure'))
    ..add(DiagnosticsProperty('index', index))..add(DiagnosticsProperty('startBeat', startBeat))..add(DiagnosticsProperty('beatsPerMeasure', beatsPerMeasure))..add(DiagnosticsProperty('notes', notes));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LevelMeasure&&(identical(other.index, index) || other.index == index)&&(identical(other.startBeat, startBeat) || other.startBeat == startBeat)&&(identical(other.beatsPerMeasure, beatsPerMeasure) || other.beatsPerMeasure == beatsPerMeasure)&&const DeepCollectionEquality().equals(other.notes, notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,index,startBeat,beatsPerMeasure,const DeepCollectionEquality().hash(notes));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'LevelMeasure(index: $index, startBeat: $startBeat, beatsPerMeasure: $beatsPerMeasure, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $LevelMeasureCopyWith<$Res>  {
  factory $LevelMeasureCopyWith(LevelMeasure value, $Res Function(LevelMeasure) _then) = _$LevelMeasureCopyWithImpl;
@useResult
$Res call({
 int index, double startBeat, int beatsPerMeasure, List<LevelNote> notes
});




}
/// @nodoc
class _$LevelMeasureCopyWithImpl<$Res>
    implements $LevelMeasureCopyWith<$Res> {
  _$LevelMeasureCopyWithImpl(this._self, this._then);

  final LevelMeasure _self;
  final $Res Function(LevelMeasure) _then;

/// Create a copy of LevelMeasure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? startBeat = null,Object? beatsPerMeasure = null,Object? notes = null,}) {
  return _then(_self.copyWith(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,startBeat: null == startBeat ? _self.startBeat : startBeat // ignore: cast_nullable_to_non_nullable
as double,beatsPerMeasure: null == beatsPerMeasure ? _self.beatsPerMeasure : beatsPerMeasure // ignore: cast_nullable_to_non_nullable
as int,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as List<LevelNote>,
  ));
}

}


/// Adds pattern-matching-related methods to [LevelMeasure].
extension LevelMeasurePatterns on LevelMeasure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LevelMeasure value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LevelMeasure() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LevelMeasure value)  $default,){
final _that = this;
switch (_that) {
case _LevelMeasure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LevelMeasure value)?  $default,){
final _that = this;
switch (_that) {
case _LevelMeasure() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  double startBeat,  int beatsPerMeasure,  List<LevelNote> notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LevelMeasure() when $default != null:
return $default(_that.index,_that.startBeat,_that.beatsPerMeasure,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  double startBeat,  int beatsPerMeasure,  List<LevelNote> notes)  $default,) {final _that = this;
switch (_that) {
case _LevelMeasure():
return $default(_that.index,_that.startBeat,_that.beatsPerMeasure,_that.notes);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  double startBeat,  int beatsPerMeasure,  List<LevelNote> notes)?  $default,) {final _that = this;
switch (_that) {
case _LevelMeasure() when $default != null:
return $default(_that.index,_that.startBeat,_that.beatsPerMeasure,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LevelMeasure with DiagnosticableTreeMixin implements LevelMeasure {
  const _LevelMeasure({required this.index, required this.startBeat, required this.beatsPerMeasure, required final  List<LevelNote> notes}): _notes = notes;
  factory _LevelMeasure.fromJson(Map<String, dynamic> json) => _$LevelMeasureFromJson(json);

@override final  int index;
@override final  double startBeat;
@override final  int beatsPerMeasure;
 final  List<LevelNote> _notes;
@override List<LevelNote> get notes {
  if (_notes is EqualUnmodifiableListView) return _notes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_notes);
}


/// Create a copy of LevelMeasure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LevelMeasureCopyWith<_LevelMeasure> get copyWith => __$LevelMeasureCopyWithImpl<_LevelMeasure>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LevelMeasureToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'LevelMeasure'))
    ..add(DiagnosticsProperty('index', index))..add(DiagnosticsProperty('startBeat', startBeat))..add(DiagnosticsProperty('beatsPerMeasure', beatsPerMeasure))..add(DiagnosticsProperty('notes', notes));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LevelMeasure&&(identical(other.index, index) || other.index == index)&&(identical(other.startBeat, startBeat) || other.startBeat == startBeat)&&(identical(other.beatsPerMeasure, beatsPerMeasure) || other.beatsPerMeasure == beatsPerMeasure)&&const DeepCollectionEquality().equals(other._notes, _notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,index,startBeat,beatsPerMeasure,const DeepCollectionEquality().hash(_notes));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'LevelMeasure(index: $index, startBeat: $startBeat, beatsPerMeasure: $beatsPerMeasure, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$LevelMeasureCopyWith<$Res> implements $LevelMeasureCopyWith<$Res> {
  factory _$LevelMeasureCopyWith(_LevelMeasure value, $Res Function(_LevelMeasure) _then) = __$LevelMeasureCopyWithImpl;
@override @useResult
$Res call({
 int index, double startBeat, int beatsPerMeasure, List<LevelNote> notes
});




}
/// @nodoc
class __$LevelMeasureCopyWithImpl<$Res>
    implements _$LevelMeasureCopyWith<$Res> {
  __$LevelMeasureCopyWithImpl(this._self, this._then);

  final _LevelMeasure _self;
  final $Res Function(_LevelMeasure) _then;

/// Create a copy of LevelMeasure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? startBeat = null,Object? beatsPerMeasure = null,Object? notes = null,}) {
  return _then(_LevelMeasure(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,startBeat: null == startBeat ? _self.startBeat : startBeat // ignore: cast_nullable_to_non_nullable
as double,beatsPerMeasure: null == beatsPerMeasure ? _self.beatsPerMeasure : beatsPerMeasure // ignore: cast_nullable_to_non_nullable
as int,notes: null == notes ? _self._notes : notes // ignore: cast_nullable_to_non_nullable
as List<LevelNote>,
  ));
}


}


/// @nodoc
mixin _$LevelModel implements DiagnosticableTreeMixin {

 String get id; String get title; String get description; int get tempo; int get beatsPerMeasure; int get totalMeasures; List<LevelMeasure> get measures; int get clefOctave;// 4 = middle C octave
 int get transpose;// semitones to transpose
 LevelClef get clef; int get beatUnit;
/// Create a copy of LevelModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LevelModelCopyWith<LevelModel> get copyWith => _$LevelModelCopyWithImpl<LevelModel>(this as LevelModel, _$identity);

  /// Serializes this LevelModel to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'LevelModel'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('description', description))..add(DiagnosticsProperty('tempo', tempo))..add(DiagnosticsProperty('beatsPerMeasure', beatsPerMeasure))..add(DiagnosticsProperty('totalMeasures', totalMeasures))..add(DiagnosticsProperty('measures', measures))..add(DiagnosticsProperty('clefOctave', clefOctave))..add(DiagnosticsProperty('transpose', transpose))..add(DiagnosticsProperty('clef', clef))..add(DiagnosticsProperty('beatUnit', beatUnit));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LevelModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.tempo, tempo) || other.tempo == tempo)&&(identical(other.beatsPerMeasure, beatsPerMeasure) || other.beatsPerMeasure == beatsPerMeasure)&&(identical(other.totalMeasures, totalMeasures) || other.totalMeasures == totalMeasures)&&const DeepCollectionEquality().equals(other.measures, measures)&&(identical(other.clefOctave, clefOctave) || other.clefOctave == clefOctave)&&(identical(other.transpose, transpose) || other.transpose == transpose)&&(identical(other.clef, clef) || other.clef == clef)&&(identical(other.beatUnit, beatUnit) || other.beatUnit == beatUnit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,tempo,beatsPerMeasure,totalMeasures,const DeepCollectionEquality().hash(measures),clefOctave,transpose,clef,beatUnit);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'LevelModel(id: $id, title: $title, description: $description, tempo: $tempo, beatsPerMeasure: $beatsPerMeasure, totalMeasures: $totalMeasures, measures: $measures, clefOctave: $clefOctave, transpose: $transpose, clef: $clef, beatUnit: $beatUnit)';
}


}

/// @nodoc
abstract mixin class $LevelModelCopyWith<$Res>  {
  factory $LevelModelCopyWith(LevelModel value, $Res Function(LevelModel) _then) = _$LevelModelCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description, int tempo, int beatsPerMeasure, int totalMeasures, List<LevelMeasure> measures, int clefOctave, int transpose, LevelClef clef, int beatUnit
});




}
/// @nodoc
class _$LevelModelCopyWithImpl<$Res>
    implements $LevelModelCopyWith<$Res> {
  _$LevelModelCopyWithImpl(this._self, this._then);

  final LevelModel _self;
  final $Res Function(LevelModel) _then;

/// Create a copy of LevelModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? tempo = null,Object? beatsPerMeasure = null,Object? totalMeasures = null,Object? measures = null,Object? clefOctave = null,Object? transpose = null,Object? clef = null,Object? beatUnit = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,tempo: null == tempo ? _self.tempo : tempo // ignore: cast_nullable_to_non_nullable
as int,beatsPerMeasure: null == beatsPerMeasure ? _self.beatsPerMeasure : beatsPerMeasure // ignore: cast_nullable_to_non_nullable
as int,totalMeasures: null == totalMeasures ? _self.totalMeasures : totalMeasures // ignore: cast_nullable_to_non_nullable
as int,measures: null == measures ? _self.measures : measures // ignore: cast_nullable_to_non_nullable
as List<LevelMeasure>,clefOctave: null == clefOctave ? _self.clefOctave : clefOctave // ignore: cast_nullable_to_non_nullable
as int,transpose: null == transpose ? _self.transpose : transpose // ignore: cast_nullable_to_non_nullable
as int,clef: null == clef ? _self.clef : clef // ignore: cast_nullable_to_non_nullable
as LevelClef,beatUnit: null == beatUnit ? _self.beatUnit : beatUnit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LevelModel].
extension LevelModelPatterns on LevelModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LevelModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LevelModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LevelModel value)  $default,){
final _that = this;
switch (_that) {
case _LevelModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LevelModel value)?  $default,){
final _that = this;
switch (_that) {
case _LevelModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description,  int tempo,  int beatsPerMeasure,  int totalMeasures,  List<LevelMeasure> measures,  int clefOctave,  int transpose,  LevelClef clef,  int beatUnit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LevelModel() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.tempo,_that.beatsPerMeasure,_that.totalMeasures,_that.measures,_that.clefOctave,_that.transpose,_that.clef,_that.beatUnit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description,  int tempo,  int beatsPerMeasure,  int totalMeasures,  List<LevelMeasure> measures,  int clefOctave,  int transpose,  LevelClef clef,  int beatUnit)  $default,) {final _that = this;
switch (_that) {
case _LevelModel():
return $default(_that.id,_that.title,_that.description,_that.tempo,_that.beatsPerMeasure,_that.totalMeasures,_that.measures,_that.clefOctave,_that.transpose,_that.clef,_that.beatUnit);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description,  int tempo,  int beatsPerMeasure,  int totalMeasures,  List<LevelMeasure> measures,  int clefOctave,  int transpose,  LevelClef clef,  int beatUnit)?  $default,) {final _that = this;
switch (_that) {
case _LevelModel() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.tempo,_that.beatsPerMeasure,_that.totalMeasures,_that.measures,_that.clefOctave,_that.transpose,_that.clef,_that.beatUnit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LevelModel with DiagnosticableTreeMixin implements LevelModel {
  const _LevelModel({required this.id, required this.title, required this.description, required this.tempo, required this.beatsPerMeasure, required this.totalMeasures, required final  List<LevelMeasure> measures, this.clefOctave = 4, this.transpose = 0, this.clef = LevelClef.treble, this.beatUnit = 4}): _measures = measures;
  factory _LevelModel.fromJson(Map<String, dynamic> json) => _$LevelModelFromJson(json);

@override final  String id;
@override final  String title;
@override final  String description;
@override final  int tempo;
@override final  int beatsPerMeasure;
@override final  int totalMeasures;
 final  List<LevelMeasure> _measures;
@override List<LevelMeasure> get measures {
  if (_measures is EqualUnmodifiableListView) return _measures;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_measures);
}

@override@JsonKey() final  int clefOctave;
// 4 = middle C octave
@override@JsonKey() final  int transpose;
// semitones to transpose
@override@JsonKey() final  LevelClef clef;
@override@JsonKey() final  int beatUnit;

/// Create a copy of LevelModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LevelModelCopyWith<_LevelModel> get copyWith => __$LevelModelCopyWithImpl<_LevelModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LevelModelToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'LevelModel'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('description', description))..add(DiagnosticsProperty('tempo', tempo))..add(DiagnosticsProperty('beatsPerMeasure', beatsPerMeasure))..add(DiagnosticsProperty('totalMeasures', totalMeasures))..add(DiagnosticsProperty('measures', measures))..add(DiagnosticsProperty('clefOctave', clefOctave))..add(DiagnosticsProperty('transpose', transpose))..add(DiagnosticsProperty('clef', clef))..add(DiagnosticsProperty('beatUnit', beatUnit));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LevelModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.tempo, tempo) || other.tempo == tempo)&&(identical(other.beatsPerMeasure, beatsPerMeasure) || other.beatsPerMeasure == beatsPerMeasure)&&(identical(other.totalMeasures, totalMeasures) || other.totalMeasures == totalMeasures)&&const DeepCollectionEquality().equals(other._measures, _measures)&&(identical(other.clefOctave, clefOctave) || other.clefOctave == clefOctave)&&(identical(other.transpose, transpose) || other.transpose == transpose)&&(identical(other.clef, clef) || other.clef == clef)&&(identical(other.beatUnit, beatUnit) || other.beatUnit == beatUnit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,tempo,beatsPerMeasure,totalMeasures,const DeepCollectionEquality().hash(_measures),clefOctave,transpose,clef,beatUnit);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'LevelModel(id: $id, title: $title, description: $description, tempo: $tempo, beatsPerMeasure: $beatsPerMeasure, totalMeasures: $totalMeasures, measures: $measures, clefOctave: $clefOctave, transpose: $transpose, clef: $clef, beatUnit: $beatUnit)';
}


}

/// @nodoc
abstract mixin class _$LevelModelCopyWith<$Res> implements $LevelModelCopyWith<$Res> {
  factory _$LevelModelCopyWith(_LevelModel value, $Res Function(_LevelModel) _then) = __$LevelModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description, int tempo, int beatsPerMeasure, int totalMeasures, List<LevelMeasure> measures, int clefOctave, int transpose, LevelClef clef, int beatUnit
});




}
/// @nodoc
class __$LevelModelCopyWithImpl<$Res>
    implements _$LevelModelCopyWith<$Res> {
  __$LevelModelCopyWithImpl(this._self, this._then);

  final _LevelModel _self;
  final $Res Function(_LevelModel) _then;

/// Create a copy of LevelModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? tempo = null,Object? beatsPerMeasure = null,Object? totalMeasures = null,Object? measures = null,Object? clefOctave = null,Object? transpose = null,Object? clef = null,Object? beatUnit = null,}) {
  return _then(_LevelModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,tempo: null == tempo ? _self.tempo : tempo // ignore: cast_nullable_to_non_nullable
as int,beatsPerMeasure: null == beatsPerMeasure ? _self.beatsPerMeasure : beatsPerMeasure // ignore: cast_nullable_to_non_nullable
as int,totalMeasures: null == totalMeasures ? _self.totalMeasures : totalMeasures // ignore: cast_nullable_to_non_nullable
as int,measures: null == measures ? _self._measures : measures // ignore: cast_nullable_to_non_nullable
as List<LevelMeasure>,clefOctave: null == clefOctave ? _self.clefOctave : clefOctave // ignore: cast_nullable_to_non_nullable
as int,transpose: null == transpose ? _self.transpose : transpose // ignore: cast_nullable_to_non_nullable
as int,clef: null == clef ? _self.clef : clef // ignore: cast_nullable_to_non_nullable
as LevelClef,beatUnit: null == beatUnit ? _self.beatUnit : beatUnit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$StageModel implements DiagnosticableTreeMixin {

 String get id; String get title; String get description; Difficulty get difficulty; LevelModel get level; int get order; List<String> get prerequisites; int get xpReward;
/// Create a copy of StageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StageModelCopyWith<StageModel> get copyWith => _$StageModelCopyWithImpl<StageModel>(this as StageModel, _$identity);

  /// Serializes this StageModel to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'StageModel'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('description', description))..add(DiagnosticsProperty('difficulty', difficulty))..add(DiagnosticsProperty('level', level))..add(DiagnosticsProperty('order', order))..add(DiagnosticsProperty('prerequisites', prerequisites))..add(DiagnosticsProperty('xpReward', xpReward));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.level, level) || other.level == level)&&(identical(other.order, order) || other.order == order)&&const DeepCollectionEquality().equals(other.prerequisites, prerequisites)&&(identical(other.xpReward, xpReward) || other.xpReward == xpReward));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,difficulty,level,order,const DeepCollectionEquality().hash(prerequisites),xpReward);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'StageModel(id: $id, title: $title, description: $description, difficulty: $difficulty, level: $level, order: $order, prerequisites: $prerequisites, xpReward: $xpReward)';
}


}

/// @nodoc
abstract mixin class $StageModelCopyWith<$Res>  {
  factory $StageModelCopyWith(StageModel value, $Res Function(StageModel) _then) = _$StageModelCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description, Difficulty difficulty, LevelModel level, int order, List<String> prerequisites, int xpReward
});


$LevelModelCopyWith<$Res> get level;

}
/// @nodoc
class _$StageModelCopyWithImpl<$Res>
    implements $StageModelCopyWith<$Res> {
  _$StageModelCopyWithImpl(this._self, this._then);

  final StageModel _self;
  final $Res Function(StageModel) _then;

/// Create a copy of StageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? difficulty = null,Object? level = null,Object? order = null,Object? prerequisites = null,Object? xpReward = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as Difficulty,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as LevelModel,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,prerequisites: null == prerequisites ? _self.prerequisites : prerequisites // ignore: cast_nullable_to_non_nullable
as List<String>,xpReward: null == xpReward ? _self.xpReward : xpReward // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of StageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LevelModelCopyWith<$Res> get level {
  
  return $LevelModelCopyWith<$Res>(_self.level, (value) {
    return _then(_self.copyWith(level: value));
  });
}
}


/// Adds pattern-matching-related methods to [StageModel].
extension StageModelPatterns on StageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StageModel value)  $default,){
final _that = this;
switch (_that) {
case _StageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StageModel value)?  $default,){
final _that = this;
switch (_that) {
case _StageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description,  Difficulty difficulty,  LevelModel level,  int order,  List<String> prerequisites,  int xpReward)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StageModel() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.difficulty,_that.level,_that.order,_that.prerequisites,_that.xpReward);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description,  Difficulty difficulty,  LevelModel level,  int order,  List<String> prerequisites,  int xpReward)  $default,) {final _that = this;
switch (_that) {
case _StageModel():
return $default(_that.id,_that.title,_that.description,_that.difficulty,_that.level,_that.order,_that.prerequisites,_that.xpReward);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description,  Difficulty difficulty,  LevelModel level,  int order,  List<String> prerequisites,  int xpReward)?  $default,) {final _that = this;
switch (_that) {
case _StageModel() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.difficulty,_that.level,_that.order,_that.prerequisites,_that.xpReward);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StageModel with DiagnosticableTreeMixin implements StageModel {
  const _StageModel({required this.id, required this.title, required this.description, required this.difficulty, required this.level, this.order = 0, final  List<String> prerequisites = const [], this.xpReward = 0}): _prerequisites = prerequisites;
  factory _StageModel.fromJson(Map<String, dynamic> json) => _$StageModelFromJson(json);

@override final  String id;
@override final  String title;
@override final  String description;
@override final  Difficulty difficulty;
@override final  LevelModel level;
@override@JsonKey() final  int order;
 final  List<String> _prerequisites;
@override@JsonKey() List<String> get prerequisites {
  if (_prerequisites is EqualUnmodifiableListView) return _prerequisites;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_prerequisites);
}

@override@JsonKey() final  int xpReward;

/// Create a copy of StageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StageModelCopyWith<_StageModel> get copyWith => __$StageModelCopyWithImpl<_StageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StageModelToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'StageModel'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('description', description))..add(DiagnosticsProperty('difficulty', difficulty))..add(DiagnosticsProperty('level', level))..add(DiagnosticsProperty('order', order))..add(DiagnosticsProperty('prerequisites', prerequisites))..add(DiagnosticsProperty('xpReward', xpReward));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.level, level) || other.level == level)&&(identical(other.order, order) || other.order == order)&&const DeepCollectionEquality().equals(other._prerequisites, _prerequisites)&&(identical(other.xpReward, xpReward) || other.xpReward == xpReward));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,difficulty,level,order,const DeepCollectionEquality().hash(_prerequisites),xpReward);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'StageModel(id: $id, title: $title, description: $description, difficulty: $difficulty, level: $level, order: $order, prerequisites: $prerequisites, xpReward: $xpReward)';
}


}

/// @nodoc
abstract mixin class _$StageModelCopyWith<$Res> implements $StageModelCopyWith<$Res> {
  factory _$StageModelCopyWith(_StageModel value, $Res Function(_StageModel) _then) = __$StageModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description, Difficulty difficulty, LevelModel level, int order, List<String> prerequisites, int xpReward
});


@override $LevelModelCopyWith<$Res> get level;

}
/// @nodoc
class __$StageModelCopyWithImpl<$Res>
    implements _$StageModelCopyWith<$Res> {
  __$StageModelCopyWithImpl(this._self, this._then);

  final _StageModel _self;
  final $Res Function(_StageModel) _then;

/// Create a copy of StageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? difficulty = null,Object? level = null,Object? order = null,Object? prerequisites = null,Object? xpReward = null,}) {
  return _then(_StageModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as Difficulty,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as LevelModel,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,prerequisites: null == prerequisites ? _self._prerequisites : prerequisites // ignore: cast_nullable_to_non_nullable
as List<String>,xpReward: null == xpReward ? _self.xpReward : xpReward // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of StageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LevelModelCopyWith<$Res> get level {
  
  return $LevelModelCopyWith<$Res>(_self.level, (value) {
    return _then(_self.copyWith(level: value));
  });
}
}


/// @nodoc
mixin _$StageProgress implements DiagnosticableTreeMixin {

 String get stageId; double get bestAccuracy; int get bestScore; int get attempts; bool get completed; bool get unlocked; DateTime? get completedAt; DateTime? get lastAttemptAt;
/// Create a copy of StageProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StageProgressCopyWith<StageProgress> get copyWith => _$StageProgressCopyWithImpl<StageProgress>(this as StageProgress, _$identity);

  /// Serializes this StageProgress to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'StageProgress'))
    ..add(DiagnosticsProperty('stageId', stageId))..add(DiagnosticsProperty('bestAccuracy', bestAccuracy))..add(DiagnosticsProperty('bestScore', bestScore))..add(DiagnosticsProperty('attempts', attempts))..add(DiagnosticsProperty('completed', completed))..add(DiagnosticsProperty('unlocked', unlocked))..add(DiagnosticsProperty('completedAt', completedAt))..add(DiagnosticsProperty('lastAttemptAt', lastAttemptAt));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StageProgress&&(identical(other.stageId, stageId) || other.stageId == stageId)&&(identical(other.bestAccuracy, bestAccuracy) || other.bestAccuracy == bestAccuracy)&&(identical(other.bestScore, bestScore) || other.bestScore == bestScore)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.unlocked, unlocked) || other.unlocked == unlocked)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.lastAttemptAt, lastAttemptAt) || other.lastAttemptAt == lastAttemptAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stageId,bestAccuracy,bestScore,attempts,completed,unlocked,completedAt,lastAttemptAt);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'StageProgress(stageId: $stageId, bestAccuracy: $bestAccuracy, bestScore: $bestScore, attempts: $attempts, completed: $completed, unlocked: $unlocked, completedAt: $completedAt, lastAttemptAt: $lastAttemptAt)';
}


}

/// @nodoc
abstract mixin class $StageProgressCopyWith<$Res>  {
  factory $StageProgressCopyWith(StageProgress value, $Res Function(StageProgress) _then) = _$StageProgressCopyWithImpl;
@useResult
$Res call({
 String stageId, double bestAccuracy, int bestScore, int attempts, bool completed, bool unlocked, DateTime? completedAt, DateTime? lastAttemptAt
});




}
/// @nodoc
class _$StageProgressCopyWithImpl<$Res>
    implements $StageProgressCopyWith<$Res> {
  _$StageProgressCopyWithImpl(this._self, this._then);

  final StageProgress _self;
  final $Res Function(StageProgress) _then;

/// Create a copy of StageProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stageId = null,Object? bestAccuracy = null,Object? bestScore = null,Object? attempts = null,Object? completed = null,Object? unlocked = null,Object? completedAt = freezed,Object? lastAttemptAt = freezed,}) {
  return _then(_self.copyWith(
stageId: null == stageId ? _self.stageId : stageId // ignore: cast_nullable_to_non_nullable
as String,bestAccuracy: null == bestAccuracy ? _self.bestAccuracy : bestAccuracy // ignore: cast_nullable_to_non_nullable
as double,bestScore: null == bestScore ? _self.bestScore : bestScore // ignore: cast_nullable_to_non_nullable
as int,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,unlocked: null == unlocked ? _self.unlocked : unlocked // ignore: cast_nullable_to_non_nullable
as bool,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastAttemptAt: freezed == lastAttemptAt ? _self.lastAttemptAt : lastAttemptAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [StageProgress].
extension StageProgressPatterns on StageProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StageProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StageProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StageProgress value)  $default,){
final _that = this;
switch (_that) {
case _StageProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StageProgress value)?  $default,){
final _that = this;
switch (_that) {
case _StageProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String stageId,  double bestAccuracy,  int bestScore,  int attempts,  bool completed,  bool unlocked,  DateTime? completedAt,  DateTime? lastAttemptAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StageProgress() when $default != null:
return $default(_that.stageId,_that.bestAccuracy,_that.bestScore,_that.attempts,_that.completed,_that.unlocked,_that.completedAt,_that.lastAttemptAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String stageId,  double bestAccuracy,  int bestScore,  int attempts,  bool completed,  bool unlocked,  DateTime? completedAt,  DateTime? lastAttemptAt)  $default,) {final _that = this;
switch (_that) {
case _StageProgress():
return $default(_that.stageId,_that.bestAccuracy,_that.bestScore,_that.attempts,_that.completed,_that.unlocked,_that.completedAt,_that.lastAttemptAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String stageId,  double bestAccuracy,  int bestScore,  int attempts,  bool completed,  bool unlocked,  DateTime? completedAt,  DateTime? lastAttemptAt)?  $default,) {final _that = this;
switch (_that) {
case _StageProgress() when $default != null:
return $default(_that.stageId,_that.bestAccuracy,_that.bestScore,_that.attempts,_that.completed,_that.unlocked,_that.completedAt,_that.lastAttemptAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StageProgress with DiagnosticableTreeMixin implements StageProgress {
  const _StageProgress({required this.stageId, this.bestAccuracy = 0, this.bestScore = 0, this.attempts = 0, this.completed = false, this.unlocked = false, this.completedAt, this.lastAttemptAt});
  factory _StageProgress.fromJson(Map<String, dynamic> json) => _$StageProgressFromJson(json);

@override final  String stageId;
@override@JsonKey() final  double bestAccuracy;
@override@JsonKey() final  int bestScore;
@override@JsonKey() final  int attempts;
@override@JsonKey() final  bool completed;
@override@JsonKey() final  bool unlocked;
@override final  DateTime? completedAt;
@override final  DateTime? lastAttemptAt;

/// Create a copy of StageProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StageProgressCopyWith<_StageProgress> get copyWith => __$StageProgressCopyWithImpl<_StageProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StageProgressToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'StageProgress'))
    ..add(DiagnosticsProperty('stageId', stageId))..add(DiagnosticsProperty('bestAccuracy', bestAccuracy))..add(DiagnosticsProperty('bestScore', bestScore))..add(DiagnosticsProperty('attempts', attempts))..add(DiagnosticsProperty('completed', completed))..add(DiagnosticsProperty('unlocked', unlocked))..add(DiagnosticsProperty('completedAt', completedAt))..add(DiagnosticsProperty('lastAttemptAt', lastAttemptAt));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StageProgress&&(identical(other.stageId, stageId) || other.stageId == stageId)&&(identical(other.bestAccuracy, bestAccuracy) || other.bestAccuracy == bestAccuracy)&&(identical(other.bestScore, bestScore) || other.bestScore == bestScore)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.unlocked, unlocked) || other.unlocked == unlocked)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.lastAttemptAt, lastAttemptAt) || other.lastAttemptAt == lastAttemptAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stageId,bestAccuracy,bestScore,attempts,completed,unlocked,completedAt,lastAttemptAt);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'StageProgress(stageId: $stageId, bestAccuracy: $bestAccuracy, bestScore: $bestScore, attempts: $attempts, completed: $completed, unlocked: $unlocked, completedAt: $completedAt, lastAttemptAt: $lastAttemptAt)';
}


}

/// @nodoc
abstract mixin class _$StageProgressCopyWith<$Res> implements $StageProgressCopyWith<$Res> {
  factory _$StageProgressCopyWith(_StageProgress value, $Res Function(_StageProgress) _then) = __$StageProgressCopyWithImpl;
@override @useResult
$Res call({
 String stageId, double bestAccuracy, int bestScore, int attempts, bool completed, bool unlocked, DateTime? completedAt, DateTime? lastAttemptAt
});




}
/// @nodoc
class __$StageProgressCopyWithImpl<$Res>
    implements _$StageProgressCopyWith<$Res> {
  __$StageProgressCopyWithImpl(this._self, this._then);

  final _StageProgress _self;
  final $Res Function(_StageProgress) _then;

/// Create a copy of StageProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stageId = null,Object? bestAccuracy = null,Object? bestScore = null,Object? attempts = null,Object? completed = null,Object? unlocked = null,Object? completedAt = freezed,Object? lastAttemptAt = freezed,}) {
  return _then(_StageProgress(
stageId: null == stageId ? _self.stageId : stageId // ignore: cast_nullable_to_non_nullable
as String,bestAccuracy: null == bestAccuracy ? _self.bestAccuracy : bestAccuracy // ignore: cast_nullable_to_non_nullable
as double,bestScore: null == bestScore ? _self.bestScore : bestScore // ignore: cast_nullable_to_non_nullable
as int,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,unlocked: null == unlocked ? _self.unlocked : unlocked // ignore: cast_nullable_to_non_nullable
as bool,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastAttemptAt: freezed == lastAttemptAt ? _self.lastAttemptAt : lastAttemptAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
