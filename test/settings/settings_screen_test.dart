import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/data/settings_repository.dart';
import 'package:piano_tool/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _open(
  WidgetTester tester,
  AppSettings settings,
) async {
  tester.view.physicalSize = const Size(1280, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final container = ProviderContainer(
    overrides: [
      settingsProvider.overrideWith(
        () => SettingsNotifier(initialSettings: settings),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  return container;
}

void main() {
  testWidgets('choosing a word changes the setting', (tester) async {
    final container = await _open(tester, const AppSettings());
    AppSettings now() => container.read(settingsProvider);

    await tester.tap(find.text('Microphone'));
    await tester.pump();
    expect(now().inputSource, PracticeInputSource.microphone);
    expect(find.text('Hears your piano through the microphone'), findsOne);

    await tester.tap(find.text('Half'));
    await tester.pump();
    expect(now().defaultPlaybackSpeed, 0.5);

    await tester.tap(find.text('Strict'));
    await tester.pump();
    expect(now().toleranceLevel, ToleranceLevel.strict);
  });

  testWidgets('checking again is offered only after a check passed', (
    tester,
  ) async {
    final container = await _open(
      tester,
      const AppSettings(verifiedInput: 'both'),
    );
    expect(find.text('Check again'), findsOne);

    await tester.tap(find.text('Check again'));
    await tester.pump();
    expect(container.read(settingsProvider).verifiedInput, isNull);
    expect(find.text('Check again'), findsNothing);
    expect(
      find.text('The next piece will ask you to play middle C first.'),
      findsOne,
    );
  });
}
