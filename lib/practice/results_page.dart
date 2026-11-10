import 'package:flutter/material.dart';

import '../brand/buttons.dart';
import '../brand/palette.dart';
import '../brand/pencil_loop.dart';
import '../models/engine_models.dart';

/// What a run came to, in the teacher's terms: notes right first time, and
/// which bars to play again.
class RunSummary {
  const RunSummary({
    required this.right,
    required this.total,
    required this.missedBars,
    required this.worstBar,
  });

  factory RunSummary.of(List<NoteState> states, List<int> measureOfNote) {
    var right = 0;
    final misses = <int, int>{};
    for (final (i, s) in states.indexed) {
      switch (s) {
        case NoteState.hitPerfect || NoteState.hitGood || NoteState.hitOkay:
          right++;
        case NoteState.missed:
          misses[measureOfNote[i]] = (misses[measureOfNote[i]] ?? 0) + 1;
        case NoteState.upcoming || NoteState.active:
          break;
      }
    }
    final bars = misses.keys.toList()..sort();
    int? worst;
    for (final bar in bars) {
      if (worst == null || misses[bar]! > misses[worst]!) worst = bar;
    }
    return RunSummary(
      right: right,
      total: states.length,
      missedBars: bars,
      worstBar: worst,
    );
  }

  final int right;
  final int total;

  /// Measure indices, zero-based, that held a missed note.
  final List<int> missedBars;
  final int? worstBar;

  int get missed => total - right;

  String get headline {
    if (missed == 0) return 'Every note right first time.';
    return missed == 1
        ? 'One note needed another go.'
        : '$missed notes needed another go.';
  }

  String get advice {
    final bar = worstBar;
    if (bar == null) return 'The next piece in the book is open.';
    return 'Bar ${bar + 1} had the most. Play it slowly a few times and it '
        'will stick.';
  }
}

/// The page handed back marked: the grade circled in red pencil, a plain
/// sentence, and what to do next.
class ResultsPage extends StatelessWidget {
  const ResultsPage({
    super.key,
    required this.summary,
    required this.staff,
    required this.onPractise,
    required this.onAgain,
    required this.onDone,
  });

  final RunSummary summary;

  /// The piece, marked, shown above the verdict.
  final Widget staff;
  final void Function(int bar) onPractise;
  final VoidCallback onAgain;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final u = (MediaQuery.sizeOf(context).height / 720).clamp(0.7, 1.25);
    final bar = summary.worstBar;
    return Padding(
      padding: EdgeInsets.fromLTRB(40 * u, 8 * u, 40 * u, 20 * u),
      child: Column(
        children: [
          Expanded(flex: 5, child: staff),
          Expanded(
            flex: 6,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Grade(summary: summary, u: u),
                SizedBox(width: 48 * u),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.headline,
                          style: TextStyle(
                            fontFamily: Fonts.ui,
                            fontSize: 30 * u,
                            height: 1.1,
                            color: Palette.ink,
                            fontVariations: const [FontVariation('wght', 800)],
                          ),
                        ),
                        SizedBox(height: 8 * u),
                        Text(
                          summary.advice,
                          style: TextStyle(
                            fontFamily: Fonts.ui,
                            fontSize: 20 * u,
                            height: 1.35,
                            color: Palette.graphite,
                          ),
                        ),
                        SizedBox(height: 22 * u),
                        Wrap(
                          spacing: 14 * u,
                          runSpacing: 12 * u,
                          children: [
                            if (bar != null)
                              StartButton(
                                label: 'Practise bar ${bar + 1}',
                                onPressed: () => onPractise(bar),
                              ),
                            QuietButton(
                              label: 'Play again',
                              onPressed: onAgain,
                            ),
                            QuietButton(
                              label: 'Back to pieces',
                              onPressed: onDone,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Grade extends StatelessWidget {
  const _Grade({required this.summary, required this.u});

  final RunSummary summary;
  final double u;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${summary.right} of ${summary.total} notes right first time',
      child: ExcludeSemantics(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 44 * u,
                vertical: 30 * u,
              ),
              child: Text(
                '${summary.right}/${summary.total}',
                style: TextStyle(
                  fontFamily: Fonts.ui,
                  fontSize: 96 * u,
                  height: 1,
                  letterSpacing: -4 * u,
                  color: Palette.ink,
                  fontVariations: const [FontVariation('wght', 800)],
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _GradeLoop(width: 5.5 * u.clamp(0.8, 1.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeLoop extends CustomPainter {
  const _GradeLoop({required this.width});

  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    PencilLoopPainter(
      target: (Offset.zero & size).deflate(2),
      color: Palette.pencilRed,
      width: width,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_GradeLoop old) => old.width != width;
}
