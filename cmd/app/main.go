// Package main is the entry point. It reads the configuration, starts the server, and stops it on a signal.
package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/tabmadi/go-template/internal/config"
	"github.com/tabmadi/go-template/internal/server"
)

// The limits of the server.
const (
	readHeaderTimeout = 5 * time.Second
	shutdownTimeout   = 10 * time.Second
)

func main() {
	cfg, err := config.FromEnv()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	logger := slog.New(
		slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: cfg.LogLevel, AddSource: false, ReplaceAttr: nil}),
	)

	err = run(cfg, logger)
	if err != nil {
		logger.Error("the server failed", "error", err)
		os.Exit(1)
	}
}

// run serves until SIGINT or SIGTERM, then lets the open requests finish.
func run(cfg config.Config, logger *slog.Logger) error {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	//nolint:exhaustruct_v5 // A field left out keeps the default that net/http documents.
	srv := &http.Server{
		Addr:              net.JoinHostPort("", strconv.Itoa(cfg.Port)),
		Handler:           server.New(logger),
		ReadHeaderTimeout: readHeaderTimeout,
	}

	failed := make(chan error, 1)

	go func() {
		logger.InfoContext(ctx, "listening", "port", cfg.Port)

		err := srv.ListenAndServe()
		if !errors.Is(err, http.ErrServerClosed) {
			failed <- err
		}

		close(failed)
	}()

	select {
	case err := <-failed:
		return fmt.Errorf("listen: %w", err)
	case <-ctx.Done():
	}

	shutdownCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), shutdownTimeout)
	defer cancel()

	err := srv.Shutdown(shutdownCtx)
	if err != nil {
		return fmt.Errorf("shutdown: %w", err)
	}

	logger.InfoContext(shutdownCtx, "stopped")

	return nil
}
