import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:piano_tool/data/progress_repository.dart';
import 'package:piano_tool/models/level_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('an unplayed stage has no progress', () async {
    final repo = ProgressRepository();
    expect(await repo.read('stage_1'), isNull);
  });

  test('recording a run stores accuracy and score', () async {
    final repo = ProgressRepository();
    await repo.record(stageId: 'stage_1', accuracy: 0.8, score: 100);

    final p = (await repo.read('stage_1'))!;
    expect(p.stageId, 'stage_1');
    expect(p.bestAccuracy, closeTo(0.8, 1e-9));
    expect(p.bestScore, 100);
    expect(p.attempts, 1);
  });

  test('a worse run raises attempts but not the bests', () async {
    final repo = ProgressRepository();
    await repo.record(stageId: 'stage_1', accuracy: 0.9, score: 200);
    await repo.record(stageId: 'stage_1', accuracy: 0.4, score: 50);

    final p = (await repo.read('stage_1'))!;
    expect(p.bestAccuracy, closeTo(0.9, 1e-9));
    expect(p.bestScore, 200);
    expect(p.attempts, 2);
  });

  test('a better run raises the bests', () async {
    final repo = ProgressRepository();
    await repo.record(stageId: 'stage_1', accuracy: 0.5, score: 10);
    await repo.record(stageId: 'stage_1', accuracy: 0.95, score: 300);

    final p = (await repo.read('stage_1'))!;
    expect(p.bestAccuracy, closeTo(0.95, 1e-9));
    expect(p.bestScore, 300);
  });

  test('completion latches at 90% accuracy and never un-completes', () async {
    final repo = ProgressRepository();
    await repo.record(stageId: 'stage_1', accuracy: 0.92, score: 100);
    expect((await repo.read('stage_1'))!.completed, isTrue);

    await repo.record(stageId: 'stage_1', accuracy: 0.10, score: 5);
    expect((await repo.read('stage_1'))!.completed, isTrue);
  });

  test('stages are stored independently', () async {
    final repo = ProgressRepository();
    await repo.record(stageId: 'stage_1', accuracy: 0.8, score: 100);
    await repo.record(stageId: 'stage_2', accuracy: 0.6, score: 60);

    final all = await repo.readAll();
    expect(all.keys.toSet(), {'stage_1', 'stage_2'});
    expect(all['stage_2']!.bestScore, 60);
  });

  test('last played round-trips and survives a new repository', () async {
    await ProgressRepository().setLastPlayed('stage_3');
    expect(await ProgressRepository().lastPlayedStageId(), 'stage_3');
  });

  test('corrupt stored JSON is discarded rather than thrown', () async {
    SharedPreferences.setMockInitialValues({
      'progress.stage_1': '{not valid json',
    });
    expect(await ProgressRepository().read('stage_1'), isNull);
  });

  group('Mastery at a tempo and bounded attempt history', () {
    test(
      'stores attempt history with exercise, range, hand, mode, tempo, result, and date',
      () async {
        final repo = ProgressRepository();
        final fixedDate = DateTime.utc(2026, 11, 20, 10, 30);

        await repo.record(
          stageId: 'stage_twinkle',
          accuracy: 0.94,
          score: 450,
          totalNotes: 20,
          hitNotes: 19,
          range: (1, 4),
          hand: HandSelection.right,
          mode: PracticeMode.timed,
          tempo: 100,
          targetTempo: 100,
          speed: 1.0,
          isAssisted: false,
          date: fixedDate,
        );

        final p = (await repo.read('stage_twinkle'))!;
        expect(p.history.length, 1);
        final attempt = p.history.first;

        expect(attempt.exercise, 'stage_twinkle');
        expect(attempt.stageId, 'stage_twinkle');
        expect(attempt.range, (1, 4));
        expect(attempt.startMeasure, 1);
        expect(attempt.endMeasure, 4);
        expect(attempt.hand, HandSelection.right);
        expect(attempt.mode, PracticeMode.timed);
        expect(attempt.tempo, 100);
        expect(attempt.targetTempo, 100);
        expect(attempt.speed, 1.0);
        expect(attempt.accuracy, closeTo(0.94, 1e-9));
        expect(attempt.score, 450);
        expect(attempt.result.totalNotes, 20);
        expect(attempt.result.hitNotes, 19);
        expect(attempt.result.missedNotes, 1);
        expect(attempt.result.passed, isTrue);
        expect(attempt.date, fixedDate);
        expect(attempt.isAssisted, isFalse);
      },
    );

    test('history is bounded to maxHistoryEntries', () async {
      final repo = ProgressRepository();

      for (var i = 1; i <= 60; i++) {
        await repo.record(
          stageId: 'stage_bounded',
          accuracy: 0.8,
          score: i * 10,
          date: DateTime.utc(2026, 11, 20, 1, i),
          maxHistoryEntries: 50,
        );
      }

      final p = (await repo.read('stage_bounded'))!;
      expect(p.history.length, 50);
      // Oldest 10 dropped; first stored score should be 11 * 10 = 110, last is 600
      expect(p.history.first.score, 110);
      expect(p.history.last.score, 600);
    });

    test(
      'a high score earned slowly does not establish target tempo readiness',
      () async {
        final repo = ProgressRepository();

        // Slow attempt at 0.5x speed with 100% accuracy
        await repo.record(
          stageId: 'stage_slow',
          accuracy: 1.0,
          score: 500,
          totalNotes: 30,
          hitNotes: 30,
          targetTempo: 120,
          tempo: 60,
          speed: 0.5,
          mode: PracticeMode.timed,
        );

        final p = (await repo.read('stage_slow'))!;
        // Best accuracy climbs and stage is completed via assisted completion
        expect(p.bestAccuracy, closeTo(1.0, 1e-9));
        expect(p.bestScore, 500);
        expect(p.completed, isTrue);
        expect(p.assistedCompletions, 1);
        expect(p.timedCompletions, 0);

        // Target tempo readiness is strictly NOT established
        expect(p.targetTempoReady, isFalse);
        expect(p.targetTempoReadyAt, isNull);
        expect(p.bestTargetTempoAccuracy, 0.0);
        expect(p.bestTargetTempoScore, 0);

        final attempt = p.history.first;
        expect(attempt.isAssisted, isTrue);
        expect(attempt.isTimedPerformance, isFalse);
        expect(attempt.isAssistedCompletion, isTrue);
        expect(attempt.establishesTargetTempoReadiness, isFalse);
      },
    );

    test('waiting mode does not establish target tempo readiness', () async {
      final repo = ProgressRepository();

      await repo.record(
        stageId: 'stage_waiting',
        accuracy: 1.0,
        score: 0,
        totalNotes: 15,
        hitNotes: 15,
        mode: PracticeMode.waiting,
        speed: 1.0,
        targetTempo: 120,
      );

      final p = (await repo.read('stage_waiting'))!;
      expect(p.completed, isTrue);
      expect(p.assistedCompletions, 1);
      expect(p.targetTempoReady, isFalse);
      expect(p.bestTargetTempoAccuracy, 0.0);

      final attempt = p.history.first;
      expect(attempt.isTimedPerformance, isFalse);
      expect(attempt.establishesTargetTempoReadiness, isFalse);
    });

    test(
      'active assistance does not establish target tempo readiness',
      () async {
        final repo = ProgressRepository();

        await repo.record(
          stageId: 'stage_assisted',
          accuracy: 0.95,
          score: 400,
          totalNotes: 25,
          hitNotes: 24,
          isAssisted: true,
          mode: PracticeMode.timed,
          speed: 1.0,
        );

        final p = (await repo.read('stage_assisted'))!;
        expect(p.targetTempoReady, isFalse);
        expect(p.bestTargetTempoAccuracy, 0.0);
        expect(p.assistedCompletions, 1);
        expect(p.history.first.establishesTargetTempoReadiness, isFalse);
      },
    );

    test(
      'timed performance at target tempo establishes readiness and tracks tempo bests',
      () async {
        final repo = ProgressRepository();
        final now = DateTime.utc(2026, 11, 20, 12, 0);

        // First run: slow at 0.75x speed
        await repo.record(
          stageId: 'stage_timed_mastery',
          accuracy: 0.96,
          score: 800,
          speed: 0.75,
          targetTempo: 120,
          tempo: 90,
          date: now.subtract(const Duration(minutes: 10)),
        );

        var p = (await repo.read('stage_timed_mastery'))!;
        expect(p.bestAccuracy, closeTo(0.96, 1e-9));
        expect(p.targetTempoReady, isFalse);
        expect(p.bestTargetTempoAccuracy, 0.0);

        // Second run: at target tempo (speed 1.0) with passing accuracy
        await repo.record(
          stageId: 'stage_timed_mastery',
          accuracy: 0.92,
          score: 950,
          speed: 1.0,
          targetTempo: 120,
          tempo: 120,
          date: now,
        );

        p = (await repo.read('stage_timed_mastery'))!;
        // Best accuracy is still 0.96 (preserved from slow run)
        expect(p.bestAccuracy, closeTo(0.96, 1e-9));
        // Best target tempo accuracy is 0.92 from the target tempo performance
        expect(p.bestTargetTempoAccuracy, closeTo(0.92, 1e-9));
        expect(p.bestTargetTempoScore, 950);
        expect(p.targetTempoReady, isTrue);
        expect(p.targetTempoReadyAt, now);
        expect(p.timedCompletions, 1);

        expect(p.history.last.isTimedPerformance, isTrue);
        expect(p.history.last.establishesTargetTempoReadiness, isTrue);
      },
    );

    test(
      'sub-range practice does not complete full stage or establish full readiness',
      () async {
        final repo = ProgressRepository();

        await repo.record(
          stageId: 'stage_range',
          accuracy: 1.0,
          score: 200,
          range: (2, 3),
          speed: 1.0,
          mode: PracticeMode.timed,
        );

        final p = (await repo.read('stage_range'))!;
        expect(p.completed, isFalse);
        expect(p.targetTempoReady, isFalse);
        expect(p.history.length, 1);
        expect(p.history.first.range, (2, 3));
        expect(p.history.first.isFullExercise, isFalse);
        expect(p.history.first.establishesTargetTempoReadiness, isFalse);
      },
    );

    test('storage migration preserves existing bests from legacy JSON', () async {
      final repo = ProgressRepository();
      // Legacy JSON created by earlier version of the application without history or targetTempoReady
      SharedPreferences.setMockInitialValues({
        'progress.legacy_piece': '''{
          "stageId": "legacy_piece",
          "bestAccuracy": 0.89,
          "bestScore": 650,
          "attempts": 7,
          "completed": true,
          "unlocked": true,
          "completedAt": "2026-10-15T10:00:00.000Z",
          "lastAttemptAt": "2026-10-15T10:30:00.000Z"
        }''',
      });

      final legacy = (await repo.read('legacy_piece'))!;
      expect(legacy.stageId, 'legacy_piece');
      expect(legacy.bestAccuracy, closeTo(0.89, 1e-9));
      expect(legacy.bestScore, 650);
      expect(legacy.attempts, 7);
      expect(legacy.completed, isTrue);
      expect(legacy.targetTempoReady, isFalse);
      expect(legacy.history, isEmpty);

      // Now record a new attempt on the legacy stage
      await repo.record(stageId: 'legacy_piece', accuracy: 0.80, score: 500);

      final updated = (await repo.read('legacy_piece'))!;
      // Existing bests are strictly preserved and attempts incremented
      expect(updated.bestAccuracy, closeTo(0.89, 1e-9));
      expect(updated.bestScore, 650);
      expect(updated.attempts, 8);
      expect(updated.completed, isTrue);
      expect(updated.history.length, 1);

      // Explicit migration verification
      final migrated = await repo.migrateLegacy('legacy_piece');
      expect(migrated?.bestAccuracy, closeTo(0.89, 1e-9));
      expect(migrated?.bestScore, 650);
    });

    test(
      'recordAttempt convenience method and repository queries round-trip',
      () async {
        final repo = ProgressRepository();
        final fixedDate = DateTime.utc(2026, 11, 20, 14, 0);

        final attempt = AttemptRecord(
          exercise: 'stage_query_test',
          tempo: 120,
          targetTempo: 120,
          speed: 1.0,
          hand: HandSelection.both,
          mode: PracticeMode.timed,
          date: fixedDate,
          result: const AttemptResult(
            accuracy: 0.95,
            score: 850,
            totalNotes: 40,
            hitNotes: 38,
            passed: true,
            completed: true,
          ),
        );

        await repo.recordAttempt(attempt);

        final history = await repo.getHistory('stage_query_test');
        expect(history.length, 1);
        expect(history.first.score, 850);

        final isReady = await repo.isTargetTempoReady('stage_query_test');
        expect(isReady, isTrue);

        final all = await repo.getAllHistory();
        expect(all.length, 1);
        expect(all.first.exercise, 'stage_query_test');
      },
    );
  });
}
