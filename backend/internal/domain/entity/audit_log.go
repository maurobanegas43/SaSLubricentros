package entity

import "time"

// AuditAction represents the type of action performed
type AuditAction string

const (
	AuditActionInsert AuditAction = "INSERT"
	AuditActionUpdate AuditAction = "UPDATE"
	AuditActionDelete AuditAction = "DELETE"
)

// AuditLog represents a general audit log entry
type AuditLog struct {
	ID         uint        `json:"id"`
	TableName  string      `json:"table_name"`
	RecordID   uint        `json:"record_id"`
	Action     AuditAction `json:"action"`
	OldData    *string     `json:"old_data,omitempty"` // JSON string
	NewData    *string     `json:"new_data,omitempty"` // JSON string
	ChangedBy  *uint       `json:"changed_by,omitempty"`
	ChangedAt  time.Time   `json:"changed_at"`
	IPAddress  *string     `json:"ip_address,omitempty"`
}

// AuthEventType represents the type of authentication event
type AuthEventType string

const (
	AuthEventRegistration       AuthEventType = "registration_attempt"
	AuthEventLogin              AuthEventType = "login_attempt"
	AuthEventPasswordRecovery   AuthEventType = "password_recovery_request"
	AuthEventPasswordReset      AuthEventType = "password_reset"
	AuthEventTokenValidation    AuthEventType = "token_validation_failure"
	AuthEventRateLimitExceeded  AuthEventType = "rate_limit_exceeded"
	AuthEventLogout             AuthEventType = "logout"
	AuthEventRefreshToken       AuthEventType = "refresh_token"
)

// AuthAuditLog represents an authentication-specific audit log entry
type AuthAuditLog struct {
	ID           uint          `json:"id"`
	EventType    AuthEventType `json:"event_type"`
	Email        *string       `json:"email,omitempty"`
	IPAddress    string        `json:"ip_address"`
	Success      bool          `json:"success"`
	ErrorMessage *string       `json:"error_message,omitempty"`
	CreatedAt    time.Time     `json:"created_at"`
}
