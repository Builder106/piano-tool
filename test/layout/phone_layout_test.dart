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
import 'package:piano_tool/practice/keys.dart';
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
  // A phone's window includes its status and navigation bars, which take
  // height or width away from the app.
  const noBars = FakeViewPadding.zero;
  const barsOnItsSide = FakeViewPadding(top: 28, right: 52);
  const sizes = {
    'a phone upright': (Size(411, 890), noBars),
    'a phone on its side': (Size(890, 411), noBars),
    'a small phone upright': (Size(360, 640), noBars),
    'a phone on its side with system bars': (Size(832, 384), barsOnItsSide),
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

  Future<void> show(
    WidgetTester tester,
    String name,
    (Size, FakeViewPadding) window,
  ) async {
    tester.view.physicalSize = window.$1;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = window.$2;
    tester.view.viewPadding = window.$2;
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
    await tester.runAsync(() => container.read(levelRepositoryProvider.future));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(fontFamily: Fonts.ui),
          home: screens[name]!(),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  for (final MapEntry(key: where, value: window) in sizes.entries) {
    for (final name in screens.keys) {
      testWidgets('$name fits $where', (tester) async {
        await show(tester, name, window);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  // Fitting is not enough: the part that matters has to be in view without
  // scrolling. Both of these were cut off on a real phone on its side.
  testWidgets('Find the notes shows its letters above the keys', (
    tester,
  ) async {
    await show(tester, 'find the notes', sizes.values.last);
    final keysTop = tester.getTopLeft(find.byType(PaperKeyboard)).dy;
    for (final letter in ['C', 'D', 'E']) {
      expect(tester.getRect(find.text(letter).first).bottom, lessThan(keysTop));
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Home shows Start without scrolling on a short screen', (
    tester,
  ) async {
    final window = sizes.values.last;
    await show(tester, 'home', window);
    final start = tester.getRect(find.text('Start').first);
    expect(start.bottom, lessThan(window.$1.height));
    await tester.pumpWidget(const SizedBox());
  });
}
