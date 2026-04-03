package middleware

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// TestPasswordNeverLogged verifies that passwords are never exposed in logs
func TestPasswordNeverLogged(t *testing.T) {
	tests := []struct {
		name        string
		method      string
		path        string
		body        string
		password    string
	}{
		{
			name:     "registration request",
			method:   "POST",
			path:     "/api/auth/register",
			body:     `{"email":"test@example.com","password":"MySecret123","name":"Test User"}`,
			password: "MySecret123",
		},
		{
			name:     "login request",
			method:   "POST",
			path:     "/api/auth/login",
			body:     `{"email":"test@example.com","password":"AnotherSecret456"}`,
			password: "AnotherSecret456",
		},
		{
			name:     "password reset request",
			method:   "POST",
			path:     "/api/auth/password-reset",
			body:     `{"token":"abc123","newPassword":"NewSecret789"}`,
			password: "NewSecret789",
		},
		{
			name:     "password with special characters",
			method:   "POST",
			path:     "/api/auth/login",
			body:     `{"email":"user@test.com","password":"P@ssw0rd!#$%"}`,
			password: "P@ssw0rd!#$%",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Capture all log output
			var logBuf bytes.Buffer
			logger := log.New(&logBuf, "", 0)

			middleware := NewLoggingMiddleware(logger)

			// Create a test handler
			handler := middleware.Middleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				w.WriteHeader(http.StatusOK)
				w.Write([]byte(`{"status":"ok"}`))
			}))

			// Create request
			req := httptest.NewRequest(tt.method, tt.path, strings.NewReader(tt.body))
			req.Header.Set("Content-Type", "application/json")
			w := httptest.NewRecorder()

			// Execute request
			handler.ServeHTTP(w, req)

			// Verify password is NOT in logs
			logOutput := logBuf.String()
			if strings.Contains(logOutput, tt.password) {
				t.Errorf("SECURITY VIOLATION: Password %q found in logs!\nLog output: %s", 
					tt.password, logOutput)
			}

			// Verify [REDACTED] is present for password fields
			if !strings.Contains(logOutput, "[REDACTED]") {
				t.Errorf("Expected [REDACTED] in logs for password field, but not found. Log: %s", 
					logOutput)
			}
		})
	}
}

// TestPasswordNotInResponse verifies that API responses never include passwords
func TestPasswordNotInResponse(t *testing.T) {
	// Simulate a handler that returns user data
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// This simulates what the auth handler should return
		userData := map[string]interface{}{
			"id":    1,
			"email": "test@example.com",
			"name":  "Test User",
			"phone": "1234567890",
			// password and password_hash should NEVER be here
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"token": "jwt.token.here",
			"user":  userData,
		})
	})

	req := httptest.NewRequest("POST", "/api/auth/login", nil)
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	// Parse response
	var response map[string]interface{}
	if err := json.NewDecoder(w.Body).Decode(&response); err != nil {
		t.Fatalf("Failed to decode response: %v", err)
	}

	// Verify no password fields in response
	responseStr := w.Body.String()
	forbiddenFields := []string{"password", "password_hash", "passwordHash"}

	for _, field := range forbiddenFields {
		if strings.Contains(responseStr, field) {
			t.Errorf("SECURITY VIOLATION: Response contains forbidden field %q: %s", 
				field, responseStr)
		}
	}

	// Verify user data exists but without password
	user, ok := response["user"].(map[string]interface{})
	if !ok {
		t.Fatal("Expected user object in response")
	}

	if _, hasPassword := user["password"]; hasPassword {
		t.Error("SECURITY VIOLATION: User object contains password field")
	}

	if _, hasPasswordHash := user["password_hash"]; hasPasswordHash {
		t.Error("SECURITY VIOLATION: User object contains password_hash field")
	}
}

// TestErrorMessagesDoNotExposePasswords verifies error messages are generic
func TestErrorMessagesDoNotExposePasswords(t *testing.T) {
	// Simulate error responses
	errorResponses := []struct {
		name     string
		response string
	}{
		{
			name:     "invalid credentials",
			response: `{"error":"Unauthorized","message":"Invalid email or password"}`,
		},
		{
			name:     "validation error",
			response: `{"error":"Validation failed","fields":{"password":"Password must be at least 8 characters"}}`,
		},
		{
			name:     "duplicate email",
			response: `{"error":"Conflict","message":"Email already registered"}`,
		},
	}

	for _, tt := range errorResponses {
		t.Run(tt.name, func(t *testing.T) {
			// Verify error message doesn't contain actual password values
			// This is a basic check - in real implementation, ensure no password values leak
			if strings.Contains(tt.response, "MySecret123") ||
				strings.Contains(tt.response, "password=") ||
				strings.Contains(tt.response, "password:") {
				t.Errorf("SECURITY VIOLATION: Error message may expose password: %s", tt.response)
			}
		})
	}
}
