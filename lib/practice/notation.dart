/// How a note is written on a treble staff. Pure functions, so the staff
/// painter only draws.
library;

import '../models/level_models.dart';

const _letterOf = [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6];
const _blackKeys = {1, 3, 6, 8, 10};

/// The bottom line of the treble staff, E4, as a diatonic number.
const _e4 = 4 * 7 + 2;

/// Diatonic steps above the bottom line of the treble staff: E4 is 0, F4 is
/// 1, middle C is -2. A black key is written as the sharp of the letter
/// below unless [alter] is -1, which spells it as the flat of the letter
/// above.
int trebleStep(int midi, {int? alter}) {
  final pc = midi % 12;
  final octave = midi ~/ 12 - 1;
  var letter = _letterOf[pc];
  if (alter == -1 && _blackKeys.contains(pc)) letter += 1;
  return octave * 7 + letter - _e4;
}

enum Accidental { none, sharp, flat }

Accidental accidentalFor(int midi, {int? alter}) {
  if (!_blackKeys.contains(midi % 12)) return Accidental.none;
  return alter == -1 ? Accidental.flat : Accidental.sharp;
}

enum NoteValue { whole, half, quarter, eighth, sixteenth }

/// A written note value, optionally dotted.
typedef Written = ({NoteValue value, bool dotted});

const _written = <(double, Written)>[
  (4, (value: NoteValue.whole, dotted: false)),
  (3, (value: NoteValue.half, dotted: true)),
  (2, (value: NoteValue.half, dotted: false)),
  (1.5, (value: NoteValue.quarter, dotted: true)),
  (1, (value: NoteValue.quarter, dotted: false)),
  (0.75, (value: NoteValue.eighth, dotted: true)),
  (0.5, (value: NoteValue.eighth, dotted: false)),
  (0.25, (value: NoteValue.sixteenth, dotted: false)),
];

/// The nearest written value for a duration in beats, where a beat is a
/// [beatUnit] note (4 for a quarter, 8 for an eighth).
Written writtenValue(double beats, {int beatUnit = 4}) {
  final quarters = beats * 4 / beatUnit;
  var best = _written.first;
  for (final w in _written) {
    if ((w.$1 - quarters).abs() < (best.$1 - quarters).abs()) best = w;
  }
  return best.$2;
}

/// Steps that need a ledger line for a note at [step].
List<int> ledgerSteps(int step) => [
  for (var s = -2; s >= step; s -= 2) s,
  for (var s = 10; s <= step; s += 2) s,
];

/// Notes below the middle line take an up stem.
bool stemUp(int step) => step < 4;

/// The staff lines (0 is the bottom line) that ring when a note at [step]
/// sounds: its own line, or the two lines either side of its space. Notes
/// off the staff ring the nearest line.
List<int> ringingLines(int step) {
  if (step <= 0) return const [0];
  if (step >= 8) return const [4];
  return step.isEven ? [step ~/ 2] : [step ~/ 2, step ~/ 2 + 1];
}

/// Which staff a note is written on.
enum Clef { treble, bass }

/// Steps above the bottom line of [clef]'s staff. The bass staff's bottom
/// line is G2, twelve diatonic steps below the treble staff's E4.
int staffStep(int midi, Clef clef, {int? alter}) {
  final step = trebleStep(midi, alter: alter);
  return clef == Clef.treble ? step : step + 12;
}

/// The staves a level is written on, top to bottom.
List<Clef> stavesFor(LevelModel level) => switch (level.clef) {
  LevelClef.treble => const [Clef.treble],
  LevelClef.bass => const [Clef.bass],
  LevelClef.grand => const [Clef.treble, Clef.bass],
};

/// The staff index (into [stavesFor]) a note belongs on. On a grand staff a
/// level that assigns voices uses them (voice 1 and up is the left hand);
/// otherwise notes below middle C go to the bass staff.
int staffIndexFor(LevelModel level, LevelNote note, {required bool voiced}) {
  if (level.clef != LevelClef.grand) return 0;
  if (voiced) return note.voiceIndex > 0 ? 1 : 0;
  return note.midiNote < 60 ? 1 : 0;
}

/// One written symbol: a note (or one tied piece of it) or a rest.
class Engraved {
  const Engraved({
    required this.staff,
    required this.beat,
    required this.beats,
    required this.written,
    this.noteIndex,
    this.midi,
    this.alter,
    this.tiedToNext = false,
    this.tiedFromPrevious = false,
    this.beam,
    this.wholeBar = false,
  });

  final int staff;
  final double beat;
  final double beats;
  final Written written;

  /// Index into the level's notes, or null for a rest.
  final int? noteIndex;
  final int? midi;
  final int? alter;
  final bool tiedToNext;
  final bool tiedFromPrevious;

  /// Notes sharing a beam carry the same id.
  final int? beam;

  /// A rest that fills an empty bar, centred in it.
  final bool wholeBar;

  bool get isRest => noteIndex == null;

  Engraved withBeam(int id) => Engraved(
    staff: staff,
    beat: beat,
    beats: beats,
    written: written,
    noteIndex: noteIndex,
    midi: midi,
    alter: alter,
    tiedToNext: tiedToNext,
    tiedFromPrevious: tiedFromPrevious,
    beam: id,
    wholeBar: wholeBar,
  );
}

const _eps = 1e-6;

/// Splits a length in quarters into written values, longest first.
List<(double, Written)> _pieces(double quarters) {
  final out = <(double, Written)>[];
  var left = quarters;
  while (left > 0.25 - _eps) {
    final fit = _written.firstWhere(
      (w) => w.$1 <= left + _eps,
      orElse: () => _written.last,
    );
    out.add(fit);
    left -= fit.$1;
  }
  if (out.isEmpty) out.add(_written.last);
  return out;
}

/// Writes a level as symbols: notes split at barlines and into writable
/// values with ties between the pieces, rests in every gap of every staff,
/// and eighths and sixteenths beamed within each beat.
List<Engraved> engrave(LevelModel level, List<LevelNote> notes) {
  final staves = stavesFor(level).length;
  final voiced = notes.any((n) => n.voiceIndex > 0);
  final toQuarters = 4 / level.beatUnit;
  final measures = [...level.measures]
    ..sort((a, b) => a.startBeat.compareTo(b.startBeat));
  final out = <Engraved>[];

  // Notes, split at barlines and into written values.
  for (final (i, note) in notes.indexed) {
    if (note.isRest) continue;
    final staff = staffIndexFor(level, note, voiced: voiced);
    final end = note.startBeat + note.durationBeats;
    final cuts = <double>[note.startBeat];
    for (final m in measures) {
      final bar = m.startBeat + m.beatsPerMeasure;
      if (bar > note.startBeat + _eps && bar < end - _eps) cuts.add(bar);
    }
    cuts.add(end);
    final parts = <Engraved>[];
    for (var c = 0; c + 1 < cuts.length; c++) {
      var beat = cuts[c];
      for (final (q, w) in _pieces((cuts[c + 1] - cuts[c]) * toQuarters)) {
        final beats = q / toQuarters;
        parts.add(
          Engraved(
            staff: staff,
            beat: beat,
            beats: beats,
            written: w,
            noteIndex: i,
            midi: note.midiNote,
            alter: note.alter,
          ),
        );
        beat += beats;
      }
    }
    for (final (p, part) in parts.indexed) {
      out.add(
        Engraved(
          staff: part.staff,
          beat: part.beat,
          beats: part.beats,
          written: part.written,
          noteIndex: i,
          midi: part.midi,
          alter: part.alter,
          tiedToNext: p < parts.length - 1,
          tiedFromPrevious: p > 0,
        ),
      );
    }
  }

  // Rests: every stretch of a bar where a staff has nothing sounding.
  for (final m in measures) {
    final barEnd = m.startBeat + m.beatsPerMeasure;
    for (var staff = 0; staff < staves; staff++) {
      final sounding = [
        for (final e in out)
          if (e.staff == staff &&
              e.beat < barEnd - _eps &&
              e.beat + e.beats > m.startBeat + _eps)
            (e.beat, e.beat + e.beats),
      ]..sort((a, b) => a.$1.compareTo(b.$1));
      if (sounding.isEmpty) {
        out.add(
          Engraved(
            staff: staff,
            beat: m.startBeat,
            beats: m.beatsPerMeasure.toDouble(),
            written: (value: NoteValue.whole, dotted: false),
            wholeBar: true,
          ),
        );
        continue;
      }
      var cursor = m.startBeat;
      void restUntil(double to) {
        if (to - cursor < 0.25 / toQuarters - _eps) return;
        var beat = cursor;
        for (final (q, w) in _pieces((to - cursor) * toQuarters)) {
          out.add(
            Engraved(
              staff: staff,
              beat: beat,
              beats: q / toQuarters,
              written: w,
            ),
          );
          beat += q / toQuarters;
        }
      }

      for (final (start, end) in sounding) {
        if (start > cursor + _eps) restUntil(start);
        if (end > cursor) cursor = end;
      }
      if (cursor < barEnd - _eps) restUntil(barEnd);
    }
  }

  out.sort((a, b) {
    final byBeat = a.beat.compareTo(b.beat);
    return byBeat != 0 ? byBeat : a.staff.compareTo(b.staff);
  });

  // Beams: eighths and sixteenths on the same staff, in the same bar and the
  // same quarter-note beat, starting on at least two different beats.
  var nextBeam = 0;
  final groups = <(int, int, int), List<int>>{};
  for (final (i, e) in out.indexed) {
    if (e.isRest) continue;
    if (e.written.value != NoteValue.eighth &&
        e.written.value != NoteValue.sixteenth) {
      continue;
    }
    final m = measures.lastWhere(
      (m) => m.startBeat <= e.beat + _eps,
      orElse: () => measures.first,
    );
    final quarter = ((e.beat - m.startBeat) * toQuarters + _eps).floor();
    groups.putIfAbsent((e.staff, m.index, quarter), () => []).add(i);
  }
  for (final members in groups.values) {
    final beats = {for (final i in members) out[i].beat};
    if (beats.length < 2) continue;
    final id = nextBeam++;
    for (final i in members) {
      out[i] = out[i].withBeam(id);
    }
  }
  return out;
}
