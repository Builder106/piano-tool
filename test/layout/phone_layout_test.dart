import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:piano_tool/brand/palette.dart';
import 'package:piano_tool/data/ingestion_repository.dart';
import 'package:piano_tool/data/level_repository.dart';
import 'package:piano_tool/home/home_screen.dart';
import 'package:piano_tool/pieces/add_piece_screen.dart';
import 'package:piano_tool/pieces/import_inputs.dart';
import 'package:piano_tool/pieces/pieces_screen.dart';
import 'package:piano_tool/practice/find_notes.dart';
import 'package:piano_tool/practice/practice_screen.dart';
import 'package:piano_tool/services/midi_service.dart';
import 'package:piano_tool/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/fake_midi_transport.dart';

class _NoInputs implements ImportInputs {
  @override
  Future<File?> pickAudioFile() async => null;
  @override
  Future<bool> startRecording() async => true;
  @override
  Future<Uint8List?> stopRecording() async => Uint8List(0);
  @override
  void dispose() {}
}

Future<void> _font(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

/// Every screen has to fit a phone held either way up. An overflow is a
/// framework error, so a screen that does not fit fails its test.
void main() {
  const sizes = {
    'a phone upright': Size(411, 890),
    'a phone on its side': Size(890, 411),
    'a small phone upright': Size(360, 640),
  };
  final screens = <String, Widget Function()>{
    'home': () => Scaffold(
      body: HomeScreen(
        onOpenPiece: (_) {},
        onAddPiece: () async => null,
        onOpenPieces: () {},
        onOpenSettings: () {},
      ),
    ),
    'all pieces': () =>
        PiecesScreen(onOpenPiece: (_) {}, onAddPiece: () async => null),
    'settings': () => const SettingsScreen(),
    'add a piece': () => const AddPieceScreen(),
    'find the notes': () => const FindNotesScreen(stageId: 'stage_1'),
    'practice': () => const PracticeScreen(stageId: 'stage_1'),
  };

  setUpAll(() async {
    await _font(Fonts.ui, 'assets/fonts/AtkinsonHyperlegibleNext.ttf');
    await _font(Fonts.music, 'assets/fonts/Bravura.otf');
  });

  for (final MapEntry(key: where, value: size) in sizes.entries) {
    for (final MapEntry(key: name, value: build) in screens.entries) {
      testWidgets('$name fits $where', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [
            ingestionRepositoryProvider.overrideWith(
              (ref) async => IngestionRepository(
                client: MockClient((_) async => http.Response('', 404)),
                baseUrl: 'http://test.api',
                prefs: prefs,
              ),
            ),
            importInputsProvider.overrideWith((ref) => _NoInputs()),
            midiServiceProvider.overrideWith(
              (ref) => MidiService(transport: FakeMidiTransport([])),
            ),
          ],
        );
        addTearDown(container.dispose);
        await tester.runAsync(
          () => container.read(levelRepositoryProvider.future),
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: ThemeData(fontFamily: Fonts.ui),
              home: build(),
            ),
          ),
        );
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
