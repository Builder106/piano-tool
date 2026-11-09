import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'palette.dart';

/// The brand's pencil loop, drawn round [target]: a loose hand whose radius
/// drifts and whose end overshoots the start.
class PencilLoopPainter extends CustomPainter {
  PencilLoopPainter({
    required this.target,
    this.color = Palette.pencilBlue,
    this.width = 2.6,
  });

  final Rect target;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = target.center;
    final rx = target.width / 2;
    final ry = target.height / 2;
    final path = Path();
    const turns = 1.12;
    const steps = 90;
    for (var i = 0; i <= steps; i++) {
      final t = -math.pi * 0.62 + 2 * math.pi * turns * i / steps;
      final wobble = 1 + 0.035 * math.sin(3 * t) - 0.05 * i / steps;
      final p =
          centre + Offset(rx * wobble * math.cos(t), ry * wobble * math.sin(t));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(PencilLoopPainter old) =>
      old.target != target || old.color != color || old.width != width;
}

/// The loop's place on a key seen from the player's seat: round the lower
/// part of the key that is on screen.
Rect pencilLoopOnKey(Rect key, double visibleBottom) {
  final bottom = math.min(key.bottom, visibleBottom);
  final centre = Offset(key.center.dx, key.top + (bottom - key.top) * 0.64);
  return Rect.fromCenter(
    center: centre,
    width: key.width * 1.56,
    height: (bottom - key.top) * 0.60,
  );
}
