#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$(dirname "$PIANO_TOOL_DB")" "$PIANO_TOOL_SPOOL"

python -m app.worker &
python -m uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-8080}" &

wait -n
exit $?
