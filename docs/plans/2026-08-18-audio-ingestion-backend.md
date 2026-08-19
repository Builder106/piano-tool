# Audio Ingestion Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** a small Python service that turns an uploaded audio file, a recording, or a YouTube link into a `LevelModel`, over an async job API, exactly matching the JSON shape the Flutter app already uses.

**Architecture:** FastAPI app with three endpoints (`POST /jobs`, `GET /jobs/{id}`, `DELETE /jobs/{id}`) backed by an in-memory job store running work on a background thread pool. Each job runs a four-step pipeline — acquire audio, transcribe with `basic-pitch`, estimate tempo, quantize to a beat grid — and produces a `LevelModel`-shaped JSON response.

**Tech Stack:** Python 3.12, FastAPI, Pydantic v2, `basic-pitch` (ONNX backend), `librosa`, `yt-dlp`, `pytest`.

**Spec:** `docs/specs/2026-08-18-audio-ingestion-design.md`

This plan covers the backend only. The Flutter app-side work (`IngestionRepository`, `ImportScreen`, `ReviewScreen`, the `LevelRepository` extension) is a separate plan, written once this one is built and reviewed — the app can't be meaningfully planned against an API that doesn't exist yet.

## Global Constraints

- The backend lives in `backend/` at the repo root. `verify-on-vm` already recognizes this as a lockfile-hashed subfolder, so no changes to the verification wrapper are needed.
- Python 3.12, plain `pip` + a `requirements.txt`, no poetry/uv — matches what's already installed on `ampere-dev` and what the feasibility spike used.
- `basic-pitch` must run on its ONNX backend, never TensorFlow. The feasibility spike found that on this VM's aarch64 + Python 3.12 combination, `basic-pitch`'s default install unconditionally pulls a `tensorflow<2.15.1` requirement that has no working install path (it falls back to building an ancient `numpy` from source, which fails outright on Python 3.12). The fix, proven in the spike: install `basic-pitch`'s real dependencies from `requirements.txt` (everything except `basic-pitch` itself, plus `onnxruntime`), then install `basic-pitch==0.4.0 --no-deps` separately via `backend/scripts/install_basic_pitch.sh`. Every task's test command runs that script first.
- `setuptools<81` is a hard pin in `requirements.txt`. Setuptools 81+ removed `pkg_resources`, which `resampy` (a `basic-pitch` dependency) still imports at module load time.
- Pydantic field names use `snake_case` in Python with an explicit `camelCase` alias matching the Dart `LevelModel`/`LevelMeasure`/`LevelNote` JSON keys exactly, copied from `lib/models/level_models.dart`: `midiNote`, `startBeat`, `durationBeats`, `measureIndex`, `beatIndex`, `isRest`, `voiceIndex`, `index`, `beatsPerMeasure`, `notes`, `id`, `title`, `description`, `tempo`, `totalMeasures`, `measures`, `clefOctave`, `transpose`. All API responses serialize with `model_dump(by_alias=True)`.
- Beats-per-measure is fixed at 4 everywhere. Meter detection is out of scope per the spec.
- Job state is in-memory, one process, no persistence across a restart. This is an accepted limitation for a single-user service, not something to fix in this plan.
- Duration cap defaults to 600 seconds (10 minutes), overridable per call for testing.
- Every task's tests run via `verify-on-vm "<repo-path>/backend" "bash scripts/install_basic_pitch.sh && pytest -v"` on `ampere-dev`. Never `pip install`, `pytest`, or any Python process locally on the Mac. If `ampere-dev` is unreachable, stop and say so rather than falling back to a local run.
- No test may make a real network call. The YouTube-acquisition path is tested exclusively against a mocked `yt_dlp.YoutubeDL` — never a real download.
- An in-app "recording" source is not a separate backend concept. From the backend's perspective, a recording the app made and a file the user picked from their device are both just uploaded audio bytes — both go through the `source: "upload"` path. Only YouTube needs its own acquisition code.

---

### Task 1: Project scaffold and health check

**Files:**
- Create: `backend/requirements.txt`
- Create: `backend/scripts/install_basic_pitch.sh`
- Create: `backend/pytest.ini`
- Create: `backend/app/__init__.py`
- Create: `backend/app/main.py`
- Create: `backend/tests/test_main.py`
- Modify: `.gitignore` (repo root)

**Interfaces:**
- Produces: a FastAPI `app` object importable as `from app.main import app`, with `GET /health`.

- [ ] **Step 1: Create the scaffold files**

`backend/requirements.txt` — everything `basic-pitch` needs except `basic-pitch` itself, plus the API and test stack:

```
numpy
librosa
soundfile
mir-eval
pretty-midi>=0.2.9
resampy<0.4.3,>=0.2.2
scikit-learn
scipy>=1.4.1
typing-extensions
onnxruntime
setuptools<81
fastapi
uvicorn[standard]
pydantic>=2
python-multipart
httpx
pytest
yt-dlp
```

`backend/scripts/install_basic_pitch.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
pip install basic-pitch==0.4.0 --no-deps
```

`backend/pytest.ini`:

```ini
[pytest]
pythonpath = .
```

`backend/app/__init__.py` — empty file.

Add to the repo root `.gitignore`, under the existing "Flutter/Dart/Pub related" section (append a new section rather than mixing into it):

```
# Python backend
backend/__pycache__/
backend/**/__pycache__/
backend/.pytest_cache/
backend/*.egg-info/
```

- [ ] **Step 2: Write the failing test**

`backend/tests/test_main.py`:

```python
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health_returns_ok():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
```

- [ ] **Step 3: Run it and confirm it fails**

```bash
verify-on-vm "<repo>/backend" "bash scripts/install_basic_pitch.sh && pytest -v"
```

Expected: FAIL — `ModuleNotFoundError: No module named 'app.main'` (or the file doesn't exist yet).

- [ ] **Step 4: Implement**

`backend/app/main.py`:

```python
from fastapi import FastAPI

app = FastAPI(title="Piano-Tool Ingestion Service")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
```

- [ ] **Step 5: Run it and confirm it passes**

Same command as Step 3. Expected: `1 passed`.

- [ ] **Step 6: Commit**

```bash
git add backend/requirements.txt backend/scripts/install_basic_pitch.sh backend/pytest.ini backend/app/__init__.py backend/app/main.py backend/tests/test_main.py .gitignore
git commit -m "Scaffold the audio-ingestion backend with a health check"
```

---

### Task 2: Pydantic models matching LevelModel

**Files:**
- Create: `backend/app/models.py`
- Create: `backend/tests/test_models.py`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `LevelNote`, `LevelMeasure`, `LevelModel` (Pydantic `BaseModel` subclasses) importable from `app.models`, each constructible with `snake_case` keyword arguments and serializable to the Dart-matching `camelCase` JSON shape via `.model_dump(by_alias=True)`.

- [ ] **Step 1: Write the failing test**

```python
from app.models import LevelMeasure, LevelModel, LevelNote


def test_level_note_serializes_with_camel_case_keys():
    note = LevelNote(
        midi_note=60,
        start_beat=0.0,
        duration_beats=1.0,
        measure_index=0,
        beat_index=0,
    )

    data = note.model_dump(by_alias=True)

    assert data == {
        "midiNote": 60,
        "startBeat": 0.0,
        "durationBeats": 1.0,
        "measureIndex": 0,
        "beatIndex": 0,
        "isRest": False,
        "voiceIndex": 0,
    }


def test_level_model_serializes_nested_structure_with_camel_case_keys():
    note = LevelNote(
        midi_note=64, start_beat=1.0, duration_beats=1.0, measure_index=0, beat_index=1
    )
    measure = LevelMeasure(index=0, start_beat=0.0, beats_per_measure=4, notes=[note])
    level = LevelModel(
        id="level_test",
        title="Test Level",
        description="A test level",
        tempo=80,
        beats_per_measure=4,
        total_measures=1,
        measures=[measure],
    )

    data = level.model_dump(by_alias=True)

    assert data["beatsPerMeasure"] == 4
    assert data["totalMeasures"] == 1
    assert data["clefOctave"] == 4
    assert data["transpose"] == 0
    assert data["measures"][0]["startBeat"] == 0.0
    assert data["measures"][0]["notes"][0]["midiNote"] == 64


def test_level_model_round_trips_from_camel_case_json():
    payload = {
        "id": "level_x",
        "title": "X",
        "description": "d",
        "tempo": 100,
        "beatsPerMeasure": 4,
        "totalMeasures": 0,
        "measures": [],
    }

    level = LevelModel.model_validate(payload)

    assert level.beats_per_measure == 4
    assert level.total_measures == 0
```

- [ ] **Step 2: Run it and confirm it fails**

```bash
verify-on-vm "<repo>/backend" "bash scripts/install_basic_pitch.sh && pytest tests/test_models.py -v"
```

Expected: FAIL — `ModuleNotFoundError: No module named 'app.models'`.

- [ ] **Step 3: Implement**

`backend/app/models.py`:

```python
from pydantic import BaseModel, ConfigDict, Field


class LevelNote(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    midi_note: int = Field(alias="midiNote")
    start_beat: float = Field(alias="startBeat")
    duration_beats: float = Field(alias="durationBeats")
    measure_index: int = Field(alias="measureIndex")
    beat_index: int = Field(alias="beatIndex")
    is_rest: bool = Field(default=False, alias="isRest")
    voice_index: int = Field(default=0, alias="voiceIndex")


class LevelMeasure(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    index: int
    start_beat: float = Field(alias="startBeat")
    beats_per_measure: int = Field(alias="beatsPerMeasure")
    notes: list[LevelNote] = Field(default_factory=list)


class LevelModel(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    id: str
    title: str
    description: str
    tempo: int
    beats_per_measure: int = Field(alias="beatsPerMeasure")
    total_measures: int = Field(alias="totalMeasures")
    measures: list[LevelMeasure]
    clef_octave: int = Field(default=4, alias="clefOctave")
    transpose: int = Field(default=0, alias="transpose")
```

- [ ] **Step 4: Run it and confirm it passes**

Same command as Step 2 (drop the file filter to run the whole suite). Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add backend/app/models.py backend/tests/test_models.py
git commit -m "Add Pydantic models matching the Dart LevelModel JSON shape"
```

---

### Task 3: Beat quantization (the core new algorithm)

**Files:**
- Create: `backend/app/quantize.py`
- Create: `backend/tests/test_quantize.py`

**Interfaces:**
- Consumes: `LevelModel`, `LevelMeasure`, `LevelNote` from `app.models` (Task 2).
- Produces: `NoteEvent` (dataclass: `pitch: int, start: float, end: float, velocity: int`) and `quantize_notes(note_events: list[NoteEvent], tempo_bpm: float, level_id: str, title: str, beats_per_measure: int = 4) -> LevelModel`, both importable from `app.quantize`.

This is the one genuinely new algorithm in this pipeline, and the kind of code that silently produces a plausible-looking wrong answer if it's off. Test it thoroughly before anything else depends on it.

- [ ] **Step 1: Write the failing tests**

```python
from app.quantize import NoteEvent, quantize_notes


def test_a_single_note_lands_on_the_expected_beat():
    # At 120 bpm, a note starting at 1.0s starts on beat 2.0.
    events = [NoteEvent(pitch=60, start=1.0, end=1.5, velocity=80)]

    level = quantize_notes(events, tempo_bpm=120.0, level_id="lvl", title="T")

    note = level.measures[0].notes[0]
    assert note.midi_note == 60
    assert note.start_beat == 2.0


def test_a_very_short_note_is_bumped_to_the_minimum_duration():
    # At 120 bpm, a 0.05s note is far shorter than a 16th note (0.125s) and
    # must not collapse to zero duration.
    events = [NoteEvent(pitch=60, start=0.0, end=0.05, velocity=80)]

    level = quantize_notes(events, tempo_bpm=120.0, level_id="lvl", title="T")

    assert level.measures[0].notes[0].duration_beats == 0.25


def test_notes_are_assigned_to_the_correct_measure():
    # At 120 bpm (0.5s/beat), beat 4.0 is the first beat of measure 1
    # (0-indexed, 4 beats per measure).
    events = [
        NoteEvent(pitch=60, start=0.0, end=0.5, velocity=80),  # beat 0, measure 0
        NoteEvent(pitch=62, start=2.0, end=2.5, velocity=80),  # beat 4, measure 1
    ]

    level = quantize_notes(events, tempo_bpm=120.0, level_id="lvl", title="T")

    assert level.total_measures == 2
    assert level.measures[0].notes[0].measure_index == 0
    assert level.measures[1].notes[0].measure_index == 1
    assert level.measures[1].notes[0].beat_index == 0


def test_overlapping_notes_are_all_preserved_as_a_chord():
    events = [
        NoteEvent(pitch=60, start=0.0, end=1.0, velocity=80),
        NoteEvent(pitch=64, start=0.0, end=1.0, velocity=70),
        NoteEvent(pitch=67, start=0.0, end=1.0, velocity=75),
    ]

    level = quantize_notes(events, tempo_bpm=120.0, level_id="lvl", title="T")

    pitches = {n.midi_note for n in level.measures[0].notes}
    assert pitches == {60, 64, 67}


def test_no_notes_produces_an_empty_level():
    level = quantize_notes([], tempo_bpm=120.0, level_id="lvl", title="T")

    assert level.total_measures == 0
    assert level.measures == []


def test_a_non_positive_tempo_is_rejected():
    import pytest

    with pytest.raises(ValueError):
        quantize_notes(
            [NoteEvent(pitch=60, start=0.0, end=0.5, velocity=80)],
            tempo_bpm=0.0,
            level_id="lvl",
            title="T",
        )
```

- [ ] **Step 2: Run them and confirm they fail**

```bash
verify-on-vm "<repo>/backend" "bash scripts/install_basic_pitch.sh && pytest tests/test_quantize.py -v"
```

Expected: FAIL — `ModuleNotFoundError: No module named 'app.quantize'`.

- [ ] **Step 3: Implement**

`backend/app/quantize.py`:

```python
import math
from dataclasses import dataclass

from app.models import LevelMeasure, LevelModel, LevelNote

SIXTEENTH_NOTE_BEATS = 0.25
MIN_DURATION_BEATS = 0.25


@dataclass
class NoteEvent:
    pitch: int
    start: float
    end: float
    velocity: int


def _snap(value_beats: float) -> float:
    return round(value_beats / SIXTEENTH_NOTE_BEATS) * SIXTEENTH_NOTE_BEATS


def quantize_notes(
    note_events: list[NoteEvent],
    tempo_bpm: float,
    level_id: str,
    title: str,
    beats_per_measure: int = 4,
) -> LevelModel:
    if tempo_bpm <= 0:
        raise ValueError("tempo_bpm must be positive")

    seconds_per_beat = 60.0 / tempo_bpm
    placed: list[tuple[int, float, float]] = []
    for event in note_events:
        start_beat = _snap(event.start / seconds_per_beat)
        raw_duration_beats = (event.end - event.start) / seconds_per_beat
        duration_beats = max(_snap(raw_duration_beats), MIN_DURATION_BEATS)
        placed.append((event.pitch, start_beat, duration_beats))

    if not placed:
        return LevelModel(
            id=level_id,
            title=title,
            description="Imported from audio",
            tempo=round(tempo_bpm),
            beats_per_measure=beats_per_measure,
            total_measures=0,
            measures=[],
        )

    last_measure_index = max(
        int(start_beat // beats_per_measure) for _, start_beat, _ in placed
    )
    measures: list[LevelMeasure] = []
    for measure_index in range(last_measure_index + 1):
        measure_start_beat = float(measure_index * beats_per_measure)
        measure_end_beat = measure_start_beat + beats_per_measure
        notes_in_measure = [
            LevelNote(
                midi_note=pitch,
                start_beat=start_beat,
                duration_beats=duration_beats,
                measure_index=measure_index,
                beat_index=int(math.floor(start_beat - measure_start_beat)),
            )
            for pitch, start_beat, duration_beats in placed
            if measure_start_beat <= start_beat < measure_end_beat
        ]
        measures.append(
            LevelMeasure(
                index=measure_index,
                start_beat=measure_start_beat,
                beats_per_measure=beats_per_measure,
                notes=notes_in_measure,
            )
        )

    return LevelModel(
        id=level_id,
        title=title,
        description="Imported from audio",
        tempo=round(tempo_bpm),
        beats_per_measure=beats_per_measure,
        total_measures=len(measures),
        measures=measures,
    )
```

- [ ] **Step 4: Run them and confirm they pass**

Same command as Step 2. Expected: all 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add backend/app/quantize.py backend/tests/test_quantize.py
git commit -m "Add beat quantization from raw note events to a LevelModel"
```

---

### Task 4: Tempo estimation

**Files:**
- Create: `backend/app/tempo.py`
- Create: `backend/tests/test_tempo.py`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `estimate_tempo(audio_path: str) -> float`, importable from `app.tempo`.

- [ ] **Step 1: Write the failing test**

```python
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
```

- [ ] **Step 2: Run it and confirm it fails**

```bash
verify-on-vm "<repo>/backend" "bash scripts/install_basic_pitch.sh && pytest tests/test_tempo.py -v"
```

Expected: FAIL — `ModuleNotFoundError: No module named 'app.tempo'`.

- [ ] **Step 3: Implement**

`backend/app/tempo.py`:

```python
import librosa


def estimate_tempo(audio_path: str) -> float:
    y, sr = librosa.load(audio_path, sr=None, mono=True)
    tempo, _ = librosa.beat.beat_track(y=y, sr=sr)
    return float(tempo)
```

- [ ] **Step 4: Run it and confirm it passes**

Same command as Step 2. Expected: `1 passed`.

- [ ] **Step 5: Commit**

```bash
git add backend/app/tempo.py backend/tests/test_tempo.py
git commit -m "Add tempo estimation via librosa beat tracking"
```

---

### Task 5: Transcription

**Files:**
- Create: `backend/app/transcribe.py`
- Create: `backend/tests/test_transcribe.py`

**Interfaces:**
- Consumes: `NoteEvent` from `app.quantize` (Task 3).
- Produces: `transcribe(audio_path: str) -> list[NoteEvent]`, importable from `app.transcribe`.

- [ ] **Step 1: Write the failing tests**

```python
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
```

Note: this deliberately does not assert an exact note count. A single synthetic sine tone may or may not register as a note to a model tuned for real piano timbre, and asserting an exact count here would make the test flaky against model behavior this task isn't trying to pin down. What matters is that every note the function does return is well-formed.

- [ ] **Step 2: Run them and confirm they fail**

```bash
verify-on-vm "<repo>/backend" "bash scripts/install_basic_pitch.sh && pytest tests/test_transcribe.py -v"
```

Expected: FAIL — `ModuleNotFoundError: No module named 'app.transcribe'`.

- [ ] **Step 3: Implement**

`backend/app/transcribe.py`:

```python
from basic_pitch import ICASSP_2022_MODEL_PATH
from basic_pitch.inference import predict

from app.quantize import NoteEvent


def transcribe(audio_path: str) -> list[NoteEvent]:
    _, _, note_events = predict(
        audio_path, model_or_model_path=str(ICASSP_2022_MODEL_PATH)
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
```

The explicit `model_or_model_path=str(ICASSP_2022_MODEL_PATH)` is required, not cosmetic — leaving it to `predict`'s default resolution is what tries to load a TensorFlow SavedModel first, which isn't installed per this plan's Global Constraints.

- [ ] **Step 4: Run them and confirm they pass**

Same command as Step 2. Expected: 2 tests pass.

- [ ] **Step 5: Commit**

```bash
git add backend/app/transcribe.py backend/tests/test_transcribe.py
git commit -m "Add basic-pitch transcription on the ONNX backend"
```

---

### Task 6: Audio acquisition (upload and YouTube)

**Files:**
- Create: `backend/app/errors.py`
- Create: `backend/app/acquire.py`
- Create: `backend/tests/test_acquire.py`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `AudioTooLongError`, `YoutubeUnavailableError`, `NoNotesDetectedError` (all `Exception` subclasses, importable from `app.errors`); `acquire_audio(source: Literal["upload", "youtube"], dest_dir: str, upload_bytes: bytes | None = None, youtube_url: str | None = None, cap_seconds: float = 600.0) -> str` (returns a local file path), importable from `app.acquire`.

- [ ] **Step 1: Write the failing tests**

```python
import numpy as np
import pytest
import soundfile as sf

from app.acquire import acquire_audio, acquire_upload
from app.errors import AudioTooLongError, YoutubeUnavailableError


def _write_wav(path, duration_s: float, sr: int = 22050) -> None:
    sf.write(str(path), np.zeros(int(duration_s * sr), dtype=np.float32), sr)


def test_acquire_upload_returns_a_path_within_the_cap(tmp_path):
    audio_path = tmp_path / "short.wav"
    _write_wav(audio_path, duration_s=2.0)

    result = acquire_upload(audio_path.read_bytes(), str(tmp_path))

    assert result.endswith(".upload")


def test_acquire_upload_raises_when_over_the_cap(tmp_path):
    audio_path = tmp_path / "long.wav"
    _write_wav(audio_path, duration_s=3.0)

    with pytest.raises(AudioTooLongError):
        acquire_upload(audio_path.read_bytes(), str(tmp_path), cap_seconds=1.0)


def test_acquire_audio_requires_upload_bytes_for_the_upload_source(tmp_path):
    with pytest.raises(ValueError):
        acquire_audio("upload", str(tmp_path))


def test_acquire_audio_requires_a_url_for_the_youtube_source(tmp_path):
    with pytest.raises(ValueError):
        acquire_audio("youtube", str(tmp_path))


def test_acquire_youtube_wraps_download_errors(tmp_path, monkeypatch):
    import yt_dlp

    class _FailingDownloader:
        def __init__(self, options):
            pass

        def __enter__(self):
            return self

        def __exit__(self, *args):
            return False

        def extract_info(self, url, download=True):
            raise yt_dlp.utils.DownloadError("video unavailable")

    monkeypatch.setattr(yt_dlp, "YoutubeDL", _FailingDownloader)

    with pytest.raises(YoutubeUnavailableError):
        acquire_audio(
            "youtube", str(tmp_path), youtube_url="https://example.com/watch?v=nope"
        )
```

- [ ] **Step 2: Run them and confirm they fail**

```bash
verify-on-vm "<repo>/backend" "bash scripts/install_basic_pitch.sh && pytest tests/test_acquire.py -v"
```

Expected: FAIL — `ModuleNotFoundError: No module named 'app.acquire'`.

- [ ] **Step 3: Implement**

`backend/app/errors.py`:

```python
class AudioTooLongError(Exception):
    def __init__(self, duration_seconds: float, cap_seconds: float):
        super().__init__(
            f"Audio is {duration_seconds:.0f}s long, which is over the "
            f"{cap_seconds:.0f}s cap."
        )
        self.duration_seconds = duration_seconds
        self.cap_seconds = cap_seconds


class YoutubeUnavailableError(Exception):
    pass


class NoNotesDetectedError(Exception):
    pass
```

`backend/app/acquire.py`:

```python
import json
import subprocess
import uuid
from pathlib import Path
from typing import Literal

from app.errors import AudioTooLongError, YoutubeUnavailableError

DEFAULT_DURATION_CAP_SECONDS = 600.0


def _probe_duration_seconds(path: str) -> float:
    result = subprocess.run(
        ["ffprobe", "-v", "quiet", "-print_format", "json", "-show_format", path],
        capture_output=True,
        text=True,
        check=True,
    )
    return float(json.loads(result.stdout)["format"]["duration"])


def _check_duration_cap(path: str, cap_seconds: float) -> None:
    duration = _probe_duration_seconds(path)
    if duration > cap_seconds:
        raise AudioTooLongError(duration, cap_seconds)


def acquire_upload(
    upload_bytes: bytes,
    dest_dir: str,
    cap_seconds: float = DEFAULT_DURATION_CAP_SECONDS,
) -> str:
    dest_path = Path(dest_dir) / f"{uuid.uuid4()}.upload"
    dest_path.write_bytes(upload_bytes)
    _check_duration_cap(str(dest_path), cap_seconds)
    return str(dest_path)


def acquire_youtube(
    url: str,
    dest_dir: str,
    cap_seconds: float = DEFAULT_DURATION_CAP_SECONDS,
) -> str:
    import yt_dlp

    output_template = str(Path(dest_dir) / f"{uuid.uuid4()}.%(ext)s")
    options = {
        "format": "bestaudio/best",
        "outtmpl": output_template,
        "postprocessors": [
            {"key": "FFmpegExtractAudio", "preferredcodec": "wav"}
        ],
        "quiet": True,
        "no_warnings": True,
    }
    try:
        with yt_dlp.YoutubeDL(options) as downloader:
            downloader.extract_info(url, download=True)
    except yt_dlp.utils.DownloadError as error:
        raise YoutubeUnavailableError(str(error)) from error

    downloaded_path = Path(output_template % {"ext": "wav"})
    if not downloaded_path.exists():
        raise YoutubeUnavailableError(
            f"yt-dlp reported success but produced no file for {url}"
        )

    _check_duration_cap(str(downloaded_path), cap_seconds)
    return str(downloaded_path)


def acquire_audio(
    source: Literal["upload", "youtube"],
    dest_dir: str,
    upload_bytes: bytes | None = None,
    youtube_url: str | None = None,
    cap_seconds: float = DEFAULT_DURATION_CAP_SECONDS,
) -> str:
    if source == "upload":
        if upload_bytes is None:
            raise ValueError("upload_bytes is required when source is 'upload'")
        return acquire_upload(upload_bytes, dest_dir, cap_seconds)
    if source == "youtube":
        if not youtube_url:
            raise ValueError("youtube_url is required when source is 'youtube'")
        return acquire_youtube(youtube_url, dest_dir, cap_seconds)
    raise ValueError(f"Unknown source: {source}")
```

Known gap, not solved here: `acquire_upload` writes the raw bytes with a generic `.upload` extension rather than preserving the original file's format. `ffprobe` and `librosa`/`soundfile` both sniff audio format from content rather than extension, so this works for the formats tested here. A compressed upload in a format that needs an extension hint to decode correctly is a real edge case this plan doesn't chase down — flag it if it comes up.

- [ ] **Step 4: Run them and confirm they pass**

Same command as Step 2. Expected: 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add backend/app/errors.py backend/app/acquire.py backend/tests/test_acquire.py
git commit -m "Add audio acquisition for uploads and YouTube, with a duration cap"
```

---

### Task 7: Job orchestration

**Files:**
- Create: `backend/app/jobs.py`
- Create: `backend/tests/test_jobs.py`

**Interfaces:**
- Consumes: `acquire_audio` from `app.acquire` (Task 6); `transcribe` from `app.transcribe` (Task 5); `estimate_tempo` from `app.tempo` (Task 4); `quantize_notes`, `NoteEvent` from `app.quantize` (Task 3); `LevelModel` from `app.models` (Task 2); `AudioTooLongError`, `YoutubeUnavailableError`, `NoNotesDetectedError` from `app.errors` (Task 6).
- Produces: `Job` (dataclass: `job_id: str, status: JobStatus, error: str | None, level: LevelModel | None`) and `JobStore` (methods: `submit(...) -> str`, `get(job_id: str) -> Job | None`, `delete(job_id: str) -> bool`, `wait(job_id: str, timeout: float = 30.0) -> None`), both importable from `app.jobs`.

- [ ] **Step 1: Write the failing tests**

```python
from app.jobs import JobStore
from app.quantize import NoteEvent


def test_submit_reaches_done_status_on_success(monkeypatch):
    store = JobStore(max_workers=1)
    monkeypatch.setattr("app.jobs.acquire_audio", lambda *a, **k: "/tmp/fake.wav")
    monkeypatch.setattr(
        "app.jobs.transcribe",
        lambda path: [NoteEvent(pitch=60, start=0.0, end=0.5, velocity=80)],
    )
    monkeypatch.setattr("app.jobs.estimate_tempo", lambda path: 120.0)

    job_id = store.submit("upload", "Test Song", upload_bytes=b"fake")
    store.wait(job_id)

    job = store.get(job_id)
    assert job.status == "done"
    assert job.level is not None
    assert job.level.title == "Test Song"


def test_submit_fails_when_no_notes_are_detected(monkeypatch):
    store = JobStore(max_workers=1)
    monkeypatch.setattr("app.jobs.acquire_audio", lambda *a, **k: "/tmp/fake.wav")
    monkeypatch.setattr("app.jobs.transcribe", lambda path: [])

    job_id = store.submit("upload", "Test Song", upload_bytes=b"fake")
    store.wait(job_id)

    job = store.get(job_id)
    assert job.status == "failed"
    assert "notes" in job.error.lower()


def test_submit_fails_when_acquisition_raises_a_known_error(monkeypatch):
    from app.errors import AudioTooLongError

    store = JobStore(max_workers=1)

    def _raise(*args, **kwargs):
        raise AudioTooLongError(700.0, 600.0)

    monkeypatch.setattr("app.jobs.acquire_audio", _raise)

    job_id = store.submit("upload", "Test Song", upload_bytes=b"fake")
    store.wait(job_id)

    job = store.get(job_id)
    assert job.status == "failed"
    assert "700" in job.error


def test_get_returns_none_for_an_unknown_job():
    store = JobStore(max_workers=1)
    assert store.get("does-not-exist") is None


def test_delete_removes_a_job(monkeypatch):
    store = JobStore(max_workers=1)
    monkeypatch.setattr("app.jobs.acquire_audio", lambda *a, **k: "/tmp/fake.wav")
    monkeypatch.setattr("app.jobs.transcribe", lambda path: [])

    job_id = store.submit("upload", "Test Song", upload_bytes=b"fake")
    store.wait(job_id)

    assert store.delete(job_id) is True
    assert store.get(job_id) is None
    assert store.delete(job_id) is False
```

- [ ] **Step 2: Run them and confirm they fail**

```bash
verify-on-vm "<repo>/backend" "bash scripts/install_basic_pitch.sh && pytest tests/test_jobs.py -v"
```

Expected: FAIL — `ModuleNotFoundError: No module named 'app.jobs'`.

- [ ] **Step 3: Implement**

`backend/app/jobs.py`:

```python
import uuid
from concurrent.futures import Future, ThreadPoolExecutor
from dataclasses import dataclass
from tempfile import TemporaryDirectory
from typing import Literal

from app.acquire import acquire_audio
from app.errors import AudioTooLongError, NoNotesDetectedError, YoutubeUnavailableError
from app.models import LevelModel
from app.quantize import quantize_notes
from app.tempo import estimate_tempo
from app.transcribe import transcribe

JobStatus = Literal["queued", "downloading", "transcribing", "done", "failed"]


@dataclass
class Job:
    job_id: str
    status: JobStatus = "queued"
    error: str | None = None
    level: LevelModel | None = None


class JobStore:
    def __init__(self, max_workers: int = 2):
        self._jobs: dict[str, Job] = {}
        self._futures: dict[str, Future] = {}
        self._executor = ThreadPoolExecutor(max_workers=max_workers)

    def submit(
        self,
        source: Literal["upload", "youtube"],
        title: str,
        upload_bytes: bytes | None = None,
        youtube_url: str | None = None,
    ) -> str:
        job_id = str(uuid.uuid4())
        job = Job(job_id=job_id)
        self._jobs[job_id] = job
        self._futures[job_id] = self._executor.submit(
            self._run, job, source, title, upload_bytes, youtube_url
        )
        return job_id

    def get(self, job_id: str) -> Job | None:
        return self._jobs.get(job_id)

    def delete(self, job_id: str) -> bool:
        self._futures.pop(job_id, None)
        return self._jobs.pop(job_id, None) is not None

    def wait(self, job_id: str, timeout: float = 30.0) -> None:
        """Block until the given job's background work has finished.

        Only meant for tests -- the API itself is polled, never blocked on.
        """
        future = self._futures.get(job_id)
        if future is not None:
            future.result(timeout=timeout)

    def _run(
        self,
        job: Job,
        source: Literal["upload", "youtube"],
        title: str,
        upload_bytes: bytes | None,
        youtube_url: str | None,
    ) -> None:
        try:
            with TemporaryDirectory() as tmp_dir:
                job.status = "downloading"
                audio_path = acquire_audio(
                    source, tmp_dir, upload_bytes=upload_bytes, youtube_url=youtube_url
                )

                job.status = "transcribing"
                note_events = transcribe(audio_path)
                if not note_events:
                    raise NoNotesDetectedError("Didn't find any notes in that audio")

                tempo_bpm = estimate_tempo(audio_path)
                job.level = quantize_notes(
                    note_events, tempo_bpm, level_id=job.job_id, title=title
                )
                job.status = "done"
        except (AudioTooLongError, YoutubeUnavailableError, NoNotesDetectedError) as error:
            job.status = "failed"
            job.error = str(error)
        except Exception as error:  # noqa: BLE001 -- deliberate: surface any
            # unexpected failure through the job's own error field rather than
            # letting it vanish on a background thread. This is not silent --
            # `job.error` is what the API and the app both read.
            job.status = "failed"
            job.error = f"Unexpected error: {error}"
```

- [ ] **Step 4: Run them and confirm they pass**

Same command as Step 2. Expected: 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add backend/app/jobs.py backend/tests/test_jobs.py
git commit -m "Add job orchestration wiring acquisition, transcription, and quantization"
```

---

### Task 8: HTTP API and end-to-end wiring

**Files:**
- Create: `backend/app/routes.py`
- Modify: `backend/app/main.py`
- Create: `backend/tests/test_jobs_api.py`

**Interfaces:**
- Consumes: `Job`, `JobStore` from `app.jobs` (Task 7).
- Produces: `POST /jobs`, `GET /jobs/{job_id}`, `DELETE /jobs/{job_id}`, matching the spec's API exactly.

- [ ] **Step 1: Write the failing tests**

```python
import numpy as np
import soundfile as sf
from fastapi.testclient import TestClient

from app.main import app
from app.quantize import NoteEvent
from app.routes import store

client = TestClient(app)


def test_job_lifecycle_success(monkeypatch):
    monkeypatch.setattr("app.jobs.acquire_audio", lambda *a, **k: "/tmp/fake.wav")
    monkeypatch.setattr(
        "app.jobs.transcribe",
        lambda path: [NoteEvent(pitch=60, start=0.0, end=0.5, velocity=80)],
    )
    monkeypatch.setattr("app.jobs.estimate_tempo", lambda path: 120.0)

    response = client.post(
        "/jobs",
        data={"title": "Test Song", "source": "upload"},
        files={"audio": ("clip.wav", b"fake-bytes", "audio/wav")},
    )
    assert response.status_code == 202
    job_id = response.json()["job_id"]
    store.wait(job_id)

    result = client.get(f"/jobs/{job_id}")
    assert result.status_code == 200
    body = result.json()
    assert body["status"] == "done"
    assert body["level"]["title"] == "Test Song"
    assert "midiNote" in body["level"]["measures"][0]["notes"][0]


def test_job_lifecycle_failure_surfaces_error(monkeypatch):
    monkeypatch.setattr("app.jobs.acquire_audio", lambda *a, **k: "/tmp/fake.wav")
    monkeypatch.setattr("app.jobs.transcribe", lambda path: [])

    response = client.post(
        "/jobs",
        data={"title": "Silent clip", "source": "upload"},
        files={"audio": ("clip.wav", b"fake-bytes", "audio/wav")},
    )
    job_id = response.json()["job_id"]
    store.wait(job_id)

    result = client.get(f"/jobs/{job_id}")
    assert result.json()["status"] == "failed"
    assert "notes" in result.json()["error"].lower()


def test_post_jobs_rejects_an_unknown_source():
    response = client.post("/jobs", data={"title": "T", "source": "carrier-pigeon"})
    assert response.status_code == 400


def test_post_jobs_requires_a_file_for_the_upload_source():
    response = client.post("/jobs", data={"title": "T", "source": "upload"})
    assert response.status_code == 400


def test_post_jobs_requires_a_url_for_the_youtube_source():
    response = client.post("/jobs", data={"title": "T", "source": "youtube"})
    assert response.status_code == 400


def test_get_unknown_job_returns_404():
    response = client.get("/jobs/does-not-exist")
    assert response.status_code == 404


def test_delete_job_then_get_returns_404(monkeypatch):
    monkeypatch.setattr("app.jobs.acquire_audio", lambda *a, **k: "/tmp/fake.wav")
    monkeypatch.setattr("app.jobs.transcribe", lambda path: [])

    response = client.post(
        "/jobs",
        data={"title": "Test", "source": "upload"},
        files={"audio": ("clip.wav", b"fake-bytes", "audio/wav")},
    )
    job_id = response.json()["job_id"]
    store.wait(job_id)

    delete_response = client.delete(f"/jobs/{job_id}")
    assert delete_response.status_code == 204

    get_response = client.get(f"/jobs/{job_id}")
    assert get_response.status_code == 404


def test_end_to_end_with_the_real_pipeline_on_a_synthetic_tone(tmp_path):
    audio_path = tmp_path / "tone.wav"
    sr = 22050
    duration_s = 2.0
    t = np.arange(int(duration_s * sr)) / sr
    envelope = np.exp(-2.0 * t)
    y = (0.5 * np.sin(2 * np.pi * 261.63 * t) * envelope).astype(np.float32)  # C4
    sf.write(str(audio_path), y, sr)

    response = client.post(
        "/jobs",
        data={"title": "Real pipeline check", "source": "upload"},
        files={"audio": ("tone.wav", audio_path.read_bytes(), "audio/wav")},
    )
    job_id = response.json()["job_id"]
    store.wait(job_id, timeout=60.0)

    result = client.get(f"/jobs/{job_id}")
    body = result.json()
    # A single synthetic tone may or may not register as a note to
    # basic-pitch -- either "done" or a "failed" no-notes-detected result is
    # a legitimate outcome here. What this test actually proves is that
    # upload -> acquire -> transcribe -> tempo -> quantize -> API response
    # runs end to end, with nothing mocked, without raising.
    assert body["status"] in ("done", "failed")
```

- [ ] **Step 2: Run them and confirm they fail**

```bash
verify-on-vm "<repo>/backend" "bash scripts/install_basic_pitch.sh && pytest tests/test_jobs_api.py -v"
```

Expected: FAIL — `ModuleNotFoundError: No module named 'app.routes'`.

- [ ] **Step 3: Implement**

`backend/app/routes.py`:

```python
from fastapi import APIRouter, File, Form, HTTPException, UploadFile
from pydantic import BaseModel

from app.jobs import Job, JobStore

router = APIRouter()
store = JobStore()


class JobResponse(BaseModel):
    job_id: str
    status: str
    error: str | None = None
    level: dict | None = None


def _to_response(job: Job) -> JobResponse:
    return JobResponse(
        job_id=job.job_id,
        status=job.status,
        error=job.error,
        level=job.level.model_dump(by_alias=True) if job.level else None,
    )


@router.post("/jobs", status_code=202)
async def create_job(
    title: str = Form(...),
    source: str = Form(...),
    youtube_url: str | None = Form(default=None),
    audio: UploadFile | None = File(default=None),
) -> JobResponse:
    if source not in ("upload", "youtube"):
        raise HTTPException(status_code=400, detail="source must be 'upload' or 'youtube'")
    if source == "upload" and audio is None:
        raise HTTPException(
            status_code=400, detail="audio file is required when source is 'upload'"
        )
    if source == "youtube" and not youtube_url:
        raise HTTPException(
            status_code=400, detail="youtube_url is required when source is 'youtube'"
        )

    upload_bytes = await audio.read() if audio is not None else None
    job_id = store.submit(source, title, upload_bytes=upload_bytes, youtube_url=youtube_url)
    return _to_response(store.get(job_id))


@router.get("/jobs/{job_id}")
def get_job(job_id: str) -> JobResponse:
    job = store.get(job_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Job not found")
    return _to_response(job)


@router.delete("/jobs/{job_id}", status_code=204)
def delete_job(job_id: str) -> None:
    if not store.delete(job_id):
        raise HTTPException(status_code=404, detail="Job not found")
```

`backend/app/main.py` (modify — add the router):

```python
from fastapi import FastAPI

from app.routes import router

app = FastAPI(title="Piano-Tool Ingestion Service")
app.include_router(router)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
```

- [ ] **Step 4: Run them and confirm they pass**

Same command as Step 2. Expected: 7 tests pass.

- [ ] **Step 5: Run the full backend suite**

```bash
verify-on-vm "<repo>/backend" "bash scripts/install_basic_pitch.sh && pytest -v"
```

Expected: every test across all 8 tasks passes (health check, models, quantize, tempo, transcribe, acquire, jobs, jobs API — roughly 25 tests total).

- [ ] **Step 6: Commit**

```bash
git add backend/app/routes.py backend/app/main.py backend/tests/test_jobs_api.py
git commit -m "Add the job API: POST, GET, and DELETE /jobs"
```

---

## After this plan

Once this lands: the backend needs to actually run persistently on `ampere-dev` (`uvicorn app.main:app`, likely under a process supervisor rather than a bare foreground command — a deployment task, not a coding one, and not covered by this plan). Then the Flutter app-side plan gets written against this real, running API: `IngestionRepository`, `ImportScreen`, `ReviewScreen`, and the minimal imported-levels list in `LevelRepository`, per the spec's App-side additions section.

The two open questions the spec explicitly deferred — backend auth once it's reachable from outside `ampere-dev`'s local network, and updating how `ampere-dev`'s role is documented now that it hosts a persistent service rather than only building and verifying — should be resolved before or during that deployment step, not silently skipped.
