import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';

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

  Widget createTestWidget({LevelRepository? customRepo}) {
    return ProviderScope(
      overrides: [
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
    testWidgets('renders app header, subtitle, and top bar action buttons', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Piano Tool'), findsOneWidget);
      expect(
        find.text('Interactive practice tutor and transcription studio'),
        findsOneWidget,
      );
      expect(find.byTooltip('All levels'), findsOneWidget);
      expect(find.byTooltip('Import piece'), findsOneWidget);
      expect(find.byTooltip('Settings & Calibration'), findsOneWidget);
    });

    testWidgets(
      'shows Continue Practice card with first unlocked stage when unplayed',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Continue Practice'), findsOneWidget);
        expect(find.text('Up Next'), findsOneWidget);
        expect(find.text('C Major Scale'), findsOneWidget);
        expect(find.text('Start'), findsOneWidget);
      },
    );

    testWidgets('tapping Start on continue card navigates to practice route', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      expect(find.text('Practice: stage_1'), findsOneWidget);
    });

    testWidgets(
      'prioritizes last played stage with progress metrics and Resume action',
      (tester) async {
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

        expect(find.text('Continue Practice'), findsOneWidget);
        expect(find.text('In Progress'), findsOneWidget);
        expect(find.text('Ode to Joy'), findsOneWidget);
        expect(find.text('75% accuracy'), findsOneWidget);
        expect(find.text('450 pts | 3 runs'), findsOneWidget);
        expect(find.text('Resume'), findsOneWidget);

        await tester.tap(find.text('Resume'));
        await tester.pumpAndSettle();

        expect(find.text('Practice: stage_2'), findsOneWidget);
      },
    );

    testWidgets(
      'navigates to /levels when clicking Browse all levels on summary card',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Level Library'), findsOneWidget);
        expect(find.text('0 of 3 cleared'), findsOneWidget);

        await tester.tap(find.text('Browse all levels'));
        await tester.pumpAndSettle();

        expect(find.text('Level List Screen'), findsOneWidget);
      },
    );

    testWidgets('navigates to /levels when tapping top bar library button', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('All levels'));
      await tester.pumpAndSettle();

      expect(find.text('Level List Screen'), findsOneWidget);
    });

    testWidgets('navigates to /import when tapping Import piece card', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Import Piece'), findsOneWidget);

      await tester.tap(find.text('Import audio'));
      await tester.pumpAndSettle();

      expect(find.text('Import Screen'), findsOneWidget);
    });

    testWidgets('navigates to /settings when tapping settings top bar icon', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Settings & Calibration'));
      await tester.pumpAndSettle();

      expect(find.text('Settings Screen'), findsOneWidget);
    });
  });
}
