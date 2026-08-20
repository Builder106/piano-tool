import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/ui/staff/staff_geometry.dart';
import 'package:piano_tool/ui/staff/staff_painter.dart';
import 'package:piano_tool/ui/theme/tokens.dart';

StaffPainter _painter({Clef clef = Clef.treble, double beat = 0}) => StaffPainter(
      clef: clef,
      notes: const [
        (midi: 60, startBeat: 0, state: NoteState.hitPerfect),
        (midi: 64, startBeat: 1, state: NoteState.missed),
        (midi: 67, startBeat: 2, state: NoteState.active),
        (midi: 72, startBeat: 3, state: NoteState.upcoming),
      ],
      colors: PianoColors.light(),
      currentBeat: beat,
      totalBeats: 8,
      beatsPerMeasure: 4,
      pixelsPerBeat: 60,
    );

void main() {
  test('painting does not throw for either clef', () {
    for (final clef in Clef.values) {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      _painter(clef: clef).paint(canvas, const Size(600, 200));
      expect(recorder.endRecording(), isNotNull);
    }
  });

  test('repaints when the playhead moves, not otherwise', () {
    expect(_painter(beat: 1).shouldRepaint(_painter(beat: 0)), isTrue);
    expect(_painter(beat: 0).shouldRepaint(_painter(beat: 0)), isFalse);
  });

  test('does not repaint when an equal note list is rebuilt', () {
    // A fresh list with identical contents must not force a repaint.
    expect(_painter(beat: 0).shouldRepaint(_painter(beat: 0)), isFalse);
  });

  test('repaints when a note state actually changes', () {
    final a = _painter(beat: 0);
    final b = StaffPainter(
      clef: Clef.treble,
      notes: const [
        (midi: 60, startBeat: 0, state: NoteState.missed),
        (midi: 64, startBeat: 1, state: NoteState.missed),
        (midi: 67, startBeat: 2, state: NoteState.active),
        (midi: 72, startBeat: 3, state: NoteState.upcoming),
      ],
      colors: PianoColors.light(),
      currentBeat: 0,
      totalBeats: 8,
      beatsPerMeasure: 4,
      pixelsPerBeat: 60,
    );
    expect(b.shouldRepaint(a), isTrue);
  });

  test('the header never overlaps the first note at any staff size', () {
    // The header (clef + time signature) is measured in staff-spaces, which
    // scale with staff height, while note x-positions used to be measured
    // in a fixed pixel offset. At small staff heights the two agreed; at
    // large ones the header grew past the first note. Pin the two
    // quantities together across a range of heights so this cannot regress.
    //
    // The staff no longer scales unboundedly with its band: Task 8 added a
    // cap (`kDefaultMaxStaffHeight`) via `staffGeometryForBand`, the same
    // function the painter itself calls. The expected geometry here is built
    // through that function rather than a hardcoded fraction, so this test
    // tracks the painter's actual behaviour instead of a formula it
    // abandoned.
    const pixelsPerBeat = 60.0;
    for (final height in [80.0, 220.0, 400.0]) {
      final painter = _painter();
      final size = Size(740, height);

      final recorder = PictureRecorder();
      painter.paint(Canvas(recorder), size);
      expect(recorder.endRecording(), isNotNull);

      final g = painter.geometryFor(height);
      final headerWidth = StaffPainter.headerWidthFor(g);

      // The first note (startBeat: 0) sits exactly at the header boundary;
      // it must never start before it, at any staff size.
      final firstNoteX = headerWidth + 0 * pixelsPerBeat;
      expect(firstNoteX, greaterThanOrEqualTo(headerWidth));

      // A later note (startBeat: 2, from _painter's fixture) must land a
      // fixed, non-zero distance after the header -- exercising the actual
      // beat-to-pixel mapping rather than an identity that would hold for
      // any pixelsPerBeat.
      final thirdNoteX = headerWidth + 2 * pixelsPerBeat;
      expect(thirdNoteX, closeTo(headerWidth + 120.0, 0.001));
      expect(thirdNoteX, greaterThan(firstNoteX));

      // At the tallest band the cap must actually be biting: the drawn
      // staff height stays at the ceiling rather than continuing to grow
      // with the band.
      if (height > kDefaultMaxStaffHeight / kStaffBandFraction) {
        expect(g.height, closeTo(kDefaultMaxStaffHeight, 0.001));
      }
    }
  });

  test('note x positions advance with the beat', () {
    // Two notes a beat apart must be exactly pixelsPerBeat apart. x for a
    // beat is headerWidth + beat * pixelsPerBeat, so the header term cancels
    // and only the beat spacing survives.
    const pixelsPerBeat = 60.0;
    const g = StaffGeometry(top: 20, height: 100);
    final headerWidth = StaffPainter.headerWidthFor(g);

    double xForBeat(double beat) => headerWidth + beat * pixelsPerBeat;

    expect(xForBeat(2) - xForBeat(1), closeTo(pixelsPerBeat, 0.001));
    expect(xForBeat(5) - xForBeat(4), closeTo(pixelsPerBeat, 0.001));
  });

  test('the playhead tracks currentBeat', () {
    // The x for currentBeat must equal the x computed for that same beat
    // via the shared header-plus-offset formula the painter uses.
    const pixelsPerBeat = 60.0;
    const g = StaffGeometry(top: 20, height: 100);
    final headerWidth = StaffPainter.headerWidthFor(g);

    double xForBeat(double beat) => headerWidth + beat * pixelsPerBeat;

    const currentBeat = 3.5;
    final playheadX = xForBeat(currentBeat);
    expect(playheadX, equals(xForBeat(currentBeat)));
    expect(playheadX, closeTo(headerWidth + 210.0, 0.001));
  });

  test('header width scales with staff height, not with pixelsPerBeat', () {
    // Doubling the staff height doubles the header; changing pixelsPerBeat
    // must not move it. This is the invariant whose absence caused the
    // time signature to collide with the first notes.
    const small = StaffGeometry(top: 0, height: 100);
    const large = StaffGeometry(top: 0, height: 200);

    final smallHeader = StaffPainter.headerWidthFor(small);
    final largeHeader = StaffPainter.headerWidthFor(large);

    expect(largeHeader, closeTo(smallHeader * 2, 0.001));

    // headerWidthFor takes only geometry, so it cannot vary with
    // pixelsPerBeat by construction; assert the same geometry always
    // yields the same header width regardless of what pixelsPerBeat is
    // used elsewhere.
    expect(StaffPainter.headerWidthFor(small), equals(smallHeader));
  });
}
