import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/ingestion_repository.dart';
import '../../data/level_repository.dart';
import '../../data/progress_repository.dart';
import '../../models/level_models.dart';
import '../desk/desk.dart';
import '../desk/shelf_book.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// The library: every stage's method book on the desk, built-in stages first,
/// then imported pieces in slate.
class LevelListScreen extends ConsumerStatefulWidget {
  const LevelListScreen({super.key});

  @override
  ConsumerState<LevelListScreen> createState() => _LevelListScreenState();
}

class _LevelListScreenState extends ConsumerState<LevelListScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final repositoryAsync = ref.watch(levelRepositoryProvider);

    return repositoryAsync.when(
      data: (repository) => _buildDesk(context, repository),
      loading: () => Scaffold(
        backgroundColor: colors.desk,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: colors.desk,
        body: Center(
          child: Text(
            'The library could not be loaded: $error',
            style: TextStyle(color: colors.deskInk),
          ),
        ),
      ),
    );
  }

  Widget _buildDesk(BuildContext context, LevelRepository repository) {
    final colors = PianoTheme.colorsOf(context);
    final stages = repository.getAllStages();
    final progressAsync = ref.watch(stageProgressProvider);
    if (progressAsync.isLoading) {
      return Scaffold(
        backgroundColor: colors.desk,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (progressAsync.hasError) {
      return Scaffold(
        backgroundColor: colors.desk,
        body: Center(
          child: Text(
            'Your progress could not be loaded: ${progressAsync.error}',
            style: TextStyle(color: colors.deskInk),
          ),
        ),
      );
    }
    final progress = progressAsync.value ?? <String, StageProgress>{};
    final cleared = stages.where((s) => progress[s.id]?.completed == true);

    return DeskScaffold(
      title: 'Library',
      subtitle: '${stages.length} books, ${cleared.length} cleared',
      backTooltip: 'Back to home',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
      actions: [
        if (ref.watch(importAvailableProvider))
          DeskAction(
            label: 'Import a piece',
            icon: Icons.add_rounded,
            onPressed: () => context.push('/import'),
          ),
        DeskAction(
          label: 'Settings',
          icon: Icons.tune_rounded,
          onPressed: () => context.push('/settings'),
        ),
      ],
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(
          PianoSpacing.xl,
          PianoSpacing.md,
          PianoSpacing.xl,
          PianoSpacing.xl,
        ),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 190,
          mainAxisSpacing: PianoSpacing.lg,
          crossAxisSpacing: PianoSpacing.lg,
          // The cover plus its pencilled line.
          childAspectRatio: 0.66,
        ),
        itemCount: stages.length,
        itemBuilder: (context, index) {
          final stage = stages[index];
          final imported = repository.isImportedLevel(stage.level.id);
          final unlocked = stage.prerequisites.every(
            (id) => progress[id]?.completed == true,
          );
          final delete = imported
              ? () => _confirmDelete(context, repository, stage.level.id)
              : null;
          return LayoutBuilder(
            builder: (context, box) => Align(
              alignment: Alignment.topLeft,
              child: ShelfBook(
                width: box.maxWidth,
                cloth: CoverCloth.forStage(index: index, imported: imported),
                stage: stage,
                number: imported ? null : index + 1,
                unlocked: unlocked,
                progress: progress[stage.id],
                imported: imported,
                onOpen: unlocked
                    ? () => context.push('/practice/${stage.id}')
                    : null,
                onLongPress: delete,
                trailing: delete == null
                    ? null
                    : IconButton(
                        onPressed: delete,
                        tooltip: 'Delete',
                        visualDensity: VisualDensity.compact,
                        color: colors.deskMuted,
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    LevelRepository repository,
    String levelId,
  ) async {
    final colors = PianoTheme.colorsOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete imported piece?'),
        content: const Text(
          'It comes off your shelf, with its progress. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: colors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final ingestionRepo = await ref.read(ingestionRepositoryProvider.future);
      await ingestionRepo.deleteImportedLevel(levelId);
    } on IngestionException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete: ${e.message}')));
      return;
    }

    repository.removeImportedLevel(levelId);
    ref.invalidate(levelRepositoryProvider);
    setState(() {});
  }
}
