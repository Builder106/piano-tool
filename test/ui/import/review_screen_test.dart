import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:piano_tool/data/ingestion_repository.dart';
import 'package:piano_tool/models/level_models.dart';
import 'package:piano_tool/ui/import/review_screen.dart';
import 'package:piano_tool/ui/theme/app_theme.dart';

@GenerateMocks([IngestionRepository])
import 'review_screen_test.mocks.dart';

void main() {
  late MockIngestionRepository mockRepo;

  setUp(() {
    mockRepo = MockIngestionRepository();
  });

  Widget createTestWidget({String jobId = 'job-123'}) {
    return ProviderScope(
      overrides: [
        ingestionRepositoryProvider.overrideWith((ref) async => mockRepo),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/review',
          routes: [
            GoRoute(
              path: '/review',
              builder: (_, __) => ReviewScreen(jobId: jobId),
            ),
            GoRoute(
              path: '/',
              builder: (_, __) => const Scaffold(body: Text('Level list')),
            ),
            GoRoute(
              path: '/import',
              builder: (_, __) => const Scaffold(body: Text('Import screen')),
            ),
          ],
        ),
        theme: PianoTheme.light(),
      ),
    );
  }

  const level = LevelModel(
    id: 'imported_1',
    title: 'My Song',
    description: 'Imported from audio',
    tempo: 100,
    beatsPerMeasure: 4,
    totalMeasures: 2,
    measures: [
      LevelMeasure(
        index: 0,
        startBeat: 0,
        beatsPerMeasure: 4,
        notes: [
          LevelNote(
            midiNote: 60,
            startBeat: 0,
            durationBeats: 1,
            measureIndex: 0,
            beatIndex: 0,
          ),
        ],
      ),
    ],
  );

  group('ReviewScreen', () {
    testWidgets('shows a loading indicator while the job is polled', (tester) async {
      final completer = Completer<IngestionJobResult>();
      when(mockRepo.pollJob('job-123')).thenAnswer((_) => completer.future);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Resolve so nothing is left pending when the test ends.
      completer.complete(
        IngestionJobResult(status: IngestionJobStatus.done, level: level),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('shows the level title and controls once loaded', (tester) async {
      when(mockRepo.pollJob('job-123')).thenAnswer(
        (_) async => IngestionJobResult(status: IngestionJobStatus.done, level: level),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('My Song'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Discard'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Save Level'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('shows an error message when the job failed', (tester) async {
      when(mockRepo.pollJob('job-123')).thenAnswer(
        (_) async => IngestionJobResult(
          status: IngestionJobStatus.failed,
          error: 'Could not transcribe audio',
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not transcribe audio'), findsOneWidget);
    });

    testWidgets('play/pause toggles the icon and advances the playhead',
        (tester) async {
      when(mockRepo.pollJob('job-123')).thenAnswer(
        (_) async => IngestionJobResult(status: IngestionJobStatus.done, level: level),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      expect(find.byIcon(Icons.pause), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progress.value, greaterThan(0));

      // Pause again so no timer keeps firing after the test ends.
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('shows elapsed and total time derived from the level tempo',
        (tester) async {
      // tempo 80 => 60/80 = 0.75s per beat; 8 beats total = 6.0s = "0:06".
      const slowLevel = LevelModel(
        id: 'imported_slow',
        title: 'Slow Song',
        description: 'Imported from audio',
        tempo: 80,
        beatsPerMeasure: 4,
        totalMeasures: 2,
        measures: [],
      );
      when(mockRepo.pollJob('job-123')).thenAnswer(
        (_) async => IngestionJobResult(status: IngestionJobStatus.done, level: slowLevel),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('0:00 / 0:06'), findsOneWidget);
    });

    testWidgets('playback advances the beat according to the level tempo',
        (tester) async {
      // tempo 180 => 180/60 = 3 beats/sec at 1.0x speed.
      const fastLevel = LevelModel(
        id: 'imported_fast',
        title: 'Fast Song',
        description: 'Imported from audio',
        tempo: 180,
        beatsPerMeasure: 4,
        totalMeasures: 2, // totalBeats = 8
        measures: [],
      );
      when(mockRepo.pollJob('job-123')).thenAnswer(
        (_) async => IngestionJobResult(status: IngestionJobStatus.done, level: fastLevel),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // One second of playback at 3 beats/sec should land close to beat 3
      // (of 8 total), not the old fixed 2 beats/sec rate.
      await tester.pump(const Duration(seconds: 1));
      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progress.value, closeTo(3.0 / 8.0, 0.01));

      // Pause so no timer keeps firing after the test ends.
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();
    });

    testWidgets('speed control cycles through the speed steps', (tester) async {
      when(mockRepo.pollJob('job-123')).thenAnswer(
        (_) async => IngestionJobResult(status: IngestionJobStatus.done, level: level),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('1.0x'), findsOneWidget);

      await tester.tap(find.text('1.0x'));
      await tester.pump();

      expect(find.text('1.5x'), findsOneWidget);
    });

    testWidgets('save calls saveLevel and navigates to the level list', (tester) async {
      when(mockRepo.pollJob('job-123')).thenAnswer(
        (_) async => IngestionJobResult(status: IngestionJobStatus.done, level: level),
      );
      when(mockRepo.saveLevel(level)).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Save Level'));
      await tester.pumpAndSettle();

      verify(mockRepo.saveLevel(level)).called(1);
      expect(find.text('Level list'), findsOneWidget);
    });

    testWidgets('shows an error snackbar when save fails', (tester) async {
      when(mockRepo.pollJob('job-123')).thenAnswer(
        (_) async => IngestionJobResult(status: IngestionJobStatus.done, level: level),
      );
      when(mockRepo.saveLevel(level))
          .thenThrow(IngestionException('Failed to save: 500'));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Save Level'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to save'), findsOneWidget);
      // Stayed on the review screen.
      expect(find.text('My Song'), findsOneWidget);
    });

    testWidgets('discard navigates back to the import screen', (tester) async {
      when(mockRepo.pollJob('job-123')).thenAnswer(
        (_) async => IngestionJobResult(status: IngestionJobStatus.done, level: level),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Discard'));
      await tester.pumpAndSettle();

      expect(find.text('Import screen'), findsOneWidget);
      verifyNever(mockRepo.saveLevel(any));
    });
  });
}
