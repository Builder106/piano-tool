from __future__ import annotations

import json
import os
import shutil
import sqlite3
import threading
import time
import uuid
from concurrent.futures import Future, ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Literal

from app.acquire import acquire_audio
from app.errors import (
    AudioTooLongError,
    MediaTooLargeError,
    NoNotesDetectedError,
    YoutubeUnavailableError,
)
from app.models import LevelModel
from app.quantize import quantize_notes
from app.tempo import estimate_tempo
from app.transcribe import transcribe

JobStatus = Literal["queued", "downloading", "transcribing", "done", "failed", "cancelled"]
DEFAULT_TEMPO_BPM = 120.0
DEFAULT_RETENTION_SECONDS = 24 * 60 * 60


@dataclass
class Job:
    job_id: str
    status: JobStatus = "queued"
    error: str | None = None
    error_code: str | None = None
    retryable: bool = False
    level: LevelModel | None = None
    cancelled: bool = False


class JobStore:
    """SQLite-backed job repository with an optional local test worker."""

    def __init__(  # noqa: PLR0913, PLR0917
        self,
        db_path: str | Path | None = None,
        spool_dir: str | Path | None = None,
        max_workers: int = 2,
        start_workers: bool = True,
        max_pending: int = 4,
        retention_seconds: float = DEFAULT_RETENTION_SECONDS,
    ) -> None:
        self.db_path = (
            Path(db_path)
            if db_path is not None
            else Path(os.getenv("PIANO_TOOL_DB", "data/jobs.sqlite3"))
        )
        self.spool_dir = (
            Path(spool_dir)
            if spool_dir is not None
            else Path(os.getenv("PIANO_TOOL_SPOOL", "data/jobs"))
        )
        self.max_pending = max_pending
        self.retention_seconds = retention_seconds
        self._lock = threading.RLock()
        self._futures: dict[str, Future[None]] = {}
        self._executor = ThreadPoolExecutor(max_workers=max_workers) if start_workers else None
        self._ensure_schema()

    def _connect(self) -> sqlite3.Connection:
        connection = sqlite3.connect(self.db_path, timeout=30, check_same_thread=False)
        connection.row_factory = sqlite3.Row
        connection.execute("PRAGMA busy_timeout=30000")
        return connection

    def _ensure_schema(self) -> None:
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self.spool_dir.mkdir(parents=True, exist_ok=True)
        with self._connect() as db:
            db.execute("PRAGMA journal_mode=WAL")
            db.executescript("""
                CREATE TABLE IF NOT EXISTS jobs (
                    job_id TEXT PRIMARY KEY, source TEXT NOT NULL, title TEXT NOT NULL,
                    youtube_url TEXT, media_path TEXT, status TEXT NOT NULL,
                    error TEXT, error_code TEXT, retryable INTEGER NOT NULL DEFAULT 0,
                    level_json TEXT, cancelled INTEGER NOT NULL DEFAULT 0,
                    idempotency_key TEXT, created_at REAL NOT NULL, updated_at REAL NOT NULL,
                    lease_until REAL, attempts INTEGER NOT NULL DEFAULT 0
                );
                CREATE UNIQUE INDEX IF NOT EXISTS jobs_idempotency ON jobs(idempotency_key)
                    WHERE idempotency_key IS NOT NULL;
                CREATE INDEX IF NOT EXISTS jobs_queue ON jobs(status, created_at);
            """)

    def submit(
        self,
        source: Literal["upload", "youtube"],
        title: str,
        upload_bytes: bytes | None = None,
        youtube_url: str | None = None,
        idempotency_key: str | None = None,
        upload_path: str | Path | None = None,
    ) -> str:
        now = time.time()
        with self._lock, self._connect() as db:
            self.reap_expired(db, now)
            if idempotency_key:
                existing = db.execute(
                    "SELECT job_id FROM jobs WHERE idempotency_key = ?", (idempotency_key,)
                ).fetchone()
                if existing:
                    if upload_path is not None:
                        Path(upload_path).unlink(missing_ok=True)
                    return str(existing["job_id"])
            pending = db.execute(
                "SELECT count(*) AS count FROM jobs WHERE status IN ('queued','downloading','transcribing')"  # noqa: E501
            ).fetchone()["count"]
            if pending >= self.max_pending:
                raise ValueError("The ingestion queue is full")
            job_id = str(uuid.uuid4())
            media_path: str | None = None
            if upload_bytes is not None:
                job_dir = self.spool_dir / job_id
                job_dir.mkdir(parents=True, exist_ok=False)
                media_path = str(job_dir / "upload.bin")
                Path(media_path).write_bytes(upload_bytes)
            elif upload_path is not None:
                job_dir = self.spool_dir / job_id
                job_dir.mkdir(parents=True, exist_ok=False)
                media_path = str(job_dir / "upload.bin")
                Path(upload_path).replace(media_path)
            db.execute(
                "INSERT INTO jobs (job_id, source, title, youtube_url, media_path, status, idempotency_key, created_at, updated_at) VALUES (?, ?, ?, ?, ?, 'queued', ?, ?, ?)",  # noqa: E501
                (job_id, source, title, youtube_url, media_path, idempotency_key, now, now),
            )
            if self._executor is not None:
                self._futures[job_id] = self._executor.submit(self._run_claimed, job_id)
            return job_id

    def get(self, job_id: str) -> Job | None:
        with self._connect() as db:
            self.reap_expired(db, time.time())
            row = db.execute("SELECT * FROM jobs WHERE job_id = ?", (job_id,)).fetchone()
        return self._row_to_job(row) if row else None

    def delete(self, job_id: str) -> bool:
        with self._connect() as db:
            row = db.execute("SELECT status FROM jobs WHERE job_id = ?", (job_id,)).fetchone()
            if row is None:
                return False
            if row["status"] in ("done", "failed", "cancelled"):
                db.execute("DELETE FROM jobs WHERE job_id = ?", (job_id,))
            else:
                db.execute(
                    "UPDATE jobs SET cancelled=1, status='cancelled', updated_at=? WHERE job_id=?",
                    (time.time(), job_id),
                )
        future = self._futures.pop(job_id, None)
        if future is not None:
            future.cancel()
        self._remove_spool(job_id)
        return True

    def wait(self, job_id: str, timeout: float = 30.0) -> None:
        future = self._futures.get(job_id)
        if future is not None:
            future.result(timeout=timeout)

    def claim(self, worker_id: str, lease_seconds: float = 60.0) -> Job | None:
        now = time.time()
        with self._connect() as db:
            self.reap_expired(db, now)
            row = db.execute(
                "SELECT * FROM jobs WHERE status='queued' AND cancelled=0 ORDER BY created_at LIMIT 1"  # noqa: E501
            ).fetchone()
            if row is None:
                return None
            updated = db.execute(
                "UPDATE jobs SET status='downloading', lease_until=?, attempts=attempts+1, updated_at=? WHERE job_id=? AND status='queued' AND cancelled=0",  # noqa: E501
                (now + lease_seconds, now, row["job_id"]),
            )
            if updated.rowcount != 1:
                return None
        return self.get(str(row["job_id"]))

    def recover(self) -> int:
        now = time.time()
        with self._connect() as db:
            result = db.execute(
                "UPDATE jobs SET status='queued', lease_until=NULL, updated_at=? WHERE status IN ('downloading','transcribing') AND lease_until < ? AND cancelled=0",  # noqa: E501
                (now, now),
            )
            return result.rowcount

    def run_worker_once(self, worker_id: str = "worker") -> bool:
        job = self.claim(worker_id)
        if job is None:
            return False
        self._run_claimed(job.job_id)
        return True

    def reap_expired(self, db: sqlite3.Connection, now: float) -> None:
        db.execute(
            "DELETE FROM jobs WHERE updated_at < ? AND status IN ('done','failed','cancelled')",
            (now - self.retention_seconds,),
        )

    def _run_claimed(self, job_id: str) -> None:
        job = self.get(job_id)
        if job is None or job.cancelled:
            return
        try:
            with TemporaryDirectory() as tmp_dir, self._connect() as db:
                row = db.execute("SELECT * FROM jobs WHERE job_id=?", (job_id,)).fetchone()
                if row is None or row["cancelled"]:
                    return
                if row["source"] == "upload":
                    audio_path = acquire_audio(
                        "upload", tmp_dir, upload_path=row["media_path"]
                    )
                else:
                    self._set_status(job_id, "downloading")
                    audio_path = acquire_audio("youtube", tmp_dir, youtube_url=row["youtube_url"])
                self._set_status(job_id, "transcribing")
                note_events = transcribe(audio_path)
                if not note_events:
                    raise NoNotesDetectedError()
                tempo_bpm = estimate_tempo(audio_path) or DEFAULT_TEMPO_BPM
                level = quantize_notes(
                    note_events, tempo_bpm, level_id=job_id, title=str(row["title"])
                )
                self._finish(job_id, "done", level=level)
        except (
            AudioTooLongError,
            MediaTooLargeError,
            YoutubeUnavailableError,
            NoNotesDetectedError,
        ) as error:
            self._finish(job_id, "failed", error=str(error), error_code=type(error).__name__)
        except Exception as error:  # noqa: BLE001
            self._finish(
                job_id,
                "failed",
                error=f"Unexpected error: {error}",
                error_code="internal_error",
                retryable=True,
            )
        finally:
            self._remove_spool(job_id)

    def _set_status(self, job_id: str, status: JobStatus) -> None:
        with self._connect() as db:
            db.execute(
                "UPDATE jobs SET status=?, updated_at=? WHERE job_id=? AND cancelled=0",
                (status, time.time(), job_id),
            )

    def _finish(  # noqa: PLR0913, PLR0917
        self,
        job_id: str,
        status: JobStatus,
        error: str | None = None,
        error_code: str | None = None,
        retryable: bool = False,
        level: LevelModel | None = None,
    ) -> None:
        with self._connect() as db:
            row = db.execute("SELECT cancelled FROM jobs WHERE job_id=?", (job_id,)).fetchone()
            if row is None or row["cancelled"]:
                return
            db.execute(
                "UPDATE jobs SET status=?, error=?, error_code=?, retryable=?, level_json=?, lease_until=NULL, updated_at=? WHERE job_id=?",  # noqa: E501
                (
                    status,
                    error,
                    error_code,
                    int(retryable),
                    json.dumps(level.model_dump(by_alias=True)) if level else None,
                    time.time(),
                    job_id,
                ),
            )

    def _row_to_job(self, row: sqlite3.Row) -> Job:
        level = (
            LevelModel.model_validate(json.loads(row["level_json"])) if row["level_json"] else None
        )
        return Job(
            str(row["job_id"]),
            row["status"],
            row["error"],
            row["error_code"],
            bool(row["retryable"]),
            level,
            bool(row["cancelled"]),
        )

    def _remove_spool(self, job_id: str) -> None:
        shutil.rmtree(self.spool_dir / job_id, ignore_errors=True)
