import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/engine/stage_engine.dart';
import 'package:piano_tool/models/audio_models.dart';
import 'package:piano_tool/models/engine_models.dart';
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

  group('timing windows', () {
    const config = StageEngineConfig(
      perfectWindow: 0.125,
      goodWindow: 0.25,
      okayWindow: 0.375,
      missWindow: 0.5,
    );

    StageEngine engineAt(double timingError) {
      const testLevel = LevelModel(
        id: 'timing-level',
        title: 'Timing level',
        description: '',
        tempo: 120,
        beatsPerMeasure: 4,
        totalMeasures: 1,
        measures: [
          LevelMeasure(
            index: 0,
            startBeat: 1,
            beatsPerMeasure: 4,
            notes: [
              LevelNote(
                midiNote: 60,
                startBeat: 1,
                durationBeats: 1,
                measureIndex: 0,
                beatIndex: 1,
              ),
            ],
          ),
        ],
      );
      final engine = StageEngine(level: testLevel, config: config);
      engine.start();
      engine.seekToBeat(1 + timingError);
      return engine;
    }

    void expectHitAtBoundary(
      double timingError, {
      required NoteState noteState,
      required int hitCount,
      required int perfectCount,
      required int goodCount,
      required int okayCount,
    }) {
      final engine = engineAt(timingError);
      addTearDown(engine.dispose);
      engine.processPitchEvent(const PitchEvent(
        frequency: 261.63,
        confidence: 1,
        midiNote: 60,
        timestamp: 0,
        volume: 1,
      ));

      expect(engine.state.noteStates.single, noteState);
      expect(engine.state.hitCount, hitCount);
      expect(engine.state.missCount, 0);
      expect(engine.state.perfectCount, perfectCount);
      expect(engine.state.goodCount, goodCount);
      expect(engine.state.okayCount, okayCount);
    }

    test('accepts the exact perfect boundary', () {
      expectHitAtBoundary(
        0.125,
        noteState: NoteState.hitPerfect,
        hitCount: 1,
        perfectCount: 1,
        goodCount: 0,
        okayCount: 0,
      );
    });

    test('accepts the exact good boundary', () {
      expectHitAtBoundary(
        0.25,
        noteState: NoteState.hitGood,
        hitCount: 1,
        perfectCount: 0,
        goodCount: 1,
        okayCount: 0,
      );
    });

    test('accepts the exact okay boundary', () {
      expectHitAtBoundary(
        0.375,
        noteState: NoteState.hitOkay,
        hitCount: 1,
        perfectCount: 0,
        goodCount: 0,
        okayCount: 1,
      );
    });

    test('counts a late miss-window event as a miss', () {
      final engine = engineAt(0.4);
      addTearDown(engine.dispose);
      engine.processPitchEvent(const PitchEvent(
        frequency: 261.63,
        confidence: 1,
        midiNote: 60,
        timestamp: 0,
        volume: 1,
      ));

      expect(engine.state.noteStates.single, NoteState.missed);
      expect(engine.state.hitCount, 0);
      expect(engine.state.missCount, 1);
      expect(engine.state.accuracy, 0);
    });

    test('counts an early miss-window event as a miss', () {
      final engine = engineAt(-0.4);
      addTearDown(engine.dispose);
      engine.processPitchEvent(const PitchEvent(
        frequency: 261.63,
        confidence: 1,
        midiNote: 60,
        timestamp: 0,
        volume: 1,
      ));

      expect(engine.state.noteStates.single, NoteState.missed);
      expect(engine.state.hitCount, 0);
      expect(engine.state.missCount, 1);
      expect(engine.state.accuracy, 0);
    });

    test('registers a note only once', () {
      final engine = engineAt(0);
      addTearDown(engine.dispose);
      const event = PitchEvent(
        frequency: 261.63,
        confidence: 1,
        midiNote: 60,
        timestamp: 0,
        volume: 1,
      );

      engine.processPitchEvent(event);
      engine.processPitchEvent(event);

      expect(engine.state.hitCount, 1);
      expect(engine.state.missCount, 0);
      expect(engine.state.score, 100);
    });

    test('completion reports hit metrics after a miss-window event', () async {
      const completionLevel = LevelModel(
        id: 'completion-level',
        title: 'Completion level',
        description: '',
        tempo: 60000,
        beatsPerMeasure: 1,
        totalMeasures: 1,
        measures: [
          LevelMeasure(
            index: 0,
            startBeat: 0,
            beatsPerMeasure: 1,
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
      final engine = StageEngine(level: completionLevel, config: config);
      addTearDown(engine.dispose);
      final completion = engine.events
          .where((event) => event.maybeMap(
                stageCompleted: (_) => true,
                orElse: () => false,
              ))
          .first;

      engine.start();
      engine.seekToBeat(0.4);
      engine.processPitchEvent(const PitchEvent(
        frequency: 261.63,
        confidence: 1,
        midiNote: 60,
        timestamp: 0,
        volume: 1,
      ));
      final event = await completion.timeout(const Duration(seconds: 1));

      event.map(
        noteHit: (_) => fail('Expected a stage completion event'),
        noteMissed: (_) => fail('Expected a stage completion event'),
        stageCompleted: (completed) {
          expect(completed.accuracy, 0);
          expect(completed.totalNotes, 1);
          expect(completed.hitNotes, 0);
          expect(completed.score, 0);
        },
        playbackPosition: (_) => fail('Expected a stage completion event'),
        stateChanged: (_) => fail('Expected a stage completion event'),
      );
    });
  });
}
