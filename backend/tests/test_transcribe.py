import numpy as np
import soundfile as sf

from app.transcribe import transcribe


def test_transcribe_returns_empty_list_for_silence(tmp_path):
    audio_path = tmp_path / "silence.wav"
    sr = 22050
    sf.write(str(audio_path), np.zeros(sr * 2, dtype=np.float32), sr)

    notes = transcribe(str(audio_path))

    assert notes == []


def test_transcribe_returns_well_typed_notes_for_a_decaying_tone(tmp_path):
    audio_path = tmp_path / "tone.wav"
    sr = 22050
    duration_s = 2.0
    t = np.arange(int(duration_s * sr)) / sr
    # A4 = 440 Hz, with a decay envelope so it resembles a struck note rather
    # than a sustained pure tone.
    envelope = np.exp(-2.0 * t)
    y = (0.5 * np.sin(2 * np.pi * 440.0 * t) * envelope).astype(np.float32)
    sf.write(str(audio_path), y, sr)

    notes = transcribe(str(audio_path))

    for note in notes:
        assert 0 <= note.pitch <= 127
        assert note.end >= note.start
        assert 1 <= note.velocity <= 127
