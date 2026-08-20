// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'engine_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

NoteHitResult _$NoteHitResultFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'perfect':
      return _NoteHitResultPerfect.fromJson(json);
    case 'good':
      return _NoteHitResultGood.fromJson(json);
    case 'okay':
      return _NoteHitResultOkay.fromJson(json);
    case 'missed':
      return _NoteHitResultMissed.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'runtimeType', 'NoteHitResult',
          'Invalid union type "${json['runtimeType']}"!');
  }
}

/// @nodoc
mixin _$NoteHitResult {
  int get noteIndex => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int noteIndex, double timingError) perfect,
    required TResult Function(int noteIndex, double timingError) good,
    required TResult Function(int noteIndex, double timingError) okay,
    required TResult Function(int noteIndex) missed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int noteIndex, double timingError)? perfect,
    TResult? Function(int noteIndex, double timingError)? good,
    TResult? Function(int noteIndex, double timingError)? okay,
    TResult? Function(int noteIndex)? missed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int noteIndex, double timingError)? perfect,
    TResult Function(int noteIndex, double timingError)? good,
    TResult Function(int noteIndex, double timingError)? okay,
    TResult Function(int noteIndex)? missed,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NoteHitResultPerfect value) perfect,
    required TResult Function(_NoteHitResultGood value) good,
    required TResult Function(_NoteHitResultOkay value) okay,
    required TResult Function(_NoteHitResultMissed value) missed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NoteHitResultPerfect value)? perfect,
    TResult? Function(_NoteHitResultGood value)? good,
    TResult? Function(_NoteHitResultOkay value)? okay,
    TResult? Function(_NoteHitResultMissed value)? missed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NoteHitResultPerfect value)? perfect,
    TResult Function(_NoteHitResultGood value)? good,
    TResult Function(_NoteHitResultOkay value)? okay,
    TResult Function(_NoteHitResultMissed value)? missed,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $NoteHitResultCopyWith<NoteHitResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NoteHitResultCopyWith<$Res> {
  factory $NoteHitResultCopyWith(
          NoteHitResult value, $Res Function(NoteHitResult) then) =
      _$NoteHitResultCopyWithImpl<$Res, NoteHitResult>;
  @useResult
  $Res call({int noteIndex});
}

/// @nodoc
class _$NoteHitResultCopyWithImpl<$Res, $Val extends NoteHitResult>
    implements $NoteHitResultCopyWith<$Res> {
  _$NoteHitResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? noteIndex = null,
  }) {
    return _then(_value.copyWith(
      noteIndex: null == noteIndex
          ? _value.noteIndex
          : noteIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NoteHitResultPerfectImplCopyWith<$Res>
    implements $NoteHitResultCopyWith<$Res> {
  factory _$$NoteHitResultPerfectImplCopyWith(_$NoteHitResultPerfectImpl value,
          $Res Function(_$NoteHitResultPerfectImpl) then) =
      __$$NoteHitResultPerfectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int noteIndex, double timingError});
}

/// @nodoc
class __$$NoteHitResultPerfectImplCopyWithImpl<$Res>
    extends _$NoteHitResultCopyWithImpl<$Res, _$NoteHitResultPerfectImpl>
    implements _$$NoteHitResultPerfectImplCopyWith<$Res> {
  __$$NoteHitResultPerfectImplCopyWithImpl(_$NoteHitResultPerfectImpl _value,
      $Res Function(_$NoteHitResultPerfectImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? noteIndex = null,
    Object? timingError = null,
  }) {
    return _then(_$NoteHitResultPerfectImpl(
      noteIndex: null == noteIndex
          ? _value.noteIndex
          : noteIndex // ignore: cast_nullable_to_non_nullable
              as int,
      timingError: null == timingError
          ? _value.timingError
          : timingError // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NoteHitResultPerfectImpl extends _NoteHitResultPerfect {
  const _$NoteHitResultPerfectImpl(
      {required this.noteIndex, required this.timingError, final String? $type})
      : $type = $type ?? 'perfect',
        super._();

  factory _$NoteHitResultPerfectImpl.fromJson(Map<String, dynamic> json) =>
      _$$NoteHitResultPerfectImplFromJson(json);

  @override
  final int noteIndex;
  @override
  final double timingError;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'NoteHitResult.perfect(noteIndex: $noteIndex, timingError: $timingError)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NoteHitResultPerfectImpl &&
            (identical(other.noteIndex, noteIndex) ||
                other.noteIndex == noteIndex) &&
            (identical(other.timingError, timingError) ||
                other.timingError == timingError));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, noteIndex, timingError);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NoteHitResultPerfectImplCopyWith<_$NoteHitResultPerfectImpl>
      get copyWith =>
          __$$NoteHitResultPerfectImplCopyWithImpl<_$NoteHitResultPerfectImpl>(
              this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int noteIndex, double timingError) perfect,
    required TResult Function(int noteIndex, double timingError) good,
    required TResult Function(int noteIndex, double timingError) okay,
    required TResult Function(int noteIndex) missed,
  }) {
    return perfect(noteIndex, timingError);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int noteIndex, double timingError)? perfect,
    TResult? Function(int noteIndex, double timingError)? good,
    TResult? Function(int noteIndex, double timingError)? okay,
    TResult? Function(int noteIndex)? missed,
  }) {
    return perfect?.call(noteIndex, timingError);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int noteIndex, double timingError)? perfect,
    TResult Function(int noteIndex, double timingError)? good,
    TResult Function(int noteIndex, double timingError)? okay,
    TResult Function(int noteIndex)? missed,
    required TResult orElse(),
  }) {
    if (perfect != null) {
      return perfect(noteIndex, timingError);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NoteHitResultPerfect value) perfect,
    required TResult Function(_NoteHitResultGood value) good,
    required TResult Function(_NoteHitResultOkay value) okay,
    required TResult Function(_NoteHitResultMissed value) missed,
  }) {
    return perfect(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NoteHitResultPerfect value)? perfect,
    TResult? Function(_NoteHitResultGood value)? good,
    TResult? Function(_NoteHitResultOkay value)? okay,
    TResult? Function(_NoteHitResultMissed value)? missed,
  }) {
    return perfect?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NoteHitResultPerfect value)? perfect,
    TResult Function(_NoteHitResultGood value)? good,
    TResult Function(_NoteHitResultOkay value)? okay,
    TResult Function(_NoteHitResultMissed value)? missed,
    required TResult orElse(),
  }) {
    if (perfect != null) {
      return perfect(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$NoteHitResultPerfectImplToJson(
      this,
    );
  }
}

abstract class _NoteHitResultPerfect extends NoteHitResult {
  const factory _NoteHitResultPerfect(
      {required final int noteIndex,
      required final double timingError}) = _$NoteHitResultPerfectImpl;
  const _NoteHitResultPerfect._() : super._();

  factory _NoteHitResultPerfect.fromJson(Map<String, dynamic> json) =
      _$NoteHitResultPerfectImpl.fromJson;

  @override
  int get noteIndex;
  double get timingError;
  @override
  @JsonKey(ignore: true)
  _$$NoteHitResultPerfectImplCopyWith<_$NoteHitResultPerfectImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NoteHitResultGoodImplCopyWith<$Res>
    implements $NoteHitResultCopyWith<$Res> {
  factory _$$NoteHitResultGoodImplCopyWith(_$NoteHitResultGoodImpl value,
          $Res Function(_$NoteHitResultGoodImpl) then) =
      __$$NoteHitResultGoodImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int noteIndex, double timingError});
}

/// @nodoc
class __$$NoteHitResultGoodImplCopyWithImpl<$Res>
    extends _$NoteHitResultCopyWithImpl<$Res, _$NoteHitResultGoodImpl>
    implements _$$NoteHitResultGoodImplCopyWith<$Res> {
  __$$NoteHitResultGoodImplCopyWithImpl(_$NoteHitResultGoodImpl _value,
      $Res Function(_$NoteHitResultGoodImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? noteIndex = null,
    Object? timingError = null,
  }) {
    return _then(_$NoteHitResultGoodImpl(
      noteIndex: null == noteIndex
          ? _value.noteIndex
          : noteIndex // ignore: cast_nullable_to_non_nullable
              as int,
      timingError: null == timingError
          ? _value.timingError
          : timingError // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NoteHitResultGoodImpl extends _NoteHitResultGood {
  const _$NoteHitResultGoodImpl(
      {required this.noteIndex, required this.timingError, final String? $type})
      : $type = $type ?? 'good',
        super._();

  factory _$NoteHitResultGoodImpl.fromJson(Map<String, dynamic> json) =>
      _$$NoteHitResultGoodImplFromJson(json);

  @override
  final int noteIndex;
  @override
  final double timingError;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'NoteHitResult.good(noteIndex: $noteIndex, timingError: $timingError)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NoteHitResultGoodImpl &&
            (identical(other.noteIndex, noteIndex) ||
                other.noteIndex == noteIndex) &&
            (identical(other.timingError, timingError) ||
                other.timingError == timingError));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, noteIndex, timingError);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NoteHitResultGoodImplCopyWith<_$NoteHitResultGoodImpl> get copyWith =>
      __$$NoteHitResultGoodImplCopyWithImpl<_$NoteHitResultGoodImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int noteIndex, double timingError) perfect,
    required TResult Function(int noteIndex, double timingError) good,
    required TResult Function(int noteIndex, double timingError) okay,
    required TResult Function(int noteIndex) missed,
  }) {
    return good(noteIndex, timingError);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int noteIndex, double timingError)? perfect,
    TResult? Function(int noteIndex, double timingError)? good,
    TResult? Function(int noteIndex, double timingError)? okay,
    TResult? Function(int noteIndex)? missed,
  }) {
    return good?.call(noteIndex, timingError);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int noteIndex, double timingError)? perfect,
    TResult Function(int noteIndex, double timingError)? good,
    TResult Function(int noteIndex, double timingError)? okay,
    TResult Function(int noteIndex)? missed,
    required TResult orElse(),
  }) {
    if (good != null) {
      return good(noteIndex, timingError);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NoteHitResultPerfect value) perfect,
    required TResult Function(_NoteHitResultGood value) good,
    required TResult Function(_NoteHitResultOkay value) okay,
    required TResult Function(_NoteHitResultMissed value) missed,
  }) {
    return good(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NoteHitResultPerfect value)? perfect,
    TResult? Function(_NoteHitResultGood value)? good,
    TResult? Function(_NoteHitResultOkay value)? okay,
    TResult? Function(_NoteHitResultMissed value)? missed,
  }) {
    return good?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NoteHitResultPerfect value)? perfect,
    TResult Function(_NoteHitResultGood value)? good,
    TResult Function(_NoteHitResultOkay value)? okay,
    TResult Function(_NoteHitResultMissed value)? missed,
    required TResult orElse(),
  }) {
    if (good != null) {
      return good(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$NoteHitResultGoodImplToJson(
      this,
    );
  }
}

abstract class _NoteHitResultGood extends NoteHitResult {
  const factory _NoteHitResultGood(
      {required final int noteIndex,
      required final double timingError}) = _$NoteHitResultGoodImpl;
  const _NoteHitResultGood._() : super._();

  factory _NoteHitResultGood.fromJson(Map<String, dynamic> json) =
      _$NoteHitResultGoodImpl.fromJson;

  @override
  int get noteIndex;
  double get timingError;
  @override
  @JsonKey(ignore: true)
  _$$NoteHitResultGoodImplCopyWith<_$NoteHitResultGoodImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NoteHitResultOkayImplCopyWith<$Res>
    implements $NoteHitResultCopyWith<$Res> {
  factory _$$NoteHitResultOkayImplCopyWith(_$NoteHitResultOkayImpl value,
          $Res Function(_$NoteHitResultOkayImpl) then) =
      __$$NoteHitResultOkayImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int noteIndex, double timingError});
}

/// @nodoc
class __$$NoteHitResultOkayImplCopyWithImpl<$Res>
    extends _$NoteHitResultCopyWithImpl<$Res, _$NoteHitResultOkayImpl>
    implements _$$NoteHitResultOkayImplCopyWith<$Res> {
  __$$NoteHitResultOkayImplCopyWithImpl(_$NoteHitResultOkayImpl _value,
      $Res Function(_$NoteHitResultOkayImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? noteIndex = null,
    Object? timingError = null,
  }) {
    return _then(_$NoteHitResultOkayImpl(
      noteIndex: null == noteIndex
          ? _value.noteIndex
          : noteIndex // ignore: cast_nullable_to_non_nullable
              as int,
      timingError: null == timingError
          ? _value.timingError
          : timingError // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NoteHitResultOkayImpl extends _NoteHitResultOkay {
  const _$NoteHitResultOkayImpl(
      {required this.noteIndex, required this.timingError, final String? $type})
      : $type = $type ?? 'okay',
        super._();

  factory _$NoteHitResultOkayImpl.fromJson(Map<String, dynamic> json) =>
      _$$NoteHitResultOkayImplFromJson(json);

  @override
  final int noteIndex;
  @override
  final double timingError;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'NoteHitResult.okay(noteIndex: $noteIndex, timingError: $timingError)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NoteHitResultOkayImpl &&
            (identical(other.noteIndex, noteIndex) ||
                other.noteIndex == noteIndex) &&
            (identical(other.timingError, timingError) ||
                other.timingError == timingError));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, noteIndex, timingError);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NoteHitResultOkayImplCopyWith<_$NoteHitResultOkayImpl> get copyWith =>
      __$$NoteHitResultOkayImplCopyWithImpl<_$NoteHitResultOkayImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int noteIndex, double timingError) perfect,
    required TResult Function(int noteIndex, double timingError) good,
    required TResult Function(int noteIndex, double timingError) okay,
    required TResult Function(int noteIndex) missed,
  }) {
    return okay(noteIndex, timingError);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int noteIndex, double timingError)? perfect,
    TResult? Function(int noteIndex, double timingError)? good,
    TResult? Function(int noteIndex, double timingError)? okay,
    TResult? Function(int noteIndex)? missed,
  }) {
    return okay?.call(noteIndex, timingError);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int noteIndex, double timingError)? perfect,
    TResult Function(int noteIndex, double timingError)? good,
    TResult Function(int noteIndex, double timingError)? okay,
    TResult Function(int noteIndex)? missed,
    required TResult orElse(),
  }) {
    if (okay != null) {
      return okay(noteIndex, timingError);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NoteHitResultPerfect value) perfect,
    required TResult Function(_NoteHitResultGood value) good,
    required TResult Function(_NoteHitResultOkay value) okay,
    required TResult Function(_NoteHitResultMissed value) missed,
  }) {
    return okay(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NoteHitResultPerfect value)? perfect,
    TResult? Function(_NoteHitResultGood value)? good,
    TResult? Function(_NoteHitResultOkay value)? okay,
    TResult? Function(_NoteHitResultMissed value)? missed,
  }) {
    return okay?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NoteHitResultPerfect value)? perfect,
    TResult Function(_NoteHitResultGood value)? good,
    TResult Function(_NoteHitResultOkay value)? okay,
    TResult Function(_NoteHitResultMissed value)? missed,
    required TResult orElse(),
  }) {
    if (okay != null) {
      return okay(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$NoteHitResultOkayImplToJson(
      this,
    );
  }
}

abstract class _NoteHitResultOkay extends NoteHitResult {
  const factory _NoteHitResultOkay(
      {required final int noteIndex,
      required final double timingError}) = _$NoteHitResultOkayImpl;
  const _NoteHitResultOkay._() : super._();

  factory _NoteHitResultOkay.fromJson(Map<String, dynamic> json) =
      _$NoteHitResultOkayImpl.fromJson;

  @override
  int get noteIndex;
  double get timingError;
  @override
  @JsonKey(ignore: true)
  _$$NoteHitResultOkayImplCopyWith<_$NoteHitResultOkayImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NoteHitResultMissedImplCopyWith<$Res>
    implements $NoteHitResultCopyWith<$Res> {
  factory _$$NoteHitResultMissedImplCopyWith(_$NoteHitResultMissedImpl value,
          $Res Function(_$NoteHitResultMissedImpl) then) =
      __$$NoteHitResultMissedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int noteIndex});
}

/// @nodoc
class __$$NoteHitResultMissedImplCopyWithImpl<$Res>
    extends _$NoteHitResultCopyWithImpl<$Res, _$NoteHitResultMissedImpl>
    implements _$$NoteHitResultMissedImplCopyWith<$Res> {
  __$$NoteHitResultMissedImplCopyWithImpl(_$NoteHitResultMissedImpl _value,
      $Res Function(_$NoteHitResultMissedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? noteIndex = null,
  }) {
    return _then(_$NoteHitResultMissedImpl(
      noteIndex: null == noteIndex
          ? _value.noteIndex
          : noteIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NoteHitResultMissedImpl extends _NoteHitResultMissed {
  const _$NoteHitResultMissedImpl(
      {required this.noteIndex, final String? $type})
      : $type = $type ?? 'missed',
        super._();

  factory _$NoteHitResultMissedImpl.fromJson(Map<String, dynamic> json) =>
      _$$NoteHitResultMissedImplFromJson(json);

  @override
  final int noteIndex;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'NoteHitResult.missed(noteIndex: $noteIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NoteHitResultMissedImpl &&
            (identical(other.noteIndex, noteIndex) ||
                other.noteIndex == noteIndex));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, noteIndex);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NoteHitResultMissedImplCopyWith<_$NoteHitResultMissedImpl> get copyWith =>
      __$$NoteHitResultMissedImplCopyWithImpl<_$NoteHitResultMissedImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int noteIndex, double timingError) perfect,
    required TResult Function(int noteIndex, double timingError) good,
    required TResult Function(int noteIndex, double timingError) okay,
    required TResult Function(int noteIndex) missed,
  }) {
    return missed(noteIndex);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int noteIndex, double timingError)? perfect,
    TResult? Function(int noteIndex, double timingError)? good,
    TResult? Function(int noteIndex, double timingError)? okay,
    TResult? Function(int noteIndex)? missed,
  }) {
    return missed?.call(noteIndex);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int noteIndex, double timingError)? perfect,
    TResult Function(int noteIndex, double timingError)? good,
    TResult Function(int noteIndex, double timingError)? okay,
    TResult Function(int noteIndex)? missed,
    required TResult orElse(),
  }) {
    if (missed != null) {
      return missed(noteIndex);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NoteHitResultPerfect value) perfect,
    required TResult Function(_NoteHitResultGood value) good,
    required TResult Function(_NoteHitResultOkay value) okay,
    required TResult Function(_NoteHitResultMissed value) missed,
  }) {
    return missed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NoteHitResultPerfect value)? perfect,
    TResult? Function(_NoteHitResultGood value)? good,
    TResult? Function(_NoteHitResultOkay value)? okay,
    TResult? Function(_NoteHitResultMissed value)? missed,
  }) {
    return missed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NoteHitResultPerfect value)? perfect,
    TResult Function(_NoteHitResultGood value)? good,
    TResult Function(_NoteHitResultOkay value)? okay,
    TResult Function(_NoteHitResultMissed value)? missed,
    required TResult orElse(),
  }) {
    if (missed != null) {
      return missed(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$NoteHitResultMissedImplToJson(
      this,
    );
  }
}

abstract class _NoteHitResultMissed extends NoteHitResult {
  const factory _NoteHitResultMissed({required final int noteIndex}) =
      _$NoteHitResultMissedImpl;
  const _NoteHitResultMissed._() : super._();

  factory _NoteHitResultMissed.fromJson(Map<String, dynamic> json) =
      _$NoteHitResultMissedImpl.fromJson;

  @override
  int get noteIndex;
  @override
  @JsonKey(ignore: true)
  _$$NoteHitResultMissedImplCopyWith<_$NoteHitResultMissedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StageEvent _$StageEventFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'noteHit':
      return _StageEventNoteHit.fromJson(json);
    case 'noteMissed':
      return _StageEventNoteMissed.fromJson(json);
    case 'stageCompleted':
      return _StageEventStageCompleted.fromJson(json);
    case 'playbackPosition':
      return _StageEventPlaybackPosition.fromJson(json);
    case 'stateChanged':
      return _StageEventStateChanged.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'runtimeType', 'StageEvent',
          'Invalid union type "${json['runtimeType']}"!');
  }
}

/// @nodoc
mixin _$StageEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            int noteIndex, NoteHitResult result, double currentBeat)
        noteHit,
    required TResult Function(int noteIndex, double currentBeat) noteMissed,
    required TResult Function(
            double accuracy, int score, int totalNotes, int hitNotes)
        stageCompleted,
    required TResult Function(
            double currentBeat, double progress, bool isPlaying)
        playbackPosition,
    required TResult Function(StageEngineStatus state) stateChanged,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int noteIndex, NoteHitResult result, double currentBeat)?
        noteHit,
    TResult? Function(int noteIndex, double currentBeat)? noteMissed,
    TResult? Function(double accuracy, int score, int totalNotes, int hitNotes)?
        stageCompleted,
    TResult? Function(double currentBeat, double progress, bool isPlaying)?
        playbackPosition,
    TResult? Function(StageEngineStatus state)? stateChanged,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int noteIndex, NoteHitResult result, double currentBeat)?
        noteHit,
    TResult Function(int noteIndex, double currentBeat)? noteMissed,
    TResult Function(double accuracy, int score, int totalNotes, int hitNotes)?
        stageCompleted,
    TResult Function(double currentBeat, double progress, bool isPlaying)?
        playbackPosition,
    TResult Function(StageEngineStatus state)? stateChanged,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_StageEventNoteHit value) noteHit,
    required TResult Function(_StageEventNoteMissed value) noteMissed,
    required TResult Function(_StageEventStageCompleted value) stageCompleted,
    required TResult Function(_StageEventPlaybackPosition value)
        playbackPosition,
    required TResult Function(_StageEventStateChanged value) stateChanged,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_StageEventNoteHit value)? noteHit,
    TResult? Function(_StageEventNoteMissed value)? noteMissed,
    TResult? Function(_StageEventStageCompleted value)? stageCompleted,
    TResult? Function(_StageEventPlaybackPosition value)? playbackPosition,
    TResult? Function(_StageEventStateChanged value)? stateChanged,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_StageEventNoteHit value)? noteHit,
    TResult Function(_StageEventNoteMissed value)? noteMissed,
    TResult Function(_StageEventStageCompleted value)? stageCompleted,
    TResult Function(_StageEventPlaybackPosition value)? playbackPosition,
    TResult Function(_StageEventStateChanged value)? stateChanged,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StageEventCopyWith<$Res> {
  factory $StageEventCopyWith(
          StageEvent value, $Res Function(StageEvent) then) =
      _$StageEventCopyWithImpl<$Res, StageEvent>;
}

/// @nodoc
class _$StageEventCopyWithImpl<$Res, $Val extends StageEvent>
    implements $StageEventCopyWith<$Res> {
  _$StageEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$StageEventNoteHitImplCopyWith<$Res> {
  factory _$$StageEventNoteHitImplCopyWith(_$StageEventNoteHitImpl value,
          $Res Function(_$StageEventNoteHitImpl) then) =
      __$$StageEventNoteHitImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int noteIndex, NoteHitResult result, double currentBeat});

  $NoteHitResultCopyWith<$Res> get result;
}

/// @nodoc
class __$$StageEventNoteHitImplCopyWithImpl<$Res>
    extends _$StageEventCopyWithImpl<$Res, _$StageEventNoteHitImpl>
    implements _$$StageEventNoteHitImplCopyWith<$Res> {
  __$$StageEventNoteHitImplCopyWithImpl(_$StageEventNoteHitImpl _value,
      $Res Function(_$StageEventNoteHitImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? noteIndex = null,
    Object? result = null,
    Object? currentBeat = null,
  }) {
    return _then(_$StageEventNoteHitImpl(
      noteIndex: null == noteIndex
          ? _value.noteIndex
          : noteIndex // ignore: cast_nullable_to_non_nullable
              as int,
      result: null == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as NoteHitResult,
      currentBeat: null == currentBeat
          ? _value.currentBeat
          : currentBeat // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }

  @override
  @pragma('vm:prefer-inline')
  $NoteHitResultCopyWith<$Res> get result {
    return $NoteHitResultCopyWith<$Res>(_value.result, (value) {
      return _then(_value.copyWith(result: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _$StageEventNoteHitImpl implements _StageEventNoteHit {
  const _$StageEventNoteHitImpl(
      {required this.noteIndex,
      required this.result,
      required this.currentBeat,
      final String? $type})
      : $type = $type ?? 'noteHit';

  factory _$StageEventNoteHitImpl.fromJson(Map<String, dynamic> json) =>
      _$$StageEventNoteHitImplFromJson(json);

  @override
  final int noteIndex;
  @override
  final NoteHitResult result;
  @override
  final double currentBeat;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'StageEvent.noteHit(noteIndex: $noteIndex, result: $result, currentBeat: $currentBeat)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StageEventNoteHitImpl &&
            (identical(other.noteIndex, noteIndex) ||
                other.noteIndex == noteIndex) &&
            (identical(other.result, result) || other.result == result) &&
            (identical(other.currentBeat, currentBeat) ||
                other.currentBeat == currentBeat));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, noteIndex, result, currentBeat);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StageEventNoteHitImplCopyWith<_$StageEventNoteHitImpl> get copyWith =>
      __$$StageEventNoteHitImplCopyWithImpl<_$StageEventNoteHitImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            int noteIndex, NoteHitResult result, double currentBeat)
        noteHit,
    required TResult Function(int noteIndex, double currentBeat) noteMissed,
    required TResult Function(
            double accuracy, int score, int totalNotes, int hitNotes)
        stageCompleted,
    required TResult Function(
            double currentBeat, double progress, bool isPlaying)
        playbackPosition,
    required TResult Function(StageEngineStatus state) stateChanged,
  }) {
    return noteHit(noteIndex, result, currentBeat);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int noteIndex, NoteHitResult result, double currentBeat)?
        noteHit,
    TResult? Function(int noteIndex, double currentBeat)? noteMissed,
    TResult? Function(double accuracy, int score, int totalNotes, int hitNotes)?
        stageCompleted,
    TResult? Function(double currentBeat, double progress, bool isPlaying)?
        playbackPosition,
    TResult? Function(StageEngineStatus state)? stateChanged,
  }) {
    return noteHit?.call(noteIndex, result, currentBeat);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int noteIndex, NoteHitResult result, double currentBeat)?
        noteHit,
    TResult Function(int noteIndex, double currentBeat)? noteMissed,
    TResult Function(double accuracy, int score, int totalNotes, int hitNotes)?
        stageCompleted,
    TResult Function(double currentBeat, double progress, bool isPlaying)?
        playbackPosition,
    TResult Function(StageEngineStatus state)? stateChanged,
    required TResult orElse(),
  }) {
    if (noteHit != null) {
      return noteHit(noteIndex, result, currentBeat);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_StageEventNoteHit value) noteHit,
    required TResult Function(_StageEventNoteMissed value) noteMissed,
    required TResult Function(_StageEventStageCompleted value) stageCompleted,
    required TResult Function(_StageEventPlaybackPosition value)
        playbackPosition,
    required TResult Function(_StageEventStateChanged value) stateChanged,
  }) {
    return noteHit(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_StageEventNoteHit value)? noteHit,
    TResult? Function(_StageEventNoteMissed value)? noteMissed,
    TResult? Function(_StageEventStageCompleted value)? stageCompleted,
    TResult? Function(_StageEventPlaybackPosition value)? playbackPosition,
    TResult? Function(_StageEventStateChanged value)? stateChanged,
  }) {
    return noteHit?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_StageEventNoteHit value)? noteHit,
    TResult Function(_StageEventNoteMissed value)? noteMissed,
    TResult Function(_StageEventStageCompleted value)? stageCompleted,
    TResult Function(_StageEventPlaybackPosition value)? playbackPosition,
    TResult Function(_StageEventStateChanged value)? stateChanged,
    required TResult orElse(),
  }) {
    if (noteHit != null) {
      return noteHit(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$StageEventNoteHitImplToJson(
      this,
    );
  }
}

abstract class _StageEventNoteHit implements StageEvent {
  const factory _StageEventNoteHit(
      {required final int noteIndex,
      required final NoteHitResult result,
      required final double currentBeat}) = _$StageEventNoteHitImpl;

  factory _StageEventNoteHit.fromJson(Map<String, dynamic> json) =
      _$StageEventNoteHitImpl.fromJson;

  int get noteIndex;
  NoteHitResult get result;
  double get currentBeat;
  @JsonKey(ignore: true)
  _$$StageEventNoteHitImplCopyWith<_$StageEventNoteHitImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$StageEventNoteMissedImplCopyWith<$Res> {
  factory _$$StageEventNoteMissedImplCopyWith(_$StageEventNoteMissedImpl value,
          $Res Function(_$StageEventNoteMissedImpl) then) =
      __$$StageEventNoteMissedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int noteIndex, double currentBeat});
}

/// @nodoc
class __$$StageEventNoteMissedImplCopyWithImpl<$Res>
    extends _$StageEventCopyWithImpl<$Res, _$StageEventNoteMissedImpl>
    implements _$$StageEventNoteMissedImplCopyWith<$Res> {
  __$$StageEventNoteMissedImplCopyWithImpl(_$StageEventNoteMissedImpl _value,
      $Res Function(_$StageEventNoteMissedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? noteIndex = null,
    Object? currentBeat = null,
  }) {
    return _then(_$StageEventNoteMissedImpl(
      noteIndex: null == noteIndex
          ? _value.noteIndex
          : noteIndex // ignore: cast_nullable_to_non_nullable
              as int,
      currentBeat: null == currentBeat
          ? _value.currentBeat
          : currentBeat // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StageEventNoteMissedImpl implements _StageEventNoteMissed {
  const _$StageEventNoteMissedImpl(
      {required this.noteIndex, required this.currentBeat, final String? $type})
      : $type = $type ?? 'noteMissed';

  factory _$StageEventNoteMissedImpl.fromJson(Map<String, dynamic> json) =>
      _$$StageEventNoteMissedImplFromJson(json);

  @override
  final int noteIndex;
  @override
  final double currentBeat;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'StageEvent.noteMissed(noteIndex: $noteIndex, currentBeat: $currentBeat)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StageEventNoteMissedImpl &&
            (identical(other.noteIndex, noteIndex) ||
                other.noteIndex == noteIndex) &&
            (identical(other.currentBeat, currentBeat) ||
                other.currentBeat == currentBeat));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, noteIndex, currentBeat);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StageEventNoteMissedImplCopyWith<_$StageEventNoteMissedImpl>
      get copyWith =>
          __$$StageEventNoteMissedImplCopyWithImpl<_$StageEventNoteMissedImpl>(
              this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            int noteIndex, NoteHitResult result, double currentBeat)
        noteHit,
    required TResult Function(int noteIndex, double currentBeat) noteMissed,
    required TResult Function(
            double accuracy, int score, int totalNotes, int hitNotes)
        stageCompleted,
    required TResult Function(
            double currentBeat, double progress, bool isPlaying)
        playbackPosition,
    required TResult Function(StageEngineStatus state) stateChanged,
  }) {
    return noteMissed(noteIndex, currentBeat);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int noteIndex, NoteHitResult result, double currentBeat)?
        noteHit,
    TResult? Function(int noteIndex, double currentBeat)? noteMissed,
    TResult? Function(double accuracy, int score, int totalNotes, int hitNotes)?
        stageCompleted,
    TResult? Function(double currentBeat, double progress, bool isPlaying)?
        playbackPosition,
    TResult? Function(StageEngineStatus state)? stateChanged,
  }) {
    return noteMissed?.call(noteIndex, currentBeat);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int noteIndex, NoteHitResult result, double currentBeat)?
        noteHit,
    TResult Function(int noteIndex, double currentBeat)? noteMissed,
    TResult Function(double accuracy, int score, int totalNotes, int hitNotes)?
        stageCompleted,
    TResult Function(double currentBeat, double progress, bool isPlaying)?
        playbackPosition,
    TResult Function(StageEngineStatus state)? stateChanged,
    required TResult orElse(),
  }) {
    if (noteMissed != null) {
      return noteMissed(noteIndex, currentBeat);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_StageEventNoteHit value) noteHit,
    required TResult Function(_StageEventNoteMissed value) noteMissed,
    required TResult Function(_StageEventStageCompleted value) stageCompleted,
    required TResult Function(_StageEventPlaybackPosition value)
        playbackPosition,
    required TResult Function(_StageEventStateChanged value) stateChanged,
  }) {
    return noteMissed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_StageEventNoteHit value)? noteHit,
    TResult? Function(_StageEventNoteMissed value)? noteMissed,
    TResult? Function(_StageEventStageCompleted value)? stageCompleted,
    TResult? Function(_StageEventPlaybackPosition value)? playbackPosition,
    TResult? Function(_StageEventStateChanged value)? stateChanged,
  }) {
    return noteMissed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_StageEventNoteHit value)? noteHit,
    TResult Function(_StageEventNoteMissed value)? noteMissed,
    TResult Function(_StageEventStageCompleted value)? stageCompleted,
    TResult Function(_StageEventPlaybackPosition value)? playbackPosition,
    TResult Function(_StageEventStateChanged value)? stateChanged,
    required TResult orElse(),
  }) {
    if (noteMissed != null) {
      return noteMissed(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$StageEventNoteMissedImplToJson(
      this,
    );
  }
}

abstract class _StageEventNoteMissed implements StageEvent {
  const factory _StageEventNoteMissed(
      {required final int noteIndex,
      required final double currentBeat}) = _$StageEventNoteMissedImpl;

  factory _StageEventNoteMissed.fromJson(Map<String, dynamic> json) =
      _$StageEventNoteMissedImpl.fromJson;

  int get noteIndex;
  double get currentBeat;
  @JsonKey(ignore: true)
  _$$StageEventNoteMissedImplCopyWith<_$StageEventNoteMissedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$StageEventStageCompletedImplCopyWith<$Res> {
  factory _$$StageEventStageCompletedImplCopyWith(
          _$StageEventStageCompletedImpl value,
          $Res Function(_$StageEventStageCompletedImpl) then) =
      __$$StageEventStageCompletedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({double accuracy, int score, int totalNotes, int hitNotes});
}

/// @nodoc
class __$$StageEventStageCompletedImplCopyWithImpl<$Res>
    extends _$StageEventCopyWithImpl<$Res, _$StageEventStageCompletedImpl>
    implements _$$StageEventStageCompletedImplCopyWith<$Res> {
  __$$StageEventStageCompletedImplCopyWithImpl(
      _$StageEventStageCompletedImpl _value,
      $Res Function(_$StageEventStageCompletedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accuracy = null,
    Object? score = null,
    Object? totalNotes = null,
    Object? hitNotes = null,
  }) {
    return _then(_$StageEventStageCompletedImpl(
      accuracy: null == accuracy
          ? _value.accuracy
          : accuracy // ignore: cast_nullable_to_non_nullable
              as double,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as int,
      totalNotes: null == totalNotes
          ? _value.totalNotes
          : totalNotes // ignore: cast_nullable_to_non_nullable
              as int,
      hitNotes: null == hitNotes
          ? _value.hitNotes
          : hitNotes // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StageEventStageCompletedImpl implements _StageEventStageCompleted {
  const _$StageEventStageCompletedImpl(
      {required this.accuracy,
      required this.score,
      required this.totalNotes,
      required this.hitNotes,
      final String? $type})
      : $type = $type ?? 'stageCompleted';

  factory _$StageEventStageCompletedImpl.fromJson(Map<String, dynamic> json) =>
      _$$StageEventStageCompletedImplFromJson(json);

  @override
  final double accuracy;
  @override
  final int score;
  @override
  final int totalNotes;
  @override
  final int hitNotes;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'StageEvent.stageCompleted(accuracy: $accuracy, score: $score, totalNotes: $totalNotes, hitNotes: $hitNotes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StageEventStageCompletedImpl &&
            (identical(other.accuracy, accuracy) ||
                other.accuracy == accuracy) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.totalNotes, totalNotes) ||
                other.totalNotes == totalNotes) &&
            (identical(other.hitNotes, hitNotes) ||
                other.hitNotes == hitNotes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, accuracy, score, totalNotes, hitNotes);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StageEventStageCompletedImplCopyWith<_$StageEventStageCompletedImpl>
      get copyWith => __$$StageEventStageCompletedImplCopyWithImpl<
          _$StageEventStageCompletedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            int noteIndex, NoteHitResult result, double currentBeat)
        noteHit,
    required TResult Function(int noteIndex, double currentBeat) noteMissed,
    required TResult Function(
            double accuracy, int score, int totalNotes, int hitNotes)
        stageCompleted,
    required TResult Function(
            double currentBeat, double progress, bool isPlaying)
        playbackPosition,
    required TResult Function(StageEngineStatus state) stateChanged,
  }) {
    return stageCompleted(accuracy, score, totalNotes, hitNotes);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int noteIndex, NoteHitResult result, double currentBeat)?
        noteHit,
    TResult? Function(int noteIndex, double currentBeat)? noteMissed,
    TResult? Function(double accuracy, int score, int totalNotes, int hitNotes)?
        stageCompleted,
    TResult? Function(double currentBeat, double progress, bool isPlaying)?
        playbackPosition,
    TResult? Function(StageEngineStatus state)? stateChanged,
  }) {
    return stageCompleted?.call(accuracy, score, totalNotes, hitNotes);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int noteIndex, NoteHitResult result, double currentBeat)?
        noteHit,
    TResult Function(int noteIndex, double currentBeat)? noteMissed,
    TResult Function(double accuracy, int score, int totalNotes, int hitNotes)?
        stageCompleted,
    TResult Function(double currentBeat, double progress, bool isPlaying)?
        playbackPosition,
    TResult Function(StageEngineStatus state)? stateChanged,
    required TResult orElse(),
  }) {
    if (stageCompleted != null) {
      return stageCompleted(accuracy, score, totalNotes, hitNotes);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_StageEventNoteHit value) noteHit,
    required TResult Function(_StageEventNoteMissed value) noteMissed,
    required TResult Function(_StageEventStageCompleted value) stageCompleted,
    required TResult Function(_StageEventPlaybackPosition value)
        playbackPosition,
    required TResult Function(_StageEventStateChanged value) stateChanged,
  }) {
    return stageCompleted(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_StageEventNoteHit value)? noteHit,
    TResult? Function(_StageEventNoteMissed value)? noteMissed,
    TResult? Function(_StageEventStageCompleted value)? stageCompleted,
    TResult? Function(_StageEventPlaybackPosition value)? playbackPosition,
    TResult? Function(_StageEventStateChanged value)? stateChanged,
  }) {
    return stageCompleted?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_StageEventNoteHit value)? noteHit,
    TResult Function(_StageEventNoteMissed value)? noteMissed,
    TResult Function(_StageEventStageCompleted value)? stageCompleted,
    TResult Function(_StageEventPlaybackPosition value)? playbackPosition,
    TResult Function(_StageEventStateChanged value)? stateChanged,
    required TResult orElse(),
  }) {
    if (stageCompleted != null) {
      return stageCompleted(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$StageEventStageCompletedImplToJson(
      this,
    );
  }
}

abstract class _StageEventStageCompleted implements StageEvent {
  const factory _StageEventStageCompleted(
      {required final double accuracy,
      required final int score,
      required final int totalNotes,
      required final int hitNotes}) = _$StageEventStageCompletedImpl;

  factory _StageEventStageCompleted.fromJson(Map<String, dynamic> json) =
      _$StageEventStageCompletedImpl.fromJson;

  double get accuracy;
  int get score;
  int get totalNotes;
  int get hitNotes;
  @JsonKey(ignore: true)
  _$$StageEventStageCompletedImplCopyWith<_$StageEventStageCompletedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$StageEventPlaybackPositionImplCopyWith<$Res> {
  factory _$$StageEventPlaybackPositionImplCopyWith(
          _$StageEventPlaybackPositionImpl value,
          $Res Function(_$StageEventPlaybackPositionImpl) then) =
      __$$StageEventPlaybackPositionImplCopyWithImpl<$Res>;
  @useResult
  $Res call({double currentBeat, double progress, bool isPlaying});
}

/// @nodoc
class __$$StageEventPlaybackPositionImplCopyWithImpl<$Res>
    extends _$StageEventCopyWithImpl<$Res, _$StageEventPlaybackPositionImpl>
    implements _$$StageEventPlaybackPositionImplCopyWith<$Res> {
  __$$StageEventPlaybackPositionImplCopyWithImpl(
      _$StageEventPlaybackPositionImpl _value,
      $Res Function(_$StageEventPlaybackPositionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentBeat = null,
    Object? progress = null,
    Object? isPlaying = null,
  }) {
    return _then(_$StageEventPlaybackPositionImpl(
      currentBeat: null == currentBeat
          ? _value.currentBeat
          : currentBeat // ignore: cast_nullable_to_non_nullable
              as double,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      isPlaying: null == isPlaying
          ? _value.isPlaying
          : isPlaying // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StageEventPlaybackPositionImpl implements _StageEventPlaybackPosition {
  const _$StageEventPlaybackPositionImpl(
      {required this.currentBeat,
      required this.progress,
      required this.isPlaying,
      final String? $type})
      : $type = $type ?? 'playbackPosition';

  factory _$StageEventPlaybackPositionImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$StageEventPlaybackPositionImplFromJson(json);

  @override
  final double currentBeat;
  @override
  final double progress;
// 0.0 - 1.0
  @override
  final bool isPlaying;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'StageEvent.playbackPosition(currentBeat: $currentBeat, progress: $progress, isPlaying: $isPlaying)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StageEventPlaybackPositionImpl &&
            (identical(other.currentBeat, currentBeat) ||
                other.currentBeat == currentBeat) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.isPlaying, isPlaying) ||
                other.isPlaying == isPlaying));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, currentBeat, progress, isPlaying);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StageEventPlaybackPositionImplCopyWith<_$StageEventPlaybackPositionImpl>
      get copyWith => __$$StageEventPlaybackPositionImplCopyWithImpl<
          _$StageEventPlaybackPositionImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            int noteIndex, NoteHitResult result, double currentBeat)
        noteHit,
    required TResult Function(int noteIndex, double currentBeat) noteMissed,
    required TResult Function(
            double accuracy, int score, int totalNotes, int hitNotes)
        stageCompleted,
    required TResult Function(
            double currentBeat, double progress, bool isPlaying)
        playbackPosition,
    required TResult Function(StageEngineStatus state) stateChanged,
  }) {
    return playbackPosition(currentBeat, progress, isPlaying);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int noteIndex, NoteHitResult result, double currentBeat)?
        noteHit,
    TResult? Function(int noteIndex, double currentBeat)? noteMissed,
    TResult? Function(double accuracy, int score, int totalNotes, int hitNotes)?
        stageCompleted,
    TResult? Function(double currentBeat, double progress, bool isPlaying)?
        playbackPosition,
    TResult? Function(StageEngineStatus state)? stateChanged,
  }) {
    return playbackPosition?.call(currentBeat, progress, isPlaying);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int noteIndex, NoteHitResult result, double currentBeat)?
        noteHit,
    TResult Function(int noteIndex, double currentBeat)? noteMissed,
    TResult Function(double accuracy, int score, int totalNotes, int hitNotes)?
        stageCompleted,
    TResult Function(double currentBeat, double progress, bool isPlaying)?
        playbackPosition,
    TResult Function(StageEngineStatus state)? stateChanged,
    required TResult orElse(),
  }) {
    if (playbackPosition != null) {
      return playbackPosition(currentBeat, progress, isPlaying);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_StageEventNoteHit value) noteHit,
    required TResult Function(_StageEventNoteMissed value) noteMissed,
    required TResult Function(_StageEventStageCompleted value) stageCompleted,
    required TResult Function(_StageEventPlaybackPosition value)
        playbackPosition,
    required TResult Function(_StageEventStateChanged value) stateChanged,
  }) {
    return playbackPosition(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_StageEventNoteHit value)? noteHit,
    TResult? Function(_StageEventNoteMissed value)? noteMissed,
    TResult? Function(_StageEventStageCompleted value)? stageCompleted,
    TResult? Function(_StageEventPlaybackPosition value)? playbackPosition,
    TResult? Function(_StageEventStateChanged value)? stateChanged,
  }) {
    return playbackPosition?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_StageEventNoteHit value)? noteHit,
    TResult Function(_StageEventNoteMissed value)? noteMissed,
    TResult Function(_StageEventStageCompleted value)? stageCompleted,
    TResult Function(_StageEventPlaybackPosition value)? playbackPosition,
    TResult Function(_StageEventStateChanged value)? stateChanged,
    required TResult orElse(),
  }) {
    if (playbackPosition != null) {
      return playbackPosition(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$StageEventPlaybackPositionImplToJson(
      this,
    );
  }
}

abstract class _StageEventPlaybackPosition implements StageEvent {
  const factory _StageEventPlaybackPosition(
      {required final double currentBeat,
      required final double progress,
      required final bool isPlaying}) = _$StageEventPlaybackPositionImpl;

  factory _StageEventPlaybackPosition.fromJson(Map<String, dynamic> json) =
      _$StageEventPlaybackPositionImpl.fromJson;

  double get currentBeat;
  double get progress; // 0.0 - 1.0
  bool get isPlaying;
  @JsonKey(ignore: true)
  _$$StageEventPlaybackPositionImplCopyWith<_$StageEventPlaybackPositionImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$StageEventStateChangedImplCopyWith<$Res> {
  factory _$$StageEventStateChangedImplCopyWith(
          _$StageEventStateChangedImpl value,
          $Res Function(_$StageEventStateChangedImpl) then) =
      __$$StageEventStateChangedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({StageEngineStatus state});
}

/// @nodoc
class __$$StageEventStateChangedImplCopyWithImpl<$Res>
    extends _$StageEventCopyWithImpl<$Res, _$StageEventStateChangedImpl>
    implements _$$StageEventStateChangedImplCopyWith<$Res> {
  __$$StageEventStateChangedImplCopyWithImpl(
      _$StageEventStateChangedImpl _value,
      $Res Function(_$StageEventStateChangedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? state = null,
  }) {
    return _then(_$StageEventStateChangedImpl(
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as StageEngineStatus,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StageEventStateChangedImpl implements _StageEventStateChanged {
  const _$StageEventStateChangedImpl({required this.state, final String? $type})
      : $type = $type ?? 'stateChanged';

  factory _$StageEventStateChangedImpl.fromJson(Map<String, dynamic> json) =>
      _$$StageEventStateChangedImplFromJson(json);

  @override
  final StageEngineStatus state;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'StageEvent.stateChanged(state: $state)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StageEventStateChangedImpl &&
            (identical(other.state, state) || other.state == state));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, state);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StageEventStateChangedImplCopyWith<_$StageEventStateChangedImpl>
      get copyWith => __$$StageEventStateChangedImplCopyWithImpl<
          _$StageEventStateChangedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            int noteIndex, NoteHitResult result, double currentBeat)
        noteHit,
    required TResult Function(int noteIndex, double currentBeat) noteMissed,
    required TResult Function(
            double accuracy, int score, int totalNotes, int hitNotes)
        stageCompleted,
    required TResult Function(
            double currentBeat, double progress, bool isPlaying)
        playbackPosition,
    required TResult Function(StageEngineStatus state) stateChanged,
  }) {
    return stateChanged(state);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int noteIndex, NoteHitResult result, double currentBeat)?
        noteHit,
    TResult? Function(int noteIndex, double currentBeat)? noteMissed,
    TResult? Function(double accuracy, int score, int totalNotes, int hitNotes)?
        stageCompleted,
    TResult? Function(double currentBeat, double progress, bool isPlaying)?
        playbackPosition,
    TResult? Function(StageEngineStatus state)? stateChanged,
  }) {
    return stateChanged?.call(state);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int noteIndex, NoteHitResult result, double currentBeat)?
        noteHit,
    TResult Function(int noteIndex, double currentBeat)? noteMissed,
    TResult Function(double accuracy, int score, int totalNotes, int hitNotes)?
        stageCompleted,
    TResult Function(double currentBeat, double progress, bool isPlaying)?
        playbackPosition,
    TResult Function(StageEngineStatus state)? stateChanged,
    required TResult orElse(),
  }) {
    if (stateChanged != null) {
      return stateChanged(state);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_StageEventNoteHit value) noteHit,
    required TResult Function(_StageEventNoteMissed value) noteMissed,
    required TResult Function(_StageEventStageCompleted value) stageCompleted,
    required TResult Function(_StageEventPlaybackPosition value)
        playbackPosition,
    required TResult Function(_StageEventStateChanged value) stateChanged,
  }) {
    return stateChanged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_StageEventNoteHit value)? noteHit,
    TResult? Function(_StageEventNoteMissed value)? noteMissed,
    TResult? Function(_StageEventStageCompleted value)? stageCompleted,
    TResult? Function(_StageEventPlaybackPosition value)? playbackPosition,
    TResult? Function(_StageEventStateChanged value)? stateChanged,
  }) {
    return stateChanged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_StageEventNoteHit value)? noteHit,
    TResult Function(_StageEventNoteMissed value)? noteMissed,
    TResult Function(_StageEventStageCompleted value)? stageCompleted,
    TResult Function(_StageEventPlaybackPosition value)? playbackPosition,
    TResult Function(_StageEventStateChanged value)? stateChanged,
    required TResult orElse(),
  }) {
    if (stateChanged != null) {
      return stateChanged(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$StageEventStateChangedImplToJson(
      this,
    );
  }
}

abstract class _StageEventStateChanged implements StageEvent {
  const factory _StageEventStateChanged(
      {required final StageEngineStatus state}) = _$StageEventStateChangedImpl;

  factory _StageEventStateChanged.fromJson(Map<String, dynamic> json) =
      _$StageEventStateChangedImpl.fromJson;

  StageEngineStatus get state;
  @JsonKey(ignore: true)
  _$$StageEventStateChangedImplCopyWith<_$StageEventStateChangedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

StageEngineConfig _$StageEngineConfigFromJson(Map<String, dynamic> json) {
  return _StageEngineConfig.fromJson(json);
}

/// @nodoc
mixin _$StageEngineConfig {
  double get perfectWindow =>
      throw _privateConstructorUsedError; // beats (early/late tolerance for perfect)
  double get goodWindow => throw _privateConstructorUsedError; // beats for good
  double get okayWindow => throw _privateConstructorUsedError; // beats for okay
  double get missWindow =>
      throw _privateConstructorUsedError; // beats after which note is missed
  bool get autoAdvance =>
      throw _privateConstructorUsedError; // auto-advance playhead
  double get playbackSpeed => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StageEngineConfigCopyWith<StageEngineConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StageEngineConfigCopyWith<$Res> {
  factory $StageEngineConfigCopyWith(
          StageEngineConfig value, $Res Function(StageEngineConfig) then) =
      _$StageEngineConfigCopyWithImpl<$Res, StageEngineConfig>;
  @useResult
  $Res call(
      {double perfectWindow,
      double goodWindow,
      double okayWindow,
      double missWindow,
      bool autoAdvance,
      double playbackSpeed});
}

/// @nodoc
class _$StageEngineConfigCopyWithImpl<$Res, $Val extends StageEngineConfig>
    implements $StageEngineConfigCopyWith<$Res> {
  _$StageEngineConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? perfectWindow = null,
    Object? goodWindow = null,
    Object? okayWindow = null,
    Object? missWindow = null,
    Object? autoAdvance = null,
    Object? playbackSpeed = null,
  }) {
    return _then(_value.copyWith(
      perfectWindow: null == perfectWindow
          ? _value.perfectWindow
          : perfectWindow // ignore: cast_nullable_to_non_nullable
              as double,
      goodWindow: null == goodWindow
          ? _value.goodWindow
          : goodWindow // ignore: cast_nullable_to_non_nullable
              as double,
      okayWindow: null == okayWindow
          ? _value.okayWindow
          : okayWindow // ignore: cast_nullable_to_non_nullable
              as double,
      missWindow: null == missWindow
          ? _value.missWindow
          : missWindow // ignore: cast_nullable_to_non_nullable
              as double,
      autoAdvance: null == autoAdvance
          ? _value.autoAdvance
          : autoAdvance // ignore: cast_nullable_to_non_nullable
              as bool,
      playbackSpeed: null == playbackSpeed
          ? _value.playbackSpeed
          : playbackSpeed // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StageEngineConfigImplCopyWith<$Res>
    implements $StageEngineConfigCopyWith<$Res> {
  factory _$$StageEngineConfigImplCopyWith(_$StageEngineConfigImpl value,
          $Res Function(_$StageEngineConfigImpl) then) =
      __$$StageEngineConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double perfectWindow,
      double goodWindow,
      double okayWindow,
      double missWindow,
      bool autoAdvance,
      double playbackSpeed});
}

/// @nodoc
class __$$StageEngineConfigImplCopyWithImpl<$Res>
    extends _$StageEngineConfigCopyWithImpl<$Res, _$StageEngineConfigImpl>
    implements _$$StageEngineConfigImplCopyWith<$Res> {
  __$$StageEngineConfigImplCopyWithImpl(_$StageEngineConfigImpl _value,
      $Res Function(_$StageEngineConfigImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? perfectWindow = null,
    Object? goodWindow = null,
    Object? okayWindow = null,
    Object? missWindow = null,
    Object? autoAdvance = null,
    Object? playbackSpeed = null,
  }) {
    return _then(_$StageEngineConfigImpl(
      perfectWindow: null == perfectWindow
          ? _value.perfectWindow
          : perfectWindow // ignore: cast_nullable_to_non_nullable
              as double,
      goodWindow: null == goodWindow
          ? _value.goodWindow
          : goodWindow // ignore: cast_nullable_to_non_nullable
              as double,
      okayWindow: null == okayWindow
          ? _value.okayWindow
          : okayWindow // ignore: cast_nullable_to_non_nullable
              as double,
      missWindow: null == missWindow
          ? _value.missWindow
          : missWindow // ignore: cast_nullable_to_non_nullable
              as double,
      autoAdvance: null == autoAdvance
          ? _value.autoAdvance
          : autoAdvance // ignore: cast_nullable_to_non_nullable
              as bool,
      playbackSpeed: null == playbackSpeed
          ? _value.playbackSpeed
          : playbackSpeed // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StageEngineConfigImpl implements _StageEngineConfig {
  const _$StageEngineConfigImpl(
      {this.perfectWindow = 0.1,
      this.goodWindow = 0.2,
      this.okayWindow = 0.3,
      this.missWindow = 0.5,
      this.autoAdvance = true,
      this.playbackSpeed = 1.0});

  factory _$StageEngineConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$StageEngineConfigImplFromJson(json);

  @override
  @JsonKey()
  final double perfectWindow;
// beats (early/late tolerance for perfect)
  @override
  @JsonKey()
  final double goodWindow;
// beats for good
  @override
  @JsonKey()
  final double okayWindow;
// beats for okay
  @override
  @JsonKey()
  final double missWindow;
// beats after which note is missed
  @override
  @JsonKey()
  final bool autoAdvance;
// auto-advance playhead
  @override
  @JsonKey()
  final double playbackSpeed;

  @override
  String toString() {
    return 'StageEngineConfig(perfectWindow: $perfectWindow, goodWindow: $goodWindow, okayWindow: $okayWindow, missWindow: $missWindow, autoAdvance: $autoAdvance, playbackSpeed: $playbackSpeed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StageEngineConfigImpl &&
            (identical(other.perfectWindow, perfectWindow) ||
                other.perfectWindow == perfectWindow) &&
            (identical(other.goodWindow, goodWindow) ||
                other.goodWindow == goodWindow) &&
            (identical(other.okayWindow, okayWindow) ||
                other.okayWindow == okayWindow) &&
            (identical(other.missWindow, missWindow) ||
                other.missWindow == missWindow) &&
            (identical(other.autoAdvance, autoAdvance) ||
                other.autoAdvance == autoAdvance) &&
            (identical(other.playbackSpeed, playbackSpeed) ||
                other.playbackSpeed == playbackSpeed));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, perfectWindow, goodWindow,
      okayWindow, missWindow, autoAdvance, playbackSpeed);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StageEngineConfigImplCopyWith<_$StageEngineConfigImpl> get copyWith =>
      __$$StageEngineConfigImplCopyWithImpl<_$StageEngineConfigImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StageEngineConfigImplToJson(
      this,
    );
  }
}

abstract class _StageEngineConfig implements StageEngineConfig {
  const factory _StageEngineConfig(
      {final double perfectWindow,
      final double goodWindow,
      final double okayWindow,
      final double missWindow,
      final bool autoAdvance,
      final double playbackSpeed}) = _$StageEngineConfigImpl;

  factory _StageEngineConfig.fromJson(Map<String, dynamic> json) =
      _$StageEngineConfigImpl.fromJson;

  @override
  double get perfectWindow;
  @override // beats (early/late tolerance for perfect)
  double get goodWindow;
  @override // beats for good
  double get okayWindow;
  @override // beats for okay
  double get missWindow;
  @override // beats after which note is missed
  bool get autoAdvance;
  @override // auto-advance playhead
  double get playbackSpeed;
  @override
  @JsonKey(ignore: true)
  _$$StageEngineConfigImplCopyWith<_$StageEngineConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StageEngineStateModel _$StageEngineStateModelFromJson(
    Map<String, dynamic> json) {
  return _StageEngineStateModel.fromJson(json);
}

/// @nodoc
mixin _$StageEngineStateModel {
  StageEngineStatus get engineState => throw _privateConstructorUsedError;
  LevelModel get level => throw _privateConstructorUsedError;
  double get currentBeat => throw _privateConstructorUsedError;
  List<NoteState> get noteStates => throw _privateConstructorUsedError;
  int get score => throw _privateConstructorUsedError;
  int get hitCount => throw _privateConstructorUsedError;
  int get missCount => throw _privateConstructorUsedError;
  int get perfectCount => throw _privateConstructorUsedError;
  int get goodCount => throw _privateConstructorUsedError;
  int get okayCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StageEngineStateModelCopyWith<StageEngineStateModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StageEngineStateModelCopyWith<$Res> {
  factory $StageEngineStateModelCopyWith(StageEngineStateModel value,
          $Res Function(StageEngineStateModel) then) =
      _$StageEngineStateModelCopyWithImpl<$Res, StageEngineStateModel>;
  @useResult
  $Res call(
      {StageEngineStatus engineState,
      LevelModel level,
      double currentBeat,
      List<NoteState> noteStates,
      int score,
      int hitCount,
      int missCount,
      int perfectCount,
      int goodCount,
      int okayCount});

  $LevelModelCopyWith<$Res> get level;
}

/// @nodoc
class _$StageEngineStateModelCopyWithImpl<$Res,
        $Val extends StageEngineStateModel>
    implements $StageEngineStateModelCopyWith<$Res> {
  _$StageEngineStateModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? engineState = null,
    Object? level = null,
    Object? currentBeat = null,
    Object? noteStates = null,
    Object? score = null,
    Object? hitCount = null,
    Object? missCount = null,
    Object? perfectCount = null,
    Object? goodCount = null,
    Object? okayCount = null,
  }) {
    return _then(_value.copyWith(
      engineState: null == engineState
          ? _value.engineState
          : engineState // ignore: cast_nullable_to_non_nullable
              as StageEngineStatus,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as LevelModel,
      currentBeat: null == currentBeat
          ? _value.currentBeat
          : currentBeat // ignore: cast_nullable_to_non_nullable
              as double,
      noteStates: null == noteStates
          ? _value.noteStates
          : noteStates // ignore: cast_nullable_to_non_nullable
              as List<NoteState>,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as int,
      hitCount: null == hitCount
          ? _value.hitCount
          : hitCount // ignore: cast_nullable_to_non_nullable
              as int,
      missCount: null == missCount
          ? _value.missCount
          : missCount // ignore: cast_nullable_to_non_nullable
              as int,
      perfectCount: null == perfectCount
          ? _value.perfectCount
          : perfectCount // ignore: cast_nullable_to_non_nullable
              as int,
      goodCount: null == goodCount
          ? _value.goodCount
          : goodCount // ignore: cast_nullable_to_non_nullable
              as int,
      okayCount: null == okayCount
          ? _value.okayCount
          : okayCount // ignore: cast_nullable_to_non_nullable
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
abstract class _$$StageEngineStateModelImplCopyWith<$Res>
    implements $StageEngineStateModelCopyWith<$Res> {
  factory _$$StageEngineStateModelImplCopyWith(
          _$StageEngineStateModelImpl value,
          $Res Function(_$StageEngineStateModelImpl) then) =
      __$$StageEngineStateModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {StageEngineStatus engineState,
      LevelModel level,
      double currentBeat,
      List<NoteState> noteStates,
      int score,
      int hitCount,
      int missCount,
      int perfectCount,
      int goodCount,
      int okayCount});

  @override
  $LevelModelCopyWith<$Res> get level;
}

/// @nodoc
class __$$StageEngineStateModelImplCopyWithImpl<$Res>
    extends _$StageEngineStateModelCopyWithImpl<$Res,
        _$StageEngineStateModelImpl>
    implements _$$StageEngineStateModelImplCopyWith<$Res> {
  __$$StageEngineStateModelImplCopyWithImpl(_$StageEngineStateModelImpl _value,
      $Res Function(_$StageEngineStateModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? engineState = null,
    Object? level = null,
    Object? currentBeat = null,
    Object? noteStates = null,
    Object? score = null,
    Object? hitCount = null,
    Object? missCount = null,
    Object? perfectCount = null,
    Object? goodCount = null,
    Object? okayCount = null,
  }) {
    return _then(_$StageEngineStateModelImpl(
      engineState: null == engineState
          ? _value.engineState
          : engineState // ignore: cast_nullable_to_non_nullable
              as StageEngineStatus,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as LevelModel,
      currentBeat: null == currentBeat
          ? _value.currentBeat
          : currentBeat // ignore: cast_nullable_to_non_nullable
              as double,
      noteStates: null == noteStates
          ? _value._noteStates
          : noteStates // ignore: cast_nullable_to_non_nullable
              as List<NoteState>,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as int,
      hitCount: null == hitCount
          ? _value.hitCount
          : hitCount // ignore: cast_nullable_to_non_nullable
              as int,
      missCount: null == missCount
          ? _value.missCount
          : missCount // ignore: cast_nullable_to_non_nullable
              as int,
      perfectCount: null == perfectCount
          ? _value.perfectCount
          : perfectCount // ignore: cast_nullable_to_non_nullable
              as int,
      goodCount: null == goodCount
          ? _value.goodCount
          : goodCount // ignore: cast_nullable_to_non_nullable
              as int,
      okayCount: null == okayCount
          ? _value.okayCount
          : okayCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StageEngineStateModelImpl extends _StageEngineStateModel {
  const _$StageEngineStateModelImpl(
      {required this.engineState,
      required this.level,
      required this.currentBeat,
      required final List<NoteState> noteStates,
      required this.score,
      required this.hitCount,
      required this.missCount,
      this.perfectCount = 0,
      this.goodCount = 0,
      this.okayCount = 0})
      : _noteStates = noteStates,
        super._();

  factory _$StageEngineStateModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$StageEngineStateModelImplFromJson(json);

  @override
  final StageEngineStatus engineState;
  @override
  final LevelModel level;
  @override
  final double currentBeat;
  final List<NoteState> _noteStates;
  @override
  List<NoteState> get noteStates {
    if (_noteStates is EqualUnmodifiableListView) return _noteStates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_noteStates);
  }

  @override
  final int score;
  @override
  final int hitCount;
  @override
  final int missCount;
  @override
  @JsonKey()
  final int perfectCount;
  @override
  @JsonKey()
  final int goodCount;
  @override
  @JsonKey()
  final int okayCount;

  @override
  String toString() {
    return 'StageEngineStateModel(engineState: $engineState, level: $level, currentBeat: $currentBeat, noteStates: $noteStates, score: $score, hitCount: $hitCount, missCount: $missCount, perfectCount: $perfectCount, goodCount: $goodCount, okayCount: $okayCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StageEngineStateModelImpl &&
            (identical(other.engineState, engineState) ||
                other.engineState == engineState) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.currentBeat, currentBeat) ||
                other.currentBeat == currentBeat) &&
            const DeepCollectionEquality()
                .equals(other._noteStates, _noteStates) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.hitCount, hitCount) ||
                other.hitCount == hitCount) &&
            (identical(other.missCount, missCount) ||
                other.missCount == missCount) &&
            (identical(other.perfectCount, perfectCount) ||
                other.perfectCount == perfectCount) &&
            (identical(other.goodCount, goodCount) ||
                other.goodCount == goodCount) &&
            (identical(other.okayCount, okayCount) ||
                other.okayCount == okayCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      engineState,
      level,
      currentBeat,
      const DeepCollectionEquality().hash(_noteStates),
      score,
      hitCount,
      missCount,
      perfectCount,
      goodCount,
      okayCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StageEngineStateModelImplCopyWith<_$StageEngineStateModelImpl>
      get copyWith => __$$StageEngineStateModelImplCopyWithImpl<
          _$StageEngineStateModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StageEngineStateModelImplToJson(
      this,
    );
  }
}

abstract class _StageEngineStateModel extends StageEngineStateModel {
  const factory _StageEngineStateModel(
      {required final StageEngineStatus engineState,
      required final LevelModel level,
      required final double currentBeat,
      required final List<NoteState> noteStates,
      required final int score,
      required final int hitCount,
      required final int missCount,
      final int perfectCount,
      final int goodCount,
      final int okayCount}) = _$StageEngineStateModelImpl;
  const _StageEngineStateModel._() : super._();

  factory _StageEngineStateModel.fromJson(Map<String, dynamic> json) =
      _$StageEngineStateModelImpl.fromJson;

  @override
  StageEngineStatus get engineState;
  @override
  LevelModel get level;
  @override
  double get currentBeat;
  @override
  List<NoteState> get noteStates;
  @override
  int get score;
  @override
  int get hitCount;
  @override
  int get missCount;
  @override
  int get perfectCount;
  @override
  int get goodCount;
  @override
  int get okayCount;
  @override
  @JsonKey(ignore: true)
  _$$StageEngineStateModelImplCopyWith<_$StageEngineStateModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$GameState {
  StageModel? get currentStage => throw _privateConstructorUsedError;
  LevelModel? get currentLevel => throw _privateConstructorUsedError;
  StageEngineStatus get engineState => throw _privateConstructorUsedError;
  double get currentBeat => throw _privateConstructorUsedError;
  int get score => throw _privateConstructorUsedError;
  double get accuracy => throw _privateConstructorUsedError;
  double get playbackSpeed => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $GameStateCopyWith<GameState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameStateCopyWith<$Res> {
  factory $GameStateCopyWith(GameState value, $Res Function(GameState) then) =
      _$GameStateCopyWithImpl<$Res, GameState>;
  @useResult
  $Res call(
      {StageModel? currentStage,
      LevelModel? currentLevel,
      StageEngineStatus engineState,
      double currentBeat,
      int score,
      double accuracy,
      double playbackSpeed});

  $StageModelCopyWith<$Res>? get currentStage;
  $LevelModelCopyWith<$Res>? get currentLevel;
}

/// @nodoc
class _$GameStateCopyWithImpl<$Res, $Val extends GameState>
    implements $GameStateCopyWith<$Res> {
  _$GameStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentStage = freezed,
    Object? currentLevel = freezed,
    Object? engineState = null,
    Object? currentBeat = null,
    Object? score = null,
    Object? accuracy = null,
    Object? playbackSpeed = null,
  }) {
    return _then(_value.copyWith(
      currentStage: freezed == currentStage
          ? _value.currentStage
          : currentStage // ignore: cast_nullable_to_non_nullable
              as StageModel?,
      currentLevel: freezed == currentLevel
          ? _value.currentLevel
          : currentLevel // ignore: cast_nullable_to_non_nullable
              as LevelModel?,
      engineState: null == engineState
          ? _value.engineState
          : engineState // ignore: cast_nullable_to_non_nullable
              as StageEngineStatus,
      currentBeat: null == currentBeat
          ? _value.currentBeat
          : currentBeat // ignore: cast_nullable_to_non_nullable
              as double,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as int,
      accuracy: null == accuracy
          ? _value.accuracy
          : accuracy // ignore: cast_nullable_to_non_nullable
              as double,
      playbackSpeed: null == playbackSpeed
          ? _value.playbackSpeed
          : playbackSpeed // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $StageModelCopyWith<$Res>? get currentStage {
    if (_value.currentStage == null) {
      return null;
    }

    return $StageModelCopyWith<$Res>(_value.currentStage!, (value) {
      return _then(_value.copyWith(currentStage: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $LevelModelCopyWith<$Res>? get currentLevel {
    if (_value.currentLevel == null) {
      return null;
    }

    return $LevelModelCopyWith<$Res>(_value.currentLevel!, (value) {
      return _then(_value.copyWith(currentLevel: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GameStateImplCopyWith<$Res>
    implements $GameStateCopyWith<$Res> {
  factory _$$GameStateImplCopyWith(
          _$GameStateImpl value, $Res Function(_$GameStateImpl) then) =
      __$$GameStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {StageModel? currentStage,
      LevelModel? currentLevel,
      StageEngineStatus engineState,
      double currentBeat,
      int score,
      double accuracy,
      double playbackSpeed});

  @override
  $StageModelCopyWith<$Res>? get currentStage;
  @override
  $LevelModelCopyWith<$Res>? get currentLevel;
}

/// @nodoc
class __$$GameStateImplCopyWithImpl<$Res>
    extends _$GameStateCopyWithImpl<$Res, _$GameStateImpl>
    implements _$$GameStateImplCopyWith<$Res> {
  __$$GameStateImplCopyWithImpl(
      _$GameStateImpl _value, $Res Function(_$GameStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentStage = freezed,
    Object? currentLevel = freezed,
    Object? engineState = null,
    Object? currentBeat = null,
    Object? score = null,
    Object? accuracy = null,
    Object? playbackSpeed = null,
  }) {
    return _then(_$GameStateImpl(
      currentStage: freezed == currentStage
          ? _value.currentStage
          : currentStage // ignore: cast_nullable_to_non_nullable
              as StageModel?,
      currentLevel: freezed == currentLevel
          ? _value.currentLevel
          : currentLevel // ignore: cast_nullable_to_non_nullable
              as LevelModel?,
      engineState: null == engineState
          ? _value.engineState
          : engineState // ignore: cast_nullable_to_non_nullable
              as StageEngineStatus,
      currentBeat: null == currentBeat
          ? _value.currentBeat
          : currentBeat // ignore: cast_nullable_to_non_nullable
              as double,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as int,
      accuracy: null == accuracy
          ? _value.accuracy
          : accuracy // ignore: cast_nullable_to_non_nullable
              as double,
      playbackSpeed: null == playbackSpeed
          ? _value.playbackSpeed
          : playbackSpeed // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$GameStateImpl extends _GameState {
  const _$GameStateImpl(
      {this.currentStage = null,
      this.currentLevel = null,
      this.engineState = StageEngineStatus.idle,
      this.currentBeat = 0.0,
      this.score = 0,
      this.accuracy = 0.0,
      this.playbackSpeed = 1.0})
      : super._();

  @override
  @JsonKey()
  final StageModel? currentStage;
  @override
  @JsonKey()
  final LevelModel? currentLevel;
  @override
  @JsonKey()
  final StageEngineStatus engineState;
  @override
  @JsonKey()
  final double currentBeat;
  @override
  @JsonKey()
  final int score;
  @override
  @JsonKey()
  final double accuracy;
  @override
  @JsonKey()
  final double playbackSpeed;

  @override
  String toString() {
    return 'GameState(currentStage: $currentStage, currentLevel: $currentLevel, engineState: $engineState, currentBeat: $currentBeat, score: $score, accuracy: $accuracy, playbackSpeed: $playbackSpeed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameStateImpl &&
            (identical(other.currentStage, currentStage) ||
                other.currentStage == currentStage) &&
            (identical(other.currentLevel, currentLevel) ||
                other.currentLevel == currentLevel) &&
            (identical(other.engineState, engineState) ||
                other.engineState == engineState) &&
            (identical(other.currentBeat, currentBeat) ||
                other.currentBeat == currentBeat) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.accuracy, accuracy) ||
                other.accuracy == accuracy) &&
            (identical(other.playbackSpeed, playbackSpeed) ||
                other.playbackSpeed == playbackSpeed));
  }

  @override
  int get hashCode => Object.hash(runtimeType, currentStage, currentLevel,
      engineState, currentBeat, score, accuracy, playbackSpeed);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GameStateImplCopyWith<_$GameStateImpl> get copyWith =>
      __$$GameStateImplCopyWithImpl<_$GameStateImpl>(this, _$identity);
}

abstract class _GameState extends GameState {
  const factory _GameState(
      {final StageModel? currentStage,
      final LevelModel? currentLevel,
      final StageEngineStatus engineState,
      final double currentBeat,
      final int score,
      final double accuracy,
      final double playbackSpeed}) = _$GameStateImpl;
  const _GameState._() : super._();

  @override
  StageModel? get currentStage;
  @override
  LevelModel? get currentLevel;
  @override
  StageEngineStatus get engineState;
  @override
  double get currentBeat;
  @override
  int get score;
  @override
  double get accuracy;
  @override
  double get playbackSpeed;
  @override
  @JsonKey(ignore: true)
  _$$GameStateImplCopyWith<_$GameStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
