// package store fans out "new changes available" notifications to the
// other connected devices of the same tenant (Architecture Book §8.5).
// Redis Pub/Sub is the default broker; channels are namespaced per business:
// `sync:notify:business:{id}`.
package store

import (
	"context"
	"fmt"
	"strconv"

	"github.com/go-redis/redis/v8"
)

// Notifier publishes a lightweight ping after a successful push. Receivers
// only use the ping as a hint to call PullChanges – ordering and durability
// remain the PostgreSQL ledger's job.
type Notifier struct {
	rdb *redis.Client
}

// New connects to Redis at REDIS_ADDR (host:port), REDIS_PASSWORD optional.
func New(addr string, password string, db int) (*Notifier, error) {
	if addr == "" {
		return nil, nil // broadcast disabled (single-instance deployments)
	}
	rdb := redis.NewClient(&redis.Options{Addr: addr, Password: password, DB: db})
	if err := rdb.Ping(context.Background()).Err(); err != nil {
		return nil, fmt.Errorf("connect redis: %w", err)
	}
	return &Notifier{rdb: rdb}, nil
}

// NotifyChangeAvailable publishes the new high-water sequence for a business.
func (n *Notifier) NotifyChangeAvailable(ctx context.Context, businessID int64, sequence int64) {
	if n == nil || n.rdb == nil {
		return
	}
	_ = n.rdb.Publish(ctx, channel(businessID),
		strconv.FormatInt(sequence, 10)).Err()
}

// Subscribe returns a channel of sequence hints for one business.
func (n *Notifier) Subscribe(ctx context.Context, businessID int64) (<-chan string, func(), error) {
	if n == nil || n.rdb == nil {
		return nil, func() {}, nil
	}
	sub := n.rdb.Subscribe(ctx, channel(businessID))
	out := make(chan string, 8)
	go func() {
		defer close(out)
		ch := sub.Channel()
		for m := range ch {
			select {
			case out <- m.Payload:
			case <-ctx.Done():
				return
			}
		}
	}()
	return out, func() { _ = sub.Close() }, nil
}

func channel(businessID int64) string {
	return fmt.Sprintf("sync:notify:business:%d", businessID)
}
