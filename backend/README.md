# Audio ingestion backend

## System dependencies

This service shells out to `ffmpeg` and `ffprobe` for audio duration checks
and YouTube audio extraction. Both are system binaries, not Python packages,
so they are not covered by `requirements.txt` or
`scripts/install_basic_pitch.sh` -- install them on the host separately
before running this service. They are already present on `ampere-dev`.
