import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/data/settings_repository.dart';
import 'package:piano_tool/models/audio_models.dart';
import 'package:piano_tool/ui/practice/input_check.dart';

PitchEvent _frame(int midi, {bool struck = false}) => PitchEvent(
  frequency: 0,
  confidence: 1,
  midiNote: midi,
  timestamp: 0,
  volume: 0.5,
  struck: struck,
);

void main() {
  final t0 = DateTime(2026, 10, 30);
  DateTime at(int ms) => t0.add(Duration(milliseconds: ms));
  InputListener listener() =>
      InputListener(target: 60, clearLevel: 0.1, startedAt: t0);

  test('waits, then calls a quiet room silent', () {
    final l = listener();
    expect(l.readingAt(at(1000)).hearing, Hearing.waiting);
    l.addLevel(at(5900), 0.001);
    expect(l.readingAt(at(6000)).hearing, Hearing.silent);
  });

  test('tells a weak signal from silence', () {
    final l = listener()..addLevel(at(100), 0.05);
    expect(l.readingAt(at(200)).hearing, Hearing.weak);
  });

  test('a loud sound with no pitch is unclear', () {
    final l = listener()..addLevel(at(100), 0.3);
    expect(l.readingAt(at(200)).hearing, Hearing.unclear);
  });

  test('a pitch that keeps changing is unstable', () {
    final l = listener();
    for (final (i, midi) in [62, 67, 64, 71, 59].indexed) {
      l.addPitch(at(i * 25), _frame(midi));
    }
    expect(l.readingAt(at(150)).hearing, Hearing.unstable);
  });

  test('names a steady wrong note', () {
    final l = listener();
    for (var i = 0; i < 4; i++) {
      l.addPitch(at(i * 25), _frame(64));
    }
    expect(l.readingAt(at(120)), (hearing: Hearing.wrongNote, midi: 64));
  });

  test('a held middle C passes; a single blip does not', () {
    final blip = listener()..addPitch(at(0), _frame(60));
    expect(blip.readingAt(at(50)).hearing, isNot(Hearing.heard));

    final held = listener();
    for (var i = 0; i < 3; i++) {
      held.addPitch(at(i * 25), _frame(60));
    }
    expect(held.readingAt(at(100)).hearing, Hearing.heard);
    // A pass is kept: it is not undone by the room going quiet.
    expect(held.readingAt(at(9000)).hearing, Hearing.heard);
  });

  test('one MIDI note-on is enough', () {
    final l = listener()..addPitch(at(0), _frame(60, struck: true));
    expect(l.readingAt(at(10)).hearing, Hearing.heard);
  });

  test('setups are keyed by source and digital piano', () {
    expect(
      inputCheckKey(PracticeInputSource.microphone, 'usb-1'),
      'microphone',
    );
    expect(inputCheckKey(PracticeInputSource.midi, null), 'midi');
    expect(inputCheckKey(PracticeInputSource.midi, 'usb-1'), 'midi:usb-1');
    expect(inputCheckKey(PracticeInputSource.both, 'bt-2'), 'both:bt-2');
  });

  test('note names use the white-key letter and octave', () {
    expect(noteName(60), 'C4');
    expect(noteName(64), 'E4');
    expect(noteName(70), 'B♭4');
  });
}
