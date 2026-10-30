import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/ui/keyboard/piano_keyboard_view.dart';

void main() {
  test('a piece around middle C gets the two octaves below and above', () {
    expect(keyRangeFor([60, 62, 64, 65, 67]), (low: 48, high: 72));
  });

  test('a range spans whole octaves, at least two', () {
    expect(keyRangeFor([55, 76]), (low: 48, high: 84));
    expect(keyRangeFor([37]), (low: 36, high: 60));
  });

  test('zooming fills the width with the range and never shrinks', () {
    const viewport = Size(800, 200);
    final zoom = PianoKeyboardView.zoomFor(viewport, (low: 48, high: 72));
    expect(zoom.width, greaterThan(viewport.width));
    expect(zoom.left, lessThanOrEqualTo(0));
    expect(zoom.left, greaterThanOrEqualTo(viewport.width - zoom.width));

    // All 61 keys fill the width, trimming only the render's side margins.
    final whole = PianoKeyboardView.zoomFor(viewport, (low: 36, high: 96));
    expect(
      whole.width,
      closeTo(
        viewport.width /
            (PianoKeyboardView.keysRight - PianoKeyboardView.keysLeft),
        1e-6,
      ),
    );
    final tiny = PianoKeyboardView.zoomFor(const Size(800, 10), (
      low: 48,
      high: 72,
    ));
    expect(tiny.width, viewport.width);
  });

  test('a short box limits the zoom so the keys keep their height', () {
    final tall = PianoKeyboardView.zoomFor(const Size(800, 400), (
      low: 48,
      high: 72,
    ));
    final short = PianoKeyboardView.zoomFor(const Size(800, 60), (
      low: 48,
      high: 72,
    ));
    expect(short.width, lessThan(tall.width));
  });
}
