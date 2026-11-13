import 'package:flutter/material.dart';

import 'scale.dart';
import 'palette.dart';

/// The main action on a page: a red pencil block, white type.
class StartButton extends StatelessWidget {
  const StartButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return _Block(
      label: label,
      onPressed: onPressed,
      fill: Palette.pencilRed,
      text: Colors.white,
    );
  }
}

/// A second action: ink outline, ink type.
class QuietButton extends StatelessWidget {
  const QuietButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return _Block(
      label: label,
      onPressed: onPressed,
      border: Palette.ink,
      text: Palette.ink,
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.label,
    required this.onPressed,
    required this.text,
    this.fill,
    this.border,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color text;
  final Color? fill;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final u = unitOf(context);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onPressed,
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: BoxConstraints(minHeight: 48, minWidth: 48 * u),
            padding: EdgeInsets.symmetric(horizontal: 28 * u, vertical: 14 * u),
            decoration: BoxDecoration(
              color: onPressed == null ? Palette.rule : fill,
              border: border == null
                  ? null
                  : Border.all(color: border!, width: 2.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: Fonts.ui,
                  fontSize: 21 * u,
                  height: 1.1,
                  color: text,
                  fontVariations: const [FontVariation('wght', 800)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A plain word on the field: Back, Pause, Speed.
class FieldAction extends StatelessWidget {
  const FieldAction({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final u = unitOf(context);
    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onPressed,
          behavior: HitTestBehavior.opaque,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: Center(
              widthFactor: 1,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10 * u),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: Fonts.ui,
                    fontSize: 20 * u,
                    color: Colors.white,
                    fontVariations: const [FontVariation('wght', 700)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
