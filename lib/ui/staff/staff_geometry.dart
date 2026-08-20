import 'dart:math' as math;
import 'dart:ui' show Size;
import 'package:flutter/foundation.dart' show immutable;

/// Which clef a staff is drawn in.
///
/// This is a rendering concept and lives in the UI layer. The level models
/// carry no clef today; `StaffView` takes an explicit list of systems and each
/// one names its clef, so the caller decides what gets drawn.
enum Clef { treble, bass }

/// Staff measurements derived from the staff's own height.
///
/// Every glyph is expressed in staff-spaces rather than as a fraction of the
/// widget, which is what lets a grand staff reuse this untouched: halve the
/// height and everything scales with it.
@immutable
class StaffGeometry {
  const StaffGeometry({required this.top, required this.height});

  /// y of the top staff line.
  final double top;

  /// Distance from the top line to the bottom line.
  final double height;

  /// Four spaces between five lines.
  double get space => height / 4;

  double lineY(int index) => top + index * space;
  double get topLineY => lineY(0);
  double get bottomLineY => lineY(4);

  Size get noteheadSize => Size(space * 1.3, space);
  double get stemLength => space * 3.5;
  double get timeSignatureFontSize => space * 2;

  /// Bravura draws clefs on a staff of 4 spaces at font-size = 4 spaces.
  double clefFontSize(Clef clef) => space * 4;

  /// Bravura anchors gClef to the G line and fClef to the F line.
  double clefCenterY(Clef clef) =>
      switch (clef) { Clef.treble => lineY(3), Clef.bass => lineY(1) };

  /// Diatonic index of the note on the staff's bottom line.
  static const int _trebleBottom = 30; // E4
  static const int _bassBottom = 18;   // G2

  /// Maps a chromatic pitch class to its diatonic degree, so a sharp shares a
  /// staff position with its natural.
  static const List<int> _degree = [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6];

  static int _diatonic(int midi) {
    final octave = (midi ~/ 12) - 1;
    return octave * 7 + _degree[midi % 12];
  }

  int _bottomFor(Clef clef) =>
      switch (clef) { Clef.treble => _trebleBottom, Clef.bass => _bassBottom };

  /// Each diatonic step moves half a space.
  double yForMidi(int midi, Clef clef) =>
      bottomLineY - (_diatonic(midi) - _bottomFor(clef)) * (space / 2);

  /// Ledger lines between the staff and a note that sits outside it.
  List<double> ledgerLinesFor(int midi, Clef clef) {
    final steps = _diatonic(midi) - _bottomFor(clef);
    final lines = <double>[];
    if (steps < 0) {
      for (var s = -2; s >= steps; s -= 2) {
        lines.add(bottomLineY - s * (space / 2));
      }
    } else if (steps > 8) {
      for (var s = 10; s <= steps; s += 2) {
        lines.add(bottomLineY - s * (space / 2));
      }
    }
    return lines;
  }
}

/// Ceiling on the drawn staff height. A five-line staff much taller than
/// this stops reading as notation and starts reading as a diagram: the clef
/// alone would out-measure the keyboard below it.
const double kDefaultMaxStaffHeight = 88;

/// The fraction of a band the staff itself occupies, leaving room above and
/// below for ledger lines.
const double kStaffBandFraction = 0.56;

/// The staff for a band of [bandHeight], never taller than [maxStaffHeight]
/// and always centred in the band it was given.
///
/// One definition, shared by the painter and by anything that needs to know
/// where the staff will land. Because every glyph is sized in staff-spaces,
/// capping the height here shrinks the clef, the time signature, the
/// noteheads and the stems together; there is no second path and no
/// per-glyph exception.
StaffGeometry staffGeometryForBand({
  required double bandHeight,
  required double maxStaffHeight,
}) {
  final height = math.min(bandHeight * kStaffBandFraction, maxStaffHeight);
  return StaffGeometry(top: (bandHeight - height) / 2, height: height);
}

/// Pixels the staff content is shifted left so the playhead stays visible.
///
/// The playhead sits still at [anchorFraction] of the viewport while the music
/// moves under it, which is what a scrolling score does. Clamped at both ends:
/// no scrolling before the anchor is reached, and none past the final beat.
double staffScrollOffset({
  required double playheadX,
  required double viewportWidth,
  required double contentWidth,
  double anchorFraction = 0.3,
}) {
  final maxOffset = contentWidth - viewportWidth;
  if (maxOffset <= 0) return 0;
  final anchor = viewportWidth * anchorFraction;
  return (playheadX - anchor).clamp(0.0, maxOffset);
}
