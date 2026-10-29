import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

/// One stroke of a pencil drawing: SVG path data and its pen width.
typedef PencilStroke = ({String d, double width});

/// The pencil vocabulary and the margin doodles, drawn in Glaxnimate
/// (design/glaxnimate/app-marks.svg and app-doodles.svg, and the site's
/// tortoise, listen and plug sketches). Each keeps the coordinates of its own
/// drawing; [frame] is the part of that drawing with ink in it.
enum Pencil {
  loop(Rect.fromLTWH(0, 0, 96, 62), [
    (
      d:
          'M78 12 C66 1 30 -1 13 10 C-2 20 0 44 18 54 C36 64 72 60 86 46 '
          'C97 34 94 18 80 10 C70 5 55 4 46 6',
      width: 2.2,
    ),
  ]),
  tick(Rect.fromLTWH(0, 0, 31, 24), [
    (d: 'M2 13 C5 15 8 18 10 22 C14 13 20 6 29 1', width: 2.4),
  ]),
  star(Rect.fromLTWH(0, 0, 120, 112), [
    (
      d:
          'M60 10 L72 44 L108 45 L80 67 L91 102 L60 81 L30 103 L40 68 '
          'L11 47 L48 44 L61 12',
      width: 2.4,
    ),
  ]),
  padlock(Rect.fromLTWH(0, 0, 40, 40), [
    (d: 'M11 18 C10.5 11 13 5 20 5 C27 5 29.5 11 29 18', width: 2.2),
    (
      d:
          'M7 18.5 C15 17.8 25 18.2 33 18 C33.4 24 33 31 33.2 36.5 '
          'C24 37.2 15 36.8 7.2 37 C6.8 31 7.3 24 7 18.5',
      width: 2.2,
    ),
    (d: 'M20 24.5 C18.6 25.4 19.2 27.6 20 28 L20.2 31.5', width: 2),
  ]),
  underline(Rect.fromLTWH(0, 0, 120, 8), [
    (d: 'M2 5 C22 2 44 6 66 4 C84 2 102 5 118 3', width: 1.8),
  ]),
  tortoise(Rect.fromLTWH(18, 18, 182, 86), [
    (d: 'M40 80 C42 42 78 23 110 24 C146 26 166 52 166 80', width: 2.2),
    (d: 'M32 81 C80 85 130 85 174 80', width: 2),
    (
      d:
          'M70 79 C72 61 86 47 104 45 C124 47 138 61 140 79 M104 45 L106 26 '
          'M72 62 L52 54 M138 62 L158 55',
      width: 1.4,
    ),
    (d: 'M168 72 C176 60 194 61 196 73 C197 84 184 89 171 83', width: 2),
    (
      d: 'M184.5 70 C184.5 68 187.5 68 187.5 70 C187.5 72 184.5 72 184.5 70',
      width: 2,
    ),
    (d: 'M60 83 C57 93 64 99 73 96 M140 83 C140 93 147 99 155 95', width: 2),
    (d: 'M36 79 C29 81 25 85 23 89', width: 1.8),
  ]),
  hare(Rect.fromLTWH(0, 2, 188, 98), [
    (
      d: 'M50 70 C55 48 95 40 125 46 C148 51 158 62 155 74 C150 86 110 90 80 88 C62 87 48 82 50 70',
      width: 2.2,
    ),
    (
      d: 'M150 52 C152 40 168 36 178 44 C186 51 182 62 170 64 C162 65 155 61 152 57',
      width: 2.2,
    ),
    (
      d: 'M160 40 C158 24 160 10 166 6 C170 14 170 28 166 40 M168 40 C170 26 176 14 182 12 C184 20 180 32 174 42',
      width: 2,
    ),
    (d: 'M171 47 C172 45 175 46 174 48 C173 50 170 49 171 47', width: 2),
    (d: 'M140 84 C150 92 162 96 176 94 M62 86 C50 92 36 96 20 92', width: 2),
    (d: 'M50 64 C42 60 38 66 44 70', width: 1.8),
    (d: 'M10 54 L34 54 M4 66 L28 66 M14 78 L32 78', width: 1.6),
  ]),
  lamp(Rect.fromLTWH(14, 8, 112, 96), [
    (
      d: 'M20 100 C40 98 70 98 90 100 C90 94 86 90 80 89 C64 88 46 88 32 89 C26 90 21 94 20 100',
      width: 2.2,
    ),
    (d: 'M55 89 L42 52 L72 26', width: 2.2),
    (d: 'M39 52 C39 49 45 49 45 52 C45 55 39 55 39 52', width: 2),
    (
      d: 'M64 18 C78 10 98 16 104 30 C106 36 100 40 92 38 L66 30 C60 28 60 22 64 18',
      width: 2.2,
    ),
    (d: 'M86 38 C86 44 94 46 97 41', width: 1.8),
  ]),

  /// The light from [lamp], drawn in the same frame so the two stack.
  lampRays(Rect.fromLTWH(14, 8, 112, 96), [
    (d: 'M96 52 L104 68 M86 52 L85 70 M106 46 L120 56', width: 1.8),
  ]),
  metronome(Rect.fromLTWH(14, 4, 62, 100), [
    (d: 'M25 100 L40 12 C42 8 48 8 50 12 L65 100 Z', width: 2.2),
    (d: 'M18 100 C40 99 60 99 72 100', width: 2),
    (d: 'M33 72 C40 71 50 71 57 72', width: 1.6),
    (d: 'M45 84 L60 30', width: 2),
    (d: 'M55 50 L63 52 L61 58 L53 56 Z', width: 2),
  ]),
  listen(Rect.fromLTWH(144, 20, 180, 128), [
    (d: 'M150 142 C200 140 262 143 318 141', width: 2),
    (
      d:
          'M206 26 C232 23 258 23 276 26 C281 28 282 33 282 39 L281 128 '
          'C281 134 278 138 272 138 L212 139 C205 139 202 135 202 129 '
          'L203 36 C203 30 204 27 206 26',
      width: 2.2,
    ),
    (
      d:
          'M214 66 L270 66 M214 74 L270 74 M214 82 L270 82 M214 90 L270 90 '
          'M214 98 L270 98',
      width: 1.2,
    ),
    (
      d: 'M233 95 C233 91 243 89 243 93 C243 97 233 99 233 95 M243 93 L243 70',
      width: 2,
    ),
    (d: 'M150 66 C160 76 160 96 150 106', width: 2),
    (d: 'M168 54 C184 70 184 102 168 118', width: 2),
    (d: 'M186 44 C206 64 206 108 186 128', width: 1.6),
  ]),
  plug(Rect.fromLTWH(6, 22, 344, 112), [
    (
      d: 'M12 84 C60 82 110 83 158 85 L157 126 C110 128 60 127 13 125 Z',
      width: 2.2,
    ),
    (
      d:
          'M30 98 L30 125 M48 98 L48 125 M66 98 L66 125 M84 98 L84 126 '
          'M102 98 L102 126 M120 98 L120 126 M138 98 L138 126 '
          'M14 98 C60 97 110 97 157 99',
      width: 1.3,
    ),
    (
      d: 'M39 99 L39 112 M57 99 L57 112 M93 99 L93 112 M111 99 L111 112 M129 99 L129 112',
      width: 3.4,
    ),
    (d: 'M158 92 C200 92 196 146 226 140 C236 138 238 132 238 128', width: 2),
    (
      d:
          'M236 30 C270 28 310 28 340 31 C344 33 345 37 345 42 L344 120 '
          'C344 125 341 128 336 128 L240 129 C235 129 232 126 232 121 '
          'L233 38 C233 33 234 31 236 30',
      width: 2.2,
    ),
    (
      d:
          'M248 62 L330 62 M248 70 L330 70 M248 78 L330 78 M248 86 L330 86 '
          'M248 94 L330 94',
      width: 1.2,
    ),
    (
      d: 'M285 75 C285 71 295 69 295 73 C295 77 285 79 285 75 M295 73 L295 50',
      width: 2,
    ),
  ]);

  const Pencil(this.frame, this.strokes);

  final Rect frame;
  final List<PencilStroke> strokes;
}

/// Parses the absolute M, L, C and Z commands the pencil drawings use.
Path parsePencilPath(String d) {
  final path = Path();
  final tokens = [
    for (final m in RegExp(r'[MLCZ]|-?\d*\.?\d+').allMatches(d)) m[0]!,
  ];
  String? command;
  var i = 0;
  double read() => double.parse(tokens[i++]);
  while (i < tokens.length) {
    final token = tokens[i];
    if (const {'M', 'L', 'C', 'Z'}.contains(token)) {
      command = token;
      i++;
      if (command == 'Z') path.close();
      continue;
    }
    switch (command) {
      case 'M':
        path.moveTo(read(), read());
        command = 'L';
      case 'L':
        path.lineTo(read(), read());
      case 'C':
        path.cubicTo(read(), read(), read(), read(), read(), read());
      default:
        throw FormatException('Unsupported path data', d);
    }
  }
  return path;
}

/// A pencil drawing in its box, optionally drawn on stroke by stroke the way
/// a hand would make it. Reduced motion shows it complete.
class PencilMark extends StatefulWidget {
  const PencilMark(
    this.pencil, {
    super.key,
    required this.color,
    this.width,
    this.height,
    this.stretch = false,
    this.drawOn = false,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 650),
  });

  final Pencil pencil;
  final Color color;
  final double? width;
  final double? height;

  /// Fill both [width] and [height], as a loop round a word does. Otherwise
  /// the drawing keeps its proportions.
  final bool stretch;
  final bool drawOn;
  final Duration delay;
  final Duration duration;

  @override
  State<PencilMark> createState() => _PencilMarkState();
}

class _PencilMarkState extends State<PencilMark>
    with SingleTickerProviderStateMixin {
  // The delay is the opening stretch of one animation rather than a timer, so
  // nothing is left pending when the mark leaves the screen.
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
    value: widget.drawOn ? 0 : 1,
  );

  late final Animation<double> _stroke = CurvedAnimation(
    parent: _draw,
    curve: Interval(
      widget.delay.inMicroseconds /
          (widget.delay + widget.duration).inMicroseconds,
      1,
      curve: Curves.easeInOut,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.drawOn || _draw.value == 1 || _draw.isAnimating) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _draw.value = 1;
    } else {
      _draw.forward();
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = widget.pencil.frame;
    final aspect = frame.width / frame.height;
    final drawing = AnimatedBuilder(
      animation: _stroke,
      builder: (context, _) => CustomPaint(
        painter: _PencilPainter(
          pencil: widget.pencil,
          color: widget.color,
          stretch: widget.stretch,
          progress: _stroke.value,
        ),
      ),
    );
    // A stretched mark with no size of its own fills whatever holds it.
    if (widget.stretch && widget.width == null && widget.height == null) {
      return ExcludeSemantics(child: SizedBox.expand(child: drawing));
    }
    final width = widget.width ?? (widget.height ?? frame.height) * aspect;
    final height = widget.height ?? width / aspect;
    return ExcludeSemantics(
      child: SizedBox(width: width, height: height, child: drawing),
    );
  }
}

class _PencilPainter extends CustomPainter {
  _PencilPainter({
    required this.pencil,
    required this.color,
    required this.stretch,
    required this.progress,
  });

  final Pencil pencil;
  final Color color;
  final bool stretch;
  final double progress;

  static final Map<String, Path> _cache = {};

  @override
  void paint(Canvas canvas, Size size) {
    final frame = pencil.frame;
    var sx = size.width / frame.width;
    var sy = size.height / frame.height;
    var dx = 0.0, dy = 0.0;
    if (!stretch) {
      final s = sx < sy ? sx : sy;
      dx = (size.width - frame.width * s) / 2;
      dy = (size.height - frame.height * s) / 2;
      sx = sy = s;
    }
    final place = Matrix4.identity()
      ..translateByDouble(dx - frame.left * sx, dy - frame.top * sy, 0, 1)
      ..scaleByDouble(sx, sy, 1, 1);
    // A pencil keeps roughly its own weight whatever size the drawing is.
    final weight = ((sx + sy) / 2).clamp(0.7, 1.3);

    final strokes = pencil.strokes;
    // Strokes draw one after another, each taking an equal share of the time.
    for (final (index, stroke) in strokes.indexed) {
      final share = (progress * strokes.length - index).clamp(0.0, 1.0);
      if (share == 0) break;
      final path = _cache
          .putIfAbsent(stroke.d, () => parsePencilPath(stroke.d))
          .transform(place.storage);
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.width * weight;
      if (share >= 1) {
        canvas.drawPath(path, paint);
        continue;
      }
      for (final PathMetric metric in path.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * share), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PencilPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.pencil != pencil ||
      old.stretch != stretch;
}
