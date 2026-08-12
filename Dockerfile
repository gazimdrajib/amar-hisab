# -----------------------------------------------------------------------------
# Amar Hisab – Backend (Shelf/Dart) production image.
# Production Deployment Guide §3 — packages `bin/server.dart` as a compiled
# executable with a minimal runtime.
# -----------------------------------------------------------------------------
FROM dart:3.5-stable AS build

WORKDIR /app

# Resolve dependencies first for layer caching.
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get

# Copy the source and generate any build_runner artefacts.
COPY bin ./bin
COPY lib ./lib
COPY build.yaml analysis_options.yaml ./
RUN dart pub get --offline

# AOT-compile the server to a single native executable.
RUN dart compile exe bin/server.dart -o /app/bin/server

# -----------------------------------------------------------------------------
FROM debian:bookworm-slim AS runtime

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates wget \
 && rm -rf /var/lib/apt/lists/*

# Non-root runtime user.
RUN groupadd --system app && useradd --system --gid app --home /app app

WORKDIR /app
COPY --from=build /app/bin/server /app/server

# SQLite data directory (mounted as a volume in production).
RUN mkdir -p /app/data && chown -R app:app /app

USER app

ENV HOST=0.0.0.0 \
    PORT=8080 \
    DB_PATH=/app/data/amar_hisab.db \
    LOG_LEVEL=info

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/health || exit 1

ENTRYPOINT ["/app/server"]
