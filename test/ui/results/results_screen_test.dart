import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/ui/results/results_screen.dart';
import 'package:piano_tool/ui/theme/app_theme.dart';

void main() {
  Widget harness({
    required VoidCallback onReplay,
    required VoidCallback onReturnToLevels,
  }) =>
      MaterialApp(
        theme: PianoTheme.light(),
        home: ResultsScreen(
          result: const StageResult(
            stageId: 'stage_1',
            title: 'C Major Scale',
            score: 600,
            accuracy: 0.75,
            totalNotes: 8,
            hitNotes: 6,
          ),
          onReplay: onReplay,
          onReturnToLevels: onReturnToLevels,
        ),
      );

  testWidgets('shows final score and accuracy', (tester) async {
    await tester.pumpWidget(harness(
      onReplay: () {},
      onReturnToLevels: () {},
    ));

    expect(find.text('Stage complete'), findsOneWidget);
    expect(find.text('C Major Scale'), findsOneWidget);
    expect(find.text('600'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('6 of 8 notes matched'), findsOneWidget);
  });

  testWidgets('uses its replay and levels actions', (tester) async {
    var replayed = false;
    var returnedToLevels = false;
    await tester.pumpWidget(harness(
      onReplay: () => replayed = true,
      onReturnToLevels: () => returnedToLevels = true,
    ));

    await tester.tap(find.text('Replay stage'));
    expect(replayed, isTrue);

    await tester.tap(find.text('All levels'));
    expect(returnedToLevels, isTrue);
  });
}
