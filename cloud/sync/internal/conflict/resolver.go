// Package resolver implements the cloud-side conflict policy
// (Architecture Book §17 / Phase 9 Part E).
//
// The cloud resolves conflicts the moment a change is appended, before it is
// broadcast. The merged ledger row is what subsequent pulls stream down.
//
// Strategies mirror the local ChangeResolver:
//   - LWW        (default): newest timestamp_ms wins.
//   - fieldMerge : customers / suppliers merge non-conflicting fields.
//   - appendOnly : journal_entries, stock_movements – first write wins;
//     later divergent writes are reported as conflicts.
//   - eventSourced: stock quantity columns are replayed by each device, never
//     merged; only INSERT of unknown entities is applied.
package resolver

import (
	"encoding/json"
	"strings"

	syncv1 "github.com/amarhisab/amar-hisab/cloud/sync/proto/sync/v1"
)

// Decision describes how an incoming event interacts with the ledger.
type Decision struct {
	// Apply: insert the event into the merged ledger.
	Apply bool

	// Conflict: report back to the pushing device (with a reason) and keep
	// the previously stored version.
	Conflict bool
	Reason   string

	// MergedPayload: when field-level merging produced a different payload,
	// this replaces the event payload in the merged ledger.
	MergedPayload []byte
}

// Strategy classification of an entity (Phase 9 Part E).
func Strategy(entityType string) string {
	switch strings.ToLower(entityType) {
	case "customer", "customers", "supplier", "suppliers":
		return "fieldmerge"
	case "journal_entry", "journal_entries", "journal_line", "journal_lines",
		"stock_movement", "stock_movements":
		return "appendonly"
	case "stock", "batch", "batches":
		return "eventsourced"
	default:
		return "lww"
	}
}

// protectedKeys are never copied between versions.
var protectedKeys = map[string]bool{"id": true, "business_id": true, "created_at": true}

// Resolve compares an incoming event against the previously accepted one.
// current may be nil when this is the first event for the entity.
func Resolve(incoming *syncv1.ChangeEvent, current *syncv1.ChangeEvent) Decision {
	strategy := Strategy(incoming.GetEntityType())

	switch strategy {
	case "appendonly":
		if current == nil {
			return Decision{Apply: true}
		}
		if payloadEquivalent(current.GetPayload(), incoming.GetPayload()) {
			// Duplicate content – acknowledge without a side effect.
			return Decision{}
		}
		return Decision{Conflict: true,
			Reason: "append-only entity mutated on two devices"}

	case "eventsourced":
		// Quantity columns are replayed, never merged.
		if current == nil && incoming.GetOperation() == "INSERT" {
			return Decision{Apply: true}
		}
		return Decision{}

	case "fieldmerge":
		if current == nil {
			return Decision{Apply: true}
		}
		merged := fieldMerge(current.GetPayload(), incoming.GetPayload())
		if merged == nil {
			return Decision{Apply: true}
		}
		return Decision{Apply: true, MergedPayload: merged}

	default: // lww
		if current == nil {
			return Decision{Apply: true}
		}
		if incoming.GetTimestampMs() > current.GetTimestampMs() {
			return Decision{Apply: true}
		}
		if incoming.GetTimestampMs() == current.GetTimestampMs() &&
			incoming.GetChangeId() > current.GetChangeId() {
			// Deterministic tie-break: all devices converge regardless of
			// delivery order.
			return Decision{Apply: true}
		}
		return Decision{}
	}
}

// fieldMerge merges non-null fields from incoming over current. Returns nil
// when the incoming payload cannot be parsed (fall back to plain apply).
func fieldMerge(current, incoming []byte) []byte {
	if len(incoming) == 0 {
		return nil
	}
	var cur map[string]any
	if len(current) != 0 {
		if err := json.Unmarshal(current, &cur); err != nil {
			cur = map[string]any{}
		}
	} else {
		cur = map[string]any{}
	}
	var inc map[string]any
	if err := json.Unmarshal(incoming, &inc); err != nil {
		return nil
	}
	for k, v := range inc {
		if protectedKeys[k] || v == nil {
			continue
		}
		cur[k] = v
	}
	out, err := json.Marshal(cur)
	if err != nil {
		return nil
	}
	return out
}

func payloadEquivalent(a, b []byte) bool {
	if len(a) == 0 || len(b) == 0 {
		return len(a) == len(b)
	}
	var am, bm map[string]any
	if err := json.Unmarshal(a, &am); err != nil {
		return string(a) == string(b)
	}
	if err := json.Unmarshal(b, &bm); err != nil {
		return string(a) == string(b)
	}
	if len(am) != len(bm) {
		return false
	}
	for k, av := range am {
		bv, ok := bm[k]
		if !ok {
			return false
		}
		aj, _ := json.Marshal(av)
		bj, _ := json.Marshal(bv)
		if string(aj) != string(bj) {
			return false
		}
	}
	return true
}
