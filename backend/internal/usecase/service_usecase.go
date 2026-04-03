package usecase

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/lubricentros/api/internal/domain/entity"
	domainrepo "github.com/lubricentros/api/internal/domain/repository"
	"github.com/lubricentros/api/internal/repository"
)

// ServiceUsecase handles service record business logic.
type ServiceUsecase struct {
	serviceRepo domainrepo.ServiceRecordRepository
	vehicleRepo domainrepo.VehicleRepository
}

// NewServiceUsecase creates a new service usecase.
func NewServiceUsecase(
	serviceRepo domainrepo.ServiceRecordRepository,
	vehicleRepo domainrepo.VehicleRepository,
) *ServiceUsecase {
	return &ServiceUsecase{
		serviceRepo: serviceRepo,
		vehicleRepo: vehicleRepo,
	}
}

// CreateServiceInput holds the input for creating a service record.
type CreateServiceInput struct {
	VehicleID        uint
	AppointmentID    *uint
	Fecha            time.Time
	Km               uint
	TipoAceite       entity.OilType
	MarcaAceite      string
	CostoTotal       *float64
	Observaciones    string
	ProximoServiceKm *uint
	CreatedBy        uint
}

// CreateService validates vehicle exists, validates km >= vehicle km,
// computes next service km if not provided, and creates the record.
func (uc *ServiceUsecase) CreateService(ctx context.Context, input CreateServiceInput) (*entity.ServiceRecord, error) {
	// Validate vehicle exists
	vehicle, err := uc.vehicleRepo.GetByID(ctx, input.VehicleID)
	if err != nil {
		return nil, fmt.Errorf("create service: vehicle not found: %w", err)
	}

	// Validate km >= vehicle km
	if input.Km < vehicle.KmActual {
		return nil, errors.New("service km cannot be less than vehicle current km")
	}

	// Compute next service km if not provided (default: +10000 km)
	proximoKm := input.ProximoServiceKm
	if proximoKm == nil {
		next := input.Km + 10000
		proximoKm = &next
	}

	record := &entity.ServiceRecord{
		VehicleID:        input.VehicleID,
		AppointmentID:    input.AppointmentID,
		Fecha:            input.Fecha,
		Km:               input.Km,
		TipoAceite:       input.TipoAceite,
		MarcaAceite:      input.MarcaAceite,
		CostoTotal:       input.CostoTotal,
		Observaciones:    input.Observaciones,
		ProximoServiceKm: proximoKm,
		CreatedBy:        input.CreatedBy,
	}

	if err := uc.serviceRepo.Create(ctx, record); err != nil {
		return nil, fmt.Errorf("create service: %w", err)
	}

	return record, nil
}

// GetServiceByVehicleID checks vehicle ownership and returns paginated service history.
func (uc *ServiceUsecase) GetServiceByVehicleID(ctx context.Context, vehicleID uint, userID uint, offset, limit int) ([]entity.ServiceRecord, error) {
	// Check vehicle ownership
	vehicle, err := uc.vehicleRepo.GetByID(ctx, vehicleID)
	if err != nil {
		return nil, fmt.Errorf("get service by vehicle: vehicle not found: %w", err)
	}

	if vehicle.UserID != userID {
		return nil, errors.New("vehicle does not belong to user")
	}

	records, err := uc.serviceRepo.GetByVehicleID(ctx, vehicleID, offset, limit)
	if err != nil {
		return nil, fmt.Errorf("get service by vehicle: %w", err)
	}

	return records, nil
}

// CountServicesByVehicle returns the total number of service records for a vehicle.
func (uc *ServiceUsecase) CountServicesByVehicle(ctx context.Context, vehicleID uint) (int64, error) {
	return uc.serviceRepo.CountByVehicleID(ctx, vehicleID)
}

// GetLastServiceByVehicleID retrieves the most recent service for a vehicle.
func (uc *ServiceUsecase) GetLastServiceByVehicleID(ctx context.Context, vehicleID uint) (*entity.ServiceRecord, error) {
	record, err := uc.serviceRepo.GetLastByVehicleID(ctx, vehicleID)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			return nil, nil
		}
		return nil, fmt.Errorf("get last service: %w", err)
	}
	return record, nil
}
