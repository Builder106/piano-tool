import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:piano_tool/audio/tone_synthesizer.dart';
import 'package:piano_tool/data/level_repository.dart';
import 'package:piano_tool/data/progress_repository.dart';
import 'package:piano_tool/data/settings_repository.dart';
import 'package:piano_tool/models/audio_models.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/models/level_models.dart';
import 'package:piano_tool/services/midi_service.dart';
import 'package:piano_tool/practice/stage_controller.dart';

import '../services/fake_midi_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer harness({
    ProgressRepository? progressRepository,
    MidiService? midi,
    AudioSynthesizer? synth,
  }) => ProviderContainer(
    overrides: [
      audioGrantedProvider.overrideWith((ref) async => true),
      if (midi != null) midiServiceProvider.overrideWith((ref) => midi),
      if (synth != null) audioSynthesizerProvider.overrideWithValue(synth),
      // stageControllerProvider reads levelRepositoryProvider
      // synchronously (requireValue) -- overrideWithValue makes it
      // resolved immediately instead of leaving it in AsyncLoading,
      // which is what the default (ingestion-hydrated) definition would
      // do since nothing here awaits it first.
      levelRepositoryProvider.overrideWith(
        (ref) => SynchronousFuture(LevelRepository()),
      ),
      if (progressRepository != null)
        progressRepositoryProvider.overrideWithValue(progressRepository),
    ],
  );

  test('start awaits persistence of the last played stage', () async {
    final writeGate = Completer<void>();
    final progressRepository = _DelayedProgressRepository(writeGate);
    final c = harness(progressRepository: progressRepository);
    addTearDown(c.dispose);
    final ctrl = c.read(stageControllerProvider('stage_1').notifier);

    final started = ctrl.start();
    final observed = started.then(
      (_) => progressRepository.startCompleted = true,
    );
    await Future<void>.delayed(Duration.zero);

    expect(progressRepository.recordedLastPlayedStageId, 'stage_1');
    expect(progressRepository.startCompleted, isFalse);

    writeGate.complete();
    await observed;
    expect(progressRepository.startCompleted, isTrue);
  });

  // handleMidiBytes notifies listeners before it emits the pitch, which used
  // to rebuild the pitch stream provider and drop the very note that caused
  // the rebuild.
  test('a MIDI key press scores through the practice controller', () async {
    final midi = MidiService(transport: FakeMidiTransport(const []));
    final c = harness(midi: midi);
    addTearDown(c.dispose);
    // The practice screen watches the controller; an unwatched provider is
    // paused and would not hear the MIDI stream at all.
    c.listen(stageControllerProvider('stage_1'), (_, _) {});
    final ctrl = c.read(stageControllerProvider('stage_1').notifier);

    await ctrl.start();
    midi
      ..simulateNotePress(60)
      ..simulateNoteRelease(60);
    await pumpEventQueue();

    final s = c.read(stageControllerProvider('stage_1'));
    expect(s.score, greaterThan(0));
    expect(s.noteStates.first, isNot(NoteState.upcoming));
    expect(s.noteStates.first, isNot(NoteState.missed));
  });

  test('starts idle at beat zero with a real level', () {
    final c = harness();
    addTearDown(c.dispose);
    final s = c.read(stageControllerProvider('stage_1'));

    expect(s.currentBeat, 0);
    expect(s.score, 0);
    expect(s.status, StageEngineStatus.idle);
    expect(s.notes, isNotEmpty);
  });

  test('speed changes are held and clamped to the allowed range', () {
    final c = harness();
    addTearDown(c.dispose);
    final ctrl = c.read(stageControllerProvider('stage_1').notifier);

    ctrl.setSpeed(1.5);
    expect(c.read(stageControllerProvider('stage_1')).speed, 1.5);

    ctrl.setSpeed(9.0);
    expect(c.read(stageControllerProvider('stage_1')).speed, 2.0);

    ctrl.setSpeed(0.1);
    expect(c.read(stageControllerProvider('stage_1')).speed, 0.5);
  });

  test('stop holds position while replay returns to the start', () async {
    final c = harness();
    addTearDown(c.dispose);
    final ctrl = c.read(stageControllerProvider('stage_1').notifier);

    await ctrl.start();
    ctrl.seekTo(4);
    expect(c.read(stageControllerProvider('stage_1')).currentBeat, 4);

    ctrl.stop();
    expect(
      c.read(stageControllerProvider('stage_1')).currentBeat,
      4,
      reason: 'stop must not rewind',
    );

    ctrl.replay();
    expect(c.read(stageControllerProvider('stage_1')).currentBeat, 0);
  });

  test('a denied microphone surfaces as state, not silence', () async {
    final c = ProviderContainer(
      overrides: [audioGrantedProvider.overrideWith((ref) async => false)],
    );
    addTearDown(c.dispose);

    expect(await c.read(audioGrantedProvider.future), isFalse);
  });

  test('derived providers expose slices without the whole state', () {
    final c = harness();
    addTearDown(c.dispose);

    expect(c.read(currentBeatProvider('stage_1')), 0);
    expect(c.read(scoreProvider('stage_1')), 0);
    expect(c.read(engineStatusProvider('stage_1')), StageEngineStatus.idle);
  });

  test('an unknown stage id fails loudly', () {
    final c = harness();
    addTearDown(c.dispose);
    expect(
      () => c.read(stageControllerProvider('nope')),
      throwsA(isA<ProviderException>()),
    );
  });

  test(
    'stop clears sounding, and a pitch afterward does not relight it',
    () async {
      final c = harness();
      addTearDown(c.dispose);
      final ctrl = c.read(stageControllerProvider('stage_1').notifier);

      await ctrl.start();
      ctrl.onPitch(
        const PitchEvent(
          frequency: 440,
          confidence: 1.0,
          midiNote: 69,
          timestamp: 0,
          volume: 1.0,
        ),
      );
      expect(c.read(stageControllerProvider('stage_1')).sounding, {69});

      ctrl.stop();
      expect(c.read(stageControllerProvider('stage_1')).sounding, isEmpty);

      // The microphone keeps running across Stop; a stray pitch afterward
      // (a decaying note's tail, a hand still on the keys) must not relight a
      // key on a keyboard whose transport reads "stopped."
      ctrl.onPitch(
        const PitchEvent(
          frequency: 440,
          confidence: 1.0,
          midiNote: 69,
          timestamp: 1,
          volume: 1.0,
        ),
      );
      expect(c.read(stageControllerProvider('stage_1')).sounding, isEmpty);
    },
  );

  test(
    'a sounding note decays and drops out if not heard again within the window',
    () async {
      final c = harness();
      addTearDown(c.dispose);
      final ctrl = c.read(stageControllerProvider('stage_1').notifier);

      await ctrl.start();
      ctrl.onPitch(
        const PitchEvent(
          frequency: 440,
          confidence: 1.0,
          midiNote: 69,
          timestamp: 0,
          volume: 1.0,
        ),
      );
      expect(c.read(stageControllerProvider('stage_1')).sounding, {
        69,
      }, reason: 'the note should light immediately on detection');

      // PitchDetector only emits while it hears a pitch; silence produces no
      // event at all. Waiting past the decay window without a fresh detection
      // must drop the note back out on its own.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(
        c.read(stageControllerProvider('stage_1')).sounding,
        isEmpty,
        reason: 'the note must not stay lit forever after going silent',
      );
    },
  );

  test(
    'a paused transport does not light the keyboard from a stray pitch',
    () async {
      final c = harness();
      addTearDown(c.dispose);
      final ctrl = c.read(stageControllerProvider('stage_1').notifier);

      await ctrl.start();
      ctrl.pause();
      ctrl.onPitch(
        const PitchEvent(
          frequency: 440,
          confidence: 1.0,
          midiNote: 69,
          timestamp: 0,
          volume: 1.0,
        ),
      );
      expect(c.read(stageControllerProvider('stage_1')).sounding, isEmpty);
    },
  );

  test('pause clears an already-lit key, same as stop', () async {
    final c = harness();
    addTearDown(c.dispose);
    final ctrl = c.read(stageControllerProvider('stage_1').notifier);

    await ctrl.start();
    ctrl.onPitch(
      const PitchEvent(
        frequency: 440,
        confidence: 1.0,
        midiNote: 69,
        timestamp: 0,
        volume: 1.0,
      ),
    );
    expect(c.read(stageControllerProvider('stage_1')).sounding, {69});

    ctrl.pause();
    expect(
      c.read(stageControllerProvider('stage_1')).sounding,
      isEmpty,
      reason: 'a paused transport should not show a lit key',
    );
  });

  test(
    'a pitch-stream error is logged rather than vanishing silently',
    () async {
      final pitchController = StreamController<PitchEvent>();
      addTearDown(pitchController.close);

      final originalDebugPrint = debugPrint;
      final logs = <String>[];
      debugPrint = (String? message, {int? wrapWidth}) =>
          logs.add(message ?? '');
      addTearDown(() => debugPrint = originalDebugPrint);

      final c = ProviderContainer(
        overrides: [
          audioGrantedProvider.overrideWith((ref) async => true),
          audioPitchStreamProvider.overrideWith(
            (ref) => pitchController.stream,
          ),
          levelRepositoryProvider.overrideWith(
            (ref) => SynchronousFuture(LevelRepository()),
          ),
        ],
      );
      addTearDown(c.dispose);
      final stageSubscription = c.listen(
        stageControllerProvider('stage_1'),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(stageSubscription.close);

      final ctrl = c.read(stageControllerProvider('stage_1').notifier);
      await ctrl.start();

      pitchController.addError(Exception('device disconnected'));
      await Future<void>.delayed(Duration.zero);

      expect(
        logs.any((line) => line.contains('audioPitchStreamProvider error')),
        isTrue,
        reason: 'the old code (next.whenData) dropped this with no log at all',
      );

      // The listener is still attached afterward: a real event that follows
      // the error still reaches the controller and lights the keyboard, so one
      // bad event does not wedge the stream for the rest of the session.
      pitchController.add(
        const PitchEvent(
          frequency: 440,
          confidence: 1.0,
          midiNote: 69,
          timestamp: 0,
          volume: 1.0,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(c.read(stageControllerProvider('stage_1')).sounding, {69});
    },
  );

  test(
    'a stage requiring MIDI ignores microphone frames and accepts MIDI',
    () async {
      final repo = LevelRepository();
      const chordLevel = LevelModel(
        id: 'poly_level',
        title: 'Polyphonic Lesson',
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
            ],
          ),
        ],
      );
      repo.addImportedLevel(chordLevel);

      final micController = StreamController<PitchEvent>();
      addTearDown(micController.close);
      final midi = MidiService(transport: FakeMidiTransport(const []));

      final c = ProviderContainer(
        overrides: [
          audioGrantedProvider.overrideWith((ref) async => true),
          audioPitchStreamProvider.overrideWith((ref) => micController.stream),
          midiServiceProvider.overrideWith((ref) => midi),
          levelRepositoryProvider.overrideWith(
            (ref) => SynchronousFuture(repo),
          ),
        ],
      );
      addTearDown(c.dispose);

      const stageId = 'imported_poly_level';
      c.listen(stageControllerProvider(stageId), (_, _) {});
      final ctrl = c.read(stageControllerProvider(stageId).notifier);
      await ctrl.start();

      // 1. Microphone frame arrives - should be ignored because effectiveRequiresMidi is true
      micController.add(
        const PitchEvent(
          frequency: 261.63,
          confidence: 1.0,
          midiNote: 60,
          timestamp: 0,
          volume: 1.0,
        ),
      );
      await pumpEventQueue();

      final stateAfterMic = c.read(stageControllerProvider(stageId));
      expect(stateAfterMic.score, 0);
      expect(stateAfterMic.noteStates[0], NoteState.upcoming);

      // 2. MIDI event arrives - should be processed and score the note
      midi
        ..simulateNotePress(60)
        ..simulateNoteRelease(60);
      await pumpEventQueue();

      final stateAfterMidi = c.read(stageControllerProvider(stageId));
      expect(stateAfterMidi.score, greaterThan(0));
      expect(stateAfterMidi.noteStates[0], NoteState.hitPerfect);
    },
  );

  test(
    'loopRange sets loop range, updates engine, and stopLoop clears it',
    () async {
      final c = harness();
      addTearDown(c.dispose);
      final ctrl = c.read(stageControllerProvider('stage_1').notifier);
      await ctrl.start();

      ctrl.loopRange(0, 1);
      final stateWithRange = c.read(stageControllerProvider('stage_1'));
      expect(stateWithRange.loopRange, (0, 1));
      expect(stateWithRange.loopMeasure, 0);

      ctrl.stopLoop();
      final stateAfterStop = c.read(stageControllerProvider('stage_1'));
      expect(stateAfterStop.loopRange, isNull);
      expect(stateAfterStop.loopMeasure, isNull);
    },
  );

  test('loopBar sets single bar range', () async {
    final c = harness();
    addTearDown(c.dispose);
    final ctrl = c.read(stageControllerProvider('stage_1').notifier);
    await ctrl.start();

    ctrl.loopBar(2);
    final s = c.read(stageControllerProvider('stage_1'));
    expect(s.loopRange, (2, 2));
    expect(s.loopMeasure, 2);
  });

  test(
    'demonstratePhrase plays phrase notes through the synthesizer and suspends microphone scoring',
    () async {
      final player = SilentAudioTonePlayer();
      final synth = AudioSynthesizer(player: player);
      final c = harness(synth: synth);
      addTearDown(c.dispose);
      final ctrl = c.read(stageControllerProvider('stage_1').notifier);

      // Initial state: not demonstrating, microphone scoring active
      expect(ctrl.isDemonstrating, isFalse);
      expect(ctrl.isMicrophoneSuspended, isFalse);
      expect(ctrl.isMicrophoneScoringActive, isTrue);

      // Start demonstration of measure 0
      await ctrl.demonstratePhrase(startMeasure: 0, endMeasure: 0);

      final demonstratingState = c.read(stageControllerProvider('stage_1'));
      expect(demonstratingState.isDemonstrating, isTrue);
      expect(demonstratingState.isMicrophoneSuspended, isTrue);
      expect(demonstratingState.isMicrophoneScoringActive, isFalse);
      expect(ctrl.isMicrophoneScoringActive, isFalse);

      // Note at beat 0 was played by the synthesizer into the tone player
      expect(player.playCount, greaterThan(0));

      // Pitch events received from microphone while demonstrating must not score
      ctrl.onPitch(
        const PitchEvent(
          frequency: 261.63,
          confidence: 1.0,
          midiNote: 60,
          timestamp: 0.0,
          volume: 0.9,
          struck: true,
        ),
      );

      // Score remains 0 -- audio playback cannot score itself!
      final stateAfterPitch = c.read(stageControllerProvider('stage_1'));
      expect(stateAfterPitch.score, 0);
      expect(stateAfterPitch.noteStates.first, isNot(NoteState.hitPerfect));

      // Stop demonstration
      ctrl.stopDemonstration();

      final restoredState = c.read(stageControllerProvider('stage_1'));
      expect(restoredState.isDemonstrating, isFalse);
      expect(restoredState.isMicrophoneSuspended, isFalse);
      expect(restoredState.isMicrophoneScoringActive, isTrue);
      expect(ctrl.isMicrophoneScoringActive, isTrue);
    },
  );

  test(
    'stopDemonstration restores the learner selected input and halts synthesizer',
    () async {
      final player = SilentAudioTonePlayer();
      final synth = AudioSynthesizer(player: player);
      final c = harness(synth: synth);
      addTearDown(c.dispose);
      final ctrl = c.read(stageControllerProvider('stage_1').notifier);

      await ctrl.demonstratePhrase(startMeasure: 0, endMeasure: 1);
      expect(ctrl.isDemonstrating, isTrue);
      expect(ctrl.isMicrophoneSuspended, isTrue);

      ctrl.stopDemonstration();

      final s = c.read(stageControllerProvider('stage_1'));
      expect(s.isDemonstrating, isFalse);
      expect(s.isMicrophoneSuspended, isFalse);
      expect(s.effectiveInputSource, PracticeInputSource.both);
    },
  );

  test(
    'demonstratePhrase respects active loopRange when no measure arguments are passed',
    () async {
      final player = SilentAudioTonePlayer();
      final synth = AudioSynthesizer(player: player);
      final c = harness(synth: synth);
      addTearDown(c.dispose);
      final ctrl = c.read(stageControllerProvider('stage_1').notifier);

      ctrl.loopRange(1, 1);
      expect(c.read(stageControllerProvider('stage_1')).loopRange, (1, 1));

      await ctrl.demonstratePhrase();

      expect(ctrl.isDemonstrating, isTrue);
      expect(ctrl.isMicrophoneSuspended, isTrue);

      ctrl.stopDemonstration();
      expect(c.read(stageControllerProvider('stage_1')).loopRange, (1, 1));
      expect(ctrl.isDemonstrating, isFalse);
      expect(ctrl.isMicrophoneSuspended, isFalse);
    },
  );

  group('practice modes and accessibility in StageController', () {
    test('defaults to timed mode with corresponding state and description', () {
      final c = harness();
      addTearDown(c.dispose);
      final s = c.read(stageControllerProvider('stage_1'));

      expect(s.practiceMode, PracticeMode.timed);
      expect(s.isTimedMode, isTrue);
      expect(s.isWaitingMode, isFalse);
      expect(s.waitingHint, isNull);
      expect(s.accessibleDescription, contains('Timed mode: Ready.'));
      expect(s.accessibleDescription, contains('Score: 0, accuracy: 0%'));
    });

    test('setPracticeMode and togglePracticeMode update controller and state', () {
      final c = harness();
      addTearDown(c.dispose);
      final ctrl = c.read(stageControllerProvider('stage_1').notifier);

      ctrl.setPracticeMode(PracticeMode.waiting);
      var s = c.read(stageControllerProvider('stage_1'));
      expect(s.practiceMode, PracticeMode.waiting);
      expect(s.isWaitingMode, isTrue);
      expect(ctrl.practiceMode, PracticeMode.waiting);

      ctrl.togglePracticeMode();
      s = c.read(stageControllerProvider('stage_1'));
      expect(s.practiceMode, PracticeMode.timed);
      expect(s.isTimedMode, isTrue);

      ctrl.togglePracticeMode();
      s = c.read(stageControllerProvider('stage_1'));
      expect(s.practiceMode, PracticeMode.waiting);
    });

    test('waiting mode provides contextual hints and accessible descriptions during practice', () async {
      final c = harness();
      addTearDown(c.dispose);
      final ctrl = c.read(stageControllerProvider('stage_1').notifier);

      ctrl.setPracticeMode(PracticeMode.waiting);
      await ctrl.start();

      final s = c.read(stageControllerProvider('stage_1'));
      expect(s.status, StageEngineStatus.playing);
      expect(s.waitingHint, isNotNull);
      expect(s.waitingHint!.hintText, contains('Play'));
      expect(s.accessibleDescription, contains('Waiting mode: Playing.'));
      expect(s.accessibleDescription, contains(s.waitingHint!.hintText));
      expect(s.score, 0);

      // Strike a wrong note (e.g. MIDI 62 if stage 1 starts on 60)
      final expectedMidi = s.waitingHint!.targetMidiNotes.first;
      final wrongMidi = expectedMidi + 2;

      ctrl.onPitch(
        PitchEvent(
          frequency: 300.0,
          confidence: 0.9,
          midiNote: wrongMidi,
          timestamp: 0.0,
          volume: 0.8,
          struck: true,
        ),
      );

      final wrongState = c.read(stageControllerProvider('stage_1'));
      expect(wrongState.waitingHint!.heardWrongMidiNote, wrongMidi);
      expect(wrongState.accessibleDescription, contains('Heard'));
      expect(wrongState.accessibleDescription, contains('Waiting for'));
      expect(wrongState.score, 0);

      // Now strike the correct expected note
      ctrl.onPitch(
        PitchEvent(
          frequency: 261.63,
          confidence: 0.9,
          midiNote: expectedMidi,
          timestamp: 0.1,
          volume: 0.8,
          struck: true,
        ),
      );

      final hitState = c.read(stageControllerProvider('stage_1'));
      // Hit count incremented, score remains 0 ("without awarding a timed score")
      expect(hitState.score, 0);
      expect(hitState.waitingHint!.heardWrongMidiNote, isNull);
    });

    test('practiceModeProvider, waitingHintProvider, and accessibleDescriptionProvider update reactively', () async {
      final c = harness();
      addTearDown(c.dispose);
      final ctrl = c.read(stageControllerProvider('stage_1').notifier);

      expect(c.read(practiceModeProvider('stage_1')), PracticeMode.timed);
      expect(c.read(waitingHintProvider('stage_1')), isNull);
      expect(
        c.read(accessibleDescriptionProvider('stage_1')),
        contains('Timed mode'),
      );

      ctrl.setPracticeMode(PracticeMode.waiting);
      await ctrl.start();

      expect(c.read(practiceModeProvider('stage_1')), PracticeMode.waiting);
      expect(c.read(waitingHintProvider('stage_1')), isNotNull);
      expect(
        c.read(accessibleDescriptionProvider('stage_1')),
        contains('Waiting mode'),
      );
    });
  });

  group('metronome, count-in, and effective BPM', () {
    test('toggles metronome and count-in and synchronizes StageUiState', () {
      final c = harness();
      addTearDown(c.dispose);
      final ctrl = c.read(stageControllerProvider('stage_1').notifier);

      expect(ctrl.isMetronomeEnabled, isFalse);
      expect(c.read(stageControllerProvider('stage_1')).isMetronomeEnabled, isFalse);

      ctrl.setMetronome(true);
      expect(ctrl.isMetronomeEnabled, isTrue);
      expect(c.read(stageControllerProvider('stage_1')).isMetronomeEnabled, isTrue);

      ctrl.toggleMetronome();
      expect(ctrl.isMetronomeEnabled, isFalse);
      expect(c.read(stageControllerProvider('stage_1')).isMetronomeEnabled, isFalse);

      expect(ctrl.isCountInEnabled, isFalse);
      expect(c.read(stageControllerProvider('stage_1')).isCountInEnabled, isFalse);

      ctrl.setCountIn(true);
      expect(ctrl.isCountInEnabled, isTrue);
      expect(c.read(stageControllerProvider('stage_1')).isCountInEnabled, isTrue);

      ctrl.toggleCountIn();
      expect(ctrl.isCountInEnabled, isFalse);
      expect(c.read(stageControllerProvider('stage_1')).isCountInEnabled, isFalse);
    });

    test('effective BPM, effective tempo, and speed multiplier label reflect tempo and speed', () {
      final c = harness();
      addTearDown(c.dispose);
      final ctrl = c.read(stageControllerProvider('stage_1').notifier);

      final state = c.read(stageControllerProvider('stage_1'));
      final baseTempo = state.level.tempo;

      expect(state.effectiveBpm, baseTempo);
      expect(state.effectiveTempo, baseTempo.toDouble());
      expect(
        state.speedMultiplierLabel,
        'Speed 100% ($baseTempo BPM)',
      );
      expect(
        state.accessibleDescription,
        contains('Speed 100% ($baseTempo BPM)'),
      );

      ctrl.setSpeed(0.75);
      final state75 = c.read(stageControllerProvider('stage_1'));
      final expectedBpm75 = (baseTempo * 0.75).round();
      expect(state75.effectiveBpm, expectedBpm75);
      expect(
        state75.speedMultiplierLabel,
        'Speed 75% ($expectedBpm75 BPM)',
      );
      expect(
        state75.accessibleDescription,
        contains('Speed 75% ($expectedBpm75 BPM)'),
      );
    });

    test('count-in suspends microphone scoring and describes count-in state', () async {
      final player = SilentAudioTonePlayer();
      final synth = AudioSynthesizer(player: player);
      final c = harness(synth: synth);
      addTearDown(c.dispose);
      final ctrl = c.read(stageControllerProvider('stage_1').notifier);

      ctrl.setCountIn(true);
      await ctrl.start();

      final state = c.read(stageControllerProvider('stage_1'));
      expect(state.isCountingIn, isTrue);
      expect(ctrl.isCountingIn, isTrue);
      expect(ctrl.isMicrophoneScoringActive, isFalse);
      expect(state.countInBeat, 1);
      expect(state.countInTotalBeats, state.level.beatsPerMeasure);
      expect(
        state.accessibleDescription,
        contains('Count-in: Beat 1 of ${state.level.beatsPerMeasure}'),
      );
      expect(
        state.accessibleDescription,
        contains('BPM)'),
      );
    });

    test('sounds metronome click through AudioSynthesizer on beat events', () async {
      final player = SilentAudioTonePlayer();
      final synth = AudioSynthesizer(player: player);
      final c = harness(synth: synth);
      addTearDown(c.dispose);

      final ctrl = c.read(stageControllerProvider('stage_1').notifier);
      ctrl.setMetronome(true);

      expect(player.playCount, 0);
      await ctrl.start();

      // On start with metronome enabled, downbeat beat event triggers a click
      await Future<void>.delayed(Duration.zero);
      expect(player.playCount, greaterThanOrEqualTo(1));
    });

    test('derived providers reactively expose metronome, count-in, and effective BPM slices', () async {
      final player = SilentAudioTonePlayer();
      final synth = AudioSynthesizer(player: player);
      final c = harness(synth: synth);
      addTearDown(c.dispose);
      final ctrl = c.read(stageControllerProvider('stage_1').notifier);

      final baseTempo = c.read(stageControllerProvider('stage_1')).level.tempo;
      expect(c.read(effectiveBpmProvider('stage_1')), baseTempo);
      expect(c.read(isMetronomeEnabledProvider('stage_1')), isFalse);
      expect(c.read(isCountInEnabledProvider('stage_1')), isFalse);
      expect(c.read(isCountingInProvider('stage_1')), isFalse);
      expect(c.read(countInBeatProvider('stage_1')), isNull);

      ctrl.setMetronome(true);
      ctrl.setCountIn(true);
      ctrl.setSpeed(0.5);

      expect(c.read(isMetronomeEnabledProvider('stage_1')), isTrue);
      expect(c.read(isCountInEnabledProvider('stage_1')), isTrue);
      expect(c.read(effectiveBpmProvider('stage_1')), (baseTempo * 0.5).round());

      await ctrl.start();
      expect(c.read(isCountingInProvider('stage_1')), isTrue);
      expect(c.read(countInBeatProvider('stage_1')), 1);
    });
  });
}

class _DelayedProgressRepository extends ProgressRepository {
  _DelayedProgressRepository(this._writeGate);

  final Completer<void> _writeGate;
  String? recordedLastPlayedStageId;
  bool startCompleted = false;

  @override
  Future<void> setLastPlayed(String stageId) async {
    recordedLastPlayedStageId = stageId;
    await _writeGate.future;
  }
}
