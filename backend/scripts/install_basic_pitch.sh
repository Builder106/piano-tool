#!/usr/bin/env bash
set -euo pipefail
python_bin="$(command -v python)"
uv pip install --python "${python_bin}" basic-pitch==0.4.0 --no-deps
