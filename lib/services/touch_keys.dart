import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/tone_synthesizer.dart';
import '../models/audio_models.dart';

/// The keys drawn on the screen. A press plays the note and is reported as a
/// key strike, exactly as a digital piano's would be, so the practice engine
/// needs no special case. The microphone stays off while these are in use,
/// because it would hear the sound they make.
class TouchKeys {
  TouchKeys(this._synth);

  final AudioSynthesizer _synth;
  final _events = StreamController<PitchEvent>.broadcast();

  Stream<PitchEvent> get pitchStream => _events.stream;

  void press(int midi) {
    unawaited(_synth.playNote(midiNote: midi, durationSeconds: 0.9));
    _events.add(
      PitchEvent(
        frequency: ToneGenerator.midiToFrequency(midi),
        confidence: 1.0,
        midiNote: midi,
        timestamp: DateTime.now().millisecondsSinceEpoch / 1000.0,
        volume: 0.8,
        struck: true,
      ),
    );
  }

  void dispose() {
    unawaited(_events.close());
  }
}

final touchKeysProvider = Provider<TouchKeys>((ref) {
  final keys = TouchKeys(ref.watch(audioSynthesizerProvider));
  ref.onDispose(keys.dispose);
  return keys;
});

final touchPitchStreamProvider = StreamProvider<PitchEvent>(
  (ref) => ref.watch(touchKeysProvider).pitchStream,
);
