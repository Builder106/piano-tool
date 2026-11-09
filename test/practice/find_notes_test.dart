import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/data/level_repository.dart';
import 'package:piano_tool/models/audio_models.dart';
import 'package:piano_tool/practice/find_notes.dart';
import 'package:piano_tool/services/midi_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/fake_midi_transport.dart';

PitchEvent _heard(int midi, {bool struck = false}) => PitchEvent(
  frequency: 440,
  confidence: 0.9,
  midiNote: midi,
  timestamp: 0,
  volume: 0.5,
  struck: struck,
);

void main() {
  final stages = LevelRepository().getAllStages();

  test('a piece asks for its first three different notes', () {
    expect(notesToFind(stages[0].level), [60, 62, 64]);
    expect(notesToFind(stages[1].level), [64, 65, 67]);
    expect(notesToFind(stages[0].level, count: 2), [60, 62]);
  });

  test('notes are listed in plain words', () {
    expect(listNotes([60]), 'C');
    expect(listNotes([60, 64]), 'C and E');
    expect(listNotes([60, 64, 67]), 'C, E and G');
    expect(listNotes([61, 64]), 'C sharp and E');
  });

  test('a key strike must be the exact key, in any order', () {
    final f = NoteFinder([60, 64, 67]);
    expect(f.feed(_heard(72, struck: true)), isNull, reason: 'wrong octave');
    expect(f.feed(_heard(67, struck: true)), 67);
    expect(f.feed(_heard(67, struck: true)), isNull, reason: 'already found');
    expect(f.feed(_heard(61, struck: true)), isNull);
    expect(f.done, isFalse);
    f.feed(_heard(60, struck: true));
    f.feed(_heard(64, struck: true));
    expect(f.done, isTrue);
  });

  test('the microphone needs the same note name twice, in any octave', () {
    final f = NoteFinder([60, 64]);
    expect(f.feed(_heard(72)), isNull, reason: 'one frame is not enough');
    expect(f.feed(_heard(72)), 60);
    expect(f.feed(_heard(64)), isNull);
    expect(f.feed(_heard(62)), isNull, reason: 'a different note resets it');
    expect(f.feed(_heard(64)), isNull);
    expect(f.feed(_heard(64)), 64);
    expect(f.done, isTrue);
  });

  testWidgets('the step names the notes and waits to listen', (tester) async {
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
        child: const MaterialApp(home: FindNotesScreen(stageId: 'stage_1')),
      ),
    );
    await tester.pump();

    expect(find.text('Find C, D and E.'), findsOneWidget);
    expect(find.text('Start listening'), findsWidgets);
    expect(find.text('Skip'), findsWidgets);
    expect(find.text('Play the tune'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
