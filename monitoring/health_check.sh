#!/usr/bin/env bash
# =============================================================================
# Amar Hisab – Node health check.
#
# Exits 0 when every probe passes, 1 otherwise.
# Usage: ./health_check.sh
#
# Uncomment / adapt MONITORING_* vars to suit your environment:
#   export SERVER_URL=http://localhost:8080
#   export DB_PATH=data/amar_hisab.db
#   export BACKUP_DIR=/backups
#   export BACKUP_MAX_AGE_HOURS=48
# =============================================================================

set -u

SERVER_URL="${SERVER_URL:-http://localhost:8080}"
DB_PATH="${DB_PATH:-data/amar_hisab.db}"
BACKUP_DIR="${BACKUP_DIR:-backups}"
BACKUP_MAX_AGE_HOURS="${BACKUP_MAX_AGE_HOURS:-48}"
SYNC_STATUS_URL="${SYNC_STATUS_URL:-${SERVER_URL}/api/v1/sync/status}"

REQUIRED_TOOLS=(curl sqlite3 jq)
for tool in "${REQUIRED_TOOLS[@]}"; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "[FAIL] $tool is required but not on PATH"
    exit 2
  fi
done

PASS=0
FAIL=0
log()  { printf '\033[36m[info]\033[0m  %s\n' "$*"; }
ok()   { printf '\033[32m[ ok ]\033[0m  %s\n' "$*";  PASS=$((PASS+1)); }
fail() { printf '\033[31m[FAIL]\033[0m  %s\n' "$*";  FAIL=$((FAIL+1)); }

# ------------------------------------------------------------ 1) /health up --
log "1) HTTP /health ($SERVER_URL/health)"
HEALTH_JSON="$(curl -sf --max-time 5 "$SERVER_URL/health" || true)"
if [[ -n "$HEALTH_JSON" && "$(echo "$HEALTH_JSON" | jq -r '.data.status // empty' 2>/dev/null)" == "ok" ]]; then
  ok "Server reachable, status=ok"
else
  fail "Server not reachable or status != ok: ${SERVER_URL}/health"
fi

# ---------------------------------------------------- 2) DB integrity check --
log "2) SQLite integrity ($DB_PATH)"
if [[ ! -f "$DB_PATH" ]]; then
  fail "Database file missing: $DB_PATH"
else
  INTEGRITY="$(sqlite3 "$DB_PATH" 'PRAGMA integrity_check;' 2>&1)"
  if [[ "$INTEGRITY" == "ok" ]]; then
    ok "SQLite integrity_check = ok"
  else
    fail "SQLite integrity_check failed: $INTEGRITY"
  fi
fi

# ---------------------------------------------------------- 3) Backup staleness --
log "3) Latest backup within ${BACKUP_MAX_AGE_HOURS}h"
LATEST_BACKUP="$(find "$BACKUP_DIR" -maxdepth 1 -type f \( -name '*.dump' -o -name '*.zip' -o -name '*.db.bak' \) -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2-)"
if [[ -z "${LATEST_BACKUP:-}" ]]; then
  fail "No backup found in $BACKUP_DIR"
else
  NOW_EPOCH="$(date +%s)"
  MTIME_EPOCH="$(stat -c %Y "$LATEST_BACKUP" 2>/dev/null || stat -f %m "$LATEST_BACKUP")"
  AGE_HOURS=$(( (NOW_EPOCH - MTIME_EPOCH) / 3600 ))
  if (( AGE_HOURS <= BACKUP_MAX_AGE_HOURS )); then
    ok "Backup fresh (${AGE_HOURS}h old) : $LATEST_BACKUP"
  else
    fail "Backup stale: ${LATEST_BACKUP} is ${AGE_HOURS}h old (>${BACKUP_MAX_AGE_HOURS}h)"
  fi
fi

# ------------------------------------------------------ 4) Sync pending count --
log "4) Sync pending <= 100"
# Requires auth; falls back to the metrics endpoint when an API token isn't
# available.  Export API_TOKEN="Bearer <jwt>" to hit the authenticated route.
SYNC_PENDING=""
if [[ -n "${API_TOKEN:-}" ]]; then
  SYNC_PENDING="$(curl -sf --max-time 5 -H "Authorization: $API_TOKEN" \
    "$SYNC_STATUS_URL" 2>/dev/null | jq -r '.data.pendingCount // empty')"
fi
if [[ -z "${SYNC_PENDING:-}" ]]; then
  # Fall back to Prometheus gauges
  SYNC_PENDING="$(curl -sf --max-time 5 -H "Accept: text/plain" "$SERVER_URL/metrics" \
    2>/dev/null | grep '^amar_hisab_sync_pending ' | awk '{print $2}' || echo 'not-reported')"
fi
if [[ "$SYNC_PENDING" == "not-reported" ]]; then
  log "  -> sync metrics not exposed (cloud sync probably disabled) – skipping"
elif [[ "$SYNC_PENDING" =~ ^[0-9]+$ && "$SYNC_PENDING" -le 100 ]]; then
  ok "Sync pending within bounds (${SYNC_PENDING})"
else
  fail "Sync pending out of bounds or unparseable: $SYNC_PENDING"
fi

# --------------------------------------------------------- 5) Disk space free --
log "5) Disk space free on $(df -k "$DB_PATH" 2>/dev/null | tail -n +2 | awk '{print $6}')"
FREE_KB="$(df -k "$DB_PATH" 2>/dev/null | tail -n +2 | awk '{print $4}')"
if [[ -n "$FREE_KB" && "$FREE_KB" -gt 2097152 ]]; then   # > 2 GiB
  ok "Disk ok ($((FREE_KB/1024/1024)) GiB free)"
else
  fail "Low disk space: $((FREE_KB/1024/1024)) GiB free (minimum 2 GiB)"
fi

# ---------------------------------------------------------------- result --
echo
if (( FAIL > 0 )); then
  echo "Health check: $FAIL failed, $PASS passed"
  exit 1
fi
echo "Health check: all $PASS checks passed"
exit 0
