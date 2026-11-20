package middleware

import (
	"bytes"
	"log"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestLoggingMiddleware_RedactsPasswords(t *testing.T) {
	tests := []struct {
		name           string
		requestBody    string
		shouldContain  []string
		shouldNotContain []string
	}{
		{
			name: "redacts password field",
			requestBody: `{"email":"test@example.com","password":"SecretPass123"}`,
			shouldContain: []string{"email", "test@example.com", "[REDACTED]"},
			shouldNotContain: []string{"SecretPass123"},
		},
		{
			name: "redacts newPassword field",
			requestBody: `{"token":"abc123","newPassword":"NewSecret456"}`,
			shouldContain: []string{"token", "abc123", "[REDACTED]"},
			shouldNotContain: []string{"NewSecret456"},
		},
		{
			name: "redacts password_confirmation field",
			requestBody: `{"password":"Pass123","password_confirmation":"Pass123"}`,
			shouldContain: []string{"[REDACTED]"},
			shouldNotContain: []string{"Pass123"},
		},
		{
			name: "handles non-password fields normally",
			requestBody: `{"email":"user@example.com","name":"John Doe"}`,
			shouldContain: []string{"email", "user@example.com", "name", "John Doe"},
			shouldNotContain: []string{"[REDACTED]"},
		},
		{
			name: "handles empty body",
			requestBody: ``,
			shouldContain: []string{},
			shouldNotContain: []string{"[REDACTED]"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Capture log output
			var logBuf bytes.Buffer
			logger := log.New(&logBuf, "", 0)
			
			middleware := NewLoggingMiddleware(logger)
			
			// Create test handler
			handler := middleware.Middleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				w.WriteHeader(http.StatusOK)
			}))
			
			// Create request
			req := httptest.NewRequest("POST", "/api/auth/login", strings.NewReader(tt.requestBody))
			req.Header.Set("Content-Type", "application/json")
			w := httptest.NewRecorder()
			
			// Execute
			handler.ServeHTTP(w, req)
			
			// Verify log output
			logOutput := logBuf.String()
			
			for _, expected := range tt.shouldContain {
				if !strings.Contains(logOutput, expected) {
					t.Errorf("Expected log to contain %q, but it didn't. Log: %s", expected, logOutput)
				}
			}
			
			for _, notExpected := range tt.shouldNotContain {
				if strings.Contains(logOutput, notExpected) {
					t.Errorf("Expected log NOT to contain %q, but it did. Log: %s", notExpected, logOutput)
				}
			}
		})
	}
}

func TestLoggingMiddleware_LogsRequestMetadata(t *testing.T) {
	var logBuf bytes.Buffer
	logger := log.New(&logBuf, "", 0)
	
	middleware := NewLoggingMiddleware(logger)
	
	handler := middleware.Middleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusCreated)
	}))
	
	req := httptest.NewRequest("POST", "/api/auth/register", strings.NewReader(`{"email":"test@example.com"}`))
	w := httptest.NewRecorder()
	
	handler.ServeHTTP(w, req)
	
	logOutput := logBuf.String()
	
	// Verify request metadata is logged
	if !strings.Contains(logOutput, "method=POST") {
		t.Error("Expected log to contain method")
	}
	if !strings.Contains(logOutput, "path=/api/auth/register") {
		t.Error("Expected log to contain path")
	}
	if !strings.Contains(logOutput, "status=201") {
		t.Error("Expected log to contain status code")
	}
	if !strings.Contains(logOutput, "duration=") {
		t.Error("Expected log to contain duration")
	}
}
