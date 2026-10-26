import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  test('supports bass clef and grand staff level models', () {
    final repository = LevelRepository();
    const bassLevel = LevelModel(
      id: 'bass_1',
      title: 'Bass Journey',
      description: 'Bass clef level',
      tempo: 90,
      beatsPerMeasure: 3,
      beatUnit: 4,
      clef: LevelClef.bass,
      totalMeasures: 2,
      measures: [],
    );
    repository.addImportedLevel(bassLevel);
    expect(repository.getStage('imported_bass_1')?.level.clef, LevelClef.bass);
    expect(repository.getStage('imported_bass_1')?.level.beatsPerMeasure, 3);
    expect(repository.getStage('imported_bass_1')?.level.beatUnit, 4);

    const grandLevel = LevelModel(
      id: 'grand_1',
      title: 'Grand Etude',
      description: 'Grand staff level',
      tempo: 100,
      beatsPerMeasure: 6,
      beatUnit: 8,
      clef: LevelClef.grand,
      totalMeasures: 2,
      measures: [],
    );
    repository.addImportedLevel(grandLevel);
    expect(
      repository.getStage('imported_grand_1')?.level.clef,
      LevelClef.grand,
    );
    expect(repository.getStage('imported_grand_1')?.level.beatsPerMeasure, 6);
    expect(repository.getStage('imported_grand_1')?.level.beatUnit, 8);
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

  // The hosted web app is built without INGESTION_API_TOKEN, so the real
  // ingestion provider fails. The catalog must still load the built-in stages
  // instead of hanging the first screen on a spinner.
  test('loads built-in stages when ingestion is not configured', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final repository = await container
        .read(levelRepositoryProvider.future)
        .timeout(const Duration(seconds: 5));

    expect(repository.getStage('stage_1'), isNotNull);
  });
}
