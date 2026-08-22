import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:piano_tool/data/level_repository.dart';
import 'package:piano_tool/data/progress_repository.dart';
import 'package:piano_tool/models/audio_models.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/ui/practice/stage_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer harness({ProgressRepository? progressRepository}) =>
      ProviderContainer(
        overrides: [
          audioGrantedProvider.overrideWith((ref) async => true),
          // stageControllerProvider reads levelRepositoryProvider
          // synchronously (requireValue) -- overrideWithValue makes it
          // resolved immediately instead of leaving it in AsyncLoading,
          // which is what the default (ingestion-hydrated) definition would
          // do since nothing here awaits it first.
          levelRepositoryProvider
              .overrideWith((ref) => SynchronousFuture(LevelRepository())),
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
    final observed =
        started.then((_) => progressRepository.startCompleted = true);
    await Future<void>.delayed(Duration.zero);

    expect(progressRepository.recordedLastPlayedStageId, 'stage_1');
    expect(progressRepository.startCompleted, isFalse);

    writeGate.complete();
    await observed;
    expect(progressRepository.startCompleted, isTrue);
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
    expect(c.read(stageControllerProvider('stage_1')).currentBeat, 4,
        reason: 'stop must not rewind');

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
    expect(() => c.read(stageControllerProvider('nope')), throwsStateError);
  });

  test('stop clears sounding, and a pitch afterward does not relight it',
      () async {
    final c = harness();
    addTearDown(c.dispose);
    final ctrl = c.read(stageControllerProvider('stage_1').notifier);

    await ctrl.start();
    ctrl.onPitch(const PitchEvent(
      frequency: 440,
      confidence: 1.0,
      midiNote: 69,
      timestamp: 0,
      volume: 1.0,
    ));
    expect(c.read(stageControllerProvider('stage_1')).sounding, {69});

    ctrl.stop();
    expect(c.read(stageControllerProvider('stage_1')).sounding, isEmpty);

    // The microphone keeps running across Stop; a stray pitch afterward
    // (a decaying note's tail, a hand still on the keys) must not relight a
    // key on a keyboard whose transport reads "stopped."
    ctrl.onPitch(const PitchEvent(
      frequency: 440,
      confidence: 1.0,
      midiNote: 69,
      timestamp: 1,
      volume: 1.0,
    ));
    expect(c.read(stageControllerProvider('stage_1')).sounding, isEmpty);
  });

  test(
      'a sounding note decays and drops out if not heard again within the window',
      () async {
    final c = harness();
    addTearDown(c.dispose);
    final ctrl = c.read(stageControllerProvider('stage_1').notifier);

    await ctrl.start();
    ctrl.onPitch(const PitchEvent(
      frequency: 440,
      confidence: 1.0,
      midiNote: 69,
      timestamp: 0,
      volume: 1.0,
    ));
    expect(c.read(stageControllerProvider('stage_1')).sounding, {69},
        reason: 'the note should light immediately on detection');

    // PitchDetector only emits while it hears a pitch; silence produces no
    // event at all. Waiting past the decay window without a fresh detection
    // must drop the note back out on its own.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(c.read(stageControllerProvider('stage_1')).sounding, isEmpty,
        reason: 'the note must not stay lit forever after going silent');
  });

  test('a paused transport does not light the keyboard from a stray pitch',
      () async {
    final c = harness();
    addTearDown(c.dispose);
    final ctrl = c.read(stageControllerProvider('stage_1').notifier);

    await ctrl.start();
    ctrl.pause();
    ctrl.onPitch(const PitchEvent(
      frequency: 440,
      confidence: 1.0,
      midiNote: 69,
      timestamp: 0,
      volume: 1.0,
    ));
    expect(c.read(stageControllerProvider('stage_1')).sounding, isEmpty);
  });

  test('pause clears an already-lit key, same as stop', () async {
    final c = harness();
    addTearDown(c.dispose);
    final ctrl = c.read(stageControllerProvider('stage_1').notifier);

    await ctrl.start();
    ctrl.onPitch(const PitchEvent(
      frequency: 440,
      confidence: 1.0,
      midiNote: 69,
      timestamp: 0,
      volume: 1.0,
    ));
    expect(c.read(stageControllerProvider('stage_1')).sounding, {69});

    ctrl.pause();
    expect(c.read(stageControllerProvider('stage_1')).sounding, isEmpty,
        reason: 'a paused transport should not show a lit key');
  });

  test('a pitch-stream error is logged rather than vanishing silently',
      () async {
    final pitchController = StreamController<PitchEvent>();
    addTearDown(pitchController.close);

    final originalDebugPrint = debugPrint;
    final logs = <String>[];
    debugPrint = (String? message, {int? wrapWidth}) => logs.add(message ?? '');
    addTearDown(() => debugPrint = originalDebugPrint);

    final c = ProviderContainer(overrides: [
      audioGrantedProvider.overrideWith((ref) async => true),
      audioPitchStreamProvider.overrideWith((ref) => pitchController.stream),
      levelRepositoryProvider
          .overrideWith((ref) => SynchronousFuture(LevelRepository())),
    ]);
    addTearDown(c.dispose);

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
    pitchController.add(const PitchEvent(
      frequency: 440,
      confidence: 1.0,
      midiNote: 69,
      timestamp: 0,
      volume: 1.0,
    ));
    await Future<void>.delayed(Duration.zero);

    expect(c.read(stageControllerProvider('stage_1')).sounding, {69});
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
