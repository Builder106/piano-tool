import librosa
import numpy as np


def estimate_tempo(audio_path: str) -> float:
    y, sr = librosa.load(audio_path, sr=None, mono=True)
    tempo, _ = librosa.beat.beat_track(y=y, sr=sr)
    # tempo is a numpy array, extract the scalar value
    if isinstance(tempo, np.ndarray):
        tempo = tempo.item()
    return float(tempo)
