import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:piano_tool/data/ingestion_repository.dart';
import 'package:piano_tool/data/progress_repository.dart';
import 'package:piano_tool/main.dart';
import 'package:piano_tool/ui/import/import_screen.dart';
import 'package:piano_tool/ui/import/review_screen.dart';
import 'package:piano_tool/ui/levels/level_list_screen.dart';
import 'package:piano_tool/ui/practice/practice_screen.dart';
import 'package:piano_tool/ui/practice/stage_controller.dart';
import 'package:piano_tool/ui/results/results_screen.dart';

@GenerateMocks([IngestionRepository, ProgressRepository])
import 'app_router_test.mocks.dart';

void main() {
  late MockIngestionRepository mockIngestionRepo;
  late MockProgressRepository mockProgressRepo;

  setUp(() {
    mockIngestionRepo = MockIngestionRepository();
    mockProgressRepo = MockProgressRepository();
    when(mockProgressRepo.read(any)).thenAnswer((_) async => null);
    when(mockIngestionRepo.pollJob(any)).thenAnswer(
      (_) async => IngestionJobResult(status: IngestionJobStatus.queued),
    );
    // levelRepositoryProvider (the real, non-overridden definition) hydrates
    // from this at startup to render LevelListScreen.
    when(mockIngestionRepo.listImportedLevels()).thenAnswer((_) async => []);
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        ingestionRepositoryProvider
            .overrideWith((ref) async => mockIngestionRepo),
        progressRepositoryProvider.overrideWithValue(mockProgressRepo),
        audioGrantedProvider.overrideWith((ref) async => true),
      ],
      child: const PianoToolApp(),
    );
  }

  group('appRouterProvider', () {
    testWidgets('home route ("/") renders LevelListScreen', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(LevelListScreen), findsOneWidget);
    });

    testWidgets('tapping the import action navigates to /import (ImportScreen)',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Import new piece'));
      await tester.pumpAndSettle();

      expect(find.byType(ImportScreen), findsOneWidget);
      expect(find.byType(LevelListScreen), findsNothing);
    });

    testWidgets('/review?jobId=... renders ReviewScreen with the jobId',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(LevelListScreen));
      GoRouter.of(context).push('/review?jobId=job-42');
      await tester.pumpAndSettle();

      final reviewScreen =
          tester.widget<ReviewScreen>(find.byType(ReviewScreen));
      expect(reviewScreen.jobId, 'job-42');
    });

    testWidgets('/practice/:stageId renders PracticeScreen with the stageId',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(LevelListScreen));
      GoRouter.of(context).push('/practice/stage_1');
      await tester.pumpAndSettle();

      final practiceScreen =
          tester.widget<PracticeScreen>(find.byType(PracticeScreen));
      expect(practiceScreen.stageId, 'stage_1');
    });

    testWidgets('results route renders its stage result', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(LevelListScreen));
      GoRouter.of(context).pushNamed(
        'results',
        pathParameters: const {'stageId': 'stage_1'},
        extra: const StageResult(
          stageId: 'stage_1',
          title: 'C Major Scale',
          score: 500,
          accuracy: 0.625,
          totalNotes: 8,
          hitNotes: 5,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ResultsScreen), findsOneWidget);
      expect(find.text('500'), findsOneWidget);
      expect(find.text('63%'), findsOneWidget);
    });

    testWidgets('results actions replay the stage or return to levels',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(LevelListScreen));
      GoRouter.of(context).pushNamed(
        'results',
        pathParameters: const {'stageId': 'stage_1'},
        extra: const StageResult(
          stageId: 'stage_1',
          title: 'C Major Scale',
          score: 500,
          accuracy: 0.625,
          totalNotes: 8,
          hitNotes: 5,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Replay stage'));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeScreen), findsOneWidget);

      GoRouter.of(tester.element(find.byType(PracticeScreen))).goNamed(
        'results',
        pathParameters: const {'stageId': 'stage_1'},
        extra: const StageResult(
          stageId: 'stage_1',
          title: 'C Major Scale',
          score: 500,
          accuracy: 0.625,
          totalNotes: 8,
          hitNotes: 5,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('All levels'));
      await tester.pumpAndSettle();
      expect(find.byType(LevelListScreen), findsOneWidget);
    });

    testWidgets('unknown route renders the error builder', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(LevelListScreen));
      GoRouter.of(context).push('/does-not-exist');
      await tester.pumpAndSettle();

      expect(find.textContaining('Route not found'), findsOneWidget);
    });
  });
}
