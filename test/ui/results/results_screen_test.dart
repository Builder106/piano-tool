import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:piano_tool/data/level_repository.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/models/level_models.dart';
import 'package:piano_tool/ui/results/results_screen.dart';
import 'package:piano_tool/ui/staff/staff_view.dart';
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

  testWidgets('golden: a cleared run, circled and starred', (tester) async {
    await tester.binding.setSurfaceSize(const Size(820, 560));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: PianoTheme.light(),
        home: ResultsScreen(
          result: const StageResult(
            stageId: 'stage_1',
            title: 'C Major Scale',
            score: 1200,
            accuracy: 0.95,
            totalNotes: 20,
            hitNotes: 19,
          ),
          onReplay: () {},
          onReturnToLevels: () {},
        ),
      ),
    );
    // The paper grain and the page clip are image assets; load them before
    // the frame is compared.
    await tester.runAsync(() async {
      final context = tester.element(find.byType(ResultsScreen));
      for (final asset in ['assets/art/paper.png', 'assets/art/clip.png']) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pumpAndSettle();

    expect(find.text('Cleared. The next stage is open.'), findsOneWidget);
    await expectLater(
      find.byType(ResultsScreen),
      matchesGoldenFile('goldens/results_cleared.png'),
    );
  });

  group('hardest passage', () {
    LevelNote note(double beat) => LevelNote(
      midiNote: 60,
      startBeat: beat,
      durationBeats: 1,
      measureIndex: beat ~/ 4,
      beatIndex: (beat % 4).toInt(),
    );
    final notes = [for (var b = 0; b < 16; b++) note(b.toDouble())];

    List<NoteState> missing(Set<int> beats) => [
      for (var b = 0; b < 16; b++)
        beats.contains(b) ? NoteState.missed : NoteState.hitGood,
    ];

    test('nothing missed means no passage and no advice', () {
      expect(hardestPassage(notes, missing({}), beatsPerMeasure: 4), isNull);
    });

    test('names the bar with the most misses', () {
      final p = hardestPassage(notes, missing({9, 10}), beatsPerMeasure: 4);
      expect(p, (first: 2, last: 2));
      expect(passageLabel(p!), 'Bar 3 had the most misses.');
    });

    test('joins two neighbouring bars that both had misses', () {
      final p = hardestPassage(
        notes,
        missing({1, 5, 6, 13}),
        beatsPerMeasure: 4,
      );
      expect(p, (first: 0, last: 1));
      expect(passageLabel(p!), 'Bars 1 and 2 had the most misses.');
    });
  });

  testWidgets('the sheet shows the marked score and names the passage', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final level = LevelRepository().getStage('stage_1')!.level;
    final notes = [for (final m in level.measures) ...m.notes];
    await tester.pumpWidget(
      MaterialApp(
        theme: PianoTheme.light(),
        home: ResultsScreen(
          result: StageResult(
            stageId: 'stage_1',
            title: 'C Major Scale',
            score: 600,
            accuracy: 0.75,
            totalNotes: 8,
            hitNotes: 6,
            level: level,
            notes: notes,
            noteStates: [
              for (var i = 0; i < notes.length; i++)
                i == 5 || i == 6 ? NoteState.missed : NoteState.hitGood,
            ],
          ),
          onReplay: () {},
          onReturnToLevels: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StaffView), findsOneWidget);
    expect(find.text('Bar 2 had the most misses.'), findsOneWidget);
    // The summary does not wait on any animation.
    expect(find.text('6 of 8 notes matched'), findsOneWidget);
  });
}
