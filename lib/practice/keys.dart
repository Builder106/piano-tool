import 'dart:math' as math;

import 'package:flutter/material.dart';

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

/// A keyboard to look at, not to play: the keys heard right now are pressed
/// in blue, and the key to play next is circled in blue pencil.
class PaperKeyboard extends StatelessWidget {
  const PaperKeyboard({
    super.key,
    required this.low,
    required this.high,
    this.sounding = const {},
    this.next,
  });

  final int low;
  final int high;
  final Set<int> sounding;

  /// The note to play next, or null.
  final int? next;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: next == null ? 'Keyboard' : 'Keyboard. Next note ${noteName(next!)}',
      child: ExcludeSemantics(
        child: CustomPaint(
          painter: _KeysPainter(
            low: low,
            high: high,
            sounding: sounding,
            next: next,
          ),
          child: const SizedBox.expand(),
        ),
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
  });

  final int low;
  final int high;
  final Set<int> sounding;
  final int? next;

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
      canvas.drawRRect(
        r,
        Paint()..color = pressed ? const Color(0xFFD7E1FF) : Palette.page,
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
      final isNext = m == next;
      _label(
        canvas,
        _noteLetters[_whiteOffsets.indexOf(m % 12)],
        Offset(x + w / 2, size.height - w * 0.34),
        w * 0.3,
        isNext ? Palette.pencilBlue : Palette.graphite,
        isNext ? 800 : 600,
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
          ..color = sounding.contains(m) ? Palette.pencilBlue : Palette.ink,
      );
    }

    // The next key, circled in pencil.
    final target = next;
    if (target != null && target >= low && target <= high) {
      final double cx;
      if (isBlackKey(target)) {
        cx = whiteX[target - 1]! + w;
      } else {
        cx = whiteX[target]! + w / 2;
      }
      final top = isBlackKey(target) ? 0.0 : blackH;
      final bottom = isBlackKey(target) ? blackH : size.height;
      final centre = Offset(cx, top + (bottom - top) * (isBlackKey(target) ? 0.72 : 0.5));
      PencilLoopPainter(
        target: Rect.fromCenter(
          center: centre,
          width: w * 0.95,
          height: math.min((bottom - top) * 0.62, w * 1.5),
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
      !_sameSet(old.sounding, sounding);

  static bool _sameSet(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);
}
