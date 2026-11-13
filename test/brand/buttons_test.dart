import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/brand/buttons.dart';

void main() {
  Future<void> show(WidgetTester tester, Widget button, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Column(children: [button])),
      ),
    );
  }

  /// Where the letters are drawn, not the box Flutter gave the Text widget:
  /// a Text stretched by a minimum height still draws from its top edge.
  Offset drawnCenter(WidgetTester tester, String label) {
    final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
    final lines = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: label.length),
    );
    final drawn = lines
        .map((box) => box.toRect())
        .reduce((a, b) => a.expandToInclude(b));
    return paragraph.localToGlobal(drawn.center);
  }

  for (final (name, size) in [
    ('a phone', const Size(412, 892)),
    ('a laptop', const Size(1280, 800)),
  ]) {
    testWidgets('the label sits in the middle of a quiet button on $name', (
      tester,
    ) async {
      await show(tester, const QuietButton(label: 'Stop'), size);

      final box = tester.getRect(find.byType(QuietButton));
      final label = drawnCenter(tester, 'Stop');

      expect(label.dy, closeTo(box.center.dy, 0.5));
      expect(label.dx, closeTo(box.center.dx, 0.5));
    });

    testWidgets('the label sits in the middle of a start button on $name', (
      tester,
    ) async {
      await show(tester, const StartButton(label: 'Make the piece'), size);

      final box = tester.getRect(find.byType(StartButton));
      final label = drawnCenter(tester, 'Make the piece');

      expect(label.dy, closeTo(box.center.dy, 0.5));
      expect(label.dx, closeTo(box.center.dx, 0.5));
    });
  }
}
