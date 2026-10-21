import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/settings_repository.dart';
import '../../services/midi_service.dart';
import '../practice/stage_controller.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Settings and hardware calibration screen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = PianoTheme.colorsOf(context);
    final textTheme = PianoTheme.textThemeOf(context);
    final settings = ref.watch(settingsProvider);
    final audioGrantedAsync = ref.watch(audioGrantedProvider);

    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PianoSpacing.lg,
                vertical: PianoSpacing.md,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: colors.ink,
                      size: 26,
                    ),
                    onPressed: () => context.pop(),
                    tooltip: 'Back to library',
                  ),
                  const SizedBox(width: PianoSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings & Calibration',
                        style: textTheme.headlineSmall?.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Practice preferences, timing accuracy, and audio diagnostics',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable settings body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(PianoSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Column 1: Appearance & Practice Preferences
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            context,
                            'Appearance',
                            Icons.palette_outlined,
                          ),
                          const SizedBox(height: PianoSpacing.sm),
                          _buildThemeSelector(context, ref, settings.themeMode),

                          const SizedBox(height: PianoSpacing.xl),
                          _buildSectionHeader(
                            context,
                            'Practice Preferences',
                            Icons.speed_rounded,
                          ),
                          const SizedBox(height: PianoSpacing.sm),
                          _buildSpeedSelector(
                            context,
                            ref,
                            settings.defaultPlaybackSpeed,
                          ),
                          const SizedBox(height: PianoSpacing.md),
                          _buildToleranceSelector(
                            context,
                            ref,
                            settings.toleranceLevel,
                          ),
                          const SizedBox(height: PianoSpacing.md),
                          _buildInputSourceSelector(
                            context,
                            ref,
                            settings.inputSource,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: PianoSpacing.xl),

                    // Column 2: Audio Diagnostics & Backend Architecture
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            context,
                            'Audio & Hardware Diagnostics',
                            Icons.mic_none_rounded,
                          ),
                          const SizedBox(height: PianoSpacing.sm),
                          _buildMicCard(context, ref, audioGrantedAsync),
                          const SizedBox(height: PianoSpacing.md),
                          _buildMidiCard(context, ref),
                          const SizedBox(height: PianoSpacing.md),
                          _buildAudioEngineSpecsCard(context),

                          const SizedBox(height: PianoSpacing.xl),
                          _buildSectionHeader(
                            context,
                            'Audio Ingestion Backend',
                            Icons.dns_outlined,
                          ),
                          const SizedBox(height: PianoSpacing.sm),
                          _buildBackendCard(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final colors = PianoTheme.colorsOf(context);
    final textTheme = PianoTheme.textThemeOf(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: colors.accent),
        const SizedBox(width: PianoSpacing.xs),
        Text(
          title,
          style: textTheme.titleLarge?.copyWith(
            color: colors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) {
    final colors = PianoTheme.colorsOf(context);
    final textTheme = PianoTheme.textThemeOf(context);

    final options = [
      (ThemeMode.system, 'System Default', Icons.brightness_auto_rounded),
      (ThemeMode.light, 'Recital Light', Icons.light_mode_rounded),
      (ThemeMode.dark, 'Recital Dark', Icons.dark_mode_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(PianoSpacing.sm),
      decoration: BoxDecoration(
        color: colors.paper2,
        borderRadius: BorderRadius.circular(PianoRadius.md),
        border: Border.all(color: colors.rule),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = current == opt.$1;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () {
                  ref.read(settingsProvider.notifier).setThemeMode(opt.$1);
                },
                borderRadius: BorderRadius.circular(PianoRadius.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: PianoSpacing.md,
                    horizontal: PianoSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.paper : Colors.transparent,
                    borderRadius: BorderRadius.circular(PianoRadius.sm),
                    border: isSelected
                        ? Border.all(color: colors.accent, width: 1.5)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colors.ink.withAlpha(15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        opt.$3,
                        color: isSelected ? colors.accent : colors.muted,
                        size: 22,
                      ),
                      const SizedBox(height: PianoSpacing.xs),
                      Text(
                        opt.$2,
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: isSelected ? colors.ink : colors.muted,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSpeedSelector(
    BuildContext context,
    WidgetRef ref,
    double currentSpeed,
  ) {
    final colors = PianoTheme.colorsOf(context);
    final textTheme = PianoTheme.textThemeOf(context);
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

    return Container(
      padding: const EdgeInsets.all(PianoSpacing.md),
      decoration: BoxDecoration(
        color: colors.paper2,
        borderRadius: BorderRadius.circular(PianoRadius.md),
        border: Border.all(color: colors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Default Practice Tempo',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                ),
              ),
              Text(
                '${currentSpeed}x',
                style: textTheme.labelLarge?.copyWith(
                  color: colors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: PianoSpacing.xs),
          Text(
            'Initial playback speed when starting a practice stage',
            style: textTheme.bodySmall?.copyWith(color: colors.muted),
          ),
          const SizedBox(height: PianoSpacing.sm),
          Row(
            children: speeds.map((speed) {
              final isSelected = (currentSpeed - speed).abs() < 0.01;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: OutlinedButton(
                    onPressed: () {
                      ref
                          .read(settingsProvider.notifier)
                          .setDefaultSpeed(speed);
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSelected
                          ? colors.accent
                          : colors.paper,
                      foregroundColor: isSelected
                          ? colors.accentInk
                          : colors.ink,
                      side: BorderSide(
                        color: isSelected ? colors.accent : colors.rule,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      '${speed}x',
                      style: textTheme.labelSmall?.copyWith(
                        color: isSelected ? colors.accentInk : colors.ink,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToleranceSelector(
    BuildContext context,
    WidgetRef ref,
    ToleranceLevel current,
  ) {
    final colors = PianoTheme.colorsOf(context);
    final textTheme = PianoTheme.textThemeOf(context);

    return Container(
      padding: const EdgeInsets.all(PianoSpacing.md),
      decoration: BoxDecoration(
        color: colors.paper2,
        borderRadius: BorderRadius.circular(PianoRadius.md),
        border: Border.all(color: colors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scoring Timing Accuracy',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: PianoSpacing.xs),
          Text(
            'Controls how closely notes must land on the beat to qualify as Perfect or Good',
            style: textTheme.bodySmall?.copyWith(color: colors.muted),
          ),
          const SizedBox(height: PianoSpacing.sm),
          ...ToleranceLevel.values.map((level) {
            final isSelected = current == level;
            return Padding(
              padding: const EdgeInsets.only(bottom: PianoSpacing.xs),
              child: InkWell(
                onTap: () {
                  ref.read(settingsProvider.notifier).setToleranceLevel(level);
                },
                borderRadius: BorderRadius.circular(PianoRadius.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PianoSpacing.md,
                    vertical: PianoSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.paper : Colors.transparent,
                    borderRadius: BorderRadius.circular(PianoRadius.sm),
                    border: Border.all(
                      color: isSelected ? colors.accent : colors.rule2,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected ? colors.accent : colors.muted,
                        size: 18,
                      ),
                      const SizedBox(width: PianoSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              level.label,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.ink,
                              ),
                            ),
                            Text(
                              level.description,
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '±${level.perfectWindow} beats',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInputSourceSelector(
    BuildContext context,
    WidgetRef ref,
    PracticeInputSource currentSource,
  ) {
    final colors = PianoTheme.colorsOf(context);
    final textTheme = PianoTheme.textThemeOf(context);

    return Container(
      padding: const EdgeInsets.all(PianoSpacing.md),
      decoration: BoxDecoration(
        color: colors.paper2,
        borderRadius: BorderRadius.circular(PianoRadius.md),
        border: Border.all(color: colors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Practice Input Source',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                ),
              ),
              Text(
                currentSource.label,
                style: textTheme.labelLarge?.copyWith(
                  color: colors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: PianoSpacing.xs),
          Text(
            currentSource.description,
            style: textTheme.bodySmall?.copyWith(color: colors.muted),
          ),
          const SizedBox(height: PianoSpacing.sm),
          Row(
            children: PracticeInputSource.values.map((src) {
              final isSelected = src == currentSource;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(settingsProvider.notifier).setInputSource(src);
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          isSelected ? colors.accent : colors.paper,
                      foregroundColor:
                          isSelected ? colors.accentInk : colors.ink,
                      side: BorderSide(
                        color: isSelected ? colors.accent : colors.rule,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      src.label,
                      textAlign: TextAlign.center,
                      style: textTheme.labelSmall?.copyWith(
                        color: isSelected ? colors.accentInk : colors.ink,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMidiCard(BuildContext context, WidgetRef ref) {
    final colors = PianoTheme.colorsOf(context);
    final textTheme = PianoTheme.textThemeOf(context);
    final midiService = ref.watch(midiServiceProvider);
    final selectedDevice = midiService.selectedDevice;

    return Container(
      padding: const EdgeInsets.all(PianoSpacing.md),
      decoration: BoxDecoration(
        color: colors.paper2,
        borderRadius: BorderRadius.circular(PianoRadius.md),
        border: Border.all(color: colors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                selectedDevice != null
                    ? Icons.piano_rounded
                    : Icons.piano_off_rounded,
                color: selectedDevice != null ? colors.success : colors.muted,
                size: 24,
              ),
              const SizedBox(width: PianoSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MIDI Keyboard (USB & Bluetooth)',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.ink,
                      ),
                    ),
                    Text(
                      selectedDevice != null
                          ? 'Connected: ${selectedDevice.name}'
                          : 'No external digital piano connected',
                      style: textTheme.bodySmall?.copyWith(
                        color: selectedDevice != null
                            ? colors.success
                            : colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                icon: midiService.isScanning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 16),
                label: Text(midiService.isScanning ? 'Scanning...' : 'Scan'),
                onPressed: midiService.isScanning
                    ? null
                    : () => midiService.scanDevices(),
              ),
            ],
          ),
          const SizedBox(height: PianoSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: PianoSpacing.sm),
          Text(
            'Available Interfaces:',
            style: textTheme.labelSmall?.copyWith(color: colors.muted),
          ),
          const SizedBox(height: PianoSpacing.xs),
          for (final device in midiService.devices)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    device.type == MidiDeviceType.usb
                        ? Icons.usb_rounded
                        : Icons.bluetooth_rounded,
                    size: 16,
                    color: colors.muted,
                  ),
                  const SizedBox(width: PianoSpacing.xs),
                  Expanded(
                    child: Text(
                      device.name,
                      style: textTheme.bodySmall?.copyWith(color: colors.ink),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (device.connected) {
                        midiService.disconnectDevice();
                      } else {
                        midiService.connectDevice(device.id);
                      }
                    },
                    child: Text(device.connected ? 'Disconnect' : 'Connect'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: PianoSpacing.xs),
          OutlinedButton.icon(
            icon: const Icon(Icons.play_circle_outline, size: 16),
            label: const Text('Test Key Press (Middle C / 60)'),
            onPressed: () {
              midiService.simulateNotePress(60);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Simulated MIDI Note On: Middle C (60)'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMicCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<bool> audioGrantedAsync,
  ) {
    final colors = PianoTheme.colorsOf(context);
    final textTheme = PianoTheme.textThemeOf(context);

    final isGranted = audioGrantedAsync.whenOrNull(data: (d) => d) == true;

    return Container(
      padding: const EdgeInsets.all(PianoSpacing.md),
      decoration: BoxDecoration(
        color: colors.paper2,
        borderRadius: BorderRadius.circular(PianoRadius.md),
        border: Border.all(color: colors.rule),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(PianoSpacing.sm),
            decoration: BoxDecoration(
              color: (isGranted ? colors.success : colors.error).withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGranted ? Icons.mic : Icons.mic_off,
              color: isGranted ? colors.success : colors.error,
              size: 24,
            ),
          ),
          const SizedBox(width: PianoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Microphone Permission',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.ink,
                  ),
                ),
                Text(
                  isGranted
                      ? 'Microphone access granted. Ready for pitch listening.'
                      : 'Permission not granted. Notes cannot be heard.',
                  style: textTheme.bodySmall?.copyWith(
                    color: isGranted ? colors.success : colors.error,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              ref.invalidate(audioGrantedProvider);
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.rule),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(
              'Test / Refresh',
              style: textTheme.labelSmall?.copyWith(color: colors.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioEngineSpecsCard(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final textTheme = PianoTheme.textThemeOf(context);

    final specs = [
      ('Algorithm', 'YIN (cumulative mean normalized difference)'),
      ('Sub-Sample Interpolation', 'Parabolic dip refinement'),
      ('Sample Rate & Buffer', '44.1 kHz / 2048 sample buffer'),
      ('Frequency Filter Window', '80 Hz – 1000 Hz (piano range E2 to C6)'),
      ('Confidence Floor', '≥ 70% autocorrelation confidence'),
    ];

    return Container(
      padding: const EdgeInsets.all(PianoSpacing.md),
      decoration: BoxDecoration(
        color: colors.paper2,
        borderRadius: BorderRadius.circular(PianoRadius.md),
        border: Border.all(color: colors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pitch Detection Parameters',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: PianoSpacing.xs),
          Text(
            'Hardware-independent real-time audio pipeline',
            style: textTheme.bodySmall?.copyWith(color: colors.muted),
          ),
          const SizedBox(height: PianoSpacing.sm),
          ...specs.map((s) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      s.$1,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      s.$2,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBackendCard(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final textTheme = PianoTheme.textThemeOf(context);

    final details = [
      ('Inference Engine', 'Spotify Basic Pitch (ONNX Runtime CPU)'),
      ('Audio Acquisition', 'yt-dlp, multipart audio uploads, in-app mic'),
      ('Tempo & Grid', 'librosa.beat.beat_track (16th-note quantization)'),
      ('Worker Infrastructure', 'FastAPI daemon + SQLite-WAL spooled worker'),
    ];

    return Container(
      padding: const EdgeInsets.all(PianoSpacing.md),
      decoration: BoxDecoration(
        color: colors.paper2,
        borderRadius: BorderRadius.circular(PianoRadius.md),
        border: Border.all(color: colors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_done_outlined, size: 18, color: colors.accent),
              const SizedBox(width: PianoSpacing.xs),
              Text(
                'Persistent Audio Ingestion Service',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: PianoSpacing.xs),
          Text(
            'Processes polyphonic piano recordings into playable level models',
            style: textTheme.bodySmall?.copyWith(color: colors.muted),
          ),
          const SizedBox(height: PianoSpacing.sm),
          ...details.map((d) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      d.$1,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      d.$2,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
