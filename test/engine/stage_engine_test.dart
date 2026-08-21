import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/engine/stage_engine.dart';
import 'package:piano_tool/models/audio_models.dart';
import 'package:piano_tool/models/level_models.dart';

void main() {
  const level = LevelModel(
    id: 'test-level',
    title: 'Test level',
    description: 'A focused engine fixture.',
    tempo: 120,
    beatsPerMeasure: 4,
    totalMeasures: 2,
    measures: [
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

  test('allNotes provides the canonical chronological note order', () {
    final engine = StageEngine(level: level);
    addTearDown(engine.dispose);

    expect(engine.allNotes.map((note) => note.midiNote), [60, 64]);
  });

  test('scores a pitch event after the audio layer has vetted it', () {
    final engine = StageEngine(level: level);
    addTearDown(engine.dispose);
    engine.start();

    engine.processPitchEvent(const PitchEvent(
      frequency: 261.63,
      confidence: 0,
      midiNote: 60,
      timestamp: 0,
      volume: 0,
    ));

    expect(engine.state.hitCount, 1);
  });
}
