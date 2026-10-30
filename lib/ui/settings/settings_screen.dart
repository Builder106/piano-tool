import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/settings_repository.dart';
import '../../services/midi_service.dart';
import '../desk/desk.dart';
import '../desk/pencil_choices.dart';
import '../desk/pencil_mark.dart';
import '../practice/stage_controller.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Settings: how practice plays and how the app hears your piano, on two
/// sheets on the desk.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final audioGrantedAsync = settings.inputSource == PracticeInputSource.midi
        ? const AsyncData(false)
        : ref.watch(audioGrantedProvider);

    final colors = PianoTheme.colorsOf(context);
    final practice = PaperSheet(
      tilt: -0.5,
      clipped: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetTitle('Practice'),
          _Section(
            title: 'Starting speed',
            note: 'How fast a stage plays when you open it.',
            child: Row(
              children: [
                PencilMark(Pencil.tortoise, color: colors.muted, width: 64),
                const SizedBox(width: PianoSpacing.xs),
                Expanded(
                  child: _speedChoices(
                    context,
                    ref,
                    settings.defaultPlaybackSpeed,
                  ),
                ),
                const SizedBox(width: PianoSpacing.xs),
                PencilMark(Pencil.hare, color: colors.muted, width: 64),
              ],
            ),
          ),
          _Section(
            title: 'Timing',
            note: settings.toleranceLevel.description,
            doodle: PencilMark(
              Pencil.metronome,
              color: colors.muted,
              height: 64,
            ),
            child: _toleranceChoices(context, ref, settings.toleranceLevel),
          ),
          _Section(
            title: 'Listen with',
            note: settings.inputSource.description,
            child: _inputChoices(context, ref, settings.inputSource),
          ),
          _Section(
            title: 'Lamp',
            note: 'A low lamp dims the paper for practising in a dark room.',
            last: true,
            doodle: _LampDoodle(mode: settings.themeMode),
            child: _lampChoices(context, ref, settings.themeMode),
          ),
        ],
      ),
    );

    final piano = PaperSheet(
      tilt: 0.7,
      clipped: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetTitle('Your piano'),
          _Section(
            title: 'Microphone',
            doodle: PencilMark(Pencil.listen, color: colors.muted, height: 60),
            child: _MicStatus(audioGrantedAsync: audioGrantedAsync),
          ),
          _Section(
            title: 'Digital piano (USB or Bluetooth)',
            last: true,
            doodle: PencilMark(Pencil.plug, color: colors.muted, height: 52),
            child: const _MidiPanel(),
          ),
        ],
      ),
    );

    return DeskScaffold(
      title: 'Settings',
      subtitle: 'How practice plays and how Piano Tool hears you',
      backTooltip: 'Back',
      onBack: () => context.pop(),
      body: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          // Room at the top for the page clips.
          padding: const EdgeInsets.fromLTRB(
            PianoSpacing.lg,
            PianoSpacing.lg,
            PianoSpacing.lg,
            PianoSpacing.xl,
          ),
          child: box.maxWidth >= 760
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: practice),
                    const SizedBox(width: PianoSpacing.lg),
                    Expanded(child: piano),
                  ],
                )
              : Column(
                  children: [
                    practice,
                    const SizedBox(height: PianoSpacing.xl),
                    piano,
                  ],
                ),
        ),
      ),
    );
  }

  Widget _speedChoices(BuildContext context, WidgetRef ref, double current) {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    return PencilChoices<double>(
      values: speeds,
      selected: speeds.firstWhere(
        (s) => (current - s).abs() < 0.01,
        orElse: () => 1.0,
      ),
      label: (s) => '${s}x',
      onSelected: (s) => ref.read(settingsProvider.notifier).setDefaultSpeed(s),
    );
  }

  Widget _toleranceChoices(
    BuildContext context,
    WidgetRef ref,
    ToleranceLevel current,
  ) => PencilChoices<ToleranceLevel>(
    values: ToleranceLevel.values,
    selected: current,
    label: (level) => level.label,
    onSelected: (level) =>
        ref.read(settingsProvider.notifier).setToleranceLevel(level),
  );

  Widget _inputChoices(
    BuildContext context,
    WidgetRef ref,
    PracticeInputSource current,
  ) => PencilChoices<PracticeInputSource>(
    values: PracticeInputSource.values,
    selected: current,
    label: (s) => s.label,
    onSelected: (s) => ref.read(settingsProvider.notifier).setInputSource(s),
  );

  Widget _lampChoices(BuildContext context, WidgetRef ref, ThemeMode current) =>
      PencilChoices<ThemeMode>(
        values: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
        selected: current,
        label: (m) => switch (m) {
          ThemeMode.system => 'Follow the device',
          ThemeMode.light => 'Bright',
          ThemeMode.dark => 'Low',
        },
        onSelected: (m) => ref.read(settingsProvider.notifier).setThemeMode(m),
      );
}

/// The desk lamp in the margin: full light when bright, a glimmer when it
/// follows the device, dark when low. The light redraws when you switch.
class _LampDoodle extends StatelessWidget {
  const _LampDoodle({required this.mode});

  final ThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    const height = 64.0;
    return Stack(
      children: [
        PencilMark(Pencil.lamp, color: colors.muted, height: height),
        if (mode != ThemeMode.dark)
          PencilMark(
            Pencil.lampRays,
            key: ValueKey(mode),
            color: mode == ThemeMode.light
                ? colors.accent
                : colors.accent.withValues(alpha: 0.45),
            height: height,
            drawOn: true,
            duration: const Duration(milliseconds: 360),
          ),
      ],
    );
  }
}

/// A sheet's printed heading.
class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: PianoSpacing.md),
    child: Text(title, style: PianoTheme.textThemeOf(context).headlineLarge),
  );
}

/// One setting: a heading, an optional line saying what it does, the control.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.note,
    this.doodle,
    this.last = false,
  });

  final String title;
  final String? note;
  final Widget child;

  /// A pencil drawing in the margin beside the heading.
  final Widget? doodle;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final text = PianoTheme.textThemeOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : PianoSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleLarge),
                    if (note != null)
                      Text(
                        note!,
                        style: text.bodySmall?.copyWith(color: colors.muted),
                      ),
                  ],
                ),
              ),
              ?doodle,
            ],
          ),
          const SizedBox(height: PianoSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _MicStatus extends ConsumerWidget {
  const _MicStatus({required this.audioGrantedAsync});

  final AsyncValue<bool> audioGrantedAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = PianoTheme.colorsOf(context);
    final text = PianoTheme.textThemeOf(context);
    final granted = audioGrantedAsync.whenOrNull(data: (d) => d) == true;
    final midiOnly =
        ref.watch(settingsProvider).inputSource == PracticeInputSource.midi;

    return Row(
      children: [
        Icon(
          granted ? Icons.mic_rounded : Icons.mic_off_rounded,
          color: granted ? colors.success : colors.error,
        ),
        const SizedBox(width: PianoSpacing.sm),
        Expanded(
          child: Text(
            midiOnly
                ? 'Microphone is not needed for digital piano practice.'
                : granted
                ? 'On. Piano Tool can hear your piano.'
                : 'Off. Allow the microphone so Piano Tool can hear you play.',
            style: text.bodyMedium?.copyWith(
              color: granted ? colors.success : colors.error,
            ),
          ),
        ),
        TextButton(
          onPressed: () => ref.invalidate(audioGrantedProvider),
          child: const Text('Check again'),
        ),
      ],
    );
  }
}

class _MidiPanel extends ConsumerWidget {
  const _MidiPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = PianoTheme.colorsOf(context);
    final text = PianoTheme.textThemeOf(context);
    final midiService = ref.watch(midiServiceProvider);
    final selectedDevice = midiService.selectedDevice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              selectedDevice != null
                  ? Icons.piano_rounded
                  : Icons.piano_off_rounded,
              color: selectedDevice != null ? colors.success : colors.muted,
            ),
            const SizedBox(width: PianoSpacing.sm),
            Expanded(
              child: Text(
                selectedDevice != null
                    ? 'Connected: ${selectedDevice.name}'
                    : 'None connected',
                style: text.bodyMedium?.copyWith(
                  color: selectedDevice != null ? colors.success : colors.muted,
                ),
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
              label: Text(midiService.isScanning ? 'Looking...' : 'Look again'),
              onPressed: midiService.isScanning
                  ? null
                  : () => midiService.scanDevices(),
            ),
          ],
        ),
        if (midiService.error case final error?)
          Padding(
            padding: const EdgeInsets.only(top: PianoSpacing.xs),
            child: Text(
              error,
              style: text.bodySmall?.copyWith(color: colors.error),
            ),
          ),
        const SizedBox(height: PianoSpacing.sm),
        if (midiService.devices.isEmpty)
          Text(
            'Plug in or pair your digital piano, then press Look again.',
            style: text.bodySmall?.copyWith(color: colors.muted),
          ),
        for (final device in midiService.devices)
          Row(
            children: [
              Icon(
                switch (device.type) {
                  MidiDeviceType.usb => Icons.usb_rounded,
                  MidiDeviceType.bluetooth => Icons.bluetooth_rounded,
                  MidiDeviceType.other => Icons.piano_rounded,
                },
                size: 16,
                color: colors.muted,
              ),
              const SizedBox(width: PianoSpacing.xs),
              Expanded(child: Text(device.name, style: text.bodyMedium)),
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
        const SizedBox(height: PianoSpacing.xs),
        OutlinedButton.icon(
          icon: const Icon(Icons.play_circle_outline, size: 16),
          label: const Text('Test with middle C'),
          onPressed: () {
            midiService.simulateNotePress(60);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sent a test middle C'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
    );
  }
}
