import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
import 'tour_link.dart' if (dart.library.js_interop) 'tour_link_web.dart';

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

    // Practice opens on the keyboard render; load it while the desk is up so
    // it does not pop in a frame after the sheet lands.
    precacheImage(const AssetImage('assets/art/keyboard.png'), context);

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
                final book = _OpenBook(
                  book: current,
                  stageCount: books.length,
                  onStart: () => open(current),
                  stacked: !wide,
                );

                // The lamp over the desk: the open book sits in its light,
                // and the shelf falls off into the lacquer.
                return DeskLamp(
                  radius: wide ? 0.9 : 1.2,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      wide ? PianoSpacing.xl : PianoSpacing.md,
                      PianoSpacing.xs,
                      wide ? PianoSpacing.xl : PianoSpacing.md,
                      PianoSpacing.lg,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [book, const _DeskPencil(), shelf],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// The current stage's method book, lying open on the desk: the cloth
/// boards, the lesson on the left page and the music on the right. The
/// right page is the sheet that carries over into practice.
class _OpenBook extends StatelessWidget {
  const _OpenBook({
    required this.book,
    required this.stageCount,
    required this.onStart,
    required this.stacked,
  });

  final _Book book;
  final int stageCount;
  final VoidCallback onStart;

  /// Narrow screens read the pages one above the other.
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final cloth = switch (CoverCloth.forStage(
      index: book.index,
      imported: book.imported,
    )) {
      CoverCloth.blue => colors.coverBlue,
      CoverCloth.green => colors.coverGreen,
      CoverCloth.rust => colors.coverRust,
      CoverCloth.slate => colors.coverSlate,
    };
    final lesson = _BookPage(
      gutter: stacked ? null : AxisDirection.right,
      child: _LessonPage(book: book, stageCount: stageCount),
    );
    final music = HeroMode(
      enabled: !MediaQuery.of(context).disableAnimations,
      child: Hero(
        tag: scoreHeroTag(book.stage.id),
        child: _BookPage(
          gutter: stacked ? null : AxisDirection.left,
          child: _MusicPage(book: book, onStart: onStart, fill: !stacked),
        ),
      ),
    );

    return Padding(
      // Room for the ribbon above the boards.
      padding: const EdgeInsets.only(top: PianoSpacing.md),
      child: Transform.rotate(
        angle: -0.4 * math.pi / 180,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cloth,
            borderRadius: BorderRadius.circular(6),
            image: DecorationImage(
              image: const AssetImage('assets/art/paper.png'),
              repeat: ImageRepeat.repeat,
              scale: 1.5,
              // The paper grain, multiplied in, reads as the cloth's weave.
              colorFilter: ColorFilter.mode(cloth, BlendMode.multiply),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xCC000000),
                blurRadius: 36,
                spreadRadius: -6,
                offset: Offset(0, 22),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
            child: stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [lesson, const SizedBox(height: 6), music],
                  )
                : IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 2, child: lesson),
                        Expanded(flex: 3, child: music),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// One page of the open book. The edge toward the spine darkens where the
/// paper curves down into the binding.
class _BookPage extends StatelessWidget {
  const _BookPage({required this.child, this.gutter});

  final Widget child;

  /// Which side the spine is on; null for a page read on its own.
  final AxisDirection? gutter;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final side = gutter;
    final page = Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.paper,
          image: DecorationImage(
            image: const AssetImage('assets/art/paper.png'),
            repeat: ImageRepeat.repeat,
            scale: 2,
            colorFilter: ColorFilter.mode(colors.paper, BlendMode.multiply),
          ),
        ),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            gradient: side == null
                ? null
                : LinearGradient(
                    begin: side == AxisDirection.right
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    end: side == AxisDirection.right
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    stops: const [0, 0.07, 0.2],
                    colors: [
                      Colors.black.withValues(alpha: 0.22),
                      Colors.black.withValues(alpha: 0.06),
                      Colors.black.withValues(alpha: 0),
                    ],
                  ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              PianoSpacing.xl,
              PianoSpacing.lg,
              PianoSpacing.xl,
              PianoSpacing.lg,
            ),
            child: child,
          ),
        ),
      ),
    );
    // The leaves beneath show along the bottom edge: a book has thickness.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final (drop, shade) in [
          (4.0, colors.paper3),
          (2.0, colors.paper2),
        ])
          Positioned(
            left: 2,
            right: 2,
            top: drop,
            bottom: -drop,
            child: ColoredBox(color: shade),
          ),
        page,
      ],
    );
  }
}

/// The left page: which lesson this is, what it teaches, and how it went.
class _LessonPage extends StatelessWidget {
  const _LessonPage({required this.book, required this.stageCount});

  final _Book book;
  final int stageCount;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: PianoSpacing.sm),
        Text(
          stage.description,
          style: text.headlineSmall?.copyWith(
            color: colors.ink2,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w400,
            fontVariations: const [FontVariation('wght', 400)],
          ),
        ),
        const SizedBox(height: PianoSpacing.lg),
        Wrap(
          spacing: PianoSpacing.lg,
          runSpacing: PianoSpacing.xs,
          children: [
            _Fact(label: 'Tempo', value: '${stage.level.tempo}'),
            _Fact(
              label: 'Time',
              value: '${stage.level.beatsPerMeasure}/${stage.level.beatUnit}',
            ),
            if (attempts > 0) ...[
              _Fact(
                label: 'Best',
                value: '${((book.progress?.bestAccuracy ?? 0) * 100).round()}%',
              ),
              _Fact(label: attempts == 1 ? 'Run' : 'Runs', value: '$attempts'),
            ],
          ],
        ),
      ],
    );
  }
}

/// The right page: the opening bars and the one action, circled in pencil.
class _MusicPage extends StatelessWidget {
  const _MusicPage({
    required this.book,
    required this.onStart,
    required this.fill,
  });

  final _Book book;
  final VoidCallback onStart;

  /// Beside the lesson page, the action sits at the foot of a page as tall
  /// as its neighbour.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final text = PianoTheme.textThemeOf(context);
    final stage = book.stage;
    final attempts = book.progress?.attempts ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: stage.level.clef == LevelClef.grand ? 170 : 116,
          child: _OpeningBars(level: stage.level),
        ),
        if (attempts == 0) ...[
          const SizedBox(height: PianoSpacing.sm),
          Text(
            'Play your piano while Piano Tool follows the music and marks your notes.',
            style: text.bodyMedium,
          ),
        ],
        if (fill) const Spacer(),
        const SizedBox(height: PianoSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (kIsWeb)
              TextButton(
                onPressed: openTour,
                child: const Text('How it works'),
              ),
            const Spacer(),
            PencilButton(
              label: attempts > 0 ? 'Resume' : 'Start',
              semanticLabel:
                  '${attempts > 0 ? 'Resume' : 'Start'} ${stage.title}',
              onPressed: onStart,
            ),
          ],
        ),
      ],
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
          if (!note.isRest)
            (
              midi: note.midiNote,
              startBeat: note.startBeat,
              durationBeats: note.durationBeats,
              alter: note.alter,
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
            Expanded(
              child: Wrap(
                spacing: PianoSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Your books',
                    style: text.titleLarge?.copyWith(color: colors.deskInk),
                  ),
                  Text(
                    '$cleared of ${books.length} cleared',
                    style: text.bodySmall?.copyWith(color: colors.deskMuted),
                  ),
                ],
              ),
            ),
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
