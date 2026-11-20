package repository

import (
	"context"

	"github.com/lubricentros/api/internal/domain/entity"
)

// ServiceRecordRepository defines the contract for service record persistence.
type ServiceRecordRepository interface {
	Create(ctx context.Context, record *entity.ServiceRecord) error
	GetByID(ctx context.Context, id uint) (*entity.ServiceRecord, error)
	GetByVehicleID(ctx context.Context, vehicleID uint, offset, limit int) ([]entity.ServiceRecord, error)
	GetLastByVehicleID(ctx context.Context, vehicleID uint) (*entity.ServiceRecord, error)
	CountByVehicleID(ctx context.Context, vehicleID uint) (int64, error)
}

// ServiceAddendumRepository defines the contract for service addendum persistence.
type ServiceAddendumRepository interface {
	Create(ctx context.Context, addendum *entity.ServiceAddendum) error
	GetByServiceID(ctx context.Context, serviceID uint) ([]entity.ServiceAddendum, error)
}

// ServicePartUsedRepository defines the contract for service parts persistence.
type ServicePartUsedRepository interface {
	Create(ctx context.Context, part *entity.ServicePartUsed) error
	GetByServiceID(ctx context.Context, serviceID uint) ([]entity.ServicePartUsed, error)
	CreateBatch(ctx context.Context, parts []entity.ServicePartUsed) error
}
