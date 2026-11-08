import 'package:flutter/material.dart';

import 'palette.dart';

/// A control lettered in nickel on lacquer, like the maker's mark on the
/// name board.
class NickelInlay extends StatelessWidget {
  const NickelInlay({
    super.key,
    required this.label,
    required this.size,
    this.onPressed,
  });

  final String label;
  final double size;
  final VoidCallback? onPressed;

  static const _nickel = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF1F3F5), Color(0xFF9DA2AA), Color(0xFFD6D9DE)],
    stops: [0.0, 0.55, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: Fonts.ui,
      fontSize: size,
      height: 1,
      letterSpacing: 0.4,
      fontVariations: const [FontVariation('wght', 700)],
    );
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: size * 0.5, vertical: size * 0.4),
        ),
        overlayColor: WidgetStatePropertyAll(
          Palette.paper.withValues(alpha: 0.06),
        ),
        shape: WidgetStateProperty.resolveWith(
          (states) => RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: states.contains(WidgetState.focused)
                ? const BorderSide(color: Color(0xFFC9CDD3), width: 1.5)
                : BorderSide.none,
          ),
        ),
      ),
      child: Stack(
        children: [
          // The inlay's lower lip: a dark line just under the metal.
          Transform.translate(
            offset: const Offset(0, 1.2),
            child: Text(label, style: style.copyWith(color: Colors.black)),
          ),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: _nickel.createShader,
            child: Text(label, style: style.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
