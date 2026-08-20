import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/ui/keyboard/piano_keyboard_view.dart';
import 'package:piano_tool/ui/theme/app_theme.dart';

Widget _harness(ThemeData theme, {Set<int> due = const {}, Set<int> playing = const {}}) =>
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: SizedBox(
          width: 720,
          height: 80,
          child: PianoKeyboardView(due: due, playing: playing),
        ),
      ),
    );

void main() {
  testWidgets('renders without overflow at a narrow landscape width', (tester) async {
    await tester.pumpWidget(_harness(PianoTheme.light()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('has no gesture detector, because it is visualization only',
      (tester) async {
    await tester.pumpWidget(_harness(PianoTheme.light()));
    expect(find.byType(GestureDetector), findsNothing);
  });

  testWidgets('does not scroll', (tester) async {
    await tester.pumpWidget(_harness(PianoTheme.light()));
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.byType(Scrollable), findsNothing);
  });

  testWidgets('repaints when the played set changes', (tester) async {
    await tester.pumpWidget(_harness(PianoTheme.light(), playing: const {60}));
    final first = tester.widget<CustomPaint>(
      find.descendant(of: find.byType(PianoKeyboardView), matching: find.byType(CustomPaint)).first,
    );
    await tester.pumpWidget(_harness(PianoTheme.light(), playing: const {62}));
    final second = tester.widget<CustomPaint>(
      find.descendant(of: find.byType(PianoKeyboardView), matching: find.byType(CustomPaint)).first,
    );
    expect(
      (second.painter as dynamic).shouldRepaint(first.painter),
      isTrue,
    );
  });
}
