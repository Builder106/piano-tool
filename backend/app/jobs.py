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

# librosa's beat tracker can return 0.0 for audio with no strong detectable
# pulse (free-tempo intros, rubato solo piano) -- exactly the kind of
# piano-forward material this pipeline targets. Falling back to a default
# lets the job still produce a level for the user to judge, instead of
# failing outright.
DEFAULT_TEMPO_BPM = 120.0


@dataclass
class Job:
    job_id: str
    status: JobStatus = "queued"
    error: str | None = None
    level: LevelModel | None = None


class JobStore:
    def __init__(self, max_workers: int = 2):
        self._jobs: dict[str, Job] = {}
        self._futures: dict[str, Future[None]] = {}
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
        future = self._futures.pop(job_id, None)
        if future is not None:
            # Only prevents a job that hasn't started yet (still queued
            # behind other work) from running. A ThreadPoolExecutor future
            # can't be interrupted once it has actually started -- .cancel()
            # is a no-op (returns False) in that case, which is fine.
            future.cancel()
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
                    raise NoNotesDetectedError()

                tempo_bpm = estimate_tempo(audio_path)
                if tempo_bpm <= 0:
                    tempo_bpm = DEFAULT_TEMPO_BPM
                job.level = quantize_notes(note_events, tempo_bpm, level_id=job.job_id, title=title)
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
