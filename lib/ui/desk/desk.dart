import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'pencil_mark.dart';

/// The lacquer ground every screen stands on: a header row on the desk and
/// the screen's content below it. Content that is read goes on a [PaperSheet].
class DeskScaffold extends StatelessWidget {
  const DeskScaffold({
    super.key,
    required this.body,
    this.title,
    this.subtitle,
    this.onBack,
    this.backTooltip = 'Back',
    this.actions = const [],
    this.brand = false,
  });

  final Widget body;
  final String? title;
  final String? subtitle;
  final VoidCallback? onBack;
  final String backTooltip;
  final List<Widget> actions;

  /// Shows the Piano Tool lockup in place of a title, for the home screen.
  final bool brand;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final text = PianoTheme.textThemeOf(context);

    return Scaffold(
      backgroundColor: colors.desk,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PianoSpacing.md,
                PianoSpacing.sm,
                PianoSpacing.lg,
                PianoSpacing.sm,
              ),
              child: Row(
                children: [
                  if (onBack != null)
                    IconButton(
                      onPressed: onBack,
                      tooltip: backTooltip,
                      color: colors.deskInk,
                      icon: const Icon(Icons.chevron_left_rounded, size: 30),
                    )
                  else
                    const SizedBox(width: PianoSpacing.xs),
                  const SizedBox(width: PianoSpacing.xs),
                  if (brand)
                    const Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: BrandLockup(),
                      ),
                    ),
                  if (!brand && title != null)
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.headlineLarge?.copyWith(
                              color: colors.deskInk,
                              fontSize: 30,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall?.copyWith(
                                color: colors.deskMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  ...actions,
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// The mark and the name, as on the fallboard of the piano.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final text = PianoTheme.textThemeOf(context);
    return Semantics(
      header: true,
      label: 'Piano Tool',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/art/mark.png', width: 40, height: 40),
            const SizedBox(width: PianoSpacing.xs),
            Text(
              'Piano Tool',
              style: text.headlineLarge?.copyWith(
                color: colors.deskInk,
                fontSize: 30,
                fontVariations: const [FontVariation('wght', 500)],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A text action on the desk: the header's links to the library, import and
/// settings.
class DeskAction extends StatelessWidget {
  const DeskAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    if (MediaQuery.sizeOf(context).width < 500) {
      return IconButton(
        onPressed: onPressed,
        tooltip: label,
        color: colors.deskMuted,
        icon: Icon(icon, size: 20),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: PianoSpacing.xs),
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: colors.deskMuted,
          overlayColor: colors.deskInk,
          textStyle: PianoTheme.textThemeOf(
            context,
          ).bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(
            horizontal: PianoSpacing.sm,
            vertical: PianoSpacing.sm,
          ),
        ),
        icon: Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }
}

/// A sheet of paper lying on the desk: the grain from the Blender render, a
/// lighter top edge and a soft contact shadow. Everything on it is ink.
class PaperSheet extends StatelessWidget {
  const PaperSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(PianoSpacing.lg),
    this.tilt = 0,
    this.clipped = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Degrees off square: sheets on a real desk never lie quite straight.
  /// Kept to a degree or so, so reading is never harder.
  final double tilt;

  /// Held at the top by the music rack's page clip (a Blender render).
  final bool clipped;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    Widget sheet = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paper,
        image: DecorationImage(
          image: const AssetImage('assets/art/paper.png'),
          repeat: ImageRepeat.repeat,
          scale: 2,
          // Multiplied into the paper colour, so the grain dims with the lamp.
          colorFilter: ColorFilter.mode(colors.paper, BlendMode.multiply),
        ),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xB3000000),
            blurRadius: 28,
            spreadRadius: -10,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
    if (clipped) {
      sheet = Stack(
        clipBehavior: Clip.none,
        children: [
          sheet,
          Positioned(
            top: -26,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/art/clip.png',
                width: 72,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ],
      );
    }
    if (tilt == 0) return sheet;
    return Transform.rotate(angle: tilt * math.pi / 180, child: sheet);
  }
}

/// The cloth of a stage's method book. Built-in stages take blue, green and
/// rust in order; imported pieces are slate.
enum CoverCloth {
  blue,
  green,
  rust,
  slate;

  String get asset => 'assets/art/cover-$name.png';

  static CoverCloth forStage({required int index, required bool imported}) =>
      imported ? slate : const [blue, green, rust][index % 3];
}

/// A stage's method book, seen from the front: the Blender cover with the
/// stage number and title stamped on it in foil.
class StageCover extends StatelessWidget {
  const StageCover({
    super.key,
    required this.cloth,
    required this.title,
    this.number,
    this.dimmed = false,
    this.sticker = false,
  });

  final CoverCloth cloth;
  final String title;

  /// The stage number; imported pieces have none.
  final int? number;

  /// A locked stage: the book stays on the shelf in shadow.
  final bool dimmed;

  /// A cleared stage: the teacher's star sticker on the corner of the cover.
  final bool sticker;

  /// The render is 720 x 840.
  static const double aspectRatio = 720 / 840;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final text = PianoTheme.textThemeOf(context);

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final foil = colors.coverFoil;
          final cover = Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(cloth.asset, fit: BoxFit.contain),
              // Inside the cover's raised frame rule.
              Positioned(
                left: w * 0.27,
                right: w * 0.16,
                top: w * 0.16,
                bottom: w * 0.16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (number != null)
                      Text(
                        '$number',
                        style: text.displayLarge?.copyWith(
                          color: foil,
                          fontSize: w * 0.3,
                          height: 1,
                          // Cormorant's old-style 1 reads as a Roman I.
                          fontFeatures: const [FontFeature.liningFigures()],
                        ),
                      ),
                    const Spacer(),
                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: text.headlineLarge?.copyWith(
                        color: foil,
                        fontSize: (w * 0.105).clamp(14.0, 40.0),
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          if (sticker) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                cover,
                Positioned(
                  right: -w * 0.04,
                  top: -w * 0.04,
                  child: _StarSticker(size: w * 0.32),
                ),
              ],
            );
          }
          if (!dimmed) return cover;
          return ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.45, 0, 0, 0, 0, //
              0, 0.45, 0, 0, 0, //
              0, 0, 0.45, 0, 0, //
              0, 0, 0, 1, 0, //
            ]),
            child: cover,
          );
        },
      ),
    );
  }
}

/// A round paper sticker with a blue pencil star, stuck on a little crooked.
class _StarSticker extends StatelessWidget {
  const _StarSticker({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    return Transform.rotate(
      angle: 0.22,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.16),
        decoration: BoxDecoration(
          color: colors.paper,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: PencilMark(Pencil.star, color: colors.accent),
      ),
    );
  }
}
