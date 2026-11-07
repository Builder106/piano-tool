import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/practice/notation.dart';

void main() {
  test('treble steps count from the bottom line', () {
    expect(trebleStep(64), 0); // E4
    expect(trebleStep(60), -2); // middle C, on a ledger line
    expect(trebleStep(71), 4); // B4, the middle line
    expect(trebleStep(77), 8); // F5, the top line
  });

  test('black keys are sharps unless spelt as flats', () {
    expect(trebleStep(61), -2);
    expect(accidentalFor(61), Accidental.sharp);
    expect(trebleStep(61, alter: -1), -1);
    expect(accidentalFor(61, alter: -1), Accidental.flat);
    expect(accidentalFor(62), Accidental.none);
  });

  test('durations map to the nearest written value', () {
    expect(writtenValue(1), (value: NoteValue.quarter, dotted: false));
    expect(writtenValue(3), (value: NoteValue.half, dotted: true));
    expect(writtenValue(0.5), (value: NoteValue.eighth, dotted: false));
    expect(writtenValue(1, beatUnit: 8), (
      value: NoteValue.eighth,
      dotted: false,
    ));
  });

  test('ledger lines and stems', () {
    expect(ledgerSteps(-2), [-2]);
    expect(ledgerSteps(-4), [-2, -4]);
    expect(ledgerSteps(11), [10]);
    expect(ledgerSteps(3), isEmpty);
    expect(stemUp(3), isTrue);
    expect(stemUp(4), isFalse);
  });

  test('a note rings its line, or both lines round its space', () {
    expect(ringingLines(2), [1]);
    expect(ringingLines(3), [1, 2]);
    expect(ringingLines(-2), [0]);
    expect(ringingLines(9), [4]);
  });
}
