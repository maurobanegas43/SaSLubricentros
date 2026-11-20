package repository

import (
	"context"
	"database/sql"
	"encoding/json"
	"strings"
	"time"

	"github.com/lubricentros/api/internal/domain/entity"
)

// AuditLogRepositoryImpl is the MariaDB implementation of the AuditLogRepository interface
type AuditLogRepositoryImpl struct {
	*BaseRepository
}

// NewAuditLogRepository creates a new audit log repository
func NewAuditLogRepository(db *sql.DB) *AuditLogRepositoryImpl {
	return &AuditLogRepositoryImpl{
		BaseRepository: NewBaseRepository(db),
	}
}

// Create inserts a new audit log entry
func (r *AuditLogRepositoryImpl) Create(ctx context.Context, log *entity.AuditLog) error {
	query := `INSERT INTO audit_log (table_name, record_id, action, old_data, new_data, changed_by, changed_at, ip_address)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)
		RETURNING id`

	log.ChangedAt = time.Now()

	var id int64
	err := r.QueryRowContext(ctx, query,
		log.TableName, log.RecordID, log.Action, log.OldData, log.NewData,
		log.ChangedBy, log.ChangedAt, log.IPAddress,
	).Scan(&id)
	if err != nil {
		return WrapError(err, "audit log create")
	}

	log.ID = uint(id)

	return nil
}

// CreateAuthEvent inserts a new authentication audit log entry
// Note: This requires a separate table auth_audit_log to be created via migration
func (r *AuditLogRepositoryImpl) CreateAuthEvent(ctx context.Context, log *entity.AuthAuditLog) error {
	// For now, we'll use the general audit_log table with a special format
	// In production, you should create a dedicated auth_audit_log table
	query := `INSERT INTO audit_log (table_name, record_id, action, new_data, changed_at, ip_address)
		VALUES (?, ?, ?, ?, ?, ?)
		RETURNING id`

	log.CreatedAt = time.Now()

	// Store auth event details as JSON in new_data field.
	// This avoids JSONB insert failures in PostgreSQL.
	payload := map[string]interface{}{
		"event_type": string(log.EventType),
		"success":    log.Success,
	}
	if log.Email != nil {
		payload["email"] = *log.Email
	}
	if log.ErrorMessage != nil {
		payload["error_message"] = *log.ErrorMessage
	}
	newDataBytes, err := json.Marshal(payload)
	if err != nil {
		return WrapError(err, "auth audit log create: marshal payload")
	}
	newData := string(newDataBytes)

	var id int64
	err = r.QueryRowContext(ctx, query,
		"auth_events",         // table_name
		0,                     // record_id (not applicable)
		string(log.EventType), // action field stores event type
		newData,               // new_data stores email
		log.CreatedAt,
		log.IPAddress,
	).Scan(&id)
	if err != nil {
		return WrapError(err, "auth audit log create")
	}
	log.ID = uint(id)

	return nil
}

// GetByTableAndRecord retrieves audit logs for a specific table and record
func (r *AuditLogRepositoryImpl) GetByTableAndRecord(ctx context.Context, tableName string, recordID uint, limit int) ([]entity.AuditLog, error) {
	query := `SELECT id, table_name, record_id, action, old_data, new_data, changed_by, changed_at, ip_address
		FROM audit_log
		WHERE table_name = ? AND record_id = ?
		ORDER BY changed_at DESC
		LIMIT ?`

	rows, err := r.QueryContext(ctx, query, tableName, recordID, limit)
	if err != nil {
		return nil, WrapError(err, "audit log get by table and record")
	}
	defer rows.Close()

	var logs []entity.AuditLog
	for rows.Next() {
		var log entity.AuditLog
		if err := rows.Scan(
			&log.ID, &log.TableName, &log.RecordID, &log.Action,
			&log.OldData, &log.NewData, &log.ChangedBy, &log.ChangedAt, &log.IPAddress,
		); err != nil {
			return nil, WrapError(err, "audit log scan")
		}
		logs = append(logs, log)
	}

	if err := rows.Err(); err != nil {
		return nil, WrapError(err, "audit log iterate")
	}

	return logs, nil
}

// GetAuthEventsByEmail retrieves authentication events for a specific email
func (r *AuditLogRepositoryImpl) GetAuthEventsByEmail(ctx context.Context, email string, limit int) ([]entity.AuthAuditLog, error) {
	query := `SELECT id, action, new_data, changed_at, ip_address
		FROM audit_log
		WHERE table_name = 'auth_events' AND new_data::text LIKE ?
		ORDER BY changed_at DESC
		LIMIT ?`

	rows, err := r.QueryContext(ctx, query, "%"+email+"%", limit)
	if err != nil {
		return nil, WrapError(err, "auth events get by email")
	}
	defer rows.Close()

	var events []entity.AuthAuditLog
	for rows.Next() {
		var event entity.AuthAuditLog
		var eventType string
		var emailStr string

		if err := rows.Scan(
			&event.ID, &eventType, &emailStr, &event.CreatedAt, &event.IPAddress,
		); err != nil {
			return nil, WrapError(err, "auth events scan")
		}

		event.EventType = entity.AuthEventType(eventType)
		if parsedEmail := extractEmailFromAuditData(emailStr); parsedEmail != "" {
			event.Email = &parsedEmail
		}
		event.Success = true // Assume success if logged

		events = append(events, event)
	}

	if err := rows.Err(); err != nil {
		return nil, WrapError(err, "auth events iterate")
	}

	return events, nil
}

// GetAuthEventsByIP retrieves authentication events for a specific IP address
func (r *AuditLogRepositoryImpl) GetAuthEventsByIP(ctx context.Context, ipAddress string, limit int) ([]entity.AuthAuditLog, error) {
	query := `SELECT id, action, new_data, changed_at, ip_address
		FROM audit_log
		WHERE table_name = 'auth_events' AND ip_address = ?
		ORDER BY changed_at DESC
		LIMIT ?`

	rows, err := r.QueryContext(ctx, query, ipAddress, limit)
	if err != nil {
		return nil, WrapError(err, "auth events get by ip")
	}
	defer rows.Close()

	var events []entity.AuthAuditLog
	for rows.Next() {
		var event entity.AuthAuditLog
		var eventType string
		var emailStr sql.NullString

		if err := rows.Scan(
			&event.ID, &eventType, &emailStr, &event.CreatedAt, &event.IPAddress,
		); err != nil {
			return nil, WrapError(err, "auth events scan")
		}

		event.EventType = entity.AuthEventType(eventType)
		if emailStr.Valid {
			parsed := extractEmailFromAuditData(emailStr.String)
			if parsed != "" {
				event.Email = &parsed
			}
		}
		event.Success = true

		events = append(events, event)
	}

	if err := rows.Err(); err != nil {
		return nil, WrapError(err, "auth events iterate")
	}

	return events, nil
}

// GetRecentAuthEvents retrieves recent authentication events
func (r *AuditLogRepositoryImpl) GetRecentAuthEvents(ctx context.Context, limit int) ([]entity.AuthAuditLog, error) {
	query := `SELECT id, action, new_data, changed_at, ip_address
		FROM audit_log
		WHERE table_name = 'auth_events'
		ORDER BY changed_at DESC
		LIMIT ?`

	rows, err := r.QueryContext(ctx, query, limit)
	if err != nil {
		return nil, WrapError(err, "auth events get recent")
	}
	defer rows.Close()

	var events []entity.AuthAuditLog
	for rows.Next() {
		var event entity.AuthAuditLog
		var eventType string
		var emailStr sql.NullString

		if err := rows.Scan(
			&event.ID, &eventType, &emailStr, &event.CreatedAt, &event.IPAddress,
		); err != nil {
			return nil, WrapError(err, "auth events scan")
		}

		event.EventType = entity.AuthEventType(eventType)
		if emailStr.Valid {
			parsed := extractEmailFromAuditData(emailStr.String)
			if parsed != "" {
				event.Email = &parsed
			}
		}
		event.Success = true

		events = append(events, event)
	}

	if err := rows.Err(); err != nil {
		return nil, WrapError(err, "auth events iterate")
	}

	return events, nil
}

// GetFailedLoginAttempts retrieves the count of failed login attempts for an email within the last N minutes
func (r *AuditLogRepositoryImpl) GetFailedLoginAttempts(ctx context.Context, email string, sinceMinutes int) (int, error) {
	query := `SELECT COUNT(*)
		FROM audit_log
		WHERE table_name = 'auth_events'
		AND action = ?
		AND new_data::text LIKE ?
		AND changed_at >= NOW() - (? * INTERVAL '1 minute')`

	var count int
	err := r.QueryRowContext(ctx, query, string(entity.AuthEventLogin), "%"+email+"%", sinceMinutes).Scan(&count)
	if err != nil {
		return 0, WrapError(err, "failed login attempts count")
	}

	return count, nil
}

// extractEmailFromAuditData tries to recover an email from JSON payloads or legacy plain strings.
func extractEmailFromAuditData(raw string) string {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return ""
	}

	// Legacy plain value (or JSON-quoted string)
	unquoted := strings.Trim(raw, "\"")
	if !strings.HasPrefix(raw, "{") {
		return unquoted
	}

	// JSON object payload
	var payload map[string]interface{}
	if err := json.Unmarshal([]byte(raw), &payload); err != nil {
		// Best effort fallback
		return strings.Trim(raw, "\"")
	}

	if v, ok := payload["email"]; ok {
		if email, ok := v.(string); ok {
			return email
		}
	}

	return ""
}
