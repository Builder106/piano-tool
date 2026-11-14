import 'dart:math' as math;

/// Reference tuning, pitch calibration, and cent deviation calculations.
///
/// Keeps pitch tuning strictly separate from timing tolerance windows.
class PitchCalibration {
  const PitchCalibration({this.referenceFrequency = 440.0});

  /// The reference tuning frequency in Hz (typically 440.0 Hz for standard A4).
  final double referenceFrequency;

  /// Converts a frequency in Hz to the nearest MIDI note number using
  /// [referenceFrequency].
  int frequencyToMidi(double frequency) {
    if (frequency <= 0) return 0;
    return (69 + 12 * math.log(frequency / referenceFrequency) / math.ln2)
        .round();
  }

  /// Converts a MIDI note number to its exact nominal frequency in Hz based on
  /// [referenceFrequency].
  double midiToFrequency(int midiNote) {
    return referenceFrequency * math.pow(2.0, (midiNote - 69) / 12.0);
  }

  /// Calculates cents deviation of an observed [frequency] from the nominal
  /// frequency of [midiNote] at [referenceFrequency].
  ///
  /// Positive means sharp, negative means flat.
  double centsDeviation(double frequency, int midiNote) {
    if (frequency <= 0) return 0.0;
    final nominalFreq = midiToFrequency(midiNote);
    return 1200.0 * math.log(frequency / nominalFreq) / math.ln2;
  }
}
