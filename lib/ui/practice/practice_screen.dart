import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../models/engine_models.dart';
import '../../models/level_models.dart';
import '../desk/desk.dart';
import '../keyboard/piano_keyboard_view.dart';
import '../staff/notation.dart';
import '../staff/staff_geometry.dart';
import '../staff/staff_painter.dart';
import '../staff/staff_view.dart';
import '../results/results_screen.dart';
import 'mic_permission_gate.dart';
import 'practice_hud.dart';
import 'stage_controller.dart';
import 'transport_column.dart';

/// The keyboard shows the piece's own octaves until the learner asks for
/// all 61 keys. Kept for the session, across pieces.
final keyboardCloseUpProvider = StateProvider<bool>((ref) => true);

/// Letter names on the white keys, off until asked for.
final keyNamesProvider = StateProvider<bool>((ref) => false);

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
  bool _showingResults = false;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(stageControllerProvider(widget.stageId).notifier);

    _completionSub = _controller.events.listen((event) {
      event.whenOrNull(
        stageCompleted: (accuracy, score, totalNotes, hitNotes) {
          if (!mounted || _showingResults) return;
          _showingResults = true;
          final played = ref.read(stageControllerProvider(widget.stageId));
          context.goNamed(
            'results',
            pathParameters: {'stageId': widget.stageId},
            extra: StageResult(
              stageId: widget.stageId,
              title: _controller.levelTitle,
              score: score,
              accuracy: accuracy,
              totalNotes: totalNotes,
              hitNotes: hitNotes,
              level: played.level,
              notes: played.notes,
              noteStates: played.noteStates,
            ),
          );
        },
      );
    });
  }

  @override
  void dispose() {
    _completionSub?.cancel();
    // The engine owns a periodic timer that outlives this widget: the provider
    // is not autoDispose, so leaving mid-song would keep the song running,
    // marking notes missed and eventually recording a completion the learner
    // never played.
    final controller = _controller;
    final completed = controller.isCompleted;
    controller.stop(syncEvents: false, notifyState: false, syncState: false);
    if (!completed) {
      Future<void>.microtask(() {
        if (!controller.mounted) return;
        controller.publishStoppedState();
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stageId = widget.stageId;
    final level = ref.watch(
      stageControllerProvider(stageId).select((s) => s.level),
    );
    final closeUp = ref.watch(keyboardCloseUpProvider);

    return Scaffold(
      body: SafeArea(
        // Microphone and dual-input practice wait for a recorder; MIDI-only
        // practice can open the transport without microphone permission.
        child: MicPermissionGate(
          startAudio: true,
          child: Row(
            children: [
              _TransportPane(stageId: stageId),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // The keyboard is the rendered instrument at its own
                    // proportions, so its height follows the width; on a short
                    // screen it gives up the top of the fallboard, never keys.
                    // Closer up, the keys get a little more of the height:
                    // that is what makes them big enough to read.
                    final keyboardHeight = closeUp
                        ? constraints.maxHeight * 0.34
                        : (constraints.maxWidth / PianoKeyboardView.imageAspect)
                              .clamp(64.0, constraints.maxHeight * 0.3);

                    return Column(
                      children: [
                        _HudPane(stageId: stageId, level: level),
                        // The staff takes the remainder, so it grows on a
                        // larger screen instead of leaving a dead band.
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 4, 12, 10),
                            child: HeroMode(
                              enabled: !MediaQuery.of(
                                context,
                              ).disableAnimations,
                              child: Hero(
                                tag: scoreHeroTag(stageId),
                                child: PaperSheet(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: _StaffPane(
                                    stageId: stageId,
                                    level: level,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
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
    final closeUp = ref.watch(keyboardCloseUpProvider);
    final noteNames = ref.watch(keyNamesProvider);

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
      closeUp: closeUp,
      onCloseUpChanged: (v) =>
          ref.read(keyboardCloseUpProvider.notifier).state = v,
      noteNames: noteNames,
      onNoteNamesChanged: (v) => ref.read(keyNamesProvider.notifier).state = v,
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
    final progress = ref.watch(
      stageControllerProvider(stageId).select((s) => s.progress),
    );

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
    final systems = _buildSystems(ref, stageId, level);

    return LayoutBuilder(
      builder: (context, box) => StaffView(
        systems: systems,
        // A big screen gets a bigger staff, up to the point where it would
        // stop reading as notation; a small one keeps the usual cap.
        maxStaffHeight: (box.maxHeight / systems.length * 0.34).clamp(
          kDefaultMaxStaffHeight,
          124.0,
        ),
        currentBeat: currentBeat,
        totalBeats: (level.totalMeasures * level.beatsPerMeasure).toDouble(),
        beatsPerMeasure: level.beatsPerMeasure,
        beatUnit: level.beatUnit,
        pixelsPerBeat: pixelsPerBeatFor([
          for (final m in level.measures)
            for (final n in m.notes)
              if (!n.isRest) n.durationBeats,
        ]),
      ),
    );
  }
}

List<StaffSystem> _buildSystems(
  WidgetRef ref,
  String stageId,
  LevelModel level,
) {
  final levelNotes = ref.watch(
    stageControllerProvider(stageId).select((s) => s.notes),
  );
  final states = ref.watch(noteStatesProvider(stageId));
  final placed = [
    for (var i = 0; i < levelNotes.length; i++)
      (
        midi: levelNotes[i].midiNote,
        startBeat: levelNotes[i].startBeat,
        durationBeats: levelNotes[i].durationBeats,
        alter: levelNotes[i].alter,
        state: i < states.length ? states[i] : NoteState.upcoming,
      ),
  ];

  return staffSystemsFor(level.clef, levelNotes, placed);
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
    final closeUp = ref.watch(keyboardCloseUpProvider);
    // Fixed for the whole piece, so the keys never slide while reading.
    final range = closeUp
        ? keyRangeFor(
            ref
                .watch(stageControllerProvider(stageId).select((s) => s.notes))
                .map((n) => n.midiNote),
          )
        : null;
    return PianoKeyboardView(
      due: due,
      playing: playing,
      range: range,
      noteNames: ref.watch(keyNamesProvider),
    );
  }
}

/// The level's notes zipped with their live states, in the shape the staff
/// painter wants.
List<PlacedNote> _placedNotes(WidgetRef ref, String stageId) {
  final levelNotes = ref.watch(
    stageControllerProvider(stageId).select((s) => s.notes),
  );
  final states = ref.watch(noteStatesProvider(stageId));

  return [
    for (var i = 0; i < levelNotes.length; i++)
      (
        midi: levelNotes[i].midiNote,
        startBeat: levelNotes[i].startBeat,
        durationBeats: levelNotes[i].durationBeats,
        alter: levelNotes[i].alter,
        state: i < states.length ? states[i] : NoteState.upcoming,
      ),
  ];
}
