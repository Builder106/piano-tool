import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/engine_models.dart';
import '../../models/level_models.dart';
import '../keyboard/piano_keyboard_view.dart';
import '../staff/staff_geometry.dart';
import '../staff/staff_painter.dart';
import '../staff/staff_view.dart';
import '../results/results_screen.dart';
import 'mic_permission_gate.dart';
import 'practice_hud.dart';
import 'stage_controller.dart';
import 'transport_column.dart';

/// The practice loop: a fixed control column on the left, with the HUD, the
/// staff, and the keyboard stacked beside it.
///
/// The control column is the only fixed size in the layout, and it sits on the
/// horizontal axis, which has slack. Every vertical child either wraps its own
/// content, is clamped, or takes the remainder, so there is no arrangement of
/// screen sizes that can overflow the column.
///
/// Each pane is its own consumer. The screen itself watches only the level,
/// which never changes during a stage, so a playhead tick rebuilds the staff
/// and not the transport beside it.
class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key, required this.stageId});

  final String stageId;

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  /// Held from initState because `ref` is already unusable by the time
  /// dispose runs.
  late final StageController _controller;
  StreamSubscription<StageEvent>? _completionSub;
  var _showingResults = false;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(stageControllerProvider(widget.stageId).notifier);

    _completionSub = _controller.events.listen((event) {
      event.whenOrNull(stageCompleted: (accuracy, score, totalNotes, hitNotes) {
        if (!mounted || _showingResults) return;
        _showingResults = true;
        context.goNamed(
          'results',
          pathParameters: {'stageId': widget.stageId},
          extra: StageResult(
            stageId: widget.stageId,
            title: _controller.state.level.title,
            score: score,
            accuracy: accuracy,
            totalNotes: totalNotes,
            hitNotes: hitNotes,
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _completionSub?.cancel();
    // The engine owns a periodic timer that outlives this widget: the provider
    // is not autoDispose, so leaving mid-song would keep the song running,
    // marking notes missed and eventually recording a completion the learner
    // never played.
    // The provider remains alive after this widget is removed, so stop the
    // engine even if Riverpod has already detached the notifier from its
    // listeners. The silent path does not publish provider state.
    _controller.stop(notify: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stageId = widget.stageId;
    final level =
        ref.watch(stageControllerProvider(stageId).select((s) => s.level));

    return Scaffold(
      body: SafeArea(
        // Without a microphone nothing can be scored, so the transport and the
        // staff stay unreachable rather than pretending to listen.
        child: MicPermissionGate(
          child: Row(
            children: [
              _TransportPane(stageId: stageId),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // The keyboard takes a fifth of the height, floored and
                    // capped so it stays legible on a short screen without
                    // eating a tall one.
                    final keyboardHeight =
                        (constraints.maxHeight * 0.21).clamp(64.0, 88.0);

                    return Column(
                      children: [
                        _HudPane(stageId: stageId, level: level),
                        // The staff takes the remainder, so it grows on a
                        // larger screen instead of leaving a dead band.
                        Expanded(
                            child: _StaffPane(stageId: stageId, level: level)),
                        SizedBox(
                          height: keyboardHeight,
                          child: _KeyboardPane(stageId: stageId),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rebuilds only when the transport itself changes, never on a playhead tick.
class _TransportPane extends ConsumerWidget {
  const _TransportPane({required this.stageId});

  final String stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(engineStatusProvider(stageId));
    final speed = ref.watch(playbackSpeedProvider(stageId));
    final controller = ref.read(stageControllerProvider(stageId).notifier);

    return TransportColumn(
      isPlaying: status == StageEngineStatus.playing,
      speed: speed,
      onPlayPause: () {
        switch (status) {
          case StageEngineStatus.playing:
            controller.pause();
          case StageEngineStatus.paused:
            controller.resume();
          case _:
            controller.start();
        }
      },
      onStop: controller.stop,
      onReplay: controller.replay,
      onSpeedChanged: controller.setSpeed,
    );
  }
}

class _HudPane extends ConsumerWidget {
  const _HudPane({required this.stageId, required this.level});

  final String stageId;
  final LevelModel level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(scoreProvider(stageId));
    final accuracy = ref.watch(accuracyProvider(stageId));
    // The state's own progress, rather than a second copy of the same sum.
    // A double compares by value, so this slice really does narrow.
    final progress =
        ref.watch(stageControllerProvider(stageId).select((s) => s.progress));

    return PracticeHud(
      title: level.title,
      tempo: level.tempo,
      score: score,
      accuracy: accuracy,
      progress: progress,
      onBack: Navigator.of(context).canPop()
          ? () => Navigator.of(context).pop()
          : null,
    );
  }
}

/// The one pane that genuinely has to rebuild on every tick: the playhead moves.
class _StaffPane extends ConsumerWidget {
  const _StaffPane({required this.stageId, required this.level});

  final String stageId;
  final LevelModel level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentBeat = ref.watch(currentBeatProvider(stageId));

    return StaffView(
      systems: [(clef: Clef.treble, notes: _placedNotes(ref, stageId))],
      currentBeat: currentBeat,
      totalBeats: (level.totalMeasures * level.beatsPerMeasure).toDouble(),
      beatsPerMeasure: level.beatsPerMeasure,
      pixelsPerBeat: 70,
    );
  }
}

class _KeyboardPane extends ConsumerWidget {
  const _KeyboardPane({required this.stageId});

  final String stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // What the learner should be playing now, against what the microphone is
    // actually hearing.
    final due = {
      for (final note in _placedNotes(ref, stageId))
        if (note.state == NoteState.active) note.midi,
    };
    final playing = ref.watch(soundingProvider(stageId));
    return PianoKeyboardView(due: due, playing: playing);
  }
}

/// The level's notes zipped with their live states, in the shape the staff
/// painter wants.
List<PlacedNote> _placedNotes(WidgetRef ref, String stageId) {
  final levelNotes =
      ref.watch(stageControllerProvider(stageId).select((s) => s.notes));
  final states = ref.watch(noteStatesProvider(stageId));

  return [
    for (var i = 0; i < levelNotes.length; i++)
      (
        midi: levelNotes[i].midiNote,
        startBeat: levelNotes[i].startBeat,
        state: i < states.length ? states[i] : NoteState.upcoming,
      ),
  ];
}
