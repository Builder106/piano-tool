import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import '../../models/engine_models.dart';
import '../theme/tokens.dart';
import 'staff_geometry.dart';

typedef GlyphStyle = ({Color color, bool filled, bool ringed, bool struck});

/// Note state is a shape first and a colour second.
///
/// Encoding state only as green against red is invisible to red-green colour
/// blindness. Filled against hollow noteheads is real notation, so carrying
/// the distinction in shape costs nothing.
abstract final class NoteGlyphStyle {
  static GlyphStyle forState(NoteState state, PianoColors c) => switch (state) {
        // All three hit gradations share one glyph. Encoding hit quality
        // visually is a scoring-feedback decision this plan does not make.
        NoteState.hitPerfect || NoteState.hitGood || NoteState.hitOkay => (
            color: c.success,
            filled: true,
            ringed: false,
            struck: false
          ),
        NoteState.missed => (
            color: c.error,
            filled: false,
            ringed: false,
            struck: true
          ),
        NoteState.active => (
            color: c.accent,
            filled: true,
            ringed: true,
            struck: false
          ),
        NoteState.upcoming => (
            color: c.muted,
            filled: false,
            ringed: false,
            struck: false
          ),
      };
}

abstract final class NoteGlyph {
  /// Noteheads are tilted the way engraved heads are.
  static const double _tilt = -0.35; // radians, about -20 degrees

  static void paint(
    Canvas canvas,
    Offset center,
    StaffGeometry g,
    NoteState state,
    PianoColors colors, {
    bool stemDown = true,
  }) {
    final style = NoteGlyphStyle.forState(state, colors);
    final size = g.noteheadSize;
    final stroke = g.space * 0.18;

    if (style.ringed) {
      canvas.drawCircle(
        center,
        size.width * 0.72,
        Paint()..color = style.color.withValues(alpha: 0.22),
      );
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_tilt);
    final rect = Rect.fromCenter(
        center: Offset.zero, width: size.width, height: size.height);
    canvas.drawOval(
      rect,
      Paint()
        ..color = style.color
        ..style = style.filled ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.restore();

    // Stems are drawn in staff space, not inside the rotated head, so they
    // stay vertical instead of inheriting the tilt.
    final stemX = center.dx + (stemDown ? -size.width / 2 : size.width / 2);
    final stemY = center.dy + (stemDown ? g.stemLength : -g.stemLength);
    canvas.drawLine(
      Offset(stemX, center.dy),
      Offset(stemX, stemY),
      Paint()
        ..color = style.color
        ..strokeWidth = g.space * 0.12,
    );

    if (style.struck) {
      final r = size.width * 0.85;
      final dx = r * math.cos(-0.6);
      final dy = r * math.sin(-0.6);
      canvas.drawLine(
        Offset(center.dx - dx, center.dy - dy),
        Offset(center.dx + dx, center.dy + dy),
        Paint()
          ..color = style.color
          ..strokeWidth = g.space * 0.16
          ..strokeCap = StrokeCap.round,
      );
    }
  }
}
