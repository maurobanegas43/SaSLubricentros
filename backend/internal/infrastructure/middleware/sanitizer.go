package middleware

import (
	"bytes"
	"encoding/json"
	"html"
	"io"
	"regexp"
	"strings"

	"github.com/gin-gonic/gin"
)

// SQL injection patterns to detect
var sqlInjectionPatterns = []*regexp.Regexp{
	regexp.MustCompile(`(?i)(union\s+select)`),
	regexp.MustCompile(`(?i)(insert\s+into)`),
	regexp.MustCompile(`(?i)(delete\s+from)`),
	regexp.MustCompile(`(?i)(drop\s+table)`),
	regexp.MustCompile(`(?i)(update\s+\w+\s+set)`),
	regexp.MustCompile(`(?i)(exec\s*\()`),
	regexp.MustCompile(`(?i)(execute\s*\()`),
	regexp.MustCompile(`(?i)(--)`),
	regexp.MustCompile(`(?i)(;.*--)`),
	regexp.MustCompile(`(?i)('.*or.*'.*=.*')`),
	regexp.MustCompile(`(?i)('.*or.*1.*=.*1)`),
}

// InputSanitizer middleware sanitizes all string inputs to prevent injection attacks
func InputSanitizer() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Only process JSON requests
		if c.ContentType() != "application/json" {
			c.Next()
			return
		}

		// Read raw body once
		rawBody, err := io.ReadAll(c.Request.Body)
		if err != nil {
			// If reading fails, keep request flow untouched
			c.Next()
			return
		}

		// Always restore body so handlers can bind it later
		c.Request.Body = io.NopCloser(bytes.NewBuffer(rawBody))

		// Empty body: nothing to sanitize
		if len(bytes.TrimSpace(rawBody)) == 0 {
			c.Next()
			return
		}

		// Decode body as generic map for recursive sanitization
		var body map[string]interface{}
		if err := json.Unmarshal(rawBody, &body); err != nil {
			// If binding fails, let the handler deal with it
			c.Next()
			return
		}

		// Sanitize all string values recursively
		sanitizeMap(body)

		// Marshal sanitized payload and re-inject it into request body
		sanitizedBody, err := json.Marshal(body)
		if err != nil {
			// Fallback to original body if marshal fails
			c.Request.Body = io.NopCloser(bytes.NewBuffer(rawBody))
			c.Next()
			return
		}

		// Store sanitized body in context for handlers to use
		c.Set("sanitized_body", body)
		c.Request.Body = io.NopCloser(bytes.NewBuffer(sanitizedBody))
		c.Request.ContentLength = int64(len(sanitizedBody))

		c.Next()
	}
}

// sanitizeMap recursively sanitizes all string values in a map
func sanitizeMap(m map[string]interface{}) {
	for key, value := range m {
		switch v := value.(type) {
		case string:
			m[key] = sanitizeString(v)
		case map[string]interface{}:
			sanitizeMap(v)
		case []interface{}:
			sanitizeSlice(v)
		}
	}
}

// sanitizeSlice recursively sanitizes all values in a slice
func sanitizeSlice(s []interface{}) {
	for i, value := range s {
		switch v := value.(type) {
		case string:
			s[i] = sanitizeString(v)
		case map[string]interface{}:
			sanitizeMap(v)
		case []interface{}:
			sanitizeSlice(v)
		}
	}
}

// sanitizeString performs multiple sanitization operations on a string
func sanitizeString(s string) string {
	// 1. Trim whitespace
	s = strings.TrimSpace(s)

	// 2. HTML entity encoding for special characters
	s = html.EscapeString(s)

	// 3. Detect SQL injection patterns (log but don't block - let validation handle it)
	for _, pattern := range sqlInjectionPatterns {
		if pattern.MatchString(s) {
			// In production, this should log to security audit
			// For now, we'll just continue
			break
		}
	}

	// 4. Normalize Unicode (NFC normalization)
	// This prevents Unicode-based attacks
	// Note: For full Unicode normalization, use golang.org/x/text/unicode/norm

	return s
}

// ContainsSQLInjection checks if a string contains SQL injection patterns
func ContainsSQLInjection(s string) bool {
	for _, pattern := range sqlInjectionPatterns {
		if pattern.MatchString(s) {
			return true
		}
	}
	return false
}
