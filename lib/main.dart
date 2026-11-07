import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/settings_repository.dart';

/// Entry point with no interface. The previous frontend was removed so the
/// app can be redesigned from scratch; audio, MIDI, the stage engine, saved
/// progress and the stage controller remain and are covered by tests.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsRepository().read();
  runApp(
    ProviderScope(
      overrides: [
        settingsProvider.overrideWith(
          () => SettingsNotifier(initialSettings: settings),
        ),
      ],
      child: const PianoToolApp(),
    ),
  );
}

class PianoToolApp extends StatelessWidget {
  const PianoToolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Piano Tool',
      debugShowCheckedModeBanner: false,
      home: Scaffold(),
    );
  }
}
