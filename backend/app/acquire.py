import json
import subprocess
import uuid
from pathlib import Path
from typing import Literal

from app.errors import AudioTooLongError, YoutubeUnavailableError

DEFAULT_DURATION_CAP_SECONDS = 600.0


def _probe_duration_seconds(path: str) -> float:
    result = subprocess.run(
        ["ffprobe", "-v", "quiet", "-print_format", "json", "-show_format", path],
        capture_output=True,
        text=True,
        check=True,
    )
    return float(json.loads(result.stdout)["format"]["duration"])


def _check_duration_cap(path: str, cap_seconds: float) -> None:
    duration = _probe_duration_seconds(path)
    if duration > cap_seconds:
        raise AudioTooLongError(duration, cap_seconds)


def acquire_upload(
    upload_bytes: bytes,
    dest_dir: str,
    cap_seconds: float = DEFAULT_DURATION_CAP_SECONDS,
) -> str:
    dest_path = Path(dest_dir) / f"{uuid.uuid4()}.upload"
    dest_path.write_bytes(upload_bytes)
    _check_duration_cap(str(dest_path), cap_seconds)
    return str(dest_path)


def acquire_youtube(
    url: str,
    dest_dir: str,
    cap_seconds: float = DEFAULT_DURATION_CAP_SECONDS,
) -> str:
    import yt_dlp

    output_template = str(Path(dest_dir) / f"{uuid.uuid4()}.%(ext)s")
    options = {
        "format": "bestaudio/best",
        "outtmpl": output_template,
        "postprocessors": [
            {"key": "FFmpegExtractAudio", "preferredcodec": "wav"}
        ],
        "quiet": True,
        "no_warnings": True,
    }
    try:
        with yt_dlp.YoutubeDL(options) as downloader:
            downloader.extract_info(url, download=True)
    except yt_dlp.utils.DownloadError as error:
        raise YoutubeUnavailableError(str(error)) from error

    downloaded_path = Path(output_template % {"ext": "wav"})
    if not downloaded_path.exists():
        raise YoutubeUnavailableError(
            f"yt-dlp reported success but produced no file for {url}"
        )

    _check_duration_cap(str(downloaded_path), cap_seconds)
    return str(downloaded_path)


def acquire_audio(
    source: Literal["upload", "youtube"],
    dest_dir: str,
    upload_bytes: bytes | None = None,
    youtube_url: str | None = None,
    cap_seconds: float = DEFAULT_DURATION_CAP_SECONDS,
) -> str:
    if source == "upload":
        if upload_bytes is None:
            raise ValueError("upload_bytes is required when source is 'upload'")
        return acquire_upload(upload_bytes, dest_dir, cap_seconds)
    if source == "youtube":
        if not youtube_url:
            raise ValueError("youtube_url is required when source is 'youtube'")
        return acquire_youtube(youtube_url, dest_dir, cap_seconds)
    raise ValueError(f"Unknown source: {source}")
