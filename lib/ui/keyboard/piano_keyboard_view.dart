import 'dart:math' as math;

import 'package:flutter/foundation.dart' show mapEquals, setEquals;
import 'package:flutter/scheduler.dart' show Ticker;
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
class PianoKeyboardView extends StatefulWidget {
  const PianoKeyboardView({
    super.key,
    this.due = const {},
    this.playing = const {},
    this.range,
    this.noteNames = false,
  });

  /// Notes the level expects right now.
  final Set<int> due;

  /// Notes currently detected from audio.
  final Set<int> playing;

  /// Keys to fill the width with, from a white key to a white key. Null
  /// shows all 61. The range is fixed by the caller, never moved to follow
  /// the music, so the keyboard does not slide while the learner reads.
  final KeyRange? range;

  /// Letter names on the white keys.
  final bool noteNames;

  /// The render's size, and where its keys sit in it, as fractions of the
  /// image (from assets/art/keyboard.json).
  static const double imageAspect = 2880 / 453;
  static const double keysLeft = 0.06716;
  static const double keysRight = 0.93284;
  static const double whiteTop = 0.41978;

  /// keyboard.json gives 0.884 here, which is the foot of the key rail; the
  /// white keys' front lip ends higher, at 0.815, measured on the render.
  /// A tint drawn to the rail spills below the key.
  static const double whiteBottom = 0.815;
  static const double blackTop = 0.346;
  static const double blackBottom = 0.64079;

  /// How much of the render above the black keys a zoomed view keeps.
  static const double _zoomTop = 0.33;

  /// Width of the whole keyboard, and its left offset, so [range] fills a
  /// [viewport]. The zoom stops where the keys would no longer fit the
  /// height, and never shrinks the keyboard below the viewport.
  static ({double width, double left}) zoomFor(Size viewport, KeyRange range) {
    const g = KeyboardGeometry(width: 1, height: 1);
    final first = g.whiteIndexFor(range.low);
    final whiteCount = g.whiteIndexFor(range.high) - first + 1;
    const whiteFraction =
        (keysRight - keysLeft) / KeyboardGeometry.whiteKeyCount;

    final fitWidth = viewport.width / (whiteCount * whiteFraction);
    final fitHeight = viewport.height * imageAspect / (1 - _zoomTop);
    final width = math.max(viewport.width, math.min(fitWidth, fitHeight));

    final centre =
        width * keysLeft + (first + whiteCount / 2) * whiteFraction * width;
    final left = (viewport.width / 2 - centre).clamp(
      viewport.width - width,
      0.0,
    );
    return (width: width, left: left);
  }

  @override
  State<PianoKeyboardView> createState() => _PianoKeyboardViewState();
}

/// Keys go down quickly and come back up a little slower, the way a real
/// key returns under its spring.
class _PianoKeyboardViewState extends State<PianoKeyboardView>
    with SingleTickerProviderStateMixin {
  static const _pressTime = Duration(milliseconds: 60);
  static const _releaseTime = Duration(milliseconds: 200);

  late final Ticker _ticker = createTicker(_onTick);
  final Map<int, double> _depth = {};
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    for (final key in widget.playing) {
      _depth[key] = 1;
    }
  }

  @override
  void didUpdateWidget(PianoKeyboardView old) {
    super.didUpdateWidget(old);
    if (setEquals(old.playing, widget.playing)) return;
    if (MediaQuery.of(context).disableAnimations) {
      _depth
        ..clear()
        ..addEntries(widget.playing.map((k) => MapEntry(k, 1)));
      return;
    }
    for (final key in widget.playing) {
      _depth.putIfAbsent(key, () => 0);
    }
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final dt = elapsed - _last;
    _last = elapsed;
    var moving = false;
    setState(() {
      for (final key in _depth.keys.toList()) {
        final down = widget.playing.contains(key);
        final step =
            dt.inMicroseconds /
            (down ? _pressTime : _releaseTime).inMicroseconds;
        final next = (_depth[key]! + (down ? step : -step)).clamp(0.0, 1.0);
        if (next == 0 && !down) {
          _depth.remove(key);
        } else {
          _depth[key] = next;
          if (next != (down ? 1 : 0)) moving = true;
        }
      }
    });
    if (!moving) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final widget = this.widget;
    final keyboard = Stack(
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
            due: widget.due,
            depth: Map.of(_depth),
            noteNames: widget.noteNames,
          ),
        ),
      ],
    );
    final r = widget.range;
    if (r == null) return ClipRect(child: keyboard);

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final zoom = PianoKeyboardView.zoomFor(constraints.biggest, r);
          return Stack(
            children: [
              Positioned(
                left: zoom.left,
                top: 0,
                bottom: 0,
                width: zoom.width,
                child: keyboard,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A span of keys, lowest to highest, as MIDI numbers.
typedef KeyRange = ({int low, int high});

/// The octaves a piece uses, from the C at or below its lowest note to the
/// C at or above its highest, at least two octaves wide, within the 61 keys.
KeyRange keyRangeFor(Iterable<int> notes) {
  if (notes.isEmpty) return (low: 48, high: 72);
  var low = notes.reduce(math.min) ~/ 12 * 12;
  var high = (notes.reduce(math.max) + 11) ~/ 12 * 12;
  // Widen downward first: beginner music sits around middle C.
  while (high - low < 24) {
    if (low - 12 >= KeyboardGeometry.lowestMidi) {
      low -= 12;
    } else {
      high += 12;
    }
  }
  return (
    low: math.max(low, KeyboardGeometry.lowestMidi),
    high: math.min(high, KeyboardGeometry.highestMidi),
  );
}

class _KeyboardPainter extends CustomPainter {
  _KeyboardPainter({
    required this.colors,
    required this.due,
    required this.depth,
    required this.noteNames,
  });

  final PianoColors colors;
  final Set<int> due;

  /// How far each played key is pressed, 0 (up) to 1 (down).
  final Map<int, double> depth;
  final bool noteNames;

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
      final d = depth[midi] ?? 0;
      // A pressed key sinks a little and its front edge falls into shadow.
      final pressed = rect.shift(Offset(0, d * rect.height * 0.025));
      if (tint != null) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(pressed, const Radius.circular(2)),
          Paint()..color = tint,
        );
      }
      if (d > 0) {
        canvas.drawRect(
          Rect.fromLTWH(
            pressed.left,
            pressed.top,
            pressed.width,
            pressed.height * 0.06 * d,
          ),
          Paint()..color = const Color(0xFF000000).withValues(alpha: 0.35 * d),
        );
      }
      if (!black && (noteNames || midi % 12 == 0)) {
        _paintKeyLabel(canvas, midi, pressed);
      }
    }
  }

  /// Played is the app's blue, strong; due is the same blue, light, so the key
  /// you should press and the key you did press read as one family.
  Color? _tint(int midi) {
    final d = depth[midi] ?? 0;
    final dueAlpha = due.contains(midi) ? 0.32 : 0.0;
    final alpha = dueAlpha + (0.72 - dueAlpha) * d;
    return alpha > 0 ? colors.accent.withValues(alpha: alpha) : null;
  }

  static const _letters = [
    'C',
    '',
    'D',
    '',
    'E',
    'F',
    '',
    'G',
    '',
    'A',
    '',
    'B',
  ];

  /// Every C carries its octave, so the keyboard stays oriented however
  /// far it is zoomed; with note names on, the other white keys get their
  /// letter.
  void _paintKeyLabel(Canvas canvas, int midi, Rect key) {
    final painter = TextPainter(
      text: TextSpan(
        text: midi % 12 == 0 ? 'C${midi ~/ 12 - 1}' : _letters[midi % 12],
        style: TextStyle(
          fontFamily: 'IBMPlexSans',
          fontSize: (key.width * 0.42).clamp(6.0, 14.0),
          color: (depth[midi] ?? 0) > 0.5 ? colors.accentInk : colors.staff,
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
      old.noteNames != noteNames ||
      !setEquals(old.due, due) ||
      !mapEquals(old.depth, depth);
}
