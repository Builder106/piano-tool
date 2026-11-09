import 'package:flutter/painting.dart';

/// Brand colours. The app is a method book: a blue field, white pages, ink
/// engraving, and a teacher's two pencils, blue for what to play and red for
/// what to fix.
abstract final class Palette {
  /// The field the pages lie on.
  static const field = Color(0xFF1F4FE0);

  /// A page of the book.
  static const page = Color(0xFFFFFFFF);
  static const ink = Color(0xFF111327);

  /// Secondary text on a page. About 6:1 against [page].
  static const graphite = Color(0xFF5B6075);

  /// Rules and resting detail on a page.
  static const rule = Color(0xFFD9DDEA);
  static const pencilBlue = Color(0xFF1F4FE0);
  static const pencilRed = Color(0xFFF0402A);

  /// Secondary text on the field. About 5:1 against [field].
  static const quietOnField = Color(0xFFDCE4FF);
}

abstract final class Fonts {
  static const ui = 'AtkinsonHyperlegibleNext';
  static const music = 'Bravura';
}
