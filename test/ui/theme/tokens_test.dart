import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/ui/theme/tokens.dart';

double _channel(int argb, int shift) => ((argb >> shift) & 0xFF) / 255.0;

double _linear(double c) =>
    c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(int argb) =>
    0.2126 * _linear(_channel(argb, 16)) +
    0.7152 * _linear(_channel(argb, 8)) +
    0.0722 * _linear(_channel(argb, 0));

double _contrast(int a, int b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final entry in {'light': argbLight, 'dark': argbDark}.entries) {
    final name = entry.key;
    final t = entry.value;

    test('$name: text tokens clear 4.5:1 on paper', () {
      for (final key in ['ink', 'ink2', 'muted', 'accent', 'success', 'error']) {
        expect(_contrast(t[key]!, t['paper']!), greaterThanOrEqualTo(4.5),
            reason: '$name.$key on paper');
      }
    });

    test('$name: staff lines clear 3:1 on paper', () {
      expect(_contrast(t['staff']!, t['paper']!), greaterThanOrEqualTo(3.0));
    });

    test('$name: accentInk is readable on accent', () {
      expect(_contrast(t['accentInk']!, t['accent']!), greaterThanOrEqualTo(4.5));
    });

    test('$name: every token is fully opaque', () {
      for (final e in t.entries) {
        expect((e.value >> 24) & 0xFF, 0xFF, reason: '${e.key} must be opaque');
      }
    });
  }

  test('light and dark define the same token names', () {
    expect(argbLight.keys.toSet(), argbDark.keys.toSet());
  });

  test('instances of the same theme compare equal', () {
    expect(PianoColors.light(), PianoColors.light());
    expect(PianoColors.light() == PianoColors.dark(), isFalse);
  });
}
