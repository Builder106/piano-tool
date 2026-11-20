import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:piano_tool/data/level_repository.dart';
import 'package:piano_tool/data/progress_repository.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/models/level_models.dart';
import 'package:piano_tool/practice/stage_controller.dart';

class _TrackingProgressRepository extends ProgressRepository {
  final List<AttemptRecord> recordedAttempts = [];

  @override
  Future<void> record({
    required String stageId,
    required double accuracy,
    required int score,
    int totalNotes = 0,
    int hitNotes = 0,
    (int, int)? range,
    HandSelection hand = HandSelection.both,
    PracticeMode mode = PracticeMode.timed,
    int? tempo,
    int? targetTempo,
    double speed = 1.0,
    bool isAssisted = false,
    DateTime? date,
    int maxHistoryEntries = ProgressRepository.defaultMaxHistoryEntries,
  }) async {
    recordedAttempts.add(
      AttemptRecord(
        exercise: stageId,
        startMeasure: range?.$1,
        endMeasure: range?.$2,
        hand: hand,
        mode: mode,
        tempo: tempo ?? 120,
        targetTempo: targetTempo,
        speed: speed,
        result: AttemptResult(
          accuracy: accuracy,
          score: score,
          totalNotes: totalNotes,
          hitNotes: hitNotes,
          missedNotes: (totalNotes - hitNotes).clamp(0, totalNotes),
          completed:
              range == null &&
              accuracy >= ProgressRepository.completionThreshold,
          passed: accuracy >= ProgressRepository.completionThreshold,
        ),
        date: date ?? DateTime.now(),
        isAssisted: isAssisted,
      ),
    );
    await super.record(
      stageId: stageId,
      accuracy: accuracy,
      score: score,
      totalNotes: totalNotes,
      hitNotes: hitNotes,
      range: range,
      hand: hand,
      mode: mode,
      tempo: tempo,
      targetTempo: targetTempo,
      speed: speed,
      isAssisted: isAssisted,
      date: date,
      maxHistoryEntries: maxHistoryEntries,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer harness({required ProgressRepository progressRepository}) =>
      ProviderContainer(
        overrides: [
          audioGrantedProvider.overrideWith((ref) async => true),
          levelRepositoryProvider.overrideWith(
            (ref) => SynchronousFuture(LevelRepository()),
          ),
          progressRepositoryProvider.overrideWithValue(progressRepository),
        ],
      );

  test(
    'StageController records full stage attempt context into progress repository',
    () async {
      final trackingRepo = _TrackingProgressRepository();
      final c = harness(progressRepository: trackingRepo);
      addTearDown(c.dispose);

      final ctrl = c.read(stageControllerProvider('stage_1').notifier);
      ctrl.setSpeed(0.75);

      // Simulate stage completion event
      ctrl.handleEventForTesting(
        const StageEvent.stageCompleted(
          accuracy: 0.95,
          score: 500,
          totalNotes: 10,
          hitNotes: 10,
        ),
      );

      // Allow progress write future to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(trackingRepo.recordedAttempts.length, 1);
      final attempt = trackingRepo.recordedAttempts.first;
      expect(attempt.exercise, 'stage_1');
      expect(attempt.accuracy, 0.95);
      expect(attempt.score, 500);
      expect(attempt.result.totalNotes, 10);
      expect(attempt.result.hitNotes, 10);
      expect(attempt.speed, 0.75);
      expect(attempt.isAssisted, isTrue); // Slower speed is assisted
      expect(attempt.mode, PracticeMode.timed);
      expect(attempt.hand, HandSelection.both);
    },
  );

  test(
    'StageController records loop pass attempt into history when notes were attempted',
    () async {
      final trackingRepo = _TrackingProgressRepository();
      final c = harness(progressRepository: trackingRepo);
      addTearDown(c.dispose);

      final ctrl = c.read(stageControllerProvider('stage_1').notifier);
      ctrl.loopRange(1, 2);

      ctrl.handleEventForTesting(
        const StageEvent.loopPassCompleted(
          accuracy: 1.0,
          score: 150,
          totalNotes: 4,
          hitNotes: 4,
          loopStartBeat: 4.0,
          loopEndBeat: 8.0,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(trackingRepo.recordedAttempts.length, 1);
      final attempt = trackingRepo.recordedAttempts.first;
      expect(attempt.exercise, 'stage_1');
      expect(attempt.range, (1, 2));
      expect(attempt.accuracy, 1.0);
      expect(attempt.score, 150);
      expect(attempt.isAssisted, isTrue);
    },
  );
}
