package repository

import (
	"context"
	"time"

	"github.com/lubricentros/api/internal/domain/entity"
)

// AppointmentRepository defines the contract for appointment persistence operations.
type AppointmentRepository interface {
	Create(ctx context.Context, appointment *entity.Appointment) error
	GetByID(ctx context.Context, id uint) (*entity.Appointment, error)
	GetByUserID(ctx context.Context, userID uint, offset, limit int) ([]entity.Appointment, error)
	GetByVehicleID(ctx context.Context, vehicleID uint) ([]entity.Appointment, error)
	GetByDateRange(ctx context.Context, start, end time.Time) ([]entity.Appointment, error)
	UpdateStatus(ctx context.Context, id uint, status entity.AppointmentStatus) error
	Update(ctx context.Context, appointment *entity.Appointment) error
	Delete(ctx context.Context, id uint) error
	CountByUserID(ctx context.Context, userID uint) (int64, error)
}
