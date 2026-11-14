import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/audio/pitch_calibration.dart';

void main() {
  group('PitchCalibration', () {
    test('standard A440 tuning maps nominal pitches to correct MIDI notes', () {
      const cal = PitchCalibration(referenceFrequency: 440.0);

      // A4 = 440 Hz -> MIDI 69
      expect(cal.frequencyToMidi(440.0), 69);
      expect(cal.midiToFrequency(69), closeTo(440.0, 0.01));

      // Middle C / C4 = 261.63 Hz -> MIDI 60
      expect(cal.frequencyToMidi(261.63), 60);
      expect(cal.midiToFrequency(60), closeTo(261.63, 0.05));

      // A3 = 220 Hz -> MIDI 57
      expect(cal.frequencyToMidi(220.0), 57);
      expect(cal.midiToFrequency(57), closeTo(220.0, 0.01));
    });

    test('non-standard reference tuning shifts pitch conversion correctly', () {
      // Baroque pitch: A4 = 415.3 Hz (one semitone flat compared to modern 440 Hz)
      const baroque = PitchCalibration(referenceFrequency: 415.3);
      expect(baroque.frequencyToMidi(415.3), 69);
      expect(baroque.midiToFrequency(69), closeTo(415.3, 0.01));

      // Under Baroque 415.3 Hz reference, 440 Hz is A#4 / Bb4 (MIDI 70)
      expect(baroque.frequencyToMidi(440.0), 70);

      // Scientific / Verdi pitch: A4 = 432.0 Hz
      const verdi = PitchCalibration(referenceFrequency: 432.0);
      expect(verdi.frequencyToMidi(432.0), 69);
      expect(verdi.midiToFrequency(69), closeTo(432.0, 0.01));

      // European orchestra concert pitch: A4 = 442.0 Hz
      const concert = PitchCalibration(referenceFrequency: 442.0);
      expect(concert.frequencyToMidi(442.0), 69);
      expect(concert.midiToFrequency(69), closeTo(442.0, 0.01));
    });

    test('calculates cents deviation accurately', () {
      const cal = PitchCalibration(referenceFrequency: 440.0);

      // In tune A4
      expect(cal.centsDeviation(440.0, 69), closeTo(0.0, 0.01));

      // Sharp by 10 Hz (450 Hz vs 440 Hz) -> ~38.9 cents sharp
      expect(cal.centsDeviation(450.0, 69), closeTo(38.9, 0.2));

      // Flat by 10 Hz (430 Hz vs 440 Hz) -> ~39.8 cents flat
      expect(cal.centsDeviation(430.0, 69), closeTo(-39.8, 0.2));

      // Exactly one semitone up (466.16 Hz -> A#4) evaluated against A4 (69)
      expect(cal.centsDeviation(466.164, 69), closeTo(100.0, 0.1));

      // Zero or negative frequency returns 0.0
      expect(cal.centsDeviation(0.0, 69), 0.0);
      expect(cal.centsDeviation(-5.0, 69), 0.0);
    });
  });
}
