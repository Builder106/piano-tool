import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import '../../models/engine_models.dart';
import '../theme/tokens.dart';
import 'notation.dart';
import 'staff_geometry.dart';

typedef GlyphStyle = ({
  Color color,

  /// A soft disc behind the head: the note to play now.
  bool halo,

  /// An outline circle around the head: a perfectly timed hit.
  bool ringed,

  /// A pencil tick beside the head: any hit.
  bool ticked,

  /// A short line under the tick: a hit outside the good window.
  bool underlined,

  /// A diagonal stroke through the head: a miss.
  bool struck,
});

/// Performance state is drawn as a mark beside the note.
///
/// The notehead belongs to the music: open for a half note, filled for a
/// quarter. Scoring must not change it, or a hit half note would read as a
/// quarter. Each state gets its own mark so it survives without colour;
/// colour only reinforces it.
abstract final class NoteGlyphStyle {
  static GlyphStyle forState(NoteState state, PianoColors c) => switch (state) {
    NoteState.hitPerfect => (
      color: c.success,
      halo: false,
      ringed: true,
      ticked: true,
      underlined: false,
      struck: false,
    ),
    NoteState.hitGood => (
      color: c.success,
      halo: false,
      ringed: false,
      ticked: true,
      underlined: false,
      struck: false,
    ),
    NoteState.hitOkay => (
      color: c.warning,
      halo: false,
      ringed: false,
      ticked: true,
      underlined: true,
      struck: false,
    ),
    NoteState.missed => (
      color: c.error,
      halo: false,
      ringed: false,
      ticked: false,
      underlined: false,
      struck: true,
    ),
    NoteState.active => (
      color: c.accent,
      halo: true,
      ringed: false,
      ticked: false,
      underlined: false,
      struck: false,
    ),
    NoteState.upcoming => (
      color: c.ink,
      halo: false,
      ringed: false,
      ticked: false,
      underlined: false,
      struck: false,
    ),
  };
}

abstract final class NoteGlyph {
  /// Noteheads are tilted the way engraved heads are.
  static const double _tilt = -0.35; // radians, about -20 degrees

  /// Width of the head for [value], in pixels. Whole notes are broader.
  static double headWidth(StaffGeometry g, NoteValue value) =>
      value == NoteValue.whole ? g.space * 1.6 : g.noteheadSize.width;

  /// Draws the notehead and its augmentation dot. Stems, flags and beams
  /// are the painter's, since they can join several heads.
  static void paintHead(
    Canvas canvas,
    Offset center,
    StaffGeometry g,
    WrittenDuration duration,
    Color color, {
    required bool onLine,
  }) {
    final width = headWidth(g, duration.value);
    final height = g.noteheadSize.height;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (duration.value != NoteValue.whole) canvas.rotate(_tilt);
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: width,
      height: height,
    );
    if (duration.value.hollow) {
      // An engraved open head is a thick ring with a thin, slanted hole.
      final hole = Rect.fromCenter(
        center: Offset.zero,
        width: width * (duration.value == NoteValue.whole ? 0.5 : 0.62),
        height: height * 0.52,
      );
      final holeAngle = duration.value == NoteValue.whole ? 0.9 : -0.25;
      final path = Path()
        ..fillType = PathFillType.evenOdd
        ..addOval(rect)
        ..addPath(
          Path()..addOval(hole),
          Offset.zero,
          matrix4: Matrix4.rotationZ(holeAngle).storage,
        );
      canvas.drawPath(path, Paint()..color = color);
    } else {
      canvas.drawOval(rect, Paint()..color = color);
    }
    canvas.restore();

    if (duration.dotted) {
      // A dot on a line moves up into the space above.
      final dy = onLine ? -g.space / 2 : 0.0;
      canvas.drawCircle(
        Offset(center.dx + width / 2 + g.space * 0.5, center.dy + dy),
        g.space * 0.2,
        Paint()..color = color,
      );
    }
  }

  /// Draws the performance marks for a head. [markBelow] puts the tick on
  /// the side away from the stem.
  static void paintMarks(
    Canvas canvas,
    Offset center,
    StaffGeometry g,
    NoteValue value,
    GlyphStyle style, {
    required bool markBelow,
  }) {
    final width = headWidth(g, value);

    if (style.ringed) {
      canvas.drawCircle(
        center,
        width * 0.78,
        Paint()
          ..color = style.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = g.space * 0.12,
      );
    }

    final pencil = Paint()
      ..color = style.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = g.space * 0.16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (style.ticked) {
      final s = g.space;
      final y = center.dy + (markBelow ? s * 1.5 : -s * 1.5);
      final tick = Path()
        ..moveTo(center.dx - s * 0.4, y - s * 0.05)
        ..lineTo(center.dx - s * 0.1, y + s * 0.3)
        ..lineTo(center.dx + s * 0.45, y - s * 0.4);
      canvas.drawPath(tick, pencil);
      if (style.underlined) {
        final uy = y + s * 0.55;
        canvas.drawLine(
          Offset(center.dx - s * 0.4, uy),
          Offset(center.dx + s * 0.45, uy),
          pencil,
        );
      }
    }

    if (style.struck) {
      final r = width * 0.85;
      final dx = r * math.cos(-0.6);
      final dy = r * math.sin(-0.6);
      canvas.drawLine(
        Offset(center.dx - dx, center.dy - dy),
        Offset(center.dx + dx, center.dy + dy),
        pencil,
      );
    }
  }
}
