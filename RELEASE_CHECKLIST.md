# Amar Hisab – Production Release Checklist

**Version:** 1.0.0
**Date:** 2026-08-05
**Target:** Core system Phases 1–9 verified, ready for production cutover.

---

## 1. Pre-launch checks (engineering)

| # | Check | Owner | Status |
|---|-------|-------|--------|
| 1.1 | `dart pub get` resolves with no version conflicts | Eng | ☐ |
| 1.2 | `dart analyze --fatal-warnings` returns **0 issues** | Eng | ☐ |
| 1.3 | `dart test` passes (unit tests + integration tests) | Eng | ☐ |
| 1.4 | Build code generation: `dart run build_runner build --delete-conflicting-outputs` clean | Eng | ☐ |
| 1.5 | DB migrations: `dart run tool/reset_schema_marker.dart` then start server → migrations apply idempotently | Eng | ☐ |
| 1.6 | Manual smoke test on macOS, Windows, and Linux | Eng | ☐ |
| 1.7 | All routers mounted in `bin/server.dart` – verified via `routes.txt` self-test | Eng | ☐ |
| 1.8 | RBAC review: `role_seeder.dart` covers §4.1 – §4.7 of the RBAC Book | Eng | ☐ |
| 1.9 | Audit + change-log emitted for every mutating service call | Eng | ☐ |
| 1.10 | Domain events published **after** `commit`, never before | Eng | ☐ |
| 1.11 | Sensitive defaults cleared from `.env.example` | Eng | ☐ |
| 1.12 | `docker build` of the backend and sync images succeed | Eng | ☐ |
| 1.13 | Image sizes within budgets (backend ≤ 150 MB, sync ≤ 30 MB) | Eng | ☐ |

---

## 2. Environment / infrastructure setup

| # | Step | Status |
|---|------|--------|
| 2.1 | Copy `.env.prod` → `.env` and fill in every value (no `__CHANGE_ME__` left) | ☐ |
| 2.2 | Generate a real `JWT_SECRET` – e.g. `openssl rand -base64 48` | ☐ |
| 2.3 | Point DNS `hisab.<your-domain>` at the production host | ☐ |
| 2.4 | Open inbound ports 80 / 443 in the firewall (and 8080 only if needed) | ☐ |
| 2.5 | Create TLS certificates via `docker compose -f docker-compose.prod.yml --profile tls run --rm certbot` | ☐ |
| 2.6 | Confirm nginx proxies `/api/*` to backend container | ☐ |
| 2.7 | Postgres and Redis containers healthy (`docker compose ps`) | ☐ |
| 2.8 | `curl -k https://your-domain/health` returns `200` | ☐ |
| 2.9 | `curl -k https://your-domain/metrics` returns Prometheus text | ☐ |
| 2.10 | Import Grafana dashboard from `monitoring/grafana/amar_hisab_dashboard.json` | ☐ |

---

## 3. Data seeding

| # | Step | Status |
|---|------|--------|
| 3.1 | Verify system roles were created (Owner / Admin / Manager / Cashier / Accountant / Inventory Manager) | ☐ |
| 3.2 | Verify default Chart of Accounts seeded for the chosen business type | ☐ |
| 3.3 | Add initial users (one Cashier + one Accountant at minimum) | ☐ |
| 3.4 | Optional – load demo data (products, customers) via the Setup wizard | ☐ |
| 3.5 | Confirm primary warehouse created and assigned during setup | ☐ |
| 3.6 | If multi-branch, link second site via Cloud Sync with a test sync cycle | ☐ |

---

## 4. Smoke tests (full flow)

| # | Flow | Expected | Status |
|---|------|----------|--------|
| 4.1 | Operator login with Cashier JWT | Token issued, `/api/v1/auth/me` returns 200 | ☐ |
| 4.2 | Create a product (Owner) | `POST /api/v1/products` returns 201 | ☐ |
| 4.3 | Record a purchase (Manager) | Stock increases, journal posts to Inventory + AP | ☐ |
| 4.4 | POS sale (Cashier) | Cash / bKash splits, receipt prints, stock decrements, journal balance | ☐ |
| 4.5 | Process return (Owner) | Stock restored, sale reversal journal auto-posted | ☐ |
| 4.6 | Generate reports (Accountant) | `GET /api/v1/reports/*` produces an Excel + PDF export | ☐ |
| 4.7 | Manual backup to USB | `.zip` file lands in the backup folder, restore works | ☐ |
| 4.8 | Force full schema restore into a scratch DB | Same content hash as the source | ☐ |
| 4.9 | Cloud sync (if enabled) | Delta moves between sites within 60 s | ☐ |

---

## 5. Backup & rollback

| # | Step | Status |
|---|------|--------|
| 5.1 | Daily scheduled backup configured (Google Drive or Telegram) | ☐ |
| 5.2 | `health_check.sh` cron entry installed and green for 24 h | ☐ |
| 5.3 | Rollback runbook placed next to production keys (DB restore + image rollback) | ☐ |
| 5.4 | Test rollback on a non-prod copy of production | ☐ |
| 5.5 | Verify container image tags (`amarhisab/backend:1.0.0`) are pushed to your registry | ☐ |

Rollback short version:

```bash
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d --build --tag 1.0.0-previous
# OR restore DB directly:
#   cp data/amar_hisab.db data/amar_hisab.db.current
#   gunzip -c data/backups/<latest>.dump.gz > data/amar_hisab.db
```

---

## 6. Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Lead Engineer | | | |
| Product Owner | | | |
| QA | | | |
| IT Admin | | | |
