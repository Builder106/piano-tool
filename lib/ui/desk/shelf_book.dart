import 'package:flutter/material.dart';

import '../../models/level_models.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'desk.dart';
import 'pencil_mark.dart';

/// A small cover with one pencilled line beneath it: cleared, its best,
/// open, or locked.
class ShelfBook extends StatelessWidget {
  const ShelfBook({
    super.key,
    required this.cloth,
    required this.stage,
    required this.number,
    required this.unlocked,
    required this.progress,
    this.current = false,
    this.imported = false,
    this.width = 92,
    this.onOpen,
    this.onLongPress,
    this.trailing,
  });

  final CoverCloth cloth;
  final StageModel stage;
  final int? number;
  final bool unlocked;
  final StageProgress? progress;
  final bool current;
  final bool imported;
  final double width;
  final VoidCallback? onOpen;

  /// Imported pieces: long press offers to delete.
  final VoidCallback? onLongPress;

  /// Shown at the end of the status line, such as a delete button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final text = PianoTheme.textThemeOf(context);
    final cleared = progress?.completed ?? false;
    final attempts = progress?.attempts ?? 0;
    final (Pencil? mark, String note) = !unlocked
        ? (Pencil.padlock, 'Locked')
        : cleared
        ? (Pencil.tick, 'Cleared')
        : attempts > 0
        ? (null, 'Best ${((progress?.bestAccuracy ?? 0) * 100).round()}%')
        : (
            null,
            imported
                ? 'Imported'
                : current
                ? 'Open now'
                : 'Not started',
          );

    // The cover is the book you pick up; the pencilled line under it, and any
    // action beside that line, stay outside it so each is reachable on its own.
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: unlocked,
            enabled: unlocked,
            label: '${stage.title}, $note',
            excludeSemantics: true,
            child: LiftingBook(
              onTap: onOpen,
              onLongPress: onLongPress,
              child: StageCover(
                cloth: cloth,
                number: number,
                title: stage.title,
                dimmed: !unlocked,
                sticker: cleared,
              ),
            ),
          ),
          const SizedBox(height: PianoSpacing.xs2),
          Row(
            children: [
              if (mark != null) ...[
                PencilMark(mark, color: colors.deskInk, height: 13),
                const SizedBox(width: PianoSpacing.xs2),
              ],
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: current ? colors.deskInk : colors.deskMuted,
                      fontWeight: current ? FontWeight.w600 : null,
                    ),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ],
      ),
    );
  }
}

/// A book you can pick up: it rises and tips a little under the pointer or a
/// finger, and settles back with a small bounce. A locked book does not move.
class LiftingBook extends StatefulWidget {
  const LiftingBook({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<LiftingBook> createState() => _LiftingBookState();
}

class _LiftingBookState extends State<LiftingBook> {
  bool _lifted = false;

  void _lift(bool lifted) {
    if (widget.onTap == null || lifted == _lifted) return;
    setState(() => _lifted = lifted);
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    const duration = Duration(milliseconds: 220);
    final up = _lifted && !still;
    return InkWell(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onHover: _lift,
      onHighlightChanged: _lift,
      borderRadius: BorderRadius.circular(4),
      child: AnimatedSlide(
        offset: up ? const Offset(0, -0.035) : Offset.zero,
        duration: duration,
        curve: Curves.easeOutBack,
        child: AnimatedRotation(
          turns: up ? -0.008 : 0,
          duration: duration,
          curve: Curves.easeOutBack,
          child: widget.child,
        ),
      ),
    );
  }
}
