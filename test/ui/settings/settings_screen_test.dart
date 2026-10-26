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
    testWidgets('renders header, title, and subtitle', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Settings & Calibration'), findsOneWidget);
      expect(
        find.text(
          'Practice preferences, timing accuracy, and audio diagnostics',
        ),
        findsOneWidget,
      );
      expect(find.byTooltip('Back to library'), findsOneWidget);
    });

    testWidgets('renders appearance theme options and reacts to selection', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('System Default'), findsOneWidget);
      expect(find.text('Recital Light'), findsOneWidget);
      expect(find.text('Recital Dark'), findsOneWidget);

      await tester.tap(find.text('Recital Dark'));
      await tester.pumpAndSettle();

      // State updated
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
      );
      expect(container.read(settingsProvider).themeMode, ThemeMode.dark);
    });

    testWidgets('renders practice speed options and updates default speed', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Default Practice Tempo'), findsOneWidget);
      expect(find.text('1.0x'), findsWidgets); // Pill + header text

      await tester.tap(find.text('0.75x'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
      );
      expect(container.read(settingsProvider).defaultPlaybackSpeed, 0.75);
    });

    testWidgets(
      'renders scoring timing tolerance and updates tolerance level',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        expect(find.text('Scoring Timing Accuracy'), findsOneWidget);
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
      },
    );

    testWidgets('displays granted microphone status when mic is enabled', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(micGranted: true));
      await tester.pumpAndSettle();

      expect(find.text('Microphone Permission'), findsOneWidget);
      expect(
        find.text('Microphone access granted. Ready for pitch listening.'),
        findsOneWidget,
      );
    });

    testWidgets('displays denied microphone status when mic is not granted', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(micGranted: false));
      await tester.pumpAndSettle();

      expect(find.text('Microphone Permission'), findsOneWidget);
      expect(
        find.text('Permission not granted. Notes cannot be heard.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'displays audio engine and backend architecture specifications',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        expect(find.text('Pitch Detection Parameters'), findsOneWidget);
        expect(find.text('Persistent Audio Ingestion Service'), findsOneWidget);
        expect(
          find.text('Spotify Basic Pitch (ONNX Runtime CPU)'),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders input source selector and switches input source', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Practice Input Source'), findsOneWidget);
      expect(find.text('Dual Input'), findsWidgets);
      expect(find.text('MIDI Keyboard'), findsWidgets);

      final buttonFinder = find.widgetWithText(OutlinedButton, 'MIDI Keyboard');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
      );
      expect(
        container.read(settingsProvider).inputSource,
        PracticeInputSource.midi,
      );
    });

    testWidgets('renders MIDI hardware card and simulates key press', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('MIDI Keyboard (USB & Bluetooth)'), findsOneWidget);
      expect(find.text('Connect a keyboard, then press Scan.'), findsOneWidget);
      expect(find.text('Connect'), findsNothing);

      final scan = find.text('Scan');
      await tester.ensureVisible(scan);
      await tester.tap(scan);
      await tester.pumpAndSettle();

      expect(find.text('Digital Piano'), findsOneWidget);

      // Connect first device
      await tester.tap(find.text('Connect').first);
      await tester.pumpAndSettle();

      expect(find.text('Disconnect'), findsOneWidget);

      // Test key press Middle C
      await tester.tap(find.text('Test Key Press (Middle C / 60)'));
      await tester.pump();

      expect(
        find.text('Simulated MIDI Note On: Middle C (60)'),
        findsOneWidget,
      );
    });
  });
}
