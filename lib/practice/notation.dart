/// How a note is written on a treble staff. Pure functions, so the staff
/// painter only draws.
library;

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
