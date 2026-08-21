class AudioTooLongError(Exception):
    def __init__(self, duration_seconds: float, cap_seconds: float):
        super().__init__(
            f"Audio is {duration_seconds:.0f}s long, which is over the " f"{cap_seconds:.0f}s cap."
        )
        self.duration_seconds = duration_seconds
        self.cap_seconds = cap_seconds


class YoutubeUnavailableError(Exception):
    pass


class NoNotesDetectedError(Exception):
    def __init__(self, message: str = "Didn't find any notes in that audio"):
        super().__init__(message)
