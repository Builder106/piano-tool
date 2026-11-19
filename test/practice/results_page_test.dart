import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/brand/buttons.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/practice/keys.dart';
import 'package:piano_tool/practice/results_page.dart';

void main() {
  test('a run is summed in notes right first time and bars to repeat with specific observation', () {
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
    expect(s.difficultMeasureRange, (0, 0));
    expect(s.advice, contains('Bar 1'));
    expect(s.isAbandonedOrEmpty, isFalse);
  });

  test('a clean run says so and has no bar to repeat', () {
    final s = RunSummary.of([NoteState.hitPerfect, NoteState.hitGood], [0, 0]);
    expect(s.worstBar, isNull);
    expect(s.difficultMeasureRange, isNull);
    expect(s.headline, 'Every note right first time.');
    expect(s.advice, contains('next piece'));
  });

  test('empty or abandoned attempts do not invent advice', () {
    final emptyRun = RunSummary.of(const [], const []);
    expect(emptyRun.isAbandonedOrEmpty, isTrue);
    expect(emptyRun.headline, 'Attempt not completed.');
    expect(emptyRun.advice, isEmpty);
    expect(emptyRun.difficultMeasureRange, isNull);

    final unplayedRun = RunSummary.of(
      const [NoteState.upcoming, NoteState.upcoming],
      const [0, 0],
    );
    expect(unplayedRun.isAbandonedOrEmpty, isTrue);
    expect(unplayedRun.advice, isEmpty);

    final abandonedRun = RunSummary.of(
      const [NoteState.hitPerfect],
      const [0],
      isAbandoned: true,
    );
    expect(abandonedRun.isAbandonedOrEmpty, isTrue);
    expect(abandonedRun.advice, isEmpty);
  });

  test('the keyboard spans at least two octaves round the piece', () {
    expect(keyRange([60, 62, 72]), (60, 83));
    expect(keyRange([60, 64, 67]), (60, 83));
    expect(keyRange([67, 71]), (48, 71));
    expect(keyRange([48, 79]), (48, 83));
    expect(keyRange(const []), (60, 83));
  });

  testWidgets('ResultsPage offers multi-measure range practice and preserves replay and return-to-desk', (tester) async {
    int? practicedStart;
    int? practicedEnd;
    var replayed = false;
    var returnedToDesk = false;

    final summary = RunSummary(
      right: 2,
      total: 4,
      missedBars: const [1, 2],
      worstBar: 1,
      difficultMeasureRange: const (1, 2),
      specificObservation: 'Bars 2–3 had missed notes.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResultsPage(
            summary: summary,
            staff: const SizedBox(height: 100),
            onPractise: (_) {},
            onPractiseRange: (start, end) {
              practicedStart = start;
              practicedEnd = end;
            },
            onAgain: () => replayed = true,
            onDone: () => returnedToDesk = true,
          ),
        ),
      ),
    );

    expect(find.text('Practise bars 2–3'), findsOneWidget);
    expect(find.text('Play again'), findsOneWidget);
    expect(find.text('Back to pieces'), findsOneWidget);
    expect(find.text('Bars 2–3 had missed notes.'), findsOneWidget);

    await tester.tap(find.text('Practise bars 2–3'));
    await tester.pump();
    expect(practicedStart, 1);
    expect(practicedEnd, 2);

    await tester.tap(find.text('Play again'));
    await tester.pump();
    expect(replayed, isTrue);

    await tester.tap(find.text('Back to pieces'));
    await tester.pump();
    expect(returnedToDesk, isTrue);
  });

  testWidgets('ResultsPage offers next stage after successful attempt', (tester) async {
    var nextPressed = false;

    final summary = RunSummary(
      right: 4,
      total: 4,
      missedBars: const [],
      worstBar: null,
      nextStageId: 'stage_2',
      nextStageTitle: 'D Minor Melody',
      specificObservation: 'Clean run. Ready for D Minor Melody.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResultsPage(
            summary: summary,
            staff: const SizedBox(height: 100),
            onPractise: (_) {},
            onNextStage: () => nextPressed = true,
            onAgain: () {},
            onDone: () {},
          ),
        ),
      ),
    );

    expect(find.text('Next piece: D Minor Melody'), findsOneWidget);
    await tester.tap(find.text('Next piece: D Minor Melody'));
    await tester.pump();
    expect(nextPressed, isTrue);
  });

  testWidgets('ResultsPage with empty or abandoned attempt does not invent advice or practice buttons', (tester) async {
    const summary = RunSummary(
      right: 0,
      total: 4,
      missedBars: [],
      worstBar: null,
      isAbandonedOrEmpty: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResultsPage(
            summary: summary,
            staff: const SizedBox(height: 100),
            onPractise: (_) {},
            onAgain: () {},
            onDone: () {},
          ),
        ),
      ),
    );

    expect(find.text('Attempt not completed.'), findsOneWidget);
    expect(find.byType(StartButton), findsNothing);
    expect(find.text('Play again'), findsOneWidget);
    expect(find.text('Back to pieces'), findsOneWidget);
  });
}
