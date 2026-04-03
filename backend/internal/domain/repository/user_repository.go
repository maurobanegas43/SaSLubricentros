package repository

import (
	"context"

	"github.com/lubricentros/api/internal/domain/entity"
)

// UserRepository defines the contract for user persistence operations.
type UserRepository interface {
	Create(ctx context.Context, user *entity.User) error
	GetByID(ctx context.Context, id uint) (*entity.User, error)
	GetByEmail(ctx context.Context, email string) (*entity.User, error)
	Update(ctx context.Context, user *entity.User) error
	Deactivate(ctx context.Context, id uint) error
	List(ctx context.Context, offset, limit int) ([]entity.User, error)
	Count(ctx context.Context) (int64, error)
}
