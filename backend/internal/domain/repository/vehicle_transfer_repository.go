package repository

import (
	"context"

	"github.com/lubricentros/api/internal/domain/entity"
)

// VehicleTransferRepository defines the contract for vehicle transfer persistence.
type VehicleTransferRepository interface {
	Create(ctx context.Context, transfer *entity.VehicleTransfer) error
	GetByID(ctx context.Context, id uint) (*entity.VehicleTransfer, error)
	GetByVehicleID(ctx context.Context, vehicleID uint) ([]entity.VehicleTransfer, error)
	GetPendingByVehicleID(ctx context.Context, vehicleID uint) (*entity.VehicleTransfer, error)
	UpdateStatus(ctx context.Context, id uint, status string) error
}
