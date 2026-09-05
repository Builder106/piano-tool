import json
import subprocess
import uuid
from pathlib import Path
from typing import Literal
from urllib.parse import urlparse

from app.errors import (
    AudioTooLongError,
    MediaTooLargeError,
    NoNotesDetectedError,
    YoutubeUnavailableError,
)

DEFAULT_DURATION_CAP_SECONDS = 600.0

YOUTUBE_HOSTS = {"youtube.com", "www.youtube.com", "m.youtube.com", "youtu.be"}
MAX_DOWNLOAD_BYTES = 256 * 1024 * 1024


def _probe_duration_seconds(path: str) -> float:
    # ffprobe is a system dependency (not pip-installable); it must already
    # be on the host's PATH -- see backend/README.md.
    result = subprocess.run(
        ["ffprobe", "-v", "quiet", "-print_format", "json", "-show_format", path],
        capture_output=True,
        text=True,
        check=True,
        timeout=30,
    )
    return float(json.loads(result.stdout)["format"]["duration"])


def _check_duration_cap(path: str, cap_seconds: float) -> None:
    try:
        duration = _probe_duration_seconds(path)
    except subprocess.CalledProcessError as error:
        # A corrupt or non-audio upload makes ffprobe exit non-zero. From the
        # user's point of view this is the same experience as "no notes
        # detected" -- nothing to practice -- so reuse that error type.
        raise NoNotesDetectedError("Didn't find any notes in that audio") from error
    if duration > cap_seconds:
        raise AudioTooLongError(duration, cap_seconds)


def acquire_upload(
    upload_bytes: bytes,
    dest_dir: str,
    cap_seconds: float = DEFAULT_DURATION_CAP_SECONDS,
) -> str:
    if len(upload_bytes) > MAX_DOWNLOAD_BYTES:
        raise MediaTooLargeError("Audio file is too large")
    dest_path = Path(dest_dir) / f"{uuid.uuid4()}.upload"
    dest_path.write_bytes(upload_bytes)
    return acquire_upload_path(dest_path, cap_seconds)


def acquire_upload_path(
    upload_path: str | Path,
    cap_seconds: float = DEFAULT_DURATION_CAP_SECONDS,
) -> str:
    path = Path(upload_path)
    if path.stat().st_size > MAX_DOWNLOAD_BYTES:
        raise MediaTooLargeError("Audio file is too large")
    _check_duration_cap(str(path), cap_seconds)
    return str(path)


def acquire_youtube(
    url: str,
    dest_dir: str,
    cap_seconds: float = DEFAULT_DURATION_CAP_SECONDS,
) -> str:
    hostname = urlparse(url).hostname
    if urlparse(url).scheme != "https" or hostname not in YOUTUBE_HOSTS:
        raise YoutubeUnavailableError("Not a YouTube URL")

    import yt_dlp

    output_template = str(Path(dest_dir) / f"{uuid.uuid4()}.%(ext)s")
    options = {
        "format": "bestaudio/best",
        "outtmpl": output_template,
        "postprocessors": [{"key": "FFmpegExtractAudio", "preferredcodec": "wav"}],
        "quiet": True,
        "no_warnings": True,
        "noplaylist": True,
        "playlist_items": "1",
        "max_filesize": MAX_DOWNLOAD_BYTES,
        "socket_timeout": 30,
        "retries": 2,
    }
    try:
        with yt_dlp.YoutubeDL(options) as downloader:
            downloader.extract_info(url, download=True)
    except (yt_dlp.utils.DownloadError, TimeoutError, subprocess.SubprocessError) as error:
        raise YoutubeUnavailableError(str(error)) from error

    downloaded_path = Path(output_template % {"ext": "wav"})
    if not downloaded_path.exists():
        raise YoutubeUnavailableError(f"yt-dlp reported success but produced no file for {url}")

    _check_duration_cap(str(downloaded_path), cap_seconds)
    return str(downloaded_path)


def acquire_audio(
    source: Literal["upload", "youtube"],
    dest_dir: str,
    upload_bytes: bytes | None = None,
    upload_path: str | Path | None = None,
    youtube_url: str | None = None,
    cap_seconds: float = DEFAULT_DURATION_CAP_SECONDS,
) -> str:
    if source == "upload":
        if upload_path is not None:
            return acquire_upload_path(upload_path, cap_seconds)
        if upload_bytes is None:
            raise ValueError("upload_bytes is required when source is 'upload'")
        return acquire_upload(upload_bytes, dest_dir, cap_seconds)
    if source == "youtube":
        if not youtube_url:
            raise ValueError("youtube_url is required when source is 'youtube'")
        return acquire_youtube(youtube_url, dest_dir, cap_seconds)
    raise ValueError(f"Unknown source: {source}")
