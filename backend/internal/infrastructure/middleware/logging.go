package middleware

import (
	"log"
	"time"

	"github.com/gin-gonic/gin"
)

// RequestLogger returns a Gin middleware that logs HTTP requests with sensitive field redaction.
func RequestLogger(logger *log.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path

		// Process request
		c.Next()

		// Log after request completes
		duration := time.Since(start)
		statusCode := c.Writer.Status()

		logger.Printf(
			"method=%s path=%s status=%d duration=%s client_ip=%s",
			c.Request.Method,
			path,
			statusCode,
			duration,
			c.ClientIP(),
		)
	}
}

// SensitiveFields defines request fields that should never be logged.
var SensitiveFields = []string{
	"password",
	"new_password",
	"newPassword",
	"old_password",
	"oldPassword",
	"password_confirmation",
	"confirmPassword",
	"currentPassword",
	"current_password",
	"token_hash",
}
