import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// The final metrics for one completed stage.
class StageResult {
  const StageResult({
    required this.stageId,
    required this.title,
    required this.score,
    required this.accuracy,
    required this.totalNotes,
    required this.hitNotes,
  });

  final String stageId;
  final String title;
  final int score;
  final double accuracy;
  final int totalNotes;
  final int hitNotes;
}

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
    super.key,
    required this.result,
    required this.onReplay,
    required this.onReturnToLevels,
  });

  final StageResult result;
  final VoidCallback onReplay;
  final VoidCallback onReturnToLevels;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final text = Theme.of(context).textTheme;
    final accuracyPercent = (result.accuracy * 100).round();

    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(PianoSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Stage complete', style: text.headlineMedium),
                  const SizedBox(height: PianoSpacing.xs),
                  Text(result.title, style: text.titleLarge),
                  const SizedBox(height: PianoSpacing.xl),
                  _ResultMetric(
                    label: 'Score',
                    value: '${result.score}',
                  ),
                  const SizedBox(height: PianoSpacing.md),
                  _ResultMetric(
                    label: 'Accuracy',
                    value: '$accuracyPercent%',
                  ),
                  const SizedBox(height: PianoSpacing.sm),
                  Text(
                    '${result.hitNotes} of ${result.totalNotes} notes matched',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: PianoSpacing.xl),
                  FilledButton.icon(
                    onPressed: onReplay,
                    icon: const Icon(Icons.replay),
                    label: const Text('Replay stage'),
                  ),
                  const SizedBox(height: PianoSpacing.sm),
                  OutlinedButton(
                    onPressed: onReturnToLevels,
                    child: const Text('All levels'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(PianoSpacing.md),
      decoration: BoxDecoration(
        color: colors.paper2,
        border: Border.all(color: colors.rule),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: text.titleMedium),
          Text(value, style: text.headlineSmall),
        ],
      ),
    );
  }
}
