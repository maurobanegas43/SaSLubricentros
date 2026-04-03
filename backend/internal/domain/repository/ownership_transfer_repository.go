package repository

import (
	"context"

	"github.com/lubricentros/api/internal/domain/entity"
)

// OwnershipTransferRepository defines the contract for ownership transfer persistence.
type OwnershipTransferRepository interface {
	Create(ctx context.Context, transfer *entity.OwnershipTransfer) error
	GetByID(ctx context.Context, id uint) (*entity.OwnershipTransfer, error)
	GetByVehicleID(ctx context.Context, vehicleID uint) ([]entity.OwnershipTransfer, error)
	GetByUserID(ctx context.Context, userID uint) ([]entity.OwnershipTransfer, error)
	UpdateStatus(ctx context.Context, id uint, status entity.TransferStatus) error
}
