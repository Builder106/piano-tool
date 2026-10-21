import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'staff_geometry.dart';
import 'staff_painter.dart';

typedef StaffSystem = ({Clef clef, List<PlacedNote> notes});

/// Draws one system per entry, splitting the available height between them.
/// A grand staff is two systems connected by a vertical barline and brace.
class StaffView extends StatelessWidget {
  const StaffView({
    super.key,
    required this.systems,
    required this.currentBeat,
    required this.totalBeats,
    required this.beatsPerMeasure,
    required this.pixelsPerBeat,
    this.beatUnit = 4,
    this.maxStaffHeight = kDefaultMaxStaffHeight,
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

  /// The geometry a single system gets in a band of [bandHeight]. Exposed so
  /// a test can assert on the staff that is actually drawn rather than on
  /// the widget box, which is the band and not the staff.
  StaffGeometry geometryFor(double bandHeight) => staffGeometryForBand(
    bandHeight: bandHeight,
    maxStaffHeight: maxStaffHeight,
  );

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
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
                currentBeat: currentBeat,
                totalBeats: totalBeats,
                beatsPerMeasure: beatsPerMeasure,
                beatUnit: beatUnit,
                pixelsPerBeat: pixelsPerBeat,
                maxStaffHeight: maxStaffHeight,
                showPlayheadCap: index == 0,
              ),
            ),
          ),
      ],
    );

    if (systems.length >= 2) {
      return ColoredBox(
        color: colors.paper,
        child: CustomPaint(
          painter: GrandStaffConnectorPainter(
            colors: colors,
            systemCount: systems.length,
            maxStaffHeight: maxStaffHeight,
          ),
          child: staffColumn,
        ),
      );
    }

    return ColoredBox(color: colors.paper, child: staffColumn);
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
