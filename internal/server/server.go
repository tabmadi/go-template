// Package server holds the HTTP routes of the app.
package server

import (
	"log/slog"
	"net/http"
)

// New returns the handler of every route. It logs each request at the debug level.
func New(logger *slog.Logger) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", health)
	mux.HandleFunc("/", http.NotFound)

	return logRequests(logger, mux)
}

// health answers that the app is up.
func health(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	_, _ = w.Write([]byte(`{"status":"ok"}`))
}

// statusRecorder keeps the status code that a handler writes, so the log can show it.
type statusRecorder struct {
	http.ResponseWriter

	status int
}

func (r *statusRecorder) WriteHeader(status int) {
	r.status = status
	r.ResponseWriter.WriteHeader(status)
}

func logRequests(logger *slog.Logger, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		recorder := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(recorder, r)
		logger.DebugContext(r.Context(), "request", "method", r.Method, "path", r.URL.Path, "status", recorder.status)
	})
}
