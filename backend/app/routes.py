from __future__ import annotations

import hashlib
import os
import secrets
import time
from collections import defaultdict, deque
from typing import Any, Literal, cast

from fastapi import APIRouter, Depends, File, Form, Header, HTTPException, UploadFile
from pydantic import BaseModel

from app.jobs import Job, JobStore

router = APIRouter()
store = JobStore(start_workers=os.getenv("PIANO_TOOL_LOCAL_WORKER") == "1")
API_TOKEN = os.getenv("PIANO_TOOL_API_TOKEN")
MAX_MEDIA_BYTES = 256 * 1024 * 1024
MAX_TITLE_LENGTH = 200
MAX_URL_LENGTH = 2048
RATE_LIMIT = 5
RATE_WINDOW = 600.0
_submissions: defaultdict[str, deque[float]] = defaultdict(deque)


class JobResponse(BaseModel):
    job_id: str
    status: str
    error: str | None = None
    error_code: str | None = None
    retryable: bool = False
    cancelled: bool = False
    level: dict[str, Any] | None = None


def _require_auth(authorization: str | None = Header(default=None)) -> str:
    if not API_TOKEN:
        raise HTTPException(status_code=503, detail="Ingestion authentication is not configured")
    scheme, _, token = (authorization or "").partition(" ")
    if scheme.lower() != "bearer" or not secrets.compare_digest(token, API_TOKEN):
        raise HTTPException(status_code=401, detail="Bearer authentication required")
    return hashlib.sha256(token.encode()).hexdigest()


def _to_response(job: Job) -> JobResponse:
    return JobResponse(
        job_id=job.job_id,
        status=job.status,
        error=job.error,
        error_code=getattr(job, "error_code", None),
        retryable=getattr(job, "retryable", False),
        cancelled=getattr(job, "cancelled", False),
        level=job.level.model_dump(by_alias=True) if job.level else None,
    )


def _check_rate_limit(identity: str) -> None:
    now = time.time()
    bucket = _submissions[identity]
    while bucket and bucket[0] <= now - RATE_WINDOW:
        bucket.popleft()
    if len(bucket) >= RATE_LIMIT:
        raise HTTPException(status_code=429, detail="Submission rate limit exceeded")
    bucket.append(now)


async def _read_bounded(audio: UploadFile) -> bytes:
    content = bytearray()
    while chunk := await audio.read(1024 * 1024):
        content.extend(chunk)
        if len(content) > MAX_MEDIA_BYTES:
            raise HTTPException(status_code=413, detail="Audio file is too large")
    return bytes(content)


@router.post("/jobs", status_code=202)
async def create_job(  # noqa: PLR0913, PLR0917
    title: str = Form(...),
    source: str = Form(...),
    youtube_url: str | None = Form(default=None),
    audio: UploadFile | None = File(default=None),  # noqa: B008
    idempotency_key: str | None = Header(default=None, alias="Idempotency-Key"),
    identity: str = Depends(_require_auth),
) -> JobResponse:
    if len(title) > MAX_TITLE_LENGTH:
        raise HTTPException(status_code=400, detail="title is too long")
    if source not in ("upload", "youtube"):
        raise HTTPException(status_code=400, detail="source must be 'upload' or 'youtube'")
    if source == "upload" and audio is None:
        raise HTTPException(
            status_code=400, detail="audio file is required when source is 'upload'"
        )
    if source == "youtube" and (not youtube_url or len(youtube_url) > MAX_URL_LENGTH):
        raise HTTPException(
            status_code=400, detail="youtube_url is required and must be at most 2048 characters"
        )
    _check_rate_limit(identity)
    upload_bytes = await _read_bounded(audio) if audio is not None else None
    try:
        job_id = store.submit(
            cast(Literal["upload", "youtube"], source),
            title,
            upload_bytes=upload_bytes,
            youtube_url=youtube_url,
            idempotency_key=idempotency_key,
        )
    except ValueError as error:
        raise HTTPException(status_code=429, detail=str(error)) from error
    return JobResponse(job_id=job_id, status="queued")


@router.get("/jobs/{job_id}")
def get_job(job_id: str, _: str = Depends(_require_auth)) -> JobResponse:
    job = store.get(job_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Job not found")
    return _to_response(job)


@router.delete("/jobs/{job_id}", status_code=204)
def delete_job(job_id: str, _: str = Depends(_require_auth)) -> None:
    if not store.delete(job_id):
        raise HTTPException(status_code=404, detail="Job not found")
