// Cloud Sync Service entry point (Architecture Book §8.5).
//
//   DATABASE_URL    postgres DSN (required)
//   REDIS_ADDR      host:port (optional; broadcast disabled when empty)
//   GRPC_ADDR       listen address, default :9090
//   TLS_CERT/TLS_KEY paths for the server certificate (required – TLS 1.3);
//                   set INSECURE_DEV=true only for local development.
package main

import (
	"context"
	"crypto/tls"
	"errors"
	"flag"
	"fmt"
	"log/slog"
	"net"
	"os"
	"os/signal"
	"syscall"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"

	"github.com/amarhisab/amar-hisab/cloud/sync/internal/service"
	"github.com/amarhisab/amar-hisab/cloud/sync/internal/store"
	syncv1 "github.com/amarhisab/amar-hisab/cloud/sync/proto/sync/v1"
)

func main() {
	migrate := flag.Bool("migrate", false, "apply schema and exit")
	flag.Parse()

	log := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelInfo}))
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		log.Error("DATABASE_URL is required")
		os.Exit(1)
	}

	changes, err := store.NewChangeStore(ctx, databaseURL)
	if err != nil {
		log.Error("postgres", "err", err)
		os.Exit(1)
	}
	defer changes.Close()

	if *migrate {
		if err := store.Migrate(ctx, changes.Pool()); err != nil {
			log.Error("migrate", "err", err)
			os.Exit(1)
		}
		log.Info("schema applied")
		return
	}

	notifier, err := store.New(os.Getenv("REDIS_ADDR"), os.Getenv("REDIS_PASSWORD"), 0)
	if err != nil {
		log.Error("redis", "err", err)
		os.Exit(1)
	}

	addr := getenv("GRPC_ADDR", ":9090")
	lis, err := net.Listen("tcp", addr)
	if err != nil {
		log.Error("listen", "addr", addr, "err", err)
		os.Exit(1)
	}

	server, err := grpcServer()
	if err != nil {
		log.Error("tls", "err", err)
		os.Exit(1)
	}

	syncv1.RegisterSyncServiceServer(server, service.New(changes, notifier, log))

	go func() {
		<-ctx.Done()
		log.Info("shutting down")
		server.GracefulStop()
	}()

	log.Info("listening", "addr", lis.Addr().String())
	if err := server.Serve(lis); err != nil {
		log.Error("serve", "err", err)
		os.Exit(1)
	}
}

// grpcServer builds the gRPC server with TLS 1.3 (Architecture Book §10.3)
// unless INSECURE_DEV=true (local development only).
func grpcServer() (*grpc.Server, error) {
	if os.Getenv("INSECURE_DEV") == "true" {
		return grpc.NewServer(), nil
	}

	certPath, keyPath := os.Getenv("TLS_CERT"), os.Getenv("TLS_KEY")
	if certPath == "" || keyPath == "" {
		return nil, errors.New("TLS_CERT and TLS_KEY are required (or set INSECURE_DEV=true)")
	}
	cert, err := tls.LoadX509KeyPair(certPath, keyPath)
	if err != nil {
		return nil, fmt.Errorf("load TLS keypair: %w", err)
	}
	creds := credentials.NewTLS(&tls.Config{
		Certificates: []tls.Certificate{cert},
		MinVersion:   tls.VersionTLS13, // TLS 1.3 only
	})
	return grpc.NewServer(grpc.Creds(creds)), nil
}

func getenv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
