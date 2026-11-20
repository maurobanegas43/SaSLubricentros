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

// TestEndToEndPasswordSecurity simulates a complete authentication flow
// and verifies passwords are never exposed at any point
func TestEndToEndPasswordSecurity(t *testing.T) {
	// Capture all log output
	var logBuf bytes.Buffer
	logger := log.New(&logBuf, "", 0)

	// Create logging middleware
	loggingMiddleware := NewLoggingMiddleware(logger)

	// Simulate a complete auth handler
	authHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Parse request
		var req map[string]interface{}
		json.NewDecoder(r.Body).Decode(&req)

		// Simulate authentication logic (without actual password processing)
		// In real implementation, password would be hashed here
		
		// Return response WITHOUT password
		response := map[string]interface{}{
			"token": "jwt.token.here",
			"user": map[string]interface{}{
				"id":    1,
				"email": req["email"],
				"name":  "Test User",
				// password is NOT included
			},
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(response)
	})

	// Wrap with logging middleware
	handler := loggingMiddleware.Middleware(authHandler)

	// Test data
	testPassword := "SuperSecret123!@#"
	requestBody := map[string]interface{}{
		"email":    "test@example.com",
		"password": testPassword,
		"name":     "Test User",
	}
	bodyBytes, _ := json.Marshal(requestBody)

	// Execute request
	req := httptest.NewRequest("POST", "/api/auth/register", bytes.NewReader(bodyBytes))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	// Verify password is NOT in logs
	logOutput := logBuf.String()
	if strings.Contains(logOutput, testPassword) {
		t.Errorf("CRITICAL SECURITY VIOLATION: Password %q found in logs!\nLog output:\n%s",
			testPassword, logOutput)
	}

	// Verify [REDACTED] is present
	if !strings.Contains(logOutput, "[REDACTED]") {
		t.Error("Expected [REDACTED] in logs for password field")
	}

	// Verify password is NOT in response
	responseBody := w.Body.String()
	if strings.Contains(responseBody, testPassword) {
		t.Errorf("CRITICAL SECURITY VIOLATION: Password found in response!\nResponse:\n%s",
			responseBody)
	}

	// Verify response doesn't have password field
	var response map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &response)
	
	if user, ok := response["user"].(map[string]interface{}); ok {
		if _, hasPassword := user["password"]; hasPassword {
			t.Error("SECURITY VIOLATION: Response contains password field")
		}
		if _, hasPasswordHash := user["password_hash"]; hasPasswordHash {
			t.Error("SECURITY VIOLATION: Response contains password_hash field")
		}
	}

	// Success
	t.Log("✅ End-to-end security test passed: password never exposed")
}

// TestMultiplePasswordFields verifies all password field variations are redacted
func TestMultiplePasswordFields(t *testing.T) {
	var logBuf bytes.Buffer
	logger := log.New(&logBuf, "", 0)
	middleware := NewLoggingMiddleware(logger)

	handler := middleware.Middleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	// Request with multiple password fields
	requestBody := `{
		"email": "test@example.com",
		"password": "Secret1",
		"newPassword": "Secret2",
		"oldPassword": "Secret3",
		"password_confirmation": "Secret1",
		"confirmPassword": "Secret1",
		"currentPassword": "Secret3"
	}`

	req := httptest.NewRequest("POST", "/api/auth/change-password", strings.NewReader(requestBody))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	logOutput := logBuf.String()

	// Verify none of the passwords appear in logs
	passwords := []string{"Secret1", "Secret2", "Secret3"}
	for _, password := range passwords {
		if strings.Contains(logOutput, password) {
			t.Errorf("SECURITY VIOLATION: Password %q found in logs", password)
		}
	}

	// Verify all fields were redacted
	redactedCount := strings.Count(logOutput, "[REDACTED]")
	if redactedCount < 6 {
		t.Errorf("Expected 6 [REDACTED] entries, got %d. Log: %s", redactedCount, logOutput)
	}
}

// TestPasswordInErrorScenarios verifies passwords are not exposed in error cases
func TestPasswordInErrorScenarios(t *testing.T) {
	var logBuf bytes.Buffer
	logger := log.New(&logBuf, "", 0)
	middleware := NewLoggingMiddleware(logger)

	// Simulate handler that returns an error
	handler := middleware.Middleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Simulate error response
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error": "Validation failed",
			"fields": map[string]string{
				"password": "Password must be at least 8 characters",
			},
		})
	}))

	testPassword := "Short1"
	requestBody := map[string]interface{}{
		"email":    "test@example.com",
		"password": testPassword,
	}
	bodyBytes, _ := json.Marshal(requestBody)

	req := httptest.NewRequest("POST", "/api/auth/register", bytes.NewReader(bodyBytes))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	// Verify password is not in logs even during error
	logOutput := logBuf.String()
	if strings.Contains(logOutput, testPassword) {
		t.Errorf("SECURITY VIOLATION: Password found in error logs: %s", logOutput)
	}

	// Verify error response doesn't contain actual password value
	responseBody := w.Body.String()
	if strings.Contains(responseBody, testPassword) {
		t.Errorf("SECURITY VIOLATION: Password found in error response: %s", responseBody)
	}
}
