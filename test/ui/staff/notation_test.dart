import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/ui/staff/notation.dart';

void main() {
  group('writtenDuration', () {
    test('maps beats to note values in simple time', () {
      expect(writtenDuration(4, 4), (value: NoteValue.whole, dotted: false));
      expect(writtenDuration(2, 4), (value: NoteValue.half, dotted: false));
      expect(writtenDuration(3, 4), (value: NoteValue.half, dotted: true));
      expect(writtenDuration(1, 4), (value: NoteValue.quarter, dotted: false));
      expect(writtenDuration(0.5, 4), (value: NoteValue.eighth, dotted: false));
      expect(writtenDuration(0.25, 4), (
        value: NoteValue.sixteenth,
        dotted: false,
      ));
    });

    test('counts beats in the meter beat unit', () {
      // In 6/8 a beat is an eighth, so three beats are a dotted quarter.
      expect(writtenDuration(3, 8), (value: NoteValue.quarter, dotted: true));
      expect(writtenDuration(1, 8), (value: NoteValue.eighth, dotted: false));
    });

    test('never writes a note longer than it sounds', () {
      // 1.25 beats has no single value; a quarter is the longest that fits.
      expect(writtenDuration(1.25, 4), (
        value: NoteValue.quarter,
        dotted: false,
      ));
    });

    test('open heads belong to half and whole notes only', () {
      expect(NoteValue.whole.hollow, isTrue);
      expect(NoteValue.half.hollow, isTrue);
      expect(NoteValue.quarter.hollow, isFalse);
      expect(NoteValue.eighth.hollow, isFalse);
    });
  });

  group('restsFor', () {
    test('a silent measure gets one whole rest', () {
      final rests = restsFor(
        notes: const [(startBeat: 0, durationBeats: 4)],
        beatsPerMeasure: 4,
        beatUnit: 4,
        totalBeats: 8,
      );
      expect(rests, hasLength(1));
      expect(rests.single.startBeat, 4);
      expect(rests.single.wholeMeasure, isTrue);
    });

    test('a rest never hides the beat it crosses', () {
      // Silence from beat 1 to the barline: quarter on 1, half on 2.
      final rests = restsFor(
        notes: const [(startBeat: 0, durationBeats: 1)],
        beatsPerMeasure: 4,
        beatUnit: 4,
        totalBeats: 4,
      );
      expect(
        [for (final r in rests) (r.startBeat, r.value)],
        [(1.0, NoteValue.quarter), (2.0, NoteValue.half)],
      );
    });

    test('an off-beat gap starts with the shortest rest that aligns', () {
      final rests = restsFor(
        notes: const [
          (startBeat: 0, durationBeats: 0.5),
          (startBeat: 2, durationBeats: 2),
        ],
        beatsPerMeasure: 4,
        beatUnit: 4,
        totalBeats: 4,
      );
      expect(
        [for (final r in rests) (r.startBeat, r.value)],
        [(0.5, NoteValue.eighth), (1.0, NoteValue.quarter)],
      );
    });

    test('a note ringing over the barline leaves no rest under it', () {
      final rests = restsFor(
        notes: const [(startBeat: 2, durationBeats: 4)],
        beatsPerMeasure: 4,
        beatUnit: 4,
        totalBeats: 8,
      );
      expect(
        [for (final r in rests) (r.startBeat, r.value)],
        [(0.0, NoteValue.half), (6.0, NoteValue.half)],
      );
    });

    test('compound time rests in dotted beats', () {
      final rests = restsFor(
        notes: const [(startBeat: 0, durationBeats: 3)],
        beatsPerMeasure: 6,
        beatUnit: 8,
        totalBeats: 6,
      );
      expect(rests, hasLength(1));
      expect(rests.single.startBeat, 3);
      expect(rests.single.value, NoteValue.quarter);
    });
  });

  group('beamGroups', () {
    const eighth = (value: NoteValue.eighth, dotted: false);
    const quarter = (value: NoteValue.quarter, dotted: false);

    test('beams eighths in pairs by beat in 4/4', () {
      final groups = beamGroups(
        const [
          (startBeat: 0, duration: eighth),
          (startBeat: 0.5, duration: eighth),
          (startBeat: 1, duration: eighth),
          (startBeat: 1.5, duration: eighth),
          (startBeat: 2, duration: quarter),
        ],
        beatsPerMeasure: 4,
        beatUnit: 4,
      );
      expect(groups, [
        [0, 1],
        [2, 3],
      ]);
    });

    test('beams three eighths together in 6/8', () {
      final groups = beamGroups(
        const [
          (startBeat: 0, duration: eighth),
          (startBeat: 1, duration: eighth),
          (startBeat: 2, duration: eighth),
          (startBeat: 3, duration: eighth),
        ],
        beatsPerMeasure: 6,
        beatUnit: 8,
      );
      expect(groups, [
        [0, 1, 2],
      ]);
    });

    test('a rest between eighths breaks the beam', () {
      final groups = beamGroups(
        const [
          (startBeat: 0, duration: eighth),
          (startBeat: 1, duration: eighth),
        ],
        beatsPerMeasure: 4,
        beatUnit: 4,
      );
      expect(groups, isEmpty);
    });
  });

  group('accidentalsFor', () {
    test('black keys are written as sharps unless spelled otherwise', () {
      expect(writtenAlter(66, null), 1);
      expect(writtenAlter(66, -1), -1);
      expect(writtenAlter(65, null), 0);
    });

    test('an accidental lasts to the barline', () {
      final marks = accidentalsFor(const [
        (startBeat: 0, midi: 66, alter: null), // F#
        (startBeat: 1, midi: 66, alter: null), // F#, already in force
        (startBeat: 2, midi: 65, alter: null), // F natural
        (startBeat: 4, midi: 66, alter: null), // F#, next bar
      ], beatsPerMeasure: 4);
      expect(marks, [1, null, 0, 1]);
    });

    test('a flat is written on the natural above', () {
      final marks = accidentalsFor(const [
        (startBeat: 0, midi: 70, alter: -1),
      ], beatsPerMeasure: 4);
      expect(marks, [-1]);
    });
  });

  test('shorter notes widen the beat, less than proportionally', () {
    expect(pixelsPerBeatFor([1, 2, 4]), 70);
    final eighths = pixelsPerBeatFor([1, 0.5]);
    expect(eighths, greaterThan(70));
    expect(eighths, lessThan(140));
  });
}
