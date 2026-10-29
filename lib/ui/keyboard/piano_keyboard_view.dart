import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'keyboard_geometry.dart';

/// A 61 key keyboard that shows what is coming and what is being played.
/// It takes no input; scoring comes from the microphone or a digital piano.
///
/// The keyboard is the Blender render (design: site/design/blender/keyboard.py)
/// scaled to the full width and anchored to the bottom, so a short box trims
/// the fallboard, never the keys. A painter tints the due and played keys over
/// it, positioned from the render's own key geometry.
class PianoKeyboardView extends StatelessWidget {
  const PianoKeyboardView({
    super.key,
    this.due = const {},
    this.playing = const {},
  });

  /// Notes the level expects right now.
  final Set<int> due;

  /// Notes currently detected from audio.
  final Set<int> playing;

  /// The render's size, and where its keys sit in it, as fractions of the
  /// image (from assets/art/keyboard.json).
  static const double imageAspect = 2880 / 453;
  static const double keysLeft = 0.06716;
  static const double keysRight = 0.93284;
  static const double whiteTop = 0.41978;
  static const double whiteBottom = 0.88404;
  static const double blackTop = 0.346;
  static const double blackBottom = 0.64079;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/art/keyboard.png',
          fit: BoxFit.fitWidth,
          alignment: Alignment.bottomCenter,
          excludeFromSemantics: true,
        ),
        CustomPaint(
          size: Size.infinite,
          painter: _KeyboardPainter(
            colors: PianoTheme.colorsOf(context),
            due: due,
            playing: playing,
          ),
        ),
      ],
    ),
  );
}

class _KeyboardPainter extends CustomPainter {
  _KeyboardPainter({
    required this.colors,
    required this.due,
    required this.playing,
  });

  final PianoColors colors;
  final Set<int> due;
  final Set<int> playing;

  @override
  void paint(Canvas canvas, Size size) {
    final imageHeight = size.width / PianoKeyboardView.imageAspect;
    final top = size.height - imageHeight;
    double y(double f) => top + imageHeight * f;
    final left = size.width * PianoKeyboardView.keysLeft;
    final g = KeyboardGeometry(
      width:
          size.width *
          (PianoKeyboardView.keysRight - PianoKeyboardView.keysLeft),
      height: y(PianoKeyboardView.whiteBottom) - y(PianoKeyboardView.whiteTop),
    );

    for (
      var midi = KeyboardGeometry.lowestMidi;
      midi <= KeyboardGeometry.highestMidi;
      midi++
    ) {
      final tint = _tint(midi);
      final black = g.isBlack(midi);
      if (tint == null && black) continue;
      final keyRect = black
          ? g.blackKeyRect(midi)
          : g.whiteKeyRect(g.whiteIndexFor(midi));
      final rect = Rect.fromLTRB(
        left + keyRect.left + (black ? 0 : 1),
        black ? y(PianoKeyboardView.blackTop) : y(PianoKeyboardView.whiteTop),
        left + keyRect.right - (black ? 0 : 1),
        black
            ? y(PianoKeyboardView.blackBottom)
            : y(PianoKeyboardView.whiteBottom),
      );
      if (tint != null) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          Paint()..color = tint,
        );
      }
      if (!black && midi % 12 == 0) _paintOctaveLabel(canvas, midi, rect);
    }
  }

  /// Played is the app's blue, strong; due is the same blue, light, so the key
  /// you should press and the key you did press read as one family.
  Color? _tint(int midi) {
    if (playing.contains(midi)) return colors.accent.withValues(alpha: 0.72);
    if (due.contains(midi)) return colors.accent.withValues(alpha: 0.32);
    return null;
  }

  void _paintOctaveLabel(Canvas canvas, int midi, Rect key) {
    final painter = TextPainter(
      text: TextSpan(
        text: 'C${midi ~/ 12 - 1}',
        style: TextStyle(
          fontFamily: 'IBMPlexSans',
          fontSize: (key.width * 0.42).clamp(6.0, 11.0),
          color: playing.contains(midi) ? colors.accentInk : colors.staff,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        key.left + (key.width - painter.width) / 2,
        key.bottom - painter.height - key.width * 0.25,
      ),
    );
  }

  @override
  bool shouldRepaint(_KeyboardPainter old) =>
      old.colors != colors ||
      !setEquals(old.due, due) ||
      !setEquals(old.playing, playing);
}
