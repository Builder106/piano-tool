import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/data/level_repository.dart';
import 'package:piano_tool/data/settings_repository.dart';
import 'package:piano_tool/models/level_models.dart';
import 'package:piano_tool/practice/keys.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/practice/practice_screen.dart';
import 'package:piano_tool/practice/stage_controller.dart';
import 'package:piano_tool/services/midi_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/fake_midi_transport.dart';

void main() {
  testWidgets('practice shows its controls and speed cycles', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        levelRepositoryProvider.overrideWith((ref) async => LevelRepository()),
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
        child: const MaterialApp(home: PracticeScreen(stageId: 'stage_1')),
      ),
    );
    await tester.pump();

    expect(find.text('Back'), findsWidgets);
    expect(find.text('Start'), findsWidgets);
    expect(find.text('Speed 100%'), findsWidgets);

    await tester.tap(find.text('Speed 100%').first);
    await tester.pump();
    expect(
      container.read(stageControllerProvider('stage_1')).speed,
      closeTo(0.75, 0.001),
    );
    expect(find.text('Speed 75%'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('with on-screen keys Start begins at once, with no check', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        levelRepositoryProvider.overrideWith((ref) async => LevelRepository()),
        settingsProvider.overrideWith(
          () => SettingsNotifier(
            initialSettings: const AppSettings(
              inputSource: PracticeInputSource.touch,
            ),
          ),
        ),
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
        child: const MaterialApp(home: PracticeScreen(stageId: 'stage_1')),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Start').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Play middle C'), findsNothing);
    expect(
      container.read(stageControllerProvider('stage_1')).status,
      StageEngineStatus.playing,
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the marked page takes the whole screen, with no keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(890, 411);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    // Ten beats a second, so the piece is over in about half a second.
    const quick = LevelModel(
      id: 'quick',
      title: 'Quick',
      description: '',
      tempo: 600,
      beatsPerMeasure: 4,
      totalMeasures: 1,
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
    final repository = LevelRepository()..addImportedLevel(quick);
    final container = ProviderContainer(
      overrides: [
        levelRepositoryProvider.overrideWith((ref) async => repository),
        settingsProvider.overrideWith(
          () => SettingsNotifier(
            initialSettings: const AppSettings(
              inputSource: PracticeInputSource.touch,
            ),
          ),
        ),
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
        child: const MaterialApp(
          home: PracticeScreen(stageId: 'imported_quick'),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Start').first);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Play again'), findsWidgets);
    expect(find.byType(PaperKeyboard), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
