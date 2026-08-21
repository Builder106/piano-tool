import numpy as np
import soundfile as sf
from basic_pitch import ICASSP_2022_MODEL_PATH
from basic_pitch.inference import predict

from app.quantize import NoteEvent


def transcribe(audio_path: str) -> list[NoteEvent]:
    audio, _ = sf.read(audio_path, always_2d=False)
    if audio.size == 0 or float(np.max(np.abs(audio))) == 0.0:
        return []

    _, _, note_events = predict(
        # Pass the ICASSP 2022 model path explicitly -- basic-pitch's default
        # model resolution tries to load a TensorFlow SavedModel, and
        # TensorFlow is deliberately never installed on this VM (see
        # requirements.txt and scripts/install_basic_pitch.sh).
        audio_path,
        model_or_model_path=str(ICASSP_2022_MODEL_PATH),
    )
    return [
        NoteEvent(
            pitch=int(pitch),
            start=float(start),
            end=float(end),
            velocity=max(1, min(127, round(float(amplitude) * 127))),
        )
        for start, end, pitch, amplitude, _pitch_bends in note_events
    ]
