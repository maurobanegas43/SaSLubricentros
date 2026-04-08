package entity

import "time"

// ServiceAddendum records corrections to immutable service records.
type ServiceAddendum struct {
	ID        uint      `json:"id" db:"id"`
	ServiceID uint      `json:"service_id" db:"service_id" validate:"required"`
	Reason    string    `json:"reason" db:"description" validate:"required"`
	CreatedBy uint      `json:"created_by" db:"created_by" validate:"required"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}
