import 'package:flutter/material.dart';

import '../../data/progress_repository.dart';
import '../desk/desk.dart';
import '../desk/pencil_mark.dart';
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
    final cleared = result.accuracy >= ProgressRepository.completionThreshold;

    // The marked sheet: the teacher circles the accuracy, and a run that
    // clears the stage gets a star in the margin.
    return Scaffold(
      backgroundColor: colors.desk,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              PianoSpacing.lg,
              PianoSpacing.xl,
              PianoSpacing.lg,
              PianoSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: PaperSheet(
                tilt: 0.8,
                clipped: true,
                padding: const EdgeInsets.fromLTRB(
                  PianoSpacing.xl,
                  PianoSpacing.lg,
                  PianoSpacing.xl,
                  PianoSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Stage complete',
                      style: text.bodySmall?.copyWith(color: colors.muted),
                    ),
                    Text(result.title, style: text.displayLarge),
                    const SizedBox(height: PianoSpacing.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 190,
                          height: 120,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PencilMark(
                                Pencil.loop,
                                color: colors.accent,
                                width: 186,
                                drawOn: true,
                                delay: const Duration(milliseconds: 300),
                                duration: const Duration(milliseconds: 800),
                              ),
                              Text(
                                '$accuracyPercent%',
                                style: text.displayLarge?.copyWith(
                                  fontSize: 64,
                                  color: colors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: PianoSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${result.hitNotes} of ${result.totalNotes} notes matched',
                                style: text.bodyLarge,
                              ),
                              const SizedBox(height: PianoSpacing.xs),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    'Score ',
                                    style: text.labelSmall?.copyWith(
                                      color: colors.muted,
                                    ),
                                  ),
                                  Text(
                                    '${result.score}',
                                    style: text.labelLarge?.copyWith(
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: PianoSpacing.sm),
                              Text(
                                cleared
                                    ? 'Cleared. The next stage is open.'
                                    : 'Nine in ten clears the stage. Try it again, slower if it helps.',
                                style: text.titleLarge?.copyWith(
                                  color: colors.muted,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w400,
                                  fontVariations: const [
                                    FontVariation('wght', 400),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (cleared)
                          PencilMark(
                            Pencil.star,
                            color: colors.accent,
                            width: 64,
                            drawOn: true,
                            delay: const Duration(milliseconds: 1100),
                          ),
                      ],
                    ),
                    const SizedBox(height: PianoSpacing.xl),
                    Wrap(
                      spacing: PianoSpacing.sm,
                      runSpacing: PianoSpacing.sm,
                      children: [
                        FilledButton.icon(
                          onPressed: onReplay,
                          icon: const Icon(Icons.replay),
                          label: const Text('Replay stage'),
                        ),
                        TextButton(
                          onPressed: onReturnToLevels,
                          child: const Text('All levels'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
