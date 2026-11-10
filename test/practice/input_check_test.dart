import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/data/settings_repository.dart';
import 'package:piano_tool/models/audio_models.dart';
import 'package:piano_tool/practice/input_check.dart';

PitchEvent _p(int midi, {bool struck = false}) => PitchEvent(
  frequency: 440,
  confidence: 0.9,
  midiNote: midi,
  timestamp: 0,
  volume: 0.3,
  struck: struck,
);

void main() {
  test('the key matches what earlier versions saved', () {
    expect(inputCheckKey(PracticeInputSource.microphone, 'x'), 'microphone');
    expect(inputCheckKey(PracticeInputSource.midi, 'dev'), 'midi:dev');
    expect(inputCheckKey(PracticeInputSource.both, null), 'both');
  });

  test('silence becomes silent only after three seconds', () {
    final c = InputCheck(loud: 0.1)..level(0.001, 1);
    expect(c.hearing, Hearing.waiting);
    c.tick(3.2);
    expect(c.hearing, Hearing.silent);
  });

  test('a faint signal and a loud one with no pitch are told apart', () {
    expect((InputCheck(loud: 0.1)..level(0.03, 0.5)).hearing, Hearing.weak);
    expect((InputCheck(loud: 0.1)..level(0.2, 0.5)).hearing, Hearing.unclear);
  });

  test('a wrong note is named', () {
    final c = InputCheck(loud: 0.1)..pitch(_p(64), 0.5);
    expect(c.hearing, Hearing.wrongNote);
    expect(c.message(midi: false), 'That was E. Try the circled C');
  });

  test('a struck C from a digital piano passes at once', () {
    final c = InputCheck(loud: 0.1)..pitch(_p(60, struck: true), 0.2);
    expect(c.hearing, Hearing.heard);
  });

  test('the microphone needs the same C twice', () {
    final c = InputCheck(loud: 0.1)..pitch(_p(72), 0.2);
    expect(c.hearing, isNot(Hearing.heard));
    c.pitch(_p(72), 0.25);
    expect(c.hearing, Hearing.heard);
  });

  test('a wandering pitch is unstable', () {
    final c = InputCheck(loud: 0.1)
      ..pitch(_p(62), 0.1)
      ..pitch(_p(64), 0.2)
      ..pitch(_p(65), 0.3);
    expect(c.hearing, Hearing.unstable);
  });
}
