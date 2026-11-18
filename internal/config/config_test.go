package config_test

import (
	"errors"
	"log/slog"
	"testing"

	"github.com/tabmadi/go-template/internal/config"
)

// The variables that the configuration reads.
const (
	port     = "PORT"
	logLevel = "LOG_LEVEL"
)

func TestLoad(t *testing.T) {
	t.Parallel()

	// A rejected configuration has no value to compare.
	var rejected config.Config

	tests := []struct {
		name    string
		env     map[string]string
		want    config.Config
		wantErr bool
	}{
		{
			name:    "defaults",
			env:     map[string]string{},
			want:    config.Config{Port: config.DefaultPort, LogLevel: slog.LevelInfo},
			wantErr: false,
		},
		{
			name:    "empty values take the defaults",
			env:     map[string]string{port: "", logLevel: ""},
			want:    config.Config{Port: config.DefaultPort, LogLevel: slog.LevelInfo},
			wantErr: false,
		},
		{
			name:    "overrides",
			env:     map[string]string{port: "9000", logLevel: "DEBUG"},
			want:    config.Config{Port: 9000, LogLevel: slog.LevelDebug},
			wantErr: false,
		},
		{name: "port is not a number", env: map[string]string{port: "abc"}, want: rejected, wantErr: true},
		{name: "port is out of range", env: map[string]string{port: "70000"}, want: rejected, wantErr: true},
		{name: "unknown log level", env: map[string]string{logLevel: "loud"}, want: rejected, wantErr: true},
	}

	for _, testCase := range tests {
		t.Run(testCase.name, func(t *testing.T) {
			t.Parallel()

			got, err := config.Load(func(key string) string { return testCase.env[key] })
			if testCase.wantErr {
				if !errors.Is(err, config.ErrInvalid) {
					t.Fatalf("Load() error = %v, want ErrInvalid", err)
				}

				return
			}

			if err != nil {
				t.Fatalf("Load() error = %v", err)
			}

			if got != testCase.want {
				t.Errorf("Load() = %+v, want %+v", got, testCase.want)
			}
		})
	}
}
