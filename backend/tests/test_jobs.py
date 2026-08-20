import time

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


def test_submit_falls_back_to_default_tempo_when_estimate_is_zero(monkeypatch):
    store = JobStore(max_workers=1)
    monkeypatch.setattr("app.jobs.acquire_audio", lambda *a, **k: "/tmp/fake.wav")
    monkeypatch.setattr(
        "app.jobs.transcribe",
        lambda path: [NoteEvent(pitch=60, start=0.0, end=0.5, velocity=80)],
    )
    monkeypatch.setattr("app.jobs.estimate_tempo", lambda path: 0.0)

    job_id = store.submit("upload", "Test Song", upload_bytes=b"fake")
    store.wait(job_id)

    job = store.get(job_id)
    assert job.status == "done"
    assert job.level.tempo == 120


def test_delete_prevents_a_queued_but_not_yet_started_job_from_running(monkeypatch):
    store = JobStore(max_workers=1)

    def _slow_acquire(*args, **kwargs):
        time.sleep(0.3)
        return "/tmp/fake.wav"

    monkeypatch.setattr("app.jobs.acquire_audio", _slow_acquire)
    monkeypatch.setattr("app.jobs.transcribe", lambda path: [])

    first_job_id = store.submit("upload", "First", upload_bytes=b"fake")
    second_job_id = store.submit("upload", "Second", upload_bytes=b"fake")
    store.delete(second_job_id)

    assert store.get(second_job_id) is None

    store.wait(first_job_id)


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
