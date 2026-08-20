import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class PracticeHud extends StatelessWidget {
  const PracticeHud({
    super.key,
    required this.title,
    required this.tempo,
    required this.score,
    required this.accuracy,
    required this.progress,
    this.onBack,
  });

  /// The header's resting height. A floor, not a fixed size: at a large text
  /// scale the row is allowed to grow rather than clip its own content.
  static const double minHeight = 44;

  final String title;
  final int tempo;
  final int score;
  final double accuracy;
  final double progress;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final text = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: PianoSpacing.sm,
            vertical: PianoSpacing.xs2,
          ),
          decoration: BoxDecoration(
            color: colors.paper2,
            border: Border(bottom: BorderSide(color: colors.rule)),
          ),
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  iconSize: 18,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Back',
                ),
              // Both sides are flex children, so neither can push the other off
              // the axis. The title ellipsizes and the metrics scale down; the
              // row cannot overflow at any text scale.
              Expanded(
                flex: 2,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleLarge,
                ),
              ),
              const SizedBox(width: PianoSpacing.sm),
              Expanded(
                flex: 3,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Metric(label: 'BPM', value: '$tempo'),
                      const SizedBox(width: PianoSpacing.md),
                      _Metric(label: 'Score', value: '$score'),
                      const SizedBox(width: PianoSpacing.md),
                      _Metric(
                          label: 'Acc',
                          value: '${(accuracy * 100).toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 2,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: colors.rule2,
            valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ', style: text.labelSmall),
        Text(value, style: text.labelLarge),
      ],
    );
  }
}
