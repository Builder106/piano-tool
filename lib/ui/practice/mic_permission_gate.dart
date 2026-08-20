import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/tokens.dart';
import 'stage_controller.dart';

/// Practice needs the microphone, so a denial has to be visible. The previous
/// screen ignored the permission result and simply never scored anything.
class MicPermissionGate extends ConsumerWidget {
  const MicPermissionGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Invalidating rebuilds the provider from scratch, so a permission that
    // was denied and then granted from system settings recovers rather than
    // leaving the gate latched on its error state.
    void retry() => ref.invalidate(audioGrantedProvider);

    return ref.watch(audioGrantedProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _Denied(
            message: 'The microphone could not be started. '
                'Piano Tool listens for the notes you play, so practice needs it.',
            onRetry: retry,
          ),
          data: (granted) => granted
              ? child
              : _Denied(
                  message:
                      'Piano Tool needs the microphone to hear what you play. '
                      'Without it, notes cannot be scored.',
                  onRetry: retry,
                ),
        );
  }
}

class _Denied extends StatelessWidget {
  const _Denied({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(PianoSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('No microphone', style: text.headlineSmall),
              const SizedBox(height: PianoSpacing.xs),
              Text(message, style: text.bodyMedium),
              const SizedBox(height: PianoSpacing.md),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(
                      onPressed: onRetry, child: const Text('Try again')),
                  const SizedBox(width: PianoSpacing.sm),
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
                            'MicPermissionGate: could not open app settings');
                      }
                    },
                    child: const Text('Open settings'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
