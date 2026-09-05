# Audio ingestion backend

The service consists of a persistent FastAPI process and one or more worker
processes. Both use the SQLite database and filesystem spool configured by
`PIANO_TOOL_DB` and `PIANO_TOOL_SPOOL`; SQLite runs in WAL mode so API and
worker processes can operate concurrently.

Run the API from `backend` with `python -m uvicorn app.main:app`. Run a worker
with `python -m app.worker`. The service templates in `scripts/` are suitable
bases for a supervised installation. `/health` is a liveness check and
`/ready` verifies required audio binaries. Job endpoints require
`Authorization: Bearer $PIANO_TOOL_API_TOKEN`.

The default limits are 256 MiB media, 600 seconds of audio, four queued jobs,
two local compatibility workers, 200-character titles, 2,048-character URLs,
five submissions per token per ten minutes, and 24-hour terminal-job
retention. Clients should send an `Idempotency-Key` when retrying submission.

## Python environment

The backend requires Python 3.12. The `.python-version` file and the exact
`requires-python` constraint in `pyproject.toml` keep local, VM, and CI
environments aligned.

## Basic Pitch installation

Basic Pitch is installed separately by `scripts/install_basic_pitch.sh`, which
runs `pip install basic-pitch==0.4.0 --no-deps`. The regular dependency files
intentionally do not list `basic-pitch`: installing it normally pulls a
TensorFlow dependency that is not used by this service. The service uses Basic
Pitch's ONNX model with the `onnxruntime` dependency listed in
`requirements.txt`.

On the remote Linux ARM64 verifier, use:

```text
verify-on-vm "<repo>/backend" "bash scripts/install_basic_pitch.sh && pytest -v"
```

## System dependencies

This service shells out to `ffmpeg` and `ffprobe` for audio duration checks
and YouTube audio extraction. Both are system binaries, not Python packages,
so they are not covered by `requirements.txt` or
`scripts/install_basic_pitch.sh` -- install them on the host separately
before running this service. They are already present on `ampere-dev`.
