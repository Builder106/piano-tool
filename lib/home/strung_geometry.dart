import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const homeBackdropAsset = 'assets/art/strung/home.jpg';
const slipAsset = 'assets/art/strung/slip.png';
const _homeGeometryAsset = 'assets/art/strung/home.json';

/// Where each note's strings, damper and key fall in the home render, in
/// 0..1 image coordinates with a top-left origin. Written by
/// `design/blender/strung.py` alongside the render it describes.
class StrungGeometry {
  const StrungGeometry({
    required this.imageSize,
    required this.notes,
    this.nameBoard,
    this.logo,
  });

  factory StrungGeometry.fromJson(Map<String, dynamic> json) {
    final notes = <int, NoteGeometry>{};
    for (final raw in json['notes'] as List<dynamic>) {
      final note = NoteGeometry.fromJson(raw as Map<String, dynamic>);
      notes[note.midi] = note;
    }
    final board = json['nameBoard'] as Map<String, dynamic>?;
    final logo = json['logo'] as Map<String, dynamic>?;
    return StrungGeometry(
      nameBoard: board == null ? null : _rect(board),
      logo: logo == null ? null : _rect(logo),
      imageSize: Size(
        (json['width'] as num).toDouble(),
        (json['height'] as num).toDouble(),
      ),
      notes: notes,
    );
  }

  final Size imageSize;
  final Map<int, NoteGeometry> notes;

  /// The lacquered board behind the keys, and the maker's mark on it.
  final Rect? nameBoard;
  final Rect? logo;
}

Rect _rect(Map<String, dynamic> r) => Rect.fromLTRB(
  (r['x0'] as num).toDouble(),
  (r['y0'] as num).toDouble(),
  (r['x1'] as num).toDouble(),
  (r['y1'] as num).toDouble(),
);

class NoteGeometry {
  const NoteGeometry({
    required this.midi,
    required this.strings,
    required this.key,
    this.damper,
  });

  factory NoteGeometry.fromJson(Map<String, dynamic> json) {
    final damper = json['damper'] as Map<String, dynamic>?;
    return NoteGeometry(
      midi: json['midi'] as int,
      strings: [
        for (final x in json['strings'] as List<dynamic>) (x as num).toDouble(),
      ],
      key: _rect(json['key'] as Map<String, dynamic>),
      damper: damper == null ? null : _rect(damper),
    );
  }

  final int midi;

  /// The x of each string in the note's unison, left to right.
  final List<double> strings;
  final Rect key;
  final Rect? damper;
}

final strungGeometryProvider = FutureProvider<StrungGeometry>((ref) async {
  final raw = await rootBundle.loadString(_homeGeometryAsset);
  return StrungGeometry.fromJson(jsonDecode(raw) as Map<String, dynamic>);
});

/// Maps image coordinates onto a box the image covers.
///
/// The image's anchor row ([anchorY], the dampers) lands as close to
/// [anchorAt] of the box height as the image allows without leaving a gap,
/// so a wide box crops a little of the strings and a little of the keys
/// rather than all of one. [focusX] is the image column kept centred where
/// the box is narrower than the image.
class CoverFit {
  factory CoverFit(
    Size image,
    Size box, {
    double anchorY = 0.415,
    double anchorAt = 0.42,
    double focusX = 0.5,
  }) {
    final scale = math.max(box.width / image.width, box.height / image.height);
    final drawn = image * scale;
    final dy = (anchorAt * box.height - anchorY * drawn.height).clamp(
      box.height - drawn.height,
      0.0,
    );
    final dx = (box.width / 2 - focusX * drawn.width).clamp(
      box.width - drawn.width,
      0.0,
    );
    return CoverFit.placed(drawn, Offset(dx, dy));
  }

  const CoverFit.placed(this.drawn, this.origin);

  /// The image scaled to the box's width, with image row [rowY] at the
  /// box's bottom edge: the practice screen's framing, which keeps only the
  /// name board and the backs of the keys.
  factory CoverFit.bottomRow(Size image, Size box, {required double rowY}) {
    final drawn = image * (box.width / image.width);
    return CoverFit.placed(drawn, Offset(0, box.height - rowY * drawn.height));
  }

  static CoverFit lerp(CoverFit a, CoverFit b, double t) => CoverFit.placed(
    Size.lerp(a.drawn, b.drawn, t)!,
    Offset.lerp(a.origin, b.origin, t)!,
  );

  final Size drawn;
  final Offset origin;

  Offset point(double x, double y) =>
      origin + Offset(x * drawn.width, y * drawn.height);

  double x(double x) => origin.dx + x * drawn.width;
  double y(double y) => origin.dy + y * drawn.height;

  Rect rect(Rect r) =>
      Rect.fromPoints(point(r.left, r.top), point(r.right, r.bottom));
}
