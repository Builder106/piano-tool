import '../models/engine_models.dart';

/// Utilities for musical meter grouping, compound meter pulse classification, and beat types.
class MeterGrouping {
  /// Whether the meter is compound (e.g. 6/8, 9/8, 12/8 with beat unit 8 and beats divisible by 3).
  static bool isCompound(int beatsPerMeasure, int beatUnit) {
    return beatUnit == 8 && beatsPerMeasure % 3 == 0;
  }

  /// Whether the meter is 6/8 compound duple meter specifically.
  static bool is68Meter(int beatsPerMeasure, int beatUnit) {
    return beatsPerMeasure == 6 && beatUnit == 8;
  }

  /// Classifies the [beatInMeasure] (0-based integer) within a measure of [beatsPerMeasure]
  /// and [beatUnit].
  ///
  /// For 6/8 meter:
  /// - Beat 0 (eighth note 1): [MetronomeBeatType.downbeat] (dotted quarter 1)
  /// - Beats 1, 2 (eighth notes 2, 3): [MetronomeBeatType.subdivision]
  /// - Beat 3 (eighth note 4): [MetronomeBeatType.secondaryAccent] (dotted quarter 2)
  /// - Beats 4, 5 (eighth notes 5, 6): [MetronomeBeatType.subdivision]
  ///
  /// For simple meters (e.g. 4/4, 3/4, 2/4):
  /// - Beat 0: [MetronomeBeatType.downbeat]
  /// - Remaining beats: [MetronomeBeatType.regular]
  static MetronomeBeatType beatType({
    required int beatsPerMeasure,
    required int beatUnit,
    required int beatInMeasure,
  }) {
    final measureLength = beatsPerMeasure > 0 ? beatsPerMeasure : 4;
    final normalized =
        (beatInMeasure % measureLength + measureLength) % measureLength;

    if (normalized == 0) {
      return MetronomeBeatType.downbeat;
    }

    if (isCompound(measureLength, beatUnit)) {
      if (normalized % 3 == 0) {
        return MetronomeBeatType.secondaryAccent;
      }
      return MetronomeBeatType.subdivision;
    }

    return MetronomeBeatType.regular;
  }
}
