package repository

import (
	"context"

	"github.com/lubricentros/api/internal/domain/entity"
)

// VehicleRepository defines the contract for vehicle persistence operations.
type VehicleRepository interface {
	Create(ctx context.Context, vehicle *entity.Vehicle) error
	GetByID(ctx context.Context, id uint) (*entity.Vehicle, error)
	GetByUserID(ctx context.Context, userID uint, offset, limit int) ([]entity.Vehicle, error)
	Update(ctx context.Context, vehicle *entity.Vehicle) error
	Delete(ctx context.Context, id uint) error
	CountByUserID(ctx context.Context, userID uint) (int64, error)
}
