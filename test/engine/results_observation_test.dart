import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/engine/results_observation.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/models/level_models.dart';

void main() {
  group('ResultsObservationEvaluator', () {
    final stages = [
      StageModel(
        id: 'stage_1',
        title: 'C Major Scale',
        description: 'First stage',
        difficulty: Difficulty.beginner,
        level: LevelModel(
          id: 'level_1',
          title: 'C Major Scale',
          description: '',
          tempo: 80,
          beatsPerMeasure: 4,
          totalMeasures: 4,
          measures: const [],
        ),
        order: 1,
        prerequisites: const [],
        xpReward: 100,
      ),
      StageModel(
        id: 'stage_2',
        title: 'D Minor Melody',
        description: 'Second stage',
        difficulty: Difficulty.beginner,
        level: LevelModel(
          id: 'level_2',
          title: 'D Minor Melody',
          description: '',
          tempo: 80,
          beatsPerMeasure: 4,
          totalMeasures: 4,
          measures: const [],
        ),
        order: 2,
        prerequisites: const ['stage_1'],
        xpReward: 100,
      ),
    ];

    test('empty attempts do not invent advice', () {
      final obsEmpty = ResultsObservationEvaluator.evaluate(
        noteStates: const [],
        measureOfNote: const [],
      );

      expect(obsEmpty.isAbandonedOrEmpty, isTrue);
      expect(obsEmpty.observation, isEmpty);
      expect(obsEmpty.difficultMeasureRange, isNull);
      expect(obsEmpty.nextStageId, isNull);
    });

    test('unstarted/unresolved attempts do not invent advice', () {
      final obsUnstarted = ResultsObservationEvaluator.evaluate(
        noteStates: const [NoteState.upcoming, NoteState.upcoming],
        measureOfNote: const [0, 0],
      );

      expect(obsUnstarted.isAbandonedOrEmpty, isTrue);
      expect(obsUnstarted.observation, isEmpty);
      expect(obsUnstarted.difficultMeasureRange, isNull);
    });

    test('abandoned attempts do not invent advice', () {
      final obsAbandoned = ResultsObservationEvaluator.evaluate(
        noteStates: const [NoteState.hitPerfect, NoteState.upcoming],
        measureOfNote: const [0, 0],
        isAbandoned: true,
      );

      expect(obsAbandoned.isAbandonedOrEmpty, isTrue);
      expect(obsAbandoned.observation, isEmpty);
      expect(obsAbandoned.difficultMeasureRange, isNull);
      expect(obsAbandoned.nextStageId, isNull);
    });

    test(
      'derives single-bar difficult measure range and missed note observation',
      () {
        final obs = ResultsObservationEvaluator.evaluate(
          noteStates: const [
            NoteState.hitPerfect,
            NoteState.missed,
            NoteState.hitGood,
            NoteState.hitOkay,
          ],
          measureOfNote: const [0, 1, 2, 3],
        );

        expect(obs.isAbandonedOrEmpty, isFalse);
        expect(obs.difficultMeasureRange, (1, 1));
        expect(obs.worstMeasure, 1);
        expect(obs.observation, contains('Bar 2'));
        expect(obs.observation, contains('missed'));
      },
    );

    test(
      'derives multi-measure contiguous difficult range for adjacent error bars',
      () {
        final obs = ResultsObservationEvaluator.evaluate(
          noteStates: const [
            NoteState.hitPerfect,
            NoteState.missed,
            NoteState.missed,
            NoteState.hitPerfect,
          ],
          measureOfNote: const [0, 1, 2, 3],
        );

        expect(obs.isAbandonedOrEmpty, isFalse);
        expect(obs.difficultMeasureRange, (1, 2));
        expect(obs.observation, contains('Bars 2–3'));
      },
    );

    test(
      'distinguishes confirmed wrong pitches from missed expected notes',
      () {
        final noteResults = <int, NoteHitResult>{
          0: const NoteHitResult.perfect(noteIndex: 0, timingError: 0.0),
          1: const NoteHitResult.wrongPitch(
            noteIndex: 1,
            playedMidiNote: 63,
            timingError: 0.02,
          ),
          2: const NoteHitResult.good(noteIndex: 2, timingError: 0.0),
        };

        final obs = ResultsObservationEvaluator.evaluate(
          noteStates: const [
            NoteState.hitPerfect,
            NoteState.missed,
            NoteState.hitGood,
          ],
          measureOfNote: const [0, 1, 2],
          noteResults: noteResults,
        );

        expect(obs.isAbandonedOrEmpty, isFalse);
        expect(obs.difficultMeasureRange, (1, 1));
        expect(obs.observation, contains('Bar 2 had unexpected pitches'));
      },
    );

    test('identifies rushing timing errors in missed phrase', () {
      final noteResults = <int, NoteHitResult>{
        0: const NoteHitResult.perfect(noteIndex: 0, timingError: -0.08),
        1: const NoteHitResult.missed(noteIndex: 1),
      };

      final obs = ResultsObservationEvaluator.evaluate(
        noteStates: const [NoteState.hitPerfect, NoteState.missed],
        measureOfNote: const [0, 0],
        noteResults: noteResults,
      );

      expect(obs.observation, contains('rushing ahead of the beat'));
    });

    test('identifies dragging timing errors in missed phrase', () {
      final noteResults = <int, NoteHitResult>{
        0: const NoteHitResult.perfect(noteIndex: 0, timingError: 0.08),
        1: const NoteHitResult.missed(noteIndex: 1),
      };

      final obs = ResultsObservationEvaluator.evaluate(
        noteStates: const [NoteState.hitPerfect, NoteState.missed],
        measureOfNote: const [0, 0],
        noteResults: noteResults,
      );

      expect(obs.observation, contains('lagging behind the beat'));
    });

    test('offers next available stage after successful attempt', () {
      final obs = ResultsObservationEvaluator.evaluate(
        noteStates: const [
          NoteState.hitPerfect,
          NoteState.hitPerfect,
          NoteState.hitGood,
        ],
        measureOfNote: const [0, 1, 2],
        allStages: stages,
        currentStageId: 'stage_1',
      );

      expect(obs.isAbandonedOrEmpty, isFalse);
      expect(obs.difficultMeasureRange, isNull);
      expect(obs.nextStageId, 'stage_2');
      expect(obs.nextStageTitle, 'D Minor Melody');
      expect(obs.observation, contains('Ready for D Minor Melody'));
    });
  });
}
