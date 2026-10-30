import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:piano_tool/data/settings_repository.dart';
import 'package:piano_tool/services/midi_service.dart';
import 'package:piano_tool/ui/practice/stage_controller.dart';
import 'package:piano_tool/ui/settings/settings_screen.dart';
import 'package:piano_tool/ui/theme/app_theme.dart';

import '../../services/fake_midi_transport.dart';

class FakeSettingsNotifier extends SettingsNotifier {
  FakeSettingsNotifier(this._initial);
  final AppSettings _initial;

  @override
  AppSettings build() => _initial;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
  }

  @override
  Future<void> setDefaultSpeed(double speed) async {
    state = state.copyWith(defaultPlaybackSpeed: speed);
  }

  @override
  Future<void> setToleranceLevel(ToleranceLevel level) async {
    state = state.copyWith(toleranceLevel: level);
  }

  @override
  Future<void> setInputSource(PracticeInputSource source) async {
    state = state.copyWith(inputSource: source);
  }

  @override
  Future<void> setVerifiedInput(String? key) async {
    state = state.copyWith(verifiedInput: key, clearVerifiedInput: key == null);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildSubject({
    bool micGranted = true,
    AppSettings initialSettings = const AppSettings(),
  }) {
    return ProviderScope(
      overrides: [
        audioGrantedProvider.overrideWith((ref) async => micGranted),
        midiServiceProvider.overrideWith(
          (ref) => MidiService(
            transport: FakeMidiTransport(const [
              MidiDevice(
                id: 'usb-1',
                name: 'Digital Piano',
                type: MidiDeviceType.usb,
              ),
            ]),
          ),
        ),
        settingsProvider.overrideWith(
          () => FakeSettingsNotifier(initialSettings),
        ),
      ],
      child: MaterialApp(
        theme: PianoTheme.light(),
        darkTheme: PianoTheme.dark(),
        home: const SettingsScreen(),
      ),
    );
  }

  group('SettingsScreen', () {
    testWidgets('renders the desk header and a way back', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(
        find.text('How practice plays and how Piano Tool hears you'),
        findsOneWidget,
      );
      expect(find.byTooltip('Back'), findsOneWidget);
    });

    testWidgets('the lamp choices set the theme', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Lamp'), findsOneWidget);
      expect(find.text('Follow the device'), findsOneWidget);
      expect(find.text('Bright'), findsOneWidget);

      await tester.ensureVisible(find.text('Low'));
      await tester.tap(find.text('Low'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
      );
      expect(container.read(settingsProvider).themeMode, ThemeMode.dark);
    });

    testWidgets('the starting speed choices set the default speed', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Starting speed'), findsOneWidget);
      expect(find.text('1.0x'), findsOneWidget);

      await tester.tap(find.text('0.75x'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
      );
      expect(container.read(settingsProvider).defaultPlaybackSpeed, 0.75);
    });

    testWidgets('the timing choices set the tolerance level', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Timing'), findsOneWidget);
      expect(find.text('Relaxed'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Strict'), findsOneWidget);

      await tester.ensureVisible(find.text('Strict'));
      await tester.tap(find.text('Strict'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
      );
      expect(
        container.read(settingsProvider).toleranceLevel,
        ToleranceLevel.strict,
      );
    });

    testWidgets('permission alone does not claim the piano was heard', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(micGranted: true));
      await tester.pumpAndSettle();

      expect(find.text('Microphone'), findsWidgets);
      expect(find.textContaining('On.'), findsNothing);
      expect(find.textContaining('has heard'), findsNothing);
      expect(find.textContaining('Allowed.'), findsOneWidget);
    });

    testWidgets('says plainly once the input check heard the piano', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          micGranted: true,
          initialSettings: const AppSettings(
            inputSource: PracticeInputSource.microphone,
            verifiedInput: 'microphone',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('On. Piano Tool has heard your piano.'), findsOneWidget);
    });

    testWidgets('says plainly when the microphone is off', (tester) async {
      await tester.pumpWidget(buildSubject(micGranted: false));
      await tester.pumpAndSettle();

      expect(
        find.text('Off. Allow the microphone so Piano Tool can hear you play.'),
        findsOneWidget,
      );
    });

    testWidgets('shows no engine or server internals to a learner', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.textContaining('YIN'), findsNothing);
      expect(find.textContaining('ONNX'), findsNothing);
      expect(find.textContaining('MIDI'), findsNothing);
    });

    testWidgets('the listen-with choices switch the input source', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Listen with'), findsOneWidget);
      expect(find.text('Both'), findsOneWidget);

      final choice = find.text('Digital piano');
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
      );
      expect(
        container.read(settingsProvider).inputSource,
        PracticeInputSource.midi,
      );
    });

    testWidgets('finds, connects and tests a digital piano', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Digital piano (USB or Bluetooth)'), findsOneWidget);
      expect(
        find.text('Plug in or pair your digital piano, then press Look again.'),
        findsOneWidget,
      );
      expect(find.text('Connect'), findsNothing);

      final look = find.text('Look again');
      await tester.ensureVisible(look);
      await tester.tap(look);
      await tester.pumpAndSettle();

      expect(find.text('Digital Piano'), findsOneWidget);

      await tester.ensureVisible(find.text('Connect').first);
      await tester.tap(find.text('Connect').first);
      await tester.pumpAndSettle();

      expect(find.text('Disconnect'), findsOneWidget);

      await tester.ensureVisible(find.text('Test with middle C'));
      await tester.tap(find.text('Test with middle C'));
      await tester.pump();

      expect(find.text('Sent a test middle C'), findsOneWidget);
    });
  });
}
