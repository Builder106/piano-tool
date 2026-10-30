import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/settings_repository.dart';
import '../../services/midi_service.dart';
import '../desk/desk.dart';
import '../theme/tokens.dart';
import 'input_check.dart';
import 'stage_controller.dart';

/// Set when the learner skips the input check. A skip lasts for this
/// session and is never saved.
final inputCheckSkippedProvider = StateProvider<bool>((ref) => false);

/// Microphone and dual-input practice need permission. MIDI-only practice can
/// score without opening a recorder.
class MicPermissionGate extends ConsumerWidget {
  const MicPermissionGate({
    super.key,
    required this.child,
    this.startAudio = false,
  });

  final Widget child;
  final bool startAudio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    if (startAudio && !settings.inputConfigured) {
      return _InputChoice(
        onSelect: (source) =>
            ref.read(settingsProvider.notifier).setInputSource(source),
        onSettings: () => context.push('/settings'),
      );
    }
    if (startAudio && settings.inputSource == PracticeInputSource.midi) {
      return _CheckedInput(child: child);
    }

    // Invalidating rebuilds the provider from scratch, so a permission that
    // was denied and then granted from system settings recovers rather than
    // leaving the gate latched on its error state.
    void retry() {
      ref.invalidate(audioGrantedProvider);
      if (startAudio) ref.invalidate(practiceAudioSessionProvider);
    }

    final permission = ref.watch(audioGrantedProvider);
    final session = startAudio ? ref.watch(practiceAudioSessionProvider) : null;
    final state = startAudio ? session!.whenData((_) => true) : permission;

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _Denied(
        message:
            'The microphone could not be started. '
            'Check your browser or device permissions and try again.',
        onRetry: retry,
        onDigitalPiano: startAudio ? () => context.push('/settings') : null,
      ),
      data: (granted) => granted
          ? (startAudio ? _CheckedInput(child: child) : child)
          : _Denied(
              message:
                  'Piano Tool needs the microphone to hear what you play. '
                  'Without it, notes cannot be scored.',
              onRetry: retry,
              onDigitalPiano: startAudio
                  ? () => context.push('/settings')
                  : null,
            ),
    );
  }
}

/// Shows the input check until a note has been heard from this setup.
class _CheckedInput extends ConsumerWidget {
  const _CheckedInput({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    // Only the device identity: the service notifies on every message.
    final deviceId = ref.watch(
      midiServiceProvider.select((m) => m.selectedDevice?.id),
    );
    final key = inputCheckKey(settings.inputSource, deviceId);
    if (settings.verifiedInput == key || ref.watch(inputCheckSkippedProvider)) {
      return child;
    }

    final source = settings.inputSource;
    final usesMic = source != PracticeInputSource.midi;
    final usesMidi = source != PracticeInputSource.microphone;
    final engine = ref.read(audioEngineProvider);
    final midi = ref.read(midiServiceProvider);
    return InputCheck(
      key: ValueKey(key),
      source: source,
      pitchSources: [
        if (usesMic) engine.pitchStream,
        if (usesMidi) midi.pitchStream,
      ],
      levels: usesMic ? engine.levelStream : null,
      clearLevel: settings.minVolumeThreshold,
      midiConnected: deviceId != null,
      onHeard: () => ref.read(settingsProvider.notifier).setVerifiedInput(key),
      onSkip: () => ref.read(inputCheckSkippedProvider.notifier).state = true,
      onConnectPiano: () => context.push('/settings'),
    );
  }
}

class _InputChoice extends StatelessWidget {
  const _InputChoice({required this.onSelect, required this.onSettings});

  final ValueChanged<PracticeInputSource> onSelect;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(PianoSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: PaperSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How will you play?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: PianoSpacing.sm),
              const Text(
                'Choose how Piano Tool will hear your notes. You can change this in Settings.',
              ),
              const SizedBox(height: PianoSpacing.md),
              FilledButton(
                onPressed: () => onSelect(PracticeInputSource.microphone),
                child: const Text('Use microphone'),
              ),
              const SizedBox(height: PianoSpacing.xs),
              const Text('Listen to an acoustic or digital piano.'),
              const SizedBox(height: PianoSpacing.sm),
              OutlinedButton(
                onPressed: () {
                  onSelect(PracticeInputSource.midi);
                  onSettings();
                },
                child: const Text('Connect a digital piano'),
              ),
              const SizedBox(height: PianoSpacing.xs),
              const Text('Connect over USB or Bluetooth in Settings.'),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Denied extends StatelessWidget {
  const _Denied({
    required this.message,
    required this.onRetry,
    this.onDigitalPiano,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onDigitalPiano;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(PianoSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: PaperSheet(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No microphone', style: text.headlineSmall),
                const SizedBox(height: PianoSpacing.xs),
                Text(message, style: text.bodyMedium),
                const SizedBox(height: PianoSpacing.md),
                Wrap(
                  spacing: PianoSpacing.sm,
                  children: [
                    FilledButton(
                      onPressed: onRetry,
                      child: const Text('Try again'),
                    ),
                    // A permanently denied permission never prompts again, so
                    // retry alone would be a dead end.
                    TextButton(
                      // openAppSettings() reports whether it could open the
                      // settings screen; a plain tear-off would discard that
                      // exactly like the boolean this task exists to stop
                      // ignoring, so a failure is at least logged.
                      onPressed: () async {
                        final opened = await openAppSettings();
                        if (!opened) {
                          debugPrint(
                            'MicPermissionGate: could not open app settings',
                          );
                        }
                      },
                      child: const Text('Open settings'),
                    ),
                    if (onDigitalPiano != null)
                      TextButton(
                        onPressed: onDigitalPiano,
                        child: const Text('Use a digital piano'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
