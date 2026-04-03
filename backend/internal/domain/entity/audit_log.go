package entity

import "time"

// AuditAction represents the type of database action logged.
type AuditAction string

const (
	ActionInsert AuditAction = "INSERT"
	ActionUpdate AuditAction = "UPDATE"
	ActionDelete AuditAction = "DELETE"
)

func (a AuditAction) String() string {
	return string(a)
}

// AuditLog records database changes for compliance and debugging.
type AuditLog struct {
	ID        uint        `json:"id" db:"id"`
	TableName string      `json:"table_name" db:"table_name" validate:"required,max=100"`
	RecordID  uint        `json:"record_id" db:"record_id" validate:"required"`
	Action    AuditAction `json:"action" db:"action" validate:"required"`
	OldData   string      `json:"old_data,omitempty" db:"old_data"`
	NewData   string      `json:"new_data,omitempty" db:"new_data"`
	ChangedBy *uint       `json:"changed_by,omitempty" db:"changed_by"`
	ChangedAt time.Time   `json:"changed_at" db:"changed_at"`
	IPAddress string      `json:"ip_address,omitempty" db:"ip_address" validate:"omitempty,max=45"`
}
