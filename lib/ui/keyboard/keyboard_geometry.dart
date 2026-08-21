import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart' show immutable;

/// Key positions for a 61 key keyboard, C2 to C7.
///
/// Sized from the space available rather than a fixed key width. The keyboard
/// is visualization only, so keys do not need a touch target and all 61 fit
/// across a landscape screen without scrolling.
@immutable
class KeyboardGeometry {
  const KeyboardGeometry({required this.width, required this.height});

  final double width;
  final double height;

  static const int lowestMidi = 36; // C2
  static const int highestMidi = 96; // C7
  static const int whiteKeyCount = 36;

  /// Semitone offsets within an octave that are black keys.
  static const Set<int> _blackOffsets = {1, 3, 6, 8, 10};

  /// White-key ordinal of each natural within an octave.
  static const List<int> _whiteOrdinal = [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6];

  double get whiteKeyWidth => width / whiteKeyCount;
  double get blackKeyWidth => whiteKeyWidth * 0.62;
  double get blackKeyHeight => height * 0.6;

  bool isBlack(int midi) => _blackOffsets.contains(midi % 12);

  /// Index of the white key at or below [midi], counting from C2.
  int whiteIndexFor(int midi) {
    final semitones = midi - lowestMidi;
    final octaves = semitones ~/ 12;
    return octaves * 7 + _whiteOrdinal[midi % 12];
  }

  Rect whiteKeyRect(int index) =>
      Rect.fromLTWH(index * whiteKeyWidth, 0, whiteKeyWidth, height);

  /// A black key is centred on the boundary between the two white keys it
  /// sits between, which is where it lands on a real instrument.
  Rect blackKeyRect(int midi) {
    final boundary = (whiteIndexFor(midi) + 1) * whiteKeyWidth;
    return Rect.fromLTWH(
      boundary - blackKeyWidth / 2,
      0,
      blackKeyWidth,
      blackKeyHeight,
    );
  }
}
