# Amar Hisab – Monitoring

This folder contains everything needed to plug the local server into a
Prometheus + Grafana observability stack (Architecture Book §11.7).

## Contents

| File | Purpose |
|------|---------|
| `prometheus.yml` | Sample scrape config that targets the backend on `:8080`. |
| `grafana/amar_hisab_dashboard.json` | Pre-built Grafana dashboard (JSON import). |
| `health_check.sh` | One-shot health probe for cron / monitoring agents. |

## Backend endpoint

The Dart/Shelf backend now exposes `GET /metrics` in Prometheus text
exposition format.  It's wired in `bin/server.dart` and uses
`lib/monitoring/metrics.dart`.

Sample response:

```text
# HELP amar_hisab_sales_today_count Sales created today.
# TYPE amar_hisab_sales_today_count gauge
amar_hisab_sales_today_count 12 1754371200
# HELP amar_hisab_sales_today_amount Total revenue today.
...
amar_hisab_sync_pending 0 1754371200
```

The endpoint answers JSON instead of plain text when
`Accept: application/json` is sent.

## Quick start

1. Start the stack: `docker compose -f docker-compose.prod.yml up -d`
2. Install Prometheus, edit `prometheus.yml` to point at the backend.
3. Import `grafana/amar_hisab_dashboard.json` into Grafana (Dashboards →
   Import → Upload JSON).
4. Create a cron entry to call `health_check.sh` every 5 minutes:

   ```bash
   */5 * * * * /opt/amar-hisab/monitoring/health_check.sh >> /var/log/amar-hisab-health.log 2>&1
   ```

## Metrics reference

| Metric | Type | Meaning |
|--------|------|---------|
| `amar_hisab_uptime_seconds` | gauge | Seconds since the backend booted. |
| `amar_hisab_sales_today_count` | gauge | Sales created on the server today. |
| `amar_hisab_sales_today_amount` | gauge | Total revenue today (in base currency). |
| `amar_hisab_low_stock_items` | gauge | Items at / below reorder level. |
| `amar_hisab_expiring_batches` | gauge | Batches expiring within 30 days (pharmacy). |
| `amar_hisab_sync_pending` | gauge | Pending change-log rows awaiting cloud sync. |
| `amar_hisab_counters` | counter | In-process counters keyed by label. |

## Health check contract

`health_check.sh` exits:

* `0` when all five checks pass (server, DB, backup, sync, disk).
* `1` when any check fails.
* `2` for missing prerequisites (`curl`, `sqlite3`, `jq`).

Override the defaults with environment variables:

* `SERVER_URL` – default `http://localhost:8080`
* `DB_PATH` – default `data/amar_hisab.db`
* `BACKUP_DIR` – default `backups`
* `BACKUP_MAX_AGE_HOURS` – default `48`
* `API_TOKEN` – optional `Bearer <jwt>` for the authenticated sync status
  endpoint; otherwise the script falls back to reading the Prometheus gauge.

## Grafana provisioning (optional)

To ship the dashboard via Grafana provisioning instead of manual import,
mount the JSON into Grafana and point a `dashboards.yaml` provider at it:

```yaml
apiVersion: 1
providers:
  - name: default
    folder: Amar Hisab
    type: file
    disableDeletion: true
    updateIntervalSeconds: 60
    options:
      path: /etc/grafana/provisioning/dashboards
```
