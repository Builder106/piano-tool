import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../brand/scale.dart';
import '../brand/buttons.dart';
import '../brand/palette.dart';
import '../brand/pencil_loop.dart';
import '../data/level_repository.dart';
import '../data/progress_repository.dart';
import '../models/engine_models.dart';
import '../models/level_models.dart';
import '../practice/paper_staff.dart';

/// Where a piece stands for this learner.
enum PieceState { learned, next, ready, locked }

/// A piece in the book's contents: its state and the line under its name.
class Piece {
  const Piece({
    required this.stage,
    required this.state,
    this.progress,
    this.opensAfter,
  });

  final StageModel stage;
  final PieceState state;
  final StageProgress? progress;
  final String? opensAfter;

  String get status => switch (state) {
    PieceState.learned =>
      'Learned. Best ${((progress?.bestAccuracy ?? 0) * 100).round()}%',
    PieceState.next => 'Up next',
    PieceState.ready => 'Ready to play',
    PieceState.locked => 'After $opensAfter',
  };
}

/// The pieces in learning order. The first open piece the learner has not
/// cleared is up next; a piece whose prerequisites are not cleared is locked.
List<Piece> placePieces(
  List<StageModel> stages,
  Map<String, StageProgress> progress,
) {
  final ordered = [...stages]..sort((a, b) => a.order.compareTo(b.order));
  final titles = {for (final s in ordered) s.id: s.title};
  var nextTaken = false;
  final pieces = <Piece>[];
  for (final stage in ordered) {
    final p = progress[stage.id];
    final unmet = stage.prerequisites
        .where((id) => progress[id]?.completed != true)
        .toList();
    final PieceState state;
    if (p?.completed == true) {
      state = PieceState.learned;
    } else if (unmet.isNotEmpty) {
      state = PieceState.locked;
    } else if (!nextTaken) {
      state = PieceState.next;
      nextTaken = true;
    } else {
      state = PieceState.ready;
    }
    pieces.add(
      Piece(
        stage: stage,
        state: state,
        progress: p,
        opensAfter: unmet.isEmpty ? null : titles[unmet.first],
      ),
    );
  }
  return pieces;
}

/// The home screen is the method book's contents on the blue field, and the
/// chosen piece open on the white page beside it.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    this.onOpenPiece,
    this.onAddPiece,
    this.onOpenPieces,
    this.onOpenSettings,
  });

  final void Function(Piece piece)? onOpenPiece;

  /// Adds a piece and returns its stage id when one was kept.
  final Future<String?> Function()? onAddPiece;
  final VoidCallback? onOpenPieces;
  final VoidCallback? onOpenSettings;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _chosen;

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(levelRepositoryProvider);
    final progress = ref.watch(stageProgressProvider);
    final body = switch ((repository, progress)) {
      (AsyncData(value: final r), AsyncData(value: final p)) => _book(
        context,
        placePieces(r.getAllStages(), p),
      ),
      _ => const SizedBox.expand(),
    };
    return ColoredBox(
      color: Palette.field,
      child: SafeArea(child: body),
    );
  }

  Widget _book(BuildContext context, List<Piece> pieces) {
    final u = unitOf(context);
    final open = pieces.where((p) => p.state != PieceState.locked);
    final chosen =
        pieces.where((p) => p.stage.id == _chosen).firstOrNull ??
        open.firstOrNull ??
        pieces.firstOrNull;
    final list = _Contents(
      pieces: pieces,
      chosen: chosen,
      u: u,
      onChoose: (p) => setState(() => _chosen = p.stage.id),
      onAdd: widget.onAddPiece == null
          ? null
          : () async {
              final id = await widget.onAddPiece!();
              if (id != null && mounted) setState(() => _chosen = id);
            },
    );
    final page = chosen == null
        ? const SizedBox.shrink()
        : _Page(
            piece: chosen,
            u: u,
            onStart: widget.onOpenPiece == null
                ? null
                : () => widget.onOpenPiece!(chosen),
          );
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 720;
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(36 * u, 18 * u, 24 * u, 0),
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const _Brand(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.onOpenPieces != null)
                          FieldAction(
                            label: 'All pieces',
                            onPressed: widget.onOpenPieces,
                          ),
                        if (widget.onOpenSettings != null)
                          FieldAction(
                            label: 'Settings',
                            onPressed: widget.onOpenSettings,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 11, child: list),
                        Expanded(flex: 9, child: page),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(flex: 5, child: list),
                        Expanded(flex: 6, child: page),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final u = unitOf(context);
    return Text(
      'Piano Tool',
      style: TextStyle(
        fontFamily: Fonts.ui,
        fontSize: 24 * u,
        color: Colors.white,
        fontVariations: const [FontVariation('wght', 800)],
      ),
    );
  }
}

class _Contents extends StatelessWidget {
  const _Contents({
    required this.pieces,
    required this.chosen,
    required this.u,
    required this.onChoose,
    required this.onAdd,
  });

  final List<Piece> pieces;
  final Piece? chosen;
  final double u;
  final void Function(Piece) onChoose;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(36 * u, 28 * u, 24 * u, 24 * u),
      children: [
        for (final (i, piece) in pieces.indexed)
          _Row(
            number: '${i + 1}',
            title: piece.stage.title,
            note: piece.state == PieceState.locked ? piece.status : null,
            circled: piece == chosen,
            dim: piece.state == PieceState.locked,
            u: u,
            onTap: piece.state == PieceState.locked
                ? null
                : () => onChoose(piece),
          ),
        if (onAdd != null)
          _Row(
            number: '+',
            title: 'Add your own piece',
            small: true,
            u: u,
            onTap: onAdd,
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.number,
    required this.title,
    required this.u,
    this.note,
    this.circled = false,
    this.dim = false,
    this.small = false,
    this.onTap,
  });

  final String number;
  final String title;
  final String? note;
  final bool circled;
  final bool dim;
  final bool small;
  final double u;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = dim ? Colors.white.withValues(alpha: 0.6) : Colors.white;
    return Semantics(
      button: onTap != null,
      selected: circled,
      enabled: onTap != null,
      label: note == null ? title : '$title. $note',
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: (small ? 12 : 16) * u),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                SizedBox(
                  width: 52 * u,
                  child: Text(
                    number,
                    style: TextStyle(
                      fontFamily: Fonts.ui,
                      fontSize: 24 * u,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontVariations: const [FontVariation('wght', 700)],
                    ),
                  ),
                ),
                Flexible(
                  child: CustomPaint(
                    foregroundPainter: circled ? const _WhiteLoop() : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: Fonts.ui,
                            fontSize: (small ? 28 : 46) * u,
                            height: 1.05,
                            letterSpacing: -1 * u,
                            color: color,
                            fontVariations: const [FontVariation('wght', 800)],
                          ),
                        ),
                        if (note != null)
                          Text(
                            note!,
                            style: TextStyle(
                              fontFamily: Fonts.ui,
                              fontSize: 17 * u,
                              color: color,
                              fontVariations: const [
                                FontVariation('wght', 600),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The chosen piece, circled in white pencil on the blue field.
class _WhiteLoop extends CustomPainter {
  const _WhiteLoop();

  @override
  void paint(Canvas canvas, Size size) {
    PencilLoopPainter(
      target: Rect.fromCenter(
        center: size.center(Offset.zero),
        width: size.width + 64,
        height: size.height + 30,
      ),
      color: Colors.white,
      width: 3.6,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_WhiteLoop old) => false;
}

class _Page extends StatelessWidget {
  const _Page({required this.piece, required this.u, required this.onStart});

  final Piece piece;
  final double u;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final stage = piece.stage;
    // On a short screen, such as a phone on its side, the engraved preview
    // is dropped so Start is in view without scrolling.
    return LayoutBuilder(
      builder: (context, box) {
        final short = box.maxHeight < 430;
        return Container(
          margin: EdgeInsets.only(top: 8 * u),
          padding: EdgeInsets.fromLTRB(
            48 * u,
            (short ? 24 : 40) * u,
            40 * u,
            (short ? 16 : 32) * u,
          ),
          decoration: const BoxDecoration(
            color: Palette.page,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.title,
                  style: TextStyle(
                    fontFamily: Fonts.ui,
                    fontSize: 54 * u,
                    height: 1,
                    letterSpacing: -1.5 * u,
                    color: Palette.ink,
                    fontVariations: const [FontVariation('wght', 800)],
                  ),
                ),
                SizedBox(height: 12 * u),
                Text(
                  stage.description,
                  style: TextStyle(
                    fontFamily: Fonts.ui,
                    fontSize: 21 * u,
                    height: 1.35,
                    color: Palette.graphite,
                  ),
                ),
                SizedBox(height: 8 * u),
                Text(
                  piece.status,
                  style: TextStyle(
                    fontFamily: Fonts.ui,
                    fontSize: 19 * u,
                    color: piece.state == PieceState.next
                        ? Palette.pencilBlue
                        : Palette.graphite,
                    fontVariations: const [FontVariation('wght', 700)],
                  ),
                ),
                if (!short) ...[
                  SizedBox(height: 24 * u),
                  SizedBox(
                    height: 210 * u,
                    child: StaticStaff(
                      level: stage.level,
                      notes: notesOf(stage.level),
                      noteStates: [
                        for (var i = 0; i < notesOf(stage.level).length; i++)
                          i == 0 ? NoteState.active : NoteState.upcoming,
                      ],
                    ),
                  ),
                ],
                SizedBox(height: (short ? 16 : 20) * u),
                StartButton(label: 'Start', onPressed: onStart),
              ],
            ),
          ),
        );
      },
    );
  }
}
