import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'pencil_mark.dart';

/// A row of words on the paper where one is chosen: the chosen word is
/// circled in blue pencil, and the loop draws itself in when you pick it,
/// as a teacher rings the answer.
class PencilChoices<T> extends StatelessWidget {
  const PencilChoices({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: PianoSpacing.xs2,
    runSpacing: PianoSpacing.xs2,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (final value in values)
        _PencilChoice(
          label: label(value),
          selected: value == selected,
          onTap: () => onSelected(value),
        ),
    ],
  );
}

class _PencilChoice extends StatefulWidget {
  const _PencilChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PencilChoice> createState() => _PencilChoiceState();
}

class _PencilChoiceState extends State<_PencilChoice> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final text = PianoTheme.textThemeOf(context);
    final still = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedRotation(
          // The word tips under your finger, like a card being picked up.
          turns: _pressed && !still ? -0.012 : 0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutBack,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: kMinInteractiveDimension,
              minHeight: kMinInteractiveDimension,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  // Room inside the loop, so the pencil never crosses a letter.
                  padding: const EdgeInsets.symmetric(
                    horizontal: PianoSpacing.md + PianoSpacing.xs2,
                    vertical: PianoSpacing.xs,
                  ),
                  child: Text(
                    widget.label,
                    style: text.headlineSmall?.copyWith(
                      color: widget.selected ? colors.accent : colors.ink2,
                      fontWeight: widget.selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontVariations: [
                        FontVariation('wght', widget.selected ? 700 : 500),
                      ],
                      // Cormorant's old-style 1 would make "1x" read as IX.
                      fontFeatures: const [FontFeature.liningFigures()],
                    ),
                  ),
                ),
                if (widget.selected)
                  Positioned.fill(
                    child: PencilMark(
                      Pencil.loop,
                      color: colors.accent,
                      stretch: true,
                      drawOn: true,
                      duration: const Duration(milliseconds: 420),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
