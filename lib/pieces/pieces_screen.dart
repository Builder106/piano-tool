import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../brand/book_page.dart';
import '../brand/buttons.dart';
import '../brand/palette.dart';
import '../data/ingestion_repository.dart';
import '../data/level_repository.dart';
import '../data/progress_repository.dart';
import '../home/home_screen.dart';

Route<void> piecesRoute({
  required void Function(Piece piece) onOpenPiece,
  Future<String?> Function()? onAddPiece,
}) => fadeRoute(
  (_) => PiecesScreen(onOpenPiece: onOpenPiece, onAddPiece: onAddPiece),
);

/// Every piece in the book, built-in and added, with where each one stands.
/// Pieces you added can be taken out again.
class PiecesScreen extends ConsumerStatefulWidget {
  const PiecesScreen({super.key, required this.onOpenPiece, this.onAddPiece});

  final void Function(Piece piece) onOpenPiece;
  final Future<String?> Function()? onAddPiece;

  @override
  ConsumerState<PiecesScreen> createState() => _PiecesScreenState();
}

class _PiecesScreenState extends ConsumerState<PiecesScreen> {
  String? _removing;

  Future<void> _remove(Piece piece) async {
    try {
      final ingestion = await ref.read(ingestionRepositoryProvider.future);
      await ingestion.deleteImportedLevel(piece.stage.level.id);
    } on Object {
      // Nothing was stored, so there is nothing to take out.
    }
    ref.invalidate(levelRepositoryProvider);
    if (mounted) setState(() => _removing = null);
  }

  @override
  Widget build(BuildContext context) {
    final u = unitOf(context);
    final repository = ref.watch(levelRepositoryProvider);
    final progress = ref.watch(stageProgressProvider);
    final Widget body = switch ((repository, progress)) {
      (AsyncData(value: final r), AsyncData(value: final p)) => ListView(
        padding: EdgeInsets.fromLTRB(40 * u, 24 * u, 40 * u, 48 * u),
        children: [
          for (final (i, piece) in placePieces(r.getAllStages(), p).indexed)
            _PieceRow(
              number: i + 1,
              piece: piece,
              added: r.isImportedLevel(piece.stage.level.id),
              confirming: _removing == piece.stage.id,
              onOpen: piece.state == PieceState.locked
                  ? null
                  : () => widget.onOpenPiece(piece),
              onAskRemove: () => setState(() => _removing = piece.stage.id),
              onKeep: () => setState(() => _removing = null),
              onRemove: () => _remove(piece),
            ),
          if (widget.onAddPiece != null) ...[
            SizedBox(height: 28 * u),
            Align(
              alignment: Alignment.centerLeft,
              child: QuietButton(
                label: 'Add your own piece',
                onPressed: widget.onAddPiece,
              ),
            ),
          ],
        ],
      ),
      _ => const SizedBox.expand(),
    };
    return BookPage(title: 'All pieces', child: body);
  }
}

class _PieceRow extends StatelessWidget {
  const _PieceRow({
    required this.number,
    required this.piece,
    required this.added,
    required this.confirming,
    required this.onOpen,
    required this.onAskRemove,
    required this.onKeep,
    required this.onRemove,
  });

  final int number;
  final Piece piece;
  final bool added;
  final bool confirming;
  final VoidCallback? onOpen;
  final VoidCallback onAskRemove;
  final VoidCallback onKeep;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final u = unitOf(context);
    final dim = piece.state == PieceState.locked;
    final title = piece.stage.title;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Palette.rule, width: 1.5)),
      ),
      padding: EdgeInsets.symmetric(vertical: 16 * u),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48 * u,
            child: Text(
              '$number',
              style: TextStyle(
                fontFamily: Fonts.ui,
                fontSize: 24 * u,
                color: Palette.graphite,
                fontVariations: const [FontVariation('wght', 700)],
              ),
            ),
          ),
          Expanded(
            child: confirming
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PageHeading('Remove $title?', size: 26),
                      SizedBox(height: 4 * u),
                      const PageText(
                        'It leaves the book. You can add it again later.',
                      ),
                      SizedBox(height: 12 * u),
                      Wrap(
                        spacing: 12 * u,
                        runSpacing: 10 * u,
                        children: [
                          StartButton(label: 'Remove', onPressed: onRemove),
                          QuietButton(label: 'Keep it', onPressed: onKeep),
                        ],
                      ),
                    ],
                  )
                : Semantics(
                    button: onOpen != null,
                    enabled: onOpen != null,
                    label: '$title. ${piece.status}',
                    child: ExcludeSemantics(
                      child: GestureDetector(
                        onTap: onOpen,
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontFamily: Fonts.ui,
                                fontSize: 32 * u,
                                height: 1.1,
                                letterSpacing: -0.5 * u,
                                color: dim ? Palette.graphite : Palette.ink,
                                fontVariations: const [
                                  FontVariation('wght', 800),
                                ],
                              ),
                            ),
                            SizedBox(height: 2 * u),
                            Text(
                              piece.status,
                              style: TextStyle(
                                fontFamily: Fonts.ui,
                                fontSize: 19 * u,
                                color: piece.state == PieceState.next
                                    ? Palette.pencilBlue
                                    : Palette.graphite,
                                fontVariations: const [
                                  FontVariation('wght', 600),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          if (added && !confirming)
            Semantics(
              button: true,
              label: 'Remove $title',
              child: ExcludeSemantics(
                child: GestureDetector(
                  onTap: onAskRemove,
                  behavior: HitTestBehavior.opaque,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 48,
                      minWidth: 48,
                    ),
                    child: Center(
                      child: Text(
                        'Remove',
                        style: TextStyle(
                          fontFamily: Fonts.ui,
                          fontSize: 19 * u,
                          color: Palette.pencilRed,
                          fontVariations: const [FontVariation('wght', 700)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
