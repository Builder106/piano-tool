import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/rendering.dart';
import '../../models/engine_models.dart';
import '../theme/tokens.dart';
import 'note_glyph.dart';
import 'staff_geometry.dart';

/// A note positioned in beats, resolved to a MIDI number.
typedef PlacedNote = ({int midi, double startBeat, NoteState state});

class StaffPainter extends CustomPainter {
  StaffPainter({
    required this.clef,
    required this.notes,
    required this.colors,
    required this.currentBeat,
    required this.totalBeats,
    required this.beatsPerMeasure,
    required this.pixelsPerBeat,
    this.maxStaffHeight = kDefaultMaxStaffHeight,
    this.showPlayheadCap = true,
  });

  final Clef clef;
  final List<PlacedNote> notes;
  final PianoColors colors;
  final double currentBeat;
  final double totalBeats;
  final int beatsPerMeasure;
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

  /// The geometry this painter would use in a band of [bandHeight]. The
  /// staff takes the middle of the band, capped so a tall band gives more
  /// air rather than a bigger clef.
  StaffGeometry geometryFor(double bandHeight) => staffGeometryForBand(
      bandHeight: bandHeight, maxStaffHeight: maxStaffHeight);

  /// Total width of the music, header included, at a given geometry.
  double contentWidthFor(StaffGeometry g) =>
      _headerWidth(g) + totalBeats * pixelsPerBeat + g.space * 2;

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
    for (var beat = beatsPerMeasure; beat <= totalBeats; beat += beatsPerMeasure) {
      final x = _xForBeat(beat.toDouble(), g);
      canvas.drawLine(Offset(x, g.topLineY), Offset(x, g.bottomLineY), barPaint);
    }

    for (final note in notes) {
      final x = _xForBeat(note.startBeat, g);
      final y = g.yForMidi(note.midi, clef);

      for (final ledgerY in g.ledgerLinesFor(note.midi, clef)) {
        canvas.drawLine(
          Offset(x - g.space, ledgerY),
          Offset(x + g.space, ledgerY),
          linePaint,
        );
      }

      // Notes above the middle line hang their stems down.
      NoteGlyph.paint(canvas, Offset(x, y), g, note.state, colors,
          stemDown: y < g.lineY(2));
    }

    final playheadX = _xForBeat(currentBeat, g);
    final playheadPaint = Paint()
      ..color = colors.accent
      ..strokeWidth = 1.5;
    canvas.drawLine(
        Offset(playheadX, 0), Offset(playheadX, size.height), playheadPaint);
    if (showPlayheadCap) {
      canvas.drawCircle(Offset(playheadX, 0), 3.5, Paint()..color = colors.accent);
    }

    canvas.restore();

    _paintGlyph(canvas, _clefCodepoint(clef), g.clefFontSize(clef),
        Offset(g.space * 0.5, g.clefCenterY(clef)), colors.ink);

    _paintTimeSignature(canvas, g);
  }

  double _xForBeat(double beat, StaffGeometry g) =>
      _headerWidth(g) + beat * pixelsPerBeat;

  /// The pixel x where notes may begin, at a given staff geometry. Notes
  /// must never start before this. Public (and static, since it needs no
  /// painter instance) so a scrolling container can account for the header
  /// when sizing and hit-testing; there is one definition of the header
  /// width, shared by painting, layout, and tests.
  static double headerWidthFor(StaffGeometry g) => _headerWidth(g);

  static int _clefCodepoint(Clef clef) =>
      switch (clef) { Clef.treble => 0xE050, Clef.bass => 0xE062 };

  void _paintGlyph(
      Canvas canvas, int codepoint, double fontSize, Offset anchor, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(codepoint),
        style: TextStyle(fontFamily: 'Bravura', fontSize: fontSize, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    // Bravura's glyph origin sits on its reference staff line, so the anchor
    // is the baseline rather than the visual centre.
    painter.paint(canvas, Offset(anchor.dx, anchor.dy - painter.computeDistanceToActualBaseline(TextBaseline.alphabetic)));
  }

  void _paintTimeSignature(Canvas canvas, StaffGeometry g) {
    final x = g.space * 5.5;
    final style = TextStyle(
      fontFamily: 'CormorantGaramond',
      fontWeight: FontWeight.w700,
      fontSize: g.timeSignatureFontSize,
      height: 0.88,
      color: colors.ink,
    );
    // The numerator fills the upper half of the staff, the denominator the
    // lower half; each glyph is centred, both horizontally and vertically,
    // on its half's midline.
    for (final (i, digit) in ['$beatsPerMeasure', '4'].indexed) {
      final painter = TextPainter(
        text: TextSpan(text: digit, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final centerY = g.lineY(i == 0 ? 1 : 3);
      painter.paint(
          canvas, Offset(x - painter.width / 2, centerY - painter.height / 2));
    }
  }

  @override
  bool shouldRepaint(StaffPainter old) =>
      old.currentBeat != currentBeat ||
      old.clef != clef ||
      old.colors != colors ||
      old.pixelsPerBeat != pixelsPerBeat ||
      old.showPlayheadCap != showPlayheadCap ||
      old.maxStaffHeight != maxStaffHeight ||
      old.beatsPerMeasure != beatsPerMeasure ||
      old.totalBeats != totalBeats ||
      !listEquals(old.notes, notes);
}
