import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/models/level_models.dart';
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

  group('engraving', () {
    test('gaps in a bar become rests', () {
      final e = _engrave([_n(64, 1, 1)]);
      expect(
        [for (final x in e) (x.beat, x.isRest, x.written.value)],
        [
          (0.0, true, NoteValue.quarter),
          (1.0, false, NoteValue.quarter),
          (2.0, true, NoteValue.half),
        ],
      );
    });

    test('an empty bar gets one whole-bar rest', () {
      final e = _engrave([_n(64, 0, 4)], bars: 2);
      final rests = e.where((x) => x.isRest).toList();
      expect(rests, hasLength(1));
      expect(rests.single.wholeBar, isTrue);
      expect(rests.single.beat, 4.0);
    });

    test('a note across a barline is tied over it', () {
      final e = _engrave([
        _n(64, 3, 2),
      ], bars: 2).where((x) => !x.isRest).toList();
      expect(
        [for (final x in e) (x.beat, x.tiedToNext, x.tiedFromPrevious)],
        [(3.0, true, false), (4.0, false, true)],
      );
    });

    test('a length with no single value is split and tied', () {
      final e = _engrave([_n(64, 0, 2.5)]).where((x) => !x.isRest).toList();
      expect(
        [for (final x in e) x.written.value],
        [NoteValue.half, NoteValue.eighth],
      );
      expect(e.first.tiedToNext, isTrue);
    });

    test('eighths in the same beat share a beam; across beats they do not', () {
      final e = _engrave([
        _n(64, 0, 0.5),
        _n(65, 0.5, 0.5),
        _n(67, 1.5, 0.5),
        _n(69, 2, 0.5),
      ]).where((x) => !x.isRest).toList();
      expect(e[0].beam, isNotNull);
      expect(e[1].beam, e[0].beam);
      expect(e[2].beam, isNull);
      expect(e[3].beam, isNull);
    });

    test('a grand staff puts low notes on the bass staff', () {
      final e = _engrave([
        _n(72, 0, 4),
        _n(48, 0, 4),
      ], clef: LevelClef.grand).where((x) => !x.isRest).toList();
      expect({for (final x in e) x.midi: x.staff}, {72: 0, 48: 1});
    });

    test('a grand staff follows voices when the level assigns them', () {
      final e = _engrave([
        _n(64, 0, 4),
        _n(62, 0, 4, voice: 1),
      ], clef: LevelClef.grand).where((x) => !x.isRest).toList();
      expect({for (final x in e) x.midi: x.staff}, {64: 0, 62: 1});
    });

    test('bass staff steps count from G2', () {
      expect(staffStep(43, Clef.bass), 0);
      expect(staffStep(57, Clef.bass), 8);
      expect(staffStep(60, Clef.bass), 10);
    });
  });
}

LevelNote _n(int midi, double beat, double beats, {int voice = 0}) => LevelNote(
  midiNote: midi,
  startBeat: beat,
  durationBeats: beats,
  measureIndex: beat ~/ 4,
  beatIndex: (beat % 4).floor(),
  voiceIndex: voice,
);

LevelModel _level(
  List<LevelNote> notes, {
  int bars = 1,
  LevelClef clef = LevelClef.treble,
}) => LevelModel(
  id: 'fixture',
  title: 'Fixture',
  description: '',
  tempo: 90,
  beatsPerMeasure: 4,
  totalMeasures: bars,
  clef: clef,
  measures: [
    for (var m = 0; m < bars; m++)
      LevelMeasure(
        index: m,
        startBeat: m * 4.0,
        beatsPerMeasure: 4,
        notes: [
          for (final n in notes)
            if (n.measureIndex == m) n,
        ],
      ),
  ],
);

List<Engraved> _engrave(
  List<LevelNote> notes, {
  int bars = 1,
  LevelClef clef = LevelClef.treble,
}) => engrave(_level(notes, bars: bars, clef: clef), notes);
