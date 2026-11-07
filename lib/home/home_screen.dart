import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../brand/nickel_inlay.dart';
import '../brand/palette.dart';
import '../brand/pencil_loop.dart';
import '../data/level_repository.dart';
import '../data/progress_repository.dart';
import '../models/level_models.dart';
import 'paper_slip.dart';
import 'strung_geometry.dart';

/// Where a piece stands for this learner.
enum PieceState { learned, next, ready, locked }

/// A piece placed on the piano: its string, its state and the line under its
/// name.
class PieceOnString {
  const PieceOnString({
    required this.stage,
    required this.midi,
    required this.state,
    this.progress,
    this.opensAfter,
  });

  final StageModel stage;
  final int midi;
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

const _whiteOffsets = {0, 2, 4, 5, 7, 9, 11};
const _noteNames = [
  'C', 'C♯', 'D', 'D♯', 'E', 'F', 'F♯', 'G', 'G♯', 'A', 'A♯', 'B', //
];

/// White keys from middle C upward.
Iterable<int> _whiteKeysFromMiddleC() sync* {
  for (var m = 60; m < 128; m++) {
    if (_whiteOffsets.contains(m % 12)) yield m;
  }
}

/// Pieces sit in learning order on every other white key from middle C, so
/// the first three spell a C major chord: C, E, G. Returns the pieces and the
/// key the next added piece would take.
(List<PieceOnString>, int) placePieces(
  List<StageModel> stages,
  Map<String, StageProgress> progress,
) {
  final ordered = [...stages]..sort((a, b) => a.order.compareTo(b.order));
  final titles = {for (final s in ordered) s.id: s.title};
  final keys = _whiteKeysFromMiddleC().toList();
  var nextTaken = false;
  final pieces = <PieceOnString>[];
  for (final (i, stage) in ordered.indexed) {
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
      PieceOnString(
        stage: stage,
        midi: keys[i * 2],
        state: state,
        progress: p,
        opensAfter: unmet.isEmpty ? null : titles[unmet.first],
      ),
    );
  }
  return (pieces, keys[ordered.length * 2]);
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    this.onOpenPiece,
    this.onAddPiece,
    this.onOpenPieces,
    this.onOpenSettings,
  });

  /// Opens a piece; [midi] is the note whose string it lives on.
  final void Function(StageModel stage, int midi)? onOpenPiece;
  final VoidCallback? onAddPiece;
  final VoidCallback? onOpenPieces;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final geometry = ref.watch(strungGeometryProvider);
    final repository = ref.watch(levelRepositoryProvider);
    final progress = ref.watch(stageProgressProvider);
    return ColoredBox(
      color: Palette.lacquer,
      child: switch ((geometry, repository, progress)) {
        (
          AsyncData(value: final g),
          AsyncData(value: final r),
          AsyncData(value: final p),
        ) =>
          _Piano(
            geometry: g,
            placed: placePieces(r.getAllStages(), p),
            screen: this,
          ),
        _ => const SizedBox.expand(),
      },
    );
  }
}

class _Piano extends StatelessWidget {
  const _Piano({
    required this.geometry,
    required this.placed,
    required this.screen,
  });

  final StrungGeometry geometry;
  final (List<PieceOnString>, int) placed;
  final HomeScreen screen;

  @override
  Widget build(BuildContext context) {
    final (pieces, addKey) = placed;
    return LayoutBuilder(
      builder: (context, constraints) {
        final box = constraints.biggest;
        final fit = CoverFit(geometry.imageSize, box);
        // Type scales with the height of the screen, within limits.
        final u = (box.height / 720).clamp(0.7, 1.25);
        // Slips two pieces apart share a height, so a slip may be no wider
        // than the gap between them (four white keys).
        final slipWidth = math.min(
          236 * u,
          fit.drawn.width * _fourWhiteKeys(geometry) - 10,
        );
        final next = pieces
            .where((p) => p.state == PieceState.next)
            .firstOrNull;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fromRect(
              rect: fit.origin & fit.drawn,
              child: Image.asset(
                homeBackdropAsset,
                fit: BoxFit.fill,
                excludeFromSemantics: true,
              ),
            ),
            // Dim the strings a little so the lit ones read as lit.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: fit.y(0.415),
              child: const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x99000000), Color(0x52000000)],
                    ),
                  ),
                ),
              ),
            ),
            CustomPaint(
              painter: _LitStrings(
                fit: fit,
                geometry: geometry,
                pieces: pieces,
              ),
            ),
            for (final piece in pieces)
              if (geometry.notes[piece.midi] case final note?)
                _KeyLetter(fit: fit, note: note, box: box, u: u),
            if (next != null)
              if (geometry.notes[next.midi] case final note?)
                CustomPaint(
                  painter: PencilLoopPainter(
                    target: pencilLoopOnKey(fit.rect(note.key), box.height),
                  ),
                ),
            for (final (i, piece) in pieces.indexed)
              if (geometry.notes[piece.midi] case final note?)
                _slipOnString(
                  box: box,
                  fit: fit,
                  note: note,
                  width: slipWidth,
                  u: u,
                  high: i.isOdd,
                  child: PaperSlip(
                    width: slipWidth,
                    u: u,
                    title: piece.stage.title,
                    status: piece.status,
                    statusColor: piece.state == PieceState.next
                        ? Palette.pencilBlue
                        : Palette.graphite,
                    button: piece.state != PieceState.locked,
                    underStrings: piece.state == PieceState.locked
                        ? _stringsAcross(fit, note, slipWidth)
                        : null,
                    onTap:
                        piece.state == PieceState.locked ||
                            screen.onOpenPiece == null
                        ? null
                        : () => screen.onOpenPiece!(piece.stage, piece.midi),
                  ),
                ),
            if (geometry.notes[addKey] case final note?)
              _slipOnString(
                box: box,
                fit: fit,
                note: note,
                width: slipWidth,
                u: u,
                high: pieces.length.isOdd,
                child: PaperSlip(
                  width: slipWidth,
                  u: u,
                  title: 'Add a piece',
                  status: 'Record or upload',
                  titleColor: Palette.pencilBlue,
                  onTap: screen.onAddPiece,
                ),
              ),
            if (geometry.nameBoard != null)
              _NameBoardControls(
                fit: fit,
                geometry: geometry,
                u: u,
                onOpenPieces: screen.onOpenPieces,
                onOpenSettings: screen.onOpenSettings,
              ),
          ],
        );
      },
    );
  }

  /// The image width between a note and the note four white keys above it.
  static double _fourWhiteKeys(StrungGeometry g) {
    final c = g.notes[60]?.strings[1];
    final g4 = g.notes[67]?.strings[1];
    return c == null || g4 == null ? 0.19 : (g4 - c);
  }

  /// The image-space x of every string that crosses a slip centred on [note],
  /// relative to the slip image's left edge, in logical pixels.
  List<double> _stringsAcross(CoverFit fit, NoteGeometry note, double width) {
    final k = width / slipPaperRect.width;
    final centre = fit.x(_centre(note));
    final left = centre - (slipPaperRect.left + slipPaperRect.width / 2) * k;
    final right = left + slipImageSize.width * k;
    return [
      for (final n in geometry.notes.values)
        for (final x in n.strings)
          if (fit.x(x) > left + slipPaperRect.left * k &&
              fit.x(x) < left + slipPaperRect.right * k)
            fit.x(x) - left,
    ]..removeWhere((x) => x < 0 || x > right - left);
  }

  static double _centre(NoteGeometry n) =>
      n.strings.reduce((a, b) => a + b) / n.strings.length;

  /// Lays a slip across a note's strings, above its damper. Slips alternate
  /// between two heights so neighbours never overlap; near the right edge of
  /// the screen a slip slides in to the margin, still over its strings.
  Widget _slipOnString({
    required Size box,
    required CoverFit fit,
    required NoteGeometry note,
    required double width,
    required double u,
    required bool high,
    required Widget child,
  }) {
    final k = width / slipPaperRect.width;
    final paperHeight = slipPaperRect.height * k;
    final damperTop = fit.y(note.damper?.top ?? 0.41);
    final lift = high ? 22 * u + paperHeight + 12 * u : 22 * u;
    final paperBottom = damperTop - lift;
    final imageTop = paperBottom - slipPaperRect.bottom * k;
    final margin = 10 * u;
    var imageLeft =
        fit.x(_centre(note)) -
        (slipPaperRect.left + slipPaperRect.width / 2) * k;
    imageLeft = imageLeft.clamp(
      margin - slipPaperRect.left * k,
      box.width - margin - slipPaperRect.right * k,
    );
    return Positioned(left: imageLeft, top: imageTop, child: child);
  }
}

class _LitStrings extends CustomPainter {
  _LitStrings({
    required this.fit,
    required this.geometry,
    required this.pieces,
  });

  final CoverFit fit;
  final StrungGeometry geometry;
  final List<PieceOnString> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final note = geometry.notes[piece.midi];
      if (note == null || piece.state == PieceState.locked) continue;
      final (color, strength) = switch (piece.state) {
        PieceState.next => (Palette.pencilBlueOnDark, 1.0),
        PieceState.learned => (Palette.paper, 0.95),
        _ => (Palette.paper, 0.6),
      };
      final bottom = fit.y(note.damper?.top ?? 0.41);
      final glow = Paint()
        ..color = color.withValues(alpha: 0.6 * strength)
        ..strokeWidth = 7
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      final core = Paint()
        ..color = color.withValues(alpha: strength)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      for (final x in note.strings) {
        final sx = fit.x(x);
        canvas.drawLine(Offset(sx, 0), Offset(sx, bottom), glow);
        canvas.drawLine(Offset(sx, 0), Offset(sx, bottom), core);
      }
    }
  }

  @override
  bool shouldRepaint(_LitStrings old) =>
      old.fit.drawn != fit.drawn || old.pieces != pieces;
}

/// The note name, printed small on the front of each key that holds a piece.
class _KeyLetter extends StatelessWidget {
  const _KeyLetter({
    required this.fit,
    required this.note,
    required this.box,
    required this.u,
  });

  final CoverFit fit;
  final NoteGeometry note;
  final Size box;
  final double u;

  @override
  Widget build(BuildContext context) {
    final r = fit.rect(note.key);
    final bottom = math.min(r.bottom, box.height);
    return Positioned(
      left: r.left,
      width: r.width,
      top: r.top + (bottom - r.top) * 0.64 - 9 * u,
      child: ExcludeSemantics(
        child: Text(
          _noteNames[note.midi % 12],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: Fonts.text,
            fontSize: 14 * u,
            fontVariations: const [FontVariation('wght', 560)],
            color: Palette.ink,
          ),
        ),
      ),
    );
  }
}

/// Pieces and Settings, inlaid in nickel on the name board like the maker's
/// mark beside them.
class _NameBoardControls extends StatelessWidget {
  const _NameBoardControls({
    required this.fit,
    required this.geometry,
    required this.u,
    this.onOpenPieces,
    this.onOpenSettings,
  });

  final CoverFit fit;
  final StrungGeometry geometry;
  final double u;
  final VoidCallback? onOpenPieces;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final logo = geometry.logo;
    final y = fit.y(logo == null ? 0.615 : logo.center.dy);
    final left = math.max(
      fit.x(0.06),
      MediaQuery.paddingOf(context).left + 16 * u,
    );
    final size = math.max(19.0, 25 * u);
    return Positioned(
      left: left,
      top: y - size * 1.25,
      height: size * 2.5,
      child: Row(
        children: [
          NickelInlay(label: 'All pieces', size: size, onPressed: onOpenPieces),
          SizedBox(width: 14 * u),
          NickelInlay(label: 'Settings', size: size, onPressed: onOpenSettings),
        ],
      ),
    );
  }
}
