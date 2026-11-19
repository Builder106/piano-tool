import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/engine/stage_engine.dart';
import 'package:piano_tool/models/audio_models.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/models/level_models.dart';

PitchEvent _strike(int midi, {double timestamp = 0.0}) => PitchEvent(
  midiNote: midi,
  frequency: 440.0 * math.pow(2.0, (midi - 69) / 12.0),
  confidence: 1.0,
  volume: 0.8,
  timestamp: timestamp,
  struck: true,
);

LevelModel _createTwoHandLevel() {
  return const LevelModel(
    id: 'two_hand_test',
    title: 'Two Hand Test Level',
    description: 'Level with authored voices for both hands',
    tempo: 120,
    beatsPerMeasure: 4,
    totalMeasures: 2,
    clef: LevelClef.grand,
    measures: [
      LevelMeasure(
        index: 0,
        startBeat: 0,
        beatsPerMeasure: 4,
        notes: [
          // Beat 0: Right hand C4, Left hand C3
          LevelNote(
            midiNote: 60, // C4
            startBeat: 0,
            durationBeats: 1,
            measureIndex: 0,
            beatIndex: 0,
            voiceIndex: 0, // Right hand
          ),
          LevelNote(
            midiNote: 48, // C3
            startBeat: 0,
            durationBeats: 1,
            measureIndex: 0,
            beatIndex: 0,
            voiceIndex: 1, // Left hand
          ),
          // Beat 2: Right hand E4
          LevelNote(
            midiNote: 64, // E4
            startBeat: 2,
            durationBeats: 1,
            measureIndex: 0,
            beatIndex: 2,
            voiceIndex: 0, // Right hand
          ),
          // Beat 3: Left hand G3
          LevelNote(
            midiNote: 55, // G3
            startBeat: 3,
            durationBeats: 1,
            measureIndex: 0,
            beatIndex: 3,
            voiceIndex: 1, // Left hand
          ),
        ],
      ),
      LevelMeasure(
        index: 1,
        startBeat: 4,
        beatsPerMeasure: 4,
        notes: [
          // Beat 4: Right hand G4, Left hand C3
          LevelNote(
            midiNote: 67, // G4
            startBeat: 4,
            durationBeats: 2,
            measureIndex: 1,
            beatIndex: 0,
            voiceIndex: 0, // Right hand
          ),
          LevelNote(
            midiNote: 48, // C3
            startBeat: 4,
            durationBeats: 2,
            measureIndex: 1,
            beatIndex: 0,
            voiceIndex: 1, // Left hand
          ),
        ],
      ),
    ],
  );
}

LevelModel _createUnvoicedLevel() {
  return const LevelModel(
    id: 'unvoiced_test',
    title: 'Unvoiced Level',
    description: 'Level without authored voice data (default voiceIndex 0)',
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
            voiceIndex: 0,
          ),
          LevelNote(
            midiNote: 62,
            startBeat: 1,
            durationBeats: 1,
            measureIndex: 0,
            beatIndex: 1,
            voiceIndex: 0,
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('Authored Voice Data & Unknown Hand Identification', () {
    test(
      'identifies content with unknown hand assignment when voice data is unauthored',
      () {
        final unvoiced = _createUnvoicedLevel();
        expect(unvoiced.hasAuthoredVoices, isFalse);
        expect(unvoiced.isHandAssignmentKnown, isFalse);
        expect(unvoiced.isHandAssignmentUnknown, isTrue);
        expect(unvoiced.supportedHands, {HandSelection.both});

        final note = unvoiced.measures.first.notes.first;
        expect(unvoiced.handForNote(note), NoteHand.unknown);
      },
    );

    test(
      'identifies content with known hand assignment when voice data is authored',
      () {
        final twoHand = _createTwoHandLevel();
        expect(twoHand.hasAuthoredVoices, isTrue);
        expect(twoHand.isHandAssignmentKnown, isTrue);
        expect(twoHand.isHandAssignmentUnknown, isFalse);
        expect(twoHand.supportedHands, {
          HandSelection.both,
          HandSelection.right,
          HandSelection.left,
        });

        final rightNote = twoHand.measures[0].notes[0]; // voiceIndex 0
        final leftNote = twoHand.measures[0].notes[1]; // voiceIndex 1
        expect(twoHand.handForNote(rightNote), NoteHand.right);
        expect(twoHand.handForNote(leftNote), NoteHand.left);
        expect(rightNote.hand, NoteHand.right);
        expect(leftNote.hand, NoteHand.left);
      },
    );

    test('validates supported hand selection in setHandSelection', () {
      final unvoiced = _createUnvoicedLevel();
      final engine = StageEngine(level: unvoiced);

      expect(engine.handSelection, HandSelection.both);
      // Attempting to select right or left hand on unvoiced content throws ArgumentError
      expect(
        () => engine.setHandSelection(HandSelection.right),
        throwsArgumentError,
      );
      expect(
        () => engine.setHandSelection(HandSelection.left),
        throwsArgumentError,
      );
    });

    test(
      'fallback to both hands when unsupported hand is passed in config',
      () {
        final unvoiced = _createUnvoicedLevel();
        final engine = StageEngine(
          level: unvoiced,
          config: const StageEngineConfig(handSelection: HandSelection.left),
        );
        expect(engine.handSelection, HandSelection.both);
      },
    );
  });

  group('Playback Filtering (Phrase Demonstration)', () {
    test('sounds only right hand notes when right hand is selected', () {
      final level = _createTwoHandLevel();
      final engine = StageEngine(
        level: level,
        config: const StageEngineConfig(handSelection: HandSelection.right),
      );

      final soundedNotes = <LevelNote>[];
      engine.playDemonstration(0, 5, onNote: (note) => soundedNotes.add(note));

      // Notes are at beat 0 (60, 48), beat 2 (64), beat 3 (55), beat 4 (67, 48)
      // Only right hand notes (60, 64, 67) should sound
      expect(soundedNotes.map((n) => n.midiNote), [60]); // initial beat 0

      // Advance playhead past all notes
      engine.seekToBeat(5.0);
      expect(
        soundedNotes.map((n) => n.midiNote),
        everyElement(anyOf(60, 64, 67)),
      );
      expect(soundedNotes.any((n) => n.midiNote == 48), isFalse);
      expect(soundedNotes.any((n) => n.midiNote == 55), isFalse);
    });

    test('sounds only left hand notes when left hand is selected', () {
      final level = _createTwoHandLevel();
      final engine = StageEngine(
        level: level,
        config: const StageEngineConfig(handSelection: HandSelection.left),
      );

      final soundedNotes = <LevelNote>[];
      engine.playDemonstration(0, 5, onNote: (note) => soundedNotes.add(note));

      // At beat 0, only left hand note (48) sounds, right hand (60) is ignored
      expect(soundedNotes.map((n) => n.midiNote), [48]);
    });

    test('sounds all notes when both hands are selected', () {
      final level = _createTwoHandLevel();
      final engine = StageEngine(
        level: level,
        config: const StageEngineConfig(handSelection: HandSelection.both),
      );

      final soundedNotes = <LevelNote>[];
      engine.playDemonstration(0, 1, onNote: (note) => soundedNotes.add(note));

      // At beat 0, both 60 and 48 sound
      expect(soundedNotes.map((n) => n.midiNote).toSet(), {60, 48});
    });
  });

  group('Hint Filtering in Waiting Mode', () {
    test('awaits only right hand notes and generates right hand hints', () {
      final level = _createTwoHandLevel();
      final engine = StageEngine(
        level: level,
        practiceMode: PracticeMode.waiting,
        config: const StageEngineConfig(handSelection: HandSelection.right),
      );

      engine.start();

      // At beat 0, right hand note is C4 (60), left hand is C3 (48)
      expect(engine.state.currentBeat, 0.0);
      final hint = engine.state.waitingHint;
      expect(hint, isNotNull);
      expect(hint!.targetMidiNotes, [60]);
      expect(hint.hintText, contains('C4 (Middle C)'));
      expect(hint.hintText, isNot(contains('C3')));

      // Striking left hand note (48) triggers wrong note feedback
      engine.processPitchEvent(_strike(48));
      expect(
        engine.state.waitingHint!.hintText,
        contains('Heard C3. Waiting for C4 (Middle C)'),
      );
      expect(engine.state.currentBeat, 0.0); // Held at beat 0

      // Striking right hand note (60) completes beat 0 and advances to next right hand note (beat 2, E4)
      engine.processPitchEvent(_strike(60));
      expect(engine.state.currentBeat, 2.0);
      expect(engine.state.waitingHint!.targetMidiNotes, [64]);
      expect(engine.state.waitingHint!.hintText, contains('E4'));

      // Striking E4 advances past beat 3 (which only has left hand G3) directly to beat 4 (G4)
      engine.processPitchEvent(_strike(64));
      expect(engine.state.currentBeat, 4.0);
      expect(engine.state.waitingHint!.targetMidiNotes, [67]);
    });

    test('awaits only left hand notes when left hand is selected', () {
      final level = _createTwoHandLevel();
      final engine = StageEngine(
        level: level,
        practiceMode: PracticeMode.waiting,
        config: const StageEngineConfig(handSelection: HandSelection.left),
      );

      engine.start();

      // At beat 0, left hand note is C3 (48)
      expect(engine.state.currentBeat, 0.0);
      expect(engine.state.waitingHint!.targetMidiNotes, [48]);
      expect(engine.state.waitingHint!.hintText, contains('C3'));

      // Striking right hand C4 gives wrong note feedback
      engine.processPitchEvent(_strike(60));
      expect(
        engine.state.waitingHint!.hintText,
        contains('Heard C4. Waiting for C3'),
      );

      // Striking C3 advances past beat 2 (right hand only) directly to beat 3 (left hand G3, 55)
      engine.processPitchEvent(_strike(48));
      expect(engine.state.currentBeat, 3.0);
      expect(engine.state.waitingHint!.targetMidiNotes, [55]);
    });

    test('awaits both hands together when both hands are selected', () {
      final level = _createTwoHandLevel();
      final engine = StageEngine(
        level: level,
        practiceMode: PracticeMode.waiting,
        config: const StageEngineConfig(handSelection: HandSelection.both),
      );

      engine.start();

      // At beat 0, both C4 and C3 must be played
      expect(engine.state.currentBeat, 0.0);
      expect(engine.state.waitingHint!.targetMidiNotes, containsAll([60, 48]));
      expect(engine.state.waitingHint!.hintText, contains('and'));

      // Playing C4 hits one note, leaving C3 awaited at beat 0
      engine.processPitchEvent(_strike(60));
      expect(engine.state.currentBeat, 0.0);
      expect(engine.state.waitingHint!.targetMidiNotes, [48]);

      // Playing C3 completes beat 0 and advances to beat 2
      engine.processPitchEvent(_strike(48));
      expect(engine.state.currentBeat, 2.0);
    });
  });

  group('Scoring and Accuracy Filtering in Timed Mode', () {
    test(
      'activates, scores, and misses only right hand notes under right hand selection',
      () {
        final level = _createTwoHandLevel();
        final engine = StageEngine(
          level: level,
          practiceMode: PracticeMode.timed,
          config: const StageEngineConfig(handSelection: HandSelection.right),
        );

        engine.start();

        expect(engine.state.noteStates[0], NoteState.upcoming);
        expect(
          engine.state.noteStates[1],
          NoteState.upcoming,
        ); // Left hand note remains upcoming

        // Sticking right hand note C4 at beat 0
        engine.processPitchEvent(_strike(60));
        expect(engine.state.noteStates[0], NoteState.hitPerfect);
        expect(engine.state.score, 100);
        expect(engine.state.hitCount, 1);
        expect(engine.state.missCount, 0);

        // Playing left hand note C3 does not score
        engine.processPitchEvent(_strike(48));
        expect(engine.state.score, 100);
        expect(engine.state.hitCount, 1);

        // Seek past right hand note at beat 2 without striking it -> right hand note misses
        engine.seekToBeat(3.0);
        expect(engine.state.noteStates[2], NoteState.missed);
        // Left hand note at beat 0 (index 1) and beat 3 (index 3) must NOT be marked missed
        expect(engine.state.noteStates[1], NoteState.upcoming);
        expect(engine.state.noteStates[3], NoteState.upcoming);
        expect(engine.state.missCount, 1);
      },
    );

    test(
      'stage completion accuracy and totalNotes reflect only selected hand',
      () async {
        final level = _createTwoHandLevel();
        final engine = StageEngine(
          level: level,
          practiceMode: PracticeMode.waiting,
          config: const StageEngineConfig(handSelection: HandSelection.right),
        );

        StageEvent? completedEvent;
        engine.events.listen((e) {
          e.whenOrNull(
            stageCompleted:
                (accuracy, score, totalNotes, hitNotes, attemptDetail) {
                  completedEvent = e;
                },
          );
        });

        engine.start();

        // Right hand notes are at beat 0 (60), beat 2 (64), beat 4 (67)
        // Hit note at beat 0 (C4)
        engine.processPitchEvent(_strike(60));
        // Hit note at beat 2 (E4)
        engine.processPitchEvent(_strike(64));
        // Hit note at beat 4 (G4) - final note for right hand
        engine.processPitchEvent(_strike(67));

        await pumpEventQueue();

        expect(completedEvent, isNotNull);
        completedEvent!.whenOrNull(
          stageCompleted:
              (accuracy, score, totalNotes, hitNotes, attemptDetail) {
                expect(totalNotes, 3); // exactly 3 right hand notes
                expect(hitNotes, 3);
                expect(accuracy, 1.0); // 100% accuracy
                expect(score, 0); // waiting mode awards 0 timed score
              },
        );
      },
    );
  });

  group('Hand Selection Dynamic Switching', () {
    test(
      'switching hand resets states and recalculates scores for active hand',
      () {
        final level = _createTwoHandLevel();
        final engine = StageEngine(
          level: level,
          practiceMode: PracticeMode.timed,
          config: const StageEngineConfig(handSelection: HandSelection.right),
        );

        engine.start();
        engine.processPitchEvent(_strike(60));
        expect(engine.state.score, 100);
        expect(engine.state.hitCount, 1);

        // Switch to left hand
        engine.setHandSelection(HandSelection.left);
        expect(engine.handSelection, HandSelection.left);
        expect(engine.state.handSelection, HandSelection.left);

        // Score and hitCount reset because previous hit was on right hand
        expect(engine.state.score, 0);
        expect(engine.state.hitCount, 0);
        expect(
          engine.state.noteStates[0],
          NoteState.upcoming,
        ); // Right hand reset to upcoming
      },
    );
  });
}
