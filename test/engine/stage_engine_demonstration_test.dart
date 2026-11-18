import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/engine/stage_engine.dart';
import 'package:piano_tool/models/audio_models.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/models/level_models.dart';

/// Ten beats a second, so a 4-beat measure is 400 ms.
const _testLevel = LevelModel(
  id: 'demo_test',
  title: 'Demo Test',
  description: '',
  tempo: 600,
  beatsPerMeasure: 4,
  totalMeasures: 3,
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
          startBeat: 2,
          durationBeats: 1,
          measureIndex: 0,
          beatIndex: 2,
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
          startBeat: 6,
          durationBeats: 1,
          measureIndex: 1,
          beatIndex: 2,
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
      ],
    ),
  ],
);

const _chordLevel = LevelModel(
  id: 'chord_test',
  title: 'Chord Test',
  description: '',
  tempo: 600,
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
          durationBeats: 2,
          measureIndex: 0,
          beatIndex: 0,
        ),
        LevelNote(
          midiNote: 64,
          startBeat: 0,
          durationBeats: 2,
          measureIndex: 0,
          beatIndex: 0,
        ),
        LevelNote(
          midiNote: 67,
          startBeat: 0,
          durationBeats: 2,
          measureIndex: 0,
          beatIndex: 0,
        ),
      ],
    ),
  ],
);

void main() {
  testWidgets(
    'playDemonstration sounds notes across phrase without scoring misses',
    (tester) async {
      final engine = StageEngine(level: _testLevel);
      final sounded = <int>[];
      var completed = false;

      // Demonstrate measure 0 (beats 0 to 4)
      engine.playDemonstration(
        0,
        4,
        onNote: (note) => sounded.add(note.midiNote),
        onComplete: () => completed = true,
      );

      expect(engine.isDemonstrating, isTrue);
      expect(engine.state.engineState, StageEngineStatus.playing);
      // Note at beat 0 sounds right away
      expect(sounded, [60]);

      // Advance 250 ms (2.5 beats) into the measure
      await tester.pump(const Duration(milliseconds: 250));
      expect(engine.state.currentBeat, greaterThan(2.0));
      // Note at beat 2 should have sounded
      expect(sounded, [60, 62]);
      // Notes passed without input MUST NOT be marked as missed during demonstration
      expect(engine.state.missCount, 0);
      expect(engine.state.hitCount, 0);
      expect(engine.state.score, 0);

      // Advance past end of measure 0 (400 ms total from start)
      await tester.pump(const Duration(milliseconds: 200));

      // Demonstration finished
      expect(completed, isTrue);
      expect(engine.isDemonstrating, isFalse);
      expect(engine.state.engineState, StageEngineStatus.idle);
      // Playhead reset to phrase start
      expect(engine.state.currentBeat, 0.0);
      // Notes reset to upcoming for the learner's turn
      expect(
        engine.state.noteStates[0],
        anyOf(NoteState.upcoming, NoteState.active),
      );
      expect(engine.state.noteStates[1], NoteState.upcoming);
      // Notes outside the demonstrated phrase remained untouched
      expect(engine.state.noteStates[2], NoteState.upcoming);

      engine.dispose();
    },
  );

  testWidgets(
    'demonstration rejects pitch events so audio cannot score itself',
    (tester) async {
      final engine = StageEngine(level: _testLevel);
      engine.playDemonstration(0, 4);

      expect(engine.isDemonstrating, isTrue);

      // Incoming pitch event while demonstrating (e.g. mic hears the speaker)
      engine.processPitchEvent(
        const PitchEvent(
          frequency: 261.6,
          confidence: 1.0,
          midiNote: 60,
          timestamp: 0.0,
          volume: 0.8,
          struck: true,
        ),
      );

      // Must NOT score or claim any hit
      expect(engine.state.hitCount, 0);
      expect(engine.state.score, 0);
      expect(engine.state.noteStates[0], isNot(NoteState.hitPerfect));
      expect(engine.state.noteStates[0], isNot(NoteState.hitGood));

      engine.dispose();
    },
  );

  testWidgets('demonstration sounds simultaneous notes in chords', (
    tester,
  ) async {
    final engine = StageEngine(level: _chordLevel);
    final sounded = <int>[];

    engine.playDemonstration(
      0,
      4,
      onNote: (note) => sounded.add(note.midiNote),
    );

    // All three chord notes at beat 0 must be sounded
    expect(sounded, containsAll([60, 64, 67]));
    expect(sounded.length, 3);

    engine.dispose();
  });

  testWidgets('stopDemonstration halts playback and resets note states', (
    tester,
  ) async {
    final engine = StageEngine(level: _testLevel);
    final sounded = <int>[];

    engine.playDemonstration(
      4,
      8,
      onNote: (note) => sounded.add(note.midiNote),
    );

    expect(engine.isDemonstrating, isTrue);
    expect(sounded, [64]);

    engine.stopDemonstration();

    expect(engine.isDemonstrating, isFalse);
    expect(engine.state.engineState, StageEngineStatus.idle);
    expect(engine.state.currentBeat, 4.0);
    expect(
      engine.state.noteStates[2],
      anyOf(NoteState.upcoming, NoteState.active),
    );
    expect(engine.state.noteStates[3], NoteState.upcoming);

    engine.dispose();
  });

  testWidgets(
    'seeking during demonstration clamps within bounds and allows forward notes',
    (tester) async {
      final engine = StageEngine(level: _testLevel);
      final sounded = <int>[];

      // Demonstrate entire piece (beats 0 to 12)
      engine.playDemonstration(
        0,
        12,
        onNote: (note) => sounded.add(note.midiNote),
      );

      expect(sounded, [60]);

      // Seek forward to beat 5 (past note 62 at beat 2 and note 64 at beat 4)
      engine.seekToBeat(5);
      expect(engine.state.currentBeat, 5.0);

      // Advance 150 ms (1.5 beats) to beat 6.5
      await tester.pump(const Duration(milliseconds: 150));
      // Note at beat 6 (midi 65) should sound
      expect(sounded, contains(65));

      engine.dispose();
    },
  );
}
