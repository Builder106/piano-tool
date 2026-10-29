import 'package:flutter/widgets.dart';

/// Colour tokens, authored in OKLCH and converted to sRGB.
/// The OKLCH source is kept alongside each value so the palette stays
/// auditable.
///
/// The app is a music desk: the desk tokens are piano lacquer and never change
/// with the theme. Everything else is the paper on the desk and what is printed
/// on it, so the dark theme is the same sheet under a lower lamp, not an
/// inverted page. The cover tokens are the cloth of each stage's method book.
const Map<String, int> argbLight = {
  'paper': 0xFFECEEF1, // oklch(94.8% 0.005 258)
  'paper2': 0xFFE3E6EB, // oklch(92.4% 0.008 261)
  'paper3': 0xFFD9DDE3, // oklch(89.6% 0.009 258)
  'ink': 0xFF13161C, // oklch(20.0% 0.013 264)
  'ink2': 0xFF3F4349, // oklch(38.1% 0.012 258)
  'staff': 0xFF6A6F77, // oklch(54.0% 0.014 260)
  'rule': 0xFFB4B9C1, // oklch(78.4% 0.013 260)
  'rule2': 0xFFCDD1D8, // oklch(86.0% 0.011 262)
  'muted': 0xFF4E535C, // oklch(44.1% 0.016 262)
  'accent': 0xFF2456C8, // oklch(49.1% 0.186 263)
  'accentInk': 0xFFFAFCFF, // oklch(99.0% 0.005 258)
  'focus': 0xFF1F5ED9, // oklch(52.0% 0.199 262)
  'success': 0xFF067132, // oklch(48.0% 0.130 150)
  'warning': 0xFF9A5A00, // oklch(52.9% 0.119 64)
  'error': 0xFFB63132, // oklch(51.9% 0.170 25)
  'desk': 0xFF0A0A0B, // oklch(14.5% 0.002 286)
  'desk2': 0xFF16171A, // oklch(20.5% 0.006 271)
  'deskInk': 0xFFECEEF1, // oklch(94.8% 0.005 258)
  'deskMuted': 0xFFA3A3AA, // oklch(71.8% 0.010 286)
  'deskRule': 0xFF2B2D32, // oklch(29.7% 0.009 268)
  'deskAccent': 0xFF6591E1, // oklch(66.0% 0.129 262)
  'coverBlue': 0xFF2456C8, // oklch(49.1% 0.186 263)
  'coverGreen': 0xFF1F6A50, // oklch(47.1% 0.084 166)
  'coverRust': 0xFFB4501E, // oklch(55.2% 0.144 44)
  'coverSlate': 0xFF4E535C, // oklch(44.1% 0.016 262)
  'coverFoil': 0xFFEEF0F3, // oklch(95.4% 0.005 258)
};

/// The lamp turned down: the same paper and ink, dimmer.
const Map<String, int> argbDark = {
  'paper': 0xFFD9DCE1, // oklch(89.4% 0.008 261)
  'paper2': 0xFFD0D3D9, // oklch(86.6% 0.009 265)
  'paper3': 0xFFC6CAD1, // oklch(83.8% 0.011 262)
  'ink': 0xFF13161C, // oklch(20.0% 0.013 264)
  'ink2': 0xFF363A41, // oklch(34.7% 0.013 262)
  'staff': 0xFF5E636B, // oklch(49.8% 0.014 260)
  'rule': 0xFFA3A8B0, // oklch(73.0% 0.013 260)
  'rule2': 0xFFBBC0C7, // oklch(80.6% 0.011 257)
  'muted': 0xFF464B53, // oklch(41.1% 0.015 260)
  'accent': 0xFF2456C8, // oklch(49.1% 0.186 263)
  'accentInk': 0xFFFAFCFF, // oklch(99.0% 0.005 258)
  'focus': 0xFF1F5ED9, // oklch(52.0% 0.199 262)
  'success': 0xFF055F2A, // oklch(42.5% 0.114 150)
  'warning': 0xFF7F4A00, // oklch(46.1% 0.104 65)
  'error': 0xFFA12829, // oklch(47.1% 0.157 25)
  'desk': 0xFF0A0A0B, // oklch(14.5% 0.002 286)
  'desk2': 0xFF16171A, // oklch(20.5% 0.006 271)
  'deskInk': 0xFFECEEF1, // oklch(94.8% 0.005 258)
  'deskMuted': 0xFFA3A3AA, // oklch(71.8% 0.010 286)
  'deskRule': 0xFF2B2D32, // oklch(29.7% 0.009 268)
  'deskAccent': 0xFF6591E1, // oklch(66.0% 0.129 262)
  'coverBlue': 0xFF2456C8, // oklch(49.1% 0.186 263)
  'coverGreen': 0xFF1F6A50, // oklch(47.1% 0.084 166)
  'coverRust': 0xFFB4501E, // oklch(55.2% 0.144 44)
  'coverSlate': 0xFF4E535C, // oklch(44.1% 0.016 262)
  'coverFoil': 0xFFEEF0F3, // oklch(95.4% 0.005 258)
};

@immutable
class PianoColors {
  const PianoColors._(this._argb);

  factory PianoColors.light() => const PianoColors._(argbLight);
  factory PianoColors.dark() => const PianoColors._(argbDark);

  /// Builds a transient token set, used only for theme-transition lerping.
  factory PianoColors.fromArgb(Map<String, int> argb) => PianoColors._(argb);

  final Map<String, int> _argb;

  /// The raw ARGB values behind this token set. Exposed for theme lerping.
  Map<String, int> get argb => _argb;

  Color _c(String name) => Color(_argb[name]!);

  Color get paper => _c('paper');
  Color get paper2 => _c('paper2');
  Color get paper3 => _c('paper3');
  Color get ink => _c('ink');
  Color get ink2 => _c('ink2');
  Color get staff => _c('staff');
  Color get rule => _c('rule');
  Color get rule2 => _c('rule2');
  Color get muted => _c('muted');
  Color get accent => _c('accent');
  Color get accentInk => _c('accentInk');
  Color get focus => _c('focus');
  Color get success => _c('success');
  Color get warning => _c('warning');
  Color get error => _c('error');
  Color get desk => _c('desk');
  Color get desk2 => _c('desk2');
  Color get deskInk => _c('deskInk');
  Color get deskMuted => _c('deskMuted');
  Color get deskRule => _c('deskRule');
  Color get deskAccent => _c('deskAccent');
  Color get coverBlue => _c('coverBlue');
  Color get coverGreen => _c('coverGreen');
  Color get coverRust => _c('coverRust');
  Color get coverSlate => _c('coverSlate');
  Color get coverFoil => _c('coverFoil');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PianoColors && identical(other._argb, _argb));

  @override
  int get hashCode => identityHashCode(_argb);
}

/// 4pt spacing scale, named by role.
abstract final class PianoSpacing {
  static const double xs2 = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 40;
  static const double xl2 = 64;
  static const double xl3 = 96;
}

/// Motion. One moment only: the notehead tick on hit.
abstract final class PianoMotion {
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration short = Duration(milliseconds: 220);
  static const Curve easeOut = Cubic(0.16, 1, 0.3, 1);
  static const Curve easeIn = Cubic(0.7, 0, 0.84, 0);
}

/// Radius tokens.
abstract final class PianoRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
}
