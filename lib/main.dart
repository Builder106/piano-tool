import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'brand/palette.dart';
import 'data/ingestion_repository.dart';
import 'data/settings_repository.dart';
import 'home/home_screen.dart';
import 'pieces/add_piece_screen.dart';
import 'pieces/pieces_screen.dart';
import 'practice/find_notes.dart';
import 'practice/practice_screen.dart';
import 'settings/settings_screen.dart';

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
      home: const _Book(),
    );
  }
}

/// The home screen with its doors wired: a piece opens its first step, and
/// the book's other screens open from the field above.
class _Book extends ConsumerWidget {
  const _Book();

  void _open(BuildContext context, Piece piece) {
    Navigator.of(context).push(
      piece.state == PieceState.learned
          ? practiceRoute(stageId: piece.stage.id)
          : findNotesRoute(stageId: piece.stage.id),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<String?> add() => Navigator.of(context).push(addPieceRoute());
    final canAdd = ref.watch(importAvailableProvider);
    return Scaffold(
      body: HomeScreen(
        onOpenPiece: (piece) => _open(context, piece),
        onAddPiece: canAdd ? add : null,
        onOpenPieces: () => Navigator.of(context).push(
          piecesRoute(
            onOpenPiece: (piece) => _open(context, piece),
            onAddPiece: canAdd ? add : null,
          ),
        ),
        onOpenSettings: () => Navigator.of(context).push(settingsRoute()),
      ),
    );
  }
}
