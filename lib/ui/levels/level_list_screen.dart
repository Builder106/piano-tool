import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/ingestion_repository.dart';
import '../../data/level_repository.dart';
import '../../data/progress_repository.dart';
import '../../models/level_models.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';

/// Main level selection screen showing built-in stages and imported levels.
class LevelListScreen extends ConsumerStatefulWidget {
  const LevelListScreen({super.key});

  @override
  ConsumerState<LevelListScreen> createState() => _LevelListScreenState();
}

class _LevelListScreenState extends ConsumerState<LevelListScreen> {
  @override
  Widget build(BuildContext context) {
    final repositoryAsync = ref.watch(levelRepositoryProvider);

    return repositoryAsync.when(
      data: (repository) => _buildScaffold(context, repository),
      loading: () => const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      ),
      error: (error, stack) => Scaffold(
        body: SafeArea(
          child: Center(child: Text('Error loading levels: $error')),
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, LevelRepository repository) {
    final stages = repository.getAllStages();

    return Scaffold(
      backgroundColor: PianoTheme.colorsOf(context).paper,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(PianoSpacing.lg),
              child: Row(
                children: [
                  Text(
                    'Piano Tool',
                    style: PianoTheme.textThemeOf(context).headlineMedium?.copyWith(
                      color: PianoTheme.colorsOf(context).ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.add_rounded,
                      color: PianoTheme.colorsOf(context).ink,
                      size: 28,
                    ),
                    onPressed: () => context.push('/import'),
                    tooltip: 'Import new piece',
                  ),
                ],
              ),
            ),

            // Stage list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: PianoSpacing.lg),
                itemCount: stages.length,
                separatorBuilder: (_, __) => const SizedBox(height: PianoSpacing.md),
                itemBuilder: (context, index) {
                  final stage = stages[index];
                  final isImported = repository.isImportedLevel(stage.level.id);
                  return _StageCard(
                    stage: stage,
                    isImported: isImported,
                    onTap: () => context.push('/practice/${stage.id}'),
                    onDelete: isImported
                        ? () => _confirmDelete(context, repository, stage.level.id)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    LevelRepository repository,
    String levelId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PianoTheme.colorsOf(context).paper3,
        title: Text('Delete imported piece?', style: PianoTheme.textThemeOf(context).titleLarge),
        content: Text(
          'This will remove the piece from your library. This action cannot be undone.',
          style: PianoTheme.textThemeOf(context).bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: PianoTheme.textThemeOf(context).labelLarge?.copyWith(
              color: PianoTheme.colorsOf(context).muted,
            )),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: PianoTheme.colorsOf(context).error,
            ),
            child: Text('Delete', style: PianoTheme.textThemeOf(context).labelLarge),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      // Both stores must agree: deleting only from the in-memory
      // LevelRepository left the level in IngestionRepository's persisted
      // storage, so it reappeared next time levelRepositoryProvider
      // rehydrated from disk.
      final ingestionRepo = await ref.read(ingestionRepositoryProvider.future);
      await ingestionRepo.deleteImportedLevel(levelId);
    } on IngestionException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: ${e.message}')),
      );
      return;
    }

    // Mutate the resolved repository directly so the list updates
    // immediately, then invalidate the provider so a future rebuild
    // rehydrates from the (now-updated) persisted store rather than reusing
    // stale state.
    repository.removeImportedLevel(levelId);
    ref.invalidate(levelRepositoryProvider);
    setState(() {});
  }
}

class _StageCard extends ConsumerWidget {
  const _StageCard({
    required this.stage,
    required this.isImported,
    required this.onTap,
    this.onDelete,
  });

  final StageModel stage;
  final bool isImported;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = PianoTheme.colorsOf(context);
    final textTheme = PianoTheme.textThemeOf(context);
    final progressRepo = ref.watch(progressRepositoryProvider);

    return FutureBuilder<StageProgress?>(
      future: progressRepo.read(stage.id),
      builder: (context, snapshot) {
        final progress = snapshot.data;
        final isCompleted = progress?.completed ?? false;
        final bestAccuracy = progress?.bestAccuracy ?? 0.0;

        return Material(
          color: colors.paper3,
          borderRadius: BorderRadius.circular(PianoRadius.lg),
          child: InkWell(
            onTap: onTap,
            onLongPress: onDelete,
            borderRadius: BorderRadius.circular(PianoRadius.lg),
            child: Padding(
              padding: const EdgeInsets.all(PianoSpacing.md),
              child: Row(
                children: [
                  // Difficulty/import indicator
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _difficultyColor(stage.difficulty, colors).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(PianoRadius.md),
                    ),
                    child: Icon(
                      isImported ? Icons.upload_file_rounded : _difficultyIcon(stage.difficulty),
                      color: _difficultyColor(stage.difficulty, colors),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: PianoSpacing.md),

                  // Stage info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                stage.title,
                                style: textTheme.titleMedium?.copyWith(
                                  color: colors.ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isImported)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: PianoSpacing.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(PianoRadius.sm),
                                ),
                                child: Text(
                                  'Imported',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stage.description,
                          style: textTheme.bodySmall?.copyWith(color: colors.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Progress indicator
                        if (progress != null) ...[
                          Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: bestAccuracy,
                                  minHeight: 4,
                                  borderRadius: BorderRadius.circular(2),
                                  backgroundColor: colors.rule,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isCompleted ? colors.success : colors.accent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: PianoSpacing.sm),
                              Text(
                                '${(bestAccuracy * 100).round()}%',
                                style: textTheme.labelSmall?.copyWith(
                                  color: isCompleted ? colors.success : colors.muted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            'Not started',
                            style: textTheme.labelSmall?.copyWith(color: colors.muted),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Chevron or delete
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: colors.error),
                      onPressed: onDelete,
                      tooltip: 'Delete',
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.muted,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _difficultyColor(Difficulty difficulty, PianoColors colors) {
    return switch (difficulty) {
      Difficulty.beginner => colors.success,
      Difficulty.intermediate => colors.accent,
      Difficulty.advanced => colors.warning,
      Difficulty.expert => colors.error,
    };
  }

  IconData _difficultyIcon(Difficulty difficulty) {
    return switch (difficulty) {
      Difficulty.beginner => Icons.looks_one_rounded,
      Difficulty.intermediate => Icons.looks_two_rounded,
      Difficulty.advanced => Icons.looks_3_rounded,
      Difficulty.expert => Icons.looks_4_rounded,
    };
  }
}