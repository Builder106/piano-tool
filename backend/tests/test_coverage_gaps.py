import asyncio
import os
import runpy
from pathlib import Path
from tempfile import SpooledTemporaryFile
from unittest.mock import Mock

import pytest
from fastapi import HTTPException, UploadFile

from app import acquire, main, routes, worker
from app.errors import MediaTooLargeError
from app.jobs import Job, JobStore


def _store(tmp_path, **kwargs):
    return JobStore(
        db_path=tmp_path / "jobs.sqlite3",
        spool_dir=tmp_path / "spool",
        start_workers=False,
        **kwargs,
    )


def test_acquire_upload_and_path_reject_oversized_media(tmp_path, monkeypatch):
    monkeypatch.setattr(acquire, "MAX_DOWNLOAD_BYTES", 3)
    with pytest.raises(MediaTooLargeError):
        acquire.acquire_upload(b"1234", str(tmp_path))

    path = tmp_path / "large.upload"
    path.write_bytes(b"1234")
    with pytest.raises(MediaTooLargeError):
        acquire.acquire_upload_path(path)


def test_acquire_audio_accepts_upload_bytes(tmp_path, monkeypatch):
    monkeypatch.setattr(acquire, "acquire_upload", lambda data, dest, cap: "converted.wav")
    assert acquire.acquire_audio("upload", str(tmp_path), upload_bytes=b"audio") == "converted.wav"


def test_jobstore_idempotency_removes_duplicate_spool(tmp_path):
    store = _store(tmp_path)
    job_id = store.submit("youtube", "Song", youtube_url="https://youtu.be/a", idempotency_key="k")
    duplicate = tmp_path / "duplicate.upload"
    duplicate.write_bytes(b"audio")
    assert (
        store.submit(
            "youtube",
            "Other",
            youtube_url="https://youtu.be/b",
            idempotency_key="k",
            upload_path=duplicate,
        )
        == job_id
    )
    assert not duplicate.exists()


def test_jobstore_rejects_full_queue_and_handles_upload_path(tmp_path):
    store = _store(tmp_path, max_pending=1)
    first = store.submit("youtube", "First", youtube_url="https://youtu.be/a")
    upload = tmp_path / "incoming.upload"
    upload.write_bytes(b"audio")
    with pytest.raises(ValueError, match="queue is full"):
        store.submit("upload", "Second", upload_path=upload)
    assert upload.exists()
    assert store.get(first).status == "queued"


def test_jobstore_claim_race_returns_none(tmp_path, monkeypatch):
    store = _store(tmp_path)
    store.submit("youtube", "Song", youtube_url="https://youtu.be/a")
    real_connect = store._connect

    class Result:
        rowcount = 0

    class Connection:
        def __enter__(self):
            return self

        def __exit__(self, *args):
            return False

        def execute(self, sql, params=()):
            if sql.startswith("SELECT * FROM jobs WHERE status='queued'"):
                return real_connect().__enter__().execute(sql, params)
            return Result()

    monkeypatch.setattr(store, "_connect", lambda: Connection())
    assert store.claim("racing-worker") is None


def test_jobstore_recovery_and_worker_once_empty(tmp_path):
    store = _store(tmp_path)
    assert store.run_worker_once() is False
    job_id = store.submit("youtube", "Song", youtube_url="https://youtu.be/a")
    assert store.claim("worker", lease_seconds=-1) is not None
    assert store.recover() == 1
    assert store.get(job_id).status == "queued"


def test_jobstore_worker_once_runs_claimed_job(tmp_path, monkeypatch):
    store = _store(tmp_path)
    claimed = Job("claimed")
    monkeypatch.setattr(store, "claim", lambda worker_id: claimed)
    run = Mock()
    monkeypatch.setattr(store, "_run_claimed", run)
    assert store.run_worker_once("worker") is True
    run.assert_called_once_with("claimed")


def test_jobstore_claimed_and_cancelled_guards(tmp_path):
    store = _store(tmp_path)
    assert store._run_claimed("missing") is None
    job_id = store.submit("youtube", "Song", youtube_url="https://youtu.be/a")
    store.delete(job_id)
    assert store._run_claimed(job_id) is None
    store._finish(job_id, "done")
    assert store.get(job_id).status == "cancelled"


def test_jobstore_rechecks_cancellation_before_pipeline(tmp_path, monkeypatch):
    store = _store(tmp_path)
    job_id = store.submit("youtube", "Song", youtube_url="https://youtu.be/a")
    store.claim("worker")
    original_connect = store._connect
    with original_connect() as db:
        db.execute("UPDATE jobs SET cancelled=1, status='cancelled' WHERE job_id=?", (job_id,))
    original_get = store.get
    monkeypatch.setattr(store, "get", lambda _job_id: Job(job_id))
    store._run_claimed(job_id)
    assert original_get(job_id).status == "cancelled"


def test_jobstore_cleanup_and_finish_guards(tmp_path):
    store = _store(tmp_path)
    job_id = store.submit("youtube", "Song", youtube_url="https://youtu.be/a")
    store.delete(job_id)
    store._finish(job_id, "done")
    assert store.get(job_id).status == "cancelled"
    store._remove_spool("does-not-exist")


def test_jobstore_reaps_terminal_jobs(tmp_path):
    store = _store(tmp_path, retention_seconds=1)
    job_id = store.submit("youtube", "Song", youtube_url="https://youtu.be/a")
    with store._connect() as db:
        db.execute(
            "UPDATE jobs SET status='failed', updated_at=? WHERE job_id=?", (0, job_id)
        )
    assert store.get(job_id) is None


def test_bounded_spool_writes_chunks_and_cleans_oversized_upload(monkeypatch, tmp_path):
    monkeypatch.setattr(routes, "MAX_MEDIA_BYTES", 3)
    file = SpooledTemporaryFile()
    file.write(b"123")
    file.seek(0)
    upload = UploadFile(file, filename="clip.wav")
    path = asyncio.run(routes._spool_bounded(upload))
    assert Path(path).read_bytes() == b"123"
    os.unlink(path)
    file.close()

    too_large = SpooledTemporaryFile()
    too_large.write(b"1234")
    too_large.seek(0)
    with pytest.raises(HTTPException) as error:
        asyncio.run(routes._spool_bounded(UploadFile(too_large, filename="large.wav")))
    assert error.value.status_code == 413
    assert list(routes.store.spool_dir.glob("incoming-*")) == []
    too_large.close()


def test_auth_and_rate_limit_edges(monkeypatch):
    monkeypatch.setattr(routes, "API_TOKEN", None)
    with pytest.raises(HTTPException) as missing:
        routes._require_auth("Bearer test-token")
    assert missing.value.status_code == 503
    monkeypatch.setattr(routes, "API_TOKEN", "test-token")
    with pytest.raises(HTTPException) as malformed:
        routes._require_auth("Basic test-token")
    assert malformed.value.status_code == 401
    with pytest.raises(HTTPException) as rate:
        for _ in range(routes.RATE_LIMIT + 1):
            routes._check_rate_limit("rate-test")
    assert rate.value.status_code == 429
    routes._submissions["expired"].append(0)
    routes._check_rate_limit("expired")


def test_create_job_validation_and_queue_cleanup(monkeypatch, tmp_path):
    audio = UploadFile(SpooledTemporaryFile(), filename="clip.wav")
    with pytest.raises(HTTPException) as title:
        asyncio.run(
            routes.create_job(
                "x" * (routes.MAX_TITLE_LENGTH + 1), "upload", audio=audio, identity="id"
            )
        )
    assert title.value.status_code == 400

    upload_path = tmp_path / "upload"
    upload_path.write_bytes(b"audio")
    monkeypatch.setattr(
        routes, "_spool_bounded", lambda audio: asyncio.sleep(0, result=str(upload_path))
    )
    monkeypatch.setattr(routes.store, "submit", Mock(side_effect=ValueError("full")))
    with pytest.raises(HTTPException) as full:
        asyncio.run(routes.create_job("title", "upload", audio=audio, identity="id"))
    assert full.value.status_code == 429
    with pytest.raises(HTTPException) as cleanup_without_upload:
        asyncio.run(
            routes.create_job(
                "title",
                "youtube",
                youtube_url="https://youtu.be/a",
                audio=None,
                identity="other-id",
            )
        )
    assert cleanup_without_upload.value.status_code == 429
    audio.file.close()


def test_ready_reports_missing_and_success(monkeypatch):
    monkeypatch.setattr(main.shutil, "which", lambda name: "/bin/" + name)
    monkeypatch.setattr(main.importlib.util, "find_spec", lambda name: None)
    missing = main.ready()
    assert missing.status_code == 503
    monkeypatch.setattr(main.importlib.util, "find_spec", lambda name: object())
    assert main.ready() == {"status": "ready"}


def test_worker_main_polls_until_interrupted(monkeypatch):
    fake_store = Mock()
    fake_store.run_worker_once.side_effect = [True, False]
    monkeypatch.setattr(worker, "JobStore", lambda start_workers: fake_store)
    monkeypatch.setattr(worker.uuid, "uuid4", lambda: "worker-id")

    def interrupt(_seconds):
        raise KeyboardInterrupt

    monkeypatch.setattr(worker.time, "sleep", interrupt)
    with pytest.raises(KeyboardInterrupt):
        worker.main()
    fake_store.recover.assert_called_once_with()
    assert fake_store.run_worker_once.call_count == 2


def test_worker_script_entrypoint_calls_main(monkeypatch):
    fake_store = Mock()
    fake_store.run_worker_once.return_value = False
    monkeypatch.setattr("app.jobs.JobStore", lambda start_workers: fake_store)
    monkeypatch.setattr(worker.time, "sleep", Mock(side_effect=KeyboardInterrupt))
    with pytest.raises(KeyboardInterrupt):
        runpy.run_path(worker.__file__, run_name="__main__")
