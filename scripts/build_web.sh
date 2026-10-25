#!/usr/bin/env bash
set -euo pipefail

# 1. Build the Astro showcase site into build/web
echo "==> Building showcase site..."
(
  cd site
  npm ci
  ASTRO_OUT_DIR=../build/web npm run build
)

# 2. Build the Flutter web app into build/web/app
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

echo "==> Building Flutter Web (release) under /app/..."
mkdir -p build/web/app
if [ ${#DART_DEFINES[@]} -gt 0 ]; then
  flutter build web --release --base-href /app/ -o build/web/app "${DART_DEFINES[@]}"
else
  flutter build web --release --base-href /app/ -o build/web/app
fi
