import 'package:flutter/material.dart';

import '../../data/progress_repository.dart';
import '../../models/engine_models.dart';
import '../../models/level_models.dart';
import '../desk/desk.dart';
import '../desk/pencil_mark.dart';
import '../staff/notation.dart';
import '../staff/staff_view.dart';
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
    this.level,
    this.notes = const [],
    this.noteStates = const [],
  });

  final String stageId;
  final String title;
  final int score;
  final double accuracy;
  final int totalNotes;
  final int hitNotes;

  /// The piece as played, so the sheet can show the marked score. Empty
  /// when the caller only has the totals.
  final LevelModel? level;
  final List<LevelNote> notes;
  final List<NoteState> noteStates;
}

/// The bars with the most misses: one bar, or two neighbouring bars when
/// both had misses. Null when nothing was missed or nothing was played.
({int first, int last})? hardestPassage(
  List<LevelNote> notes,
  List<NoteState> states, {
  required int beatsPerMeasure,
}) {
  final misses = <int, int>{};
  for (var i = 0; i < notes.length && i < states.length; i++) {
    if (states[i] != NoteState.missed) continue;
    final m = (notes[i].startBeat / beatsPerMeasure + 1e-6).floor();
    misses[m] = (misses[m] ?? 0) + 1;
  }
  if (misses.isEmpty) return null;
  ({int first, int last})? best;
  var bestCount = 0;
  for (final m in misses.keys.toList()..sort()) {
    final pair = misses[m]! + (misses[m + 1] ?? 0);
    if (pair > bestCount) {
      bestCount = pair;
      best = (first: m, last: misses.containsKey(m + 1) ? m + 1 : m);
    }
  }
  return best;
}

/// Plain words for a passage, counted from bar 1.
String passageLabel(({int first, int last}) p) => p.first == p.last
    ? 'Bar ${p.first + 1} had the most misses.'
    : 'Bars ${p.first + 1} and ${p.last + 1} had the most misses.';

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
      body: DeskLamp(
        center: Alignment.center,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                PianoSpacing.lg,
                PianoSpacing.xl,
                PianoSpacing.lg,
                PianoSpacing.lg,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
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
                      if (result.level case final level?
                          when result.notes.isNotEmpty) ...[
                        const SizedBox(height: PianoSpacing.md),
                        _MarkedScore(result: result, level: level),
                      ],
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
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
      ),
    );
  }
}

/// The score as it was played, every note marked, with the hardest bars
/// looped in pencil and named underneath. It is the same sheet the
/// learner practised from, carried over from the practice screen.
class _MarkedScore extends StatelessWidget {
  const _MarkedScore({required this.result, required this.level});

  final StageResult result;
  final LevelModel level;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final text = Theme.of(context).textTheme;
    final bpm = level.beatsPerMeasure;
    final placed = [
      for (var i = 0; i < result.notes.length; i++)
        (
          midi: result.notes[i].midiNote,
          startBeat: result.notes[i].startBeat,
          durationBeats: result.notes[i].durationBeats,
          alter: result.notes[i].alter,
          state: i < result.noteStates.length
              ? result.noteStates[i]
              : NoteState.upcoming,
        ),
    ];
    final passage = hardestPassage(
      result.notes,
      result.noteStates,
      beatsPerMeasure: bpm,
    );
    final played = result.noteStates.any(
      (s) => s != NoteState.upcoming && s != NoteState.active,
    );
    final totalBeats = (level.totalMeasures * bpm).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeroMode(
          enabled: !MediaQuery.of(context).disableAnimations,
          child: Hero(
            tag: scoreHeroTag(result.stageId),
            child: SizedBox(
              height: level.clef == LevelClef.grand ? 200 : 132,
              child: ExcludeSemantics(
                child: StaffView(
                  systems: staffSystemsFor(level.clef, result.notes, placed),
                  // Scrolled so the looped bars are in view.
                  currentBeat: passage == null
                      ? 0
                      : (passage.first * bpm).toDouble(),
                  totalBeats: totalBeats,
                  beatsPerMeasure: bpm,
                  beatUnit: level.beatUnit,
                  pixelsPerBeat: pixelsPerBeatFor(
                    result.notes.map((n) => n.durationBeats),
                    base: 44,
                  ),
                  maxStaffHeight: 56,
                  showPlayhead: false,
                  bracket: passage == null
                      ? null
                      : (
                          start: (passage.first * bpm).toDouble(),
                          end: ((passage.last + 1) * bpm).toDouble(),
                        ),
                ),
              ),
            ),
          ),
        ),
        if (played)
          Text(
            passage == null
                ? 'Every bar played without a miss.'
                : passageLabel(passage),
            style: text.bodyLarge?.copyWith(
              color: passage == null ? colors.success : colors.accent,
            ),
          ),
      ],
    );
  }
}
