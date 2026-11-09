import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/practice/keys.dart';
import 'package:piano_tool/practice/results_page.dart';

void main() {
  test('a run is summed in notes right first time and bars to repeat', () {
    final states = [
      NoteState.hitPerfect,
      NoteState.missed,
      NoteState.missed,
      NoteState.hitGood,
      NoteState.hitOkay,
      NoteState.missed,
    ];
    final s = RunSummary.of(states, [0, 0, 0, 1, 1, 2]);
    expect(s.right, 3);
    expect(s.total, 6);
    expect(s.missedBars, [0, 2]);
    expect(s.worstBar, 0);
    expect(s.headline, '3 notes needed another go.');
    expect(s.advice, startsWith('Bar 1 had the most.'));
  });

  test('a clean run says so and has no bar to repeat', () {
    final s = RunSummary.of([NoteState.hitPerfect, NoteState.hitGood], [0, 0]);
    expect(s.worstBar, isNull);
    expect(s.headline, 'Every note right first time.');
  });

  test('the keyboard spans at least two octaves round the piece', () {
    expect(keyRange([60, 62, 72]), (60, 83));
    expect(keyRange([60, 64, 67]), (60, 83));
    expect(keyRange([67, 71]), (48, 71));
    expect(keyRange([48, 79]), (48, 83));
    expect(keyRange(const []), (60, 83));
  });
}
