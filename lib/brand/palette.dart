import 'package:flutter/painting.dart';

/// Brand colours from `brand/README.md`. One accent; every neutral sits on the
/// accent's hue so the greys stay cool.
abstract final class Palette {
  static const lacquer = Color(0xFF0A0A0B);
  static const paper = Color(0xFFECEEF1);
  static const ink = Color(0xFF141519);
  static const graphite = Color(0xFF4E535C);
  static const pencilBlue = Color(0xFF2456C8);
  static const pencilBlueOnDark = Color(0xFF6591E1);

  /// Secondary text on lacquer. About 8:1 against [lacquer].
  static const quietOnDark = Color(0xFFA7ACB5);
}

abstract final class Fonts {
  static const display = 'CormorantGaramond';
  static const text = 'IBMPlexSans';
  static const music = 'Bravura';
}
