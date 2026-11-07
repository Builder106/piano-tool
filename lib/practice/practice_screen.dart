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
  bool _listening = false;
  bool _cantHear = false;
  static const _speeds = [1.0, 0.75, 0.5];

  @override
  void initState() {
    super.initState();
    _controller = ref.read(stageControllerProvider(widget.stageId).notifier);
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
    _ticker.dispose();
    _clock.dispose();
    // The controller outlives the route; leave it halted, not playing on.
    _controller.stop(syncEvents: false, notifyState: false);
    super.dispose();
  }

  void _onNoteStates(List<NoteState>? before, List<NoteState> after) {
    final ui = ref.read(stageControllerProvider(widget.stageId));
    final now = _clock.value;
    final added = <Ring>[];
    for (var i = 0; i < after.length; i++) {
      final was = before != null && i < before.length ? before[i] : null;
      if (was == after[i]) continue;
      final note = ui.notes[i];
      final lines = ringingLines(trebleStep(note.midiNote, alter: note.alter));
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
  /// played well; the quiet bars are the ones to practise.
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
            Ring(
              measure: m,
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
    if (settings.inputSource != PracticeInputSource.midi && !_listening) {
      bool granted;
      try {
        granted = await ref.read(audioGrantedProvider.future);
      } on Object {
        granted = false;
      }
      if (!mounted) return;
      setState(() {
        _listening = granted;
        _cantHear =
            !granted && settings.inputSource == PracticeInputSource.microphone;
      });
      if (_cantHear) return;
    }
    await _controller.start();
  }

  void _transport(StageEngineStatus status) {
    switch (status) {
      case StageEngineStatus.playing:
        _controller.pause();
      case StageEngineStatus.paused:
        _controller.resume();
      case StageEngineStatus.completed:
        setState(() => _rings = []);
        _controller.replay();
        _start();
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
  ) {
    final home = CoverFit(geometry.imageSize, box);
    final settled = CoverFit.bottomRow(geometry.imageSize, box, rowY: _keysCut);
    final fit = CoverFit.lerp(home, settled, t);
    final u = (box.height / 720).clamp(0.7, 1.25);
    final staffArea = Rect.fromLTWH(0, 0, box.width, settled.y(_boardTop));
    final layout = StaffLayout.fit(
      staffArea,
      leftInset: MediaQuery.paddingOf(context).left,
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
        // The soundboard the staff is strung over.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: fit.y(_boardTop),
          child: Opacity(opacity: board, child: const _Soundboard()),
        ),
        CustomPaint(
          painter: StrungStaffPainter(
            level: ui.level,
            notes: ui.notes,
            noteStates: ui.noteStates,
            currentBeat: ui.currentBeat,
            layout: layout,
            rings: _rings,
            clock: _clock,
            intro: t,
            introString: introString,
            reducedMotion: MediaQuery.disableAnimationsOf(context),
          ),
        ),
        if (late > 0) ..._keyCues(fit, box, ui, geometry, late),
        if (late > 0)
          _BoardControls(
            fit: fit,
            geometry: geometry,
            u: u,
            opacity: late,
            status: ui.status,
            speed: ui.speed,
            onBack: () => Navigator.of(context).maybePop(),
            onTransport: () => _transport(ui.status),
            onSpeed: () => _cycleSpeed(ui.speed),
          ),
        if (late > 0 && (finished || _cantHear))
          _CentredSlip(
            area: staffArea,
            u: u,
            title: finished
                ? '${(ui.accuracy * 100).round()}% of the notes'
                : "The piano can't hear you yet",
            status: finished
                ? 'The still bars are the ones to practise'
                : 'Allow the microphone, or plug in a digital piano',
          ),
      ],
    );
  }

  static double _mean(List<double> xs) =>
      xs.reduce((a, b) => a + b) / xs.length;

  /// The next note's key circled in pencil, and the keys being played lit.
  List<Widget> _keyCues(
    CoverFit fit,
    Size box,
    StageUiState ui,
    StrungGeometry geometry,
    double opacity,
  ) {
    final next = _nextNote(ui);
    final key = next == null ? null : geometry.notes[next]?.key;
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

/// Back, Start and Speed, in nickel on the name board left of the mark.
class _BoardControls extends StatelessWidget {
  const _BoardControls({
    required this.fit,
    required this.geometry,
    required this.u,
    required this.opacity,
    required this.status,
    required this.speed,
    required this.onBack,
    required this.onTransport,
    required this.onSpeed,
  });

  final CoverFit fit;
  final StrungGeometry geometry;
  final double u;
  final double opacity;
  final StageEngineStatus status;
  final double speed;
  final VoidCallback onBack;
  final VoidCallback onTransport;
  final VoidCallback onSpeed;

  @override
  Widget build(BuildContext context) {
    final logo = geometry.logo;
    final y = fit.y(logo == null ? 0.615 : logo.center.dy);
    final size = math.max(18.0, 23 * u);
    final transport = switch (status) {
      StageEngineStatus.playing => 'Pause',
      StageEngineStatus.paused => 'Resume',
      StageEngineStatus.completed => 'Again',
      _ => 'Start',
    };
    return Positioned(
      left: math.max(fit.x(0.03), MediaQuery.paddingOf(context).left + 12 * u),
      top: y - size * 1.25,
      height: size * 2.5,
      child: Opacity(
        opacity: opacity,
        child: Row(
          children: [
            NickelInlay(label: 'Back', size: size, onPressed: onBack),
            SizedBox(width: 6 * u),
            NickelInlay(label: transport, size: size, onPressed: onTransport),
            SizedBox(width: 6 * u),
            NickelInlay(
              label: 'Speed ${(speed * 100).round()}%',
              size: size,
              onPressed: onSpeed,
            ),
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
    final width = math.min(area.width - 32, 380 * u);
    final k = width / slipPaperRect.width;
    return Positioned(
      left: area.center.dx - slipImageSize.width * k / 2,
      top: area.top + area.height * 0.08,
      child: PaperSlip(
        width: width,
        u: u,
        title: title,
        status: status,
        button: false,
      ),
    );
  }
}
