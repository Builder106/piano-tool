// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LevelNoteImpl _$$LevelNoteImplFromJson(Map<String, dynamic> json) =>
    _$LevelNoteImpl(
      midiNote: (json['midiNote'] as num).toInt(),
      startBeat: (json['startBeat'] as num).toDouble(),
      durationBeats: (json['durationBeats'] as num).toDouble(),
      measureIndex: (json['measureIndex'] as num).toInt(),
      beatIndex: (json['beatIndex'] as num).toInt(),
      isRest: json['isRest'] as bool? ?? false,
      voiceIndex: (json['voiceIndex'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$LevelNoteImplToJson(_$LevelNoteImpl instance) =>
    <String, dynamic>{
      'midiNote': instance.midiNote,
      'startBeat': instance.startBeat,
      'durationBeats': instance.durationBeats,
      'measureIndex': instance.measureIndex,
      'beatIndex': instance.beatIndex,
      'isRest': instance.isRest,
      'voiceIndex': instance.voiceIndex,
    };

_$LevelMeasureImpl _$$LevelMeasureImplFromJson(Map<String, dynamic> json) =>
    _$LevelMeasureImpl(
      index: (json['index'] as num).toInt(),
      startBeat: (json['startBeat'] as num).toDouble(),
      beatsPerMeasure: (json['beatsPerMeasure'] as num).toInt(),
      notes: (json['notes'] as List<dynamic>)
          .map((e) => LevelNote.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$LevelMeasureImplToJson(_$LevelMeasureImpl instance) =>
    <String, dynamic>{
      'index': instance.index,
      'startBeat': instance.startBeat,
      'beatsPerMeasure': instance.beatsPerMeasure,
      'notes': instance.notes,
    };

_$LevelModelImpl _$$LevelModelImplFromJson(Map<String, dynamic> json) =>
    _$LevelModelImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      tempo: (json['tempo'] as num).toInt(),
      beatsPerMeasure: (json['beatsPerMeasure'] as num).toInt(),
      totalMeasures: (json['totalMeasures'] as num).toInt(),
      measures: (json['measures'] as List<dynamic>)
          .map((e) => LevelMeasure.fromJson(e as Map<String, dynamic>))
          .toList(),
      clefOctave: (json['clefOctave'] as num?)?.toInt() ?? 4,
      transpose: (json['transpose'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$LevelModelImplToJson(_$LevelModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'tempo': instance.tempo,
      'beatsPerMeasure': instance.beatsPerMeasure,
      'totalMeasures': instance.totalMeasures,
      'measures': instance.measures,
      'clefOctave': instance.clefOctave,
      'transpose': instance.transpose,
    };

_$StageModelImpl _$$StageModelImplFromJson(Map<String, dynamic> json) =>
    _$StageModelImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      difficulty: $enumDecode(_$DifficultyEnumMap, json['difficulty']),
      level: LevelModel.fromJson(json['level'] as Map<String, dynamic>),
      order: (json['order'] as num?)?.toInt() ?? 0,
      prerequisites: (json['prerequisites'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$StageModelImplToJson(_$StageModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'difficulty': _$DifficultyEnumMap[instance.difficulty]!,
      'level': instance.level,
      'order': instance.order,
      'prerequisites': instance.prerequisites,
      'xpReward': instance.xpReward,
    };

const _$DifficultyEnumMap = {
  Difficulty.beginner: 'beginner',
  Difficulty.intermediate: 'intermediate',
  Difficulty.advanced: 'advanced',
  Difficulty.expert: 'expert',
};

_$StageProgressImpl _$$StageProgressImplFromJson(Map<String, dynamic> json) =>
    _$StageProgressImpl(
      stageId: json['stageId'] as String,
      bestAccuracy: (json['bestAccuracy'] as num?)?.toDouble() ?? 0,
      bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      completed: json['completed'] as bool? ?? false,
      unlocked: json['unlocked'] as bool? ?? false,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      lastAttemptAt: json['lastAttemptAt'] == null
          ? null
          : DateTime.parse(json['lastAttemptAt'] as String),
    );

Map<String, dynamic> _$$StageProgressImplToJson(_$StageProgressImpl instance) =>
    <String, dynamic>{
      'stageId': instance.stageId,
      'bestAccuracy': instance.bestAccuracy,
      'bestScore': instance.bestScore,
      'attempts': instance.attempts,
      'completed': instance.completed,
      'unlocked': instance.unlocked,
      'completedAt': instance.completedAt?.toIso8601String(),
      'lastAttemptAt': instance.lastAttemptAt?.toIso8601String(),
    };
