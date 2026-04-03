package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	jwtpkg "github.com/lubricentros/api/pkg/jwt"
)

const (
	ctxKeyUserID    = "user_id"
	ctxKeyUserEmail = "user_email"
	ctxKeyUserRole  = "user_role"
)

// Auth extracts and validates the JWT access token from the Authorization header,
// then sets user_id, user_email, and user_role in gin.Context.
func Auth(jwtMgr *jwtpkg.Manager) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"error":   "Unauthorized",
				"message": "Missing Authorization header",
			})
			return
		}

		// Expect "Bearer <token>"
		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"error":   "Unauthorized",
				"message": "Invalid Authorization header format. Use: Bearer <token>",
			})
			return
		}

		tokenString := parts[1]
		claims, err := jwtMgr.ValidateAccessToken(tokenString)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"error":   "Unauthorized",
				"message": "Invalid or expired access token",
			})
			return
		}

		// Set claims in context for downstream handlers
		c.Set(ctxKeyUserID, claims.UserID)
		c.Set(ctxKeyUserEmail, claims.Email)
		c.Set(ctxKeyUserRole, claims.Role)

		c.Next()
	}
}

// GetUserID extracts the user ID from gin.Context.
// Returns 0 if not set (should not happen if Auth middleware ran).
func GetUserID(c *gin.Context) uint {
	id, exists := c.Get(ctxKeyUserID)
	if !exists {
		return 0
	}
	uid, ok := id.(uint)
	if !ok {
		return 0
	}
	return uid
}

// GetUserEmail extracts the user email from gin.Context.
func GetUserEmail(c *gin.Context) string {
	email, exists := c.Get(ctxKeyUserEmail)
	if !exists {
		return ""
	}
	e, ok := email.(string)
	if !ok {
		return ""
	}
	return e
}

// GetUserRole extracts the user role from gin.Context.
func GetUserRole(c *gin.Context) string {
	role, exists := c.Get(ctxKeyUserRole)
	if !exists {
		return ""
	}
	r, ok := role.(string)
	if !ok {
		return ""
	}
	return r
}
