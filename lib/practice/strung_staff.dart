import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../brand/palette.dart';
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

/// A bar of the staff ringing: some of its strings vibrate between the bar's
/// bridges and die away. Amplitude is in staff spaces.
class Ring {
  const Ring({
    required this.measure,
    required this.staff,
    required this.lines,
    required this.amplitude,
    required this.decay,
    required this.frequency,
    required this.start,
    this.glow = 0,
  });

  final int measure;
  final int staff;
  final List<int> lines;
  final double amplitude;

  /// Seconds for the ring to fall to about a third.
  final double decay;
  final double frequency;
  final Duration start;

  /// How brightly the ringing strings glow, 0 to 1.
  final double glow;

  double envelope(Duration now) {
    final t = (now - start).inMicroseconds / 1e6;
    return t < 0 ? 0 : math.exp(-t / decay);
  }

  double phase(Duration now) => (now - start).inMicroseconds / 1e6;
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

/// The staves as strings across the soundboard, with the piece written on
/// them. While [intro] is below 1 the strings are still swinging down from
/// the single string the piece opened from.
class StrungStaffPainter extends CustomPainter {
  StrungStaffPainter({
    required this.level,
    required this.clefs,
    required this.engraved,
    required this.noteStates,
    required this.currentBeat,
    required this.layout,
    required this.rings,
    required this.clock,
    required this.intro,
    required this.introString,
    required this.reducedMotion,
    this.loopMeasure,
  }) : super(repaint: clock);

  final LevelModel level;
  final List<Clef> clefs;
  final List<Engraved> engraved;
  final List<NoteState> noteStates;
  final double currentBeat;
  final StaffLayout layout;
  final List<Ring> rings;
  final ValueListenable<Duration> clock;
  final double intro;

  /// The piece's string on the home screen, top and bottom: where the
  /// staff lines start from.
  final (Offset, Offset) introString;
  final bool reducedMotion;

  /// The bar playing on repeat, whose bridges glow.
  final int? loopMeasure;

  static const _steel = Color(0xFFC9CDD3);
  static const _glint = Color(0xFFF4F6F8);
  static const _shade = Color(0x66000000);

  double get _s => layout.space;

  @override
  void paint(Canvas canvas, Size size) {
    if (intro < 1) {
      _paintSwing(canvas, size);
      if (intro < 0.7) return;
    }
    final fade = ((intro - 0.7) / 0.3).clamp(0.0, 1.0);
    final now = clock.value;
    _paintBridges(canvas, size, fade);
    _paintStrings(canvas, size, now);
    _paintStrike(canvas, fade);
    _paintMusic(canvas, size, fade);
    // Music passing the clefs slides under the shade at the left edge.
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
          colors: [Color(0xF0120E0B), Color(0xE6120E0B), Color(0x00120E0B)],
          stops: [0, 0.75, 1],
        ).createShader(zone),
    );
    canvas.save();
    canvas.clipRect(zone);
    _paintStrings(canvas, size, now);
    canvas.restore();
    _paintClefs(canvas, fade);
  }

  void _paintSwing(Canvas canvas, Size size) {
    final (top, bottom) = introString;
    final count = 5 * layout.staves;
    var k = 0;
    for (var staff = 0; staff < layout.staves; staff++) {
      for (var line = 0; line < 5; line++, k++) {
        final spread = Offset((k - (count - 1) / 2) * 3.0, 0);
        final y = layout.lineY(staff, line);
        final a = Offset.lerp(top + spread, Offset(0, y), intro)!;
        final b = Offset.lerp(bottom + spread, Offset(size.width, y), intro)!;
        _string(
          canvas,
          Path()
            ..moveTo(a.dx, a.dy)
            ..lineTo(b.dx, b.dy),
          1.0 - intro * 0.4,
        );
      }
    }
  }

  void _string(Canvas canvas, Path path, double glow) {
    canvas.drawPath(
      path.shift(const Offset(2.5, 3)),
      Paint()
        ..color = _shade
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    if (glow > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = Palette.paper.withValues(alpha: 0.5 * glow)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = _steel
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7,
    );
    canvas.drawPath(
      path.shift(const Offset(0, -0.4)),
      Paint()
        ..color = _glint.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
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

  void _paintStrings(Canvas canvas, Size size, Duration now) {
    final live = [
      for (final r in rings)
        if (r.envelope(now) > 0.01) r,
    ];
    for (var staff = 0; staff < layout.staves; staff++) {
      for (var line = 0; line < 5; line++) {
        final y = layout.lineY(staff, line);
        final mine = [
          for (final r in live)
            if (r.staff == staff && r.lines.contains(line)) r,
        ];
        if (mine.isEmpty || reducedMotion) {
          final glow = reducedMotion
              ? mine.fold(0.0, (g, r) => math.max(g, r.glow * r.envelope(now)))
              : 0.0;
          _string(
            canvas,
            Path()
              ..moveTo(0, y)
              ..lineTo(size.width, y),
            glow,
          );
          continue;
        }
        final path = Path()..moveTo(0, y);
        var glow = 0.0;
        const step = 4.0;
        for (var x = step; x <= size.width + step; x += step) {
          var dy = 0.0;
          for (final r in mine) {
            final (x0, x1) = _measureSpan(r.measure);
            if (x <= x0 || x >= x1) continue;
            final u = (x - x0) / (x1 - x0);
            final env = r.envelope(now);
            final t = r.phase(now);
            final a = r.amplitude * _s * env;
            dy +=
                a *
                math.sin(math.pi * u) *
                math.cos(2 * math.pi * r.frequency * t);
            dy +=
                0.35 *
                a *
                math.sin(2 * math.pi * u) *
                math.cos(2 * math.pi * r.frequency * 2.1 * t + 0.6);
            glow = math.max(glow, r.glow * env);
          }
          path.lineTo(x, y + dy);
        }
        _string(canvas, path, glow);
      }
    }
  }

  /// Each barline is a short length of bridge: a strip of maple under the
  /// strings with a pin pressed in beside each one, so a bar is the stretch
  /// of string that rings between two bridges.
  void _paintBridges(Canvas canvas, Size size, double fade) {
    final s = _s;
    final pin = Paint()..color = _steel.withValues(alpha: fade);
    final pinGlint = Paint()..color = _glint.withValues(alpha: 0.8 * fade);
    final maple = Paint()
      ..color = const Color(0xFF5A3A22).withValues(alpha: fade);
    final edge = Paint()
      ..color = const Color(0xFF8A5E3B).withValues(alpha: fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final looped = loopMeasure == null ? null : _measureSpan(loopMeasure!);
    final bars = <double>{
      for (final m in level.measures) m.startBeat,
      for (final m in level.measures) m.startBeat + m.beatsPerMeasure,
    };
    for (final beat in bars) {
      final x = layout.beatX(beat, currentBeat);
      if (x < layout.clefRight || x > size.width + s) continue;
      final strip = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          x - s * 0.22,
          layout.systemTop - s * 0.35,
          x + s * 0.22,
          layout.systemBottom + s * 0.35,
        ),
        Radius.circular(s * 0.12),
      );
      if (looped != null &&
          ((x - looped.$1).abs() < 1 || (x - looped.$2).abs() < 1)) {
        canvas.drawRRect(
          strip.inflate(s * 0.25),
          Paint()
            ..color = Palette.pencilBlueOnDark.withValues(alpha: 0.75 * fade)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
      canvas.drawRRect(
        strip.shift(const Offset(2, 3)),
        Paint()..color = _shade.withValues(alpha: 0.5 * fade),
      );
      canvas.drawRRect(strip, maple);
      canvas.drawRRect(strip, edge);
      for (var staff = 0; staff < layout.staves; staff++) {
        for (var line = 0; line < 5; line++) {
          final c = Offset(x + s * 0.09, layout.lineY(staff, line) - s * 0.08);
          canvas.drawCircle(c, s * 0.09, pin);
          canvas.drawCircle(
            c + Offset(-s * 0.03, -s * 0.03),
            s * 0.035,
            pinGlint,
          );
        }
      }
    }
  }

  void _paintStrike(Canvas canvas, double fade) {
    final x = layout.strikeX;
    canvas.drawLine(
      Offset(x, layout.systemTop - _s * 2.5),
      Offset(x, layout.systemBottom + _s * 2.5),
      Paint()
        ..color = Palette.paper.withValues(alpha: 0.22 * fade)
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  Color _noteColor(int noteIndex, double fade) {
    final state = noteIndex < noteStates.length
        ? noteStates[noteIndex]
        : NoteState.upcoming;
    return switch (state) {
      NoteState.active => Palette.pencilBlueOnDark,
      NoteState.missed => Palette.paper.withValues(alpha: 0.45),
      _ => Palette.paper.withValues(alpha: 0.94),
    }.withValues(alpha: fade);
  }

  double _headWidth(NoteValue v) =>
      v == NoteValue.whole ? _s * 1.68 : _s * 1.18;

  void _paintMusic(Canvas canvas, Size size, double fade) {
    final s = _s;
    final left = layout.clefRight - s * 2;
    final right = size.width + s * 3;
    final units = <(int, double), _Unit>{};
    final xs = <Engraved, double>{};
    for (final e in engraved) {
      final x = layout.beatX(e.beat, currentBeat);
      xs[e] = x;
      if (e.isRest) {
        if (x > left && x < right) _paintRest(canvas, e, x, fade);
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
      _paintUnit(canvas, u, fade);
    }
    for (final g in groups.values) {
      if (g.last.x < left || g.first.x > right) continue;
      _paintBeams(canvas, g, fade);
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
          color: _noteColor(a.noteIndex!, fade),
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

  void _paintBeams(Canvas canvas, List<_Unit> g, double fade) {
    final s = _s;
    final color = _noteColor(g.first.pieces.first.noteIndex!, fade);
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

  void _paintUnit(Canvas canvas, _Unit u, double fade) {
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
      final color = _noteColor(piece.noteIndex!, fade);
      for (final l in ledgerSteps(step)) {
        canvas.drawLine(
          Offset(u.x - s * 0.4, layout.stepY(u.staff, l)),
          Offset(u.x + headW + s * 0.4, layout.stepY(u.staff, l)),
          Paint()
            ..color = _steel.withValues(alpha: 0.85 * fade)
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
        _paintMark(canvas, state, u, k, y, headW, fade);
      }
    }
    if (written.value == NoteValue.whole) return;
    final color = _noteColor(u.pieces.first.noteIndex!, fade);
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

  void _paintRest(Canvas canvas, Engraved e, double x, double fade) {
    final s = _s;
    final color = Palette.paper.withValues(alpha: 0.8 * fade);
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
    double fade,
  ) {
    final s = _s;
    final pencil = Paint()
      ..color = Palette.pencilBlueOnDark.withValues(alpha: fade)
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
        canvas.drawLine(
          Offset(u.x - s * 0.25, y + s * 0.75),
          Offset(u.x + w + s * 0.25, y - s * 0.75),
          pencil..color = Palette.quietOnDark.withValues(alpha: fade),
        );
      case NoteState.upcoming || NoteState.active:
        break;
    }
  }

  void _paintClefs(Canvas canvas, double fade) {
    final s = _s;
    final color = Palette.paper.withValues(alpha: 0.94 * fade);
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
          ..color = _steel.withValues(alpha: 0.8 * fade)
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
  bool shouldRepaint(StrungStaffPainter old) =>
      old.currentBeat != currentBeat ||
      old.noteStates != noteStates ||
      old.intro != intro ||
      old.rings != rings ||
      old.loopMeasure != loopMeasure ||
      old.layout.space != layout.space;
}
