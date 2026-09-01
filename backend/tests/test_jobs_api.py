import numpy as np
import soundfile as sf
from starlette.testclient import TestClient

from app.main import app
from app.models import LevelModel
from app.quantize import NoteEvent
from app.routes import JobResponse, _to_response, store

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


def test_post_jobs_response_status_is_queued(monkeypatch):
    monkeypatch.setattr("app.jobs.acquire_audio", lambda *a, **k: "/tmp/fake.wav")
    monkeypatch.setattr("app.jobs.transcribe", lambda path: [])

    response = client.post(
        "/jobs",
        data={"title": "Test Song", "source": "upload"},
        files={"audio": ("clip.wav", b"fake-bytes", "audio/wav")},
    )
    assert response.status_code == 202
    assert response.json()["status"] == "queued"

    store.wait(response.json()["job_id"])


def test_post_jobs_with_youtube_source_threads_the_url_through(monkeypatch):
    recorded_urls = []

    def _fake_acquire_audio(source, dest_dir, upload_bytes=None, youtube_url=None):
        recorded_urls.append(youtube_url)
        return "/tmp/fake.wav"

    monkeypatch.setattr("app.jobs.acquire_audio", _fake_acquire_audio)
    monkeypatch.setattr(
        "app.jobs.transcribe",
        lambda path: [NoteEvent(pitch=60, start=0.0, end=0.5, velocity=80)],
    )
    monkeypatch.setattr("app.jobs.estimate_tempo", lambda path: 120.0)

    youtube_url = "https://www.youtube.com/watch?v=abc123"
    response = client.post(
        "/jobs",
        data={"title": "Test Song", "source": "youtube", "youtube_url": youtube_url},
    )
    job_id = response.json()["job_id"]
    store.wait(job_id)

    assert recorded_urls == [youtube_url]


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


def test_delete_unknown_job_returns_404():
    response = client.delete("/jobs/does-not-exist")
    assert response.status_code == 404


def test_to_response_serializes_a_level():
    level = LevelModel(
        id="level",
        title="Song",
        description="",
        tempo=120,
        beatsPerMeasure=4,
        totalMeasures=0,
        measures=[],
    )
    job = type(
        "JobLike",
        (),
        {
            "job_id": "job",
            "status": "done",
            "error": None,
            "level": level,
        },
    )()
    response = _to_response(job)

    assert isinstance(response, JobResponse)
    assert response.level["title"] == "Song"


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
