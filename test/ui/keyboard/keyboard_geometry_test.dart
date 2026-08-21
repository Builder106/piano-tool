import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/ui/keyboard/keyboard_geometry.dart';

void main() {
  const g = KeyboardGeometry(width: 720, height: 80);

  test('36 white keys divide the full width with none left over', () {
    expect(KeyboardGeometry.whiteKeyCount, 36);
    expect(g.whiteKeyWidth, closeTo(20, 1e-9));
    expect(g.whiteKeyRect(35).right, closeTo(720, 1e-6));
  });

  test('the keyboard spans C2 to C7', () {
    expect(KeyboardGeometry.lowestMidi, 36);
    expect(KeyboardGeometry.highestMidi, 96);
  });

  test('black keys are narrower and shorter than white', () {
    expect(g.blackKeyWidth, lessThan(g.whiteKeyWidth));
    expect(g.blackKeyHeight, lessThan(g.height));
  });

  test('there are 25 black keys and none between B and C or E and F', () {
    var count = 0;
    for (var midi = 36; midi <= 96; midi++) {
      if (g.isBlack(midi)) count++;
    }
    expect(count, 25);

    // B2 to C3 and E2 to F2 are the two semitone steps with no black key.
    expect(g.isBlack(47), isFalse); // B2
    expect(g.isBlack(48), isFalse); // C3
    expect(g.isBlack(40), isFalse); // E2
    expect(g.isBlack(41), isFalse); // F2
  });

  test('white index advances by seven per octave', () {
    expect(g.whiteIndexFor(36), 0); // C2
    expect(g.whiteIndexFor(48), 7); // C3
    expect(g.whiteIndexFor(96), 35); // C7
  });

  test('a black key sits astride the boundary of its two white neighbours', () {
    // C#2 straddles C2 and D2, so its centre is the boundary between them.
    final boundary = g.whiteKeyRect(0).right;
    expect(g.blackKeyRect(37).center.dx, closeTo(boundary, 1e-6));
  });

  test('every measurement scales with the given size', () {
    const wide = KeyboardGeometry(width: 1440, height: 80);
    expect(wide.whiteKeyWidth, closeTo(g.whiteKeyWidth * 2, 1e-9));
  });
}
