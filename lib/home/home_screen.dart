import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../brand/palette.dart';
import '../data/level_repository.dart';
import '../data/progress_repository.dart';
import '../models/level_models.dart';
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

  final void Function(StageModel stage)? onOpenPiece;
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

/// The paper slip asset: its pixel size, and where the paper itself sits in
/// it (the rest is the slip's shadow). Measured from `slip.png`.
const _slipImage = Size(960, 320);
const _slipPaper = Rect.fromLTRB(33, 37, 927, 284);

/// Lettering on a slip lies flat on the strings, so it is foreshortened like
/// the slip; not fully (cos 40°), which would cost legibility.
const _flatten = 0.86;

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
                  painter: _PencilLoop(fit: fit, key: note.key),
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
                  child: _Slip(
                    width: slipWidth,
                    u: u,
                    title: piece.stage.title,
                    status: piece.status,
                    state: piece.state,
                    underStrings: piece.state == PieceState.locked
                        ? _stringsAcross(fit, note, slipWidth)
                        : null,
                    onTap:
                        piece.state == PieceState.locked ||
                            screen.onOpenPiece == null
                        ? null
                        : () => screen.onOpenPiece!(piece.stage),
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
                child: _Slip(
                  width: slipWidth,
                  u: u,
                  title: 'Add a piece',
                  status: 'Record or upload',
                  state: null,
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
    final k = width / _slipPaper.width;
    final centre = fit.x(_centre(note));
    final left = centre - (_slipPaper.left + _slipPaper.width / 2) * k;
    final right = left + _slipImage.width * k;
    return [
      for (final n in geometry.notes.values)
        for (final x in n.strings)
          if (fit.x(x) > left + _slipPaper.left * k &&
              fit.x(x) < left + _slipPaper.right * k)
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
    final k = width / _slipPaper.width;
    final paperHeight = _slipPaper.height * k;
    final damperTop = fit.y(note.damper?.top ?? 0.41);
    final lift = high ? 22 * u + paperHeight + 12 * u : 22 * u;
    final paperBottom = damperTop - lift;
    final imageTop = paperBottom - _slipPaper.bottom * k;
    final margin = 10 * u;
    var imageLeft =
        fit.x(_centre(note)) - (_slipPaper.left + _slipPaper.width / 2) * k;
    imageLeft = imageLeft.clamp(
      margin - _slipPaper.left * k,
      box.width - margin - _slipPaper.right * k,
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

/// The brand's pencil loop, drawn round the key that opens the next piece.
class _PencilLoop extends CustomPainter {
  _PencilLoop({required this.fit, required this.key});

  final CoverFit fit;
  final Rect key;

  @override
  void paint(Canvas canvas, Size size) {
    final r = fit.rect(key);
    final bottom = math.min(r.bottom, size.height);
    final centre = Offset(r.center.dx, r.top + (bottom - r.top) * 0.64);
    final rx = r.width * 0.78;
    final ry = (bottom - r.top) * 0.30;
    final path = Path();
    const turns = 1.12;
    const steps = 90;
    for (var i = 0; i <= steps; i++) {
      final t = -math.pi * 0.62 + 2 * math.pi * turns * i / steps;
      // A loose hand: the radius drifts and the end overshoots the start.
      final wobble = 1 + 0.035 * math.sin(3 * t) - 0.05 * i / steps;
      final p =
          centre + Offset(rx * wobble * math.cos(t), ry * wobble * math.sin(t));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Palette.pencilBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_PencilLoop old) =>
      old.key != key || old.fit.drawn != fit.drawn;
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

/// A paper slip lying on the strings with a piece's name on it. A locked
/// piece's slip lies under the strings instead, in their shade, with the
/// strings drawn across it.
class _Slip extends StatelessWidget {
  const _Slip({
    required this.width,
    required this.u,
    required this.title,
    required this.status,
    required this.state,
    this.underStrings,
    this.onTap,
  });

  final double width;
  final double u;
  final String title;
  final String status;

  /// Null for the blank slip that adds a piece.
  final PieceState? state;

  /// The x of each string crossing the slip, when it lies under them.
  final List<double>? underStrings;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final k = width / _slipPaper.width;
    final paper = Rect.fromLTRB(
      _slipPaper.left * k,
      _slipPaper.top * k,
      _slipPaper.right * k,
      _slipPaper.bottom * k,
    );
    final blank = state == null;
    final titleColor = blank ? Palette.pencilBlue : Palette.ink;
    final statusColor = state == PieceState.next
        ? Palette.pencilBlue
        : Palette.graphite;
    final under = underStrings;
    return Semantics(
      button: state != PieceState.locked,
      label: '$title. $status',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: _slipImage.width * k,
          height: _slipImage.height * k,
          child: Stack(
            children: [
              Positioned.fill(child: Image.asset(slipAsset, fit: BoxFit.fill)),
              Positioned.fromRect(
                rect: paper.deflate(1),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12 * u),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(1, _flatten, 1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: Fonts.display,
                            fontSize: math.max(18, 23 * u),
                            height: 1.05,
                            letterSpacing: -0.2,
                            fontVariations: const [FontVariation('wght', 600)],
                            color: titleColor,
                          ),
                        ),
                        SizedBox(height: 2 * u),
                        Text(
                          status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: Fonts.text,
                            fontSize: math.max(13, 13.5 * u),
                            height: 1.2,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (under != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _StringsOverSlip(xs: under, paper: paper),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The shade and the strings over a slip that lies beneath them.
class _StringsOverSlip extends CustomPainter {
  _StringsOverSlip({required this.xs, required this.paper});

  final List<double> xs;
  final Rect paper;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(paper, Paint()..color = const Color(0x2E000000));
    final shadow = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 1.6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    // Thin and slightly see-through, so the name under them stays readable.
    final steel = Paint()
      ..color = const Color(0xB8B4B9C1)
      ..strokeWidth = 1.0;
    final glint = Paint()
      ..color = const Color(0x99F4F6F8)
      ..strokeWidth = 0.4;
    for (final x in xs) {
      canvas.drawLine(
        Offset(x + 2.5, paper.top),
        Offset(x + 2.5, paper.bottom),
        shadow,
      );
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), steel);
      canvas.drawLine(Offset(x - 0.3, 0), Offset(x - 0.3, size.height), glint);
    }
  }

  @override
  bool shouldRepaint(_StringsOverSlip old) =>
      old.xs != xs || old.paper != paper;
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
          _Inlay(label: 'All pieces', size: size, onPressed: onOpenPieces),
          SizedBox(width: 14 * u),
          _Inlay(label: 'Settings', size: size, onPressed: onOpenSettings),
        ],
      ),
    );
  }
}

class _Inlay extends StatelessWidget {
  const _Inlay({required this.label, required this.size, this.onPressed});

  final String label;
  final double size;
  final VoidCallback? onPressed;

  static const _nickel = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF1F3F5), Color(0xFF9DA2AA), Color(0xFFD6D9DE)],
    stops: [0.0, 0.55, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: Fonts.display,
      fontSize: size,
      height: 1,
      letterSpacing: 0.4,
      fontVariations: const [FontVariation('wght', 560)],
    );
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: size * 0.5, vertical: size * 0.4),
        ),
        overlayColor: WidgetStatePropertyAll(
          Palette.paper.withValues(alpha: 0.06),
        ),
        shape: WidgetStateProperty.resolveWith(
          (states) => RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: states.contains(WidgetState.focused)
                ? const BorderSide(color: Color(0xFFC9CDD3), width: 1.5)
                : BorderSide.none,
          ),
        ),
      ),
      child: Stack(
        children: [
          // The inlay's lower lip: a dark line just under the metal.
          Transform.translate(
            offset: const Offset(0, 1.2),
            child: Text(label, style: style.copyWith(color: Colors.black)),
          ),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: _nickel.createShader,
            child: Text(label, style: style.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
