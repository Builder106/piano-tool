import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/engine/difficulty_assistance.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/models/level_models.dart';

void main() {
  group('DifficultyAssistanceEvaluator speed suggestions', () {
    test('steps down speeds correctly', () {
      expect(DifficultyAssistanceEvaluator.suggestSlowerSpeed(2.0), 1.0);
      expect(DifficultyAssistanceEvaluator.suggestSlowerSpeed(1.5), 1.0);
      expect(DifficultyAssistanceEvaluator.suggestSlowerSpeed(1.2), 1.0);
      expect(DifficultyAssistanceEvaluator.suggestSlowerSpeed(1.0), 0.75);
      expect(DifficultyAssistanceEvaluator.suggestSlowerSpeed(0.85), 0.75);
      expect(DifficultyAssistanceEvaluator.suggestSlowerSpeed(0.75), 0.5);
      expect(DifficultyAssistanceEvaluator.suggestSlowerSpeed(0.6), 0.5);
      expect(DifficultyAssistanceEvaluator.suggestSlowerSpeed(0.5), isNull);
      expect(DifficultyAssistanceEvaluator.suggestSlowerSpeed(0.4), isNull);
    });
  });

  group('DifficultyAssistanceEvaluator phrase suggestions', () {
    late LevelModel multiMeasureLevel;
    late LevelModel singleMeasureLevel;

    setUp(() {
      multiMeasureLevel = const LevelModel(
        id: 'test_multi',
        title: 'Multi Measure Piece',
        description: 'Test level',
        tempo: 120,
        totalMeasures: 4,
        beatsPerMeasure: 4,
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
                midiNote: 62,
                startBeat: 1,
                durationBeats: 1,
                measureIndex: 0,
                beatIndex: 1,
              ),
            ],
          ),
          LevelMeasure(
            index: 1,
            startBeat: 4,
            beatsPerMeasure: 4,
            notes: [
              LevelNote(
                midiNote: 64,
                startBeat: 4,
                durationBeats: 1,
                measureIndex: 1,
                beatIndex: 0,
              ),
              LevelNote(
                midiNote: 65,
                startBeat: 5,
                durationBeats: 1,
                measureIndex: 1,
                beatIndex: 1,
              ),
            ],
          ),
          LevelMeasure(
            index: 2,
            startBeat: 8,
            beatsPerMeasure: 4,
            notes: [
              LevelNote(
                midiNote: 67,
                startBeat: 8,
                durationBeats: 1,
                measureIndex: 2,
                beatIndex: 0,
              ),
              LevelNote(
                midiNote: 69,
                startBeat: 9,
                durationBeats: 1,
                measureIndex: 2,
                beatIndex: 1,
              ),
            ],
          ),
          LevelMeasure(
            index: 3,
            startBeat: 12,
            beatsPerMeasure: 4,
            notes: [
              LevelNote(
                midiNote: 71,
                startBeat: 12,
                durationBeats: 1,
                measureIndex: 3,
                beatIndex: 0,
              ),
              LevelNote(
                midiNote: 72,
                startBeat: 13,
                durationBeats: 1,
                measureIndex: 3,
                beatIndex: 1,
              ),
            ],
          ),
        ],
      );

      singleMeasureLevel = const LevelModel(
        id: 'test_single',
        title: 'Single Measure Piece',
        description: 'Test level',
        tempo: 120,
        totalMeasures: 1,
        beatsPerMeasure: 4,
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
    });

    test('findMostMissedMeasure identifies the measure with highest miss count', () {
      final allNotes = multiMeasureLevel.measures
          .expand((m) => m.notes)
          .toList();
      // Notes: 0,1 (m0), 2,3 (m1), 4,5 (m2), 6,7 (m3)
      final states = [
        NoteState.hitPerfect, // n0 (m0)
        NoteState.missed,     // n1 (m0) -> 1 miss
        NoteState.hitPerfect, // n2 (m1)
        NoteState.hitPerfect, // n3 (m1) -> 0 misses
        NoteState.missed,     // n4 (m2) -> 2 misses
        NoteState.missed,     // n5 (m2)
        NoteState.hitPerfect, // n6 (m3)
        NoteState.hitPerfect, // n7 (m3) -> 0 misses
      ];

      final worst = DifficultyAssistanceEvaluator.findMostMissedMeasure(
        allNotes: allNotes,
        noteStates: states,
      );
      expect(worst, 2);
    });

    test('suggestShorterPhrase targets most missed measure on full piece', () {
      final allNotes = multiMeasureLevel.measures
          .expand((m) => m.notes)
          .toList();
      final states = [
        NoteState.hitPerfect,
        NoteState.hitPerfect,
        NoteState.hitPerfect,
        NoteState.hitPerfect,
        NoteState.missed,
        NoteState.missed,
        NoteState.hitPerfect,
        NoteState.hitPerfect,
      ];

      final suggested = DifficultyAssistanceEvaluator.suggestShorterPhrase(
        level: multiMeasureLevel,
        allNotes: allNotes,
        noteStates: states,
      );
      expect(suggested, (2, 2));
    });

    test('suggestShorterPhrase returns null on a 1-measure piece', () {
      final allNotes = singleMeasureLevel.measures
          .expand((m) => m.notes)
          .toList();
      final states = [NoteState.missed];

      final suggested = DifficultyAssistanceEvaluator.suggestShorterPhrase(
        level: singleMeasureLevel,
        allNotes: allNotes,
        noteStates: states,
      );
      expect(suggested, isNull);
    });

    test('suggestShorterPhrase narrows multi-measure loop to hardest measure', () {
      final allNotes = multiMeasureLevel.measures
          .expand((m) => m.notes)
          .toList();
      // Currently looping measures 1 to 3
      final states = [
        NoteState.upcoming,
        NoteState.upcoming,
        NoteState.hitPerfect,
        NoteState.hitPerfect,
        NoteState.missed, // Measure 2 has miss
        NoteState.missed,
        NoteState.hitPerfect,
        NoteState.hitPerfect,
      ];

      final suggested = DifficultyAssistanceEvaluator.suggestShorterPhrase(
        level: multiMeasureLevel,
        currentLoopRange: (1, 3),
        allNotes: allNotes,
        noteStates: states,
      );
      expect(suggested, (2, 2));
    });

    test('suggestShorterPhrase returns null when already looping a single measure', () {
      final allNotes = multiMeasureLevel.measures
          .expand((m) => m.notes)
          .toList();
      final states = [
        NoteState.missed,
        NoteState.missed,
        NoteState.upcoming,
        NoteState.upcoming,
        NoteState.upcoming,
        NoteState.upcoming,
        NoteState.upcoming,
        NoteState.upcoming,
      ];

      final suggested = DifficultyAssistanceEvaluator.suggestShorterPhrase(
        level: multiMeasureLevel,
        currentLoopRange: (0, 0),
        allNotes: allNotes,
        noteStates: states,
      );
      expect(suggested, isNull);
    });
  });

  group('DifficultyAssistanceEvaluator evaluate', () {
    late LevelModel level;
    late List<LevelNote> allNotes;

    setUp(() {
      level = const LevelModel(
        id: 'eval_test',
        title: 'Evaluation Test',
        description: 'Test level',
        tempo: 100,
        totalMeasures: 3,
        beatsPerMeasure: 4,
        measures: [
          LevelMeasure(
            index: 0,
            startBeat: 0,
            beatsPerMeasure: 4,
            notes: [
              LevelNote(
                midiNote: 60,
                startBeat: 0,
                durationBeats: 2,
                measureIndex: 0,
                beatIndex: 0,
              ),
            ],
          ),
          LevelMeasure(
            index: 1,
            startBeat: 4,
            beatsPerMeasure: 4,
            notes: [
              LevelNote(
                midiNote: 64,
                startBeat: 4,
                durationBeats: 2,
                measureIndex: 1,
                beatIndex: 0,
              ),
            ],
          ),
          LevelMeasure(
            index: 2,
            startBeat: 8,
            beatsPerMeasure: 4,
            notes: [
              LevelNote(
                midiNote: 67,
                startBeat: 8,
                durationBeats: 2,
                measureIndex: 2,
                beatIndex: 0,
              ),
            ],
          ),
        ],
      );
      allNotes = level.measures.expand((m) => m.notes).toList();
    });

    test('does not offer assistance after only 1 unsuccessful attempt', () {
      final offer = DifficultyAssistanceEvaluator.evaluate(
        level: level,
        currentSpeed: 1.0,
        allNotes: allNotes,
        noteStates: [NoteState.hitPerfect, NoteState.missed, NoteState.missed],
        unsuccessfulAttempts: 1,
      );
      expect(offer, isNull);
    });

    test('offers both slower speed and shorter phrase after 2 unsuccessful attempts', () {
      final offer = DifficultyAssistanceEvaluator.evaluate(
        level: level,
        currentSpeed: 1.0,
        allNotes: allNotes,
        noteStates: [NoteState.hitPerfect, NoteState.missed, NoteState.missed],
        unsuccessfulAttempts: 2,
      );
      expect(offer, isNotNull);
      expect(offer!.unsuccessfulAttempts, 2);
      expect(offer.currentSpeed, 1.0);
      expect(offer.suggestedSpeed, 0.75);
      expect(offer.hasSlowerSpeed, isTrue);
      expect(offer.suggestedLoopRange, isNotNull);
      expect(offer.hasShorterPhrase, isTrue);
      expect(offer.message, contains('75% speed'));
      expect(offer.message, contains('focusing on measure'));
      expect(offer.reason, contains('2 unsuccessful attempts'));
    });

    test('offers only shorter phrase when already at minimum speed (0.5)', () {
      final offer = DifficultyAssistanceEvaluator.evaluate(
        level: level,
        currentSpeed: 0.5,
        allNotes: allNotes,
        noteStates: [NoteState.hitPerfect, NoteState.missed, NoteState.missed],
        unsuccessfulAttempts: 2,
      );
      expect(offer, isNotNull);
      expect(offer!.suggestedSpeed, isNull);
      expect(offer.hasSlowerSpeed, isFalse);
      expect(offer.hasShorterPhrase, isTrue);
      expect(offer.message, contains('Try focusing on measure'));
      expect(offer.message, isNot(contains('speed')));
    });

    test('offers only slower speed when already looping a single measure', () {
      final offer = DifficultyAssistanceEvaluator.evaluate(
        level: level,
        currentSpeed: 1.0,
        currentLoopRange: (1, 1),
        allNotes: allNotes,
        noteStates: [NoteState.upcoming, NoteState.missed, NoteState.upcoming],
        unsuccessfulAttempts: 2,
      );
      expect(offer, isNotNull);
      expect(offer!.suggestedSpeed, 0.75);
      expect(offer.hasSlowerSpeed, isTrue);
      expect(offer.suggestedLoopRange, isNull);
      expect(offer.hasShorterPhrase, isFalse);
      expect(offer.message, 'Try slowing down to 75% speed.');
    });

    test('returns null when at minimum speed and already looping a single measure', () {
      final offer = DifficultyAssistanceEvaluator.evaluate(
        level: level,
        currentSpeed: 0.5,
        currentLoopRange: (1, 1),
        allNotes: allNotes,
        noteStates: [NoteState.upcoming, NoteState.missed, NoteState.upcoming],
        unsuccessfulAttempts: 3,
      );
      expect(offer, isNull);
    });
  });
}
