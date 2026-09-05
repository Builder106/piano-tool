import os

import pytest

os.environ.setdefault("PIANO_TOOL_API_TOKEN", "test-token")
os.environ.setdefault("PIANO_TOOL_LOCAL_WORKER", "1")
os.environ.setdefault("PIANO_TOOL_DB", "/tmp/piano-tool-test.sqlite3")
os.environ.setdefault("PIANO_TOOL_SPOOL", "/tmp/piano-tool-test-spool")


@pytest.fixture(autouse=True)
def reset_submission_rate_limit():
    from app.routes import _submissions

    _submissions.clear()
    yield


def pytest_configure(config: pytest.Config) -> None:
    # Pytest applies command-line -W flags after configuration-file filterwarnings.
    # When -W error is supplied on the CLI, it takes precedence and converts ignored
    # warnings from third-party dependencies into collection/runtime errors.
    # Moving "error" from pythonwarnings to the start of filterwarnings preserves
    # specific ignore rules while treating all other unignored warnings as errors.
    pythonwarnings = config.known_args_namespace.pythonwarnings
    if pythonwarnings and "error" in pythonwarnings:
        pythonwarnings.remove("error")
        filters = list(config.getini("filterwarnings"))
        if "error" not in filters:
            filters.insert(0, "error")
            config._inicache["filterwarnings"] = filters
