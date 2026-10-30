import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/ui/staff/staff_geometry.dart';
import 'package:piano_tool/ui/staff/staff_painter.dart';
import 'package:piano_tool/ui/staff/staff_view.dart';
import 'package:piano_tool/ui/theme/app_theme.dart';

PlacedNote _note(int midi, double beat, NoteState state) =>
    (midi: midi, startBeat: beat, durationBeats: 1, alter: null, state: state);

Widget _staff(List<PlacedNote> notes, {bool reduceMotion = false}) =>
    MaterialApp(
      theme: PianoTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: SizedBox(
          width: 600,
          height: 200,
          child: StaffView(
            systems: [(clef: Clef.treble, notes: notes)],
            currentBeat: 0,
            totalBeats: 8,
            beatsPerMeasure: 4,
            pixelsPerBeat: 60,
          ),
        ),
      ),
    );

StaffPainter _painter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find
                  .descendant(
                    of: find.byType(StaffView),
                    matching: find.byType(CustomPaint),
                  )
                  .first,
            )
            .painter!
        as StaffPainter;

void main() {
  final upcoming = [
    for (var i = 0; i < 4; i++)
      _note(60 + i * 2, i.toDouble(), NoteState.upcoming),
  ];
  final hit = [_note(60, 0, NoteState.hitGood), ...upcoming.skip(1)];

  testWidgets('a fresh hit is pencilled in over a moment', (tester) async {
    await tester.pumpWidget(_staff(upcoming));
    await tester.pumpWidget(_staff(hit));
    await tester.pump(const Duration(milliseconds: 100));
    final midway = _painter(tester).markProgress['60@0.0'];
    expect(midway, isNotNull);
    expect(midway, inExclusiveRange(0, 1));

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(_painter(tester).markProgress.containsKey('60@0.0'), isFalse);
  });

  testWidgets('with reduced motion the mark appears complete', (tester) async {
    await tester.pumpWidget(_staff(upcoming, reduceMotion: true));
    await tester.pumpWidget(_staff(hit, reduceMotion: true));
    await tester.pump(const Duration(milliseconds: 50));
    expect(_painter(tester).markProgress, isEmpty);
  });

  testWidgets('a measure played clean gets its tick drawn in', (tester) async {
    await tester.pumpWidget(_staff(upcoming));
    await tester.pumpWidget(
      _staff([
        for (final n in upcoming)
          _note(n.midi, n.startBeat, NoteState.hitPerfect),
      ]),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(_painter(tester).markProgress['m0'], inExclusiveRange(0, 1));
    await tester.pump(const Duration(seconds: 1));
  });

  test('a measure is clean only once every note in it is hit', () {
    expect(cleanMeasures(hit, beatsPerMeasure: 4), isEmpty);
    expect(
      cleanMeasures([
        for (final n in upcoming) _note(n.midi, n.startBeat, NoteState.hitOkay),
      ], beatsPerMeasure: 4),
      {0},
    );
    expect(
      cleanMeasures([
        _note(60, 0, NoteState.hitGood),
        _note(62, 1, NoteState.missed),
      ], beatsPerMeasure: 4),
      isEmpty,
    );
  });
}
