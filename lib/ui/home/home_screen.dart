import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/level_repository.dart';
import '../../data/progress_repository.dart';
import '../../models/level_models.dart';
import '../levels/level_list_screen.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Landing home screen and continue hub for practice.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = PianoTheme.colorsOf(context);
    final repositoryAsync = ref.watch(levelRepositoryProvider);

    return repositoryAsync.when(
      data: (repository) => _buildScaffold(context, ref, repository),
      loading: () => Scaffold(
        backgroundColor: colors.paper,
        body: const SafeArea(child: Center(child: CircularProgressIndicator())),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: colors.paper,
        body: SafeArea(
          child: Center(
            child: Text(
              'Error loading stages: $error',
              style: TextStyle(color: colors.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    WidgetRef ref,
    LevelRepository repository,
  ) {
    final colors = PianoTheme.colorsOf(context);
    final textTheme = PianoTheme.textThemeOf(context);
    final stages = repository.getAllStages();

    final progressAsync = ref.watch(stageProgressProvider);
    final lastPlayedAsync = ref.watch(lastPlayedStageIdProvider);

    if (progressAsync.isLoading || lastPlayedAsync.isLoading) {
      return Scaffold(
        backgroundColor: colors.paper,
        body: const SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    final progress = progressAsync.value ?? <String, StageProgress>{};
    final lastPlayedId = lastPlayedAsync.value;

    StageModel? continueStage;
    if (lastPlayedId != null) {
      final candidate = repository.getStage(lastPlayedId);
      if (candidate != null) {
        final isUnlocked = candidate.prerequisites.every(
          (id) => progress[id]?.completed == true,
        );
        if (isUnlocked) {
          continueStage = candidate;
        }
      }
    }

    // Fall back to the first unlocked stage, or the first stage in the repository
    continueStage ??= stages.cast<StageModel?>().firstWhere(
      (s) =>
          s != null &&
          s.prerequisites.every((id) => progress[id]?.completed == true),
      orElse: () => stages.isNotEmpty ? stages.first : null,
    );

    final totalStages = stages.length;
    final completedCount = stages
        .where((s) => progress[s.id]?.completed == true)
        .length;

    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PianoSpacing.lg,
            vertical: PianoSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Piano Tool',
                        style: textTheme.headlineMedium?.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Interactive practice tutor and transcription studio',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.muted,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.library_music_outlined,
                      color: colors.ink,
                      size: 26,
                    ),
                    onPressed: () => context.push('/levels'),
                    tooltip: 'All levels',
                  ),
                  const SizedBox(width: PianoSpacing.xs),
                  IconButton(
                    icon: Icon(Icons.add_rounded, color: colors.ink, size: 28),
                    onPressed: () => context.push('/import'),
                    tooltip: 'Import piece',
                  ),
                  const SizedBox(width: PianoSpacing.xs),
                  IconButton(
                    icon: Icon(
                      Icons.settings_outlined,
                      color: colors.ink,
                      size: 26,
                    ),
                    onPressed: () => context.push('/settings'),
                    tooltip: 'Settings & Calibration',
                  ),
                ],
              ),
              const SizedBox(height: PianoSpacing.md),

              // Main Content Area (Landscape Two-Column Layout)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Primary Continue Hero Card
                    Expanded(
                      flex: 5,
                      child: continueStage != null
                          ? _ContinueCard(
                              stage: continueStage,
                              progress: progress[continueStage.id],
                              isImported: repository.isImportedLevel(
                                continueStage.level.id,
                              ),
                              onContinue: () => context.push(
                                '/practice/${continueStage!.id}',
                              ),
                            )
                          : _EmptyStagesCard(
                              onImport: () => context.push('/import'),
                            ),
                    ),
                    const SizedBox(width: PianoSpacing.md),

                    // Secondary Hub Cards Column
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _LibrarySummaryCard(
                              totalStages: totalStages,
                              completedCount: completedCount,
                              onBrowse: () => context.push('/levels'),
                            ),
                          ),
                          const SizedBox(height: PianoSpacing.md),
                          Expanded(
                            child: _QuickImportCard(
                              onImport: () => context.push('/import'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hero card highlighting the active or next recommended practice stage.
class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.stage,
    required this.progress,
    required this.isImported,
    required this.onContinue,
  });

  final StageModel stage;
  final StageProgress? progress;
  final bool isImported;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final textTheme = PianoTheme.textThemeOf(context);

    final attempts = progress?.attempts ?? 0;
    final isCompleted = progress?.completed ?? false;
    final bestAccuracy = progress?.bestAccuracy ?? 0.0;
    final bestScore = progress?.bestScore ?? 0;

    final String statusLabel = isCompleted
        ? 'Cleared'
        : attempts > 0
        ? 'In Progress'
        : 'Up Next';

    final Color statusColor = isCompleted
        ? colors.success
        : attempts > 0
        ? colors.accent
        : colors.muted;

    return Material(
      color: colors.paper3,
      borderRadius: BorderRadius.circular(PianoRadius.lg),
      child: InkWell(
        onTap: onContinue,
        borderRadius: BorderRadius.circular(PianoRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(PianoSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Card section name and status badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Continue Practice',
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: PianoSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: PianoSpacing.sm,
                      vertical: PianoSpacing.xs2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(PianoRadius.sm),
                    ),
                    child: Text(
                      statusLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Title and Description
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: stageDifficultyColor(
                        stage.difficulty,
                        colors,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(PianoRadius.md),
                    ),
                    child: Icon(
                      isImported
                          ? Icons.upload_file_rounded
                          : stageDifficultyIcon(stage.difficulty),
                      color: stageDifficultyColor(stage.difficulty, colors),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: PianoSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage.title,
                          style: textTheme.titleLarge?.copyWith(
                            color: colors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: PianoSpacing.xs2),
                        Text(
                          stage.description,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.muted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Metrics & Action Row
              Row(
                children: [
                  Expanded(
                    child: attempts > 0
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${(bestAccuracy * 100).round()}% accuracy',
                                style: textTheme.labelMedium?.copyWith(
                                  color: colors.ink,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '$bestScore pts | $attempts ${attempts == 1 ? "run" : "runs"}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.muted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          )
                        : Text(
                            '${stage.level.tempo} BPM | 4/4 meter',
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                  const SizedBox(width: PianoSpacing.sm),
                  FilledButton.icon(
                    onPressed: onContinue,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.accentInk,
                      padding: const EdgeInsets.symmetric(
                        horizontal: PianoSpacing.lg,
                        vertical: PianoSpacing.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(PianoRadius.md),
                      ),
                    ),
                    icon: Icon(
                      attempts > 0
                          ? Icons.play_arrow_rounded
                          : Icons.arrow_forward_rounded,
                      size: 20,
                    ),
                    label: Text(
                      attempts > 0 ? 'Resume' : 'Start',
                      style: textTheme.labelLarge?.copyWith(
                        color: colors.accentInk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Secondary card showing overall library completion and a link to all levels.
class _LibrarySummaryCard extends StatelessWidget {
  const _LibrarySummaryCard({
    required this.totalStages,
    required this.completedCount,
    required this.onBrowse,
  });

  final int totalStages;
  final int completedCount;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final textTheme = PianoTheme.textThemeOf(context);
    final double ratio = totalStages > 0 ? (completedCount / totalStages) : 0.0;

    return Material(
      color: colors.paper3,
      borderRadius: BorderRadius.circular(PianoRadius.lg),
      child: InkWell(
        onTap: onBrowse,
        borderRadius: BorderRadius.circular(PianoRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(PianoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.library_music_rounded,
                    color: colors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: PianoSpacing.xs),
                  Text(
                    'Level Library',
                    style: textTheme.titleSmall?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$completedCount of $totalStages cleared',
                    style: textTheme.labelSmall?.copyWith(color: colors.muted),
                  ),
                ],
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(PianoRadius.sm),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: colors.rule2,
                  valueColor: AlwaysStoppedAnimation(colors.accent),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Browse all levels',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: PianoSpacing.xs2),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: colors.accent,
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Secondary card offering a quick path to audio import and transcription.
class _QuickImportCard extends StatelessWidget {
  const _QuickImportCard({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final textTheme = PianoTheme.textThemeOf(context);

    return Material(
      color: colors.paper3,
      borderRadius: BorderRadius.circular(PianoRadius.lg),
      child: InkWell(
        onTap: onImport,
        borderRadius: BorderRadius.circular(PianoRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(PianoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.upload_file_rounded,
                    color: colors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: PianoSpacing.xs),
                  Text(
                    'Import Piece',
                    style: textTheme.titleSmall?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'Transcribe audio recordings into playable practice levels.',
                style: textTheme.bodySmall?.copyWith(color: colors.muted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Import audio',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: PianoSpacing.xs2),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: colors.accent,
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fallback card when no stages are found.
class _EmptyStagesCard extends StatelessWidget {
  const _EmptyStagesCard({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final textTheme = PianoTheme.textThemeOf(context);

    return Material(
      color: colors.paper3,
      borderRadius: BorderRadius.circular(PianoRadius.lg),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(PianoSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.music_off_rounded, color: colors.muted, size: 40),
              const SizedBox(height: PianoSpacing.sm),
              Text(
                'No stages available',
                style: textTheme.titleMedium?.copyWith(color: colors.ink),
              ),
              const SizedBox(height: PianoSpacing.xs),
              Text(
                'Import an audio piece to begin practice.',
                style: textTheme.bodySmall?.copyWith(color: colors.muted),
              ),
              const SizedBox(height: PianoSpacing.md),
              FilledButton.icon(
                onPressed: onImport,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.accentInk,
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Import piece'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
