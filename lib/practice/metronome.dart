import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the rod's pivot and top, and the weight's centre, sit in the
/// metronome sprites, as 0..1 of the image. Written by
/// `design/blender/strung.py` with the renders.
class MetronomeGeometry {
  const MetronomeGeometry({
    required this.aspect,
    required this.pivot,
    required this.rodTop,
    required this.weight,
  });

  factory MetronomeGeometry.fromJson(Map<String, dynamic> j) {
    Offset at(String k) {
      final p = j[k] as List<dynamic>;
      return Offset((p[0] as num).toDouble(), (p[1] as num).toDouble());
    }

    return MetronomeGeometry(
      aspect: (j['width'] as num) / (j['height'] as num),
      pivot: at('pivot'),
      rodTop: at('rodTop'),
      weight: at('weight'),
    );
  }

  final double aspect;
  final Offset pivot;
  final Offset rodTop;
  final Offset weight;

  /// How far up the rod the weight was rendered, 0 at the pivot.
  double get renderedAt => (pivot.dy - weight.dy) / (pivot.dy - rodTop.dy);
}

final metronomeGeometryProvider = FutureProvider<MetronomeGeometry>((
  ref,
) async {
  final raw = await rootBundle.loadString('assets/art/strung/metronome.json');
  return MetronomeGeometry.fromJson(jsonDecode(raw) as Map<String, dynamic>);
});

const minMetronomeSpeed = 0.5;
const maxMetronomeSpeed = 1.0;

/// Where the weight sits on the rod for a speed: low and fast at full
/// speed, high and slow at half, as on a real metronome.
double weightPosition(double speed) {
  final t =
      ((maxMetronomeSpeed - speed) / (maxMetronomeSpeed - minMetronomeSpeed))
          .clamp(0.0, 1.0);
  return 0.25 + t * 0.55;
}

/// The speed for a weight position on the rod, snapped to five per cent.
double speedForWeight(double position) {
  final t = ((position - 0.25) / 0.55).clamp(0.0, 1.0);
  final speed = maxMetronomeSpeed - t * (maxMetronomeSpeed - minMetronomeSpeed);
  return (speed * 20).round() / 20;
}

/// A metronome standing on the piano. Sliding the weight up the rod slows
/// the piece down; while the piece plays, the rod swings on the beat.
class Metronome extends StatefulWidget {
  const Metronome({
    super.key,
    required this.geometry,
    required this.height,
    required this.speed,
    required this.beat,
    required this.swinging,
    required this.onSpeed,
  });

  final MetronomeGeometry geometry;
  final double height;
  final double speed;
  final double beat;
  final bool swinging;
  final ValueChanged<double> onSpeed;

  @override
  State<Metronome> createState() => _MetronomeState();
}

class _MetronomeState extends State<Metronome> {
  double? _dragPosition;

  void _nudge(double by) => widget.onSpeed(
    (widget.speed + by).clamp(minMetronomeSpeed, maxMetronomeSpeed),
  );

  @override
  Widget build(BuildContext context) {
    final g = widget.geometry;
    final h = widget.height;
    final w = h * g.aspect;
    final pivot = Offset(g.pivot.dx * w, g.pivot.dy * h);
    final rod = (g.pivot.dy - g.rodTop.dy) * h;
    final at = _dragPosition ?? weightPosition(widget.speed);
    final lift = (at - g.renderedAt) * rod;
    final reduced = MediaQuery.disableAnimationsOf(context);
    // The rod reaches the end of its swing on every beat.
    final angle = widget.swinging && !reduced
        ? 0.3 * math.cos(math.pi * widget.beat)
        : 0.0;
    final percent = (widget.speed * 100).round();
    return FocusableActionDetector(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowUp): _Faster(),
        SingleActivator(LogicalKeyboardKey.arrowRight): _Faster(),
        SingleActivator(LogicalKeyboardKey.arrowDown): _Slower(),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _Slower(),
      },
      actions: {
        _Faster: CallbackAction<_Faster>(onInvoke: (_) => _nudge(0.05)),
        _Slower: CallbackAction<_Slower>(onInvoke: (_) => _nudge(-0.05)),
      },
      child: Semantics(
        slider: true,
        label: 'Metronome speed',
        value: '$percent percent',
        increasedValue: '${math.min(100, percent + 5)} percent',
        decreasedValue: '${math.max(50, percent - 5)} percent',
        onIncrease: () => _nudge(0.05),
        onDecrease: () => _nudge(-0.05),
        child: GestureDetector(
          onVerticalDragStart: (_) =>
              setState(() => _dragPosition = weightPosition(widget.speed)),
          onVerticalDragUpdate: (d) {
            final next = ((_dragPosition ?? at) - d.delta.dy / rod).clamp(
              0.25,
              0.8,
            );
            setState(() => _dragPosition = next);
            widget.onSpeed(speedForWeight(next));
          },
          onVerticalDragEnd: (_) => setState(() => _dragPosition = null),
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: w * 0.08,
                  right: w * 0.08,
                  bottom: -h * 0.02,
                  height: h * 0.06,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [Color(0x99000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Image.asset(
                    'assets/art/strung/metronome-body.png',
                    fit: BoxFit.fill,
                    excludeFromSemantics: true,
                  ),
                ),
                Positioned.fill(
                  child: Transform(
                    transform: Matrix4.identity()
                      ..translateByDouble(pivot.dx, pivot.dy, 0, 1)
                      ..rotateZ(angle)
                      ..translateByDouble(-pivot.dx, -pivot.dy, 0, 1),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/art/strung/metronome-rod.png',
                          fit: BoxFit.fill,
                          excludeFromSemantics: true,
                        ),
                        Transform.translate(
                          offset: Offset(0, -lift),
                          child: Image.asset(
                            'assets/art/strung/metronome-weight.png',
                            fit: BoxFit.fill,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Faster extends Intent {
  const _Faster();
}

class _Slower extends Intent {
  const _Slower();
}
