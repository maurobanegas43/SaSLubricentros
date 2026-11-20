package entity

import "time"

// RefreshToken represents a JWT refresh token stored in the database.
type RefreshToken struct {
	ID        uint       `json:"-" db:"id"`
	UserID    uint       `json:"user_id" db:"user_id" validate:"required"`
	TokenHash string     `json:"-" db:"token_hash"`
	ExpiresAt time.Time  `json:"expires_at" db:"expires_at" validate:"required"`
	CreatedAt time.Time  `json:"created_at" db:"created_at"`
	RevokedAt *time.Time `json:"revoked_at,omitempty" db:"revoked_at"`
	IPAddress string     `json:"ip_address,omitempty" db:"ip_address" validate:"omitempty,max=45"`
	UserAgent string     `json:"user_agent,omitempty" db:"user_agent"`
}
