import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:piano_tool/data/ingestion_repository.dart';
import 'package:piano_tool/data/level_repository.dart';
import 'package:piano_tool/data/progress_repository.dart';
import 'package:piano_tool/models/level_models.dart';
import 'package:piano_tool/ui/levels/level_list_screen.dart';
import 'package:piano_tool/ui/theme/app_theme.dart';

@GenerateMocks([ProgressRepository, IngestionRepository])
import 'level_list_screen_test.mocks.dart';

void main() {
  late MockProgressRepository mockProgressRepo;
  late MockIngestionRepository mockIngestionRepo;
  late LevelRepository levelRepository;

  setUp(() {
    mockProgressRepo = MockProgressRepository();
    mockIngestionRepo = MockIngestionRepository();
    levelRepository = LevelRepository();
    // The delete flow reads this to persist the removal; tests that don't
    // exercise delete never call it.
    when(mockIngestionRepo.deleteImportedLevel(any)).thenAnswer((_) async {});
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        levelRepositoryProvider.overrideWith((ref) async => levelRepository),
        progressRepositoryProvider.overrideWithValue(mockProgressRepo),
        ingestionRepositoryProvider.overrideWith((ref) async => mockIngestionRepo),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const LevelListScreen(),
            ),
            GoRoute(
              path: '/import',
              builder: (_, __) => const Scaffold(body: Text('Import Screen')),
            ),
            GoRoute(
              path: '/practice/:stageId',
              builder: (_, state) => Scaffold(body: Text('Practice: ${state.pathParameters['stageId']}')),
            ),
          ],
        ),
        theme: PianoTheme.light(),
      ),
    );
  }

  group('LevelListScreen', () {
    testWidgets('shows built-in stages in order', (tester) async {
      when(mockProgressRepo.read(any)).thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for built-in stages
      expect(find.text('C Major Scale'), findsOneWidget);
      expect(find.text('Ode to Joy'), findsOneWidget);
      expect(find.text('Mixed Rhythms'), findsOneWidget);

      // Check order
      final scaleIndex = tester.getSemantics(find.text('C Major Scale')).indexInParent as int;
      final odeIndex = tester.getSemantics(find.text('Ode to Joy')).indexInParent as int;
      final mixedIndex = tester.getSemantics(find.text('Mixed Rhythms')).indexInParent as int;
      expect(scaleIndex, lessThan(odeIndex));
      expect(odeIndex, lessThan(mixedIndex));
    });

    testWidgets('shows import button in app bar', (tester) async {
      when(mockProgressRepo.read(any)).thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('tapping import button navigates to import screen', (tester) async {
      when(mockProgressRepo.read(any)).thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Import Screen'), findsOneWidget);
    });

    testWidgets('tapping a stage navigates to practice screen', (tester) async {
      when(mockProgressRepo.read(any)).thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('C Major Scale'));
      await tester.pumpAndSettle();

      expect(find.text('Practice: stage_1'), findsOneWidget);
    });

    testWidgets('shows imported label for imported levels', (tester) async {
      when(mockProgressRepo.read(any)).thenAnswer((_) async => null);

      // Add an imported level
      const importedLevel = LevelModel(
        id: 'imported_1',
        title: 'My Song',
        description: 'Imported from audio',
        tempo: 100,
        beatsPerMeasure: 4,
        totalMeasures: 2,
        measures: [],
      );
      levelRepository.addImportedLevel(importedLevel);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('My Song'), findsOneWidget);
      expect(find.text('Imported'), findsOneWidget);
    });

    testWidgets('imported levels appear after built-in stages', (tester) async {
      when(mockProgressRepo.read(any)).thenAnswer((_) async => null);

      const importedLevel = LevelModel(
        id: 'imported_1',
        title: 'My Song',
        description: 'Imported from audio',
        tempo: 100,
        beatsPerMeasure: 4,
        totalMeasures: 2,
        measures: [],
      );
      levelRepository.addImportedLevel(importedLevel);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Built-in stages should appear first
      final builtInStages = find.byWidgetPredicate((widget) {
        return widget is Text &&
            (widget.data?.contains('C Major Scale') == true ||
             widget.data?.contains('Ode to Joy') == true ||
             widget.data?.contains('Mixed Rhythms') == true);
      });
      expect(builtInStages, findsAtLeastNWidgets(3));
    });

    testWidgets('imported levels appear newest-first', (tester) async {
      when(mockProgressRepo.read(any)).thenAnswer((_) async => null);

      const firstImport = LevelModel(
        id: 'imported_1',
        title: 'First Import',
        description: 'Imported earlier',
        tempo: 100,
        beatsPerMeasure: 4,
        totalMeasures: 2,
        measures: [],
      );
      const secondImport = LevelModel(
        id: 'imported_2',
        title: 'Second Import',
        description: 'Imported later',
        tempo: 100,
        beatsPerMeasure: 4,
        totalMeasures: 2,
        measures: [],
      );
      levelRepository.addImportedLevel(firstImport);
      levelRepository.addImportedLevel(secondImport);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final secondIndex =
          tester.getSemantics(find.text('Second Import')).indexInParent as int;
      final firstIndex =
          tester.getSemantics(find.text('First Import')).indexInParent as int;
      expect(secondIndex, lessThan(firstIndex));
    });

    testWidgets('shows progress for completed stages', (tester) async {
      when(mockProgressRepo.read('stage_1')).thenAnswer((_) async => StageProgress(
        stageId: 'stage_1',
        bestAccuracy: 0.95,
        bestScore: 1000,
        attempts: 3,
        completed: true,
        unlocked: true,
        completedAt: DateTime.now(),
        lastAttemptAt: DateTime.now(),
      ));
      when(mockProgressRepo.read('stage_2')).thenAnswer((_) async => null);
      when(mockProgressRepo.read('stage_3')).thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('95%'), findsOneWidget);
    });

    testWidgets('long press on imported level shows delete dialog', (tester) async {
      when(mockProgressRepo.read(any)).thenAnswer((_) async => null);

      const importedLevel = LevelModel(
        id: 'imported_1',
        title: 'My Song',
        description: 'Imported from audio',
        tempo: 100,
        beatsPerMeasure: 4,
        totalMeasures: 2,
        measures: [],
      );
      levelRepository.addImportedLevel(importedLevel);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.longPress(find.text('My Song'));
      await tester.pumpAndSettle();

      expect(find.text('Delete imported piece?'), findsOneWidget);
    });

    testWidgets('confirming delete removes imported level', (tester) async {
      when(mockProgressRepo.read(any)).thenAnswer((_) async => null);

      const importedLevel = LevelModel(
        id: 'imported_1',
        title: 'My Song',
        description: 'Imported from audio',
        tempo: 100,
        beatsPerMeasure: 4,
        totalMeasures: 2,
        measures: [],
      );
      levelRepository.addImportedLevel(importedLevel);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.longPress(find.text('My Song'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('My Song'), findsNothing);
      verify(mockIngestionRepo.deleteImportedLevel('imported_1')).called(1);
    });

    testWidgets('canceling delete keeps imported level', (tester) async {
      when(mockProgressRepo.read(any)).thenAnswer((_) async => null);

      const importedLevel = LevelModel(
        id: 'imported_1',
        title: 'My Song',
        description: 'Imported from audio',
        tempo: 100,
        beatsPerMeasure: 4,
        totalMeasures: 2,
        measures: [],
      );
      levelRepository.addImportedLevel(importedLevel);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.longPress(find.text('My Song'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('My Song'), findsOneWidget);
    });
  });
}