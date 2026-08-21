import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const expected = [
    'assets/fonts/CormorantGaramond.ttf',
    'assets/fonts/IBMPlexSans.ttf',
    'assets/fonts/Bravura.otf',
  ];

  for (final path in expected) {
    test('$path is bundled and non-empty', () async {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(1000));
    });
  }

  test('Bravura contains the treble and bass clef glyphs', () async {
    final data = await rootBundle.load('assets/fonts/Bravura.otf');
    await ui.loadFontFromList(data.buffer.asUint8List(), fontFamily: 'Bravura');

    // U+E050 gClef, U+E062 fClef in the SMuFL private-use range.
    for (final code in [0xE050, 0xE062]) {
      final builder =
          ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Bravura'))
            ..addText(String.fromCharCode(code));
      final paragraph = builder.build()
        ..layout(const ui.ParagraphConstraints(width: 200));
      expect(paragraph.maxIntrinsicWidth, greaterThan(0),
          reason: 'glyph U+${code.toRadixString(16).toUpperCase()} missing');
    }
  });

  test('IBMPlexSans exposes a variable weight axis', () async {
    final data = await rootBundle.load('assets/fonts/IBMPlexSans.ttf');
    final bytes = data.buffer.asUint8List();
    // 'fvar' table tag in the font directory.
    final hasFvar =
        String.fromCharCodes(bytes.sublist(0, 4096)).contains('fvar');
    expect(hasFvar, isTrue);
  });
}
