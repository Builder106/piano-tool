import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:piano_tool/data/ingestion_repository.dart';
import 'package:piano_tool/models/level_models.dart';
import 'package:piano_tool/ui/levels/level_list_screen.dart';
import 'package:piano_tool/ui/theme/app_theme.dart';

/// Exercises the seam the final whole-branch review flagged as untested:
/// every other test stubs either IngestionRepository or LevelRepository, so
/// nothing proved that a level saved through IngestionRepository actually
/// shows up in LevelListScreen. This test uses the real (shared_preferences
/// backed) IngestionRepository and the real LevelRepository -- no mocks for
/// either -- so it fails if the two are ever wired apart again.
void main() {
  const level = LevelModel(
    id: 'imported_integration_1',
    title: 'Integration Song',
    description: 'Imported from audio',
    tempo: 100,
    beatsPerMeasure: 4,
    totalMeasures: 2,
    measures: [],
  );

  Widget createTestWidget(IngestionRepository ingestionRepository) {
    return ProviderScope(
      overrides: [
        // Only IngestionRepository's provider is overridden, to swap the
        // real http.Client for one that can't hit a network in tests -- the
        // repository itself, and levelRepositoryProvider's hydration logic,
        // are the real production code.
        ingestionRepositoryProvider.overrideWith((ref) async => ingestionRepository),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, __) => const LevelListScreen()),
            GoRoute(
              path: '/import',
              builder: (_, __) => const Scaffold(body: Text('Import Screen')),
            ),
            GoRoute(
              path: '/practice/:stageId',
              builder: (_, state) =>
                  Scaffold(body: Text('Practice: ${state.pathParameters['stageId']}')),
            ),
          ],
        ),
        theme: PianoTheme.light(),
      ),
    );
  }

  testWidgets(
      'a level saved via IngestionRepository appears in LevelListScreen on next load',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final ingestionRepository = IngestionRepository(
      client: MockClient((request) async => http.Response('Not found', 404)),
      baseUrl: 'http://test.api',
      prefs: prefs,
    );

    // This is the save half of the seam: what ReviewScreen._saveLevel calls
    // after a successful transcription.
    await ingestionRepository.saveLevel(level);

    // This is the display half: LevelListScreen reads levelRepositoryProvider,
    // which must hydrate from IngestionRepository.listImportedLevels() on
    // its own for the saved level to appear here.
    await tester.pumpWidget(createTestWidget(ingestionRepository));
    await tester.pumpAndSettle();

    expect(find.text('Integration Song'), findsOneWidget);
    expect(find.text('Imported'), findsOneWidget);
  });

  testWidgets('deleting an imported level removes it from IngestionRepository storage too',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final ingestionRepository = IngestionRepository(
      client: MockClient((request) async => http.Response('Not found', 404)),
      baseUrl: 'http://test.api',
      prefs: prefs,
    );
    await ingestionRepository.saveLevel(level);

    await tester.pumpWidget(createTestWidget(ingestionRepository));
    await tester.pumpAndSettle();
    expect(find.text('Integration Song'), findsOneWidget);

    await tester.longPress(find.text('Integration Song'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Integration Song'), findsNothing);

    // The persisted store must agree, or the level would reappear the next
    // time levelRepositoryProvider rehydrates from it.
    final remaining = await ingestionRepository.listImportedLevels();
    expect(remaining, isEmpty);
  });
}
