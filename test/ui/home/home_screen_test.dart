import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';

import 'package:piano_tool/data/ingestion_repository.dart';
import 'package:piano_tool/data/level_repository.dart';
import 'package:piano_tool/data/progress_repository.dart';
import 'package:piano_tool/models/level_models.dart';
import 'package:piano_tool/ui/home/home_screen.dart';
import 'package:piano_tool/ui/theme/app_theme.dart';

import '../levels/level_list_screen_test.mocks.dart';

void main() {
  late MockProgressRepository mockProgressRepo;
  late LevelRepository levelRepository;

  setUp(() {
    mockProgressRepo = MockProgressRepository();
    levelRepository = LevelRepository();
    when(
      mockProgressRepo.readAll(),
    ).thenAnswer((_) async => <String, StageProgress>{});
    when(mockProgressRepo.lastPlayedStageId()).thenAnswer((_) async => null);
  });

  Widget createTestWidget({
    LevelRepository? customRepo,
    bool canImport = true,
  }) {
    return ProviderScope(
      overrides: [
        importAvailableProvider.overrideWithValue(canImport),
        levelRepositoryProvider.overrideWith(
          (ref) async => customRepo ?? levelRepository,
        ),
        progressRepositoryProvider.overrideWithValue(mockProgressRepo),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
            GoRoute(
              path: '/levels',
              builder: (context, state) =>
                  const Scaffold(body: Text('Level List Screen')),
            ),
            GoRoute(
              path: '/import',
              builder: (context, state) =>
                  const Scaffold(body: Text('Import Screen')),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) =>
                  const Scaffold(body: Text('Settings Screen')),
            ),
            GoRoute(
              path: '/practice/:stageId',
              builder: (context, state) => Scaffold(
                body: Text('Practice: ${state.pathParameters['stageId']}'),
              ),
            ),
          ],
        ),
        theme: PianoTheme.light(),
      ),
    );
  }

  group('HomeScreen', () {
    testWidgets('shows the lockup and the desk actions', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Piano Tool'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Import a piece'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('keeps settings accessible on a phone', (tester) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings Screen'), findsOneWidget);
    });

    testWidgets('opens the first stage when nothing has been played', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Stage 1 of 3'), findsOneWidget);
      expect(find.text('Up next'), findsOneWidget);
      // The open book's lesson page and its place on the shelf.
      expect(find.text('C Major Scale'), findsNWidgets(2));
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('Start opens the stage', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      expect(find.text('Practice: stage_1'), findsOneWidget);
    });

    testWidgets('reopens the last stage played, with its best run', (
      tester,
    ) async {
      when(
        mockProgressRepo.lastPlayedStageId(),
      ).thenAnswer((_) async => 'stage_2');
      when(mockProgressRepo.readAll()).thenAnswer(
        (_) async => {
          'stage_1': const StageProgress(
            stageId: 'stage_1',
            bestAccuracy: 0.95,
            bestScore: 1000,
            attempts: 2,
            completed: true,
            unlocked: true,
          ),
          'stage_2': const StageProgress(
            stageId: 'stage_2',
            bestAccuracy: 0.75,
            bestScore: 450,
            attempts: 3,
            completed: false,
            unlocked: true,
          ),
        },
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Stage 2 of 3'), findsOneWidget);
      expect(find.text('In progress'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('Runs'), findsOneWidget);
      // Stage one is cleared on the shelf.
      expect(find.text('Cleared'), findsOneWidget);

      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();

      expect(find.text('Practice: stage_2'), findsOneWidget);
    });

    testWidgets('the shelf counts cleared books and leaves every book open', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('0 of 3 cleared'), findsOneWidget);
      expect(find.text('Locked'), findsNothing);

      await tester.tap(find.text('Open the library'));
      await tester.pumpAndSettle();

      expect(find.text('Level List Screen'), findsOneWidget);
    });

    testWidgets('any book on the shelf opens', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Ode to Joy'));
      await tester.tap(find.text('Ode to Joy'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Practice:'), findsOneWidget);
    });

    testWidgets('offers no import when this build has no import service', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(canImport: false));
      await tester.pumpAndSettle();

      expect(find.text('Import a piece'), findsNothing);
      expect(find.text('Library'), findsOneWidget);
    });

    for (final (label, screen) in [
      ('Library', 'Level List Screen'),
      ('Import a piece', 'Import Screen'),
      ('Settings', 'Settings Screen'),
    ]) {
      testWidgets('$label in the header opens its screen', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text(label));
        await tester.pumpAndSettle();

        expect(find.text(screen), findsOneWidget);
      });
    }
  });
}
