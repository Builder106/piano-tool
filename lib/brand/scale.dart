import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Scale shared by every screen: 1 at a 1280 by 720 window. It follows the
/// smaller of the height and the width, so a tall, narrow phone does not get
/// desktop-sized type.
double unitOf(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return math.min(size.height / 720, size.width / 900).clamp(0.7, 1.25);
}
