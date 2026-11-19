import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/audio/tone_synthesizer.dart';
import 'package:piano_tool/engine/meter_grouping.dart';
import 'package:piano_tool/engine/stage_engine.dart';
import 'package:piano_tool/models/audio_models.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/models/level_models.dart';

const _level44 = LevelModel(
  id: 'test_44',
  title: 'Test 4/4',
  description: '',
  tempo: 120,
  beatsPerMeasure: 4,
  beatUnit: 4,
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

const _level68 = LevelModel(
  id: 'test_68',
  title: 'Test 6/8',
  description: '',
  tempo: 90,
  beatsPerMeasure: 6,
  beatUnit: 8,
  totalMeasures: 2,
  measures: [
    LevelMeasure(
      index: 0,
      startBeat: 0,
      beatsPerMeasure: 6,
      notes: [
        LevelNote(
          midiNote: 60,
          startBeat: 0,
          durationBeats: 3,
          measureIndex: 0,
          beatIndex: 0,
        ),
        LevelNote(
          midiNote: 64,
          startBeat: 3,
          durationBeats: 3,
          measureIndex: 0,
          beatIndex: 3,
        ),
      ],
    ),
    LevelMeasure(
      index: 1,
      startBeat: 6,
      beatsPerMeasure: 6,
      notes: [
        LevelNote(
          midiNote: 67,
          startBeat: 6,
          durationBeats: 6,
          measureIndex: 1,
          beatIndex: 0,
        ),
      ],
    ),
  ],
);

void main() {
  group('MeterGrouping', () {
    test('identifies simple meters and classifies downbeat vs regular', () {
      expect(MeterGrouping.isCompound(4, 4), isFalse);
      expect(MeterGrouping.is68Meter(4, 4), isFalse);
      expect(
        MeterGrouping.beatType(
          beatsPerMeasure: 4,
          beatUnit: 4,
          beatInMeasure: 0,
        ),
        MetronomeBeatType.downbeat,
      );
      expect(
        MeterGrouping.beatType(
          beatsPerMeasure: 4,
          beatUnit: 4,
          beatInMeasure: 1,
        ),
        MetronomeBeatType.regular,
      );
      expect(
        MeterGrouping.beatType(
          beatsPerMeasure: 4,
          beatUnit: 4,
          beatInMeasure: 2,
        ),
        MetronomeBeatType.regular,
      );
      expect(
        MeterGrouping.beatType(
          beatsPerMeasure: 4,
          beatUnit: 4,
          beatInMeasure: 3,
        ),
        MetronomeBeatType.regular,
      );
    });

    test(
      'identifies 6/8 compound meter and groups into 2 pulses with subdivisions',
      () {
        expect(MeterGrouping.isCompound(6, 8), isTrue);
        expect(MeterGrouping.is68Meter(6, 8), isTrue);

        // Pulse 1 (Downbeat at beat 0 / eighth note 1)
        expect(
          MeterGrouping.beatType(
            beatsPerMeasure: 6,
            beatUnit: 8,
            beatInMeasure: 0,
          ),
          MetronomeBeatType.downbeat,
        );
        // Eighth notes 2 & 3 (subdivisions)
        expect(
          MeterGrouping.beatType(
            beatsPerMeasure: 6,
            beatUnit: 8,
            beatInMeasure: 1,
          ),
          MetronomeBeatType.subdivision,
        );
        expect(
          MeterGrouping.beatType(
            beatsPerMeasure: 6,
            beatUnit: 8,
            beatInMeasure: 2,
          ),
          MetronomeBeatType.subdivision,
        );
        // Pulse 2 (Secondary accent at beat 3 / eighth note 4)
        expect(
          MeterGrouping.beatType(
            beatsPerMeasure: 6,
            beatUnit: 8,
            beatInMeasure: 3,
          ),
          MetronomeBeatType.secondaryAccent,
        );
        // Eighth notes 5 & 6 (subdivisions)
        expect(
          MeterGrouping.beatType(
            beatsPerMeasure: 6,
            beatUnit: 8,
            beatInMeasure: 4,
          ),
          MetronomeBeatType.subdivision,
        );
        expect(
          MeterGrouping.beatType(
            beatsPerMeasure: 6,
            beatUnit: 8,
            beatInMeasure: 5,
          ),
          MetronomeBeatType.subdivision,
        );
      },
    );

    test(
      'handles 9/8 and 12/8 compound meters with secondary accents every 3 beats',
      () {
        expect(MeterGrouping.isCompound(9, 8), isTrue);
        expect(
          MeterGrouping.beatType(
            beatsPerMeasure: 9,
            beatUnit: 8,
            beatInMeasure: 0,
          ),
          MetronomeBeatType.downbeat,
        );
        expect(
          MeterGrouping.beatType(
            beatsPerMeasure: 9,
            beatUnit: 8,
            beatInMeasure: 3,
          ),
          MetronomeBeatType.secondaryAccent,
        );
        expect(
          MeterGrouping.beatType(
            beatsPerMeasure: 9,
            beatUnit: 8,
            beatInMeasure: 6,
          ),
          MetronomeBeatType.secondaryAccent,
        );
        expect(
          MeterGrouping.beatType(
            beatsPerMeasure: 9,
            beatUnit: 8,
            beatInMeasure: 1,
          ),
          MetronomeBeatType.subdivision,
        );
      },
    );
  });

  group('ToneGenerator & AudioSynthesizer Metronome', () {
    test(
      'ToneGenerator generates non-empty PCM WAV click buffers for all beat types',
      () {
        for (final type in MetronomeBeatType.values) {
          final wav = ToneGenerator.generateMetronomeClickWav(type: type);
          expect(wav.length, greaterThan(44)); // WAV header + PCM data
          // Check RIFF header magic
          expect(wav.sublist(0, 4), [0x52, 0x49, 0x46, 0x46]); // RIFF
          expect(wav.sublist(8, 12), [0x57, 0x41, 0x56, 0x45]); // WAVE
        }
      },
    );

    test('AudioSynthesizer plays metronome clicks and respects mute', () async {
      final player = SilentAudioTonePlayer();
      final synth = AudioSynthesizer(player: player);

      await synth.playMetronomeClick(type: MetronomeBeatType.downbeat);
      expect(player.playCount, 1);
      expect(player.playedBuffers.length, 1);

      await synth.playMetronomeClick(type: MetronomeBeatType.secondaryAccent);
      expect(player.playCount, 2);

      synth.isMuted = true;
      await synth.playMetronomeClick(type: MetronomeBeatType.regular);
      expect(player.playCount, 2); // No new click played while muted

      synth.isMuted = false;
      await synth.playMetronomeClick(type: MetronomeBeatType.regular);
      expect(player.playCount, 3);
    });
  });

  group('StageEngine Metronome & Effective BPM', () {
    test('calculates effective BPM according to tempo and playback speed', () {
      final engine = StageEngine(level: _level44);
      expect(engine.effectiveBpm, 120.0);

      engine.setPlaybackSpeed(0.75);
      expect(engine.effectiveBpm, 90.0);

      engine.setPlaybackSpeed(0.5);
      expect(engine.effectiveBpm, 60.0);

      engine.setPlaybackSpeed(1.5);
      expect(engine.effectiveBpm, 180.0);
    });

    test(
      'emits beat events with appropriate 6/8 meter grouping during playback',
      () async {
        final fast68 = _level68.copyWith(tempo: 1200);
        final engine = StageEngine(
          level: fast68,
          config: const StageEngineConfig(metronomeEnabled: true),
        );
        addTearDown(engine.dispose);

        final beats =
            <({double beat, MetronomeBeatType type, bool isCountIn})>[];
        engine.onBeat = (beat, type, isCountIn) {
          beats.add((beat: beat, type: type, isCountIn: isCountIn));
        };

        engine.start();
        expect(beats.isNotEmpty, isTrue);
        expect(beats.first.beat, 0.0);
        expect(beats.first.type, MetronomeBeatType.downbeat);
        expect(beats.first.isCountIn, isFalse);

        // Wait for playback timer to advance across measure 0 (6 beats at 1200 BPM takes ~300ms)
        await Future<void>.delayed(const Duration(milliseconds: 350));

        expect(beats.length, greaterThanOrEqualTo(6));
        expect(beats[0].type, MetronomeBeatType.downbeat);
        expect(beats[1].type, MetronomeBeatType.subdivision);
        expect(beats[2].type, MetronomeBeatType.subdivision);
        expect(beats[3].type, MetronomeBeatType.secondaryAccent);
        expect(beats[4].type, MetronomeBeatType.subdivision);
        expect(beats[5].type, MetronomeBeatType.subdivision);

        engine.stop();
      },
    );

    test('metronome toggle can be enabled and disabled dynamically', () {
      final engine = StageEngine(level: _level44);
      expect(engine.isMetronomeEnabled, isFalse);

      engine.setMetronomeEnabled(true);
      expect(engine.isMetronomeEnabled, isTrue);

      engine.setMetronomeEnabled(false);
      expect(engine.isMetronomeEnabled, isFalse);
    });
  });

  group('StageEngine Count-In', () {
    test(
      'count-in starts 1 full measure before beat 0 with negative beats and downbeat',
      () {
        final engine = StageEngine(
          level: _level44,
          config: const StageEngineConfig(countInEnabled: true),
        );

        final beats =
            <({double beat, MetronomeBeatType type, bool isCountIn})>[];
        engine.onBeat = (beat, type, isCountIn) {
          beats.add((beat: beat, type: type, isCountIn: isCountIn));
        };

        engine.start();

        expect(engine.isCountingIn, isTrue);
        expect(engine.state.currentBeat, -4.0);
        expect(engine.countInBeat, 1);
        expect(engine.countInTotalBeats, 4);

        expect(beats.length, 1);
        expect(beats.first.beat, -4.0);
        expect(beats.first.type, MetronomeBeatType.downbeat);
        expect(beats.first.isCountIn, isTrue);

        engine.stop();
      },
    );

    test('count-in in 6/8 meter has 6 count-in beats with compound pulses', () {
      final engine = StageEngine(
        level: _level68,
        config: const StageEngineConfig(countInEnabled: true),
      );

      final beats = <({double beat, MetronomeBeatType type, bool isCountIn})>[];
      engine.onBeat = (beat, type, isCountIn) {
        beats.add((beat: beat, type: type, isCountIn: isCountIn));
      };

      engine.start();

      expect(engine.isCountingIn, isTrue);
      expect(engine.state.currentBeat, -6.0);
      expect(engine.countInBeat, 1);
      expect(engine.countInTotalBeats, 6);
      expect(beats.first.type, MetronomeBeatType.downbeat);

      engine.stop();
    });

    test(
      'pitch events during count-in are ignored and do not score or cause misses',
      () {
        final engine = StageEngine(
          level: _level44,
          config: const StageEngineConfig(countInEnabled: true),
        );

        engine.start();
        expect(engine.isCountingIn, isTrue);

        // Player strikes a note during count-in
        engine.processPitchEvent(
          const PitchEvent(
            frequency: 261.63,
            confidence: 1.0,
            midiNote: 60,
            timestamp: 0,
            volume: 1.0,
          ),
        );

        // Score remains 0, hit count remains 0, note 0 remains upcoming
        expect(engine.state.score, 0);
        expect(engine.state.hitCount, 0);
        expect(engine.state.missCount, 0);
        expect(engine.state.noteStates[0], NoteState.upcoming);

        engine.stop();
      },
    );

    test('seeking past 0 ends count-in and synchronizes playhead', () {
      final engine = StageEngine(
        level: _level44,
        config: const StageEngineConfig(countInEnabled: true),
      );

      engine.start();
      expect(engine.isCountingIn, isTrue);

      engine.seekToBeat(2.0);
      expect(engine.isCountingIn, isFalse);
      expect(engine.state.currentBeat, 2.0);
      expect(engine.countInBeat, isNull);

      engine.stop();
    });
  });
}
