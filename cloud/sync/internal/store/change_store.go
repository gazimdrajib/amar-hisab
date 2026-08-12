// Package store implements the PostgreSQL persistence for the cloud change
// ledger (Architecture Book §8.5 – Merge Log).
//
// The cloud schema (a superset of the local one; Database Book §2) is:
//
//	cloud_change_log(global_sequence BIGSERIAL PK,
//	                 change_id TEXT UNIQUE NOT NULL,
//	                 business_id BIGINT NOT NULL,
//	                 device_id TEXT NOT NULL,
//	                 entity_type TEXT NOT NULL,
//	                 entity_id BIGINT NOT NULL,
//	                 operation TEXT NOT NULL,
//	                 payload JSONB, old_values JSONB,
//	                 timestamp_ms BIGINT NOT NULL, device_sequence BIGINT NOT NULL,
//	                 received_at TIMESTAMPTZ NOT NULL DEFAULT now())
//
// Devices authenticate via `devices(device_id, business_id, jwt_secret,
// certificate_fingerprint, is_authorized)`.
package store

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	syncv1 "github.com/amarhisab/amar-hisab/cloud/sync/proto/sync/v1"
)

// LatestFor reads the newest merged change for an entity (used by the
// conflict resolver before appending).
func (s *ChangeStore) LatestFor(ctx context.Context, businessID int64, entityType string, entityID int64) (*syncv1.ChangeEvent, error) {
	var ev syncv1.ChangeEvent
	var payloadStr, oldStr string
	err := s.pool.QueryRow(ctx, `
		SELECT change_id, device_id, entity_type, entity_id, operation,
		       COALESCE(payload::text, ''), COALESCE(old_values::text, ''),
		       timestamp_ms, device_sequence
		  FROM cloud_change_log
		 WHERE business_id = $1 AND entity_type = $2 AND entity_id = $3
		 ORDER BY global_sequence DESC LIMIT 1`,
		businessID, entityType, entityID).
		Scan(&ev.ChangeId, &ev.DeviceId, &ev.EntityType, &ev.EntityId,
			&ev.Operation, &payloadStr, &oldStr, &ev.TimestampMs, &ev.Sequence)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	ev.Payload = []byte(payloadStr)
	ev.OldValues = []byte(oldStr)
	return &ev, nil
}

// StoredChange is one row of the cloud change ledger.
type StoredChange struct {
	GlobalSequence int64
	ChangeID       string
	BusinessID     int64
	DeviceID       string
	EntityType     string
	EntityID       int64
	Operation      string
	Payload        []byte
	OldValues      []byte
	TimestampMs    int64
	DeviceSequence int64
}

// ErrDuplicateChange is returned for replayed change IDs (at-least-once
// delivery; Proto Book §4.1 idempotency).
var ErrDuplicateChange = errors.New("change_id already processed")

// ChangeStore wraps the PostgreSQL connection pool.
type ChangeStore struct {
	pool *pgxpool.Pool
}

// NewChangeStore connects to PostgreSQL (DATABASE_URL env).
func NewChangeStore(ctx context.Context, databaseURL string) (*ChangeStore, error) {
	pool, err := pgxpool.New(ctx, databaseURL)
	if err != nil {
		return nil, fmt.Errorf("connect postgres: %w", err)
	}
	if err := pool.Ping(ctx); err != nil {
		return nil, fmt.Errorf("ping postgres: %w", err)
	}
	return &ChangeStore{pool: pool}, nil
}

// Close releases the pool.
func (s *ChangeStore) Close() { s.pool.Close() }

// Pool exposes the underlying pool for migrations / health checks.
func (s *ChangeStore) Pool() *pgxpool.Pool { return s.pool }

// ResolveDevice returns (businessID, jwtSecret, authorized) for a device.
// Unknown devices return sql.ErrNoRows equivalent semantics.
func (s *ChangeStore) ResolveDevice(ctx context.Context, deviceID string) (businessID int64, jwtSecret string, authorized bool, err error) {
	err = s.pool.QueryRow(ctx, `
		SELECT business_id, COALESCE(jwt_secret, ''), is_authorized
		  FROM devices WHERE device_id = $1`, deviceID).
		Scan(&businessID, &jwtSecret, &authorized)
	if errors.Is(err, pgx.ErrNoRows) {
		return 0, "", false, nil
	}
	return businessID, jwtSecret, authorized, err
}

// AppendChanges inserts the batch in one transaction, deduplicating by
// change_id. Returns the new global high-water sequence for the business.
func (s *ChangeStore) AppendChanges(ctx context.Context, businessID int64, events []*syncv1.ChangeEvent) (acceptedSequence int64, conflicts []string, err error) {
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return 0, nil, err
	}
	defer func() {
		if err != nil {
			_ = tx.Rollback(ctx)
		}
	}()

	var maxSeq int64
	for _, ev := range events {
		var inserted bool
		row := tx.QueryRow(ctx, `
			INSERT INTO cloud_change_log
			    (change_id, business_id, device_id, entity_type, entity_id,
			     operation, payload, old_values, timestamp_ms, device_sequence)
			VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
			ON CONFLICT (change_id) DO NOTHING
			RETURNING global_sequence`,
			ev.GetChangeId(), businessID, ev.GetDeviceId(), ev.GetEntityType(),
			ev.GetEntityId(), ev.GetOperation(),
			nullIfEmpty(ev.GetPayload()), nullIfEmpty(ev.GetOldValues()),
			ev.GetTimestampMs(), ev.GetSequence())
		var seq int64
		if scanErr := row.Scan(&seq); scanErr != nil {
			if errors.Is(scanErr, pgx.ErrNoRows) {
				// Duplicate delivery – acknowledge without side effect.
				inserted = false
				conflicts = append(conflicts, ev.GetChangeId())
			} else {
				err = scanErr
				return 0, nil, err
			}
		}
		if inserted && seq > maxSeq {
			maxSeq = seq
		}
		if !inserted {
			// Ensure the duplicate does not extend the accepted window with a
			// value of zero below.
			row2 := tx.QueryRow(ctx,
				`SELECT global_sequence FROM cloud_change_log WHERE change_id = $1`,
				ev.GetChangeId())
			if scanErr := row2.Scan(&seq); scanErr == nil && seq > maxSeq {
				maxSeq = seq
			}
		}
	}

	if maxSeq == 0 {
		row := tx.QueryRow(ctx,
			`SELECT COALESCE(MAX(global_sequence), 0) FROM cloud_change_log WHERE business_id = $1`,
			businessID)
		if err = row.Scan(&maxSeq); err != nil {
			return 0, nil, err
		}
	}

	if err = tx.Commit(ctx); err != nil {
		return 0, nil, err
	}
	return maxSeq, conflicts, nil
}

// StreamAfter sends every ledger row for businessID with
// global_sequence > after, ordered ascending, into emit. Rows originating
// from deviceID are skipped (they already have their own changes).
func (s *ChangeStore) StreamAfter(ctx context.Context, businessID int64, after int64, excludeDevice string, emit func(*syncv1.ChangeEvent) error) error {
	rows, err := s.pool.Query(ctx, `
		SELECT global_sequence, change_id, device_id, entity_type, entity_id,
		       operation, COALESCE(payload::text, ''), COALESCE(old_values::text, ''),
		       timestamp_ms, device_sequence
		  FROM cloud_change_log
		 WHERE business_id = $1 AND global_sequence > $2
		 ORDER BY global_sequence ASC`, businessID, after)
	if err != nil {
		return err
	}
	defer rows.Close()

	for rows.Next() {
		var (
			globalSeq  int64
			ev         syncv1.ChangeEvent
			payloadStr string
			oldStr     string
		)
		if err := rows.Scan(&globalSeq, &ev.ChangeId, &ev.DeviceId,
			&ev.EntityType, &ev.EntityId, &ev.Operation, &payloadStr, &oldStr,
			&ev.TimestampMs, &ev.Sequence); err != nil {
			return err
		}
		if ev.DeviceId == excludeDevice {
			continue
		}
		ev.Payload = []byte(payloadStr)
		ev.OldValues = []byte(oldStr)
		// The device applies events in cloud order: overwrite sequence with
		// the global ledger position (clients track `last_remote_sequence`).
		ev.Sequence = globalSeq
		if err := emit(&ev); err != nil {
			return err
		}
	}
	return rows.Err()
}

func nullIfEmpty(b []byte) any {
	if len(b) == 0 {
		return nil
	}
	return string(b)
}
