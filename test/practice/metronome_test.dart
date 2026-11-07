import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/practice/metronome.dart';

void main() {
  test('the weight sits low at full speed and high at half', () {
    expect(weightPosition(1.0), closeTo(0.25, 1e-9));
    expect(weightPosition(0.5), closeTo(0.80, 1e-9));
    expect(weightPosition(0.75), greaterThan(weightPosition(1.0)));
  });

  test('a weight position gives back its speed, in steps of five per cent', () {
    for (final speed in [0.5, 0.55, 0.75, 0.9, 1.0]) {
      expect(speedForWeight(weightPosition(speed)), closeTo(speed, 1e-9));
    }
    expect(speedForWeight(0.0), 1.0);
    expect(speedForWeight(2.0), 0.5);
  });
}
