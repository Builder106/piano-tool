import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../brand/nickel_inlay.dart';
import '../brand/palette.dart';
import '../brand/pencil_loop.dart';
import '../data/settings_repository.dart';
import '../home/paper_slip.dart';
import '../home/strung_geometry.dart';
import '../models/engine_models.dart';
import '../services/midi_service.dart';
import 'input_check.dart';
import 'metronome.dart';
import 'notation.dart';
import 'stage_controller.dart';
import 'strung_staff.dart';

const soundboardAsset = 'assets/art/strung/soundboard.jpg';

/// Opens a piece from its string on the home screen. The route draws the
/// whole scene itself, starting from the home framing, so the piano never
/// cuts away.
Route<void> practiceRoute({required String stageId, required int midi}) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 900),
    reverseTransitionDuration: const Duration(milliseconds: 650),
    pageBuilder: (context, animation, secondary) =>
        PracticeScreen(stageId: stageId, midi: midi),
    transitionsBuilder: (context, animation, secondary, child) => child,
  );
}

/// Image rows of the home render: where the practice framing cuts it.
const _boardTop = 0.585;
const _keysCut = 0.90;

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key, required this.stageId, required this.midi});

  final String stageId;

  /// The piece's string on the home screen, where the staff swings from.
  final int midi;

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _clock = ValueNotifier(Duration.zero);
  var _rings = <Ring>[];
  late final StageController _controller;
  late final List<Clef> _clefs;
  late final List<Engraved> _engraved;
  late final Map<int, int> _staffOf;
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
    _staffOf = {
      for (final e in _engraved.reversed)
        if (e.noteIndex != null) e.noteIndex!: e.staff,
    };
    _ticker = createTicker((elapsed) {
      _clock.value = elapsed;
      if (_rings.any((r) => r.envelope(elapsed) < 0.01)) {
        _rings = [
          for (final r in _rings)
            if (r.envelope(elapsed) >= 0.01) r,
        ];
      }
    })..start();
  }

  @override
  void dispose() {
    _endCheck();
    _ticker.dispose();
    _clock.dispose();
    // The controller outlives the route; leave it halted, not playing on.
    _controller.stop(syncEvents: false, notifyState: false);
    super.dispose();
  }

  int _staff(int noteIndex) => _staffOf[noteIndex] ?? 0;

  void _onNoteStates(List<NoteState>? before, List<NoteState> after) {
    final ui = ref.read(stageControllerProvider(widget.stageId));
    final now = _clock.value;
    final added = <Ring>[];
    for (var i = 0; i < after.length; i++) {
      final was = before != null && i < before.length ? before[i] : null;
      if (was == after[i]) continue;
      final note = ui.notes[i];
      final staff = _staff(i);
      final lines = ringingLines(
        staffStep(note.midiNote, _clefs[staff], alter: note.alter),
      );
      final seconds = note.durationBeats * 60 / (ui.level.tempo * ui.speed);
      final ring = switch (after[i]) {
        NoteState.hitPerfect => (0.24, 1.0),
        NoteState.hitGood => (0.16, 0.75),
        NoteState.hitOkay => (0.10, 0.5),
        _ => null,
      };
      if (ring != null) {
        added.add(
          Ring(
            measure: note.measureIndex,
            staff: staff,
            lines: lines,
            amplitude: ring.$1,
            decay: (seconds * 0.8).clamp(0.35, 2.5),
            frequency: 7,
            start: now,
            glow: ring.$2,
          ),
        );
      } else if (after[i] == NoteState.missed) {
        // A dull thud: the string barely moves and stops at once.
        added.add(
          Ring(
            measure: note.measureIndex,
            staff: staff,
            lines: lines,
            amplitude: 0.08,
            decay: 0.08,
            frequency: 3,
            start: now,
          ),
        );
      }
    }
    if (added.isNotEmpty) setState(() => _rings = [..._rings, ...added]);
  }

  /// At the end every bar that was played rings at once, as loud as it was
  /// played well; the still bars are the ones to practise.
  void _onFinished() {
    final ui = ref.read(stageControllerProvider(widget.stageId));
    final now = _clock.value;
    final played = <int, (int, int)>{};
    for (final (i, note) in ui.notes.indexed) {
      final (hit, all) = played[note.measureIndex] ?? (0, 0);
      final ok = switch (ui.noteStates[i]) {
        NoteState.hitPerfect || NoteState.hitGood || NoteState.hitOkay => 1,
        _ => 0,
      };
      played[note.measureIndex] = (hit + ok, all + 1);
    }
    setState(() {
      _rings = [
        for (final MapEntry(key: m, value: (hit, all)) in played.entries)
          if (hit > 0)
            for (var staff = 0; staff < _clefs.length; staff++)
              Ring(
                measure: m,
                staff: staff,
                lines: const [0, 1, 2, 3, 4],
                amplitude: 0.2 * hit / all,
                decay: 3.2,
                frequency: 5,
                start: now,
                glow: hit / all,
              ),
      ];
    });
  }

  Future<void> _start() async {
    final settings = ref.read(settingsProvider);
    final source = settings.inputSource;
    final midi = ref.read(midiServiceProvider);
    if (source != PracticeInputSource.microphone) {
      try {
        await midi.connectSoleWiredDevice();
      } on Object {
        // No MIDI on this platform; the microphone may still do.
      }
    }
    if (source != PracticeInputSource.midi && !_listening) {
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
    if (source != PracticeInputSource.midi) {
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
    if (source != PracticeInputSource.microphone) {
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
    final now = _clock.value;
    setState(() {
      _rings = [
        for (var staff = 0; staff < _clefs.length; staff++)
          for (final m in [0, 1])
            Ring(
              measure: m,
              staff: staff,
              lines: const [0, 1, 2, 3, 4],
              amplitude: 0.15,
              decay: 0.9,
              frequency: 6,
              start: now,
              glow: 0.8,
            ),
      ];
    });
    await ref.read(settingsProvider.notifier).setVerifiedInput(key);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _check = null);
    await _controller.start();
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
        setState(() => _rings = []);
        _controller.replay();
      case StageEngineStatus.idle || StageEngineStatus.stopped:
        _start();
    }
  }

  void _cycleSpeed(double speed) {
    final i = _speeds.indexWhere((s) => (s - speed).abs() < 0.01);
    _controller.setSpeed(_speeds[(i + 1) % _speeds.length]);
  }

  /// On the results, tapping a bar plays it over and over.
  void _tapBar(StageUiState ui, StaffLayout layout, Offset at) {
    if (ui.status != StageEngineStatus.completed) return;
    final beat = layout.xBeat(at.dx, ui.currentBeat);
    for (final m in ui.level.measures) {
      if (beat >= m.startBeat && beat < m.startBeat + m.beatsPerMeasure) {
        setState(() => _rings = []);
        _controller.loopBar(m.index);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.stageId;
    ref.listen(
      stageControllerProvider(id).select((s) => s.noteStates),
      _onNoteStates,
    );
    ref.listen(stageControllerProvider(id).select((s) => s.status), (_, s) {
      if (s == StageEngineStatus.completed) _onFinished();
    });
    if (_listening) ref.watch(practiceAudioSessionProvider);
    final ui = ref.watch(stageControllerProvider(id));
    final geometry = ref.watch(strungGeometryProvider).value;
    final metronome = ref.watch(metronomeGeometryProvider).value;
    final animation =
        ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation;
    if (geometry == null) return const ColoredBox(color: Palette.lacquer);
    return Material(
      color: Palette.lacquer,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) => _scene(
            context,
            constraints.biggest,
            Curves.easeInOutCubic.transform(animation.value),
            ui,
            geometry,
            metronome,
          ),
        ),
      ),
    );
  }

  Widget _scene(
    BuildContext context,
    Size box,
    double t,
    StageUiState ui,
    StrungGeometry geometry,
    MetronomeGeometry? metronome,
  ) {
    final home = CoverFit(geometry.imageSize, box);
    final settled = CoverFit.bottomRow(geometry.imageSize, box, rowY: _keysCut);
    final fit = CoverFit.lerp(home, settled, t);
    final u = (box.height / 720).clamp(0.7, 1.25);
    final staffArea = Rect.fromLTWH(0, 0, box.width, settled.y(_boardTop));
    final layout = StaffLayout.fit(
      staffArea,
      leftInset: MediaQuery.paddingOf(context).left,
      staves: _clefs.length,
    );
    final note = geometry.notes[widget.midi];
    final stringX = home.x(note == null ? 0.5 : _mean(note.strings));
    final introString = (
      Offset(stringX, 0),
      Offset(stringX, home.y(note?.damper?.top ?? 0.41)),
    );
    final late = ((t - 0.6) / 0.4).clamp(0.0, 1.0);
    final board = ((t - 0.3) / 0.7).clamp(0.0, 1.0);
    final finished = ui.status == StageEngineStatus.completed;
    final checking = _check != null;
    final slip = switch (true) {
      _ when checking => (
        _heard ? 'Heard it' : 'Play middle C',
        _heard
            ? 'Starting the piece'
            : _check!.message(
                midi:
                    ref.read(settingsProvider).inputSource ==
                    PracticeInputSource.midi,
              ),
      ),
      _ when _cantHear => (
        "The piano can't hear you yet",
        'Allow the microphone, or plug in a digital piano',
      ),
      _ when finished => (
        '${(ui.accuracy * 100).round()}% of the notes',
        'Tap a still bar to play it on repeat',
      ),
      _ => null,
    };
    final metroHeight = (staffArea.height * 0.34).clamp(80.0, 230.0);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Wood behind everything, so the piano can slide without a gap.
        const _Soundboard(),
        Positioned.fromRect(
          rect: fit.origin & fit.drawn,
          child: Image.asset(
            homeBackdropAsset,
            fit: BoxFit.fill,
            excludeFromSemantics: true,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: fit.y(_boardTop),
          child: Opacity(opacity: board, child: const _Soundboard()),
        ),
        Positioned.fromRect(
          rect: staffArea,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: (d) => _tapBar(ui, layout, d.localPosition),
            child: CustomPaint(
              painter: StrungStaffPainter(
                level: ui.level,
                clefs: _clefs,
                engraved: _engraved,
                noteStates: ui.noteStates,
                currentBeat: ui.currentBeat,
                layout: layout,
                rings: _rings,
                clock: _clock,
                intro: t,
                introString: introString,
                reducedMotion: MediaQuery.disableAnimationsOf(context),
                loopMeasure: ui.loopMeasure,
              ),
            ),
          ),
        ),
        if (late > 0) ..._keyCues(fit, box, ui, geometry, late),
        if (late > 0 && metronome != null)
          Positioned(
            right: math.max(24 * u, MediaQuery.paddingOf(context).right + 16),
            top: staffArea.bottom - metroHeight + metroHeight * 0.03,
            child: Opacity(
              opacity: late,
              child: Metronome(
                geometry: metronome,
                height: metroHeight,
                speed: ui.speed,
                beat: ui.currentBeat,
                swinging: ui.status == StageEngineStatus.playing,
                onSpeed: _controller.setSpeed,
              ),
            ),
          ),
        if (late > 0)
          _BoardControls(
            fit: fit,
            geometry: geometry,
            u: u,
            opacity: late,
            controls: [
              ('Back', () => Navigator.of(context).maybePop()),
              if (checking && !_heard)
                ('Skip the check', _skipCheck)
              else if (!checking)
                (
                  switch (ui.status) {
                    StageEngineStatus.playing => 'Pause',
                    StageEngineStatus.paused => 'Resume',
                    StageEngineStatus.completed => 'Again',
                    _ => 'Start',
                  },
                  () => _transport(ui),
                ),
              if (ui.loopMeasure != null)
                (
                  'Whole piece',
                  () {
                    setState(() => _rings = []);
                    _controller.stopLoop();
                  },
                ),
              (
                'Speed ${(ui.speed * 100).round()}%',
                () => _cycleSpeed(ui.speed),
              ),
            ],
          ),
        if (late > 0 && slip != null)
          _CentredSlip(area: staffArea, u: u, title: slip.$1, status: slip.$2),
      ],
    );
  }

  static double _mean(List<double> xs) =>
      xs.reduce((a, b) => a + b) / xs.length;

  /// The key to play next circled in pencil (middle C during the check),
  /// and the keys being heard lit.
  List<Widget> _keyCues(
    CoverFit fit,
    Size box,
    StageUiState ui,
    StrungGeometry geometry,
    double opacity,
  ) {
    final target = _check != null ? 60 : _nextNote(ui);
    final key = target == null ? null : geometry.notes[target]?.key;
    return [
      for (final midi in ui.sounding)
        if (geometry.notes[midi]?.key case final k?)
          Positioned.fromRect(
            rect: _keyFront(fit.rect(k), box.height, _isBlack(midi)),
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Palette.pencilBlue.withValues(alpha: 0.3 * opacity),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      if (key != null && ui.status != StageEngineStatus.completed)
        IgnorePointer(
          child: CustomPaint(
            painter: PencilLoopPainter(
              target: pencilLoopOnKey(fit.rect(key), box.height),
              color: Palette.pencilBlue.withValues(alpha: opacity),
            ),
          ),
        ),
    ];
  }

  static bool _isBlack(int midi) => const {1, 3, 6, 8, 10}.contains(midi % 12);

  /// The part of a key a player sees: a white key below the black keys,
  /// inset from its neighbours; a black key whole.
  static Rect _keyFront(Rect key, double screenBottom, bool black) {
    final bottom = math.min(key.bottom, screenBottom);
    if (black) return Rect.fromLTRB(key.left, key.top, key.right, bottom);
    final top = key.top + (bottom - key.top) * 0.42;
    return Rect.fromLTRB(key.left + 2, top, key.right - 2, bottom);
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

class _Soundboard extends StatelessWidget {
  const _Soundboard();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          soundboardAsset,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
        ),
        // Lamplight falls off toward the top, away from the keys.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xE0100B07), Color(0xA6100B07)],
            ),
          ),
        ),
      ],
    );
  }
}

/// The practice controls in nickel on the name board, left of the mark.
class _BoardControls extends StatelessWidget {
  const _BoardControls({
    required this.fit,
    required this.geometry,
    required this.u,
    required this.opacity,
    required this.controls,
  });

  final CoverFit fit;
  final StrungGeometry geometry;
  final double u;
  final double opacity;
  final List<(String, VoidCallback)> controls;

  @override
  Widget build(BuildContext context) {
    final logo = geometry.logo;
    final y = fit.y(logo == null ? 0.615 : logo.center.dy);
    final size = math.max(17.0, 22 * u);
    return Positioned(
      left: math.max(fit.x(0.03), MediaQuery.paddingOf(context).left + 12 * u),
      top: y - size * 1.25,
      height: size * 2.5,
      child: Opacity(
        opacity: opacity,
        child: Row(
          children: [
            for (final (i, (label, onPressed)) in controls.indexed) ...[
              if (i > 0) SizedBox(width: 4 * u),
              NickelInlay(label: label, size: size, onPressed: onPressed),
            ],
          ],
        ),
      ),
    );
  }
}

class _CentredSlip extends StatelessWidget {
  const _CentredSlip({
    required this.area,
    required this.u,
    required this.title,
    required this.status,
  });

  final Rect area;
  final double u;
  final String title;
  final String status;

  @override
  Widget build(BuildContext context) {
    final width = math.min(area.width - 32, 400 * u);
    final k = width / slipPaperRect.width;
    return Positioned(
      left: area.center.dx - slipImageSize.width * k / 2,
      top: area.top + area.height * 0.06,
      child: IgnorePointer(
        child: PaperSlip(
          width: width,
          u: u,
          title: title,
          status: status,
          button: false,
        ),
      ),
    );
  }
}
