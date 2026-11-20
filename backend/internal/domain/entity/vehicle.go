package entity

import "time"

// Vehicle represents a registered vehicle owned by a user.
type Vehicle struct {
	ID        uint      `json:"id" db:"id"`
	UserID    uint      `json:"user_id" db:"user_id" validate:"required"`
	Patente   string    `json:"patente,omitempty" db:"patente" validate:"omitempty,max=10"`
	Marca     string    `json:"marca" validate:"required,max=100"`
	Modelo    string    `json:"modelo" validate:"required,max=100"`
	Anio      int16     `json:"anio" validate:"required"`
	Motor     string    `json:"motor,omitempty" db:"motor" validate:"omitempty,max=100"`
	KmActual  uint      `json:"km_actual" db:"km_actual"`
	Color     string    `json:"color,omitempty" db:"color" validate:"omitempty,max=50"`
	ImageURL  *string   `json:"image_url,omitempty" db:"image_url"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}
