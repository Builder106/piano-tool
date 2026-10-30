import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:piano_tool/data/settings_repository.dart';
import 'package:piano_tool/services/midi_service.dart';
import 'package:piano_tool/ui/practice/mic_permission_gate.dart';
import 'package:piano_tool/ui/practice/stage_controller.dart';
import 'package:piano_tool/ui/theme/app_theme.dart';

import '../../services/fake_midi_transport.dart';

Widget _harness(Future<bool> Function(Ref) grant) => ProviderScope(
  overrides: [audioGrantedProvider.overrideWith(grant)],
  child: MaterialApp(
    theme: PianoTheme.light(),
    home: const Scaffold(body: MicPermissionGate(child: Text('practice'))),
  ),
);

void main() {
  testWidgets('new learners choose an input before microphone permission', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var requested = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(
            () => SettingsNotifier(
              initialSettings: const AppSettings(inputConfigured: false),
            ),
          ),
          audioGrantedProvider.overrideWith((ref) async {
            requested = true;
            return true;
          }),
          practiceAudioSessionProvider.overrideWith((ref) async {}),
        ],
        child: MaterialApp(
          theme: PianoTheme.light(),
          home: const Scaffold(
            body: MicPermissionGate(startAudio: true, child: Text('practice')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('How will you play?'), findsOneWidget);
    expect(requested, isFalse);
    await tester.tap(find.text('Use microphone'));
    await tester.pumpAndSettle();
    expect(requested, isTrue);
    expect((await SettingsRepository().read()).inputConfigured, isTrue);
    // Permission is not proof of hearing: the unscored check comes next.
    expect(find.text('Play middle C'), findsOneWidget);
    expect(find.text('practice'), findsNothing);
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();
    expect(find.text('practice'), findsOneWidget);
  });

  group('input check', () {
    Widget checked({
      required PracticeInputSource source,
      String? verifiedInput,
      MidiService? midi,
    }) => ProviderScope(
      overrides: [
        settingsProvider.overrideWith(
          () => SettingsNotifier(
            initialSettings: AppSettings(
              inputSource: source,
              verifiedInput: verifiedInput,
            ),
          ),
        ),
        audioGrantedProvider.overrideWith((ref) async => true),
        practiceAudioSessionProvider.overrideWith((ref) async {}),
        if (midi != null) midiServiceProvider.overrideWith((ref) => midi),
      ],
      child: MaterialApp(
        theme: PianoTheme.light(),
        home: const Scaffold(
          body: MicPermissionGate(startAudio: true, child: Text('practice')),
        ),
      ),
    );

    testWidgets('a checked setup goes straight to practice', (tester) async {
      await tester.pumpWidget(
        checked(
          source: PracticeInputSource.microphone,
          verifiedInput: 'microphone',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('practice'), findsOneWidget);
    });

    testWidgets('a MIDI note-on for middle C passes the check', (tester) async {
      SharedPreferences.setMockInitialValues({});
      // The provider owns and disposes the service.
      final midi = MidiService(transport: FakeMidiTransport(const []));
      await tester.pumpWidget(
        checked(source: PracticeInputSource.midi, midi: midi),
      );
      await tester.pump();
      expect(find.text('Play middle C'), findsOneWidget);

      midi.simulateNotePress(64);
      await tester.pump();
      expect(find.textContaining('That was E4'), findsOneWidget);

      midi.simulateNotePress(60);
      await tester.pump();
      expect(find.text('Middle C, heard'), findsOneWidget);
      await tester.tap(find.text('Start practising'));
      await tester.pumpAndSettle();
      expect(find.text('practice'), findsOneWidget);
      expect((await SettingsRepository().read()).verifiedInput, 'midi');
    });

    testWidgets('changing the input source checks again', (tester) async {
      await tester.pumpWidget(
        checked(source: PracticeInputSource.both, verifiedInput: 'microphone'),
      );
      await tester.pump();
      expect(find.text('Play middle C'), findsOneWidget);
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();
      expect(find.text('practice'), findsOneWidget);
    });
  });

  testWidgets('recording still requires a microphone in MIDI mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(
            () => SettingsNotifier(
              initialSettings: const AppSettings(
                inputSource: PracticeInputSource.midi,
              ),
            ),
          ),
          audioGrantedProvider.overrideWith((ref) async => false),
        ],
        child: MaterialApp(
          theme: PianoTheme.light(),
          home: const Scaffold(
            body: MicPermissionGate(child: Text('recording')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No microphone'), findsOneWidget);
    expect(find.text('recording'), findsNothing);
  });

  testWidgets('MIDI-only practice skips microphone permission', (tester) async {
    var requested = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(
            () => SettingsNotifier(
              initialSettings: const AppSettings(
                inputSource: PracticeInputSource.midi,
              ),
            ),
          ),
          audioGrantedProvider.overrideWith((ref) async {
            requested = true;
            return false;
          }),
        ],
        child: MaterialApp(
          theme: PianoTheme.light(),
          home: const Scaffold(
            body: MicPermissionGate(startAudio: true, child: Text('practice')),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Play middle C'), findsOneWidget);
    expect(requested, isFalse);
  });

  testWidgets('shows the child once the microphone is granted', (tester) async {
    await tester.pumpWidget(_harness((ref) async => true));
    await tester.pumpAndSettle();
    expect(find.text('practice'), findsOneWidget);
  });

  testWidgets('explains the problem and offers a retry when denied', (
    tester,
  ) async {
    await tester.pumpWidget(_harness((ref) async => false));
    await tester.pumpAndSettle();

    expect(find.text('practice'), findsNothing);
    expect(find.textContaining('microphone'), findsWidgets);
    expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);
  });

  testWidgets('surfaces a failure instead of hanging', (tester) async {
    await tester.pumpWidget(
      _harness((ref) async => throw Exception('no device')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('microphone'), findsWidgets);
  });

  testWidgets('shows progress while the request is outstanding', (
    tester,
  ) async {
    final completer = Completer<bool>();
    await tester.pumpWidget(_harness((ref) => completer.future));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('practice'), findsOneWidget);
  });

  testWidgets('a retry after a denial actually recovers', (tester) async {
    // The gate must not latch on its error state: a learner who grants the
    // permission from system settings and comes back has to get in.
    var attempt = 0;
    await tester.pumpWidget(_harness((ref) async => attempt++ > 0));
    await tester.pumpAndSettle();
    expect(find.text('practice'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Try again'));
    await tester.pumpAndSettle();
    expect(find.text('practice'), findsOneWidget);
  });
}
