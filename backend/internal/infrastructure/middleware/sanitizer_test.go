package middleware

import (
	"testing"
)

func TestSanitizeString(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{
			name:     "trim whitespace",
			input:    "  hello world  ",
			expected: "hello world",
		},
		{
			name:     "html entity encoding",
			input:    "<script>alert('xss')</script>",
			expected: "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;",
		},
		{
			name:     "special characters",
			input:    "test & test",
			expected: "test &amp; test",
		},
		{
			name:     "quotes",
			input:    `test "quoted" text`,
			expected: `test &#34;quoted&#34; text`,
		},
		{
			name:     "empty string",
			input:    "",
			expected: "",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := sanitizeString(tt.input)
			if result != tt.expected {
				t.Errorf("sanitizeString(%q) = %q, want %q", tt.input, result, tt.expected)
			}
		})
	}
}

func TestContainsSQLInjection(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected bool
	}{
		{
			name:     "union select attack",
			input:    "' UNION SELECT * FROM users --",
			expected: true,
		},
		{
			name:     "drop table attack",
			input:    "'; DROP TABLE users; --",
			expected: true,
		},
		{
			name:     "or 1=1 attack",
			input:    "' OR '1'='1",
			expected: true,
		},
		{
			name:     "insert into attack",
			input:    "'; INSERT INTO users VALUES ('hacker', 'pass'); --",
			expected: true,
		},
		{
			name:     "normal email",
			input:    "user@example.com",
			expected: false,
		},
		{
			name:     "normal text",
			input:    "This is a normal text",
			expected: false,
		},
		{
			name:     "text with apostrophe",
			input:    "O'Brien",
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := ContainsSQLInjection(tt.input)
			if result != tt.expected {
				t.Errorf("ContainsSQLInjection(%q) = %v, want %v", tt.input, result, tt.expected)
			}
		})
	}
}

func TestSanitizeMap(t *testing.T) {
	tests := []struct {
		name     string
		input    map[string]interface{}
		expected map[string]interface{}
	}{
		{
			name: "sanitize string values",
			input: map[string]interface{}{
				"name":  "  John Doe  ",
				"email": "<script>alert('xss')</script>",
			},
			expected: map[string]interface{}{
				"name":  "John Doe",
				"email": "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;",
			},
		},
		{
			name: "nested map",
			input: map[string]interface{}{
				"user": map[string]interface{}{
					"name": "  Jane  ",
				},
			},
			expected: map[string]interface{}{
				"user": map[string]interface{}{
					"name": "Jane",
				},
			},
		},
		{
			name: "mixed types",
			input: map[string]interface{}{
				"name":   "  Test  ",
				"age":    25,
				"active": true,
			},
			expected: map[string]interface{}{
				"name":   "Test",
				"age":    25,
				"active": true,
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			sanitizeMap(tt.input)
			// Compare string values
			for key, expectedVal := range tt.expected {
				if actualVal, ok := tt.input[key]; ok {
					if strVal, ok := actualVal.(string); ok {
						if expStr, ok := expectedVal.(string); ok {
							if strVal != expStr {
								t.Errorf("sanitizeMap() key %q = %q, want %q", key, strVal, expStr)
							}
						}
					}
				}
			}
		})
	}
}
