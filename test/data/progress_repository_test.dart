import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:piano_tool/data/progress_repository.dart';

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
}
