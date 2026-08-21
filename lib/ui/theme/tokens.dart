import 'package:flutter/widgets.dart';

/// Colour tokens, authored in OKLCH and converted to sRGB.
/// The OKLCH source is kept alongside each value so the palette stays
/// auditable. Hue never changes between themes; only lightness and chroma.
const Map<String, int> argbLight = {
  'paper': 0xFFFFFFFF, // oklch(100%  0     0)
  'paper2': 0xFFF9F6F2, // oklch(97.5% 0.006 72)
  'paper3': 0xFFF1ECE6, // oklch(94.5% 0.010 72)
  'ink': 0xFF1A1510, // oklch(20%   0.012 68)
  'ink2': 0xFF47413C, // oklch(38%   0.012 68)
  'staff': 0xFF807971, // oklch(58%   0.014 72)
  'rule': 0xFFC9C3BC, // oklch(82%   0.012 72)
  'rule2': 0xFFE2DDD7, // oklch(90%   0.010 72)
  'muted': 0xFF68625C, // oklch(50%   0.012 68)
  'accent': 0xFF2757B6, // oklch(48%   0.16  262)
  'accentInk': 0xFFFDFBF9, // oklch(99%   0.004 72)
  'focus': 0xFF1F5ED9, // oklch(52%   0.20  262)
  'success': 0xFF067132, // oklch(48%   0.13  150)
  'warning': 0xFFF57C00, // oklch(65%   0.14  72)
  'error': 0xFFB63132, // oklch(52%   0.17  25)
};

const Map<String, int> argbDark = {
  'paper': 0xFF110C07, // oklch(16% 0.014 72)
  'paper2': 0xFF1B150E, // oklch(20% 0.016 72)
  'paper3': 0xFF241E17, // oklch(24% 0.016 72)
  'ink': 0xFFECE7E1, // oklch(93% 0.010 72)
  'ink2': 0xFFAFAAA4, // oklch(74% 0.010 72)
  'staff': 0xFF7A736C, // oklch(56% 0.014 72)
  'rule': 0xFF4D4740, // oklch(40% 0.014 72)
  'rule2': 0xFF322D27, // oklch(30% 0.012 72)
  'muted': 0xFF8B857F, // oklch(62% 0.012 68)
  'accent': 0xFF6591E1, // oklch(66% 0.13  262)
  'accentInk': 0xFF15110C, // oklch(18% 0.012 68)
  'focus': 0xFF68A1FF, // oklch(72% 0.17  262)
  'success': 0xFF5DAD70, // oklch(68% 0.12  150)
  'warning': 0xFFFFB74D, // oklch(80%   0.12  72)
  'error': 0xFFD8625C, // oklch(64% 0.15  25)
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
