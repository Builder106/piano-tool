#!/usr/bin/env bash
set -euo pipefail
python_bin="$(command -v python)"
if command -v uv >/dev/null 2>&1; then
  uv pip install --python "${python_bin}" basic-pitch==0.4.0 --no-deps
else
  "${python_bin}" -m pip install basic-pitch==0.4.0 --no-deps
fi
