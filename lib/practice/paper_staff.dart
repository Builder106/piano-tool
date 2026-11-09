import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../brand/palette.dart';
import '../brand/pencil_loop.dart';
import '../models/engine_models.dart';
import '../models/level_models.dart';
import 'notation.dart';

/// SMuFL code points in Bravura. Kept as numbers: a literal private-use
/// character in source is easy to corrupt without anyone seeing it.
abstract final class _G {
  static const brace = 0xE000;
  static const gClef = 0xE050;
  static const fClef = 0xE062;
  static const timeSig0 = 0xE080;
  static const headWhole = 0xE0A2;
  static const headHalf = 0xE0A3;
  static const headBlack = 0xE0A4;
  static const dot = 0xE1E7;
  static const flag8Up = 0xE240;
  static const flag8Down = 0xE241;
  static const flag16Up = 0xE242;
  static const flag16Down = 0xE243;
  static const flat = 0xE260;
  static const sharp = 0xE262;
  static const restWhole = 0xE4E3;
  static const restHalf = 0xE4E4;
  static const restQuarter = 0xE4E5;
  static const rest8 = 0xE4E6;
  static const rest16 = 0xE4E7;
}

/// Spaces between the bottom line of one staff and the top line of the next.
const _staffGap = 5.0;

/// Where the staves sit and how fast they move, derived from the space they
/// have.
class StaffLayout {
  const StaffLayout({
    required this.space,
    required this.firstBottomLineY,
    required this.staves,
    required this.strikeX,
    required this.clefRight,
    required this.pxPerBeat,
    required this.areaBottom,
  });

  factory StaffLayout.fit(Rect area, {double leftInset = 0, int staves = 1}) {
    final space = (area.height / (staves == 1 ? 15 : 24)).clamp(8.0, 26.0);
    final system = (staves * 4 + (staves - 1) * _staffGap) * space;
    final top = area.top + area.height * 0.5 - system / 2;
    final clefRight = leftInset + 16 + space * (staves > 1 ? 7.6 : 6.4);
    return StaffLayout(
      space: space,
      firstBottomLineY: top + 4 * space,
      staves: staves,
      strikeX: math.max(area.width * 0.3, clefRight + space * 3),
      clefRight: clefRight,
      pxPerBeat: space * 5.2,
      areaBottom: area.bottom,
    );
  }

  /// One staff space: the gap between two lines.
  final double space;
  final double firstBottomLineY;
  final int staves;

  /// Where the hammer strikes: notes are due as they reach this line.
  final double strikeX;

  /// Right edge of the clefs and time signatures, which stay put.
  final double clefRight;
  final double pxPerBeat;

  /// Bottom of the soundboard the staves are strung over.
  final double areaBottom;

  double bottomLine(int staff) =>
      firstBottomLineY + staff * (4 + _staffGap) * space;
  double lineY(int staff, int line) => bottomLine(staff) - line * space;
  double stepY(int staff, int step) => bottomLine(staff) - step * space / 2;
  double get systemTop => lineY(0, 4);
  double get systemBottom => lineY(staves - 1, 0);
  double beatX(double beat, double currentBeat) =>
      strikeX + (beat - currentBeat) * pxPerBeat;
  double xBeat(double x, double currentBeat) =>
      currentBeat + (x - strikeX) / pxPerBeat;
}

/// A chord or single note at one beat on one staff: one stem for all heads.
class _Unit {
  _Unit(this.staff, this.beat, this.x);
  final int staff;
  final double beat;
  final double x;
  final pieces = <Engraved>[];
  final steps = <int>[];
  bool up = true;
  double? stemEnd;

  Written get written => pieces.first.written;
  int? get beam => pieces.first.beam;
}

/// The staves as ink on a page, with the piece written on them. Music scrolls
/// right to left through a blue pencil line, the strike line, where each note
/// is due.
class PaperStaffPainter extends CustomPainter {
  PaperStaffPainter({
    required this.level,
    required this.clefs,
    required this.engraved,
    required this.noteStates,
    required this.currentBeat,
    required this.layout,
    this.loopMeasure,
    this.showStrike = true,
  });

  final LevelModel level;
  final List<Clef> clefs;
  final List<Engraved> engraved;
  final List<NoteState> noteStates;
  final double currentBeat;
  final StaffLayout layout;

  /// The bar playing on repeat, drawn with a blue band.
  final int? loopMeasure;

  /// Whether to draw the strike line; a still preview has none.
  final bool showStrike;

  double get _s => layout.space;

  @override
  void paint(Canvas canvas, Size size) {
    _paintLoopBand(canvas);
    _paintLines(canvas, size);
    _paintBars(canvas, size);
    if (showStrike) _paintStrike(canvas);
    _paintMusic(canvas, size);
    // Music passing the clefs slides under the page at the left edge.
    final zone = Rect.fromLTWH(
      0,
      0,
      layout.clefRight + _s * 1.5,
      layout.areaBottom,
    );
    canvas.drawRect(
      zone,
      Paint()
        ..shader = const LinearGradient(
          colors: [Palette.page, Palette.page, Color(0x00FFFFFF)],
          stops: [0, 0.75, 1],
        ).createShader(zone),
    );
    canvas.save();
    canvas.clipRect(zone);
    _paintLines(canvas, size);
    canvas.restore();
    _paintClefs(canvas);
  }

  (double, double) _measureSpan(int index) {
    final m = level.measures.firstWhere(
      (m) => m.index == index,
      orElse: () => level.measures[index.clamp(0, level.measures.length - 1)],
    );
    return (
      layout.beatX(m.startBeat, currentBeat),
      layout.beatX(m.startBeat + m.beatsPerMeasure, currentBeat),
    );
  }

  void _paintLines(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = Palette.ink.withValues(alpha: 0.85)
      ..strokeWidth = math.max(1.2, _s * 0.07)
      ..strokeCap = StrokeCap.round;
    for (var staff = 0; staff < layout.staves; staff++) {
      for (var line = 0; line < 5; line++) {
        final y = layout.lineY(staff, line);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), ink);
      }
    }
  }

  /// A bar repeated on purpose is shaded blue between its barlines.
  void _paintLoopBand(Canvas canvas) {
    if (loopMeasure == null) return;
    final (x0, x1) = _measureSpan(loopMeasure!);
    canvas.drawRect(
      Rect.fromLTRB(
        x0,
        layout.systemTop - _s * 1.5,
        x1,
        layout.systemBottom + _s * 1.5,
      ),
      Paint()..color = Palette.pencilBlue.withValues(alpha: 0.08),
    );
  }

  void _paintBars(Canvas canvas, Size size) {
    final looped = loopMeasure == null ? null : _measureSpan(loopMeasure!);
    final bars = <double>{
      for (final m in level.measures) m.startBeat,
      for (final m in level.measures) m.startBeat + m.beatsPerMeasure,
    };
    for (final beat in bars) {
      final x = layout.beatX(beat, currentBeat);
      if (x < layout.clefRight || x > size.width + _s) continue;
      final edge =
          looped != null &&
          ((x - looped.$1).abs() < 1 || (x - looped.$2).abs() < 1);
      canvas.drawLine(
        Offset(x, layout.systemTop),
        Offset(x, layout.systemBottom),
        Paint()
          ..color = edge ? Palette.pencilBlue : Palette.ink
          ..strokeWidth = math.max(1.4, _s * (edge ? 0.2 : 0.1)),
      );
    }
  }

  void _paintStrike(Canvas canvas) {
    final x = layout.strikeX;
    canvas.drawLine(
      Offset(x, layout.systemTop - _s * 2.5),
      Offset(x, layout.systemBottom + _s * 2.5),
      Paint()
        ..color = Palette.pencilBlue
        ..strokeWidth = math.max(2.4, _s * 0.18)
        ..strokeCap = StrokeCap.round,
    );
  }

  Color _noteColor(int noteIndex) {
    final state = noteIndex < noteStates.length
        ? noteStates[noteIndex]
        : NoteState.upcoming;
    return switch (state) {
      NoteState.active => Palette.pencilBlue,
      NoteState.missed => Palette.pencilRed,
      NoteState.hitPerfect ||
      NoteState.hitGood ||
      NoteState.hitOkay => Palette.pencilBlue,
      NoteState.upcoming => Palette.ink,
    };
  }

  double _headWidth(NoteValue v) =>
      v == NoteValue.whole ? _s * 1.68 : _s * 1.18;

  void _paintMusic(Canvas canvas, Size size) {
    final s = _s;
    final left = layout.clefRight - s * 2;
    final right = size.width + s * 3;
    final units = <(int, double), _Unit>{};
    final xs = <Engraved, double>{};
    for (final e in engraved) {
      final x = layout.beatX(e.beat, currentBeat);
      xs[e] = x;
      if (e.isRest) {
        if (x > left && x < right) _paintRest(canvas, e, x);
        continue;
      }
      final unit = units.putIfAbsent((
        e.staff,
        e.beat,
      ), () => _Unit(e.staff, e.beat, x));
      unit.pieces.add(e);
      unit.steps.add(staffStep(e.midi!, clefs[e.staff], alter: e.alter));
    }

    // Stem directions: a beamed group agrees, otherwise each unit decides.
    final groups = <int, List<_Unit>>{};
    for (final u in units.values) {
      final b = u.beam;
      if (b != null) groups.putIfAbsent(b, () => []).add(u);
      final mean = u.steps.reduce((a, b) => a + b) / u.steps.length;
      u.up = mean < 4;
    }
    for (final g in groups.values) {
      final all = [for (final u in g) ...u.steps];
      final up = all.reduce((a, b) => a + b) / all.length < 4;
      for (final u in g) {
        u.up = up;
      }
      _placeBeam(g);
    }

    for (final u in units.values) {
      if (u.x < left || u.x > right) continue;
      _paintUnit(canvas, u);
    }
    for (final g in groups.values) {
      if (g.last.x < left || g.first.x > right) continue;
      _paintBeams(canvas, g);
    }

    // Ties, from each tied piece to the next piece of the same note.
    final byNote = <int, List<Engraved>>{};
    for (final e in engraved) {
      if (!e.isRest) byNote.putIfAbsent(e.noteIndex!, () => []).add(e);
    }
    for (final pieces in byNote.values) {
      for (var i = 0; i + 1 < pieces.length; i++) {
        final a = pieces[i];
        final b = pieces[i + 1];
        if (!a.tiedToNext) continue;
        final xa = xs[a]!;
        final xb = xs[b]!;
        if (xb < left || xa > right) continue;
        final unit = units[(a.staff, a.beat)]!;
        final step = staffStep(a.midi!, clefs[a.staff], alter: a.alter);
        _paintTie(
          canvas,
          xa + _headWidth(a.written.value) + s * 0.12,
          xb - s * 0.12,
          layout.stepY(a.staff, step),
          below: unit.up,
          color: _noteColor(a.noteIndex!),
        );
      }
    }
  }

  /// Lays a beam across a group's stems: sloped with the notes but gently,
  /// and kept at least two and a half spaces from every head.
  void _placeBeam(List<_Unit> g) {
    final s = _s;
    g.sort((a, b) => a.x.compareTo(b.x));
    double stemX(_Unit u) =>
        u.up ? u.x + _headWidth(u.written.value) - s * 0.06 : u.x + s * 0.06;
    double natural(_Unit u) {
      final ys = [for (final st in u.steps) layout.stepY(u.staff, st)];
      return u.up
          ? ys.reduce(math.min) - s * 3.5
          : ys.reduce(math.max) + s * 3.5;
    }

    final x0 = stemX(g.first);
    final x1 = stemX(g.last);
    final y0 = natural(g.first);
    final y1 = natural(g.last);
    final slope = x1 == x0 ? 0.0 : ((y1 - y0) / (x1 - x0)).clamp(-0.18, 0.18);
    var shift = 0.0;
    for (final u in g) {
      final ys = [for (final st in u.steps) layout.stepY(u.staff, st)];
      final beamY = y0 + slope * (stemX(u) - x0);
      if (u.up) {
        shift = math.min(shift, (ys.reduce(math.min) - s * 2.5) - beamY);
      } else {
        shift = math.max(shift, (ys.reduce(math.max) + s * 2.5) - beamY);
      }
    }
    for (final u in g) {
      u.stemEnd = y0 + slope * (stemX(u) - x0) + shift;
    }
  }

  void _paintBeams(Canvas canvas, List<_Unit> g) {
    final s = _s;
    final color = _noteColor(g.first.pieces.first.noteIndex!);
    final ink = Paint()..color = color;
    double stemX(_Unit u) =>
        u.up ? u.x + _headWidth(u.written.value) - s * 0.06 : u.x + s * 0.06;
    final t = s * 0.5;
    final dir = g.first.up ? 1.0 : -1.0;
    void beam(_Unit a, _Unit b, double offset) {
      final ax = stemX(a);
      final bx = stemX(b);
      final ay = a.stemEnd! + offset * dir;
      final by = b.stemEnd! + offset * dir;
      canvas.drawPath(
        Path()
          ..moveTo(ax - 0.5, ay)
          ..lineTo(bx + 0.5, by)
          ..lineTo(bx + 0.5, by + t * dir)
          ..lineTo(ax - 0.5, ay + t * dir)
          ..close(),
        ink,
      );
    }

    beam(g.first, g.last, 0);
    for (var i = 0; i + 1 < g.length; i++) {
      if (g[i].written.value == NoteValue.sixteenth &&
          g[i + 1].written.value == NoteValue.sixteenth) {
        beam(g[i], g[i + 1], s * 0.75);
      }
    }
  }

  void _paintUnit(Canvas canvas, _Unit u) {
    final s = _s;
    final written = u.written;
    final headW = _headWidth(written.value);
    final head = switch (written.value) {
      NoteValue.whole => _G.headWhole,
      NoteValue.half => _G.headHalf,
      _ => _G.headBlack,
    };
    final ys = <double>[];
    for (final (k, piece) in u.pieces.indexed) {
      final step = u.steps[k];
      final y = layout.stepY(u.staff, step);
      ys.add(y);
      final color = _noteColor(piece.noteIndex!);
      for (final l in ledgerSteps(step)) {
        canvas.drawLine(
          Offset(u.x - s * 0.4, layout.stepY(u.staff, l)),
          Offset(u.x + headW + s * 0.4, layout.stepY(u.staff, l)),
          Paint()
            ..color = Palette.ink.withValues(alpha: 0.85)
            ..strokeWidth = math.max(1, s * 0.11),
        );
      }
      if (!piece.tiedFromPrevious) {
        switch (accidentalFor(piece.midi!, alter: piece.alter)) {
          case Accidental.sharp:
            _glyph(canvas, _G.sharp, Offset(u.x - s * 1.25, y), color);
          case Accidental.flat:
            _glyph(canvas, _G.flat, Offset(u.x - s * 1.15, y), color);
          case Accidental.none:
            break;
        }
      }
      _glyph(canvas, head, Offset(u.x, y), color);
      if (piece.noteIndex! < noteStates.length &&
          noteStates[piece.noteIndex!] == NoteState.active) {
        _loop(
          canvas,
          Offset(u.x + headW / 2, y),
          s * 1.25,
          s * 1.0,
          Palette.pencilBlue,
        );
      }
      if (written.dotted) {
        _glyph(
          canvas,
          _G.dot,
          Offset(u.x + headW + s * 0.3, y - (step.isEven ? s / 2 : 0)),
          color,
        );
      }
      if (!piece.tiedFromPrevious) {
        final state = piece.noteIndex! < noteStates.length
            ? noteStates[piece.noteIndex!]
            : NoteState.upcoming;
        _paintMark(canvas, state, u, k, y, headW);
      }
    }
    if (written.value == NoteValue.whole) return;
    final color = _noteColor(u.pieces.first.noteIndex!);
    final sx = u.up ? u.x + headW - s * 0.06 : u.x + s * 0.06;
    final from = u.up
        ? ys.reduce(math.max) - s * 0.15
        : ys.reduce(math.min) + s * 0.15;
    final end =
        u.stemEnd ??
        (u.up ? ys.reduce(math.min) - s * 3.5 : ys.reduce(math.max) + s * 3.5);
    canvas.drawLine(
      Offset(sx, from),
      Offset(sx, end),
      Paint()
        ..color = color
        ..strokeWidth = math.max(1, s * 0.12),
    );
    if (u.beam == null) {
      final flag = switch ((written.value, u.up)) {
        (NoteValue.eighth, true) => _G.flag8Up,
        (NoteValue.eighth, false) => _G.flag8Down,
        (NoteValue.sixteenth, true) => _G.flag16Up,
        (NoteValue.sixteenth, false) => _G.flag16Down,
        _ => null,
      };
      if (flag != null) _glyph(canvas, flag, Offset(sx - s * 0.06, end), color);
    }
  }

  void _paintTie(
    Canvas canvas,
    double x0,
    double x1,
    double y, {
    required bool below,
    required Color color,
  }) {
    final s = _s;
    final d = below ? 1.0 : -1.0;
    final y0 = y + d * s * 0.55;
    final mid = (x0 + x1) / 2;
    canvas.drawPath(
      Path()
        ..moveTo(x0, y0)
        ..quadraticBezierTo(mid, y0 + d * s * 0.9, x1, y0)
        ..quadraticBezierTo(mid, y0 + d * s * 0.65, x0, y0)
        ..close(),
      Paint()..color = color,
    );
  }

  void _paintRest(Canvas canvas, Engraved e, double x) {
    final s = _s;
    const color = Palette.ink;
    final glyph = switch (e.written.value) {
      NoteValue.whole => _G.restWhole,
      NoteValue.half => _G.restHalf,
      NoteValue.quarter => _G.restQuarter,
      NoteValue.eighth => _G.rest8,
      NoteValue.sixteenth => _G.rest16,
    };
    // A whole rest hangs from the fourth line; the rest sit on the middle.
    final step = e.written.value == NoteValue.whole ? 6 : 4;
    var left = x + s * 0.2;
    if (e.wholeBar) {
      final end = layout.beatX(e.beat + e.beats, currentBeat);
      left = (x + end) / 2 - s * 0.6;
    }
    final y = layout.stepY(e.staff, step);
    _glyph(canvas, glyph, Offset(left, y), color);
    if (e.written.dotted && !e.wholeBar) {
      _glyph(
        canvas,
        _G.dot,
        Offset(left + s * 1.4, layout.stepY(e.staff, 5)),
        color,
      );
    }
  }

  /// Marks in blue pencil under each played note, by shape: a tick for
  /// perfect, a ring for good, a line for okay, a strike through a miss.
  /// Notes of a chord take their marks side by side.
  void _paintMark(
    Canvas canvas,
    NoteState state,
    _Unit u,
    int k,
    double y,
    double w,
  ) {
    final s = _s;
    final pencil = Paint()
      ..color = Palette.pencilBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.6, s * 0.14)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final below = math.max(
      layout.bottomLine(u.staff),
      [for (final st in u.steps) layout.stepY(u.staff, st)].reduce(math.max),
    );
    final markY = below + s * 1.7;
    final cx = u.x + w / 2 + (k - (u.pieces.length - 1) / 2) * s * 1.1;
    switch (state) {
      case NoteState.hitPerfect:
        canvas.drawPath(
          Path()
            ..moveTo(cx - s * 0.45, markY - s * 0.05)
            ..lineTo(cx - s * 0.1, markY + s * 0.3)
            ..lineTo(cx + s * 0.55, markY - s * 0.45),
          pencil,
        );
      case NoteState.hitGood:
        canvas.drawCircle(Offset(cx, markY), s * 0.33, pencil);
      case NoteState.hitOkay:
        canvas.drawLine(
          Offset(cx - s * 0.45, markY),
          Offset(cx + s * 0.45, markY),
          pencil,
        );
      case NoteState.missed:
        _loop(canvas, Offset(u.x + w / 2, y), s * 1.15, s * 0.95, Palette.pencilRed);
      case NoteState.upcoming || NoteState.active:
        break;
    }
  }

  /// A pencil loop round a head, as the brand mark is drawn.
  void _loop(Canvas canvas, Offset centre, double rx, double ry, Color color) {
    PencilLoopPainter(
      target: Rect.fromCenter(center: centre, width: rx * 2, height: ry * 2),
      color: color,
    ).paint(canvas, Size.zero);
  }

  void _paintClefs(Canvas canvas) {
    final s = _s;
    const color = Palette.ink;
    final grand = layout.staves > 1;
    final left =
        layout.clefRight - s * (grand ? 7.6 : 6.4) + (grand ? s * 1.2 : 0);
    if (grand) {
      // The brace joining the hands, stretched to the whole system.
      final height = layout.systemBottom - layout.systemTop;
      canvas.save();
      canvas.translate(left - s * 1.3, layout.systemBottom);
      canvas.scale(1, height / (4 * s));
      _glyph(canvas, _G.brace, Offset.zero, color);
      canvas.restore();
      canvas.drawLine(
        Offset(left - s * 0.1, layout.systemTop),
        Offset(left - s * 0.1, layout.systemBottom),
        Paint()
          ..color = Palette.ink
          ..strokeWidth = math.max(1, s * 0.1),
      );
    }
    for (final (staff, clef) in clefs.indexed) {
      final (glyph, step) = clef == Clef.treble ? (_G.gClef, 2) : (_G.fClef, 6);
      _glyph(
        canvas,
        glyph,
        Offset(left + s * 0.5, layout.stepY(staff, step)),
        color,
      );
      final x = left + s * 3.9;
      _glyph(
        canvas,
        _G.timeSig0 + level.beatsPerMeasure,
        Offset(x, layout.stepY(staff, 6)),
        color,
      );
      _glyph(
        canvas,
        _G.timeSig0 + level.beatUnit,
        Offset(x, layout.stepY(staff, 2)),
        color,
      );
    }
  }

  /// SMuFL glyphs sit on their baseline, and the font's em is four spaces.
  void _glyph(Canvas canvas, int code, Offset baselineLeft, Color color) {
    if (_glyphs.length > 512) _glyphs.clear();
    final tp = _glyphs.putIfAbsent((code, _s, color.toARGB32()), () {
      return TextPainter(
        text: TextSpan(
          text: String.fromCharCode(code),
          style: TextStyle(
            fontFamily: Fonts.music,
            fontSize: _s * 4,
            height: 1,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
    final baseline = tp.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    tp.paint(canvas, baselineLeft - Offset(0, baseline));
  }

  static final _glyphs = <(int, double, int), TextPainter>{};

  @override
  bool shouldRepaint(PaperStaffPainter old) =>
      old.currentBeat != currentBeat ||
      old.noteStates != noteStates ||
      old.loopMeasure != loopMeasure ||
      old.layout.space != layout.space;
}

/// The playable notes of a level, in the order the engine plays them.
List<LevelNote> notesOf(LevelModel level) => [
  for (final m in level.measures)
    for (final n in m.notes)
      if (!n.isRest) n,
]..sort((a, b) => a.startBeat.compareTo(b.startBeat));

/// The piece written out and still: for the home page, and for the marked
/// page after a run. [noteStates] colour and mark each note; with [fitWhole]
/// the whole piece is squeezed to the width, as far as it stays legible.
class StaticStaff extends StatelessWidget {
  const StaticStaff({
    super.key,
    required this.level,
    required this.notes,
    required this.noteStates,
    this.fitWhole = false,
  });

  final LevelModel level;
  final List<LevelNote> notes;
  final List<NoteState> noteStates;
  final bool fitWhole;

  @override
  Widget build(BuildContext context) {
    final clefs = stavesFor(level);
    final engraved = engrave(level, notes);
    return LayoutBuilder(
      builder: (context, box) {
        final base = StaffLayout.fit(
          Offset.zero & box.biggest,
          staves: clefs.length,
        );
        var pxPerBeat = base.pxPerBeat;
        if (fitWhole) {
          final beats = level.totalMeasures * level.beatsPerMeasure;
          final room = box.maxWidth - base.clefRight - base.space * 3;
          if (beats > 0) pxPerBeat = math.min(pxPerBeat, room / beats);
        }
        final layout = StaffLayout(
          space: base.space,
          firstBottomLineY: base.firstBottomLineY,
          staves: base.staves,
          strikeX: base.strikeX,
          clefRight: base.clefRight,
          pxPerBeat: pxPerBeat,
          areaBottom: base.areaBottom,
        );
        // Beat zero sits a little right of the clef.
        final firstBeatX = layout.clefRight + layout.space * 2.5;
        return CustomPaint(
          size: box.biggest,
          painter: PaperStaffPainter(
            level: level,
            clefs: clefs,
            engraved: engraved,
            noteStates: noteStates,
            currentBeat: (layout.strikeX - firstBeatX) / pxPerBeat,
            layout: layout,
            showStrike: false,
          ),
        );
      },
    );
  }
}
