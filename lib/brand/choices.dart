import 'package:flutter/material.dart';

import 'book_page.dart';
import 'palette.dart';
import 'pencil_loop.dart';

/// A few words to choose between on a page; the chosen one is circled in blue
/// pencil.
class Choices<T> extends StatelessWidget {
  const Choices({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final u = unitOf(context);
    return Wrap(
      spacing: 22 * u,
      runSpacing: 10 * u,
      children: [
        for (final (v, label) in options)
          Semantics(
            button: true,
            inMutuallyExclusiveGroup: true,
            selected: v == value,
            label: label,
            child: ExcludeSemantics(
              child: GestureDetector(
                onTap: () => onChanged(v),
                behavior: HitTestBehavior.opaque,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16 * u,
                      vertical: 6 * u,
                    ),
                    child: CustomPaint(
                      foregroundPainter: v == value
                          ? const LoopAround(grow: Size(30, 12))
                          : null,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: Fonts.ui,
                          fontSize: 28 * u,
                          height: 1.2,
                          color: v == value ? Palette.ink : Palette.graphite,
                          fontVariations: [
                            FontVariation('wght', v == value ? 800 : 600),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
