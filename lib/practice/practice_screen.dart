import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../brand/buttons.dart';
import '../brand/palette.dart';
import '../data/settings_repository.dart';
import '../models/engine_models.dart';
import '../services/midi_service.dart';
import '../services/touch_keys.dart';
import 'input_check.dart';
import 'keys.dart';
import 'notation.dart';
import 'paper_staff.dart';
import 'results_page.dart';
import 'stage_controller.dart';

/// Opens a piece. The page slides up over the field in a quarter second.
Route<void> practiceRoute({required String stageId}) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondary) =>
        PracticeScreen(stageId: stageId),
    transitionsBuilder: (context, animation, secondary, child) =>
        FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
  );
}

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key, required this.stageId});

  final String stageId;

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  late final StageController _controller;
  late final List<Clef> _clefs;
  late final List<Engraved> _engraved;
  late final (int, int) _keys;
  bool _listening = false;
  bool _cantHear = false;

  // The input check: the first Start on a new setup asks for a C first.
  InputCheck? _check;
  final _checkClock = Stopwatch();
  final _checkSubs = <Object>[];
  Timer? _checkTimer;
  bool _checkSkipped = false;
  bool _heard = false;

  static const _speeds = [1.0, 0.75, 0.5];

  @override
  void initState() {
    super.initState();
    _controller = ref.read(stageControllerProvider(widget.stageId).notifier);
    final ui = ref.read(stageControllerProvider(widget.stageId));
    _clefs = stavesFor(ui.level);
    _engraved = engrave(ui.level, ui.notes);
    _keys = keyRange([for (final n in ui.notes) n.midiNote]);
  }

  @override
  void dispose() {
    _endCheck();
    // The controller outlives the route; leave it halted, not playing on.
    _controller.stop(syncEvents: false, notifyState: false);
    super.dispose();
  }

  Future<void> _start() async {
    final settings = ref.read(settingsProvider);
    final source = settings.inputSource;
    final midi = ref.read(midiServiceProvider);
    if (source.usesMidi) {
      try {
        await midi.connectSoleWiredDevice();
      } on Object {
        // No MIDI on this platform; the microphone may still do.
      }
    }
    if (source.usesMicrophone && !_listening) {
      bool granted;
      try {
        granted = await ref.read(audioGrantedProvider.future);
      } on Object {
        granted = false;
      }
      if (!mounted) return;
      setState(() {
        _listening = granted;
        _cantHear = !granted && source == PracticeInputSource.microphone;
      });
      if (_cantHear) return;
    }
    if (!mounted) return;
    // Taps on the screen are certain, so there is nothing to check.
    if (source.usesTouch) {
      await _controller.start();
      return;
    }
    final key = inputCheckKey(source, midi.selectedDevice?.id);
    if (settings.verifiedInput != key && !_checkSkipped) {
      _beginCheck(key, source);
      return;
    }
    await _controller.start();
  }

  /// Before the first piece on a new setup, ask for a C and say what is
  /// heard instead, so a silent microphone is found before a piece is
  /// marked wrong.
  void _beginCheck(String key, PracticeInputSource source) {
    final check = InputCheck(
      loud: ref.read(settingsProvider).minVolumeThreshold,
    );
    _checkClock
      ..reset()
      ..start();
    double now() => _checkClock.elapsedMicroseconds / 1e6;
    if (source.usesMicrophone) {
      _checkSubs.add(
        ref.listenManual(audioPitchStreamProvider, (_, next) {
          if (next.value case final e?) check.pitch(e, now());
        }),
      );
      _checkSubs.add(
        ref
            .read(audioEngineProvider)
            .levelStream
            .listen((l) => check.level(l, now())),
      );
    }
    if (source.usesMidi) {
      _checkSubs.add(
        ref.listenManual(midiPitchStreamProvider, (_, next) {
          if (next.value case final e?) check.pitch(e, now());
        }),
      );
    }
    _checkTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      check.tick(now());
      if (!mounted) return;
      if (check.hearing == Hearing.heard && !_heard) {
        _passCheck(key);
      } else {
        setState(() {});
      }
    });
    setState(() {
      _check = check;
      _heard = false;
    });
  }

  Future<void> _passCheck(String key) async {
    setState(() => _heard = true);
    _endCheck();
    await ref.read(settingsProvider.notifier).setVerifiedInput(key);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _check = null);
    await _controller.start();
  }

  /// The microphone was refused: play on the screen instead.
  Future<void> _useScreenKeys() async {
    await ref
        .read(settingsProvider.notifier)
        .setInputSource(PracticeInputSource.touch);
    if (!mounted) return;
    setState(() => _cantHear = false);
    await _start();
  }

  void _skipCheck() {
    _checkSkipped = true;
    _endCheck();
    setState(() => _check = null);
    _controller.start();
  }

  void _endCheck() {
    _checkTimer?.cancel();
    _checkTimer = null;
    for (final sub in _checkSubs) {
      switch (sub) {
        case ProviderSubscription<Object?>():
          sub.close();
        case StreamSubscription<Object?>():
          sub.cancel();
      }
    }
    _checkSubs.clear();
    _checkClock.stop();
  }

  void _transport(StageUiState ui) {
    switch (ui.status) {
      case StageEngineStatus.playing:
        _controller.pause();
      case StageEngineStatus.paused:
        _controller.resume();
      case StageEngineStatus.completed:
        _controller.replay();
      case StageEngineStatus.idle || StageEngineStatus.stopped:
        _start();
    }
  }

  void _cycleSpeed(double speed) {
    final i = _speeds.indexWhere((s) => (s - speed).abs() < 0.01);
    _controller.setSpeed(_speeds[(i + 1) % _speeds.length]);
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.stageId;
    if (_listening) ref.watch(practiceAudioSessionProvider);
    final ui = ref.watch(stageControllerProvider(id));
    final u = (MediaQuery.sizeOf(context).height / 720).clamp(0.7, 1.25);
    final source = ref.watch(settingsProvider.select((s) => s.inputSource));
    final finished = ui.status == StageEngineStatus.completed;
    final checking = _check != null;
    final title = ui.level.title;
    final message = switch (true) {
      _ when checking =>
        _heard
            ? 'Heard it. Starting the piece.'
            : 'Play middle C. ${_check!.message(midi: source == PracticeInputSource.midi)}',
      _ when _cantHear =>
        "The piano can't hear you yet. Allow the microphone, plug in a "
            'digital piano, or play on the keys on the screen.',
      _ => null,
    };
    final side = math.max(
      MediaQuery.paddingOf(context).left,
      MediaQuery.paddingOf(context).right,
    );
    return Material(
      color: Palette.field,
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, box) {
            final keysHeight = (box.maxHeight * 0.3).clamp(120.0, 260.0);
            return Column(
              children: [
                SizedBox(
                  height: 64 * u,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24 * u),
                    child: Row(
                      children: [
                        FieldAction(
                          label: 'Back',
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        Expanded(
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: Fonts.ui,
                              fontSize: 26 * u,
                              color: Colors.white,
                              fontVariations: const [
                                FontVariation('wght', 800),
                              ],
                            ),
                          ),
                        ),
                        if (checking && !_heard)
                          FieldAction(
                            label: 'Skip the check',
                            onPressed: _skipCheck,
                          )
                        else if (!checking) ...[
                          if (_cantHear)
                            FieldAction(
                              label: 'Use screen keys',
                              onPressed: _useScreenKeys,
                            ),
                          if (ui.loopMeasure != null)
                            FieldAction(
                              label: 'Whole piece',
                              onPressed: _controller.stopLoop,
                            ),
                          FieldAction(
                            label: 'Speed ${(ui.speed * 100).round()}%',
                            onPressed: () => _cycleSpeed(ui.speed),
                          ),
                          FieldAction(
                            label: switch (ui.status) {
                              StageEngineStatus.playing => 'Pause',
                              StageEngineStatus.paused => 'Resume',
                              StageEngineStatus.completed => 'Again',
                              _ => 'Start',
                            },
                            onPressed: () => _transport(ui),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Palette.page,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: finished && ui.loopMeasure == null
                        ? ResultsPage(
                            summary: RunSummary.of(ui.noteStates, [
                              for (final n in ui.notes) n.measureIndex,
                            ]),
                            staff: StaticStaff(
                              level: ui.level,
                              notes: ui.notes,
                              noteStates: ui.noteStates,
                              fitWhole: true,
                            ),
                            onPractise: _controller.loopBar,
                            onAgain: _controller.replay,
                            onDone: () => Navigator.of(context).maybePop(),
                          )
                        : _Stage(
                            ui: ui,
                            clefs: _clefs,
                            engraved: _engraved,
                            message: message,
                            leftInset: side,
                            u: u,
                          ),
                  ),
                ),
                SizedBox(
                  height: keysHeight,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12 * u),
                    child: PaperKeyboard(
                      low: _keys.$1,
                      high: _keys.$2,
                      sounding: ui.sounding,
                      next: checking
                          ? 60
                          : (finished && ui.loopMeasure == null)
                          ? null
                          : _nextNote(ui),
                      onPress: source.usesTouch
                          ? ref.read(touchKeysProvider).press
                          : null,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static int? _nextNote(StageUiState ui) {
    for (final (i, s) in ui.noteStates.indexed) {
      if (s == NoteState.active) return ui.notes[i].midiNote;
    }
    for (final (i, s) in ui.noteStates.indexed) {
      if (s == NoteState.upcoming &&
          ui.notes[i].startBeat >= ui.currentBeat - 0.01) {
        return ui.notes[i].midiNote;
      }
    }
    return null;
  }
}

/// The staff on its page, with a line of plain words above when there is
/// something to say.
class _Stage extends StatelessWidget {
  const _Stage({
    required this.ui,
    required this.clefs,
    required this.engraved,
    required this.message,
    required this.leftInset,
    required this.u,
  });

  final StageUiState ui;
  final List<Clef> clefs;
  final List<Engraved> engraved;
  final String? message;
  final double leftInset;
  final double u;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final area = Offset.zero & box.biggest;
        final layout = StaffLayout.fit(
          area,
          leftInset: leftInset,
          staves: clefs.length,
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: PaperStaffPainter(
                level: ui.level,
                clefs: clefs,
                engraved: engraved,
                noteStates: ui.noteStates,
                currentBeat: ui.currentBeat,
                layout: layout,
                loopMeasure: ui.loopMeasure,
              ),
            ),
            if (message != null)
              Positioned(
                left: 24 * u,
                right: 24 * u,
                top: 14 * u,
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: Fonts.ui,
                    fontSize: 22 * u,
                    height: 1.25,
                    color: Palette.ink,
                    fontVariations: const [FontVariation('wght', 700)],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
