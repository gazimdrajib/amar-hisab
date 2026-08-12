// Package service implements amarhisab.sync.v1.SyncService
// (Proto Contract Book §4.1).
package service

import (
	"context"
	"errors"
	"log/slog"
	"strconv"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	deviceauth "github.com/amarhisab/amar-hisab/cloud/sync/internal/auth"
	resolver "github.com/amarhisab/amar-hisab/cloud/sync/internal/conflict"
	"github.com/amarhisab/amar-hisab/cloud/sync/internal/store"
	syncv1 "github.com/amarhisab/amar-hisab/cloud/sync/proto/sync/v1"
)

// Broadcaster is the subset of the Redis notifier the service needs.
type Broadcaster interface {
	NotifyChangeAvailable(ctx context.Context, businessID int64, sequence int64)
}

// SyncService implements syncv1.SyncServiceServer.
type SyncService struct {
	syncv1.UnimplementedSyncServiceServer

	changes *store.ChangeStore
	pub     Broadcaster
	log     *slog.Logger
}

// New constructs the service.
func New(changes *store.ChangeStore, pub Broadcaster, log *slog.Logger) *SyncService {
	return &SyncService{changes: changes, pub: pub, log: log}
}

// authenticate resolves the device from the request metadata.
func (s *SyncService) authenticate(ctx context.Context) (deviceID string, businessID int64, err error) {
	md, ok := metadata.FromIncomingContext(ctx)
	if !ok {
		return "", 0, status.Error(codes.Unauthenticated, "missing metadata")
	}
	authz := md.Get("authorization")
	if len(authz) == 0 {
		return "", 0, status.Error(codes.Unauthenticated, "missing device credentials")
	}
	deviceID, businessID, err = deviceauth.ParseBearer(authz[0],
		func(id string) (int64, string, bool, error) {
			return s.changes.ResolveDevice(ctx, id)
		})
	if err != nil {
		if errors.Is(err, deviceauth.ErrUnauthorized) {
			return "", 0, status.Error(codes.Unauthenticated, "invalid device credentials")
		}
		return "", 0, status.Error(codes.Internal, "device lookup failed")
	}
	return deviceID, businessID, nil
}

// PushBatch processes an ordered batch of local changes: conflict-resolved,
// deduplicated by change_id, appended to the cloud ledger, then broadcast to
// the tenant's other devices.
func (s *SyncService) PushBatch(ctx context.Context, req *syncv1.PushBatchRequest) (*syncv1.PushBatchResponse, error) {
	deviceID, businessID, err := s.authenticate(ctx)
	if err != nil {
		return nil, err
	}
	if req.GetDeviceId() != "" && req.GetDeviceId() != deviceID {
		return nil, status.Error(codes.PermissionDenied, "device_id mismatch")
	}

	// Pre-resolve conflicts: give the pushing device useful feedback, and make
	// sure only winning events are appended.
	accept := make([]*syncv1.ChangeEvent, 0, len(req.Changes))
	conflicts := make([]*syncv1.Conflict, 0)

	for _, ev := range req.Changes {
		// Force tenant isolation: a device may only write its own business's
		// ledger regardless of payload content.
		ev.DeviceId = deviceID

		current, _ := s.changes.LatestFor(ctx, businessID, ev.GetEntityType(), ev.GetEntityId())
		decision := resolver.Resolve(ev, current)
		switch {
		case decision.Conflict:
			var localVersion []byte
			if current != nil {
				localVersion = current.GetPayload()
			}
			conflicts = append(conflicts, &syncv1.Conflict{
				ChangeId:      ev.GetChangeId(),
				Reason:        decision.Reason,
				LocalVersion:  ev.GetPayload(),
				RemoteVersion: localVersion,
			})
		case decision.Apply:
			if decision.MergedPayload != nil {
				ev.Payload = decision.MergedPayload
			}
			accept = append(accept, ev)
		}
	}

	acceptedSeq, dedup, err := s.changes.AppendChanges(ctx, businessID, accept)
	if err != nil {
		s.log.Error("append changes", "err", err, "device", deviceID)
		return nil, status.Error(codes.Internal, "failed to persist changes")
	}
	for _, id := range dedup {
		// Duplicate deliveries from the retry loop: acknowledge silently.
		conflicts = append(conflicts, &syncv1.Conflict{
			ChangeId: id, Reason: "duplicate delivery (idempotent)"})
	}

	if len(accept) > 0 && s.pub != nil {
		s.pub.NotifyChangeAvailable(ctx, businessID, acceptedSeq)
	}

	return &syncv1.PushBatchResponse{
		Success:          true,
		AcceptedSequence: acceptedSeq,
		Conflicts:        conflicts,
	}, nil
}

// PullChanges streams all ledger entries > last_remote_sequence for the
// caller's business (Proto Book §4.1). Events from the requesting device
// itself are skipped; for each remaining event the sequence field is set to
// the global ledger position so clients can persist a monotonic cursor.
func (s *SyncService) PullChanges(req *syncv1.PullRequest, stream grpc.ServerStreamingServer[syncv1.ChangeEvent]) error {
	deviceID, businessID, err := s.authenticate(stream.Context())
	if err != nil {
		return err
	}
	if req.GetBusinessId() != "" && req.GetBusinessId() != strconv.FormatInt(businessID, 10) {
		return status.Error(codes.PermissionDenied, "business_id mismatch")
	}

	s.log.Info("pull start", "device", deviceID, "after", req.GetLastRemoteSequence())
	if err := s.changes.StreamAfter(stream.Context(), businessID,
		req.GetLastRemoteSequence(), deviceID, stream.Send); err != nil {
		s.log.Error("pull", "err", err, "device", deviceID)
		return status.Error(codes.Internal, "pull failed")
	}
	return nil
}
