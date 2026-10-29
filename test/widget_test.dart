import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/ui/theme/app_theme.dart';
import 'package:piano_tool/ui/theme/tokens.dart';

void main() {
  testWidgets('app applies the Piano-Tool theme', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: PianoTheme.light(),
        darkTheme: PianoTheme.dark(),
        home: Builder(
          builder: (c) {
            ctx = c;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );
    // The ground is the piano's lacquer; paper sheets sit on it.
    expect(Theme.of(ctx).scaffoldBackgroundColor, PianoColors.light().desk);
    expect(PianoTheme.colorsOf(ctx).accent, PianoColors.light().accent);
  });
}
