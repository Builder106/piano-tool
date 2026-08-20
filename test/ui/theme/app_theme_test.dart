import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/ui/theme/app_theme.dart';
import 'package:piano_tool/ui/theme/tokens.dart';

void main() {
  testWidgets('light theme exposes tokens and uses the bundled faces',
      (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      theme: PianoTheme.light(),
      home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }),
    ));

    final colors = PianoTheme.colorsOf(ctx);
    expect(colors.paper, PianoColors.light().paper);
    expect(colors.accent, PianoColors.light().accent);

    final theme = Theme.of(ctx);
    expect(theme.scaffoldBackgroundColor, PianoColors.light().paper);
    expect(theme.textTheme.bodyMedium!.fontFamily, 'IBMPlexSans');
    expect(theme.textTheme.headlineSmall!.fontFamily, 'CormorantGaramond');
  });

  testWidgets('dark theme swaps tokens but keeps the same families',
      (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      theme: PianoTheme.dark(),
      home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }),
    ));

    expect(PianoTheme.colorsOf(ctx).paper, PianoColors.dark().paper);
    expect(Theme.of(ctx).textTheme.bodyMedium!.fontFamily, 'IBMPlexSans');
  });

  testWidgets('no display text style is italic', (tester) async {
    final theme = PianoTheme.light();
    for (final style in [
      theme.textTheme.displayLarge,
      theme.textTheme.headlineLarge,
      theme.textTheme.headlineSmall,
      theme.textTheme.titleLarge,
    ]) {
      expect(style!.fontStyle ?? FontStyle.normal, FontStyle.normal);
    }
  });

  testWidgets('metric style uses tabular figures', (tester) async {
    expect(
      PianoTheme.light().textTheme.labelLarge!.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  test('theme extension lerps tokens rather than snapping', () {
    final light = PianoColorsExtension(PianoColors.light());
    final dark = PianoColorsExtension(PianoColors.dark());
    final mid = light.lerp(dark, 0.5);
    expect(mid.colors.paper, isNot(PianoColors.light().paper));
    expect(mid.colors.paper, isNot(PianoColors.dark().paper));
  });
}
