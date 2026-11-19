import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/engine/stage_engine.dart';
import 'package:piano_tool/engine/timing_advice.dart';
import 'package:piano_tool/models/audio_models.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/models/level_models.dart';

PitchEvent _strike(int midi, {double timestamp = 0.0, double volume = 0.8}) =>
    PitchEvent(
      frequency: 440.0,
      confidence: 1.0,
      midiNote: midi,
      timestamp: timestamp,
      volume: volume,
      struck: true,
    );

void main() {
  const testLevel = LevelModel(
    id: 'attempt_detail_test',
    title: 'Attempt Detail Test',
    description: '',
    tempo: 120,
    beatsPerMeasure: 4,
    totalMeasures: 2,
    measures: [
      LevelMeasure(
        index: 0,
        startBeat: 0.0,
        beatsPerMeasure: 4,
        notes: [
          LevelNote(
            midiNote: 60, // C4
            startBeat: 1.0,
            durationBeats: 1.0,
            measureIndex: 0,
            beatIndex: 1,
          ),
          LevelNote(
            midiNote: 62, // D4
            startBeat: 3.0,
            durationBeats: 1.0,
            measureIndex: 0,
            beatIndex: 3,
          ),
        ],
      ),
      LevelMeasure(
        index: 1,
        startBeat: 4.0,
        beatsPerMeasure: 4,
        notes: [
          LevelNote(
            midiNote: 64, // E4
            startBeat: 5.0,
            durationBeats: 1.0,
            measureIndex: 1,
            beatIndex: 1,
          ),
          LevelNote(
            midiNote: 67, // G4
            startBeat: 7.0,
            durationBeats: 1.0,
            measureIndex: 1,
            beatIndex: 3,
          ),
        ],
      ),
    ],
  );

  group('NoteHitResult and AttemptDetail models', () {
    test('wrongPitch note hit result preserves details and maps to missed state', () {
      const wrong = NoteHitResult.wrongPitch(
        noteIndex: 2,
        playedMidiNote: 63,
        timingError: -0.08,
      );

      expect(wrong.noteIndex, 2);
      expect(wrong.playedMidiNote, 63);
      expect(wrong.timingError, -0.08);
      expect(wrong.noteState, NoteState.missed);
      expect(wrong.score, 0.0);
      expect(wrong.isHit, isFalse);
      expect(wrong.isMissed, isFalse);
      expect(wrong.isWrongPitch, isTrue);
    });

    test('missed note hit result separates unplayed from wrong pitch', () {
      const missed = NoteHitResult.missed(noteIndex: 1);

      expect(missed.noteIndex, 1);
      expect(missed.playedMidiNote, isNull);
      expect(missed.timingError, isNull);
      expect(missed.noteState, NoteState.missed);
      expect(missed.score, 0.0);
      expect(missed.isHit, isFalse);
      expect(missed.isMissed, isTrue);
      expect(missed.isWrongPitch, isFalse);
    });

    test('AttemptDetail.fromResults compiles note results and signed timing errors', () {
      final allNotes = testLevel.measures.expand((m) => m.notes).toList();
      final results = <int, NoteHitResult>{
        0: const NoteHitResult.perfect(noteIndex: 0, timingError: -0.02),
        1: const NoteHitResult.wrongPitch(
          noteIndex: 1,
          playedMidiNote: 63,
          timingError: 0.12,
        ),
        2: const NoteHitResult.good(noteIndex: 2, timingError: 0.09),
        3: const NoteHitResult.missed(noteIndex: 3),
      };

      final detail = AttemptDetail.fromResults(
        allNotes: allNotes,
        noteResults: results,
        handSelection: HandSelection.both,
        score: 175,
      );

      expect(detail.totalNotes, 4);
      expect(detail.hitNotes, 2);
      expect(detail.wrongPitchNotes, 1);
      expect(detail.missedNotes, 1);
      expect(detail.accuracy, 0.5);
      expect(detail.score, 175);
      expect(detail.hasErrors, isTrue);
      expect(detail.hasWrongPitches, isTrue);
      expect(detail.hasMissedExpected, isTrue);
      expect(detail.signedTimingErrors, [-0.02, 0.12, 0.09]);
      expect(detail.averageTimingError, closeTo((-0.02 + 0.12 + 0.09) / 3, 0.0001));
      expect(detail.wrongPitchMeasureIndices, [0]);
      expect(detail.missedMeasureIndices, [1]);
    });

    test('TimingAdvice evaluates from AttemptDetail', () {
      final allNotes = testLevel.measures.expand((m) => m.notes).toList();
      final results = <int, NoteHitResult>{
        0: const NoteHitResult.good(noteIndex: 0, timingError: 0.12),
        1: const NoteHitResult.good(noteIndex: 1, timingError: 0.10),
      };

      final detail = AttemptDetail.fromResults(
        allNotes: allNotes,
        noteResults: results,
        handSelection: HandSelection.both,
      );

      final advice = TimingAdvice.evaluateAttempt(
        detail: detail,
        isCalibrated: true,
      );

      expect(advice, isNotNull);
      expect(advice!.trend, TimingTrend.dragging);
      expect(advice.averageErrorBeats, closeTo(0.11, 0.001));
    });
  });

  group('StageEngine - Preserve attempt detail and separate missed from wrong pitch', () {
    test(
      'separates missed expected note from confirmed wrong pitch',
      () async {
        final engine = StageEngine(
          level: testLevel,
          config: const StageEngineConfig(
            playbackSpeed: 50.0,
            countInEnabled: false,
          ),
        );
        addTearDown(engine.dispose);

        final completion = engine.events
            .where((e) => e.maybeMap(stageCompleted: (_) => true, orElse: () => false))
            .first;

        engine.start();

        // Note 0 (C4 at beat 1.0): strike wrong pitch D#4 (63) at beat 1.05
        engine.seekToBeat(1.05);
        engine.processPitchEvent(_strike(63, timestamp: 0.05));

        expect(engine.state.noteStates[0], NoteState.missed);
        expect(engine.noteResults[0], isA<NoteHitResult>());
        final res0 = engine.noteResults[0]!;
        expect(res0.isWrongPitch, isTrue);
        expect(res0.isMissed, isFalse);
        expect(res0.playedMidiNote, 63);
        expect(res0.timingError, closeTo(0.05, 0.001));

        // Note 1 (D4 at beat 3.0): hit correctly at beat 2.95 (timingError = -0.05)
        engine.seekToBeat(2.95);
        engine.processPitchEvent(_strike(62, timestamp: 0.1));

        expect(engine.state.noteStates[1], NoteState.hitPerfect);
        final res1 = engine.noteResults[1]!;
        expect(res1.isHit, isTrue);
        expect(res1.timingError, closeTo(-0.05, 0.001));

        // Note 2 (E4 at beat 5.0): leave unplayed, advance past miss window (5.0 + 0.5 = 5.5)
        engine.seekToBeat(5.6);

        expect(engine.state.noteStates[2], NoteState.missed);
        final res2 = engine.noteResults[2]!;
        expect(res2.isMissed, isTrue);
        expect(res2.isWrongPitch, isFalse);
        expect(res2.playedMidiNote, isNull);
        expect(res2.timingError, isNull);

        // Note 3 (G4 at beat 7.0): hit correctly at beat 7.0
        engine.seekToBeat(7.0);
        engine.processPitchEvent(_strike(67, timestamp: 0.2));

        expect(engine.state.noteStates[3], NoteState.hitPerfect);

        // Advance to near end and wait for stage completion event
        engine.seekToBeat(7.8);
        await completion.timeout(const Duration(seconds: 1));

        expect(engine.state.engineState, StageEngineStatus.completed);
        final detail = engine.attemptDetail;
        expect(detail, isNotNull);
        expect(detail!.totalNotes, 4);
        expect(detail.hitNotes, 2);
        expect(detail.wrongPitchNotes, 1);
        expect(detail.missedNotes, 1);
        expect(detail.accuracy, 0.5);
        expect(detail.hasWrongPitches, isTrue);
        expect(detail.hasMissedExpected, isTrue);
        expect(detail.wrongPitchMeasureIndices, [0]);
        expect(detail.missedMeasureIndices, [1]);
        expect(detail.signedTimingErrors.length, 3); // 2 hits + 1 wrong pitch
      },
    );

    test(
      'scorer does not classify every unexpected pitch outside active hit window',
      () {
        final engine = StageEngine(level: testLevel);
        addTearDown(engine.dispose);
        engine.start();

        // At beat 0.1 (well before Note 0 startBeat 1.0 - okayWindow 0.3 = 0.7):
        // strike an unexpected pitch
        engine.seekToBeat(0.1);
        engine.processPitchEvent(_strike(72)); // C5

        // Note 0 must NOT be classified as wrong or missed; it remains upcoming
        expect(engine.state.noteStates[0], NoteState.upcoming);
        expect(engine.noteResults.containsKey(0), isFalse);
        expect(engine.state.missCount, 0);

        // Advance to beat 1.0 (Note 0 hit window) and hit correctly
        engine.seekToBeat(1.0);
        engine.processPitchEvent(_strike(60));
        expect(engine.state.noteStates[0], NoteState.hitPerfect);

        // At beat 2.0 (during rest between Note 0 [1.0..2.0] and Note 1 [3.0]):
        // strike an unexpected pitch
        engine.seekToBeat(2.0);
        engine.processPitchEvent(_strike(70));

        // Note 1 must NOT be classified as wrong; it remains upcoming
        expect(engine.state.noteStates[1], NoteState.upcoming);
        expect(engine.noteResults.containsKey(1), isFalse);
        expect(engine.state.missCount, 0);

        // Advance to beat 3.0 and hit Note 1 correctly
        engine.seekToBeat(3.0);
        engine.processPitchEvent(_strike(62));
        expect(engine.state.noteStates[1], NoteState.hitPerfect);
        expect(engine.state.hitCount, 2);
        expect(engine.state.missCount, 0);
      },
    );

    test('stageCompleted event carries attemptDetail into results flow', () async {
      final engine = StageEngine(
        level: testLevel,
        config: const StageEngineConfig(
          playbackSpeed: 50.0,
          countInEnabled: false,
        ),
      );
      addTearDown(engine.dispose);

      final completion = engine.events
          .where((e) => e.maybeMap(stageCompleted: (_) => true, orElse: () => false))
          .first;

      engine.start();

      // Note 0: wrong pitch
      engine.seekToBeat(1.0);
      engine.processPitchEvent(_strike(61)); // C#4 instead of C4

      // Note 1: hit
      engine.seekToBeat(3.0);
      engine.processPitchEvent(_strike(62));

      // Note 2: unplayed missed
      // Note 3: hit
      engine.seekToBeat(7.0);
      engine.processPitchEvent(_strike(67));

      // Finish piece
      engine.seekToBeat(7.8);
      final event = await completion.timeout(const Duration(seconds: 1));

      AttemptDetail? receivedDetail;
      event.whenOrNull(
        stageCompleted: (acc, score, total, hit, attemptDetail) {
          receivedDetail = attemptDetail;
        },
      );

      expect(receivedDetail, isNotNull);
      expect(receivedDetail!.totalNotes, 4);
      expect(receivedDetail!.hitNotes, 2);
      expect(receivedDetail!.wrongPitchNotes, 1);
      expect(receivedDetail!.missedNotes, 1);
      expect(receivedDetail!.accuracy, 0.5);
    });

    test('loopPassCompleted carries attemptDetail for repeat loops', () async {
      final engine = StageEngine(
        level: testLevel,
        config: const StageEngineConfig(
          playbackSpeed: 20.0,
          countInEnabled: false,
        ),
      );
      addTearDown(engine.dispose);

      final loopCompleted = engine.events
          .where((e) => e.maybeMap(loopPassCompleted: (_) => true, orElse: () => false))
          .first;

      // Loop measure 0 (beats [0, 4))
      engine.playLoop(0, 4);

      // Beat 1.0: Note 0 wrong pitch
      engine.seekToBeat(1.0);
      engine.processPitchEvent(_strike(65));

      // Beat 3.0: Note 1 hit
      engine.seekToBeat(3.0);
      engine.processPitchEvent(_strike(62));

      // Wait for loop to wrap at beat 4.0
      final event = await loopCompleted.timeout(const Duration(seconds: 1));

      AttemptDetail? loopDetail;
      event.whenOrNull(
        loopPassCompleted: (acc, score, total, hit, start, end, detail) {
          loopDetail = detail;
        },
      );

      expect(loopDetail, isNotNull);
      expect(loopDetail!.totalNotes, 2);
      expect(loopDetail!.hitNotes, 1);
      expect(loopDetail!.wrongPitchNotes, 1);
      expect(loopDetail!.missedNotes, 0);
    });
  });
}
