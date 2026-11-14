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

  group('polyphony detection and MIDI requirement', () {
    test('built-in levels are monophonic', () {
      for (final stage in LevelRepository().getAllStages()) {
        expect(
          stage.level.isPolyphonic,
          isFalse,
          reason: '${stage.id} should be monophonic',
        );
        expect(stage.effectiveRequiresMidi, isFalse);
        expect(stage.inputRequirementLabel, isNull);
      }
    });

    test('detects simultaneous notes starting on the same beat', () {
      const chordLevel = LevelModel(
        id: 'chord',
        title: 'Chord',
        description: '',
        tempo: 120,
        beatsPerMeasure: 4,
        totalMeasures: 1,
        measures: [
          LevelMeasure(
            index: 0,
            startBeat: 0,
            beatsPerMeasure: 4,
            notes: [
              LevelNote(
                midiNote: 60,
                startBeat: 0,
                durationBeats: 1,
                measureIndex: 0,
                beatIndex: 0,
              ),
              LevelNote(
                midiNote: 64,
                startBeat: 0,
                durationBeats: 1,
                measureIndex: 0,
                beatIndex: 0,
              ),
            ],
          ),
        ],
      );

      expect(chordLevel.isPolyphonic, isTrue);

      const stage = StageModel(
        id: 'stage_chord',
        title: 'Chord Stage',
        description: '',
        difficulty: Difficulty.beginner,
        level: chordLevel,
      );

      expect(stage.effectiveRequiresMidi, isTrue);
      expect(stage.inputRequirementLabel, 'Digital piano (MIDI) required');
    });

    test('detects overlapping note durations', () {
      const overlappingLevel = LevelModel(
        id: 'overlap',
        title: 'Overlap',
        description: '',
        tempo: 120,
        beatsPerMeasure: 4,
        totalMeasures: 1,
        measures: [
          LevelMeasure(
            index: 0,
            startBeat: 0,
            beatsPerMeasure: 4,
            notes: [
              LevelNote(
                midiNote: 60,
                startBeat: 0,
                durationBeats: 2, // half note (beats 0..2)
                measureIndex: 0,
                beatIndex: 0,
              ),
              LevelNote(
                midiNote: 64,
                startBeat: 1, // enters while C4 still rings
                durationBeats: 1,
                measureIndex: 0,
                beatIndex: 1,
              ),
            ],
          ),
        ],
      );

      expect(overlappingLevel.isPolyphonic, isTrue);
    });

    test('ignores rest entries when evaluating polyphony', () {
      const levelWithRests = LevelModel(
        id: 'rests',
        title: 'Rests',
        description: '',
        tempo: 120,
        beatsPerMeasure: 4,
        totalMeasures: 1,
        measures: [
          LevelMeasure(
            index: 0,
            startBeat: 0,
            beatsPerMeasure: 4,
            notes: [
              LevelNote(
                midiNote: 60,
                startBeat: 0,
                durationBeats: 1,
                measureIndex: 0,
                beatIndex: 0,
              ),
              LevelNote(
                midiNote: 0,
                startBeat: 0,
                durationBeats: 1,
                measureIndex: 0,
                beatIndex: 0,
                isRest: true,
              ),
              LevelNote(
                midiNote: 64,
                startBeat: 1,
                durationBeats: 1,
                measureIndex: 0,
                beatIndex: 1,
              ),
            ],
          ),
        ],
      );

      expect(levelWithRests.isPolyphonic, isFalse);
    });

    test('explicit requiresMidi flags stage even for monophonic levels', () {
      const monoLevel = LevelModel(
        id: 'mono',
        title: 'Mono',
        description: '',
        tempo: 120,
        beatsPerMeasure: 4,
        totalMeasures: 1,
        measures: [
          LevelMeasure(
            index: 0,
            startBeat: 0,
            beatsPerMeasure: 4,
            notes: [
              LevelNote(
                midiNote: 60,
                startBeat: 0,
                durationBeats: 1,
                measureIndex: 0,
                beatIndex: 0,
              ),
            ],
          ),
        ],
      );

      const stage = StageModel(
        id: 'stage_midi_required',
        title: 'MIDI Required Stage',
        description: '',
        difficulty: Difficulty.beginner,
        level: monoLevel,
        requiresMidi: true,
      );

      expect(stage.effectiveRequiresMidi, isTrue);
      expect(stage.inputRequirementLabel, 'Digital piano (MIDI) required');
    });

    test('addImportedLevel sets requiresMidi on polyphonic levels', () {
      final repository = LevelRepository();
      const chordLevel = LevelModel(
        id: 'imported_chord',
        title: 'Imported Chord',
        description: '',
        tempo: 120,
        beatsPerMeasure: 4,
        totalMeasures: 1,
        measures: [
          LevelMeasure(
            index: 0,
            startBeat: 0,
            beatsPerMeasure: 4,
            notes: [
              LevelNote(
                midiNote: 60,
                startBeat: 0,
                durationBeats: 1,
                measureIndex: 0,
                beatIndex: 0,
              ),
              LevelNote(
                midiNote: 64,
                startBeat: 0,
                durationBeats: 1,
                measureIndex: 0,
                beatIndex: 0,
              ),
            ],
          ),
        ],
      );

      repository.addImportedLevel(chordLevel);
      final stage = repository.getStage('imported_imported_chord');
      expect(stage, isNotNull);
      expect(stage!.requiresMidi, isTrue);
      expect(stage.effectiveRequiresMidi, isTrue);
      expect(stage.inputRequirementLabel, 'Digital piano (MIDI) required');
    });
  });
}
