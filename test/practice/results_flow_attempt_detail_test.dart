import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:piano_tool/data/level_repository.dart';
import 'package:piano_tool/models/audio_models.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/practice/results_page.dart';
import 'package:piano_tool/practice/stage_controller.dart';

PitchEvent _strike(int midi, {double timestamp = 0.0}) => PitchEvent(
      frequency: 440.0,
      confidence: 1.0,
      midiNote: midi,
      timestamp: timestamp,
      volume: 0.8,
      struck: true,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('RunSummary attempt detail integration', () {
    test('RunSummary preserves note results and signed timing errors', () {
      final states = [
        NoteState.hitPerfect,
        NoteState.missed,
        NoteState.hitGood,
        NoteState.missed,
      ];
      final measureOfNote = [0, 0, 1, 1];
      final noteResults = <int, NoteHitResult>{
        0: const NoteHitResult.perfect(noteIndex: 0, timingError: -0.04),
        1: const NoteHitResult.wrongPitch(
          noteIndex: 1,
          playedMidiNote: 61,
          timingError: 0.08,
        ),
        2: const NoteHitResult.good(noteIndex: 2, timingError: 0.06),
        3: const NoteHitResult.missed(noteIndex: 3),
      };

      final summary = RunSummary.of(
        states,
        measureOfNote,
        noteResults: noteResults,
      );

      expect(summary.right, 2);
      expect(summary.total, 4);
      expect(summary.missed, 2);
      expect(summary.hasAttemptDetail, isTrue);
      expect(summary.noteResults.length, 4);
      expect(summary.signedTimingErrors, [-0.04, 0.08, 0.06]);
      expect(summary.missedExpectedCount, 1);
      expect(summary.wrongPitchCount, 1);
      expect(summary.hasWrongPitches, isTrue);
      expect(summary.hasMissedExpected, isTrue);
      expect(summary.missedExpectedBars, [1]);
      expect(summary.wrongPitchBars, [0]);
      expect(summary.averageTimingError, closeTo((-0.04 + 0.08 + 0.06) / 3, 0.0001));
    });

    test('RunSummary preserves backwards compatibility without attempt detail', () {
      final states = [NoteState.hitPerfect, NoteState.missed];
      final measureOfNote = [0, 0];

      final summary = RunSummary.of(states, measureOfNote);

      expect(summary.right, 1);
      expect(summary.total, 2);
      expect(summary.hasAttemptDetail, isFalse);
      expect(summary.signedTimingErrors, isEmpty);
      expect(summary.missedExpectedCount, 0);
      expect(summary.wrongPitchCount, 0);
      expect(summary.hasWrongPitches, isFalse);
      expect(summary.hasMissedExpected, isFalse);
      expect(summary.averageTimingError, isNull);
    });
  });

  group('StageController results flow and providers', () {
    ProviderContainer harness() => ProviderContainer(
          overrides: [
            audioGrantedProvider.overrideWith((ref) async => true),
            levelRepositoryProvider.overrideWith(
              (ref) => SynchronousFuture(LevelRepository()),
            ),
          ],
        );

    test('exposes noteResults, attemptDetail, and signedTimingErrors through state and providers', () async {
      final c = harness();
      addTearDown(c.dispose);

      const stageId = 'stage_1';
      final controller = c.read(stageControllerProvider(stageId).notifier);

      controller.start();
      expect(c.read(noteResultsProvider(stageId)), isEmpty);
      expect(c.read(attemptDetailProvider(stageId)), isNull);
      expect(c.read(signedTimingErrorsProvider(stageId)), isEmpty);

      // Hit first note with timing
      controller.onPitch(_strike(60)); // C4

      final stateAfterHit = c.read(stageControllerProvider(stageId));
      expect(stateAfterHit.noteResults.containsKey(0), isTrue);
      expect(stateAfterHit.noteResults[0]!.isHit, isTrue);
      expect(c.read(noteResultsProvider(stageId))[0], isNotNull);
      expect(c.read(signedTimingErrorsProvider(stageId)), isNotEmpty);

      // Advance to note 1 (D4) and play confirmed wrong pitch
      controller.seekTo(1.0);
      controller.onPitch(_strike(66)); // F#4 instead of D4

      final stateAfterWrong = c.read(stageControllerProvider(stageId));
      expect(stateAfterWrong.noteResults[1]!.isWrongPitch, isTrue);
      expect(stateAfterWrong.hasWrongPitches, isTrue);
      expect(c.read(wrongPitchCountProvider(stageId)), 1);

      // Complete stage and verify attempt detail in results flow
      final completedFuture = controller.events.firstWhere(
        (e) => e.maybeMap(stageCompleted: (_) => true, orElse: () => false),
      );
      controller.setSpeed(50.0);
      controller.seekTo(16.0);
      await completedFuture.timeout(const Duration(seconds: 3));

      final stateFinished = c.read(stageControllerProvider(stageId));
      expect(stateFinished.status, StageEngineStatus.completed);
      expect(stateFinished.attemptDetail, isNotNull);
      expect(c.read(attemptDetailProvider(stageId)), isNotNull);

      final detail = stateFinished.attemptDetail!;
      expect(detail.totalNotes, greaterThan(0));
      expect(detail.hitNotes, 1);
      expect(detail.wrongPitchNotes, 1);
      expect(stateFinished.hasMissedExpected, isTrue);
      expect(c.read(missedExpectedCountProvider(stageId)), greaterThan(0));

      // Results that lead somewhere: derived difficult measure range and observation
      expect(stateFinished.hasDifficultRange, isTrue);
      expect(stateFinished.difficultMeasureRange, isNotNull);
      expect(c.read(difficultMeasureRangeProvider(stageId)), isNotNull);
      expect(stateFinished.specificObservation, isNotNull);
      expect(c.read(specificObservationProvider(stageId)), isNotNull);
      expect(stateFinished.isAbandonedOrEmpty, isFalse);

      // Offer practice of difficult range
      controller.practiceDifficultRange();
      final loopState = c.read(stageControllerProvider(stageId));
      expect(loopState.loopRange, stateFinished.difficultMeasureRange);
    });

    test('replay resets difficult measure range and observation for a fresh attempt', () async {
      final c = harness();
      addTearDown(c.dispose);

      const stageId = 'stage_1';
      final controller = c.read(stageControllerProvider(stageId).notifier);
      controller.start();

      controller.seekTo(1.0);
      controller.onPitch(_strike(66)); // wrong note

      final completedFuture = controller.events.firstWhere(
        (e) => e.maybeMap(stageCompleted: (_) => true, orElse: () => false),
      );
      controller.setSpeed(50.0);
      controller.seekTo(16.0);
      await completedFuture.timeout(const Duration(seconds: 3));

      expect(c.read(stageControllerProvider(stageId)).difficultMeasureRange, isNotNull);

      controller.replay();
      final resetState = c.read(stageControllerProvider(stageId));
      expect(resetState.difficultMeasureRange, isNull);
      expect(resetState.specificObservation, isNull);
      expect(resetState.isAbandonedOrEmpty, isFalse);
    });
  });
}
