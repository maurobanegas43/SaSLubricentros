package entity

import "time"

// ServiceAddendum records corrections to immutable service records.
type ServiceAddendum struct {
	ID        uint      `json:"id" db:"id"`
	ServiceID uint      `json:"service_id" db:"service_id" validate:"required"`
	FieldName string    `json:"field_name" db:"field_name" validate:"required,max=100"`
	OldValue  string    `json:"old_value,omitempty" db:"old_value"`
	NewValue  string    `json:"new_value" db:"new_value" validate:"required"`
	Reason    string    `json:"reason" db:"reason" validate:"required"`
	CreatedBy uint      `json:"created_by" db:"created_by" validate:"required"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}
