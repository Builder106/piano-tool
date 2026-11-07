import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/data/level_repository.dart';
import 'package:piano_tool/home/strung_geometry.dart';
import 'package:piano_tool/practice/practice_screen.dart';
import 'package:piano_tool/practice/stage_controller.dart';
import 'package:piano_tool/services/midi_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/fake_midi_transport.dart';

void main() {
  testWidgets('practice shows the board controls and speed cycles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final geometry = StrungGeometry.fromJson(
      jsonDecode(File('assets/art/strung/home.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    final container = ProviderContainer(
      overrides: [
        strungGeometryProvider.overrideWith((ref) async => geometry),
        levelRepositoryProvider.overrideWith((ref) async => LevelRepository()),
        midiServiceProvider.overrideWith(
          (ref) => MidiService(transport: FakeMidiTransport([])),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      await container.read(levelRepositoryProvider.future);
      await container.read(strungGeometryProvider.future);
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: PracticeScreen(stageId: 'stage_1', midi: 60),
        ),
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
}
