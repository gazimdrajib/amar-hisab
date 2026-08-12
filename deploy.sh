#!/usr/bin/env bash
# =============================================================================
# Amar Hisab – Build & release script.
#
# Usage:
#   ./deploy.sh [version]
#
# Steps:
#   1. Resolve Dart dependencies and run build_runner code generation.
#   2. Build the Flutter app for web, Android (debug + release), and Windows.
#   3. AOT-compile the Dart backend (same as Dockerfile, for local smoke-test).
#   4. Package everything into dist/amar-hisab-<version>/ (backend image via
#      docker-compose.prod.yml + native executable + Flutter artefacts).
#
# Prerequisites: Dart SDK 3.x, Flutter SDK, Docker Desktop (optional for
# container packaging).  On Windows run inside Git Bash / WSL –
# deploy.ps1 covers native Windows paths.
# =============================================================================
set -euo pipefail

VERSION="${1:-$(date +%Y%m%d-%H%M%S)}"
DIST_DIR="dist/amar-hisab-${VERSION}"

log() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==> WARNING:\033[0m %s\n' "$*" >&2; }
err() { printf '\033[1;31m==> ERROR:\033[0m %s\n' "$*" >&2; }

command -v dart >/dev/null 2>&1 || { err "Dart SDK not found in PATH"; exit 1; }
command -v flutter >/dev/null 2>&1 || { err "Flutter SDK not found in PATH"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

# --------------------------------------------------------------------------
# 1. Dart backend: dependencies + code generation
# --------------------------------------------------------------------------
log "Backend: dart pub get"
dart pub get

log "Backend: build_runner (build for prod)"
dart run build_runner build --delete-conflicting-outputs

# --------------------------------------------------------------------------
# 2. Flutter client builds
# --------------------------------------------------------------------------
pushd flutter_app >/dev/null

log "Flutter: flutter pub get"
flutter pub get

log "Flutter: build web (release)"
flutter build web --dart-define=AMAR_HISAB_ENV=production --base-href=/

log "Flutter: build Android (release)"
flutter build apk --release --dart-define=AMAR_HISAB_ENV=production

# Windows build only on Windows hosts / runners.
if [[ "$(uname -s)" == MINGW* || "$(uname -s)" == MSYS* || "$(uname -s)" == Windows* ]]; then
  log "Flutter: build Windows (release)"
  flutter build windows --dart-define=AMAR_HISAB_ENV=production || warn "Windows build failed (non-fatal)"
else
  warn "Skipping Windows build (not on a Windows host)"
fi

popd >/dev/null

# --------------------------------------------------------------------------
# 3. Native backend compile (local smoke-test binary)
# --------------------------------------------------------------------------
log "Backend: AOT compile bin/server.dart"
dart compile exe bin/server.dart -o "${DIST_DIR}/server"

# --------------------------------------------------------------------------
# 4. Package everything into dist/
# --------------------------------------------------------------------------
log "Packaging release ${VERSION} -> ${DIST_DIR}"
mkdir -p "${DIST_DIR}/web-app" "${DIST_DIR}/apk" "${DIST_DIR}/windows-app"

cp -r flutter_app/build/web/*                           "${DIST_DIR}/web-app/"
cp flutter_app/build/app/outputs/flutter-apk/*.apk      "${DIST_DIR}/apk/" 2>/dev/null || true
if [[ -d flutter_app/build/windows/runner/Release ]]; then
  cp -r flutter_app/build/windows/runner/Release/*      "${DIST_DIR}/windows-app/"
fi

# Docker image artefacts (optional – rebuild with compose).
cp Dockerfile Dockerfile.sync docker-compose.prod.yml .env.prod "${DIST_DIR}/" 2>/dev/null || true

cat > "${DIST_DIR}/VERSION.txt" <<EOF
Amar Hisab production release
Version: ${VERSION}
Built:   $(date -u +"%Y-%m-%dT%H:%M:%SZ")
Package contents:
  server            – native Dart backend executable
  web-app/          – Flutter web build (serve behind nginx)
  apk/              – Flutter Android release APK
  windows-app/      – Flutter Windows installer / portable build (when built)
  docker-compose.prod.yml + Dockerfile – full container stack
EOF

log "Release packaged in ${DIST_DIR}"
log "Container stack ready: docker compose -f docker-compose.prod.yml up -d --build"
