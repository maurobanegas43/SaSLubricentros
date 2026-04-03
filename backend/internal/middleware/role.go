package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/lubricentros/api/internal/domain/entity"
)

// RequireRole returns a Gin middleware that checks if the user's role
// matches the required role. Must be used after Auth middleware.
func RequireRole(required entity.Role) gin.HandlerFunc {
	return func(c *gin.Context) {
		userRole := GetUserRole(c)
		if userRole == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"error":   "Unauthorized",
				"message": "User role not found in context",
			})
			return
		}

		if entity.Role(userRole) != required {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
				"success": false,
				"error":   "Forbidden",
				"message": "Insufficient permissions",
			})
			return
		}

		c.Next()
	}
}

// RequireAnyRole returns a Gin middleware that checks if the user's role
// matches any of the allowed roles.
func RequireAnyRole(allowed ...entity.Role) gin.HandlerFunc {
	return func(c *gin.Context) {
		userRole := GetUserRole(c)
		if userRole == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"error":   "Unauthorized",
				"message": "User role not found in context",
			})
			return
		}

		for _, r := range allowed {
			if entity.Role(userRole) == r {
				c.Next()
				return
			}
		}

		c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
			"success": false,
			"error":   "Forbidden",
			"message": "Insufficient permissions",
		})
	}
}
