# Audio ingestion backend

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

On `ampere-dev`, use:

```text
verify-on-vm "<repo>/backend" "bash scripts/install_basic_pitch.sh && pytest -v"
```

## System dependencies

This service shells out to `ffmpeg` and `ffprobe` for audio duration checks
and YouTube audio extraction. Both are system binaries, not Python packages,
so they are not covered by `requirements.txt` or
`scripts/install_basic_pitch.sh` -- install them on the host separately
before running this service. They are already present on `ampere-dev`.
