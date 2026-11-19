// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'engine_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WaitingHint _$WaitingHintFromJson(Map<String, dynamic> json) => _WaitingHint(
  targetBeat: (json['targetBeat'] as num).toDouble(),
  targetMidiNotes: (json['targetMidiNotes'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  hintText: json['hintText'] as String,
  noteNames:
      (json['noteNames'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  measureIndex: (json['measureIndex'] as num?)?.toInt(),
  beatIndex: (json['beatIndex'] as num?)?.toInt(),
  heardWrongMidiNote: (json['heardWrongMidiNote'] as num?)?.toInt(),
);

Map<String, dynamic> _$WaitingHintToJson(_WaitingHint instance) =>
    <String, dynamic>{
      'targetBeat': instance.targetBeat,
      'targetMidiNotes': instance.targetMidiNotes,
      'hintText': instance.hintText,
      'noteNames': instance.noteNames,
      'measureIndex': instance.measureIndex,
      'beatIndex': instance.beatIndex,
      'heardWrongMidiNote': instance.heardWrongMidiNote,
    };

_NoteHitResultPerfect _$NoteHitResultPerfectFromJson(
  Map<String, dynamic> json,
) => _NoteHitResultPerfect(
  noteIndex: (json['noteIndex'] as num).toInt(),
  timingError: (json['timingError'] as num).toDouble(),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$NoteHitResultPerfectToJson(
  _NoteHitResultPerfect instance,
) => <String, dynamic>{
  'noteIndex': instance.noteIndex,
  'timingError': instance.timingError,
  'runtimeType': instance.$type,
};

_NoteHitResultGood _$NoteHitResultGoodFromJson(Map<String, dynamic> json) =>
    _NoteHitResultGood(
      noteIndex: (json['noteIndex'] as num).toInt(),
      timingError: (json['timingError'] as num).toDouble(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$NoteHitResultGoodToJson(_NoteHitResultGood instance) =>
    <String, dynamic>{
      'noteIndex': instance.noteIndex,
      'timingError': instance.timingError,
      'runtimeType': instance.$type,
    };

_NoteHitResultOkay _$NoteHitResultOkayFromJson(Map<String, dynamic> json) =>
    _NoteHitResultOkay(
      noteIndex: (json['noteIndex'] as num).toInt(),
      timingError: (json['timingError'] as num).toDouble(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$NoteHitResultOkayToJson(_NoteHitResultOkay instance) =>
    <String, dynamic>{
      'noteIndex': instance.noteIndex,
      'timingError': instance.timingError,
      'runtimeType': instance.$type,
    };

_NoteHitResultMissed _$NoteHitResultMissedFromJson(Map<String, dynamic> json) =>
    _NoteHitResultMissed(
      noteIndex: (json['noteIndex'] as num).toInt(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$NoteHitResultMissedToJson(
  _NoteHitResultMissed instance,
) => <String, dynamic>{
  'noteIndex': instance.noteIndex,
  'runtimeType': instance.$type,
};

_NoteHitResultWaiting _$NoteHitResultWaitingFromJson(
  Map<String, dynamic> json,
) => _NoteHitResultWaiting(
  noteIndex: (json['noteIndex'] as num).toInt(),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$NoteHitResultWaitingToJson(
  _NoteHitResultWaiting instance,
) => <String, dynamic>{
  'noteIndex': instance.noteIndex,
  'runtimeType': instance.$type,
};

_StageEventNoteHit _$StageEventNoteHitFromJson(Map<String, dynamic> json) =>
    _StageEventNoteHit(
      noteIndex: (json['noteIndex'] as num).toInt(),
      result: NoteHitResult.fromJson(json['result'] as Map<String, dynamic>),
      currentBeat: (json['currentBeat'] as num).toDouble(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$StageEventNoteHitToJson(_StageEventNoteHit instance) =>
    <String, dynamic>{
      'noteIndex': instance.noteIndex,
      'result': instance.result,
      'currentBeat': instance.currentBeat,
      'runtimeType': instance.$type,
    };

_StageEventNoteMissed _$StageEventNoteMissedFromJson(
  Map<String, dynamic> json,
) => _StageEventNoteMissed(
  noteIndex: (json['noteIndex'] as num).toInt(),
  currentBeat: (json['currentBeat'] as num).toDouble(),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$StageEventNoteMissedToJson(
  _StageEventNoteMissed instance,
) => <String, dynamic>{
  'noteIndex': instance.noteIndex,
  'currentBeat': instance.currentBeat,
  'runtimeType': instance.$type,
};

_StageEventStageCompleted _$StageEventStageCompletedFromJson(
  Map<String, dynamic> json,
) => _StageEventStageCompleted(
  accuracy: (json['accuracy'] as num).toDouble(),
  score: (json['score'] as num).toInt(),
  totalNotes: (json['totalNotes'] as num).toInt(),
  hitNotes: (json['hitNotes'] as num).toInt(),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$StageEventStageCompletedToJson(
  _StageEventStageCompleted instance,
) => <String, dynamic>{
  'accuracy': instance.accuracy,
  'score': instance.score,
  'totalNotes': instance.totalNotes,
  'hitNotes': instance.hitNotes,
  'runtimeType': instance.$type,
};

_StageEventPlaybackPosition _$StageEventPlaybackPositionFromJson(
  Map<String, dynamic> json,
) => _StageEventPlaybackPosition(
  currentBeat: (json['currentBeat'] as num).toDouble(),
  progress: (json['progress'] as num).toDouble(),
  isPlaying: json['isPlaying'] as bool,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$StageEventPlaybackPositionToJson(
  _StageEventPlaybackPosition instance,
) => <String, dynamic>{
  'currentBeat': instance.currentBeat,
  'progress': instance.progress,
  'isPlaying': instance.isPlaying,
  'runtimeType': instance.$type,
};

_StageEventStateChanged _$StageEventStateChangedFromJson(
  Map<String, dynamic> json,
) => _StageEventStateChanged(
  state: $enumDecode(_$StageEngineStatusEnumMap, json['state']),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$StageEventStateChangedToJson(
  _StageEventStateChanged instance,
) => <String, dynamic>{
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

_StageEventBeat _$StageEventBeatFromJson(Map<String, dynamic> json) =>
    _StageEventBeat(
      beat: (json['beat'] as num).toDouble(),
      beatType: $enumDecode(_$MetronomeBeatTypeEnumMap, json['beatType']),
      measureIndex: (json['measureIndex'] as num).toInt(),
      beatInMeasure: (json['beatInMeasure'] as num).toInt(),
      isCountIn: json['isCountIn'] as bool? ?? false,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$StageEventBeatToJson(_StageEventBeat instance) =>
    <String, dynamic>{
      'beat': instance.beat,
      'beatType': _$MetronomeBeatTypeEnumMap[instance.beatType]!,
      'measureIndex': instance.measureIndex,
      'beatInMeasure': instance.beatInMeasure,
      'isCountIn': instance.isCountIn,
      'runtimeType': instance.$type,
    };

const _$MetronomeBeatTypeEnumMap = {
  MetronomeBeatType.downbeat: 'downbeat',
  MetronomeBeatType.secondaryAccent: 'secondaryAccent',
  MetronomeBeatType.regular: 'regular',
  MetronomeBeatType.subdivision: 'subdivision',
};

_StageEventLoopPassCompleted _$StageEventLoopPassCompletedFromJson(
  Map<String, dynamic> json,
) => _StageEventLoopPassCompleted(
  accuracy: (json['accuracy'] as num).toDouble(),
  score: (json['score'] as num).toInt(),
  totalNotes: (json['totalNotes'] as num).toInt(),
  hitNotes: (json['hitNotes'] as num).toInt(),
  loopStartBeat: (json['loopStartBeat'] as num).toDouble(),
  loopEndBeat: (json['loopEndBeat'] as num).toDouble(),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$StageEventLoopPassCompletedToJson(
  _StageEventLoopPassCompleted instance,
) => <String, dynamic>{
  'accuracy': instance.accuracy,
  'score': instance.score,
  'totalNotes': instance.totalNotes,
  'hitNotes': instance.hitNotes,
  'loopStartBeat': instance.loopStartBeat,
  'loopEndBeat': instance.loopEndBeat,
  'runtimeType': instance.$type,
};

_StageEngineConfig _$StageEngineConfigFromJson(Map<String, dynamic> json) =>
    _StageEngineConfig(
      perfectWindow: (json['perfectWindow'] as num?)?.toDouble() ?? 0.1,
      goodWindow: (json['goodWindow'] as num?)?.toDouble() ?? 0.2,
      okayWindow: (json['okayWindow'] as num?)?.toDouble() ?? 0.3,
      missWindow: (json['missWindow'] as num?)?.toDouble() ?? 0.5,
      autoAdvance: json['autoAdvance'] as bool? ?? true,
      playbackSpeed: (json['playbackSpeed'] as num?)?.toDouble() ?? 1.0,
      inputLatency: (json['inputLatency'] as num?)?.toDouble() ?? 0.0,
      practiceMode:
          $enumDecodeNullable(_$PracticeModeEnumMap, json['practiceMode']) ??
          PracticeMode.timed,
      metronomeEnabled: json['metronomeEnabled'] as bool? ?? false,
      countInEnabled: json['countInEnabled'] as bool? ?? false,
      handSelection:
          $enumDecodeNullable(_$HandSelectionEnumMap, json['handSelection']) ??
          HandSelection.both,
    );

Map<String, dynamic> _$StageEngineConfigToJson(_StageEngineConfig instance) =>
    <String, dynamic>{
      'perfectWindow': instance.perfectWindow,
      'goodWindow': instance.goodWindow,
      'okayWindow': instance.okayWindow,
      'missWindow': instance.missWindow,
      'autoAdvance': instance.autoAdvance,
      'playbackSpeed': instance.playbackSpeed,
      'inputLatency': instance.inputLatency,
      'practiceMode': _$PracticeModeEnumMap[instance.practiceMode]!,
      'metronomeEnabled': instance.metronomeEnabled,
      'countInEnabled': instance.countInEnabled,
      'handSelection': _$HandSelectionEnumMap[instance.handSelection]!,
    };

const _$PracticeModeEnumMap = {
  PracticeMode.timed: 'timed',
  PracticeMode.waiting: 'waiting',
};

const _$HandSelectionEnumMap = {
  HandSelection.both: 'both',
  HandSelection.right: 'right',
  HandSelection.left: 'left',
};

_StageEngineStateModel _$StageEngineStateModelFromJson(
  Map<String, dynamic> json,
) => _StageEngineStateModel(
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
  practiceMode:
      $enumDecodeNullable(_$PracticeModeEnumMap, json['practiceMode']) ??
      PracticeMode.timed,
  waitingHint: json['waitingHint'] == null
      ? null
      : WaitingHint.fromJson(json['waitingHint'] as Map<String, dynamic>),
  isCountingIn: json['isCountingIn'] as bool? ?? false,
  countInBeat: (json['countInBeat'] as num?)?.toInt(),
  handSelection:
      $enumDecodeNullable(_$HandSelectionEnumMap, json['handSelection']) ??
      HandSelection.both,
);

Map<String, dynamic> _$StageEngineStateModelToJson(
  _StageEngineStateModel instance,
) => <String, dynamic>{
  'engineState': _$StageEngineStatusEnumMap[instance.engineState]!,
  'level': instance.level,
  'currentBeat': instance.currentBeat,
  'noteStates': instance.noteStates.map((e) => _$NoteStateEnumMap[e]!).toList(),
  'score': instance.score,
  'hitCount': instance.hitCount,
  'missCount': instance.missCount,
  'perfectCount': instance.perfectCount,
  'goodCount': instance.goodCount,
  'okayCount': instance.okayCount,
  'practiceMode': _$PracticeModeEnumMap[instance.practiceMode]!,
  'waitingHint': instance.waitingHint,
  'isCountingIn': instance.isCountingIn,
  'countInBeat': instance.countInBeat,
  'handSelection': _$HandSelectionEnumMap[instance.handSelection]!,
};

const _$NoteStateEnumMap = {
  NoteState.upcoming: 'upcoming',
  NoteState.active: 'active',
  NoteState.hitPerfect: 'hitPerfect',
  NoteState.hitGood: 'hitGood',
  NoteState.hitOkay: 'hitOkay',
  NoteState.missed: 'missed',
};

_AssistanceOffer _$AssistanceOfferFromJson(Map<String, dynamic> json) =>
    _AssistanceOffer(
      unsuccessfulAttempts: (json['unsuccessfulAttempts'] as num).toInt(),
      currentSpeed: (json['currentSpeed'] as num).toDouble(),
      suggestedSpeed: (json['suggestedSpeed'] as num?)?.toDouble(),
      currentStartMeasure: (json['currentStartMeasure'] as num?)?.toInt(),
      currentEndMeasure: (json['currentEndMeasure'] as num?)?.toInt(),
      suggestedStartMeasure: (json['suggestedStartMeasure'] as num?)?.toInt(),
      suggestedEndMeasure: (json['suggestedEndMeasure'] as num?)?.toInt(),
      mostMissedMeasure: (json['mostMissedMeasure'] as num?)?.toInt(),
      reason: json['reason'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$AssistanceOfferToJson(_AssistanceOffer instance) =>
    <String, dynamic>{
      'unsuccessfulAttempts': instance.unsuccessfulAttempts,
      'currentSpeed': instance.currentSpeed,
      'suggestedSpeed': instance.suggestedSpeed,
      'currentStartMeasure': instance.currentStartMeasure,
      'currentEndMeasure': instance.currentEndMeasure,
      'suggestedStartMeasure': instance.suggestedStartMeasure,
      'suggestedEndMeasure': instance.suggestedEndMeasure,
      'mostMissedMeasure': instance.mostMissedMeasure,
      'reason': instance.reason,
      'message': instance.message,
    };

_AppliedAssistance _$AppliedAssistanceFromJson(Map<String, dynamic> json) =>
    _AppliedAssistance(
      originalSpeed: (json['originalSpeed'] as num).toDouble(),
      originalStartMeasure: (json['originalStartMeasure'] as num?)?.toInt(),
      originalEndMeasure: (json['originalEndMeasure'] as num?)?.toInt(),
      assistedSpeed: (json['assistedSpeed'] as num?)?.toDouble(),
      assistedStartMeasure: (json['assistedStartMeasure'] as num?)?.toInt(),
      assistedEndMeasure: (json['assistedEndMeasure'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AppliedAssistanceToJson(_AppliedAssistance instance) =>
    <String, dynamic>{
      'originalSpeed': instance.originalSpeed,
      'originalStartMeasure': instance.originalStartMeasure,
      'originalEndMeasure': instance.originalEndMeasure,
      'assistedSpeed': instance.assistedSpeed,
      'assistedStartMeasure': instance.assistedStartMeasure,
      'assistedEndMeasure': instance.assistedEndMeasure,
    };
