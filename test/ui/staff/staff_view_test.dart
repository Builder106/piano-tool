import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/ui/staff/staff_geometry.dart';
import 'package:piano_tool/ui/staff/staff_painter.dart';
import 'package:piano_tool/ui/staff/staff_view.dart';
import 'package:piano_tool/ui/theme/app_theme.dart';

const _treble = (
  clef: Clef.treble,
  notes: <PlacedNote>[
    (midi: 60, startBeat: 0, state: NoteState.hitPerfect),
    (midi: 64, startBeat: 1, state: NoteState.missed),
    (midi: 67, startBeat: 2, state: NoteState.active),
    (midi: 72, startBeat: 3, state: NoteState.upcoming),
  ]
);
const _bass = (
  clef: Clef.bass,
  notes: <PlacedNote>[
    (midi: 48, startBeat: 0, state: NoteState.hitGood),
    (midi: 55, startBeat: 2, state: NoteState.upcoming),
  ]
);

Widget _harness(ThemeData theme, List<StaffSystem> systems) => MaterialApp(
      theme: theme,
      home: Scaffold(
        body: SizedBox(
          width: 740,
          height: 220,
          child: StaffView(
            systems: systems,
            currentBeat: 2,
            totalBeats: 8,
            beatsPerMeasure: 4,
            pixelsPerBeat: 70,
          ),
        ),
      ),
    );

/// Pins the test surface to the widget's own size so captured goldens are
/// all signal, with no empty margin from the default 800x600 test surface.
Future<void> _pinSurfaceSize(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(740, 220));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  testWidgets('the staff never grows past its cap in a tall band',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(740, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      theme: PianoTheme.light(),
      home: const Scaffold(
        body: SizedBox(
          width: 740,
          height: 400,
          child: StaffView(
            systems: [_treble],
            currentBeat: 2,
            totalBeats: 8,
            beatsPerMeasure: 4,
            pixelsPerBeat: 70,
            maxStaffHeight: 120,
          ),
        ),
      ),
    ));

    final view = tester.widget<StaffView>(find.byType(StaffView));
    expect(tester.getSize(find.byType(StaffView)).height, 400);

    // The painted staff, not the band, is what is capped: 400 * 0.56 would
    // be 224, and a staff that tall makes a clef taller than the keyboard.
    final g = view.geometryFor(400);
    expect(g.height, 120);
    // ...and it is centred in the band it was given.
    expect(g.top, closeTo((400 - 120) / 2, 1e-9));
  });

  testWidgets('a short band still scales the staff down', (tester) async {
    const view = StaffView(
      systems: [_treble],
      currentBeat: 0,
      totalBeats: 8,
      beatsPerMeasure: 4,
      pixelsPerBeat: 70,
    );
    expect(view.geometryFor(100).height, closeTo(56, 1e-9));
  });

  testWidgets('renders a single staff without overflow', (tester) async {
    await _pinSurfaceSize(tester);
    await tester.pumpWidget(_harness(PianoTheme.light(), const [_treble]));
    expect(tester.takeException(), isNull);
    expect(find.byType(StaffView), findsOneWidget);
  });

  testWidgets('renders a grand staff without overflow', (tester) async {
    await _pinSurfaceSize(tester);
    await tester
        .pumpWidget(_harness(PianoTheme.light(), const [_treble, _bass]));
    expect(tester.takeException(), isNull);
  });

  // Goldens are byte-exact and font rasterisation differs by host, so these
  // are generated and verified on Linux (where CI runs) only. They are
  // skipped elsewhere rather than run with a fuzzy comparator, to keep the
  // checked-in PNGs an exact, unambiguous reference.
  testWidgets(
    'golden: single staff, light',
    (tester) async {
      await _pinSurfaceSize(tester);
      await tester.pumpWidget(_harness(PianoTheme.light(), const [_treble]));
      await expectLater(find.byType(StaffView),
          matchesGoldenFile('goldens/staff_single_light.png'));
    },
    skip: !Platform.isLinux,
  );

  testWidgets(
    'golden: single staff, dark',
    (tester) async {
      await _pinSurfaceSize(tester);
      await tester.pumpWidget(_harness(PianoTheme.dark(), const [_treble]));
      await expectLater(find.byType(StaffView),
          matchesGoldenFile('goldens/staff_single_dark.png'));
    },
    skip: !Platform.isLinux,
  );

  testWidgets(
    'golden: grand staff, light',
    (tester) async {
      await _pinSurfaceSize(tester);
      await tester
          .pumpWidget(_harness(PianoTheme.light(), const [_treble, _bass]));
      await expectLater(find.byType(StaffView),
          matchesGoldenFile('goldens/staff_grand_light.png'));
    },
    skip: !Platform.isLinux,
  );
}
