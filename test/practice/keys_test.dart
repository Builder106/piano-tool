import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/practice/keys.dart';

void main() {
  group('keyAt', () {
    const size = Size(1400, 200);

    test('a white key is found by its column', () {
      expect(keyAt(const Offset(50, 190), size, 60, 83), 60);
      expect(keyAt(const Offset(150, 190), size, 60, 83), 62);
      expect(keyAt(const Offset(1390, 190), size, 60, 83), 83);
    });

    test('a black key wins in the top part, a white key below it', () {
      expect(keyAt(const Offset(100, 50), size, 60, 83), 61);
      expect(keyAt(const Offset(90, 150), size, 60, 83), 60);
      expect(keyAt(const Offset(60, 50), size, 60, 83), 60);
      expect(keyAt(const Offset(200, 50), size, 60, 83), 63);
    });

    test('there is no black key between E and F', () {
      expect(keyAt(const Offset(290, 50), size, 60, 83), 64);
      expect(keyAt(const Offset(310, 50), size, 60, 83), 65);
    });

    test('outside the keyboard is no key', () {
      expect(keyAt(const Offset(-1, 50), size, 60, 83), isNull);
      expect(keyAt(const Offset(1400, 50), size, 60, 83), isNull);
      expect(keyAt(const Offset(50, 201), size, 60, 83), isNull);
    });
  });

  testWidgets('a keyboard with onPress reports a touched key', (tester) async {
    tester.view.physicalSize = const Size(1400, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final pressed = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 1400,
            height: 200,
            child: PaperKeyboard(low: 60, high: 83, onPress: pressed.add),
          ),
        ),
      ),
    );
    final box = tester.getTopLeft(find.byType(PaperKeyboard));
    await tester.tapAt(box + const Offset(50, 190));
    await tester.tapAt(box + const Offset(100, 50));
    expect(pressed, [60, 61]);
  });

  testWidgets('a keyboard without onPress ignores touches', (tester) async {
    tester.view.physicalSize = const Size(1400, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 1400,
            height: 200,
            child: PaperKeyboard(low: 60, high: 83),
          ),
        ),
      ),
    );
    await tester.tapAt(const Offset(10, 10));
    expect(tester.takeException(), isNull);
  });
}
