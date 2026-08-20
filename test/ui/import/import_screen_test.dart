import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:piano_tool/data/ingestion_repository.dart';
import 'package:piano_tool/models/level_models.dart';
import 'package:piano_tool/ui/import/import_screen.dart';
import 'package:piano_tool/ui/practice/stage_controller.dart';
import 'package:piano_tool/ui/theme/app_theme.dart';

@GenerateMocks([IngestionRepository])
import 'import_screen_test.mocks.dart';

void main() {
  late MockIngestionRepository mockRepo;

  setUp(() {
    mockRepo = MockIngestionRepository();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        ingestionRepositoryProvider.overrideWith((ref) async => mockRepo),
        audioGrantedProvider.overrideWith((ref) async => true),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const ImportScreen(),
            ),
            GoRoute(
              path: '/review',
              builder: (_, state) => Scaffold(
                body: Text('Review: ${state.uri.queryParameters['jobId']}'),
              ),
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
    measures: [],
  );

  group('ImportScreen', () {
    testWidgets('shows all three source options', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('File'), findsOneWidget);
      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('Record'), findsOneWidget);
    });

    testWidgets('defaults to the file source with submit disabled', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Pick Audio File'), findsOneWidget);

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Submit'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('selecting YouTube reveals the URL field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('YouTube'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'YouTube URL'), findsOneWidget);
    });

    testWidgets('submit is disabled until a YouTube URL is entered', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('YouTube'));
      await tester.pumpAndSettle();

      var button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Submit'),
      );
      expect(button.onPressed, isNull);

      await tester.enterText(
        find.widgetWithText(TextField, 'YouTube URL'),
        'https://youtube.com/watch?v=abc',
      );
      await tester.pumpAndSettle();

      button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Submit'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('submitting a YouTube URL polls and navigates to ReviewScreen on success',
        (tester) async {
      when(mockRepo.submitYoutubeUrl(any)).thenAnswer((_) async => 'job-123');
      when(mockRepo.pollJob('job-123')).thenAnswer(
        (_) async => IngestionJobResult(
          status: IngestionJobStatus.done,
          level: level,
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('YouTube'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'YouTube URL'),
        'https://youtube.com/watch?v=abc',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await tester.pump();
      await tester.pump();

      // Polling status is visible while the job is in flight.
      expect(find.textContaining('Queued'), findsOneWidget);

      // Let the periodic poll timer fire and resolve.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Review: job-123'), findsOneWidget);
      verify(mockRepo.submitYoutubeUrl('https://youtube.com/watch?v=abc')).called(1);
    });

    testWidgets('progresses through downloading and transcribing before done',
        (tester) async {
      when(mockRepo.submitYoutubeUrl(any)).thenAnswer((_) async => 'job-789');

      // The repository is polled repeatedly; return a different stage on
      // each call so the test can assert the UI actually reflects each one,
      // rather than a static message for the whole job lifecycle.
      final statuses = [
        IngestionJobStatus.downloading,
        IngestionJobStatus.transcribing,
        IngestionJobStatus.done,
      ];
      var pollCount = 0;
      when(mockRepo.pollJob('job-789')).thenAnswer((_) async {
        final status = statuses[pollCount.clamp(0, statuses.length - 1)];
        pollCount++;
        return IngestionJobResult(
          status: status,
          level: status == IngestionJobStatus.done ? level : null,
        );
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('YouTube'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'YouTube URL'),
        'https://youtube.com/watch?v=abc',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Queued'), findsOneWidget);

      // First poll tick: downloading.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(find.textContaining('Downloading'), findsOneWidget);

      // Second poll tick: transcribing.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(find.textContaining('Transcribing'), findsOneWidget);

      // Third poll tick: done, navigates away.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Review: job-789'), findsOneWidget);
    });

    testWidgets('shows an error and resets when the job fails', (tester) async {
      when(mockRepo.submitYoutubeUrl(any)).thenAnswer((_) async => 'job-456');
      when(mockRepo.pollJob('job-456')).thenAnswer(
        (_) async => IngestionJobResult(
          status: IngestionJobStatus.failed,
          error: 'Could not transcribe audio',
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('YouTube'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'YouTube URL'),
        'https://youtube.com/watch?v=abc',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Could not transcribe audio'), findsOneWidget);
      // Back at the source picker with the retry option (submit re-enabled).
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Submit'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('shows an error when the submission itself throws', (tester) async {
      when(mockRepo.submitYoutubeUrl(any))
          .thenThrow(IngestionException('Failed to submit YouTube URL: 500'));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('YouTube'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'YouTube URL'),
        'https://youtube.com/watch?v=abc',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to submit YouTube URL: 500'), findsOneWidget);
    });

    testWidgets('shows a validation error for a non-YouTube URL and does not submit',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('YouTube'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'YouTube URL'),
        'https://example.com/not-youtube',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a youtube.com or youtu.be URL'), findsOneWidget);
      verifyNever(mockRepo.submitYoutubeUrl(any));
    });

    testWidgets('accepts a youtu.be short URL', (tester) async {
      when(mockRepo.submitYoutubeUrl(any)).thenAnswer((_) async => 'job-short');
      when(mockRepo.pollJob('job-short')).thenAnswer(
        (_) async => IngestionJobResult(status: IngestionJobStatus.done, level: level),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('YouTube'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'YouTube URL'),
        'https://youtu.be/abc123',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Queued'), findsOneWidget);
      verify(mockRepo.submitYoutubeUrl('https://youtu.be/abc123')).called(1);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pumpAndSettle();
    });

    testWidgets('cancel button stops polling and calls cancelJob', (tester) async {
      when(mockRepo.submitYoutubeUrl(any)).thenAnswer((_) async => 'job-cancel');
      when(mockRepo.pollJob('job-cancel')).thenAnswer(
        (_) async => IngestionJobResult(status: IngestionJobStatus.queued),
      );
      when(mockRepo.cancelJob('job-cancel')).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('YouTube'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'YouTube URL'),
        'https://youtube.com/watch?v=abc',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verify(mockRepo.cancelJob('job-cancel')).called(1);
      // Back at the submit button, not stuck on the polling view.
      expect(find.widgetWithText(FilledButton, 'Submit'), findsOneWidget);
    });

    testWidgets('polling times out and shows an error after the deadline', (tester) async {
      when(mockRepo.submitYoutubeUrl(any)).thenAnswer((_) async => 'job-timeout');
      when(mockRepo.pollJob('job-timeout')).thenAnswer(
        (_) async => IngestionJobResult(status: IngestionJobStatus.queued),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('YouTube'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'YouTube URL'),
        'https://youtube.com/watch?v=abc',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await tester.pump();
      await tester.pump();

      // Advance well past the 5-minute polling deadline.
      await tester.pump(const Duration(minutes: 6));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Transcription timed out. Please try again.'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Submit'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('record source is gated behind MicPermissionGate', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Record'));
      await tester.pumpAndSettle();

      expect(find.text('Start Recording'), findsOneWidget);
    });

    testWidgets('record source shows the denied state when the mic is unavailable',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ingestionRepositoryProvider.overrideWith((ref) async => mockRepo),
            audioGrantedProvider.overrideWith((ref) async => false),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(path: '/', builder: (_, __) => const ImportScreen()),
              ],
            ),
            theme: PianoTheme.light(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Record'));
      await tester.pumpAndSettle();

      expect(find.text('No microphone'), findsOneWidget);
      expect(find.text('Start Recording'), findsNothing);
    });
  });
}
