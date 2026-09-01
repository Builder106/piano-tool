import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:piano_tool/ui/results/results_screen.dart';
import 'package:piano_tool/ui/theme/app_theme.dart';

void main() {
  testWidgets('shows the completed stage metrics and actions', (tester) async {
    var replayed = false;
    var returnedToLevels = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: PianoTheme.light(),
        home: ResultsScreen(
          result: const StageResult(
            stageId: 'stage_1',
            title: 'C Major Scale',
            score: 500,
            accuracy: 0.625,
            totalNotes: 8,
            hitNotes: 5,
          ),
          onReplay: () => replayed = true,
          onReturnToLevels: () => returnedToLevels = true,
        ),
      ),
    );

    expect(find.text('Stage complete'), findsOneWidget);
    expect(find.text('C Major Scale'), findsOneWidget);
    expect(find.text('500'), findsOneWidget);
    expect(find.text('63%'), findsOneWidget);
    expect(find.text('5 of 8 notes matched'), findsOneWidget);

    await tester.tap(find.text('Replay stage'));
    await tester.tap(find.text('All levels'));

    expect(replayed, isTrue);
    expect(returnedToLevels, isTrue);
  });
}
