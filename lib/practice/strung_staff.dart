import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../brand/palette.dart';
import '../models/engine_models.dart';
import '../models/level_models.dart';
import 'notation.dart';

/// Where the staff sits and how fast it moves, derived from the space it has.
class StaffLayout {
  const StaffLayout({
    required this.space,
    required this.bottomLineY,
    required this.strikeX,
    required this.clefRight,
    required this.pxPerBeat,
    required this.areaBottom,
  });

  factory StaffLayout.fit(Rect area, {double leftInset = 0}) {
    final space = (area.height / 15).clamp(9.0, 26.0);
    final clefRight = leftInset + 16 + space * 6.4;
    return StaffLayout(
      space: space,
      bottomLineY: area.top + area.height * 0.52 + 2 * space,
      strikeX: math.max(area.width * 0.3, clefRight + space * 3),
      clefRight: clefRight,
      pxPerBeat: space * 5.2,
      areaBottom: area.bottom,
    );
  }

  /// One staff space: the gap between two lines.
  final double space;
  final double bottomLineY;

  /// Where the hammer strikes: notes are due as they reach this line.
  final double strikeX;

  /// Right edge of the clef and time signature, which stay put.
  final double clefRight;
  final double pxPerBeat;

  /// Bottom of the soundboard the staff is strung over.
  final double areaBottom;

  double lineY(int line) => bottomLineY - line * space;
  double stepY(int step) => bottomLineY - step * space / 2;
  double beatX(double beat, double currentBeat) =>
      strikeX + (beat - currentBeat) * pxPerBeat;
}

/// A bar of the staff ringing: its lines vibrate between the bar's bridge
/// pins and die away. Amplitude is in staff spaces.
class Ring {
  const Ring({
    required this.measure,
    required this.lines,
    required this.amplitude,
    required this.decay,
    required this.frequency,
    required this.start,
    this.glow = 0,
  });

  final int measure;
  final List<int> lines;
  final double amplitude;

  /// Seconds for the ring to fall to about a third.
  final double decay;
  final double frequency;
  final Duration start;

  /// How brightly the ringing lines glow, 0 to 1.
  final double glow;

  double envelope(Duration now) {
    final t = (now - start).inMicroseconds / 1e6;
    return t < 0 ? 0 : math.exp(-t / decay);
  }

  double phase(Duration now) => (now - start).inMicroseconds / 1e6;
}

/// The staff as five strings across the soundboard, with the piece's notes
/// riding on them. While [intro] is below 1 the strings are still swinging
/// down from the single string the piece opened from.
class StrungStaffPainter extends CustomPainter {
  StrungStaffPainter({
    required this.level,
    required this.notes,
    required this.noteStates,
    required this.currentBeat,
    required this.layout,
    required this.rings,
    required this.clock,
    required this.intro,
    required this.introString,
    required this.reducedMotion,
  }) : super(repaint: clock);

  final LevelModel level;
  final List<LevelNote> notes;
  final List<NoteState> noteStates;
  final double currentBeat;
  final StaffLayout layout;
  final List<Ring> rings;
  final ValueListenable<Duration> clock;
  final double intro;

  /// The piece's string on the home screen, top and bottom: where the five
  /// lines start from.
  final (Offset, Offset) introString;
  final bool reducedMotion;

  static const _steel = Color(0xFFC9CDD3);
  static const _glint = Color(0xFFF4F6F8);
  static const _shade = Color(0x66000000);

  @override
  void paint(Canvas canvas, Size size) {
    if (intro < 1) {
      _paintSwing(canvas, size);
      if (intro < 0.7) return;
    }
    final fade = ((intro - 0.7) / 0.3).clamp(0.0, 1.0);
    final now = clock.value;
    _paintBridges(canvas, size, fade);
    _paintStrings(canvas, size, now, Rect.largest);
    _paintStrike(canvas, fade);
    _paintNotes(canvas, size, fade);
    // Notes passing the clef slide under the shade at the left edge.
    final zone = Rect.fromLTWH(
      0,
      0,
      layout.clefRight + layout.space * 1.5,
      layout.areaBottom,
    );
    canvas.drawRect(
      zone,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xF0120E0B),
            const Color(0xE6120E0B),
            const Color(0x00120E0B),
          ],
          stops: const [0, 0.75, 1],
        ).createShader(zone),
    );
    canvas.save();
    canvas.clipRect(zone);
    _paintStrings(canvas, size, now, zone);
    canvas.restore();
    _paintClef(canvas, fade);
  }

  void _paintSwing(Canvas canvas, Size size) {
    final (top, bottom) = introString;
    final t = intro;
    for (var i = 0; i < 5; i++) {
      final spread = Offset((i - 2) * 3.0, 0);
      final a = Offset.lerp(top + spread, Offset(0, layout.lineY(i)), t)!;
      final b = Offset.lerp(
        bottom + spread,
        Offset(size.width, layout.lineY(i)),
        t,
      )!;
      _string(
        canvas,
        Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy),
        1.0 - t * 0.4,
      );
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
    final m = level.measures[index];
    return (
      layout.beatX(m.startBeat, currentBeat),
      layout.beatX(m.startBeat + m.beatsPerMeasure, currentBeat),
    );
  }

  void _paintStrings(Canvas canvas, Size size, Duration now, Rect clip) {
    final live = [
      for (final r in rings)
        if (r.envelope(now) > 0.01 && r.measure < level.measures.length) r,
    ];
    for (var line = 0; line < 5; line++) {
      final y = layout.lineY(line);
      final mine = [
        for (final r in live)
          if (r.lines.contains(line)) r,
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
          final a = r.amplitude * layout.space * env;
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

  /// Each barline is a short length of bridge: a strip of maple under the
  /// strings with a pin pressed in beside each one, so a bar is the stretch
  /// of string that rings between two bridges.
  void _paintBridges(Canvas canvas, Size size, double fade) {
    final s = layout.space;
    final pin = Paint()..color = _steel.withValues(alpha: fade);
    final pinGlint = Paint()..color = _glint.withValues(alpha: 0.8 * fade);
    final maple = Paint()
      ..color = const Color(0xFF5A3A22).withValues(alpha: fade);
    final mapleEdge = Paint()
      ..color = const Color(0xFF8A5E3B).withValues(alpha: fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final starts = [for (final m in level.measures) m.startBeat];
    if (level.measures.isNotEmpty) {
      final last = level.measures.last;
      starts.add(last.startBeat + last.beatsPerMeasure);
    }
    for (final beat in starts) {
      final x = layout.beatX(beat, currentBeat);
      if (x < layout.clefRight || x > size.width + s) continue;
      final strip = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          x - s * 0.22,
          layout.lineY(4) - s * 0.35,
          x + s * 0.22,
          layout.lineY(0) + s * 0.35,
        ),
        Radius.circular(s * 0.12),
      );
      canvas.drawRRect(
        strip.shift(const Offset(2, 3)),
        Paint()..color = _shade.withValues(alpha: 0.5 * fade),
      );
      canvas.drawRRect(strip, maple);
      canvas.drawRRect(strip, mapleEdge);
      // A pin pressed in beside each string, on the string's own line.
      for (var line = 0; line < 5; line++) {
        final c = Offset(x + s * 0.09, layout.lineY(line) - s * 0.08);
        canvas.drawCircle(c, s * 0.09, pin);
        canvas.drawCircle(
          c + Offset(-s * 0.03, -s * 0.03),
          s * 0.035,
          pinGlint,
        );
      }
    }
  }

  void _paintStrike(Canvas canvas, double fade) {
    final s = layout.space;
    final x = layout.strikeX;
    canvas.drawLine(
      Offset(x, layout.lineY(4) - s * 2.5),
      Offset(x, layout.lineY(0) + s * 2.5),
      Paint()
        ..color = Palette.paper.withValues(alpha: 0.22 * fade)
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  void _paintNotes(Canvas canvas, Size size, double fade) {
    final s = layout.space;
    for (final (i, note) in notes.indexed) {
      final x = layout.beatX(note.startBeat, currentBeat);
      if (x < layout.clefRight - s * 2 || x > size.width + s * 3) continue;
      final state = i < noteStates.length ? noteStates[i] : NoteState.upcoming;
      final step = trebleStep(note.midiNote, alter: note.alter);
      final y = layout.stepY(step);
      final written = writtenValue(
        note.durationBeats,
        beatUnit: level.beatUnit,
      );
      final color = switch (state) {
        NoteState.active => Palette.pencilBlueOnDark,
        NoteState.missed => Palette.paper.withValues(alpha: 0.45),
        _ => Palette.paper.withValues(alpha: 0.94),
      }.withValues(alpha: fade);
      final head = switch (written.value) {
        NoteValue.whole => '\uE0A2',
        NoteValue.half => '\uE0A3',
        _ => '\uE0A4',
      };
      final headWidth = written.value == NoteValue.whole ? s * 1.68 : s * 1.18;
      final ink = Paint()
        ..color = color
        ..strokeWidth = math.max(1, s * 0.12)
        ..strokeCap = StrokeCap.butt;
      for (final l in ledgerSteps(step)) {
        canvas.drawLine(
          Offset(x - s * 0.4, layout.stepY(l)),
          Offset(x + headWidth + s * 0.4, layout.stepY(l)),
          Paint()
            ..color = _steel.withValues(alpha: 0.85 * fade)
            ..strokeWidth = math.max(1, s * 0.11),
        );
      }
      switch (accidentalFor(note.midiNote, alter: note.alter)) {
        case Accidental.sharp:
          _glyph(canvas, '\uE262', Offset(x - s * 1.25, y), color);
        case Accidental.flat:
          _glyph(canvas, '\uE260', Offset(x - s * 1.15, y), color);
        case Accidental.none:
          break;
      }
      _glyph(canvas, head, Offset(x, y), color);
      if (written.value != NoteValue.whole) {
        final up = stemUp(step);
        final sx = up ? x + headWidth - s * 0.06 : x + s * 0.06;
        final end = up ? y - s * 3.5 : y + s * 3.5;
        canvas.drawLine(
          Offset(sx, y + (up ? -s * 0.15 : s * 0.15)),
          Offset(sx, end),
          ink,
        );
        final flag = switch ((written.value, up)) {
          (NoteValue.eighth, true) => '\uE240',
          (NoteValue.eighth, false) => '\uE241',
          (NoteValue.sixteenth, true) => '\uE242',
          (NoteValue.sixteenth, false) => '\uE243',
          _ => null,
        };
        if (flag != null) {
          _glyph(
            canvas,
            flag,
            Offset(sx - (up ? s * 0.06 : s * 0.06), end),
            color,
          );
        }
      }
      if (written.dotted) {
        _glyph(
          canvas,
          '\uE1E7',
          Offset(x + headWidth + s * 0.3, y - (step.isEven ? s / 2 : 0)),
          color,
        );
      }
      _paintMark(canvas, state, x, y, headWidth, fade);
    }
  }

  /// Marks in blue pencil under each played note, by shape: a tick for
  /// perfect, a ring for good, a line for okay, a strike through a miss.
  void _paintMark(
    Canvas canvas,
    NoteState state,
    double x,
    double y,
    double w,
    double fade,
  ) {
    final s = layout.space;
    final pencil = Paint()
      ..color = Palette.pencilBlueOnDark.withValues(alpha: fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.6, s * 0.14)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final markY = math.max(y, layout.bottomLineY) + s * 1.7;
    final cx = x + w / 2;
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
          Offset(x - s * 0.25, y + s * 0.75),
          Offset(x + w + s * 0.25, y - s * 0.75),
          pencil..color = Palette.quietOnDark.withValues(alpha: fade),
        );
      case NoteState.upcoming || NoteState.active:
        break;
    }
  }

  void _paintClef(Canvas canvas, double fade) {
    final s = layout.space;
    final color = Palette.paper.withValues(alpha: 0.94 * fade);
    final left = layout.clefRight - s * 6.4;
    _glyph(canvas, '\uE050', Offset(left + s * 0.5, layout.stepY(2)), color);
    final top = '\uE080'.codeUnitAt(0);
    String digit(int n) => String.fromCharCode(top + n);
    final x = left + s * 3.9;
    _glyph(
      canvas,
      digit(level.beatsPerMeasure),
      Offset(x, layout.stepY(6)),
      color,
    );
    _glyph(canvas, digit(level.beatUnit), Offset(x, layout.stepY(2)), color);
  }

  /// SMuFL glyphs sit on their baseline, and the font's em is four spaces.
  void _glyph(Canvas canvas, String glyph, Offset baselineLeft, Color color) {
    final tp = _glyphs.putIfAbsent((glyph, layout.space, color.toARGB32()), () {
      return TextPainter(
        text: TextSpan(
          text: glyph,
          style: TextStyle(
            fontFamily: Fonts.music,
            fontSize: layout.space * 4,
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

  static final _glyphs = <(String, double, int), TextPainter>{};

  @override
  bool shouldRepaint(StrungStaffPainter old) =>
      old.currentBeat != currentBeat ||
      old.noteStates != noteStates ||
      old.intro != intro ||
      old.rings != rings ||
      old.layout.space != layout.space;
}
