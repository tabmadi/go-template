// Package config reads the configuration from the environment and checks it. No other package reads the environment.
package config

import (
	"errors"
	"fmt"
	"log/slog"
	"os"
	"strconv"
	"strings"
)

// The defaults and limits of the configuration.
const (
	DefaultPort = 8080
	maxPort     = 65535
)

// ErrInvalid marks a configuration value that the app cannot start with.
var ErrInvalid = errors.New("invalid configuration")

// Config holds the checked configuration of the app.
type Config struct {
	Port     int
	LogLevel slog.Level
}

// FromEnv reads the configuration from the environment of the process.
func FromEnv() (Config, error) {
	return Load(os.Getenv)
}

// Load reads the configuration through getenv. An unset or empty variable takes its default.
func Load(getenv func(string) string) (Config, error) {
	cfg := Config{Port: DefaultPort, LogLevel: slog.LevelInfo}

	portValue := getenv("PORT")
	if portValue != "" {
		port, err := strconv.Atoi(portValue)
		if err != nil || port < 1 || port > maxPort {
			return Config{}, fmt.Errorf(
				"%w: PORT must be a number from 1 to %d, not %q",
				ErrInvalid,
				maxPort,
				portValue,
			)
		}

		cfg.Port = port
	}

	levelValue := getenv("LOG_LEVEL")
	if levelValue != "" {
		level, err := parseLevel(levelValue)
		if err != nil {
			return Config{}, err
		}

		cfg.LogLevel = level
	}

	return cfg, nil
}

// parseLevel reads one of debug, info, warn, or error, in any case.
func parseLevel(value string) (slog.Level, error) {
	switch strings.ToLower(value) {
	case "debug":
		return slog.LevelDebug, nil
	case "info":
		return slog.LevelInfo, nil
	case "warn":
		return slog.LevelWarn, nil
	case "error":
		return slog.LevelError, nil
	default:
		return slog.LevelInfo, fmt.Errorf(
			"%w: LOG_LEVEL must be debug, info, warn, or error, not %q",
			ErrInvalid,
			value,
		)
	}
}
