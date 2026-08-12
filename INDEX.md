# Amar Hisab – Documentation Index

One entry point for everything we ship.

---

## 🧱 Product documentation (engineering books)

| File | Purpose | Audience |
|------|---------|----------|
| `Amar Hisab Architecture Book.txt` | End-to-end architecture: modules, folders, contracts, event rules | Engineers |
| `Amar Hisab Database Book.txt` | SQL schema reference | Engineers |
| `Amar Hisab Event Catalog.txt` | Domain events + payload contracts | Engineers |
| `Amar Hisab Proto Contract Book.txt` | gRPC / Protobuf service definitions | Engineers |
| `Amar Hisab RBAC Book.txt` | Roles × permissions matrix | Engineers / Security |
| `Amar Hisab Sitemap.txt` | UI / page inventory | Product / Designers |
| `Amar Hisab AI Co‑Engineering Roadmap.txt` | Roadmap and AI assistant plans | Product |
| `Amar Hisab – Investor Architecture Book.txt` | Executive summary + diagrams | Investors / leadership |

## 📘 Ops + lifecycle

| File | Purpose |
|------|---------|
| `Amar Hisab Operations Runbook.txt` | Day-to-day operations and emergency playbooks |
| `Amar Hisab Training Manual.txt` | End-user onboarding (source for the rendered manual) |
| `Amar Hisab Production Deployment Guide.txt` | Hardware, network, peripherals, backup, security |
| `RELEASE_CHECKLIST.md` | Go-live runbook (this release) |
| `docs/INTEGRATION_VERIFICATION.md` | Phase 10 sign-off (routes, RBAC, audit, events) |

## 📦 Core code (backend)

| Path | Description |
|------|-------------|
| `bin/server.dart` | Shelf HTTP server entrypoint, mounts all routers |
| `lib/core/` | DB access, middleware, JWT, seeders, response envelope |
| `lib/modules/<m>/domain` | Entities + repository contracts (no SQL) |
| `lib/modules/<m>/application` | Services containing business logic; emit audit/change-log/events |
| `lib/modules/<m>/infrastructure` | Repository implementations over SQLite |
| `lib/modules/<m>/presentation` | Shelf controllers; thin – just validation + envelope |
| `lib/monitoring/metrics.dart` | Prometheus registry and /metrics handler |

## 📱 Front-end / clients

| Path | Description |
|------|-------------|
| `flutter_app/` | Flutter client (POS UI) – Android / iOS / Windows / Web |

## ☁️ Cloud sync service

| Path | Description |
|------|-------------|
| `cloud/sync/` | Go-based gRPC sync server (PostgreSQL + Redis) |

## 📚 Training material

| Path | Description |
|------|-------------|
| `training/Amar_Hisab_Training_Manual.md` | Markdown source (regenerate after edits) |
| `training/Amar_Hisab_Training_Manual.pdf` | Ready-to-print PDF |
| `training/` | Placeholder for screenshot assets |

## 📈 Monitoring

| Path | Description |
|------|-------------|
| `monitoring/README.md` | How to wire Prometheus / Grafana |
| `monitoring/prometheus.yml` | Sample scrape config |
| `monitoring/grafana/amar_hisab_dashboard.json` | Pre-built dashboard |
| `monitoring/health_check.sh` | One-shot health probe for cron |

## 🚢 Deployment

| Path | Description |
|------|-------------|
| `Dockerfile` | Backend Docker image (multi-stage Dart build) |
| `docker-compose.prod.yml` | Backend + Postgres + Redis + nginx + certbot |
| `.env.prod` | Production env template |
| `deploy.sh` | Build & package script (Dart + Flutter + Docker) |
| `deploy/nginx/default.conf` | Reverse-proxy + TLS config sample |

## 📄 API documentation

| Path | Description |
|------|-------------|
| `api/openapi.yaml` | OpenAPI 3.0 spec for every public endpoint |
| `GET /api/docs` | In-browser Swagger-UI served by the backend |
| `GET /api/openapi.yaml` | Same spec fetched over HTTP from the server |

---

*Last regenerated: 2026-08-05*
