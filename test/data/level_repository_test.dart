import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/data/level_repository.dart';
import 'package:piano_tool/models/level_models.dart';

void main() {
  test('getStage finds an imported stage, matching getAllStages', () {
    final repository = LevelRepository();
    const level = LevelModel(
      id: 'imported_1',
      title: 'My Song',
      description: 'Imported from audio',
      tempo: 100,
      beatsPerMeasure: 4,
      totalMeasures: 2,
      measures: [],
    );
    repository.addImportedLevel(level);

    final stage = repository.getStage('imported_imported_1');
    expect(stage, isNotNull);
    expect(stage!.level.id, 'imported_1');
  });

  test('getStage returns null for an unknown id', () {
    expect(LevelRepository().getStage('does_not_exist'), isNull);
  });

  test('ships three built-in stages, in order', () {
    final stages = LevelRepository().getAllStages();
    expect(stages.map((s) => s.id).toList(), ['stage_1', 'stage_2', 'stage_3']);
    expect(stages.map((s) => s.order).toList(), [1, 2, 3]);
  });

  test('every stage has a level with measures and notes', () {
    for (final stage in LevelRepository().getAllStages()) {
      expect(stage.level.measures, isNotEmpty, reason: stage.id);
      expect(
        stage.level.measures.expand((m) => m.notes),
        isNotEmpty,
        reason: stage.id,
      );
    }
  });

  test('note beats are ordered within each level', () {
    for (final stage in LevelRepository().getAllStages()) {
      final beats = stage.level.measures
          .expand((m) => m.notes)
          .map((n) => n.startBeat)
          .toList();
      final sorted = [...beats]..sort();
      expect(beats, sorted, reason: stage.id);
    }
  });
}
