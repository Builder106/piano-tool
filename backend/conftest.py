import pytest


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
