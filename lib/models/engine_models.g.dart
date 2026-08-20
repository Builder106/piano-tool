// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'engine_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NoteHitResultPerfectImpl _$$NoteHitResultPerfectImplFromJson(
        Map<String, dynamic> json) =>
    _$NoteHitResultPerfectImpl(
      noteIndex: (json['noteIndex'] as num).toInt(),
      timingError: (json['timingError'] as num).toDouble(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$NoteHitResultPerfectImplToJson(
        _$NoteHitResultPerfectImpl instance) =>
    <String, dynamic>{
      'noteIndex': instance.noteIndex,
      'timingError': instance.timingError,
      'runtimeType': instance.$type,
    };

_$NoteHitResultGoodImpl _$$NoteHitResultGoodImplFromJson(
        Map<String, dynamic> json) =>
    _$NoteHitResultGoodImpl(
      noteIndex: (json['noteIndex'] as num).toInt(),
      timingError: (json['timingError'] as num).toDouble(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$NoteHitResultGoodImplToJson(
        _$NoteHitResultGoodImpl instance) =>
    <String, dynamic>{
      'noteIndex': instance.noteIndex,
      'timingError': instance.timingError,
      'runtimeType': instance.$type,
    };

_$NoteHitResultOkayImpl _$$NoteHitResultOkayImplFromJson(
        Map<String, dynamic> json) =>
    _$NoteHitResultOkayImpl(
      noteIndex: (json['noteIndex'] as num).toInt(),
      timingError: (json['timingError'] as num).toDouble(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$NoteHitResultOkayImplToJson(
        _$NoteHitResultOkayImpl instance) =>
    <String, dynamic>{
      'noteIndex': instance.noteIndex,
      'timingError': instance.timingError,
      'runtimeType': instance.$type,
    };

_$NoteHitResultMissedImpl _$$NoteHitResultMissedImplFromJson(
        Map<String, dynamic> json) =>
    _$NoteHitResultMissedImpl(
      noteIndex: (json['noteIndex'] as num).toInt(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$NoteHitResultMissedImplToJson(
        _$NoteHitResultMissedImpl instance) =>
    <String, dynamic>{
      'noteIndex': instance.noteIndex,
      'runtimeType': instance.$type,
    };

_$StageEventNoteHitImpl _$$StageEventNoteHitImplFromJson(
        Map<String, dynamic> json) =>
    _$StageEventNoteHitImpl(
      noteIndex: (json['noteIndex'] as num).toInt(),
      result: NoteHitResult.fromJson(json['result'] as Map<String, dynamic>),
      currentBeat: (json['currentBeat'] as num).toDouble(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$StageEventNoteHitImplToJson(
        _$StageEventNoteHitImpl instance) =>
    <String, dynamic>{
      'noteIndex': instance.noteIndex,
      'result': instance.result,
      'currentBeat': instance.currentBeat,
      'runtimeType': instance.$type,
    };

_$StageEventNoteMissedImpl _$$StageEventNoteMissedImplFromJson(
        Map<String, dynamic> json) =>
    _$StageEventNoteMissedImpl(
      noteIndex: (json['noteIndex'] as num).toInt(),
      currentBeat: (json['currentBeat'] as num).toDouble(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$StageEventNoteMissedImplToJson(
        _$StageEventNoteMissedImpl instance) =>
    <String, dynamic>{
      'noteIndex': instance.noteIndex,
      'currentBeat': instance.currentBeat,
      'runtimeType': instance.$type,
    };

_$StageEventStageCompletedImpl _$$StageEventStageCompletedImplFromJson(
        Map<String, dynamic> json) =>
    _$StageEventStageCompletedImpl(
      accuracy: (json['accuracy'] as num).toDouble(),
      score: (json['score'] as num).toInt(),
      totalNotes: (json['totalNotes'] as num).toInt(),
      hitNotes: (json['hitNotes'] as num).toInt(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$StageEventStageCompletedImplToJson(
        _$StageEventStageCompletedImpl instance) =>
    <String, dynamic>{
      'accuracy': instance.accuracy,
      'score': instance.score,
      'totalNotes': instance.totalNotes,
      'hitNotes': instance.hitNotes,
      'runtimeType': instance.$type,
    };

_$StageEventPlaybackPositionImpl _$$StageEventPlaybackPositionImplFromJson(
        Map<String, dynamic> json) =>
    _$StageEventPlaybackPositionImpl(
      currentBeat: (json['currentBeat'] as num).toDouble(),
      progress: (json['progress'] as num).toDouble(),
      isPlaying: json['isPlaying'] as bool,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$StageEventPlaybackPositionImplToJson(
        _$StageEventPlaybackPositionImpl instance) =>
    <String, dynamic>{
      'currentBeat': instance.currentBeat,
      'progress': instance.progress,
      'isPlaying': instance.isPlaying,
      'runtimeType': instance.$type,
    };

_$StageEventStateChangedImpl _$$StageEventStateChangedImplFromJson(
        Map<String, dynamic> json) =>
    _$StageEventStateChangedImpl(
      state: $enumDecode(_$StageEngineStatusEnumMap, json['state']),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$StageEventStateChangedImplToJson(
        _$StageEventStateChangedImpl instance) =>
    <String, dynamic>{
      'state': _$StageEngineStatusEnumMap[instance.state]!,
      'runtimeType': instance.$type,
    };

const _$StageEngineStatusEnumMap = {
  StageEngineStatus.idle: 'idle',
  StageEngineStatus.playing: 'playing',
  StageEngineStatus.paused: 'paused',
  StageEngineStatus.completed: 'completed',
  StageEngineStatus.stopped: 'stopped',
};

_$StageEngineConfigImpl _$$StageEngineConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$StageEngineConfigImpl(
      perfectWindow: (json['perfectWindow'] as num?)?.toDouble() ?? 0.1,
      goodWindow: (json['goodWindow'] as num?)?.toDouble() ?? 0.2,
      okayWindow: (json['okayWindow'] as num?)?.toDouble() ?? 0.3,
      missWindow: (json['missWindow'] as num?)?.toDouble() ?? 0.5,
      autoAdvance: json['autoAdvance'] as bool? ?? true,
      playbackSpeed: (json['playbackSpeed'] as num?)?.toDouble() ?? 1.0,
    );

Map<String, dynamic> _$$StageEngineConfigImplToJson(
        _$StageEngineConfigImpl instance) =>
    <String, dynamic>{
      'perfectWindow': instance.perfectWindow,
      'goodWindow': instance.goodWindow,
      'okayWindow': instance.okayWindow,
      'missWindow': instance.missWindow,
      'autoAdvance': instance.autoAdvance,
      'playbackSpeed': instance.playbackSpeed,
    };

_$StageEngineStateModelImpl _$$StageEngineStateModelImplFromJson(
        Map<String, dynamic> json) =>
    _$StageEngineStateModelImpl(
      engineState: $enumDecode(_$StageEngineStatusEnumMap, json['engineState']),
      level: LevelModel.fromJson(json['level'] as Map<String, dynamic>),
      currentBeat: (json['currentBeat'] as num).toDouble(),
      noteStates: (json['noteStates'] as List<dynamic>)
          .map((e) => $enumDecode(_$NoteStateEnumMap, e))
          .toList(),
      score: (json['score'] as num).toInt(),
      hitCount: (json['hitCount'] as num).toInt(),
      missCount: (json['missCount'] as num).toInt(),
      perfectCount: (json['perfectCount'] as num?)?.toInt() ?? 0,
      goodCount: (json['goodCount'] as num?)?.toInt() ?? 0,
      okayCount: (json['okayCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$StageEngineStateModelImplToJson(
        _$StageEngineStateModelImpl instance) =>
    <String, dynamic>{
      'engineState': _$StageEngineStatusEnumMap[instance.engineState]!,
      'level': instance.level,
      'currentBeat': instance.currentBeat,
      'noteStates':
          instance.noteStates.map((e) => _$NoteStateEnumMap[e]!).toList(),
      'score': instance.score,
      'hitCount': instance.hitCount,
      'missCount': instance.missCount,
      'perfectCount': instance.perfectCount,
      'goodCount': instance.goodCount,
      'okayCount': instance.okayCount,
    };

const _$NoteStateEnumMap = {
  NoteState.upcoming: 'upcoming',
  NoteState.active: 'active',
  NoteState.hitPerfect: 'hitPerfect',
  NoteState.hitGood: 'hitGood',
  NoteState.hitOkay: 'hitOkay',
  NoteState.missed: 'missed',
};
