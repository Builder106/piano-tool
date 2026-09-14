#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
  if [ ! -d "$FLUTTER_HOME" ]; then
    echo "==> Installing Flutter SDK (stable)..."
    git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_HOME"
  fi
  export PATH="$FLUTTER_HOME/bin:$PATH"
fi

flutter config --no-analytics

DART_DEFINES=()
if [ -n "${INGESTION_API_BASE_URL:-}" ]; then
  DART_DEFINES+=(--dart-define="INGESTION_API_BASE_URL=$INGESTION_API_BASE_URL")
fi
if [ -n "${INGESTION_API_TOKEN:-}" ]; then
  DART_DEFINES+=(--dart-define="INGESTION_API_TOKEN=$INGESTION_API_TOKEN")
fi

echo "==> Building Flutter Web (release)..."
if [ ${#DART_DEFINES[@]} -gt 0 ]; then
  flutter build web --release "${DART_DEFINES[@]}"
else
  flutter build web --release
fi
