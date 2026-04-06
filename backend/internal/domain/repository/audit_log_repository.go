package repository

import (
	"context"

	"github.com/lubricentros/api/internal/domain/entity"
)

// AuditLogRepository defines the interface for audit log data access
type AuditLogRepository interface {
	// Create creates a new audit log entry
	Create(ctx context.Context, log *entity.AuditLog) error

	// CreateAuthEvent creates a new authentication audit log entry
	CreateAuthEvent(ctx context.Context, log *entity.AuthAuditLog) error

	// GetByTableAndRecord retrieves audit logs for a specific table and record
	GetByTableAndRecord(ctx context.Context, tableName string, recordID uint, limit int) ([]entity.AuditLog, error)

	// GetAuthEventsByEmail retrieves authentication events for a specific email
	GetAuthEventsByEmail(ctx context.Context, email string, limit int) ([]entity.AuthAuditLog, error)

	// GetAuthEventsByIP retrieves authentication events for a specific IP address
	GetAuthEventsByIP(ctx context.Context, ipAddress string, limit int) ([]entity.AuthAuditLog, error)

	// GetRecentAuthEvents retrieves recent authentication events
	GetRecentAuthEvents(ctx context.Context, limit int) ([]entity.AuthAuditLog, error)

	// GetFailedLoginAttempts retrieves failed login attempts within a time window
	GetFailedLoginAttempts(ctx context.Context, email string, since int) (int, error)
}
