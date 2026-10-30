import 'dart:math' as math;

import 'staff_geometry.dart';

/// Written note values the staff can engrave, longest first.
enum NoteValue {
  whole(1),
  half(1 / 2),
  quarter(1 / 4),
  eighth(1 / 8),
  sixteenth(1 / 16);

  const NoteValue(this.wholeFraction);

  /// Length as a fraction of a whole note.
  final double wholeFraction;

  /// Whole and half notes have open heads; shorter values are filled.
  bool get hollow => this == whole || this == half;

  bool get hasStem => this != whole;

  /// Flags on a lone note, or beams in a group.
  int get flags => switch (this) {
    eighth => 1,
    sixteenth => 2,
    _ => 0,
  };
}

typedef WrittenDuration = ({NoteValue value, bool dotted});

const double _eps = 1e-6;

/// Every duration the staff can write, longest first.
const List<WrittenDuration> _durations = [
  (value: NoteValue.whole, dotted: true),
  (value: NoteValue.whole, dotted: false),
  (value: NoteValue.half, dotted: true),
  (value: NoteValue.half, dotted: false),
  (value: NoteValue.quarter, dotted: true),
  (value: NoteValue.quarter, dotted: false),
  (value: NoteValue.eighth, dotted: true),
  (value: NoteValue.eighth, dotted: false),
  (value: NoteValue.sixteenth, dotted: false),
];

double _wholeLength(WrittenDuration d) =>
    d.value.wholeFraction * (d.dotted ? 1.5 : 1);

/// Beats are counted in the meter's beat unit: in 4/4 a beat is a quarter
/// note, in 6/8 an eighth.
double beatsFor(WrittenDuration d, int beatUnit) => _wholeLength(d) * beatUnit;

/// The written value for a note lasting [beats].
///
/// An exact match wins. Anything else gets the longest value that does not
/// exceed it, so a learner never reads a note as longer than it sounds.
WrittenDuration writtenDuration(double beats, int beatUnit) {
  final whole = beats / beatUnit;
  for (final d in _durations) {
    if ((_wholeLength(d) - whole).abs() < _eps) return d;
  }
  for (final d in _durations) {
    if (_wholeLength(d) <= whole + _eps) return d;
  }
  return _durations.last;
}

typedef NoteSpan = ({double startBeat, double durationBeats});

typedef PlacedRest = ({
  double startBeat,
  double durationBeats,
  NoteValue value,

  /// A whole rest that fills a measure of any meter, centred in it.
  bool wholeMeasure,
});

/// Compound meters (6/8, 9/8, 12/8) group beats in threes.
bool isCompound(int beatsPerMeasure, int beatUnit) =>
    beatUnit == 8 && beatsPerMeasure % 3 == 0 && beatsPerMeasure > 3;

/// Rests for every stretch of a measure that no note sounds through.
///
/// Levels store silence as a gap between notes, so the score
/// derives its rests the way an engraver would: a silent measure gets one
/// whole rest; a partial gap is split into rests that start on a beat they
/// fit, so a rest never hides a beat it crosses.
List<PlacedRest> restsFor({
  required List<NoteSpan> notes,
  required int beatsPerMeasure,
  required int beatUnit,
  required double totalBeats,
}) {
  final rests = <PlacedRest>[];
  final compound = isCompound(beatsPerMeasure, beatUnit);
  final candidates = [
    if (!compound) (value: NoteValue.half, dotted: false),
    if (compound) (value: NoteValue.quarter, dotted: true),
    (value: NoteValue.quarter, dotted: false),
    (value: NoteValue.eighth, dotted: false),
    (value: NoteValue.sixteenth, dotted: false),
  ];

  for (
    var measureStart = 0.0;
    measureStart < totalBeats - _eps;
    measureStart += beatsPerMeasure
  ) {
    final measureEnd = measureStart + beatsPerMeasure;
    final covered = [
      for (final n in notes)
        if (n.startBeat < measureEnd - _eps &&
            n.startBeat + n.durationBeats > measureStart + _eps)
          (
            start: n.startBeat < measureStart ? measureStart : n.startBeat,
            end: n.startBeat + n.durationBeats > measureEnd
                ? measureEnd
                : n.startBeat + n.durationBeats,
          ),
    ]..sort((a, b) => a.start.compareTo(b.start));

    if (covered.isEmpty) {
      rests.add((
        startBeat: measureStart,
        durationBeats: beatsPerMeasure.toDouble(),
        value: NoteValue.whole,
        wholeMeasure: true,
      ));
      continue;
    }

    final gaps = <({double start, double end})>[];
    var cursor = measureStart;
    for (final span in covered) {
      if (span.start > cursor + _eps) {
        gaps.add((start: cursor, end: span.start));
      }
      if (span.end > cursor) cursor = span.end;
    }
    if (measureEnd > cursor + _eps) gaps.add((start: cursor, end: measureEnd));

    for (final gap in gaps) {
      var pos = gap.start;
      while (gap.end - pos > _eps) {
        final relative = pos - measureStart;
        WrittenDuration? fit;
        for (final c in candidates) {
          final length = beatsFor(c, beatUnit);
          final steps = relative / length;
          if (length <= gap.end - pos + _eps &&
              (steps - steps.roundToDouble()).abs() < _eps) {
            fit = c;
            break;
          }
        }
        if (fit == null) break;
        final length = beatsFor(fit, beatUnit);
        rests.add((
          startBeat: pos,
          durationBeats: length,
          value: fit.value,
          wholeMeasure: false,
        ));
        pos += length;
      }
    }
  }
  return rests;
}

/// Beats in one beam group: a beat in simple time, a dotted beat in
/// compound time.
double beamUnitBeats(int beatsPerMeasure, int beatUnit) =>
    isCompound(beatsPerMeasure, beatUnit) ? 3 : 1;

typedef BeamCandidate = ({double startBeat, WrittenDuration duration});

/// Runs of eighths and shorter that share a beat, as index lists into
/// [events].
///
/// [events] are onsets in time order. A run breaks at a rest, at a longer
/// note, and at the beat boundary, so beams show the pulse.
List<List<int>> beamGroups(
  List<BeamCandidate> events, {
  required int beatsPerMeasure,
  required int beatUnit,
}) {
  final unit = beamUnitBeats(beatsPerMeasure, beatUnit);
  final groups = <List<int>>[];
  var current = <int>[];

  int beatOf(double startBeat) {
    final measure = (startBeat / beatsPerMeasure + _eps).floor();
    final within = startBeat - measure * beatsPerMeasure;
    return measure * 1000 + (within / unit + _eps).floor();
  }

  void close() {
    if (current.length >= 2) groups.add(current);
    current = <int>[];
  }

  for (var i = 0; i < events.length; i++) {
    final e = events[i];
    if (e.duration.value.flags == 0) {
      close();
      continue;
    }
    if (current.isNotEmpty) {
      final prev = events[current.last];
      final prevEnd = prev.startBeat + beatsFor(prev.duration, beatUnit);
      final contiguous = (prevEnd - e.startBeat).abs() < _eps;
      if (!contiguous || beatOf(prev.startBeat) != beatOf(e.startBeat)) {
        close();
      }
    }
    current.add(i);
  }
  close();
  return groups;
}

/// A written accidental: -1 flat, 0 natural, 1 sharp.
typedef Accidental = int;

/// The alteration a note is written with. MIDI pitch alone cannot tell F#
/// from Gb, so an authored spelling wins; otherwise black keys are sharps.
int writtenAlter(int midi, int? alter) =>
    alter ?? (const {1, 3, 6, 8, 10}.contains(midi % 12) ? 1 : 0);

typedef SpelledNote = ({double startBeat, int midi, int? alter});

/// The accidental to print before each note, or null when the measure's
/// running alteration already implies it.
///
/// An accidental lasts to the barline on its own staff position, so a second
/// F# in a bar prints bare and a later F natural needs its natural sign.
List<Accidental?> accidentalsFor(
  List<SpelledNote> notes, {
  required int beatsPerMeasure,
}) {
  final result = List<Accidental?>.filled(notes.length, null);
  final order = List<int>.generate(notes.length, (i) => i)
    ..sort((a, b) => notes[a].startBeat.compareTo(notes[b].startBeat));

  var measure = -1;
  var inForce = <int, int>{};
  for (final i in order) {
    final n = notes[i];
    final m = (n.startBeat / beatsPerMeasure + _eps).floor();
    if (m != measure) {
      measure = m;
      inForce = <int, int>{};
    }
    final alter = writtenAlter(n.midi, n.alter);
    final step = StaffGeometry.diatonicStep(n.midi - alter);
    if ((inForce[step] ?? 0) != alter) {
      result[i] = alter;
      inForce[step] = alter;
    }
  }
  return result;
}

/// Beat spacing that leaves the shortest note room for its head and an
/// accidental. Engravers give shorter notes less room than their length
/// alone would, so the spacing grows by less than the beat shrinks.
double pixelsPerBeatFor(Iterable<double> durations, {double base = 70}) {
  final shortest = durations.where((d) => d > 0).fold<double>(1, math.min);
  return shortest >= 1 ? base : base / math.pow(shortest, 0.75);
}

/// Identifies a note on a staff across rebuilds: its pitch and its beat.
String noteKey(int midi, double startBeat) => '$midi@$startBeat';

/// Measures, by index, in which every note was hit. A measure with no notes
/// is never resolved; there was nothing to play.
Set<int> resolvedMeasures(
  Iterable<({double startBeat, bool hit})> notes, {
  required int beatsPerMeasure,
}) {
  final hit = <int>{};
  final missed = <int>{};
  for (final n in notes) {
    final m = (n.startBeat / beatsPerMeasure + _eps).floor();
    (n.hit ? hit : missed).add(m);
  }
  return hit.difference(missed);
}
