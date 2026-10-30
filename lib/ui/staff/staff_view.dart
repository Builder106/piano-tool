import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

import '../../models/engine_models.dart';
import '../../models/level_models.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'notation.dart';
import 'staff_geometry.dart';
import 'staff_painter.dart';

typedef StaffSystem = ({Clef clef, List<PlacedNote> notes});

/// The tag a piece's score flies under, from the open book on the desk to
/// the practice screen and on to the marked results.
String scoreHeroTag(String stageId) => 'score-$stageId';

/// The staves a level is drawn on. [placed] runs parallel to [notes]. A grand
/// staff puts the second voice on the bass staff when the level has voices,
/// and otherwise everything below middle C.
List<StaffSystem> staffSystemsFor(
  LevelClef clef,
  List<LevelNote> notes,
  List<PlacedNote> placed,
) {
  switch (clef) {
    case LevelClef.treble:
      return [(clef: Clef.treble, notes: placed)];
    case LevelClef.bass:
      return [(clef: Clef.bass, notes: placed)];
    case LevelClef.grand:
      final voiced = notes.any((n) => n.voiceIndex != 0);
      final treble = <PlacedNote>[];
      final bass = <PlacedNote>[];
      for (var i = 0; i < notes.length && i < placed.length; i++) {
        final isBass = voiced
            ? notes[i].voiceIndex == 1
            : notes[i].midiNote < 60;
        (isBass ? bass : treble).add(placed[i]);
      }
      return [
        (clef: Clef.treble, notes: treble),
        (clef: Clef.bass, notes: bass),
      ];
  }
}

/// Draws one system per entry, splitting the available height between them.
/// A grand staff is two systems connected by a vertical barline and brace.
///
/// A note that has just been scored gets its pencil mark drawn in over a
/// moment, and so does the tick over a measure played clean. With reduced
/// motion the marks appear complete.
class StaffView extends StatefulWidget {
  const StaffView({
    super.key,
    required this.systems,
    required this.currentBeat,
    required this.totalBeats,
    required this.beatsPerMeasure,
    required this.pixelsPerBeat,
    this.beatUnit = 4,
    this.maxStaffHeight = kDefaultMaxStaffHeight,
    this.showPlayhead = true,
    this.bracket,
  });

  final List<StaffSystem> systems;
  final double currentBeat;
  final double totalBeats;
  final int beatsPerMeasure;
  final int beatUnit;
  final double pixelsPerBeat;

  /// Ceiling on the height of each drawn staff. The view happily accepts a
  /// tall band; it just spends the extra on air above and below the staff
  /// rather than on a bigger clef.
  final double maxStaffHeight;

  /// False for a still preview of the music.
  final bool showPlayhead;

  /// A pencil loop round a span of beats, on the lowest system.
  final ({double start, double end})? bracket;

  /// The geometry a single system gets in a band of [bandHeight]. Exposed so
  /// a test can assert on the staff that is actually drawn rather than on
  /// the widget box, which is the band and not the staff.
  StaffGeometry geometryFor(double bandHeight) => staffGeometryForBand(
    bandHeight: bandHeight,
    maxStaffHeight: maxStaffHeight,
  );

  @override
  State<StaffView> createState() => _StaffViewState();
}

class _StaffViewState extends State<StaffView>
    with SingleTickerProviderStateMixin {
  static const _markTime = Duration(milliseconds: 260);
  static const _measureTime = Duration(milliseconds: 420);

  late final Ticker _ticker = createTicker(_onTick);

  /// When each fresh mark started, per system, by mark key.
  final List<Map<String, Duration>> _started = [];
  List<Map<String, double>> _progress = [];

  /// Time on the view's own clock. A ticker restarts from zero each time it
  /// starts, so its elapsed time is added to where the clock had reached.
  Duration _now = Duration.zero;
  Duration _base = Duration.zero;

  void _startTicker() {
    if (_ticker.isActive) return;
    _base = _now;
    _ticker.start();
  }

  static const _loopTime = Duration(milliseconds: 700);
  static const _loopDelay = Duration(milliseconds: 600);
  bool _loopStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The loop round a passage is drawn once, after the sheet has settled.
    if (_loopStarted || widget.bracket == null) return;
    _loopStarted = true;
    if (MediaQuery.of(context).disableAnimations) return;
    while (_started.length < widget.systems.length) {
      _started.add({});
    }
    _started.last['bracket'] = _now + _loopDelay;
    _recompute();
    _startTicker();
  }

  Duration _durationOf(String key) => key == 'bracket'
      ? _loopTime
      : key.startsWith('m')
      ? _measureTime
      : _markTime;

  @override
  void didUpdateWidget(StaffView old) {
    super.didUpdateWidget(old);
    if (MediaQuery.of(context).disableAnimations) return;
    for (var i = 0; i < widget.systems.length; i++) {
      if (_started.length <= i) _started.add({});
      final before = i < old.systems.length ? old.systems[i].notes : null;
      if (before == null) continue;
      _startFreshMarks(i, before, widget.systems[i].notes);
    }
  }

  static bool _settled(NoteState s) =>
      s != NoteState.upcoming && s != NoteState.active;

  void _startFreshMarks(
    int system,
    List<PlacedNote> before,
    List<PlacedNote> after,
  ) {
    final was = {for (final n in before) noteKey(n.midi, n.startBeat): n.state};
    final started = _started[system];
    for (final n in after) {
      final key = noteKey(n.midi, n.startBeat);
      final prior = was[key];
      if (prior == null) continue;
      if (_settled(n.state) && !_settled(prior)) {
        started[key] = _now;
      } else if (!_settled(n.state)) {
        started.remove(key);
      }
    }
    final cleanBefore = cleanMeasures(
      before,
      beatsPerMeasure: widget.beatsPerMeasure,
    );
    final cleanAfter = cleanMeasures(
      after,
      beatsPerMeasure: widget.beatsPerMeasure,
    );
    for (final m in cleanAfter.difference(cleanBefore)) {
      started['m$m'] = _now;
    }
    for (final m in cleanBefore.difference(cleanAfter)) {
      started.remove('m$m');
    }
    if (started.isNotEmpty) _startTicker();
    _recompute();
  }

  void _onTick(Duration elapsed) {
    _now = _base + elapsed;
    setState(_recompute);
  }

  /// Progress for every mark still being drawn. A finished mark drops out,
  /// and the painter draws anything not listed complete.
  void _recompute() {
    for (final started in _started) {
      started.removeWhere((key, at) => _now - at >= _durationOf(key));
    }
    _progress = [
      for (final started in _started)
        {
          for (final MapEntry(:key, value: at) in started.entries)
            key: ((_now - at).inMicroseconds / _durationOf(key).inMicroseconds)
                .clamp(0.0, 1.0),
        },
    ];
    if (_started.every((s) => s.isEmpty) && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final systems = widget.systems;
    final staffColumn = Column(
      children: [
        for (final (index, system) in systems.indexed)
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: StaffPainter(
                clef: system.clef,
                notes: system.notes,
                colors: colors,
                currentBeat: widget.currentBeat,
                totalBeats: widget.totalBeats,
                beatsPerMeasure: widget.beatsPerMeasure,
                beatUnit: widget.beatUnit,
                pixelsPerBeat: widget.pixelsPerBeat,
                maxStaffHeight: widget.maxStaffHeight,
                showPlayheadCap: index == 0,
                showPlayhead: widget.showPlayhead,
                markProgress: index < _progress.length
                    ? _progress[index]
                    : const {},
                bracket: index == systems.length - 1 ? widget.bracket : null,
              ),
            ),
          ),
      ],
    );

    if (systems.length >= 2) {
      // No fill of its own: the staff is engraved on whatever sheet holds it.
      return CustomPaint(
        painter: GrandStaffConnectorPainter(
          colors: colors,
          systemCount: systems.length,
          maxStaffHeight: widget.maxStaffHeight,
        ),
        child: staffColumn,
      );
    }

    return staffColumn;
  }
}

/// Paints the vertical barline and grand staff brace when multiple systems
/// are displayed together.
class GrandStaffConnectorPainter extends CustomPainter {
  const GrandStaffConnectorPainter({
    required this.colors,
    required this.systemCount,
    required this.maxStaffHeight,
  });

  final PianoColors colors;
  final int systemCount;
  final double maxStaffHeight;

  @override
  void paint(Canvas canvas, Size size) {
    if (systemCount < 2) return;

    final bandHeight = size.height / systemCount;
    final g0 = staffGeometryForBand(
      bandHeight: bandHeight,
      maxStaffHeight: maxStaffHeight,
    );
    final g1 = staffGeometryForBand(
      bandHeight: bandHeight,
      maxStaffHeight: maxStaffHeight,
    );

    final yTop = g0.topLineY;
    final yBottom = (systemCount - 1) * bandHeight + g1.bottomLineY;
    final totalHeight = yBottom - yTop;

    // 1. Initial system vertical connecting barline
    final linePaint = Paint()
      ..color = colors.staff
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, yTop), Offset(0, yBottom), linePaint);

    // 2. SMuFL Grand staff brace glyph (0xE000 in Bravura)
    final bracePainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(0xE000),
        style: TextStyle(
          fontFamily: 'Bravura',
          fontSize: totalHeight * 0.95,
          color: colors.ink,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final yMid = (yTop + yBottom) / 2;
    bracePainter.paint(
      canvas,
      Offset(-bracePainter.width * 0.35, yMid - bracePainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(GrandStaffConnectorPainter old) =>
      old.colors != colors ||
      old.systemCount != systemCount ||
      old.maxStaffHeight != maxStaffHeight;
}
