// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'level_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LevelNote _$LevelNoteFromJson(Map<String, dynamic> json) {
  return _LevelNote.fromJson(json);
}

/// @nodoc
mixin _$LevelNote {
  int get midiNote => throw _privateConstructorUsedError;
  double get startBeat => throw _privateConstructorUsedError;
  double get durationBeats => throw _privateConstructorUsedError;
  int get measureIndex => throw _privateConstructorUsedError;
  int get beatIndex => throw _privateConstructorUsedError;
  bool get isRest => throw _privateConstructorUsedError;
  int get voiceIndex => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LevelNoteCopyWith<LevelNote> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LevelNoteCopyWith<$Res> {
  factory $LevelNoteCopyWith(LevelNote value, $Res Function(LevelNote) then) =
      _$LevelNoteCopyWithImpl<$Res, LevelNote>;
  @useResult
  $Res call(
      {int midiNote,
      double startBeat,
      double durationBeats,
      int measureIndex,
      int beatIndex,
      bool isRest,
      int voiceIndex});
}

/// @nodoc
class _$LevelNoteCopyWithImpl<$Res, $Val extends LevelNote>
    implements $LevelNoteCopyWith<$Res> {
  _$LevelNoteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? midiNote = null,
    Object? startBeat = null,
    Object? durationBeats = null,
    Object? measureIndex = null,
    Object? beatIndex = null,
    Object? isRest = null,
    Object? voiceIndex = null,
  }) {
    return _then(_value.copyWith(
      midiNote: null == midiNote
          ? _value.midiNote
          : midiNote // ignore: cast_nullable_to_non_nullable
              as int,
      startBeat: null == startBeat
          ? _value.startBeat
          : startBeat // ignore: cast_nullable_to_non_nullable
              as double,
      durationBeats: null == durationBeats
          ? _value.durationBeats
          : durationBeats // ignore: cast_nullable_to_non_nullable
              as double,
      measureIndex: null == measureIndex
          ? _value.measureIndex
          : measureIndex // ignore: cast_nullable_to_non_nullable
              as int,
      beatIndex: null == beatIndex
          ? _value.beatIndex
          : beatIndex // ignore: cast_nullable_to_non_nullable
              as int,
      isRest: null == isRest
          ? _value.isRest
          : isRest // ignore: cast_nullable_to_non_nullable
              as bool,
      voiceIndex: null == voiceIndex
          ? _value.voiceIndex
          : voiceIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LevelNoteImplCopyWith<$Res>
    implements $LevelNoteCopyWith<$Res> {
  factory _$$LevelNoteImplCopyWith(
          _$LevelNoteImpl value, $Res Function(_$LevelNoteImpl) then) =
      __$$LevelNoteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int midiNote,
      double startBeat,
      double durationBeats,
      int measureIndex,
      int beatIndex,
      bool isRest,
      int voiceIndex});
}

/// @nodoc
class __$$LevelNoteImplCopyWithImpl<$Res>
    extends _$LevelNoteCopyWithImpl<$Res, _$LevelNoteImpl>
    implements _$$LevelNoteImplCopyWith<$Res> {
  __$$LevelNoteImplCopyWithImpl(
      _$LevelNoteImpl _value, $Res Function(_$LevelNoteImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? midiNote = null,
    Object? startBeat = null,
    Object? durationBeats = null,
    Object? measureIndex = null,
    Object? beatIndex = null,
    Object? isRest = null,
    Object? voiceIndex = null,
  }) {
    return _then(_$LevelNoteImpl(
      midiNote: null == midiNote
          ? _value.midiNote
          : midiNote // ignore: cast_nullable_to_non_nullable
              as int,
      startBeat: null == startBeat
          ? _value.startBeat
          : startBeat // ignore: cast_nullable_to_non_nullable
              as double,
      durationBeats: null == durationBeats
          ? _value.durationBeats
          : durationBeats // ignore: cast_nullable_to_non_nullable
              as double,
      measureIndex: null == measureIndex
          ? _value.measureIndex
          : measureIndex // ignore: cast_nullable_to_non_nullable
              as int,
      beatIndex: null == beatIndex
          ? _value.beatIndex
          : beatIndex // ignore: cast_nullable_to_non_nullable
              as int,
      isRest: null == isRest
          ? _value.isRest
          : isRest // ignore: cast_nullable_to_non_nullable
              as bool,
      voiceIndex: null == voiceIndex
          ? _value.voiceIndex
          : voiceIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LevelNoteImpl with DiagnosticableTreeMixin implements _LevelNote {
  const _$LevelNoteImpl(
      {required this.midiNote,
      required this.startBeat,
      required this.durationBeats,
      required this.measureIndex,
      required this.beatIndex,
      this.isRest = false,
      this.voiceIndex = 0});

  factory _$LevelNoteImpl.fromJson(Map<String, dynamic> json) =>
      _$$LevelNoteImplFromJson(json);

  @override
  final int midiNote;
  @override
  final double startBeat;
  @override
  final double durationBeats;
  @override
  final int measureIndex;
  @override
  final int beatIndex;
  @override
  @JsonKey()
  final bool isRest;
  @override
  @JsonKey()
  final int voiceIndex;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'LevelNote(midiNote: $midiNote, startBeat: $startBeat, durationBeats: $durationBeats, measureIndex: $measureIndex, beatIndex: $beatIndex, isRest: $isRest, voiceIndex: $voiceIndex)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'LevelNote'))
      ..add(DiagnosticsProperty('midiNote', midiNote))
      ..add(DiagnosticsProperty('startBeat', startBeat))
      ..add(DiagnosticsProperty('durationBeats', durationBeats))
      ..add(DiagnosticsProperty('measureIndex', measureIndex))
      ..add(DiagnosticsProperty('beatIndex', beatIndex))
      ..add(DiagnosticsProperty('isRest', isRest))
      ..add(DiagnosticsProperty('voiceIndex', voiceIndex));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LevelNoteImpl &&
            (identical(other.midiNote, midiNote) ||
                other.midiNote == midiNote) &&
            (identical(other.startBeat, startBeat) ||
                other.startBeat == startBeat) &&
            (identical(other.durationBeats, durationBeats) ||
                other.durationBeats == durationBeats) &&
            (identical(other.measureIndex, measureIndex) ||
                other.measureIndex == measureIndex) &&
            (identical(other.beatIndex, beatIndex) ||
                other.beatIndex == beatIndex) &&
            (identical(other.isRest, isRest) || other.isRest == isRest) &&
            (identical(other.voiceIndex, voiceIndex) ||
                other.voiceIndex == voiceIndex));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, midiNote, startBeat,
      durationBeats, measureIndex, beatIndex, isRest, voiceIndex);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LevelNoteImplCopyWith<_$LevelNoteImpl> get copyWith =>
      __$$LevelNoteImplCopyWithImpl<_$LevelNoteImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LevelNoteImplToJson(
      this,
    );
  }
}

abstract class _LevelNote implements LevelNote {
  const factory _LevelNote(
      {required final int midiNote,
      required final double startBeat,
      required final double durationBeats,
      required final int measureIndex,
      required final int beatIndex,
      final bool isRest,
      final int voiceIndex}) = _$LevelNoteImpl;

  factory _LevelNote.fromJson(Map<String, dynamic> json) =
      _$LevelNoteImpl.fromJson;

  @override
  int get midiNote;
  @override
  double get startBeat;
  @override
  double get durationBeats;
  @override
  int get measureIndex;
  @override
  int get beatIndex;
  @override
  bool get isRest;
  @override
  int get voiceIndex;
  @override
  @JsonKey(ignore: true)
  _$$LevelNoteImplCopyWith<_$LevelNoteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LevelMeasure _$LevelMeasureFromJson(Map<String, dynamic> json) {
  return _LevelMeasure.fromJson(json);
}

/// @nodoc
mixin _$LevelMeasure {
  int get index => throw _privateConstructorUsedError;
  double get startBeat => throw _privateConstructorUsedError;
  int get beatsPerMeasure => throw _privateConstructorUsedError;
  List<LevelNote> get notes => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LevelMeasureCopyWith<LevelMeasure> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LevelMeasureCopyWith<$Res> {
  factory $LevelMeasureCopyWith(
          LevelMeasure value, $Res Function(LevelMeasure) then) =
      _$LevelMeasureCopyWithImpl<$Res, LevelMeasure>;
  @useResult
  $Res call(
      {int index,
      double startBeat,
      int beatsPerMeasure,
      List<LevelNote> notes});
}

/// @nodoc
class _$LevelMeasureCopyWithImpl<$Res, $Val extends LevelMeasure>
    implements $LevelMeasureCopyWith<$Res> {
  _$LevelMeasureCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? index = null,
    Object? startBeat = null,
    Object? beatsPerMeasure = null,
    Object? notes = null,
  }) {
    return _then(_value.copyWith(
      index: null == index
          ? _value.index
          : index // ignore: cast_nullable_to_non_nullable
              as int,
      startBeat: null == startBeat
          ? _value.startBeat
          : startBeat // ignore: cast_nullable_to_non_nullable
              as double,
      beatsPerMeasure: null == beatsPerMeasure
          ? _value.beatsPerMeasure
          : beatsPerMeasure // ignore: cast_nullable_to_non_nullable
              as int,
      notes: null == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as List<LevelNote>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LevelMeasureImplCopyWith<$Res>
    implements $LevelMeasureCopyWith<$Res> {
  factory _$$LevelMeasureImplCopyWith(
          _$LevelMeasureImpl value, $Res Function(_$LevelMeasureImpl) then) =
      __$$LevelMeasureImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int index,
      double startBeat,
      int beatsPerMeasure,
      List<LevelNote> notes});
}

/// @nodoc
class __$$LevelMeasureImplCopyWithImpl<$Res>
    extends _$LevelMeasureCopyWithImpl<$Res, _$LevelMeasureImpl>
    implements _$$LevelMeasureImplCopyWith<$Res> {
  __$$LevelMeasureImplCopyWithImpl(
      _$LevelMeasureImpl _value, $Res Function(_$LevelMeasureImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? index = null,
    Object? startBeat = null,
    Object? beatsPerMeasure = null,
    Object? notes = null,
  }) {
    return _then(_$LevelMeasureImpl(
      index: null == index
          ? _value.index
          : index // ignore: cast_nullable_to_non_nullable
              as int,
      startBeat: null == startBeat
          ? _value.startBeat
          : startBeat // ignore: cast_nullable_to_non_nullable
              as double,
      beatsPerMeasure: null == beatsPerMeasure
          ? _value.beatsPerMeasure
          : beatsPerMeasure // ignore: cast_nullable_to_non_nullable
              as int,
      notes: null == notes
          ? _value._notes
          : notes // ignore: cast_nullable_to_non_nullable
              as List<LevelNote>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LevelMeasureImpl with DiagnosticableTreeMixin implements _LevelMeasure {
  const _$LevelMeasureImpl(
      {required this.index,
      required this.startBeat,
      required this.beatsPerMeasure,
      required final List<LevelNote> notes})
      : _notes = notes;

  factory _$LevelMeasureImpl.fromJson(Map<String, dynamic> json) =>
      _$$LevelMeasureImplFromJson(json);

  @override
  final int index;
  @override
  final double startBeat;
  @override
  final int beatsPerMeasure;
  final List<LevelNote> _notes;
  @override
  List<LevelNote> get notes {
    if (_notes is EqualUnmodifiableListView) return _notes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_notes);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'LevelMeasure(index: $index, startBeat: $startBeat, beatsPerMeasure: $beatsPerMeasure, notes: $notes)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'LevelMeasure'))
      ..add(DiagnosticsProperty('index', index))
      ..add(DiagnosticsProperty('startBeat', startBeat))
      ..add(DiagnosticsProperty('beatsPerMeasure', beatsPerMeasure))
      ..add(DiagnosticsProperty('notes', notes));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LevelMeasureImpl &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.startBeat, startBeat) ||
                other.startBeat == startBeat) &&
            (identical(other.beatsPerMeasure, beatsPerMeasure) ||
                other.beatsPerMeasure == beatsPerMeasure) &&
            const DeepCollectionEquality().equals(other._notes, _notes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, index, startBeat,
      beatsPerMeasure, const DeepCollectionEquality().hash(_notes));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LevelMeasureImplCopyWith<_$LevelMeasureImpl> get copyWith =>
      __$$LevelMeasureImplCopyWithImpl<_$LevelMeasureImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LevelMeasureImplToJson(
      this,
    );
  }
}

abstract class _LevelMeasure implements LevelMeasure {
  const factory _LevelMeasure(
      {required final int index,
      required final double startBeat,
      required final int beatsPerMeasure,
      required final List<LevelNote> notes}) = _$LevelMeasureImpl;

  factory _LevelMeasure.fromJson(Map<String, dynamic> json) =
      _$LevelMeasureImpl.fromJson;

  @override
  int get index;
  @override
  double get startBeat;
  @override
  int get beatsPerMeasure;
  @override
  List<LevelNote> get notes;
  @override
  @JsonKey(ignore: true)
  _$$LevelMeasureImplCopyWith<_$LevelMeasureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LevelModel _$LevelModelFromJson(Map<String, dynamic> json) {
  return _LevelModel.fromJson(json);
}

/// @nodoc
mixin _$LevelModel {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  int get tempo => throw _privateConstructorUsedError;
  int get beatsPerMeasure => throw _privateConstructorUsedError;
  int get totalMeasures => throw _privateConstructorUsedError;
  List<LevelMeasure> get measures => throw _privateConstructorUsedError;
  int get clefOctave =>
      throw _privateConstructorUsedError; // 4 = middle C octave
  int get transpose => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LevelModelCopyWith<LevelModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LevelModelCopyWith<$Res> {
  factory $LevelModelCopyWith(
          LevelModel value, $Res Function(LevelModel) then) =
      _$LevelModelCopyWithImpl<$Res, LevelModel>;
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      int tempo,
      int beatsPerMeasure,
      int totalMeasures,
      List<LevelMeasure> measures,
      int clefOctave,
      int transpose});
}

/// @nodoc
class _$LevelModelCopyWithImpl<$Res, $Val extends LevelModel>
    implements $LevelModelCopyWith<$Res> {
  _$LevelModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? tempo = null,
    Object? beatsPerMeasure = null,
    Object? totalMeasures = null,
    Object? measures = null,
    Object? clefOctave = null,
    Object? transpose = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      tempo: null == tempo
          ? _value.tempo
          : tempo // ignore: cast_nullable_to_non_nullable
              as int,
      beatsPerMeasure: null == beatsPerMeasure
          ? _value.beatsPerMeasure
          : beatsPerMeasure // ignore: cast_nullable_to_non_nullable
              as int,
      totalMeasures: null == totalMeasures
          ? _value.totalMeasures
          : totalMeasures // ignore: cast_nullable_to_non_nullable
              as int,
      measures: null == measures
          ? _value.measures
          : measures // ignore: cast_nullable_to_non_nullable
              as List<LevelMeasure>,
      clefOctave: null == clefOctave
          ? _value.clefOctave
          : clefOctave // ignore: cast_nullable_to_non_nullable
              as int,
      transpose: null == transpose
          ? _value.transpose
          : transpose // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LevelModelImplCopyWith<$Res>
    implements $LevelModelCopyWith<$Res> {
  factory _$$LevelModelImplCopyWith(
          _$LevelModelImpl value, $Res Function(_$LevelModelImpl) then) =
      __$$LevelModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      int tempo,
      int beatsPerMeasure,
      int totalMeasures,
      List<LevelMeasure> measures,
      int clefOctave,
      int transpose});
}

/// @nodoc
class __$$LevelModelImplCopyWithImpl<$Res>
    extends _$LevelModelCopyWithImpl<$Res, _$LevelModelImpl>
    implements _$$LevelModelImplCopyWith<$Res> {
  __$$LevelModelImplCopyWithImpl(
      _$LevelModelImpl _value, $Res Function(_$LevelModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? tempo = null,
    Object? beatsPerMeasure = null,
    Object? totalMeasures = null,
    Object? measures = null,
    Object? clefOctave = null,
    Object? transpose = null,
  }) {
    return _then(_$LevelModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      tempo: null == tempo
          ? _value.tempo
          : tempo // ignore: cast_nullable_to_non_nullable
              as int,
      beatsPerMeasure: null == beatsPerMeasure
          ? _value.beatsPerMeasure
          : beatsPerMeasure // ignore: cast_nullable_to_non_nullable
              as int,
      totalMeasures: null == totalMeasures
          ? _value.totalMeasures
          : totalMeasures // ignore: cast_nullable_to_non_nullable
              as int,
      measures: null == measures
          ? _value._measures
          : measures // ignore: cast_nullable_to_non_nullable
              as List<LevelMeasure>,
      clefOctave: null == clefOctave
          ? _value.clefOctave
          : clefOctave // ignore: cast_nullable_to_non_nullable
              as int,
      transpose: null == transpose
          ? _value.transpose
          : transpose // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LevelModelImpl with DiagnosticableTreeMixin implements _LevelModel {
  const _$LevelModelImpl(
      {required this.id,
      required this.title,
      required this.description,
      required this.tempo,
      required this.beatsPerMeasure,
      required this.totalMeasures,
      required final List<LevelMeasure> measures,
      this.clefOctave = 4,
      this.transpose = 0})
      : _measures = measures;

  factory _$LevelModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$LevelModelImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final int tempo;
  @override
  final int beatsPerMeasure;
  @override
  final int totalMeasures;
  final List<LevelMeasure> _measures;
  @override
  List<LevelMeasure> get measures {
    if (_measures is EqualUnmodifiableListView) return _measures;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_measures);
  }

  @override
  @JsonKey()
  final int clefOctave;
// 4 = middle C octave
  @override
  @JsonKey()
  final int transpose;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'LevelModel(id: $id, title: $title, description: $description, tempo: $tempo, beatsPerMeasure: $beatsPerMeasure, totalMeasures: $totalMeasures, measures: $measures, clefOctave: $clefOctave, transpose: $transpose)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'LevelModel'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('title', title))
      ..add(DiagnosticsProperty('description', description))
      ..add(DiagnosticsProperty('tempo', tempo))
      ..add(DiagnosticsProperty('beatsPerMeasure', beatsPerMeasure))
      ..add(DiagnosticsProperty('totalMeasures', totalMeasures))
      ..add(DiagnosticsProperty('measures', measures))
      ..add(DiagnosticsProperty('clefOctave', clefOctave))
      ..add(DiagnosticsProperty('transpose', transpose));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LevelModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.tempo, tempo) || other.tempo == tempo) &&
            (identical(other.beatsPerMeasure, beatsPerMeasure) ||
                other.beatsPerMeasure == beatsPerMeasure) &&
            (identical(other.totalMeasures, totalMeasures) ||
                other.totalMeasures == totalMeasures) &&
            const DeepCollectionEquality().equals(other._measures, _measures) &&
            (identical(other.clefOctave, clefOctave) ||
                other.clefOctave == clefOctave) &&
            (identical(other.transpose, transpose) ||
                other.transpose == transpose));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      description,
      tempo,
      beatsPerMeasure,
      totalMeasures,
      const DeepCollectionEquality().hash(_measures),
      clefOctave,
      transpose);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LevelModelImplCopyWith<_$LevelModelImpl> get copyWith =>
      __$$LevelModelImplCopyWithImpl<_$LevelModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LevelModelImplToJson(
      this,
    );
  }
}

abstract class _LevelModel implements LevelModel {
  const factory _LevelModel(
      {required final String id,
      required final String title,
      required final String description,
      required final int tempo,
      required final int beatsPerMeasure,
      required final int totalMeasures,
      required final List<LevelMeasure> measures,
      final int clefOctave,
      final int transpose}) = _$LevelModelImpl;

  factory _LevelModel.fromJson(Map<String, dynamic> json) =
      _$LevelModelImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get description;
  @override
  int get tempo;
  @override
  int get beatsPerMeasure;
  @override
  int get totalMeasures;
  @override
  List<LevelMeasure> get measures;
  @override
  int get clefOctave;
  @override // 4 = middle C octave
  int get transpose;
  @override
  @JsonKey(ignore: true)
  _$$LevelModelImplCopyWith<_$LevelModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StageModel _$StageModelFromJson(Map<String, dynamic> json) {
  return _StageModel.fromJson(json);
}

/// @nodoc
mixin _$StageModel {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  Difficulty get difficulty => throw _privateConstructorUsedError;
  LevelModel get level => throw _privateConstructorUsedError;
  int get order => throw _privateConstructorUsedError;
  List<String> get prerequisites => throw _privateConstructorUsedError;
  int get xpReward => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StageModelCopyWith<StageModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StageModelCopyWith<$Res> {
  factory $StageModelCopyWith(
          StageModel value, $Res Function(StageModel) then) =
      _$StageModelCopyWithImpl<$Res, StageModel>;
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      Difficulty difficulty,
      LevelModel level,
      int order,
      List<String> prerequisites,
      int xpReward});

  $LevelModelCopyWith<$Res> get level;
}

/// @nodoc
class _$StageModelCopyWithImpl<$Res, $Val extends StageModel>
    implements $StageModelCopyWith<$Res> {
  _$StageModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? difficulty = null,
    Object? level = null,
    Object? order = null,
    Object? prerequisites = null,
    Object? xpReward = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as Difficulty,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as LevelModel,
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
      prerequisites: null == prerequisites
          ? _value.prerequisites
          : prerequisites // ignore: cast_nullable_to_non_nullable
              as List<String>,
      xpReward: null == xpReward
          ? _value.xpReward
          : xpReward // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $LevelModelCopyWith<$Res> get level {
    return $LevelModelCopyWith<$Res>(_value.level, (value) {
      return _then(_value.copyWith(level: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$StageModelImplCopyWith<$Res>
    implements $StageModelCopyWith<$Res> {
  factory _$$StageModelImplCopyWith(
          _$StageModelImpl value, $Res Function(_$StageModelImpl) then) =
      __$$StageModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      Difficulty difficulty,
      LevelModel level,
      int order,
      List<String> prerequisites,
      int xpReward});

  @override
  $LevelModelCopyWith<$Res> get level;
}

/// @nodoc
class __$$StageModelImplCopyWithImpl<$Res>
    extends _$StageModelCopyWithImpl<$Res, _$StageModelImpl>
    implements _$$StageModelImplCopyWith<$Res> {
  __$$StageModelImplCopyWithImpl(
      _$StageModelImpl _value, $Res Function(_$StageModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? difficulty = null,
    Object? level = null,
    Object? order = null,
    Object? prerequisites = null,
    Object? xpReward = null,
  }) {
    return _then(_$StageModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as Difficulty,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as LevelModel,
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
      prerequisites: null == prerequisites
          ? _value._prerequisites
          : prerequisites // ignore: cast_nullable_to_non_nullable
              as List<String>,
      xpReward: null == xpReward
          ? _value.xpReward
          : xpReward // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StageModelImpl with DiagnosticableTreeMixin implements _StageModel {
  const _$StageModelImpl(
      {required this.id,
      required this.title,
      required this.description,
      required this.difficulty,
      required this.level,
      this.order = 0,
      final List<String> prerequisites = const [],
      this.xpReward = 0})
      : _prerequisites = prerequisites;

  factory _$StageModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$StageModelImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final Difficulty difficulty;
  @override
  final LevelModel level;
  @override
  @JsonKey()
  final int order;
  final List<String> _prerequisites;
  @override
  @JsonKey()
  List<String> get prerequisites {
    if (_prerequisites is EqualUnmodifiableListView) return _prerequisites;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_prerequisites);
  }

  @override
  @JsonKey()
  final int xpReward;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'StageModel(id: $id, title: $title, description: $description, difficulty: $difficulty, level: $level, order: $order, prerequisites: $prerequisites, xpReward: $xpReward)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'StageModel'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('title', title))
      ..add(DiagnosticsProperty('description', description))
      ..add(DiagnosticsProperty('difficulty', difficulty))
      ..add(DiagnosticsProperty('level', level))
      ..add(DiagnosticsProperty('order', order))
      ..add(DiagnosticsProperty('prerequisites', prerequisites))
      ..add(DiagnosticsProperty('xpReward', xpReward));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StageModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.order, order) || other.order == order) &&
            const DeepCollectionEquality()
                .equals(other._prerequisites, _prerequisites) &&
            (identical(other.xpReward, xpReward) ||
                other.xpReward == xpReward));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      description,
      difficulty,
      level,
      order,
      const DeepCollectionEquality().hash(_prerequisites),
      xpReward);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StageModelImplCopyWith<_$StageModelImpl> get copyWith =>
      __$$StageModelImplCopyWithImpl<_$StageModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StageModelImplToJson(
      this,
    );
  }
}

abstract class _StageModel implements StageModel {
  const factory _StageModel(
      {required final String id,
      required final String title,
      required final String description,
      required final Difficulty difficulty,
      required final LevelModel level,
      final int order,
      final List<String> prerequisites,
      final int xpReward}) = _$StageModelImpl;

  factory _StageModel.fromJson(Map<String, dynamic> json) =
      _$StageModelImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get description;
  @override
  Difficulty get difficulty;
  @override
  LevelModel get level;
  @override
  int get order;
  @override
  List<String> get prerequisites;
  @override
  int get xpReward;
  @override
  @JsonKey(ignore: true)
  _$$StageModelImplCopyWith<_$StageModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StageProgress _$StageProgressFromJson(Map<String, dynamic> json) {
  return _StageProgress.fromJson(json);
}

/// @nodoc
mixin _$StageProgress {
  String get stageId => throw _privateConstructorUsedError;
  double get bestAccuracy => throw _privateConstructorUsedError;
  int get bestScore => throw _privateConstructorUsedError;
  int get attempts => throw _privateConstructorUsedError;
  bool get completed => throw _privateConstructorUsedError;
  bool get unlocked => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;
  DateTime? get lastAttemptAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StageProgressCopyWith<StageProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StageProgressCopyWith<$Res> {
  factory $StageProgressCopyWith(
          StageProgress value, $Res Function(StageProgress) then) =
      _$StageProgressCopyWithImpl<$Res, StageProgress>;
  @useResult
  $Res call(
      {String stageId,
      double bestAccuracy,
      int bestScore,
      int attempts,
      bool completed,
      bool unlocked,
      DateTime? completedAt,
      DateTime? lastAttemptAt});
}

/// @nodoc
class _$StageProgressCopyWithImpl<$Res, $Val extends StageProgress>
    implements $StageProgressCopyWith<$Res> {
  _$StageProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stageId = null,
    Object? bestAccuracy = null,
    Object? bestScore = null,
    Object? attempts = null,
    Object? completed = null,
    Object? unlocked = null,
    Object? completedAt = freezed,
    Object? lastAttemptAt = freezed,
  }) {
    return _then(_value.copyWith(
      stageId: null == stageId
          ? _value.stageId
          : stageId // ignore: cast_nullable_to_non_nullable
              as String,
      bestAccuracy: null == bestAccuracy
          ? _value.bestAccuracy
          : bestAccuracy // ignore: cast_nullable_to_non_nullable
              as double,
      bestScore: null == bestScore
          ? _value.bestScore
          : bestScore // ignore: cast_nullable_to_non_nullable
              as int,
      attempts: null == attempts
          ? _value.attempts
          : attempts // ignore: cast_nullable_to_non_nullable
              as int,
      completed: null == completed
          ? _value.completed
          : completed // ignore: cast_nullable_to_non_nullable
              as bool,
      unlocked: null == unlocked
          ? _value.unlocked
          : unlocked // ignore: cast_nullable_to_non_nullable
              as bool,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastAttemptAt: freezed == lastAttemptAt
          ? _value.lastAttemptAt
          : lastAttemptAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StageProgressImplCopyWith<$Res>
    implements $StageProgressCopyWith<$Res> {
  factory _$$StageProgressImplCopyWith(
          _$StageProgressImpl value, $Res Function(_$StageProgressImpl) then) =
      __$$StageProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String stageId,
      double bestAccuracy,
      int bestScore,
      int attempts,
      bool completed,
      bool unlocked,
      DateTime? completedAt,
      DateTime? lastAttemptAt});
}

/// @nodoc
class __$$StageProgressImplCopyWithImpl<$Res>
    extends _$StageProgressCopyWithImpl<$Res, _$StageProgressImpl>
    implements _$$StageProgressImplCopyWith<$Res> {
  __$$StageProgressImplCopyWithImpl(
      _$StageProgressImpl _value, $Res Function(_$StageProgressImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stageId = null,
    Object? bestAccuracy = null,
    Object? bestScore = null,
    Object? attempts = null,
    Object? completed = null,
    Object? unlocked = null,
    Object? completedAt = freezed,
    Object? lastAttemptAt = freezed,
  }) {
    return _then(_$StageProgressImpl(
      stageId: null == stageId
          ? _value.stageId
          : stageId // ignore: cast_nullable_to_non_nullable
              as String,
      bestAccuracy: null == bestAccuracy
          ? _value.bestAccuracy
          : bestAccuracy // ignore: cast_nullable_to_non_nullable
              as double,
      bestScore: null == bestScore
          ? _value.bestScore
          : bestScore // ignore: cast_nullable_to_non_nullable
              as int,
      attempts: null == attempts
          ? _value.attempts
          : attempts // ignore: cast_nullable_to_non_nullable
              as int,
      completed: null == completed
          ? _value.completed
          : completed // ignore: cast_nullable_to_non_nullable
              as bool,
      unlocked: null == unlocked
          ? _value.unlocked
          : unlocked // ignore: cast_nullable_to_non_nullable
              as bool,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastAttemptAt: freezed == lastAttemptAt
          ? _value.lastAttemptAt
          : lastAttemptAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StageProgressImpl
    with DiagnosticableTreeMixin
    implements _StageProgress {
  const _$StageProgressImpl(
      {required this.stageId,
      this.bestAccuracy = 0,
      this.bestScore = 0,
      this.attempts = 0,
      this.completed = false,
      this.unlocked = false,
      this.completedAt,
      this.lastAttemptAt});

  factory _$StageProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$StageProgressImplFromJson(json);

  @override
  final String stageId;
  @override
  @JsonKey()
  final double bestAccuracy;
  @override
  @JsonKey()
  final int bestScore;
  @override
  @JsonKey()
  final int attempts;
  @override
  @JsonKey()
  final bool completed;
  @override
  @JsonKey()
  final bool unlocked;
  @override
  final DateTime? completedAt;
  @override
  final DateTime? lastAttemptAt;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'StageProgress(stageId: $stageId, bestAccuracy: $bestAccuracy, bestScore: $bestScore, attempts: $attempts, completed: $completed, unlocked: $unlocked, completedAt: $completedAt, lastAttemptAt: $lastAttemptAt)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'StageProgress'))
      ..add(DiagnosticsProperty('stageId', stageId))
      ..add(DiagnosticsProperty('bestAccuracy', bestAccuracy))
      ..add(DiagnosticsProperty('bestScore', bestScore))
      ..add(DiagnosticsProperty('attempts', attempts))
      ..add(DiagnosticsProperty('completed', completed))
      ..add(DiagnosticsProperty('unlocked', unlocked))
      ..add(DiagnosticsProperty('completedAt', completedAt))
      ..add(DiagnosticsProperty('lastAttemptAt', lastAttemptAt));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StageProgressImpl &&
            (identical(other.stageId, stageId) || other.stageId == stageId) &&
            (identical(other.bestAccuracy, bestAccuracy) ||
                other.bestAccuracy == bestAccuracy) &&
            (identical(other.bestScore, bestScore) ||
                other.bestScore == bestScore) &&
            (identical(other.attempts, attempts) ||
                other.attempts == attempts) &&
            (identical(other.completed, completed) ||
                other.completed == completed) &&
            (identical(other.unlocked, unlocked) ||
                other.unlocked == unlocked) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.lastAttemptAt, lastAttemptAt) ||
                other.lastAttemptAt == lastAttemptAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, stageId, bestAccuracy, bestScore,
      attempts, completed, unlocked, completedAt, lastAttemptAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StageProgressImplCopyWith<_$StageProgressImpl> get copyWith =>
      __$$StageProgressImplCopyWithImpl<_$StageProgressImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StageProgressImplToJson(
      this,
    );
  }
}

abstract class _StageProgress implements StageProgress {
  const factory _StageProgress(
      {required final String stageId,
      final double bestAccuracy,
      final int bestScore,
      final int attempts,
      final bool completed,
      final bool unlocked,
      final DateTime? completedAt,
      final DateTime? lastAttemptAt}) = _$StageProgressImpl;

  factory _StageProgress.fromJson(Map<String, dynamic> json) =
      _$StageProgressImpl.fromJson;

  @override
  String get stageId;
  @override
  double get bestAccuracy;
  @override
  int get bestScore;
  @override
  int get attempts;
  @override
  bool get completed;
  @override
  bool get unlocked;
  @override
  DateTime? get completedAt;
  @override
  DateTime? get lastAttemptAt;
  @override
  @JsonKey(ignore: true)
  _$$StageProgressImplCopyWith<_$StageProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
