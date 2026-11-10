import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../brand/book_page.dart';
import '../brand/buttons.dart';
import '../brand/choices.dart';
import '../data/settings_repository.dart';

Route<void> settingsRoute() => fadeRoute((_) => const SettingsScreen());

/// The speeds a piece can start at: the same three the practice page cycles.
const startSpeeds = [(1.0, 'Full'), (0.75, 'Three quarters'), (0.5, 'Half')];

/// How the piano listens, how fast pieces start and how exact marking is.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final u = unitOf(context);
    final speed = startSpeeds
        .map((s) => s.$1)
        .firstWhere(
          (s) => (s - settings.defaultPlaybackSpeed).abs() < 0.01,
          orElse: () => 1.0,
        );
    return BookPage(
      title: 'Settings',
      child: ListView(
        padding: EdgeInsets.fromLTRB(40 * u, 32 * u, 40 * u, 48 * u),
        children: [
          const PageHeading('How do you play?'),
          SizedBox(height: 8 * u),
          Choices<PracticeInputSource>(
            options: [for (final s in PracticeInputSource.values) (s, s.label)],
            value: settings.inputSource,
            onChanged: notifier.setInputSource,
          ),
          SizedBox(height: 8 * u),
          PageText(settings.inputSource.description),
          SizedBox(height: 40 * u),
          const PageHeading('How fast should a piece start?'),
          SizedBox(height: 8 * u),
          Choices<double>(
            options: [for (final (v, label) in startSpeeds) (v, label)],
            value: speed,
            onChanged: notifier.setDefaultSpeed,
          ),
          SizedBox(height: 8 * u),
          const PageText(
            'You can change the speed while you play, one piece at a time.',
          ),
          SizedBox(height: 40 * u),
          const PageHeading('How exact should you be?'),
          SizedBox(height: 8 * u),
          Choices<ToleranceLevel>(
            options: [for (final t in ToleranceLevel.values) (t, t.label)],
            value: settings.toleranceLevel,
            onChanged: notifier.setToleranceLevel,
          ),
          SizedBox(height: 8 * u),
          PageText(settings.toleranceLevel.description),
          SizedBox(height: 40 * u),
          if (!settings.inputSource.usesTouch) ...[
          const PageHeading('Does it hear you?'),
          SizedBox(height: 8 * u),
          if (settings.verifiedInput == null)
            const PageText(
              'The next piece will ask you to play middle C first.',
            )
          else ...[
            const PageText(
              'Before your first piece it listens for middle C, once for '
              'each way of playing. Check again if you moved the microphone '
              'or changed piano.',
            ),
            SizedBox(height: 16 * u),
            Align(
              alignment: Alignment.centerLeft,
              child: QuietButton(
                label: 'Check again',
                onPressed: () => notifier.setVerifiedInput(null),
              ),
            ),
          ],
          ],
        ],
      ),
    );
  }
}
