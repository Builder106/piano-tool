import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:piano_tool/data/level_repository.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/ui/keyboard/keyboard_geometry.dart';
import 'package:piano_tool/ui/keyboard/piano_keyboard_view.dart';
import 'package:piano_tool/ui/practice/practice_hud.dart';
import 'package:piano_tool/ui/practice/practice_screen.dart';
import 'package:piano_tool/ui/practice/stage_controller.dart';
import 'package:piano_tool/ui/practice/transport_column.dart';
import 'package:piano_tool/ui/staff/staff_view.dart';
import 'package:piano_tool/ui/theme/app_theme.dart';

Widget _screen({double textScale = 1.0}) => MaterialApp(
      theme: PianoTheme.light(),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: const PracticeScreen(stageId: 'stage_1'),
        ),
      ),
    );

Widget _harness({double textScale = 1.0}) => ProviderScope(
      overrides: [
        audioGrantedProvider.overrideWith((ref) async => true),
        // stageControllerProvider reads levelRepositoryProvider
        // synchronously (requireValue); PracticeScreen is mounted directly
        // here, without going through LevelListScreen first, so nothing
        // else resolves it.
        levelRepositoryProvider
            .overrideWith((ref) => SynchronousFuture(LevelRepository())),
      ],
      child: _screen(textScale: textScale),
    );

/// The screen's own stage has short metrics, so the two header tests drive the
/// HUD directly with the widest values it can ever hold: a fast tempo, a six
/// figure score, and full accuracy.
Widget _hud({required double textScale, required double width}) => MaterialApp(
      theme: PianoTheme.light(),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: const PracticeHud(
                title: 'C Major Scale',
                tempo: 200,
                score: 999999,
                accuracy: 1.0,
                progress: 0.5,
              ),
            ),
          ),
        ),
      ),
    );

/// Landscape sizes that bracket real phones, including the narrowest.
const _sizes = [Size(640, 360), Size(740, 360), Size(915, 412)];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final size in _sizes) {
    testWidgets('renders without overflow at ${size.width}x${size.height}',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_harness());
      await tester.pump();

      // A RenderFlex overflow surfaces as a thrown exception in tests, which
      // is exactly the failure the old screen shipped.
      expect(tester.takeException(), isNull);
    });
  }

  for (final scale in [2.0, 3.0]) {
    testWidgets('renders without overflow at a text scale of $scale',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(640, 360));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // An accessibility text scale doubles the width of every metric. The
      // header must absorb that rather than throw.
      await tester.pumpWidget(_harness(textScale: scale));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('BPM'), findsOneWidget);
      expect(find.textContaining('Score'), findsOneWidget);
      expect(find.textContaining('Acc'), findsOneWidget);
    });
  }

  testWidgets('the header absorbs a large text scale instead of overflowing',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // 580 is the header's usable width on the narrowest phone once the
    // transport column is taken out.
    await tester.pumpWidget(_hud(textScale: 3.0, width: 580));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('BPM'), findsOneWidget);
    expect(find.textContaining('Score'), findsOneWidget);
    expect(find.textContaining('Acc'), findsOneWidget);
  });

  testWidgets('the header grows for tall text rather than clipping it',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_hud(textScale: 1.0, width: 580));
    await tester.pump();
    expect(tester.getSize(find.byType(PracticeHud)).height,
        greaterThanOrEqualTo(PracticeHud.minHeight));

    await tester.pumpWidget(_hud(textScale: 3.0, width: 580));
    await tester.pump();
    // Pinned at 44 the tripled text would paint outside its own header.
    expect(tester.getSize(find.byType(PracticeHud)).height,
        greaterThan(PracticeHud.minHeight + 20));
  });

  testWidgets('shows the staff, the keyboard, and the transport',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(740, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_harness());
    await tester.pump();

    expect(find.byType(StaffView), findsOneWidget);
    expect(find.byType(PianoKeyboardView), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('the title yields to the metrics rather than pushing them off',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_harness());
    await tester.pump();

    // Every metric stays on screen even at the narrowest width; the title is
    // the thing that ellipsizes.
    expect(find.textContaining('BPM'), findsOneWidget);
    expect(find.textContaining('Score'), findsOneWidget);
    expect(find.textContaining('Acc'), findsOneWidget);
  });

  testWidgets('all 61 keys fit across the pane at a legible width',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_harness());
    await tester.pump();

    final size = tester.getSize(find.byType(PianoKeyboardView));
    expect(size.width, 640 - TransportColumn.width);

    // The keys are laid out from the pane width, so assert the real geometry:
    // the last white key ends exactly at the right edge, and no key is so thin
    // that "fits" would mean "unreadable".
    final geometry = KeyboardGeometry(width: size.width, height: size.height);
    expect(geometry.whiteKeyWidth, greaterThan(12));
    expect(
      geometry.whiteKeyRect(KeyboardGeometry.whiteKeyCount - 1).right,
      moreOrLessEquals(size.width),
    );
  });

  testWidgets('the speed control cycles through every step and wraps',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(740, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_harness());
    await tester.pump();

    expect(find.text('1.0x'), findsOneWidget);

    // The label is small; the target is not.
    final target = tester.getSize(find
        .ancestor(
          of: find.text('1.0x'),
          matching: find.byType(Container),
        )
        .first);
    expect(target.width, greaterThanOrEqualTo(48));
    expect(target.height, greaterThanOrEqualTo(48));

    var current = '1.0x';
    for (final expected in ['1.5x', '2.0x', '0.5x', '0.75x', '1.0x']) {
      await tester.tap(find.text(current));
      await tester.pump();
      expect(find.text(expected), findsOneWidget);
      current = expected;
    }
  });

  testWidgets('finishing a stage shows a completion SnackBar', (tester) async {
    await tester.binding.setSurfaceSize(const Size(740, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [
        audioGrantedProvider.overrideWith((ref) async => true),
        // stageControllerProvider reads levelRepositoryProvider
        // synchronously (requireValue); PracticeScreen is mounted directly
        // here, without going through LevelListScreen first, so nothing
        // else resolves it.
        levelRepositoryProvider
            .overrideWith((ref) => SynchronousFuture(LevelRepository())),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: _screen()),
    );
    // The permission gate resolves a frame after the first build.
    await tester.pump();
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();

    // stage_1 is 4 measures of 4 beats at 80 BPM: 16 beats at 80/60 beats
    // per second is well under 13 seconds to run out the clock, past every
    // note being marked missed and the engine reaching `completed`.
    await tester.pump(const Duration(seconds: 13));
    await tester.pump();

    expect(container.read(engineStatusProvider('stage_1')),
        StageEngineStatus.completed);
    // The legacy screen's "Stage Completed!" dialog was deleted along with
    // it and nothing replaced it; this SnackBar is the smallest thing that
    // closes that regression.
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Stage complete'), findsOneWidget);
  });

  testWidgets('leaving the screen stops the engine', (tester) async {
    await tester.binding.setSurfaceSize(const Size(740, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [
        audioGrantedProvider.overrideWith((ref) async => true),
        // stageControllerProvider reads levelRepositoryProvider
        // synchronously (requireValue); PracticeScreen is mounted directly
        // here, without going through LevelListScreen first, so nothing
        // else resolves it.
        levelRepositoryProvider
            .overrideWith((ref) => SynchronousFuture(LevelRepository())),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: _screen()),
    );
    // The permission gate resolves a frame after the first build; the transport
    // is not on screen until it does.
    await tester.pump();
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    expect(container.read(engineStatusProvider('stage_1')),
        StageEngineStatus.playing);

    // Navigating away must not leave a periodic timer marking notes missed.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(container.read(engineStatusProvider('stage_1')),
        StageEngineStatus.stopped);
  });
}
