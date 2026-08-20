import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/data/level_repository.dart';
import 'package:piano_tool/engine/stage_engine.dart';

void main() {
  StageEngine engineForStage1() =>
      StageEngine(level: LevelRepository().getAllStages().first.level);

  test('playback speed defaults to 1.0', () {
    final e = engineForStage1();
    addTearDown(e.dispose);
    expect(e.playbackSpeed, 1.0);
  });

  test('setting the speed is retained', () {
    final e = engineForStage1();
    addTearDown(e.dispose);
    e.setPlaybackSpeed(1.5);
    expect(e.playbackSpeed, 1.5);
  });

  test('speed is clamped to a usable range', () {
    final e = engineForStage1();
    addTearDown(e.dispose);
    e.setPlaybackSpeed(99);
    expect(e.playbackSpeed, lessThanOrEqualTo(2.0));
    e.setPlaybackSpeed(0.01);
    expect(e.playbackSpeed, greaterThanOrEqualTo(0.25));
  });

  test('a faster speed advances more beats in the same elapsed time', () async {
    final slow = engineForStage1()..setPlaybackSpeed(0.5);
    final fast = engineForStage1()..setPlaybackSpeed(2.0);
    addTearDown(slow.dispose);
    addTearDown(fast.dispose);

    slow.start();
    fast.start();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(fast.state.currentBeat, greaterThan(slow.state.currentBeat),
        reason: 'speed must affect how fast the playhead moves');
  });

  test('changing speed mid-playback takes effect without restarting the stage',
      () async {
    final e = engineForStage1();
    addTearDown(e.dispose);

    e.start();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final beforeChange = e.state.currentBeat;

    e.setPlaybackSpeed(2.0);
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(e.state.currentBeat, greaterThan(beforeChange),
        reason: 'the playhead must keep moving across a speed change');
    expect(e.state.engineState.toString(), contains('playing'),
        reason: 'changing speed must not stop playback');
  });
}
