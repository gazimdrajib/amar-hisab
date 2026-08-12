// Schema and migrations for the Cloud Sync Service (Architecture Book §8.5).
// The cloud holds the ordered change ledger from which any local database
// can be reconstructed; it is NOT a full replica of the local schema.
package store

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
)

// SchemaDDL applied idempotently at startup (development/CI). Production
// deployments should manage this with a proper migration tool; keeping the
// DDL here makes `main.go --migrate` self-contained.
const SchemaDDL = `
CREATE TABLE IF NOT EXISTS cloud_change_log (
    global_sequence BIGSERIAL PRIMARY KEY,
    change_id       TEXT   NOT NULL UNIQUE,
    business_id     BIGINT NOT NULL,
    device_id       TEXT   NOT NULL,
    entity_type     TEXT   NOT NULL,
    entity_id       BIGINT NOT NULL,
    operation       TEXT   NOT NULL CHECK (operation IN ('INSERT','UPDATE','DELETE')),
    payload         JSONB,
    old_values      JSONB,
    timestamp_ms    BIGINT NOT NULL,
    device_sequence BIGINT NOT NULL,
    received_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_ccg_business_seq ON cloud_change_log (business_id, global_sequence);
CREATE INDEX IF NOT EXISTS idx_ccg_entity ON cloud_change_log (business_id, entity_type, entity_id);

CREATE TABLE IF NOT EXISTS devices (
    device_id      TEXT PRIMARY KEY,
    business_id    BIGINT NOT NULL,
    device_name    TEXT,
    jwt_secret     TEXT,
    public_key     TEXT,
    is_authorized  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_devices_business ON devices (business_id);
`

// Migrate applies SchemaDDL.
func Migrate(ctx context.Context, pool *pgxpool.Pool) error {
	_, err := pool.Exec(ctx, SchemaDDL)
	return err
}
