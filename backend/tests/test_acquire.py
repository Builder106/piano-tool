import numpy as np
import pytest
import soundfile as sf

from app.acquire import acquire_audio, acquire_upload
from app.errors import AudioTooLongError, NoNotesDetectedError, YoutubeUnavailableError


def _write_wav(path, duration_s: float, sr: int = 22050) -> None:
    sf.write(str(path), np.zeros(int(duration_s * sr), dtype=np.float32), sr)


def test_acquire_upload_returns_a_path_within_the_cap(tmp_path):
    audio_path = tmp_path / "short.wav"
    _write_wav(audio_path, duration_s=2.0)

    result = acquire_upload(audio_path.read_bytes(), str(tmp_path))

    assert result.endswith(".upload")


def test_acquire_upload_raises_when_over_the_cap(tmp_path):
    audio_path = tmp_path / "long.wav"
    _write_wav(audio_path, duration_s=3.0)

    with pytest.raises(AudioTooLongError):
        acquire_upload(audio_path.read_bytes(), str(tmp_path), cap_seconds=1.0)


def test_acquire_audio_requires_upload_bytes_for_the_upload_source(tmp_path):
    with pytest.raises(ValueError):
        acquire_audio("upload", str(tmp_path))


def test_acquire_audio_requires_a_url_for_the_youtube_source(tmp_path):
    with pytest.raises(ValueError):
        acquire_audio("youtube", str(tmp_path))


def test_acquire_youtube_wraps_download_errors(tmp_path, monkeypatch):
    import yt_dlp

    class _FailingDownloader:
        def __init__(self, options):
            pass

        def __enter__(self):
            return self

        def __exit__(self, *args):
            return False

        def extract_info(self, url, download=True):
            raise yt_dlp.utils.DownloadError("video unavailable")

    monkeypatch.setattr(yt_dlp, "YoutubeDL", _FailingDownloader)

    with pytest.raises(YoutubeUnavailableError):
        acquire_audio("youtube", str(tmp_path), youtube_url="https://example.com/watch?v=nope")


def test_acquire_youtube_rejects_a_non_youtube_host(tmp_path):
    # No monkeypatch of yt_dlp here -- the rejection must happen before any
    # yt_dlp code runs, proving this is a genuine gate, not a mock intercept.
    with pytest.raises(YoutubeUnavailableError):
        acquire_audio("youtube", str(tmp_path), youtube_url="https://example.com/not-youtube")


@pytest.mark.parametrize(
    "url",
    ["https://www.youtube.com/watch?v=abc123", "https://youtu.be/abc123"],
)
def test_acquire_youtube_accepts_real_shaped_youtube_urls(tmp_path, monkeypatch, url):
    import yt_dlp

    calls = []

    class _FakeDownloader:
        def __init__(self, options):
            pass

        def __enter__(self):
            return self

        def __exit__(self, *args):
            return False

        def extract_info(self, url, download=True):
            calls.append(url)
            raise yt_dlp.utils.DownloadError("stop before doing real work")

    monkeypatch.setattr(yt_dlp, "YoutubeDL", _FakeDownloader)

    with pytest.raises(YoutubeUnavailableError):
        acquire_audio("youtube", str(tmp_path), youtube_url=url)

    assert calls == [url]


def test_acquire_upload_of_garbage_bytes_raises_no_notes_detected(tmp_path):
    with pytest.raises(NoNotesDetectedError):
        acquire_upload(b"this is not a valid audio file", str(tmp_path))
