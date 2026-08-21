import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'keyboard_geometry.dart';

/// A 61 key keyboard that shows what is coming and what is being played.
/// It takes no input; scoring comes from the microphone.
class PianoKeyboardView extends StatelessWidget {
  const PianoKeyboardView(
      {super.key, this.due = const {}, this.playing = const {}});

  /// Notes the level expects right now.
  final Set<int> due;

  /// Notes currently detected from audio.
  final Set<int> playing;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.infinite,
        painter: _KeyboardPainter(
          colors: PianoTheme.colorsOf(context),
          due: due,
          playing: playing,
        ),
      );
}

class _KeyboardPainter extends CustomPainter {
  _KeyboardPainter(
      {required this.colors, required this.due, required this.playing});

  final PianoColors colors;
  final Set<int> due;
  final Set<int> playing;

  @override
  void paint(Canvas canvas, Size size) {
    final g = KeyboardGeometry(width: size.width, height: size.height);
    final edge = Paint()
      ..color = colors.rule
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var midi = KeyboardGeometry.lowestMidi;
        midi <= KeyboardGeometry.highestMidi;
        midi++) {
      if (g.isBlack(midi)) continue;
      final rect = g.whiteKeyRect(g.whiteIndexFor(midi));
      canvas.drawRect(rect, Paint()..color = _whiteFill(midi));
      canvas.drawRect(rect, edge);
    }

    for (var midi = KeyboardGeometry.lowestMidi;
        midi <= KeyboardGeometry.highestMidi;
        midi++) {
      if (!g.isBlack(midi)) continue;
      canvas.drawRect(g.blackKeyRect(midi), Paint()..color = _blackFill(midi));
    }

    _paintOctaveLabels(canvas, g, size);
  }

  Color _whiteFill(int midi) {
    if (playing.contains(midi)) return colors.accent;
    if (due.contains(midi)) return colors.paper3;
    return colors.paper;
  }

  Color _blackFill(int midi) {
    if (playing.contains(midi)) return colors.accent;
    if (due.contains(midi)) return colors.ink2;
    return colors.ink;
  }

  void _paintOctaveLabels(Canvas canvas, KeyboardGeometry g, Size size) {
    for (var octave = 2; octave <= 7; octave++) {
      final midi = 12 * (octave + 1);
      if (midi > KeyboardGeometry.highestMidi) break;
      final rect = g.whiteKeyRect(g.whiteIndexFor(midi));
      final painter = TextPainter(
        text: TextSpan(
          text: 'C$octave',
          style: TextStyle(
            fontFamily: 'IBMPlexSans',
            fontSize: (g.whiteKeyWidth * 0.42).clamp(6.0, 10.0),
            color: colors.muted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(rect.left + (rect.width - painter.width) / 2,
            size.height - painter.height - 2),
      );
    }
  }

  @override
  bool shouldRepaint(_KeyboardPainter old) =>
      old.colors != colors ||
      !setEquals(old.due, due) ||
      !setEquals(old.playing, playing);
}
