import numpy as np
import soundfile as sf

from app.tempo import estimate_tempo


def _write_click_track(path: str, bpm: float, duration_s: float = 8.0, sr: int = 22050) -> None:
    interval_s = 60.0 / bpm
    y = np.zeros(int(duration_s * sr), dtype=np.float32)
    click = np.sin(2 * np.pi * 1000 * np.arange(int(0.02 * sr)) / sr).astype(np.float32)
    t = 0.0
    while t < duration_s:
        start = int(t * sr)
        end = min(start + len(click), len(y))
        y[start:end] += click[: end - start]
        t += interval_s
    sf.write(path, y, sr)


def test_estimate_tempo_recovers_a_click_tracks_bpm(tmp_path):
    audio_path = tmp_path / "clicks.wav"
    _write_click_track(str(audio_path), bpm=120.0)

    tempo = estimate_tempo(str(audio_path))

    # Beat trackers commonly report a tempo related to the true value by a
    # factor of two (double- or half-time) rather than the exact number, so
    # accept any octave-related match rather than one specific value.
    assert any(abs(tempo - 120.0 * factor) < 6 for factor in (0.5, 1.0, 2.0))
