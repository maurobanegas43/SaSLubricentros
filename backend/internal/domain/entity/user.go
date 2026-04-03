package entity

import "time"

// Role represents a user role in the system.
type Role string

const (
	RoleCustomer Role = "customer"
	RoleAdmin    Role = "admin"
)

func (r Role) String() string {
	return string(r)
}

// User represents a system user (customers and admins).
type User struct {
	ID           uint      `json:"id" db:"id"`
	Email        string    `json:"email" validate:"required,email"`
	PasswordHash string    `json:"-" db:"password_hash"`
	Name         string    `json:"name" validate:"required,min=2,max=255"`
	Phone        string    `json:"phone,omitempty" validate:"omitempty,max=20"`
	Role         Role      `json:"role" db:"role"`
	IsActive     bool      `json:"is_active" db:"is_active"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time `json:"updated_at" db:"updated_at"`
}
