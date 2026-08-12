# Amar Hisab (আমার হিসাব)

**Offline-first business management platform for SMEs.**
POS + inventory + accounting + reports + optional cloud sync, in one self-hosted
Dart/Shelf backend with a Flutter multi-platform client.

![Backend status](https://img.shields.io/badge/backend-Dart%203.5-blue)
![Status](https://img.shields.io/badge/production-ready-green)
![License](https://img.shields.io/badge/license-internal-orange)

---

## 1. Quick start

### Local development

```bash
# 1. Resolve dependencies
dart pub get

# 2. Code generation (freezed / json_serializable)
dart run build_runner build --delete-conflicting-outputs

# 3. Run the local server
dart run bin/server.dart
# -> Health: http://127.0.0.1:8080/health
# -> Docs:   http://127.0.0.1:8080/api/docs

# 4. Flutter client (in a second terminal)
cd flutter_app
flutter pub get
flutter run -d windows        # or: chrome, android-...
```

### Production

```bash
cp .env.prod .env            # fill in everything
./deploy.sh 1.0.0            # build + package the release
docker compose -f docker-compose.prod.yml up -d --build
```

The full release runbook (incl. TLS certificates with Let's Encrypt) is in
[`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md).

---

## 2. Architecture overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                       Client devices                                │
│   Flutter web (nginx static)  |  Flutter mobile  |  Flutter desktop │
└──────────────────────────────┬─────────────────────────────────────┘
                               │ HTTPS (Let's Encrypt)
                    ┌──────────┴───────────┐
                    │  nginx reverse proxy │  ← deploy/nginx/default.conf
                    └──────────┬───────────┘
                               │ /api/*   →  Dart backend  (port 8080)
                               │ /        →  static Flutter web build
                    ┌──────────┴───────────┐
                    │   Dart/Shelf server  │  bin/server.dart
                    │ ──────────────────── │
                    │ Modules              │  lib/modules/*
                    │  ├─ auth & users     │
                    │  ├─ products         │
                    │  ├─ inventory        │
                    │  ├─ sales            │
                    │  ├─ purchases        │
                    │  ├─ accounting       │
                    │  ├─ reports          │
                    │  ├─ portal  (public) │  /public/*
                    │  └─ sync    (gRPC)   │  → PostgreSQL + Redis
                    │ ──────────────────── │
                    │ Core                 │  db · jwt · rbac · audit ·
                    │                      │  change-log · event bus
                    └──────────────────────┘
```

Key principles:

- **Offline-first:** SQLite (WAL mode) keeps the shop running offline; cloud
  sync is opt-in.
- **Domain events:** Domain events are published **after commit**, never inside
  the transaction.
- **RBAC:** Requests pass `authMiddleware` → `requirePermission` chain.
- **Double-entry accounting:** Every mutation emits a balanced journal entry.
- **Auditability:** `AuditService` + `ChangeLogService` trace every change.

---

## 3. Repository layout

| Path | Purpose |
|------|---------|
| `bin/` | Server entrypoint (`dart run bin/server.dart`) |
| `lib/core/` | DB, JWT, RBAC, audit, change log, seeders |
| `lib/modules/*/domain` | Entities + repository contracts |
| `lib/modules/*/application` | Services – transactional flows |
| `lib/modules/*/infrastructure` | SQLite-backed repositories |
| `lib/modules/*/presentation` | Shelf controllers |
| `lib/monitoring/` | Prometheus metrics exporter (`/metrics`) |
| `cloud/sync/` | Optional cloud sync (Go + gRPC) |
| `flutter_app/` | Flutter client source |
| `api/` | `openapi.yaml` served at `/api/docs` |
| `monitoring/` | Prometheus & Grafana artefacts, `health_check.sh` |
| `training/` | User manual (Markdown + PDF) |
| `deploy/` | nginx TLS config, certbot helpers |
| `Dockerfile` | Multi-stage backend image |
| `docker-compose.prod.yml` | Full prod stack |
| `.env.prod` | Production env template |
| `RELEASE_CHECKLIST.md` | Go-live runbook |
| `INDEX.md` | Master documentation index |

---

## 4. Quality gates

Every PR must satisfy:

| Gate | Command | Pass condition |
|------|---------|----------------|
| Static analysis | `dart analyze --fatal-warnings` | 0 issues |
| Unit tests | `dart test` | all green |
| Flutter tests | `cd flutter_app && flutter test` | all green |
| Server boots | `dart run bin/server.dart` | starts without warnings |
| Health probe | `curl -s http://localhost:8080/health` | `200 {"data":{"status":"ok",…}}` |
| Metrics | `curl -s http://localhost:8080/metrics` | Prometheus text |
| OpenAPI docs | `curl -s http://localhost:8080/api/docs` | HTML 200 |

The latest verification results are recorded in
[`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md).

---

## 5. Contributing

1. Read [`INDEX.md`](INDEX.md) for the full documentation map.
2. Branch from `main`. Keep diffs small and tests green.
3. Add a test for every behaviour change (unit for services, widget for UI).
4. After you change anything referenced in a runbook or training manual,
   update **both** the source `.txt` and the rendered docs.
5. Use the response envelope (`ResponseEnvelope`) and
   `requirePermission(...)` in every controller. New mutating code *must*:
   - wrap writes in a transaction,
   - record audit + change-log,
   - publish the domain event **after** commit.
6. Run the quality gates locally before opening a PR.

PRs are reviewed against the
[`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md) entries.

---

## 6. License

Proprietary – internal use only.
See `LICENSE` when published by owning entity.
