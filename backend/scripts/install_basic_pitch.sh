#!/usr/bin/env bash
set -euo pipefail
if [[ -x backend/.venv/bin/python ]]; then
  python_bin=backend/.venv/bin/python
elif [[ -x .venv/bin/python ]]; then
  python_bin=.venv/bin/python
else
  python_bin=python
fi
uv pip install --python "${python_bin}" basic-pitch==0.4.0 --no-deps
