from typing import Any, Literal

from fastapi import APIRouter, File, Form, HTTPException, UploadFile
from pydantic import BaseModel

from app.jobs import Job, JobStore

router = APIRouter()
store = JobStore()


class JobResponse(BaseModel):
    job_id: str
    status: str
    error: str | None = None
    level: dict[str, Any] | None = None


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
    source: Literal["upload", "youtube"] = Form(...),
    youtube_url: str | None = Form(default=None),
    audio: UploadFile | None = File(),  # noqa: B008
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
    # Build the response from the known state at submission time rather than
    # re-reading from the store: the job runs on a background thread, so a
    # re-fetch here can race and report "downloading" instead of "queued".
    return JobResponse(job_id=job_id, status="queued", error=None, level=None)


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
