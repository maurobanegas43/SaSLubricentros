package repository

import (
	"context"

	"github.com/lubricentros/api/internal/domain/entity"
)

// RefreshTokenRepository defines the contract for refresh token persistence.
type RefreshTokenRepository interface {
	Create(ctx context.Context, token *entity.RefreshToken) error
	GetByTokenHash(ctx context.Context, tokenHash string) (*entity.RefreshToken, error)
	GetByUserID(ctx context.Context, userID uint) ([]entity.RefreshToken, error)
	Revoke(ctx context.Context, tokenHash string) error
	RevokeAllByUserID(ctx context.Context, userID uint) error
	DeleteExpired(ctx context.Context) error
}
