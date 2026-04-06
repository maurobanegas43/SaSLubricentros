package repository

import (
	"context"

	"github.com/lubricentros/api/internal/domain/entity"
)

// PasswordResetTokenRepository defines the interface for password reset token data access
type PasswordResetTokenRepository interface {
	// Create creates a new password reset token
	Create(ctx context.Context, token *entity.PasswordResetToken) error

	// GetByToken retrieves a password reset token by its token string
	GetByToken(ctx context.Context, token string) (*entity.PasswordResetToken, error)

	// Delete deletes a password reset token
	Delete(ctx context.Context, token string) error

	// DeleteByUserID deletes all password reset tokens for a user
	DeleteByUserID(ctx context.Context, userID uint) error

	// DeleteExpired deletes all expired password reset tokens
	DeleteExpired(ctx context.Context) error
}
