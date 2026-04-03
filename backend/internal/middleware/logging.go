package middleware

import (
	"bytes"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"time"
)

// LoggingMiddleware logs HTTP requests with sensitive field redaction
type LoggingMiddleware struct {
	logger *log.Logger
}

// NewLoggingMiddleware creates a new logging middleware
func NewLoggingMiddleware(logger *log.Logger) *LoggingMiddleware {
	return &LoggingMiddleware{
		logger: logger,
	}
}

// Middleware wraps HTTP handlers with request logging
func (m *LoggingMiddleware) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		// Read and restore request body for logging
		var bodyBytes []byte
		if r.Body != nil {
			bodyBytes, _ = io.ReadAll(r.Body)
			r.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))
		}

		// Redact sensitive fields from body
		redactedBody := m.redactSensitiveFields(bodyBytes)

		// Log request
		m.logger.Printf(
			"method=%s path=%s remote_addr=%s body=%s",
			r.Method,
			r.URL.Path,
			r.RemoteAddr,
			redactedBody,
		)

		// Wrap response writer to capture status code
		wrapped := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}

		// Call next handler
		next.ServeHTTP(wrapped, r)

		// Log response
		duration := time.Since(start)
		m.logger.Printf(
			"method=%s path=%s status=%d duration=%s",
			r.Method,
			r.URL.Path,
			wrapped.statusCode,
			duration,
		)
	})
}

// redactSensitiveFields removes password fields from JSON body
func (m *LoggingMiddleware) redactSensitiveFields(bodyBytes []byte) string {
	if len(bodyBytes) == 0 {
		return ""
	}

	var body map[string]interface{}
	if err := json.Unmarshal(bodyBytes, &body); err != nil {
		return "[invalid json]"
	}

	// List of sensitive fields to redact
	sensitiveFields := []string{
		"password",
		"newPassword",
		"oldPassword",
		"password_confirmation",
		"confirmPassword",
		"currentPassword",
	}

	// Redact sensitive fields
	for _, field := range sensitiveFields {
		if _, exists := body[field]; exists {
			body[field] = "[REDACTED]"
		}
	}

	redacted, err := json.Marshal(body)
	if err != nil {
		return "[redaction error]"
	}

	return string(redacted)
}

// responseWriter wraps http.ResponseWriter to capture status code
type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}
