import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/data/level_repository.dart';
import 'package:piano_tool/models/audio_models.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/models/level_models.dart';
import 'package:piano_tool/practice/stage_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

LevelModel _fourMeasureLevel() => const LevelModel(
  id: 'four_bar_stage',
  title: 'Four Bar Stage',
  description: 'Stage for testing assistance',
  tempo: 1200, // fast tempo for instant test execution
  beatsPerMeasure: 1,
  totalMeasures: 4,
  measures: [
    LevelMeasure(
      index: 0,
      startBeat: 0,
      beatsPerMeasure: 1,
      notes: [
        LevelNote(
          midiNote: 60,
          startBeat: 0,
          durationBeats: 0.5,
          measureIndex: 0,
          beatIndex: 0,
        ),
      ],
    ),
    LevelMeasure(
      index: 1,
      startBeat: 1,
      beatsPerMeasure: 1,
      notes: [
        LevelNote(
          midiNote: 64,
          startBeat: 1,
          durationBeats: 0.5,
          measureIndex: 1,
          beatIndex: 0,
        ),
      ],
    ),
    LevelMeasure(
      index: 2,
      startBeat: 2,
      beatsPerMeasure: 1,
      notes: [
        LevelNote(
          midiNote: 67,
          startBeat: 2,
          durationBeats: 0.5,
          measureIndex: 2,
          beatIndex: 0,
        ),
      ],
    ),
    LevelMeasure(
      index: 3,
      startBeat: 3,
      beatsPerMeasure: 1,
      notes: [
        LevelNote(
          midiNote: 72,
          startBeat: 3,
          durationBeats: 0.5,
          measureIndex: 3,
          beatIndex: 0,
        ),
      ],
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const stageId = 'imported_four_bar_stage';

  ProviderContainer createHarness(LevelRepository repo) => ProviderContainer(
    overrides: [
      audioGrantedProvider.overrideWith((ref) async => true),
      levelRepositoryProvider.overrideWith((ref) => SynchronousFuture(repo)),
    ],
  );

  group('StageController assistance after difficulty', () {
    test('initial state has no assistance offer or active assistance', () {
      final repo = LevelRepository()..addImportedLevel(_fourMeasureLevel());
      final c = createHarness(repo);
      addTearDown(c.dispose);

      final ctrl = c.read(stageControllerProvider(stageId).notifier);
      final ui = c.read(stageControllerProvider(stageId));

      expect(ui.assistanceOffer, isNull);
      expect(ui.appliedAssistance, isNull);
      expect(ui.isAssistanceAvailable, isFalse);
      expect(ui.isAssistanceActive, isFalse);
      expect(ui.consecutiveUnsuccessfulAttempts, 0);

      expect(ctrl.assistanceOffer, isNull);
      expect(ctrl.appliedAssistance, isNull);
      expect(ctrl.isAssistanceAvailable, isFalse);
      expect(ctrl.isAssistanceActive, isFalse);
      expect(ctrl.consecutiveUnsuccessfulAttempts, 0);

      expect(
        c.read(assistanceOfferProvider(stageId)),
        isNull,
      );
      expect(
        c.read(appliedAssistanceProvider(stageId)),
        isNull,
      );
      expect(
        c.read(isAssistanceAvailableProvider(stageId)),
        isFalse,
      );
      expect(
        c.read(isAssistanceActiveProvider(stageId)),
        isFalse,
      );
      expect(
        c.read(consecutiveUnsuccessfulAttemptsProvider(stageId)),
        0,
      );
    });

    test(
      'single unsuccessful attempt increments failure count but does not offer assistance or alter tempo',
      () async {
        final repo = LevelRepository()..addImportedLevel(_fourMeasureLevel());
        final c = createHarness(repo);
        addTearDown(c.dispose);

        final ctrl = c.read(stageControllerProvider(stageId).notifier);
        ctrl.setSpeed(1.0);

        // Run through without playing notes (accuracy 0.0)
        await ctrl.start();

        // Let stage complete
        await ctrl.events
            .firstWhere((e) => e.maybeMap(stageCompleted: (_) => true, orElse: () => false))
            .timeout(const Duration(seconds: 3));

        expect(ctrl.consecutiveUnsuccessfulAttempts, 1);
        expect(ctrl.isAssistanceAvailable, isFalse);
        expect(ctrl.state.speed, 1.0); // Never silently changes tempo
        expect(ctrl.state.loopRange, isNull); // Never silently changes range
      },
    );

    test(
      'repeated unsuccessful attempts offer assistance with slower speed and shorter phrase without silent changes',
      () async {
        final repo = LevelRepository()..addImportedLevel(_fourMeasureLevel());
        final c = createHarness(repo);
        addTearDown(c.dispose);

        final ctrl = c.read(stageControllerProvider(stageId).notifier);
        ctrl.setSpeed(1.0);

        // First unsuccessful attempt
        await ctrl.start();
        await ctrl.events
            .firstWhere((e) => e.maybeMap(stageCompleted: (_) => true, orElse: () => false))
            .timeout(const Duration(seconds: 3));

        expect(ctrl.consecutiveUnsuccessfulAttempts, 1);
        expect(ctrl.isAssistanceAvailable, isFalse);

        // Second unsuccessful attempt
        ctrl.replay();
        await ctrl.events
            .firstWhere((e) => e.maybeMap(stageCompleted: (_) => true, orElse: () => false))
            .timeout(const Duration(seconds: 3));

        expect(ctrl.consecutiveUnsuccessfulAttempts, 2);
        expect(ctrl.isAssistanceAvailable, isTrue);

        final offer = ctrl.assistanceOffer;
        expect(offer, isNotNull);
        expect(offer!.suggestedSpeed, 0.75);
        expect(offer.suggestedLoopRange, isNotNull);
        expect(offer.hasSlowerSpeed, isTrue);
        expect(offer.hasShorterPhrase, isTrue);

        // Verified non-silent: speed remains 1.0 and loop remains null
        expect(ctrl.state.speed, 1.0);
        expect(ctrl.state.loopRange, isNull);
        expect(ctrl.isAssistanceActive, isFalse);

        // Accessible description announces assistance offer
        expect(
          ctrl.state.accessibleDescription,
          contains('Assistance available:'),
        );

        // Sliced providers react
        expect(
          c.read(isAssistanceAvailableProvider(stageId)),
          isTrue,
        );
        expect(
          c.read(assistanceOfferProvider(stageId)),
          offer,
        );
        expect(
          c.read(consecutiveUnsuccessfulAttemptsProvider(stageId)),
          2,
        );
      },
    );

    test('dismissAssistanceOffer clears the offer without making changes', () async {
      final repo = LevelRepository()..addImportedLevel(_fourMeasureLevel());
      final c = createHarness(repo);
      addTearDown(c.dispose);

      final ctrl = c.read(stageControllerProvider(stageId).notifier);
      ctrl.setSpeed(1.0);

      // Trigger 2 failures
      await ctrl.start();
      await ctrl.events
          .firstWhere((e) => e.maybeMap(stageCompleted: (_) => true, orElse: () => false))
          .timeout(const Duration(seconds: 3));
      ctrl.replay();
      await ctrl.events
          .firstWhere((e) => e.maybeMap(stageCompleted: (_) => true, orElse: () => false))
          .timeout(const Duration(seconds: 3));

      expect(ctrl.isAssistanceAvailable, isTrue);

      ctrl.dismissAssistanceOffer();

      expect(ctrl.isAssistanceAvailable, isFalse);
      expect(ctrl.assistanceOffer, isNull);
      expect(ctrl.state.speed, 1.0);
      expect(ctrl.state.loopRange, isNull);
    });

    test('applySlowerSpeed changes speed visibly and reversibly with clear way back', () async {
      final repo = LevelRepository()..addImportedLevel(_fourMeasureLevel());
      final c = createHarness(repo);
      addTearDown(c.dispose);

      final ctrl = c.read(stageControllerProvider(stageId).notifier);
      ctrl.setSpeed(1.0);

      // Trigger 2 failures
      await ctrl.start();
      await ctrl.events
          .firstWhere((e) => e.maybeMap(stageCompleted: (_) => true, orElse: () => false))
          .timeout(const Duration(seconds: 3));
      ctrl.replay();
      await ctrl.events
          .firstWhere((e) => e.maybeMap(stageCompleted: (_) => true, orElse: () => false))
          .timeout(const Duration(seconds: 3));

      expect(ctrl.isAssistanceAvailable, isTrue);
      expect(ctrl.assistanceOffer?.suggestedSpeed, 0.75);

      // Apply slower speed
      ctrl.applySlowerSpeed();

      // Offer is consumed, speed is 0.75, appliedAssistance tracks originalSpeed 1.0
      expect(ctrl.state.speed, 0.75);
      expect(ctrl.isAssistanceAvailable, isFalse);
      expect(ctrl.isAssistanceActive, isTrue);
      expect(ctrl.appliedAssistance?.originalSpeed, 1.0);
      expect(ctrl.appliedAssistance?.assistedSpeed, 0.75);
      expect(ctrl.appliedAssistance?.isSpeedAssisted, isTrue);
      expect(ctrl.appliedAssistance?.isPhraseAssisted, isFalse);

      // Accessible description indicates assisted status and clear way back
      expect(ctrl.state.accessibleDescription, contains('Assisted:'));
      expect(ctrl.state.accessibleDescription, contains('Clear way back available'));

      // Revert assistance (clear way back)
      ctrl.revertAssistance();

      expect(ctrl.state.speed, 1.0);
      expect(ctrl.isAssistanceActive, isFalse);
      expect(ctrl.appliedAssistance, isNull);
      expect(ctrl.state.accessibleDescription, isNot(contains('Assisted:')));
    });

    test('applyShorterPhrase loops targeted measure visibly and reversibly with clear way back', () async {
      final repo = LevelRepository()..addImportedLevel(_fourMeasureLevel());
      final c = createHarness(repo);
      addTearDown(c.dispose);

      final ctrl = c.read(stageControllerProvider(stageId).notifier);
      ctrl.setSpeed(1.0);

      // Trigger 2 failures
      await ctrl.start();
      await ctrl.events
          .firstWhere((e) => e.maybeMap(stageCompleted: (_) => true, orElse: () => false))
          .timeout(const Duration(seconds: 3));
      ctrl.replay();
      await ctrl.events
          .firstWhere((e) => e.maybeMap(stageCompleted: (_) => true, orElse: () => false))
          .timeout(const Duration(seconds: 3));

      expect(ctrl.isAssistanceAvailable, isTrue);
      final suggestedRange = ctrl.assistanceOffer!.suggestedLoopRange!;

      // Apply shorter phrase
      ctrl.applyShorterPhrase();

      expect(ctrl.state.loopRange, suggestedRange);
      expect(ctrl.isAssistanceActive, isTrue);
      expect(ctrl.appliedAssistance?.originalLoopRange, isNull);
      expect(ctrl.appliedAssistance?.assistedLoopRange, suggestedRange);
      expect(ctrl.appliedAssistance?.isPhraseAssisted, isTrue);

      // Clear way back: revert restores whole piece
      ctrl.revertAssistance();

      expect(ctrl.state.loopRange, isNull);
      expect(ctrl.isAssistanceActive, isFalse);
      expect(ctrl.appliedAssistance, isNull);
    });

    test('applyAssistance applies both speed and phrase and reverts both cleanly', () async {
      final repo = LevelRepository()..addImportedLevel(_fourMeasureLevel());
      final c = createHarness(repo);
      addTearDown(c.dispose);

      final ctrl = c.read(stageControllerProvider(stageId).notifier);
      ctrl.setSpeed(1.0);

      // Trigger 2 failures
      await ctrl.start();
      await ctrl.events
          .firstWhere((e) => e.maybeMap(stageCompleted: (_) => true, orElse: () => false))
          .timeout(const Duration(seconds: 3));
      ctrl.replay();
      await ctrl.events
          .firstWhere((e) => e.maybeMap(stageCompleted: (_) => true, orElse: () => false))
          .timeout(const Duration(seconds: 3));

      ctrl.applyAssistance(speed: true, phrase: true);

      expect(ctrl.state.speed, 0.75);
      expect(ctrl.state.loopRange, isNotNull);
      expect(ctrl.isAssistanceActive, isTrue);
      expect(ctrl.appliedAssistance?.originalSpeed, 1.0);
      expect(ctrl.appliedAssistance?.originalLoopRange, isNull);

      // Revert restores both
      ctrl.revertAssistance();

      expect(ctrl.state.speed, 1.0);
      expect(ctrl.state.loopRange, isNull);
      expect(ctrl.isAssistanceActive, isFalse);
    });

    test('success on attempt clears pending offer and resets consecutive failures', () async {
      final repo = LevelRepository()..addImportedLevel(_fourMeasureLevel());
      final c = createHarness(repo);
      addTearDown(c.dispose);

      final ctrl = c.read(stageControllerProvider(stageId).notifier);
      ctrl.setSpeed(1.0);

      // Trigger 2 failures to get an offer
      await ctrl.start();
      await ctrl.events
          .firstWhere((e) => e.maybeMap(stageCompleted: (_) => true, orElse: () => false))
          .timeout(const Duration(seconds: 3));
      ctrl.replay();
      await ctrl.events
          .firstWhere((e) => e.maybeMap(stageCompleted: (_) => true, orElse: () => false))
          .timeout(const Duration(seconds: 3));

      expect(ctrl.isAssistanceAvailable, isTrue);
      expect(ctrl.consecutiveUnsuccessfulAttempts, 2);

      // Now play a successful loop attempt: loop bar 0 and hit the note
      ctrl.loopBar(0);
      ctrl.onPitch(
        const PitchEvent(
          frequency: 261.63,
          confidence: 1.0,
          midiNote: 60,
          timestamp: 0,
          volume: 0.9,
        ),
      );

      // Wait for loop wrap event with high accuracy
      await ctrl.events
          .firstWhere((e) => e.maybeMap(loopPassCompleted: (ev) => ev.accuracy >= 0.8, orElse: () => false))
          .timeout(const Duration(seconds: 3));

      expect(ctrl.consecutiveUnsuccessfulAttempts, 0);
      expect(ctrl.isAssistanceAvailable, isFalse);
      expect(ctrl.assistanceOffer, isNull);
    });

    test('waiting mode never counts as an unsuccessful attempt', () async {
      final repo = LevelRepository()..addImportedLevel(_fourMeasureLevel());
      final c = createHarness(repo);
      addTearDown(c.dispose);

      final ctrl = c.read(stageControllerProvider(stageId).notifier);
      ctrl.setPracticeMode(PracticeMode.waiting);

      // Loop measure 0 in waiting mode
      ctrl.loopBar(0);

      // Hit C4
      ctrl.onPitch(
        const PitchEvent(
          frequency: 261.63,
          confidence: 1.0,
          midiNote: 60,
          timestamp: 0,
          volume: 0.9,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(ctrl.consecutiveUnsuccessfulAttempts, 0);
      expect(ctrl.isAssistanceAvailable, isFalse);
    });
  });
}
