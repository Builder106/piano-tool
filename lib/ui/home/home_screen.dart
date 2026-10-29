import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/ingestion_repository.dart';
import '../../data/level_repository.dart';
import '../../data/progress_repository.dart';
import '../../models/engine_models.dart';
import '../../models/level_models.dart';
import '../desk/desk.dart';
import '../desk/pencil_mark.dart';
import '../desk/shelf_book.dart';
import '../staff/staff_geometry.dart';
import '../staff/staff_view.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Home: the music desk. The stage you are on stands open, its cloth cover
/// beside the practice sheet, and the rest of your books wait on the shelf.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = PianoTheme.colorsOf(context);
    final repositoryAsync = ref.watch(levelRepositoryProvider);

    return repositoryAsync.when(
      data: (repository) => _HomeDesk(repository: repository),
      loading: () => Scaffold(
        backgroundColor: colors.desk,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: colors.desk,
        body: Center(
          child: Text(
            'The stages could not be loaded: $error',
            style: TextStyle(color: colors.deskInk),
          ),
        ),
      ),
    );
  }
}

/// What the shelf needs to know about each stage.
typedef _Book = ({
  StageModel stage,
  int index,
  bool imported,
  bool unlocked,
  StageProgress? progress,
});

class _HomeDesk extends ConsumerWidget {
  const _HomeDesk({required this.repository});

  final LevelRepository repository;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = PianoTheme.colorsOf(context);
    final progressAsync = ref.watch(stageProgressProvider);
    final lastPlayedAsync = ref.watch(lastPlayedStageIdProvider);

    if (progressAsync.isLoading || lastPlayedAsync.isLoading) {
      return Scaffold(
        backgroundColor: colors.desk,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final progress = progressAsync.value ?? <String, StageProgress>{};
    final stages = repository.getAllStages();
    final books = <_Book>[
      for (final (index, stage) in stages.indexed)
        (
          stage: stage,
          index: index,
          imported: repository.isImportedLevel(stage.level.id),
          unlocked: stage.prerequisites.every(
            (id) => progress[id]?.completed == true,
          ),
          progress: progress[stage.id],
        ),
    ];

    // The last stage played, if it is still open; otherwise the first open one.
    final lastPlayedId = lastPlayedAsync.value;
    final _Book? current =
        books
            .where((b) => b.stage.id == lastPlayedId && b.unlocked)
            .firstOrNull ??
        books.where((b) => b.unlocked).firstOrNull ??
        books.firstOrNull;

    void open(_Book book) => context.push('/practice/${book.stage.id}');
    final canImport = ref.watch(importAvailableProvider);

    return DeskScaffold(
      brand: true,
      actions: [
        DeskAction(
          label: 'Library',
          icon: Icons.menu_book_outlined,
          onPressed: () => context.push('/levels'),
        ),
        if (canImport)
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
      body: current == null
          ? _EmptyDesk(
              onImport: canImport ? () => context.push('/import') : null,
            )
          : LayoutBuilder(
              builder: (context, box) {
                final wide = box.maxWidth >= 760;
                final shelf = _Shelf(
                  books: books,
                  currentId: current.stage.id,
                  onOpen: open,
                  onLibrary: () => context.push('/levels'),
                );
                final cover = Semantics(
                  button: true,
                  label: 'Open ${current.stage.title}',
                  excludeSemantics: true,
                  child: LiftingBook(
                    onTap: () => open(current),
                    child: StageCover(
                      cloth: CoverCloth.forStage(
                        index: current.index,
                        imported: current.imported,
                      ),
                      number: current.imported ? null : current.index + 1,
                      title: current.stage.title,
                      sticker: current.progress?.completed ?? false,
                    ),
                  ),
                );
                final sheet = _PracticeSheet(
                  book: current,
                  stageCount: books.length,
                  onStart: () => open(current),
                );

                if (!wide) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      PianoSpacing.md,
                      PianoSpacing.xs,
                      PianoSpacing.md,
                      PianoSpacing.xl,
                    ),
                    children: [
                      Center(child: SizedBox(width: 180, child: cover)),
                      const SizedBox(height: PianoSpacing.lg),
                      sheet,
                      const SizedBox(height: PianoSpacing.xl),
                      shelf,
                    ],
                  );
                }

                // One scrolling desk: the sheet sizes to its content, so
                // nothing on it is ever clipped by a box beside the cover.
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    PianoSpacing.xl,
                    PianoSpacing.xs,
                    PianoSpacing.xl,
                    PianoSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        // Room for the page clip above the sheet.
                        padding: const EdgeInsets.only(top: PianoSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // About the width of a method book lying on the
                            // desk beside its open page.
                            SizedBox(
                              width: (box.maxWidth * 0.2).clamp(180.0, 260.0),
                              child: cover,
                            ),
                            const SizedBox(width: PianoSpacing.xl),
                            Expanded(child: sheet),
                          ],
                        ),
                      ),
                      const _DeskPencil(),
                      shelf,
                    ],
                  ),
                );
              },
            ),
    );
  }
}

/// The practice sheet for the open stage: printed header, the opening bars,
/// the teacher's note, and the one action, circled in pencil.
class _PracticeSheet extends StatelessWidget {
  const _PracticeSheet({
    required this.book,
    required this.stageCount,
    required this.onStart,
  });

  final _Book book;
  final int stageCount;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final text = PianoTheme.textThemeOf(context);
    final stage = book.stage;
    final attempts = book.progress?.attempts ?? 0;
    final cleared = book.progress?.completed ?? false;
    final status = cleared
        ? 'Cleared'
        : attempts > 0
        ? 'In progress'
        : 'Up next';

    return PaperSheet(
      tilt: -0.6,
      clipped: true,
      padding: const EdgeInsets.fromLTRB(
        PianoSpacing.xl,
        PianoSpacing.lg,
        PianoSpacing.xl,
        PianoSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  book.imported
                      ? 'Your piece'
                      : 'Stage ${book.index + 1} of $stageCount',
                  style: text.bodySmall?.copyWith(color: colors.muted),
                ),
              ),
              if (cleared) ...[
                PencilMark(Pencil.tick, color: colors.success, height: 14),
                const SizedBox(width: PianoSpacing.xs2),
              ],
              Text(
                status,
                style: text.titleLarge?.copyWith(
                  color: colors.muted,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  fontVariations: const [FontVariation('wght', 500)],
                ),
              ),
            ],
          ),
          const SizedBox(height: PianoSpacing.xs),
          Text(
            stage.title,
            style: text.displayLarge?.copyWith(
              fontWeight: FontWeight.w500,
              fontVariations: const [FontVariation('wght', 500)],
            ),
          ),
          const SizedBox(height: PianoSpacing.md),
          SizedBox(
            height: stage.level.clef == LevelClef.grand ? 150 : 96,
            child: _OpeningBars(level: stage.level),
          ),
          const SizedBox(height: PianoSpacing.md),
          Text(
            stage.description,
            style: text.headlineSmall?.copyWith(
              color: colors.muted,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              fontVariations: const [FontVariation('wght', 400)],
            ),
          ),
          const SizedBox(height: PianoSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Wrap(
                  spacing: PianoSpacing.lg,
                  runSpacing: PianoSpacing.xs,
                  children: [
                    _Fact(label: 'Tempo', value: '${stage.level.tempo}'),
                    _Fact(
                      label: 'Time',
                      value:
                          '${stage.level.beatsPerMeasure}/${stage.level.beatUnit}',
                    ),
                    if (attempts > 0) ...[
                      _Fact(
                        label: 'Best',
                        value:
                            '${((book.progress?.bestAccuracy ?? 0) * 100).round()}%',
                      ),
                      _Fact(
                        label: attempts == 1 ? 'Run' : 'Runs',
                        value: '$attempts',
                      ),
                    ],
                  ],
                ),
              ),
              PencilButton(
                label: attempts > 0 ? 'Resume' : 'Start',
                semanticLabel:
                    '${attempts > 0 ? 'Resume' : 'Start'} ${stage.title}',
                onPressed: onStart,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The first bars of the stage, engraved on the sheet.
class _OpeningBars extends StatelessWidget {
  const _OpeningBars({required this.level});

  final LevelModel level;

  @override
  Widget build(BuildContext context) {
    final notes = [
      for (final measure in level.measures)
        for (final note in measure.notes)
          (
            midi: note.midiNote,
            startBeat: note.startBeat,
            state: NoteState.upcoming,
          ),
    ]..sort((a, b) => a.startBeat.compareTo(b.startBeat));
    final systems = switch (level.clef) {
      LevelClef.treble => [(clef: Clef.treble, notes: notes)],
      LevelClef.bass => [(clef: Clef.bass, notes: notes)],
      LevelClef.grand => [
        (
          clef: Clef.treble,
          notes: [
            for (final n in notes)
              if (n.midi >= 60) n,
          ],
        ),
        (
          clef: Clef.bass,
          notes: [
            for (final n in notes)
              if (n.midi < 60) n,
          ],
        ),
      ],
    };
    return ExcludeSemantics(
      child: StaffView(
        systems: systems,
        currentBeat: 0,
        totalBeats: (level.totalMeasures * level.beatsPerMeasure).toDouble(),
        beatsPerMeasure: level.beatsPerMeasure,
        beatUnit: level.beatUnit,
        pixelsPerBeat: 44,
        showPlayhead: false,
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final text = PianoTheme.textThemeOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: text.labelSmall?.copyWith(color: colors.muted)),
        Text(value, style: text.labelLarge?.copyWith(fontSize: 16)),
      ],
    );
  }
}

/// The sheet's one action: the word in the app's blue with a pencil loop
/// drawn round it, the way a teacher circles where to begin.
class PencilButton extends StatelessWidget {
  const PencilButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final text = PianoTheme.textThemeOf(context);
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(40),
        child: SizedBox(
          width: 160,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PencilMark(
                Pencil.loop,
                color: colors.accent,
                width: 150,
                drawOn: true,
                delay: const Duration(milliseconds: 250),
              ),
              Text(
                label,
                style: text.displayLarge?.copyWith(
                  color: colors.accent,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  fontVariations: const [FontVariation('wght', 600)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every stage as a book on the shelf, with its standing pencilled beneath.
class _Shelf extends StatelessWidget {
  const _Shelf({
    required this.books,
    required this.currentId,
    required this.onOpen,
    required this.onLibrary,
  });

  final List<_Book> books;
  final String currentId;
  final ValueChanged<_Book> onOpen;
  final VoidCallback onLibrary;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final text = PianoTheme.textThemeOf(context);
    final cleared = books.where((b) => b.progress?.completed == true).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'Your books',
              style: text.titleLarge?.copyWith(color: colors.deskInk),
            ),
            const SizedBox(width: PianoSpacing.sm),
            Text(
              '$cleared of ${books.length} cleared',
              style: text.bodySmall?.copyWith(color: colors.deskMuted),
            ),
            const Spacer(),
            TextButton(
              onPressed: onLibrary,
              style: TextButton.styleFrom(foregroundColor: colors.deskAccent),
              child: const Text('Open the library'),
            ),
          ],
        ),
        const SizedBox(height: PianoSpacing.xs),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            separatorBuilder: (_, _) => const SizedBox(width: PianoSpacing.md),
            itemBuilder: (context, i) => ShelfBook(
              cloth: CoverCloth.forStage(
                index: books[i].index,
                imported: books[i].imported,
              ),
              stage: books[i].stage,
              number: books[i].imported ? null : books[i].index + 1,
              unlocked: books[i].unlocked,
              progress: books[i].progress,
              current: books[i].stage.id == currentId,
              onOpen: books[i].unlocked ? () => onOpen(books[i]) : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// The pencil the teacher left on the desk, rolled a little off square.
class _DeskPencil extends StatelessWidget {
  const _DeskPencil();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        0,
        PianoSpacing.sm,
        PianoSpacing.xl,
        0,
      ),
      child: Transform.rotate(
        angle: -0.04,
        child: Image.asset(
          'assets/art/pencil.png',
          width: 300,
          excludeFromSemantics: true,
        ),
      ),
    ),
  );
}

/// No stages at all: the desk is bare apart from an invitation to import.
class _EmptyDesk extends StatelessWidget {
  const _EmptyDesk({required this.onImport});

  /// Null when this build cannot import.
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    final text = PianoTheme.textThemeOf(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: PaperSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No stages yet', style: text.headlineLarge),
              const SizedBox(height: PianoSpacing.xs),
              Text(
                onImport != null
                    ? 'Import a recording and it becomes a stage you can practise.'
                    : 'Stages will appear here once there are some to play.',
                textAlign: TextAlign.center,
                style: text.bodyMedium,
              ),
              if (onImport case final onImport?) ...[
                const SizedBox(height: PianoSpacing.md),
                FilledButton(
                  onPressed: onImport,
                  child: const Text('Import a piece'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
