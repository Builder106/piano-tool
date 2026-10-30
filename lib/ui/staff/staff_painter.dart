import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals, mapEquals;
import 'package:flutter/rendering.dart';
import '../../models/engine_models.dart';
import '../theme/tokens.dart';
import 'note_glyph.dart';
import 'notation.dart';
import 'staff_geometry.dart';

/// A note positioned in beats, resolved to a MIDI number.
///
/// [durationBeats] decides the written value; [alter] is an authored
/// spelling (-1 flat, 0 natural, 1 sharp) and null means black keys are
/// written as sharps.
typedef PlacedNote = ({
  int midi,
  double startBeat,
  double durationBeats,
  int? alter,
  NoteState state,
});

/// Measures whose notes are all played and all hit. A measure still being
/// played is not finished, whatever came before in it.
Set<int> cleanMeasures(List<PlacedNote> notes, {required int beatsPerMeasure}) {
  const hits = {NoteState.hitPerfect, NoteState.hitGood, NoteState.hitOkay};
  bool open(NoteState s) => s == NoteState.upcoming || s == NoteState.active;
  final resolved = resolvedMeasures([
    for (final n in notes)
      if (!open(n.state)) (startBeat: n.startBeat, hit: hits.contains(n.state)),
  ], beatsPerMeasure: beatsPerMeasure);
  return resolved.difference({
    for (final n in notes)
      if (open(n.state)) (n.startBeat / beatsPerMeasure + 1e-6).floor(),
  });
}

class StaffPainter extends CustomPainter {
  StaffPainter({
    required this.clef,
    required this.notes,
    required this.colors,
    required this.currentBeat,
    required this.totalBeats,
    required this.beatsPerMeasure,
    required this.pixelsPerBeat,
    this.beatUnit = 4,
    this.maxStaffHeight = kDefaultMaxStaffHeight,
    this.showPlayheadCap = true,
    this.showPlayhead = true,
    this.markProgress = const {},
    this.bracket,
  });

  final Clef clef;
  final List<PlacedNote> notes;
  final PianoColors colors;
  final double currentBeat;
  final double totalBeats;
  final int beatsPerMeasure;
  final int beatUnit;
  final double pixelsPerBeat;

  /// Ceiling on the drawn staff height, whatever band the painter is given.
  final double maxStaffHeight;

  /// Horizontal room the clef and time signature occupy, in staff-spaces.
  /// Notes begin after this, so the header can never overlap the music at
  /// any staff size. Staying in staff-spaces (rather than a fixed pixel or
  /// beat offset) keeps this in the same unit as the header glyphs
  /// themselves, so the two can never drift apart at different scales.
  static const double _headerSpaces = 8.5;

  static double _headerWidth(StaffGeometry g) => g.space * _headerSpaces;

  /// Whether to draw the round cap at the top of the playhead line. In a
  /// grand staff each system draws its own playhead line, so only the first
  /// system should draw the cap to avoid two dots stacking.
  final bool showPlayheadCap;

  /// A preview of the music (the home screen's opening bars) has no playhead.
  final bool showPlayhead;

  /// How far each fresh pencil mark has been drawn, 0 to 1, by [noteKey] for
  /// notes and by `m` plus the measure index for a measure's tick. Missing
  /// means complete.
  final Map<String, double> markProgress;

  /// A pencil loop round a span of beats: the passage to look at.
  final ({double start, double end})? bracket;

  /// The geometry this painter would use in a band of [bandHeight]. The
  /// staff takes the middle of the band, capped so a tall band gives more
  /// air rather than a bigger clef.
  StaffGeometry geometryFor(double bandHeight) => staffGeometryForBand(
    bandHeight: bandHeight,
    maxStaffHeight: maxStaffHeight,
  );

  /// Total width of the music, header included, at a given geometry.
  double contentWidthFor(StaffGeometry g) =>
      _musicOrigin(g) + totalBeats * pixelsPerBeat + g.space * 2;

  /// Space for the first notehead and its ledger line inside the music clip.
  static double _musicOrigin(StaffGeometry g) =>
      _headerWidth(g) + g.space * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometryFor(size.height);

    final linePaint = Paint()
      ..color = colors.staff
      ..strokeWidth = 1.0;

    for (var i = 0; i < 5; i++) {
      final y = g.lineY(i);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // The music scrolls under a playhead pinned a third across the viewport,
    // while the clef and time signature stay put at the left edge: they are
    // the header, not part of the music. Clipping to the right of the header
    // keeps scrolled notes from sliding out over it.
    //
    // Everything below is measured from the right edge of the header rather
    // than from the left edge of the widget, because that is the strip the
    // music actually gets. Anchoring in widget coordinates instead would put
    // the anchor behind the clef on a narrow screen and scroll the opening
    // notes out of sight before the piece had started.
    final header = _headerWidth(g);
    final offset = staffScrollOffset(
      playheadX: _xForBeat(currentBeat, g) - header,
      viewportWidth: size.width - header,
      contentWidth: contentWidthFor(g) - header,
    );

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(header, 0, size.width, size.height));
    canvas.translate(-offset, 0);

    final barPaint = Paint()
      ..color = colors.staff.withValues(alpha: 0.55)
      ..strokeWidth = 1.0;
    for (
      var beat = beatsPerMeasure;
      beat <= totalBeats;
      beat += beatsPerMeasure
    ) {
      final x = _xForBeat(beat.toDouble(), g);
      canvas.drawLine(
        Offset(x, g.topLineY),
        Offset(x, g.bottomLineY),
        barPaint,
      );
    }

    _paintRests(canvas, g);
    _paintNotes(canvas, g, linePaint);
    _paintMeasureTicks(canvas, g);
    _paintBracket(canvas, g);

    if (showPlayhead) {
      final playheadX = _xForBeat(currentBeat, g);
      final playheadPaint = Paint()
        ..color = colors.accent
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(playheadX, 0),
        Offset(playheadX, size.height),
        playheadPaint,
      );
      if (showPlayheadCap) {
        canvas.drawCircle(
          Offset(playheadX, 0),
          3.5,
          Paint()..color = colors.accent,
        );
      }
    }

    canvas.restore();

    _paintGlyph(
      canvas,
      _clefCodepoint(clef),
      g.clefFontSize(clef),
      Offset(g.space * 0.5, g.clefCenterY(clef)),
      colors.ink,
    );

    _paintTimeSignature(canvas, g);
  }

  static const double _eps = 1e-6;

  void _paintRests(Canvas canvas, StaffGeometry g) {
    final rests = restsFor(
      notes: [
        for (final n in notes)
          (startBeat: n.startBeat, durationBeats: n.durationBeats),
      ],
      beatsPerMeasure: beatsPerMeasure,
      beatUnit: beatUnit,
      totalBeats: totalBeats,
    );
    for (final rest in rests) {
      final x = rest.wholeMeasure
          ? _xForBeat(rest.startBeat + beatsPerMeasure / 2, g)
          : _xForBeat(rest.startBeat, g);
      // A whole rest hangs from the fourth line; the rest sit on the middle.
      final baseline = rest.value == NoteValue.whole ? g.lineY(1) : g.lineY(2);
      _paintGlyph(
        canvas,
        _restCodepoint(rest.value),
        g.space * 4,
        Offset(x, baseline),
        colors.ink2,
        alignX: 0.5,
      );
    }
  }

  static int _restCodepoint(NoteValue value) => switch (value) {
    NoteValue.whole => 0xE4E3,
    NoteValue.half => 0xE4E4,
    NoteValue.quarter => 0xE4E5,
    NoteValue.eighth => 0xE4E6,
    NoteValue.sixteenth => 0xE4E7,
  };

  /// The value written for [n]. A note that rings past the barline is
  /// written up to the barline; ties are not engraved yet.
  WrittenDuration _durationOf(PlacedNote n) {
    final measureEnd =
        ((n.startBeat / beatsPerMeasure + _eps).floor() + 1) * beatsPerMeasure;
    return writtenDuration(
      math.min(n.durationBeats, measureEnd - n.startBeat),
      beatUnit,
    );
  }

  void _paintNotes(Canvas canvas, StaffGeometry g, Paint linePaint) {
    if (notes.isEmpty) return;
    final order = List<int>.generate(notes.length, (i) => i)
      ..sort((a, b) => notes[a].startBeat.compareTo(notes[b].startBeat));

    // Notes struck together share one stem.
    final events = <List<int>>[];
    for (final i in order) {
      if (events.isNotEmpty &&
          (notes[events.last.first].startBeat - notes[i].startBeat).abs() <
              _eps) {
        events.last.add(i);
      } else {
        events.add([i]);
      }
    }

    final durations = [for (final n in notes) _durationOf(n)];
    final alters = [for (final n in notes) writtenAlter(n.midi, n.alter)];
    final ys = [
      for (var i = 0; i < notes.length; i++)
        g.yForMidi(notes[i].midi, clef, alter: alters[i]),
    ];
    final accidentals = accidentalsFor([
      for (final n in notes)
        (startBeat: n.startBeat, midi: n.midi, alter: n.alter),
    ], beatsPerMeasure: beatsPerMeasure);

    // A chord's stem carries its shortest value.
    final eventDurations = [
      for (final e in events)
        e
            .map((i) => durations[i])
            .reduce(
              (a, b) => beatsFor(a, beatUnit) <= beatsFor(b, beatUnit) ? a : b,
            ),
    ];
    final groups = beamGroups(
      [
        for (var k = 0; k < events.length; k++)
          (
            startBeat: notes[events[k].first].startBeat,
            duration: eventDurations[k],
          ),
      ],
      beatsPerMeasure: beatsPerMeasure,
      beatUnit: beatUnit,
    );
    final groupOf = <int, int>{
      for (var gi = 0; gi < groups.length; gi++)
        for (final k in groups[gi]) k: gi,
    };

    // Notes above the middle line hang their stems down. A beamed group
    // decides together, so its stems all point the same way.
    bool stemsDown(Iterable<int> heads) {
      final top = heads.map((i) => ys[i]).reduce(math.min);
      final bottom = heads.map((i) => ys[i]).reduce(math.max);
      return (top + bottom) / 2 <= g.lineY(2);
    }

    final eventDown = <bool>[
      for (var k = 0; k < events.length; k++)
        groupOf.containsKey(k)
            ? stemsDown(groups[groupOf[k]!].expand((e) => events[e]))
            : stemsDown(events[k]),
    ];
    final beamY = <int, double>{
      for (var gi = 0; gi < groups.length; gi++)
        gi: () {
          final heads = groups[gi].expand((e) => events[e]).map((i) => ys[i]);
          return eventDown[groups[gi].first]
              ? heads.reduce(math.max) + g.stemLength
              : heads.reduce(math.min) - g.stemLength;
        }(),
    };

    final stemStroke = g.space * 0.12;
    final stemPaint = Paint()
      ..color = colors.ink
      ..strokeWidth = stemStroke;
    final stemXs = List<double>.filled(events.length, 0);

    for (var k = 0; k < events.length; k++) {
      final heads = events[k];
      final x = _xForBeat(notes[heads.first].startBeat, g);
      final down = eventDown[k];
      final value = eventDurations[k].value;

      for (final i in heads) {
        for (final ledgerY in g.ledgerLinesFor(
          notes[i].midi,
          clef,
          alter: alters[i],
        )) {
          canvas.drawLine(
            Offset(x - g.space, ledgerY),
            Offset(x + g.space, ledgerY),
            linePaint,
          );
        }
        final style = NoteGlyphStyle.forState(notes[i].state, colors);
        if (style.halo) {
          canvas.drawCircle(
            Offset(x, ys[i]),
            NoteGlyph.headWidth(g, durations[i].value) * 0.78,
            Paint()..color = style.color.withValues(alpha: 0.2),
          );
        }
        final accidental = accidentals[i];
        if (accidental != null) {
          _paintGlyph(
            canvas,
            _accidentalCodepoint(accidental),
            g.space * 4,
            Offset(
              x -
                  NoteGlyph.headWidth(g, durations[i].value) / 2 -
                  g.space * 0.3,
              ys[i],
            ),
            style.color,
            alignX: 1,
          );
        }
        NoteGlyph.paintHead(
          canvas,
          Offset(x, ys[i]),
          g,
          durations[i],
          style.color,
          onLine: g.isOnLine(notes[i].midi, clef, alter: alters[i]),
        );
      }

      if (value.hasStem) {
        final headHalf = NoteGlyph.headWidth(g, value) / 2;
        final stemX = down
            ? x - headHalf + stemStroke / 2
            : x + headHalf - stemStroke / 2;
        stemXs[k] = stemX;
        final headYs = heads.map((i) => ys[i]);
        final from = down ? headYs.reduce(math.min) : headYs.reduce(math.max);
        final group = groupOf[k];
        final to =
            beamY[group] ??
            (down
                ? headYs.reduce(math.max) + g.stemLength
                : headYs.reduce(math.min) - g.stemLength);
        canvas.drawLine(Offset(stemX, from), Offset(stemX, to), stemPaint);

        if (group == null && value.flags > 0) {
          _paintGlyph(
            canvas,
            0xE240 + (value.flags - 1) * 2 + (down ? 1 : 0),
            g.space * 4,
            Offset(stemX - stemStroke / 2, to),
            colors.ink,
          );
        }
      }

      for (final i in heads) {
        NoteGlyph.paintMarks(
          canvas,
          Offset(x, ys[i]),
          g,
          durations[i].value,
          NoteGlyphStyle.forState(notes[i].state, colors),
          markBelow: !down,
          progress:
              markProgress[noteKey(notes[i].midi, notes[i].startBeat)] ?? 1,
        );
      }
    }

    final beamPaint = Paint()..color = colors.ink;
    final thickness = g.space * 0.5;
    for (var gi = 0; gi < groups.length; gi++) {
      final group = groups[gi];
      final down = eventDown[group.first];
      final y = beamY[gi]!;
      // The beam sits inside the stems' reach, toward the heads.
      final top = down ? y - thickness : y;
      canvas.drawRect(
        Rect.fromLTRB(
          stemXs[group.first] - stemStroke / 2,
          top,
          stemXs[group.last] + stemStroke / 2,
          top + thickness,
        ),
        beamPaint,
      );
      // A second beam joins neighbouring sixteenths.
      final step = (down ? -1 : 1) * thickness * 1.6;
      for (var j = 0; j + 1 < group.length; j++) {
        if (eventDurations[group[j]].value.flags < 2 ||
            eventDurations[group[j + 1]].value.flags < 2) {
          continue;
        }
        canvas.drawRect(
          Rect.fromLTRB(
            stemXs[group[j]] - stemStroke / 2,
            top + step,
            stemXs[group[j + 1]] + stemStroke / 2,
            top + step + thickness,
          ),
          beamPaint,
        );
      }
    }
  }

  /// A small pencil tick over the barline of every measure played clean.
  void _paintMeasureTicks(Canvas canvas, StaffGeometry g) {
    final clean = cleanMeasures(notes, beatsPerMeasure: beatsPerMeasure);
    final s = g.space;
    final pencil = Paint()
      ..color = colors.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final m in clean) {
      final x = _xForBeat(((m + 1) * beatsPerMeasure).toDouble(), g) - s * 1.1;
      final y = g.topLineY - s * 1.4;
      NoteGlyph.drawPartial(
        canvas,
        Path()
          ..moveTo(x - s * 0.5, y)
          ..lineTo(x - s * 0.1, y + s * 0.45)
          ..lineTo(x + s * 0.65, y - s * 0.55),
        pencil,
        markProgress['m$m'] ?? 1,
      );
    }
  }

  /// The teacher's loop round the passage to look at again: drawn round the
  /// bars themselves, so it never collides with a mark above or below a note.
  void _paintBracket(Canvas canvas, StaffGeometry g) {
    final span = bracket;
    if (span == null) return;
    final s = g.space;
    final loop = RRect.fromLTRBR(
      _xForBeat(span.start, g) - s * 1.6,
      g.topLineY - s * 1.8,
      _xForBeat(span.end, g) - s * 0.6,
      g.bottomLineY + s * 1.8,
      Radius.circular(s * 1.6),
    );
    NoteGlyph.drawPartial(
      canvas,
      Path()..addRRect(loop),
      Paint()
        ..color = colors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.2
        ..strokeCap = StrokeCap.round,
      markProgress['bracket'] ?? 1,
    );
  }

  static int _accidentalCodepoint(int alter) => switch (alter) {
    < 0 => 0xE260,
    0 => 0xE261,
    _ => 0xE262,
  };

  double _xForBeat(double beat, StaffGeometry g) =>
      _musicOrigin(g) + beat * pixelsPerBeat;

  /// The pixel x where notes may begin, at a given staff geometry. Notes
  /// must never start before this. Public (and static, since it needs no
  /// painter instance) so a scrolling container can account for the header
  /// when sizing and hit-testing; there is one definition of the header
  /// width, shared by painting, layout, and tests.
  static double headerWidthFor(StaffGeometry g) => _headerWidth(g);

  static int _clefCodepoint(Clef clef) => switch (clef) {
    Clef.treble => 0xE050,
    Clef.bass => 0xE062,
  };

  void _paintGlyph(
    Canvas canvas,
    int codepoint,
    double fontSize,
    Offset anchor,
    Color color, {
    double alignX = 0,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(codepoint),
        style: TextStyle(
          fontFamily: 'Bravura',
          fontSize: fontSize,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    // Bravura's glyph origin sits on its reference staff line, so the anchor
    // is the baseline rather than the visual centre.
    painter.paint(
      canvas,
      Offset(
        anchor.dx - painter.width * alignX,
        anchor.dy -
            painter.computeDistanceToActualBaseline(TextBaseline.alphabetic),
      ),
    );
  }

  void _paintTimeSignature(Canvas canvas, StaffGeometry g) {
    final x = g.space * 5.5;
    final fontSize = g.space * 4;

    _paintTimeSigNumber(canvas, '$beatsPerMeasure', fontSize, x, g.lineY(2));
    _paintTimeSigNumber(canvas, '$beatUnit', fontSize, x, g.lineY(4));
  }

  void _paintTimeSigNumber(
    Canvas canvas,
    String digits,
    double fontSize,
    double centerX,
    double baselineY,
  ) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final code = digits.codeUnitAt(i) - 0x30;
      if (code >= 0 && code <= 9) {
        buffer.writeCharCode(0xE080 + code);
      }
    }
    final painter = TextPainter(
      text: TextSpan(
        text: buffer.toString(),
        style: TextStyle(
          fontFamily: 'Bravura',
          fontSize: fontSize,
          color: colors.ink,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(
        centerX - painter.width / 2,
        baselineY -
            painter.computeDistanceToActualBaseline(TextBaseline.alphabetic),
      ),
    );
  }

  @override
  bool shouldRepaint(StaffPainter old) =>
      old.currentBeat != currentBeat ||
      old.clef != clef ||
      old.colors != colors ||
      old.pixelsPerBeat != pixelsPerBeat ||
      old.showPlayheadCap != showPlayheadCap ||
      old.showPlayhead != showPlayhead ||
      old.maxStaffHeight != maxStaffHeight ||
      old.beatsPerMeasure != beatsPerMeasure ||
      old.beatUnit != beatUnit ||
      old.totalBeats != totalBeats ||
      old.bracket != bracket ||
      !mapEquals(old.markProgress, markProgress) ||
      !listEquals(old.notes, notes);
}
