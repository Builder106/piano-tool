import 'package:flutter/material.dart';

import 'buttons.dart';
import 'palette.dart';
import 'scale.dart';

export 'scale.dart';

/// A fade between screens, the only transition the book uses.
Route<T> fadeRoute<T>(WidgetBuilder builder) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondary) => builder(context),
    transitionsBuilder: (context, animation, secondary, child) =>
        FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
  );
}

/// A screen that is one white page on the blue field, with Back and the title
/// on the field above it.
class BookPage extends StatelessWidget {
  const BookPage({
    super.key,
    required this.title,
    required this.child,
    this.onBack,
  });

  final String title;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final u = unitOf(context);
    return Material(
      color: Palette.field,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 64 * u,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24 * u),
                child: Row(
                  children: [
                    FieldAction(
                      label: 'Back',
                      onPressed:
                          onBack ?? () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: Fonts.ui,
                          fontSize: 26 * u,
                          color: Colors.white,
                          fontVariations: const [FontVariation('wght', 800)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 68),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Palette.page,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A heading on a page, set large and heavy.
class PageHeading extends StatelessWidget {
  const PageHeading(this.text, {super.key, this.size = 30});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final u = unitOf(context);
    return Text(
      text,
      style: TextStyle(
        fontFamily: Fonts.ui,
        fontSize: size * u,
        height: 1.1,
        letterSpacing: -0.5 * u,
        color: Palette.ink,
        fontVariations: const [FontVariation('wght', 800)],
      ),
    );
  }
}

/// Body text on a page, in graphite.
class PageText extends StatelessWidget {
  const PageText(this.text, {super.key, this.color = Palette.graphite});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final u = unitOf(context);
    return Text(
      text,
      style: TextStyle(
        fontFamily: Fonts.ui,
        fontSize: 20 * u,
        height: 1.35,
        color: color,
      ),
    );
  }
}
