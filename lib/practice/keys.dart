import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../brand/palette.dart';
import '../brand/pencil_loop.dart';

const _noteLetters = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
const _whiteOffsets = [0, 2, 4, 5, 7, 9, 11];
const _blackOffsets = {1, 3, 6, 8, 10};

bool isBlackKey(int midi) => _blackOffsets.contains(midi % 12);

const _names = [
  'C', 'C sharp', 'D', 'D sharp', 'E', 'F', //
  'F sharp', 'G', 'G sharp', 'A', 'A sharp', 'B',
];

/// The spoken name of a note, without its octave.
String noteName(int midi) => _names[midi % 12];

/// The octave-aligned span of keys a piece needs: from the C at or below its
/// lowest note up to the B at or above its highest, at least two octaves,
/// centred on the notes.
(int low, int high) keyRange(Iterable<int> midis) {
  if (midis.isEmpty) return (60, 83);
  final lo = midis.reduce(math.min);
  final hi = midis.reduce(math.max);
  var low = lo ~/ 12 * 12;
  var octaves = ((hi - low) ~/ 12) + 1;
  if (octaves < 2) {
    // A piece in the lower half of its octave gets the extra octave above;
    // one in the upper half gets it below.
    if (lo - low >= 6) low -= 12;
    octaves = 2;
  }
  return (low, low + octaves * 12 - 1);
}

/// Which key is under [point] on a keyboard drawn over [size] from [low] to
/// [high], or null. Black keys sit over the white ones, so they are tried
/// first.
int? keyAt(Offset point, Size size, int low, int high) {
  final whites = [
    for (var m = low; m <= high; m++)
      if (!isBlackKey(m)) m,
  ];
  if (whites.isEmpty ||
      point.dx < 0 ||
      point.dx >= size.width ||
      point.dy < 0 ||
      point.dy > size.height) {
    return null;
  }
  final w = size.width / whites.length;
  final blackH = size.height * 0.6;
  final bw = w * 0.62;
  if (point.dy < blackH) {
    for (var m = low; m <= high; m++) {
      if (!isBlackKey(m)) continue;
      final below = whites.indexOf(m - 1);
      if (below < 0) continue;
      final cx = (below + 1) * w;
      if ((point.dx - cx).abs() <= bw / 2) return m;
    }
  }
  return whites[(point.dx / w).floor().clamp(0, whites.length - 1)];
}

/// A keyboard. The keys heard right now are pressed in blue, and the key to
/// play next is circled in blue pencil. With [onPress] the keys can be
/// tapped, for playing on the screen.
class PaperKeyboard extends StatelessWidget {
  const PaperKeyboard({
    super.key,
    required this.low,
    required this.high,
    this.sounding = const {},
    this.next,
    this.circled = const {},
    this.found = const {},
    this.onPress,
  });

  final int low;
  final int high;
  final Set<int> sounding;

  /// The note to play next, or null.
  final int? next;

  /// Keys circled together, as when a few notes are to be found.
  final Set<int> circled;

  /// Keys already found, filled in blue.
  final Set<int> found;

  /// Called with the key as soon as it is touched. Null for a keyboard that
  /// is only to look at.
  final ValueChanged<int>? onPress;

  @override
  Widget build(BuildContext context) {
    final painter = _KeysPainter(
      low: low,
      high: high,
      sounding: sounding,
      next: next,
      circled: circled,
      found: found,
      onPress: onPress,
    );
    final press = onPress;
    if (press == null) {
      return Semantics(
        label: next == null
            ? 'Keyboard'
            : 'Keyboard. Next note ${noteName(next!)}',
        child: ExcludeSemantics(
          child: CustomPaint(painter: painter, child: const SizedBox.expand()),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, box) => Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) {
          final key = keyAt(e.localPosition, box.biggest, low, high);
          if (key != null) press(key);
        },
        child: CustomPaint(painter: painter, child: const SizedBox.expand()),
      ),
    );
  }
}

class _KeysPainter extends CustomPainter {
  _KeysPainter({
    required this.low,
    required this.high,
    required this.sounding,
    required this.next,
    required this.circled,
    required this.found,
    required this.onPress,
  });

  final int low;
  final int high;
  final Set<int> sounding;
  final int? next;
  final Set<int> circled;
  final Set<int> found;
  final ValueChanged<int>? onPress;

  /// One button per key for a screen reader, when the keys can be pressed.
  @override
  SemanticsBuilderCallback? get semanticsBuilder {
    final press = onPress;
    if (press == null) return null;
    return (size) {
      final whites = [
        for (var m = low; m <= high; m++)
          if (!isBlackKey(m)) m,
      ];
      if (whites.isEmpty) return const [];
      final w = size.width / whites.length;
      final blackH = size.height * 0.6;
      final bw = w * 0.62;
      CustomPainterSemantics key(int m, Rect rect) => CustomPainterSemantics(
        rect: rect,
        properties: SemanticsProperties(
          label: '${noteName(m)} ${m ~/ 12 - 1}',
          textDirection: TextDirection.ltr,
          button: true,
          onTap: () => press(m),
        ),
      );
      return [
        for (final (i, m) in whites.indexed)
          key(m, Rect.fromLTWH(i * w, 0, w, size.height)),
        for (var m = low; m <= high; m++)
          if (isBlackKey(m) && whites.contains(m - 1))
            key(
              m,
              Rect.fromLTWH(
                (whites.indexOf(m - 1) + 1) * w - bw / 2,
                0,
                bw,
                blackH,
              ),
            ),
      ];
    };
  }

  @override
  bool shouldRebuildSemantics(_KeysPainter old) =>
      old.low != low || old.high != high || (old.onPress == null) != (onPress == null);

  static final _labels = <(String, double, int), TextPainter>{};

  @override
  void paint(Canvas canvas, Size size) {
    final whites = [
      for (var m = low; m <= high; m++)
        if (!isBlackKey(m)) m,
    ];
    if (whites.isEmpty) return;
    final w = size.width / whites.length;
    final whiteX = {for (final (i, m) in whites.indexed) m: i * w};

    // White keys: a page with a drawn edge, pressed in pale blue.
    for (final m in whites) {
      final x = whiteX[m]!;
      final rect = Rect.fromLTWH(x + 1.5, 0, w - 3, size.height);
      final r = RRect.fromRectAndCorners(
        rect,
        bottomLeft: Radius.circular(w * 0.12),
        bottomRight: Radius.circular(w * 0.12),
      );
      final pressed = sounding.contains(m);
      final isFound = found.contains(m);
      canvas.drawRRect(
        r,
        Paint()
          ..color = isFound
              ? Palette.pencilBlue
              : pressed
              ? const Color(0xFFD7E1FF)
              : Palette.page,
      );
      if (pressed) {
        canvas.drawRRect(
          r,
          Paint()
            ..color = Palette.pencilBlue
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
      final isNext = m == next || circled.contains(m);
      _label(
        canvas,
        _noteLetters[_whiteOffsets.indexOf(m % 12)],
        Offset(x + w / 2, size.height - w * 0.5),
        w * 0.3,
        isFound
            ? Colors.white
            : isNext
            ? Palette.pencilBlue
            : Palette.graphite,
        isNext || isFound ? 800 : 600,
      );
    }

    // Black keys sit on the boundary above their white neighbour.
    final blackH = size.height * 0.6;
    final bw = w * 0.62;
    for (var m = low; m <= high; m++) {
      if (!isBlackKey(m)) continue;
      final below = whiteX[m - 1];
      if (below == null) continue;
      final cx = below + w;
      final rect = Rect.fromLTWH(cx - bw / 2, 0, bw, blackH);
      final r = RRect.fromRectAndCorners(
        rect,
        bottomLeft: Radius.circular(bw * 0.18),
        bottomRight: Radius.circular(bw * 0.18),
      );
      canvas.drawRRect(
        r,
        Paint()
          ..color = sounding.contains(m) || found.contains(m)
              ? Palette.pencilBlue
              : Palette.ink,
      );
    }

    // The next key, and any keys to find, circled in pencil.
    for (final target in {?next, ...circled}) {
      if (target < low || target > high || found.contains(target)) continue;
      final black = isBlackKey(target);
      final cx = black ? whiteX[target - 1]! + w : whiteX[target]! + w / 2;
      // A white key is circled round its letter; a black key near its foot.
      final centre = Offset(cx, black ? blackH * 0.72 : size.height - w * 0.5);
      PencilLoopPainter(
        target: Rect.fromCenter(
          center: centre,
          width: w * (black ? 0.7 : 0.92),
          height: w * (black ? 0.8 : 0.84),
        ),
      ).paint(canvas, size);
    }
  }

  void _label(
    Canvas canvas,
    String text,
    Offset centre,
    double size,
    Color color,
    int weight,
  ) {
    if (_labels.length > 128) _labels.clear();
    final tp = _labels.putIfAbsent((text, size, color.toARGB32() + weight), () {
      return TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: Fonts.ui,
            fontSize: size,
            color: color,
            fontVariations: [FontVariation('wght', weight.toDouble())],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
    tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_KeysPainter old) =>
      old.low != low ||
      old.high != high ||
      old.next != next ||
      !_sameSet(old.sounding, sounding) ||
      !_sameSet(old.circled, circled) ||
      !_sameSet(old.found, found);

  static bool _sameSet(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);
}
