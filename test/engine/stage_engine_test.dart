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

    engine.processPitchEvent(
      const PitchEvent(
        frequency: 261.63,
        confidence: 0,
        midiNote: 60,
        timestamp: 0,
        volume: 0,
      ),
    );

    expect(engine.state.hitCount, 1);
  });

  group('repeated notes', () {
    const repeated = LevelModel(
      id: 'repeated',
      title: 'Repeated C',
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

    PitchEvent heard(double at, {double volume = 0.5}) => PitchEvent(
      frequency: 261.63,
      confidence: 1,
      midiNote: 60,
      timestamp: at,
      volume: volume,
    );

    test('a held pitch does not miss the next note before its beat', () {
      final engine = StageEngine(level: repeated);
      addTearDown(engine.dispose);

      engine.start();
      engine.processPitchEvent(heard(0));
      engine.seekToBeat(0.55);
      engine.processPitchEvent(heard(0.05));
      expect(engine.state.noteStates[1], isNot(NoteState.missed));
    });

    test('a held pitch does not score the repeated note', () {
      final engine = StageEngine(level: repeated);
      addTearDown(engine.dispose);

      engine.start();
      engine.processPitchEvent(heard(0));
      // The same C keeps ringing, one detector frame after another, into
      // the second note's window.
      for (var t = 0.05; t < 0.55; t += 0.05) {
        engine.processPitchEvent(heard(t, volume: 0.5 - t / 2));
      }
      engine.seekToBeat(1);
      engine.processPitchEvent(heard(0.55, volume: 0.2));

      expect(engine.state.hitCount, 1);
      expect(engine.state.noteStates[1], isNot(NoteState.hitPerfect));
    });

    test('a new strike after a silence scores the repeated note', () {
      final engine = StageEngine(level: repeated);
      addTearDown(engine.dispose);

      engine.start();
      engine.processPitchEvent(heard(0));
      engine.seekToBeat(1);
      engine.processPitchEvent(heard(0.5));

      expect(engine.state.hitCount, 2);
      expect(engine.state.missCount, 0);
    });

    test('a key struck again while ringing scores on its swell', () {
      final engine = StageEngine(level: repeated);
      addTearDown(engine.dispose);

      engine.start();
      engine.processPitchEvent(heard(0, volume: 0.5));
      engine.processPitchEvent(heard(0.05, volume: 0.2));
      engine.seekToBeat(1);
      engine.processPitchEvent(heard(0.1, volume: 0.6));

      expect(engine.state.hitCount, 2);
    });

    test('every MIDI note-on is a strike', () {
      final engine = StageEngine(level: repeated);
      addTearDown(engine.dispose);
      const noteOn = PitchEvent(
        frequency: 261.63,
        confidence: 1,
        midiNote: 60,
        timestamp: 0,
        volume: 1,
        struck: true,
      );

      engine.start();
      engine.processPitchEvent(noteOn);
      engine.seekToBeat(1);
      engine.processPitchEvent(noteOn);

      expect(engine.state.hitCount, 2);
    });
  });

  test('rest entries are never scored', () {
    const withRest = LevelModel(
      id: 'rest',
      title: 'Rest',
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
              midiNote: 0,
              startBeat: 1,
              durationBeats: 1,
              measureIndex: 0,
              beatIndex: 1,
              isRest: true,
            ),
          ],
        ),
      ],
    );
    final engine = StageEngine(level: withRest);
    addTearDown(engine.dispose);

    expect(engine.allNotes.map((n) => n.midiNote), [60]);
    expect(engine.state.noteStates, hasLength(1));
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
      engine.processPitchEvent(
        const PitchEvent(
          frequency: 261.63,
          confidence: 1,
          midiNote: 60,
          timestamp: 0,
          volume: 1,
        ),
      );

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
      engine.processPitchEvent(
        const PitchEvent(
          frequency: 261.63,
          confidence: 1,
          midiNote: 60,
          timestamp: 0,
          volume: 1,
        ),
      );

      expect(engine.state.noteStates.single, NoteState.missed);
      expect(engine.state.hitCount, 0);
      expect(engine.state.missCount, 1);
      expect(engine.state.accuracy, 0);
    });

    test('an early event leaves the note available for an on-time hit', () {
      final engine = engineAt(-0.4);
      addTearDown(engine.dispose);
      const event = PitchEvent(
        frequency: 261.63,
        confidence: 1,
        midiNote: 60,
        timestamp: 0,
        volume: 1,
      );
      engine.processPitchEvent(event);

      expect(engine.state.noteStates.single, isNot(NoteState.missed));
      expect(engine.state.hitCount, 0);
      expect(engine.state.missCount, 0);
      expect(engine.state.accuracy, 0);

      engine.seekToBeat(1);
      // Struck again, half a second later.
      engine.processPitchEvent(event.copyWith(timestamp: 0.5));
      expect(engine.state.hitCount, 1);
      expect(engine.state.missCount, 0);
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
          .where(
            (event) => event.maybeMap(
              stageCompleted: (_) => true,
              orElse: () => false,
            ),
          )
          .first;

      engine.start();
      engine.seekToBeat(0.4);
      engine.processPitchEvent(
        const PitchEvent(
          frequency: 261.63,
          confidence: 1,
          midiNote: 60,
          timestamp: 0,
          volume: 1,
        ),
      );
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

  group('polyphony and chords', () {
    const chordLevel = LevelModel(
      id: 'chord-level',
      title: 'Chord Level',
      description: 'C major triad followed by D minor triad.',
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
            ), // C4
            LevelNote(
              midiNote: 64,
              startBeat: 0,
              durationBeats: 1,
              measureIndex: 0,
              beatIndex: 0,
            ), // E4
            LevelNote(
              midiNote: 67,
              startBeat: 0,
              durationBeats: 1,
              measureIndex: 0,
              beatIndex: 0,
            ), // G4
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
            ), // D4
            LevelNote(
              midiNote: 65,
              startBeat: 4,
              durationBeats: 1,
              measureIndex: 1,
              beatIndex: 0,
            ), // F4
            LevelNote(
              midiNote: 69,
              startBeat: 4,
              durationBeats: 1,
              measureIndex: 1,
              beatIndex: 0,
            ), // A4
          ],
        ),
      ],
    );

    PitchEvent strike(
      int midiNote, {
      double timestamp = 0,
      double volume = 1.0,
    }) => PitchEvent(
      frequency: 440,
      confidence: 1,
      midiNote: midiNote,
      timestamp: timestamp,
      volume: volume,
      struck: true,
    );

    test('allNotes preserves and sorts all simultaneous notes', () {
      final engine = StageEngine(level: chordLevel);
      addTearDown(engine.dispose);

      expect(engine.allNotes.map((n) => n.midiNote), [60, 64, 67, 62, 65, 69]);
      expect(engine.state.noteStates, List.filled(6, NoteState.upcoming));
    });

    test('matches all notes of a chord when played simultaneously', () {
      final engine = StageEngine(level: chordLevel);
      addTearDown(engine.dispose);
      engine.start();

      engine.processPitchEvent(strike(60));
      engine.processPitchEvent(strike(64));
      engine.processPitchEvent(strike(67));

      expect(engine.state.hitCount, 3);
      expect(engine.state.missCount, 0);
      expect(engine.state.perfectCount, 3);
      expect(engine.state.score, 300);
      expect(engine.state.accuracy, 1.0);
      expect(engine.state.noteStates.sublist(0, 3), [
        NoteState.hitPerfect,
        NoteState.hitPerfect,
        NoteState.hitPerfect,
      ]);
      expect(engine.state.noteStates.sublist(3), [
        NoteState.upcoming,
        NoteState.upcoming,
        NoteState.upcoming,
      ]);
    });

    test(
      'matches chord notes arriving in reverse pitch order (highest first)',
      () {
        final engine = StageEngine(level: chordLevel);
        addTearDown(engine.dispose);
        engine.start();

        engine.processPitchEvent(strike(67));
        engine.processPitchEvent(strike(64));
        engine.processPitchEvent(strike(60));

        expect(engine.state.hitCount, 3);
        expect(engine.state.score, 300);
        expect(engine.state.noteStates.sublist(0, 3), [
          NoteState.hitPerfect,
          NoteState.hitPerfect,
          NoteState.hitPerfect,
        ]);
      },
    );

    test('matches chord notes arriving scrambled (middle first)', () {
      final engine = StageEngine(level: chordLevel);
      addTearDown(engine.dispose);
      engine.start();

      engine.processPitchEvent(strike(64));
      engine.processPitchEvent(strike(67));
      engine.processPitchEvent(strike(60));

      expect(engine.state.hitCount, 3);
      expect(engine.state.score, 300);
    });

    test('scores chord notes independently across timing windows', () {
      final engine = StageEngine(level: chordLevel);
      addTearDown(engine.dispose);
      engine.start();

      // C4 lands on time (perfect: 0.0)
      engine.processPitchEvent(strike(60));
      // E4 lands slightly late at beat 0.15 (good: within 0.2 goodWindow)
      engine.seekToBeat(0.15);
      engine.processPitchEvent(strike(64));
      // G4 lands late at beat 0.28 (okay: within 0.3 okayWindow)
      engine.seekToBeat(0.28);
      engine.processPitchEvent(strike(67));

      expect(engine.state.noteStates[0], NoteState.hitPerfect);
      expect(engine.state.noteStates[1], NoteState.hitGood);
      expect(engine.state.noteStates[2], NoteState.hitOkay);
      expect(engine.state.perfectCount, 1);
      expect(engine.state.goodCount, 1);
      expect(engine.state.okayCount, 1);
      expect(engine.state.hitCount, 3);
      expect(engine.state.missCount, 0);
      expect(engine.state.score, 100 + 75 + 50); // 225
      expect(engine.state.accuracy, 1.0);
    });

    test(
      'partial chord hit marks unplayed notes as missed when window expires',
      () {
        final engine = StageEngine(level: chordLevel);
        addTearDown(engine.dispose);
        engine.start();

        // Play C4 and E4, but omit G4
        engine.processPitchEvent(strike(60));
        engine.processPitchEvent(strike(64));

        // Advance past missWindow (0.5 beats)
        engine.seekToBeat(0.6);

        expect(engine.state.noteStates[0], NoteState.hitPerfect);
        expect(engine.state.noteStates[1], NoteState.hitPerfect);
        expect(engine.state.noteStates[2], NoteState.missed);
        expect(engine.state.hitCount, 2);
        expect(engine.state.missCount, 1);
        expect(engine.state.score, 200);
        expect(engine.state.accuracy, closeTo(2 / 3, 0.001));
      },
    );

    test('consecutive chords score cleanly without cross-matching', () {
      final engine = StageEngine(level: chordLevel);
      addTearDown(engine.dispose);
      engine.start();

      // Hit first chord at beat 0
      engine.processPitchEvent(strike(60));
      engine.processPitchEvent(strike(64));
      engine.processPitchEvent(strike(67));

      // Advance to beat 4 and hit second chord
      engine.seekToBeat(4);
      engine.processPitchEvent(strike(62));
      engine.processPitchEvent(strike(65));
      engine.processPitchEvent(strike(69));

      expect(engine.state.hitCount, 6);
      expect(engine.state.missCount, 0);
      expect(engine.state.score, 600);
      expect(engine.state.accuracy, 1.0);
    });

    test(
      'repeated pitch across chords does not prematurely consume later chord note',
      () {
        const repeatedChordLevel = LevelModel(
          id: 'repeated-chord',
          title: 'Repeated Chord',
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
                  midiNote: 64,
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
                  midiNote: 60,
                  startBeat: 4,
                  durationBeats: 1,
                  measureIndex: 1,
                  beatIndex: 0,
                ),
                LevelNote(
                  midiNote: 67,
                  startBeat: 4,
                  durationBeats: 1,
                  measureIndex: 1,
                  beatIndex: 0,
                ),
              ],
            ),
          ],
        );

        final engine = StageEngine(level: repeatedChordLevel);
        addTearDown(engine.dispose);
        engine.start();

        // Hit chord 1 C4 at beat 0
        engine.processPitchEvent(strike(60));
        // Stray strike of C4 at beat 0.1 must not score chord 2 C4 at beat 4
        engine.seekToBeat(0.1);
        engine.processPitchEvent(strike(60, timestamp: 0.5));

        expect(engine.state.noteStates[0], NoteState.hitPerfect);
        expect(engine.state.noteStates[2], NoteState.upcoming);
        expect(engine.state.hitCount, 1);
      },
    );

    test('chord with varying note durations matches and scores each note', () {
      const mixedDurationChord = LevelModel(
        id: 'mixed-duration',
        title: 'Mixed Duration Chord',
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
                midiNote: 48,
                startBeat: 0,
                durationBeats: 2, // half note
                measureIndex: 0,
                beatIndex: 0,
              ),
              LevelNote(
                midiNote: 60,
                startBeat: 0,
                durationBeats: 1, // quarter note
                measureIndex: 0,
                beatIndex: 0,
              ),
              LevelNote(
                midiNote: 64,
                startBeat: 0,
                durationBeats: 0.5, // eighth note
                measureIndex: 0,
                beatIndex: 0,
              ),
            ],
          ),
        ],
      );

      final engine = StageEngine(level: mixedDurationChord);
      addTearDown(engine.dispose);
      engine.start();

      engine.processPitchEvent(strike(48));
      engine.processPitchEvent(strike(60));
      engine.processPitchEvent(strike(64));

      expect(engine.state.hitCount, 3);
      expect(engine.state.score, 300);
      expect(engine.state.accuracy, 1.0);
    });

    testWidgets(
      'polyphonic loop playback resets chord note states on loop restart',
      (tester) async {
        const fastChordLevel = LevelModel(
          id: 'fast-chord-level',
          title: '',
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
                LevelNote(
                  midiNote: 64,
                  startBeat: 0,
                  durationBeats: 1,
                  measureIndex: 0,
                  beatIndex: 0,
                ),
                LevelNote(
                  midiNote: 67,
                  startBeat: 0,
                  durationBeats: 1,
                  measureIndex: 0,
                  beatIndex: 0,
                ),
              ],
            ),
          ],
        );

        final engine = StageEngine(level: fastChordLevel);
        engine.playLoop(0, 2);
        engine.processPitchEvent(strike(60));
        engine.processPitchEvent(strike(64));
        engine.processPitchEvent(strike(67));

        expect(engine.state.noteStates[0], NoteState.hitPerfect);
        expect(engine.state.noteStates[1], NoteState.hitPerfect);
        expect(engine.state.noteStates[2], NoteState.hitPerfect);

        // Wait for loop wrap at beat 2 (200 ms at 600 BPM) and restart at beat 0
        await tester.pump(const Duration(milliseconds: 210));

        // Notes in the loop are reset to upcoming/active for the new pass
        expect(
          engine.state.noteStates[0],
          anyOf(NoteState.upcoming, NoteState.active),
        );
        expect(
          engine.state.noteStates[1],
          anyOf(NoteState.upcoming, NoteState.active),
        );
        expect(
          engine.state.noteStates[2],
          anyOf(NoteState.upcoming, NoteState.active),
        );

        // Re-striking scores in the new pass
        engine.processPitchEvent(strike(60));
        expect(engine.state.noteStates[0], NoteState.hitPerfect);
        engine.dispose();
      },
    );
  });
}
