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
}
