package middleware

import (
	"log"
	"net/http"
	"runtime/debug"

	"github.com/gin-gonic/gin"
)

// Recovery returns a Gin middleware that recovers from panics and returns a 500 error.
func Recovery() gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if err := recover(); err != nil {
				// Log the panic with stack trace for debugging
				log.Printf("[recovery] panic recovered: %v\n%s", err, debug.Stack())

				// Return generic error to client — never expose internal details
				c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
					"error":   "Internal Server Error",
					"message": "An unexpected error occurred. Please try again later.",
				})
			}
		}()

		c.Next()
	}
}
