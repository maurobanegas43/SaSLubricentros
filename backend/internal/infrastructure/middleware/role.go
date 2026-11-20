package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/lubricentros/api/internal/domain/entity"
)

// RequireRole restricts access to specific roles.
// Must be used after AuthMiddleware.
func RequireRole(roles ...entity.Role) gin.HandlerFunc {
	return func(c *gin.Context) {
		userRoleRaw, exists := c.Get("role")
		if !exists {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
				"error":   "Forbidden",
				"message": "Role information not available",
			})
			return
		}

		userRole := entity.Role(userRoleRaw.(string))

		for _, allowed := range roles {
			if userRole == allowed {
				c.Next()
				return
			}
		}

		c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
			"error":   "Forbidden",
			"message": "Insufficient permissions for this resource",
		})
	}
}

// RequireAdmin is a convenience wrapper for admin-only routes.
func RequireAdmin() gin.HandlerFunc {
	return RequireRole(entity.RoleAdmin)
}

// RequireCustomerOrAdmin allows both roles (useful for routes that need auth but both can access).
func RequireCustomerOrAdmin() gin.HandlerFunc {
	return RequireRole(entity.RoleCustomer, entity.RoleAdmin)
}
