package server_test

import (
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/tabmadi/go-template/internal/server"
)

func TestRoutes(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name       string
		path       string
		wantStatus int
		wantBody   string
	}{
		{name: "health", path: "/health", wantStatus: http.StatusOK, wantBody: `{"status":"ok"}`},
		{name: "unknown path", path: "/missing", wantStatus: http.StatusNotFound, wantBody: ""},
		{name: "root", path: "/", wantStatus: http.StatusNotFound, wantBody: ""},
	}

	handler := server.New(slog.New(slog.DiscardHandler))

	for _, testCase := range tests {
		t.Run(testCase.name, func(t *testing.T) {
			t.Parallel()

			request := httptest.NewRequestWithContext(t.Context(), http.MethodGet, testCase.path, nil)
			recorder := httptest.NewRecorder()
			handler.ServeHTTP(recorder, request)

			if recorder.Code != testCase.wantStatus {
				t.Errorf("status = %d, want %d", recorder.Code, testCase.wantStatus)
			}

			body, _ := io.ReadAll(recorder.Body)
			if testCase.wantBody != "" && string(body) != testCase.wantBody {
				t.Errorf("body = %q, want %q", body, testCase.wantBody)
			}
		})
	}
}
