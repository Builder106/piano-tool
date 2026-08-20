import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/ui/staff/staff_geometry.dart';

void main() {
  // A staff 80px tall starting at y=10: 4 spaces of 20px each.
  const g = StaffGeometry(top: 10, height: 80);

  test('one space is a quarter of the staff height', () {
    expect(g.space, 20);
  });

  test('lines run top to bottom at even spacing', () {
    expect(g.lineY(0), 10);   // top line
    expect(g.lineY(4), 90);   // bottom line
    expect(g.topLineY, 10);
    expect(g.bottomLineY, 90);
  });

  group('treble clef', () {
    test('E4 sits on the bottom line', () {
      expect(g.yForMidi(64, Clef.treble), 90);
    });
    test('F5 sits on the top line', () {
      expect(g.yForMidi(77, Clef.treble), 10);
    });
    test('C4 sits one ledger line below the staff', () {
      // C4 is 2 diatonic steps below E4, so one full space below the bottom line.
      expect(g.yForMidi(60, Clef.treble), 110);
      expect(g.ledgerLinesFor(60, Clef.treble), [110.0]);
    });
    test('a note inside the staff needs no ledger lines', () {
      expect(g.ledgerLinesFor(71, Clef.treble), isEmpty);
    });
    test('accidentals share a line with their natural', () {
      // F#5 and F5 occupy the same staff position.
      expect(g.yForMidi(78, Clef.treble), g.yForMidi(77, Clef.treble));
    });
  });

  group('bass clef', () {
    test('G2 sits on the bottom line', () {
      expect(g.yForMidi(43, Clef.bass), 90);
    });
    test('A3 sits on the top line', () {
      expect(g.yForMidi(57, Clef.bass), 10);
    });
    test('C4 sits one ledger line above the staff', () {
      // C4 is 10 diatonic steps above G2, one full space above the top line.
      expect(g.yForMidi(60, Clef.bass), -10);
      expect(g.ledgerLinesFor(60, Clef.bass), [-10.0]);
    });
  });

  test('glyph sizes are expressed in staff spaces', () {
    expect(g.noteheadSize.height, g.space);
    expect(g.noteheadSize.width, closeTo(g.space * 1.3, 0.001));
    expect(g.stemLength, g.space * 3.5);
    expect(g.timeSignatureFontSize, g.space * 2);
  });

  test('halving the staff halves every derived measurement', () {
    const half = StaffGeometry(top: 0, height: 40);
    expect(half.space, g.space / 2);
    expect(half.noteheadSize.height, g.noteheadSize.height / 2);
    expect(half.clefFontSize(Clef.treble), g.clefFontSize(Clef.treble) / 2);
  });
}
