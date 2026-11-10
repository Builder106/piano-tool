import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/audio/tone_synthesizer.dart';
import 'package:piano_tool/data/settings_repository.dart';
import 'package:piano_tool/models/audio_models.dart';
import 'package:piano_tool/services/touch_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('a press plays the note and reports a key strike', () async {
    final player = SilentAudioTonePlayer();
    final keys = TouchKeys(AudioSynthesizer(player: player));
    addTearDown(keys.dispose);
    final heard = <PitchEvent>[];
    keys.pitchStream.listen(heard.add);

    keys.press(64);
    await Future<void>.delayed(Duration.zero);

    expect(player.playCount, 1);
    expect(heard, hasLength(1));
    expect(heard.single.midiNote, 64);
    expect(heard.single.struck, isTrue);
    expect(heard.single.frequency, closeTo(329.63, 0.01));
  });

  test('on-screen keys use neither the microphone nor MIDI', () {
    const touch = PracticeInputSource.touch;
    expect(touch.usesTouch, isTrue);
    expect(touch.usesMicrophone, isFalse);
    expect(touch.usesMidi, isFalse);
    expect(PracticeInputSource.both.usesMicrophone, isTrue);
    expect(PracticeInputSource.both.usesMidi, isTrue);
    expect(PracticeInputSource.both.usesTouch, isFalse);
  });

  test('the choice of on-screen keys is remembered', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = SettingsRepository();
    await repository.save(
      const AppSettings(inputSource: PracticeInputSource.touch),
    );
    expect((await repository.read()).inputSource, PracticeInputSource.touch);
  });
}
