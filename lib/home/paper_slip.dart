import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../brand/palette.dart';
import 'strung_geometry.dart';

/// The paper slip asset: its pixel size, and where the paper itself sits in
/// it (the rest is the slip's shadow). Measured from `slip.png`.
const slipImageSize = Size(960, 320);
const slipPaperRect = Rect.fromLTRB(33, 37, 927, 284);

/// Lettering on a slip lies flat on the strings, so it is foreshortened like
/// the slip; not fully (cos 40°), which would cost legibility.
const _flatten = 0.86;

/// A paper slip lying on the strings with a title and a line under it. A
/// slip can lie under the strings instead, in their shade, with the strings
/// drawn across it.
class PaperSlip extends StatelessWidget {
  const PaperSlip({
    super.key,
    required this.width,
    required this.u,
    required this.title,
    required this.status,
    this.titleColor = Palette.ink,
    this.statusColor = Palette.graphite,
    this.button = true,
    this.underStrings,
    this.onTap,
  });

  final double width;
  final double u;
  final String title;
  final String status;

  final Color titleColor;
  final Color statusColor;

  /// Whether the slip acts as a button for assistive technology.
  final bool button;

  /// The x of each string crossing the slip, when it lies under them.
  final List<double>? underStrings;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final k = width / slipPaperRect.width;
    final paper = Rect.fromLTRB(
      slipPaperRect.left * k,
      slipPaperRect.top * k,
      slipPaperRect.right * k,
      slipPaperRect.bottom * k,
    );
    final under = underStrings;
    return Semantics(
      button: button,
      label: '$title. $status',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: slipImageSize.width * k,
          height: slipImageSize.height * k,
          child: Stack(
            children: [
              Positioned.fill(child: Image.asset(slipAsset, fit: BoxFit.fill)),
              Positioned.fromRect(
                rect: paper.deflate(1),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12 * u),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(1, _flatten, 1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: Fonts.ui,
                            fontSize: math.max(18, 23 * u),
                            height: 1.05,
                            letterSpacing: -0.2,
                            fontVariations: const [FontVariation('wght', 700)],
                            color: titleColor,
                          ),
                        ),
                        SizedBox(height: 2 * u),
                        Text(
                          status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: Fonts.ui,
                            fontSize: math.max(13, 13.5 * u),
                            height: 1.2,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (under != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _StringsOverSlip(xs: under, paper: paper),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The shade and the strings over a slip that lies beneath them.
class _StringsOverSlip extends CustomPainter {
  _StringsOverSlip({required this.xs, required this.paper});

  final List<double> xs;
  final Rect paper;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(paper, Paint()..color = const Color(0x2E000000));
    final shadow = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 1.6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    // Thin and slightly see-through, so the name under them stays readable.
    final steel = Paint()
      ..color = const Color(0xB8B4B9C1)
      ..strokeWidth = 1.0;
    final glint = Paint()
      ..color = const Color(0x99F4F6F8)
      ..strokeWidth = 0.4;
    for (final x in xs) {
      canvas.drawLine(
        Offset(x + 2.5, paper.top),
        Offset(x + 2.5, paper.bottom),
        shadow,
      );
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), steel);
      canvas.drawLine(Offset(x - 0.3, 0), Offset(x - 0.3, size.height), glint);
    }
  }

  @override
  bool shouldRepaint(_StringsOverSlip old) =>
      old.xs != xs || old.paper != paper;
}
