import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'brand/palette.dart';
import 'data/settings_repository.dart';
import 'home/home_screen.dart';
import 'practice/find_notes.dart';
import 'practice/practice_screen.dart';

/// Entry point. The interface is a method book: see DESIGN.md.
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
        brightness: Brightness.light,
        fontFamily: Fonts.ui,
        scaffoldBackgroundColor: Palette.field,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: HomeScreen(
            onOpenPiece: (piece) => Navigator.of(context).push(
              piece.state == PieceState.learned
                  ? practiceRoute(stageId: piece.stage.id)
                  : findNotesRoute(stageId: piece.stage.id),
            ),
          ),
        ),
      ),
    );
  }
}
