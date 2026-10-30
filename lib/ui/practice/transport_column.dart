import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// The left control column. Fixed width because it holds icon buttons at a
/// real touch target; the horizontal axis has room to spare.
class TransportColumn extends StatelessWidget {
  const TransportColumn({
    super.key,
    required this.isPlaying,
    required this.speed,
    required this.onPlayPause,
    required this.onStop,
    required this.onReplay,
    required this.onSpeedChanged,
    this.closeUp = false,
    this.onCloseUpChanged,
    this.noteNames = false,
    this.onNoteNamesChanged,
  });

  static const double width = 60;

  /// The speeds the label cycles through, slowest first.
  static const List<double> speedSteps = [0.5, 0.75, 1.0, 1.5, 2.0];

  final bool isPlaying;
  final double speed;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final VoidCallback onReplay;
  final ValueChanged<double> onSpeedChanged;

  /// The keyboard shows the piece's octaves rather than all 61 keys.
  final bool closeUp;
  final ValueChanged<bool>? onCloseUpChanged;

  /// Letter names on the white keys.
  final bool noteNames;
  final ValueChanged<bool>? onNoteNamesChanged;

  /// "0.75x" and "1.0x", not "0.8x". Trailing zeros go, the tenth stays.
  String get _label {
    final digits = speed
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return '${digits}x';
  }

  double get _nextSpeed {
    // Nearest step, so a speed set elsewhere still advances sensibly.
    var nearest = 0;
    for (var i = 1; i < speedSteps.length; i++) {
      if ((speedSteps[i] - speed).abs() < (speedSteps[nearest] - speed).abs()) {
        nearest = i;
      }
    }
    return speedSteps[(nearest + 1) % speedSteps.length];
  }

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    // Stands on the desk beside the music, like the controls on a piano's cheek.
    return SizedBox(
      width: width,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onPlayPause,
                iconSize: 26,
                style: IconButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.accentInk,
                  minimumSize: const Size(48, 48),
                ),
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                tooltip: isPlaying ? 'Pause' : 'Play',
              ),
              const SizedBox(height: PianoSpacing.sm),
              IconButton(
                onPressed: onStop,
                iconSize: 20,
                color: colors.deskInk,
                icon: const Icon(Icons.stop),
                tooltip: 'Stop and hold position',
              ),
              IconButton(
                onPressed: onReplay,
                iconSize: 20,
                color: colors.deskInk,
                icon: const Icon(Icons.replay),
                tooltip: 'Replay from the start',
              ),
              const SizedBox(height: PianoSpacing.xs),
              // Choices that change how the page looks wait for a pause, so
              // nothing moves under the learner's hands while they play. They
              // keep their place either way.
              IgnorePointer(
                ignoring: isPlaying,
                child: AnimatedOpacity(
                  opacity: isPlaying ? 0 : 1,
                  duration: PianoMotion.short,
                  child: Column(
                    children: [
                      Tooltip(
                        message: 'Playback speed',
                        child: InkWell(
                          onTap: () => onSpeedChanged(_nextSpeed),
                          // A real touch target. The label is small, the thing
                          // you hit is not.
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: kMinInteractiveDimension,
                              minHeight: kMinInteractiveDimension,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _label,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: colors.deskInk),
                            ),
                          ),
                        ),
                      ),
                      if (onCloseUpChanged case final onCloseUp?)
                        IconButton(
                          onPressed: () => onCloseUp(!closeUp),
                          iconSize: 20,
                          color: colors.deskInk,
                          isSelected: closeUp,
                          icon: const Icon(Icons.zoom_in_rounded),
                          selectedIcon: const Icon(Icons.zoom_out_rounded),
                          tooltip: closeUp
                              ? 'Show all keys'
                              : 'Show these keys closer',
                        ),
                      if (onNoteNamesChanged case final onNoteNames?)
                        Tooltip(
                          message: noteNames
                              ? 'Hide note names'
                              : 'Show note names',
                          child: Semantics(
                            button: true,
                            toggled: noteNames,
                            label: 'Note names on the keys',
                            excludeSemantics: true,
                            child: InkWell(
                              onTap: () => onNoteNames(!noteNames),
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: kMinInteractiveDimension,
                                  minHeight: kMinInteractiveDimension,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'CDE',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: noteNames
                                            ? colors.deskAccent
                                            : colors.deskMuted,
                                        decoration: noteNames
                                            ? TextDecoration.underline
                                            : null,
                                        decorationColor: colors.deskAccent,
                                      ),
                                ),
                              ),
                            ),
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
    );
  }
}
