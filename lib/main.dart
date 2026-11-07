import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'brand/palette.dart';
import 'data/settings_repository.dart';
import 'home/home_screen.dart';
import 'practice/practice_screen.dart';

/// Entry point. The interface is being rebuilt around the "Strung" design in
/// DESIGN.md; the home screen is the first piece of it.
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
    return MaterialApp(
      title: 'Piano Tool',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: Fonts.text,
        scaffoldBackgroundColor: Palette.lacquer,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: HomeScreen(
            onOpenPiece: (stage, midi) => Navigator.of(
              context,
            ).push(practiceRoute(stageId: stage.id, midi: midi)),
          ),
        ),
      ),
    );
  }
}
