import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:piano_tool/data/ingestion_repository.dart';
import 'package:piano_tool/data/level_repository.dart';
import 'package:piano_tool/home/home_screen.dart';
import 'package:piano_tool/models/level_models.dart';
import 'package:piano_tool/pieces/pieces_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('lists every piece and removes one you added', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = IngestionRepository(
      client: MockClient((_) async => http.Response('', 404)),
      baseUrl: 'http://test.api',
      prefs: prefs,
    );
    await repo.saveLevel(
      const LevelModel(
        id: 'mine',
        title: 'My tune',
        description: 'Imported',
        tempo: 90,
        beatsPerMeasure: 4,
        totalMeasures: 0,
        measures: [],
      ),
    );
    final container = ProviderContainer(
      overrides: [
        ingestionRepositoryProvider.overrideWith((ref) async => repo),
      ],
    );
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(levelRepositoryProvider.future));

    Piece? opened;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: PiecesScreen(onOpenPiece: (p) => opened = p)),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(find.text('C Major Scale'), findsOne);
    expect(find.text('My tune'), findsOne);
    expect(find.text('Remove'), findsOne, reason: 'only the added piece');
    expect(find.text('Add your own piece'), findsNothing);

    await tester.tap(find.text('C Major Scale'));
    expect(opened?.stage.title, 'C Major Scale');

    await tester.tap(find.text('Remove'));
    await tester.pump();
    expect(find.text('Remove My tune?'), findsOne);
    await tester.tap(find.text('Keep it'));
    await tester.pump();
    expect(find.text('My tune'), findsOne);

    await tester.tap(find.text('Remove'));
    await tester.pump();
    await tester.tap(find.text('Remove').last);
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }

    expect(await repo.listImportedLevels(), isEmpty);
    expect(find.text('My tune'), findsNothing);
  });
}
