import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:piano_tool/data/ingestion_repository.dart';
import 'package:piano_tool/data/level_repository.dart';
import 'package:piano_tool/models/level_models.dart';
import 'package:piano_tool/pieces/add_piece_screen.dart';
import 'package:piano_tool/pieces/import_inputs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeInputs implements ImportInputs {
  bool allowed = true;
  int recordings = 0;
  bool disposed = false;

  @override
  Future<File?> pickAudioFile() async => null;

  @override
  Future<bool> startRecording() async => allowed;

  @override
  Future<Uint8List?> stopRecording() async {
    recordings++;
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  void dispose() => disposed = true;
}

class _BrokenInputs extends _FakeInputs {
  @override
  Future<bool> startRecording() async => throw StateError('no recorder');
}

final _level = LevelModel(
  id: 'job-1',
  title: 'recording.wav',
  description: 'Imported',
  tempo: 90,
  beatsPerMeasure: 4,
  totalMeasures: 1,
  measures: [
    LevelMeasure(
      index: 0,
      startBeat: 0,
      beatsPerMeasure: 4,
      notes: [
        for (var i = 0; i < 4; i++)
          LevelNote(
            midiNote: 60 + i,
            startBeat: i.toDouble(),
            durationBeats: 1,
            measureIndex: 0,
            beatIndex: i,
          ),
      ],
    ),
  ],
);

void main() {
  test('only youtube links are accepted', () {
    expect(isYoutubeLink('https://www.youtube.com/watch?v=abc'), isTrue);
    expect(isYoutubeLink('https://youtu.be/abc'), isTrue);
    expect(isYoutubeLink('https://example.com/watch'), isFalse);
    expect(isYoutubeLink('https://notyoutube.com'), isFalse);
    expect(isYoutubeLink('youtube.com'), isFalse);
    expect(isYoutubeLink(''), isFalse);
  });

  Future<(ProviderContainer, SharedPreferences)> open(
    WidgetTester tester, {
    required String jobStatus,
    _FakeInputs? inputs,
  }) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final client = MockClient((request) async {
      if (request.method == 'POST') {
        return http.Response('{"job_id": "job-1"}', 202);
      }
      return http.Response(
        jsonEncode({
          'status': jobStatus,
          if (jobStatus == 'done') 'level': _level.toJson(),
          if (jobStatus == 'failed') 'error': 'No notes detected',
        }),
        200,
      );
    });
    final repo = IngestionRepository(
      client: client,
      baseUrl: 'http://test.api',
      prefs: prefs,
    );
    final container = ProviderContainer(
      overrides: [
        ingestionRepositoryProvider.overrideWith((ref) async => repo),
        importInputsProvider.overrideWith((ref) {
          final fake = inputs ?? _FakeInputs();
          ref.onDispose(fake.dispose);
          return fake;
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<String>(
                    builder: (_) => const AddPieceScreen(
                      pollEvery: Duration(milliseconds: 10),
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return (container, prefs);
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(milliseconds: 30));
    }
  }

  testWidgets('the recorder stays alive while the screen is open', (
    tester,
  ) async {
    final inputs = _FakeInputs();
    await open(tester, jobStatus: 'done', inputs: inputs);

    await tester.tap(find.text('Start recording'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(inputs.disposed, isFalse);
  });

  testWidgets('a recording becomes a piece you can name and keep', (
    tester,
  ) async {
    final (container, prefs) = await open(tester, jobStatus: 'done');
    await container.read(ingestionRepositoryProvider.future);

    expect(find.text('Make the piece'), findsWidgets);
    await tester.tap(find.text('Start recording'));
    await tester.pump();
    expect(find.text('Recording. Play the piece, then press Stop.'), findsOne);
    await tester.tap(find.text('Stop'));
    await tester.pump();
    await tester.tap(find.text('Make the piece'));
    await tester.pump();
    await settle(tester);

    expect(find.text('Is this your piece?'), findsOne);
    expect(
      find.text(
        '4 notes in 1 bar. If it looks wrong, throw it away '
        'and play it again, slower.',
      ),
      findsOne,
    );

    await tester.enterText(find.byType(TextField), 'Warm up');
    await tester.tap(find.text('Keep it'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pumpAndSettle();

    final saved = jsonDecode(prefs.getString('ingestion.levels')!) as Map;
    expect((saved['job-1'] as Map)['title'], 'Warm up');
    final repo = await container.read(levelRepositoryProvider.future);
    expect(repo.getAllStages().last.title, 'Warm up');
  });

  testWidgets('a failed job says so and offers another go', (tester) async {
    await open(tester, jobStatus: 'failed');
    await tester.tap(find.text('YouTube link'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'https://youtu.be/abc');
    await tester.pump();
    await tester.tap(find.text('Make the piece'));
    await tester.pump();
    await settle(tester);

    expect(find.text('That did not work'), findsOne);
    expect(find.text('No notes detected'), findsOne);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(find.text('How will you show it?'), findsOne);
  });

  testWidgets('a refused microphone is explained', (tester) async {
    await open(
      tester,
      jobStatus: 'done',
      inputs: _FakeInputs()..allowed = false,
    );
    await tester.tap(find.text('Start recording'));
    await tester.pump();
    expect(find.textContaining('The microphone is not allowed'), findsOne);
  });

  testWidgets('a recorder that breaks is explained, not silent', (
    tester,
  ) async {
    await open(tester, jobStatus: 'done', inputs: _BrokenInputs());
    await tester.tap(find.text('Start recording'));
    await tester.pump();
    expect(find.textContaining('The recording did not work'), findsOne);
    expect(find.text('Start recording'), findsOne);
  });
}
