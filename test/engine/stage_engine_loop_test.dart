import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/engine/stage_engine.dart';
import 'package:piano_tool/models/audio_models.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/models/level_models.dart';

/// Ten beats a second, so a four-beat bar loops in 0.4 s.
const _fast = LevelModel(
  id: 'loop',
  title: 'Loop',
  description: '',
  tempo: 600,
  beatsPerMeasure: 4,
  totalMeasures: 2,
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
      ],
    ),
  ],
);

void main() {
  // These run on the test's own clock, advanced by pump, so they do not
  // depend on how fast the machine happens to be. The engine is disposed in
  // the body: a timer still running when the test ends fails it.
  testWidgets('a loop plays its bar again and never completes the piece', (
    tester,
  ) async {
    final e = StageEngine(level: _fast);
    e.playLoop(0, 4);
    await tester.pump(const Duration(milliseconds: 900));
    expect(e.state.engineState, StageEngineStatus.playing);
    expect(e.state.currentBeat, lessThan(4));
    expect(e.loop, isNotNull);
    e.dispose();
  });

  testWidgets('each pass judges the bar afresh', (tester) async {
    final e = StageEngine(level: _fast);
    e.playLoop(0, 4);
    e.processPitchEvent(
      const PitchEvent(
        frequency: 261.6,
        confidence: 1,
        midiNote: 60,
        timestamp: 0,
        volume: 0.5,
        struck: true,
      ),
    );
    expect(e.state.noteStates[0], isNot(NoteState.upcoming));
    expect(e.state.noteStates[0], isNot(NoteState.active));
    // Wait for the wrap at beat 4 (0.4 s) and a little into the next pass.
    await tester.pump(const Duration(milliseconds: 450));
    expect(e.state.noteStates[0], anyOf(NoteState.upcoming, NoteState.active));
    e.dispose();
  });

  test('starting or resetting clears the loop', () {
    final e = StageEngine(level: _fast);
    addTearDown(e.dispose);
    e.playLoop(0, 4);
    e.reset();
    expect(e.loop, isNull);
    e.playLoop(4, 8);
    e.pause();
    e.start();
    expect(e.loop, isNull);
  });

  testWidgets(
    'loop repeat scopes score to range and resets score and counts on each repeat pass',
    (tester) async {
      final e = StageEngine(level: _fast);
      e.playLoop(0, 4);

      // Hit the note in measure 0 (beat 0)
      e.processPitchEvent(
        const PitchEvent(
          frequency: 261.6,
          confidence: 1,
          midiNote: 60,
          timestamp: 0,
          volume: 0.5,
          struck: true,
        ),
      );
      expect(e.state.hitCount, 1);
      expect(e.state.score, 100);

      // Note in measure 1 (beat 4) must be untouched (upcoming, not hit/missed)
      expect(e.state.noteStates[1], NoteState.upcoming);

      // Advance through the loop wrap (beat 4 is at 0.4s) into the second pass (0.42s)
      await tester.pump(const Duration(milliseconds: 420));

      // Fresh attempt defined for the second pass: score, hits, misses reset
      expect(e.state.hitCount, 0);
      expect(e.state.score, 0);
      expect(e.state.missCount, 0);
      expect(e.state.noteStates[0], anyOf(NoteState.upcoming, NoteState.active));
      expect(e.state.noteStates[1], NoteState.upcoming);

      e.dispose();
    },
  );

  test(
    'seeking within a loop is clamped to the loop range and does not mark outer notes missed',
    () {
      final e = StageEngine(level: _fast);
      addTearDown(e.dispose);
      e.playLoop(4, 8); // Loop measure 1 (beats 4 to 8)

      // Note 0 (beat 0) is before the loop
      expect(e.state.noteStates[0], NoteState.upcoming);

      // Seeking backwards or forwards is clamped to the loop
      e.seekToBeat(0);
      expect(e.state.currentBeat, 4.0);
      // Outer note 0 must NOT be marked missed
      expect(e.state.noteStates[0], NoteState.upcoming);

      e.seekToBeat(10);
      expect(e.state.currentBeat, 8.0);

      // Seeking to beat 5 within the loop
      e.seekToBeat(5);
      expect(e.state.currentBeat, 5.0);
      // Note 1 (beat 4) passed its miss window without a hit, so it's marked missed in this loop attempt
      expect(e.state.noteStates[1], NoteState.missed);
      expect(e.state.missCount, 1);
      expect(e.state.noteStates[0], NoteState.upcoming); // outer note still untouched!

      // Seeking back to beat 4 resets the note in the loop for another try
      e.seekToBeat(4);
      expect(e.state.noteStates[1], anyOf(NoteState.upcoming, NoteState.active));
      expect(e.state.missCount, 0);
      expect(e.state.score, 0);
    },
  );

  testWidgets(
    'multi-measure range loop repeats across selected measures',
    (tester) async {
      const multi = LevelModel(
        id: 'multi',
        title: 'Multi',
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
            ],
          ),
          LevelMeasure(
            index: 1,
            startBeat: 4,
            beatsPerMeasure: 4,
            notes: [
              LevelNote(
                midiNote: 62,
                startBeat: 4,
                durationBeats: 1,
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
                midiNote: 64,
                startBeat: 8,
                durationBeats: 1,
                measureIndex: 2,
                beatIndex: 0,
              ),
            ],
          ),
        ],
      );

      final e = StageEngine(level: multi);
      // Loop measures 0 and 1 (beats 0 to 8)
      e.playLoop(0, 8);

      // Hit note 0 (beat 0)
      e.processPitchEvent(
        const PitchEvent(
          frequency: 261.6,
          confidence: 1,
          midiNote: 60,
          timestamp: 0,
          volume: 0.5,
          struck: true,
        ),
      );
      expect(e.state.hitCount, 1);

      // Note 2 in measure 2 (beat 8) is outside the loop
      expect(e.state.noteStates[2], NoteState.upcoming);

      // Advance across beat 4 (measure 1) into beat 7 (0.7 s)
      await tester.pump(const Duration(milliseconds: 700));
      expect(e.state.currentBeat, greaterThan(4));
      expect(e.state.currentBeat, lessThan(8));

      // Measure 2 note is still untouched
      expect(e.state.noteStates[2], NoteState.upcoming);

      // Advance across beat 8 wrap (0.8s) a little into the next pass (0.82s)
      await tester.pump(const Duration(milliseconds: 120));
      expect(e.state.currentBeat, lessThan(4));
      // Both notes in the loop reset for the fresh attempt
      expect(e.state.noteStates[0], anyOf(NoteState.upcoming, NoteState.active));
      expect(e.state.noteStates[1], anyOf(NoteState.upcoming, NoteState.active));
      expect(e.state.hitCount, 0);
      expect(e.state.score, 0);
      expect(e.state.noteStates[2], NoteState.upcoming);

      e.dispose();
    },
  );
}
