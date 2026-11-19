import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/engine/stage_engine.dart';
import 'package:piano_tool/models/audio_models.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/models/level_models.dart';

const _singleNoteLevel = LevelModel(
  id: 'waiting_single',
  title: 'Waiting Single Level',
  description: '',
  tempo: 120,
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
      ],
    ),
  ],
);

const _chordLevel = LevelModel(
  id: 'waiting_chord',
  title: 'Waiting Chord Level',
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
        LevelNote(
          midiNote: 67,
          startBeat: 2,
          durationBeats: 1,
          measureIndex: 0,
          beatIndex: 2,
        ),
      ],
    ),
  ],
);

void main() {
  group('StageEngine - Waiting Mode vs Timed Mode', () {
    test('defaults to timed mode with no waiting hint', () {
      final engine = StageEngine(level: _singleNoteLevel);
      addTearDown(engine.dispose);

      expect(engine.practiceMode, PracticeMode.timed);
      expect(engine.mode, PracticeMode.timed);
      expect(engine.state.isTimedMode, isTrue);
      expect(engine.state.isWaitingMode, isFalse);
      expect(engine.state.waitingHint, isNull);
    });

    test('can be initialized with waiting mode directly or via config', () {
      final engine1 = StageEngine(
        level: _singleNoteLevel,
        practiceMode: PracticeMode.waiting,
      );
      addTearDown(engine1.dispose);
      expect(engine1.practiceMode, PracticeMode.waiting);
      expect(engine1.state.isWaitingMode, isTrue);

      final engine2 = StageEngine(
        level: _singleNoteLevel,
        config: const StageEngineConfig(practiceMode: PracticeMode.waiting),
      );
      addTearDown(engine2.dispose);
      expect(engine2.practiceMode, PracticeMode.waiting);
      expect(engine2.state.isWaitingMode, isTrue);
    });

    test('switching mode dynamically updates state and manages timer', () {
      final engine = StageEngine(level: _singleNoteLevel);
      addTearDown(engine.dispose);

      engine.setPracticeMode(PracticeMode.waiting);
      expect(engine.practiceMode, PracticeMode.waiting);
      expect(engine.state.isWaitingMode, isTrue);

      engine.setPracticeMode(PracticeMode.timed);
      expect(engine.practiceMode, PracticeMode.timed);
      expect(engine.state.isTimedMode, isTrue);
    });

    test('starting in waiting mode sets playhead at first note and provides hint', () {
      final engine = StageEngine(
        level: _singleNoteLevel,
        practiceMode: PracticeMode.waiting,
      );
      addTearDown(engine.dispose);

      engine.start();

      expect(engine.state.engineState, StageEngineStatus.playing);
      expect(engine.state.currentBeat, 0.0);
      expect(engine.state.noteStates[0], NoteState.active);
      expect(engine.state.noteStates[1], NoteState.upcoming);
      expect(engine.state.noteStates[2], NoteState.upcoming);

      final hint = engine.state.waitingHint;
      expect(hint, isNotNull);
      expect(hint!.targetBeat, 0.0);
      expect(hint.targetMidiNotes, [60]);
      expect(hint.hintText, contains('Play C4 (Middle C)'));
      expect(hint.measureIndex, 0);
      expect(hint.beatIndex, 0);
    });

    test('in waiting mode, timer does not advance beat or score misses', () async {
      final engine = StageEngine(
        level: _singleNoteLevel,
        practiceMode: PracticeMode.waiting,
      );
      addTearDown(engine.dispose);

      engine.start();
      expect(engine.state.currentBeat, 0.0);

      // Wait 100 ms (several tick intervals)
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(engine.state.currentBeat, 0.0);
      expect(engine.state.missCount, 0);
      expect(engine.state.noteStates[0], NoteState.active);
    });

    test('striking expected note registers hit, does not award timed score, and advances playhead', () async {
      final engine = StageEngine(
        level: _singleNoteLevel,
        practiceMode: PracticeMode.waiting,
      );
      addTearDown(engine.dispose);

      StageEvent? lastEvent;
      engine.events.listen((e) => lastEvent = e);

      engine.start();

      // Strike middle C (60)
      engine.processPitchEvent(
        const PitchEvent(
          frequency: 261.63,
          confidence: 0.9,
          midiNote: 60,
          timestamp: 0.0,
          volume: 0.8,
          struck: true,
        ),
      );

      await pumpEventQueue();

      // Note was hit
      expect(engine.state.noteStates[0], NoteState.hitPerfect);
      expect(engine.state.hitCount, 1);
      // "without awarding a timed score"
      expect(engine.state.score, 0);

      // Playhead advances to next note at beat 2.0
      expect(engine.state.currentBeat, 2.0);
      expect(engine.state.noteStates[1], NoteState.active);
      expect(engine.state.noteStates[2], NoteState.upcoming);

      final hint = engine.state.waitingHint;
      expect(hint, isNotNull);
      expect(hint!.targetBeat, 2.0);
      expect(hint.targetMidiNotes, [62]);
      expect(hint.hintText, contains('Play D4'));

      // Check emitted event
      expect(lastEvent, isNotNull);
      expect(engine.state.accuracy, 1.0);
    });

    test('wrong note in waiting mode offers contextual feedback without miss penalties', () {
      final engine = StageEngine(
        level: _singleNoteLevel,
        practiceMode: PracticeMode.waiting,
      );
      addTearDown(engine.dispose);

      engine.start();

      // Play wrong note: D4 (62) instead of C4 (60)
      engine.processPitchEvent(
        const PitchEvent(
          frequency: 293.66,
          confidence: 0.9,
          midiNote: 62,
          timestamp: 0.0,
          volume: 0.8,
          struck: true,
        ),
      );

      // Does not mark missed or advance
      expect(engine.state.currentBeat, 0.0);
      expect(engine.state.noteStates[0], NoteState.active);
      expect(engine.state.missCount, 0);
      expect(engine.state.hitCount, 0);
      expect(engine.state.score, 0);

      // Contextual hint reflects what was heard and what is awaited
      final hint = engine.state.waitingHint;
      expect(hint, isNotNull);
      expect(hint!.heardWrongMidiNote, 62);
      expect(hint.hintText, contains('Heard D4. Waiting for C4 (Middle C).'));

      // Now play the correct note C4 (60)
      engine.processPitchEvent(
        const PitchEvent(
          frequency: 261.63,
          confidence: 0.9,
          midiNote: 60,
          timestamp: 0.1,
          volume: 0.8,
          struck: true,
        ),
      );

      // Correctly resolved and advanced
      expect(engine.state.noteStates[0], NoteState.hitPerfect);
      expect(engine.state.currentBeat, 2.0);
      expect(engine.state.waitingHint!.hintText, contains('Play D4'));
      expect(engine.state.waitingHint!.heardWrongMidiNote, isNull);
    });

    test('chord handling in waiting mode: waits for all notes at beat before advancing', () {
      final engine = StageEngine(
        level: _chordLevel,
        practiceMode: PracticeMode.waiting,
      );
      addTearDown(engine.dispose);

      engine.start();

      expect(engine.state.currentBeat, 0.0);
      expect(engine.state.noteStates[0], NoteState.active); // 60 (C4)
      expect(engine.state.noteStates[1], NoteState.active); // 64 (E4)
      expect(engine.state.noteStates[2], NoteState.upcoming); // 67 (G4)

      final initialHint = engine.state.waitingHint;
      expect(initialHint, isNotNull);
      expect(initialHint!.targetMidiNotes, [60, 64]);
      expect(initialHint.hintText, contains('Play C4 (Middle C) and E4'));

      // Strike C4 (60)
      engine.processPitchEvent(
        const PitchEvent(
          frequency: 261.63,
          confidence: 0.9,
          midiNote: 60,
          timestamp: 0.0,
          volume: 0.8,
          struck: true,
        ),
      );

      // C4 is hit, but E4 is still unhit: playhead stays at beat 0.0
      expect(engine.state.noteStates[0], NoteState.hitPerfect);
      expect(engine.state.noteStates[1], NoteState.active);
      expect(engine.state.currentBeat, 0.0);

      // Hint updates to remaining note
      expect(engine.state.waitingHint!.targetMidiNotes, [64]);
      expect(engine.state.waitingHint!.hintText, contains('Play E4'));

      // Strike E4 (64)
      engine.processPitchEvent(
        const PitchEvent(
          frequency: 329.63,
          confidence: 0.9,
          midiNote: 64,
          timestamp: 0.1,
          volume: 0.8,
          struck: true,
        ),
      );

      // Both notes hit: playhead now advances to G4 at beat 2.0
      expect(engine.state.noteStates[0], NoteState.hitPerfect);
      expect(engine.state.noteStates[1], NoteState.hitPerfect);
      expect(engine.state.currentBeat, 2.0);
      expect(engine.state.noteStates[2], NoteState.active);
      expect(engine.state.waitingHint!.hintText, contains('Play G4'));
    });

    test('completing level in waiting mode completes stage with 0 score and clears hint', () async {
      final engine = StageEngine(
        level: _singleNoteLevel,
        practiceMode: PracticeMode.waiting,
      );
      addTearDown(engine.dispose);

      StageEvent? completionEvent;
      engine.events.listen((e) {
        e.whenOrNull(stageCompleted: (acc, score, total, hit, attemptDetail) {
          completionEvent = e;
        });
      });

      engine.start();

      // Hit note 0 (C4 at beat 0)
      engine.processPitchEvent(
        const PitchEvent(
          frequency: 261.63,
          confidence: 0.9,
          midiNote: 60,
          timestamp: 0.0,
          volume: 0.8,
          struck: true,
        ),
      );

      // Hit note 1 (D4 at beat 2)
      engine.processPitchEvent(
        const PitchEvent(
          frequency: 293.66,
          confidence: 0.9,
          midiNote: 62,
          timestamp: 0.1,
          volume: 0.8,
          struck: true,
        ),
      );

      // Hit note 2 (E4 at beat 4)
      engine.processPitchEvent(
        const PitchEvent(
          frequency: 329.63,
          confidence: 0.9,
          midiNote: 64,
          timestamp: 0.2,
          volume: 0.8,
          struck: true,
        ),
      );

      await pumpEventQueue();

      expect(engine.state.engineState, StageEngineStatus.completed);
      expect(engine.state.score, 0); // No timed score awarded
      expect(engine.state.hitCount, 3);
      expect(engine.state.missCount, 0);
      expect(engine.state.waitingHint, isNull);

      expect(completionEvent, isNotNull);
      completionEvent!.whenOrNull(
        stageCompleted: (accuracy, score, totalNotes, hitNotes, attemptDetail) {
          expect(score, 0);
          expect(accuracy, 1.0);
          expect(totalNotes, 3);
          expect(hitNotes, 3);
        },
      );
    });

    test('loop in waiting mode restarts at loop start when range notes are resolved', () {
      final engine = StageEngine(
        level: _singleNoteLevel,
        practiceMode: PracticeMode.waiting,
      );
      addTearDown(engine.dispose);

      // Loop first measure [0.0, 4.0)
      engine.playLoop(0.0, 4.0);

      expect(engine.loop, isNotNull);
      expect(engine.loop!.start, 0.0);
      expect(engine.loop!.end, 4.0);
      expect(engine.state.currentBeat, 0.0);
      expect(engine.state.waitingHint!.targetMidiNotes, [60]);

      // Hit C4
      engine.processPitchEvent(
        const PitchEvent(
          frequency: 261.63,
          confidence: 0.9,
          midiNote: 60,
          timestamp: 0.0,
          volume: 0.8,
          struck: true,
        ),
      );

      expect(engine.state.currentBeat, 2.0);
      expect(engine.state.waitingHint!.targetMidiNotes, [62]);

      // Hit D4 (last note in loop)
      engine.processPitchEvent(
        const PitchEvent(
          frequency: 293.66,
          confidence: 0.9,
          midiNote: 62,
          timestamp: 0.1,
          volume: 0.8,
          struck: true,
        ),
      );

      // Loop wrapped! Returned to beat 0.0 with reset note states
      expect(engine.state.currentBeat, 0.0);
      expect(engine.state.noteStates[0], NoteState.active);
      expect(engine.state.noteStates[1], NoteState.upcoming);
      expect(engine.state.score, 0);
      expect(engine.state.waitingHint!.targetMidiNotes, [60]);
    });

    test('seeking in waiting mode updates awaited note, resets forward notes, and keeps score 0', () {
      final engine = StageEngine(
        level: _singleNoteLevel,
        practiceMode: PracticeMode.waiting,
      );
      addTearDown(engine.dispose);

      engine.start();

      // Hit note 0
      engine.processPitchEvent(
        const PitchEvent(
          frequency: 261.63,
          confidence: 0.9,
          midiNote: 60,
          timestamp: 0.0,
          volume: 0.8,
          struck: true,
        ),
      );
      expect(engine.state.currentBeat, 2.0);

      // Seek back to 0.0
      engine.seekToBeat(0.0);

      expect(engine.state.currentBeat, 0.0);
      expect(engine.state.noteStates[0], NoteState.active);
      expect(engine.state.noteStates[1], NoteState.upcoming);
      expect(engine.state.waitingHint!.targetMidiNotes, [60]);
      expect(engine.state.score, 0);
    });

    test('switching from waiting to timed mode mid-play starts timer from current position', () {
      final engine = StageEngine(
        level: _singleNoteLevel,
        practiceMode: PracticeMode.waiting,
      );
      addTearDown(engine.dispose);

      engine.start();
      expect(engine.state.isWaitingMode, isTrue);

      engine.setPracticeMode(PracticeMode.timed);

      expect(engine.state.isTimedMode, isTrue);
      expect(engine.state.waitingHint, isNull);
    });
  });
}
