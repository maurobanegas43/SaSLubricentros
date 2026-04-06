package usecase

import (
	"context"
	"errors"
	"fmt"

	"github.com/lubricentros/api/internal/domain/entity"
	domainrepo "github.com/lubricentros/api/internal/domain/repository"
	"github.com/lubricentros/api/internal/repository"
)

// VehicleUsecase handles vehicle business logic.
type VehicleUsecase struct {
	vehicleRepo  domainrepo.VehicleRepository
	serviceRepo  domainrepo.ServiceRecordRepository
	transferRepo domainrepo.VehicleTransferRepository
	userRepo     domainrepo.UserRepository
}

// NewVehicleUsecase creates a new vehicle usecase.
func NewVehicleUsecase(
	vehicleRepo domainrepo.VehicleRepository,
	serviceRepo domainrepo.ServiceRecordRepository,
	transferRepo domainrepo.VehicleTransferRepository,
	userRepo domainrepo.UserRepository,
) *VehicleUsecase {
	return &VehicleUsecase{
		vehicleRepo:  vehicleRepo,
		serviceRepo:  serviceRepo,
		transferRepo: transferRepo,
		userRepo:     userRepo,
	}
}

// CreateVehicleInput holds the input for creating a vehicle.
type CreateVehicleInput struct {
	UserID   uint
	Patente  string
	Marca    string
	Modelo   string
	Anio     int16
	Motor    string
	KmActual uint
	Color    string
}

// CreateVehicle validates input and creates a new vehicle for the user.
func (uc *VehicleUsecase) CreateVehicle(ctx context.Context, input CreateVehicleInput) (*entity.Vehicle, error) {
	if input.Marca == "" || input.Modelo == "" {
		return nil, repository.ErrInvalidInput
	}
	if input.Anio < 1900 || input.Anio > 2099 {
		return nil, repository.ErrInvalidInput
	}

	vehicle := &entity.Vehicle{
		UserID:   input.UserID,
		Patente:  input.Patente,
		Marca:    input.Marca,
		Modelo:   input.Modelo,
		Anio:     input.Anio,
		Motor:    input.Motor,
		KmActual: input.KmActual,
		Color:    input.Color,
	}

	if err := uc.vehicleRepo.Create(ctx, vehicle); err != nil {
		return nil, fmt.Errorf("create vehicle: %w", err)
	}

	return vehicle, nil
}

// GetVehicleByID retrieves a vehicle and checks ownership.
func (uc *VehicleUsecase) GetVehicleByID(ctx context.Context, vehicleID uint, userID uint) (*entity.Vehicle, error) {
	vehicle, err := uc.vehicleRepo.GetByID(ctx, vehicleID)
	if err != nil {
		return nil, fmt.Errorf("get vehicle by id: %w", err)
	}

	if vehicle.UserID != userID {
		return nil, errors.New("vehicle does not belong to user")
	}

	return vehicle, nil
}

// ListByUser returns a paginated list of vehicles for a user.
func (uc *VehicleUsecase) ListByUser(ctx context.Context, userID uint, offset, limit int) ([]entity.Vehicle, error) {
	vehicles, err := uc.vehicleRepo.GetByUserID(ctx, userID, offset, limit)
	if err != nil {
		return nil, fmt.Errorf("list vehicles: %w", err)
	}

	return vehicles, nil
}

// CountByUser returns the total number of vehicles for a user.
func (uc *VehicleUsecase) CountByUser(ctx context.Context, userID uint) (int64, error) {
	return uc.vehicleRepo.CountByUserID(ctx, userID)
}

// UpdateVehicleInput holds the input for updating a vehicle.
type UpdateVehicleInput struct {
	VehicleID uint
	UserID    uint
	Patente   *string
	Marca     *string
	Modelo    *string
	Anio      *int16
	Motor     *string
	KmActual  *uint
	Color     *string
}

// UpdateVehicle checks ownership, validates, and updates the vehicle.
func (uc *VehicleUsecase) UpdateVehicle(ctx context.Context, input UpdateVehicleInput) (*entity.Vehicle, error) {
	// Check ownership
	vehicle, err := uc.GetVehicleByID(ctx, input.VehicleID, input.UserID)
	if err != nil {
		return nil, fmt.Errorf("update vehicle: %w", err)
	}

	// Apply updates
	if input.Patente != nil {
		vehicle.Patente = *input.Patente
	}
	if input.Marca != nil {
		if *input.Marca == "" {
			return nil, repository.ErrInvalidInput
		}
		vehicle.Marca = *input.Marca
	}
	if input.Modelo != nil {
		if *input.Modelo == "" {
			return nil, repository.ErrInvalidInput
		}
		vehicle.Modelo = *input.Modelo
	}
	if input.Anio != nil {
		if *input.Anio < 1900 || *input.Anio > 2099 {
			return nil, repository.ErrInvalidInput
		}
		vehicle.Anio = *input.Anio
	}
	if input.Motor != nil {
		vehicle.Motor = *input.Motor
	}
	if input.KmActual != nil {
		// Validate km doesn't decrease
		if *input.KmActual < vehicle.KmActual {
			return nil, errors.New("km cannot decrease")
		}
		vehicle.KmActual = *input.KmActual
	}
	if input.Color != nil {
		vehicle.Color = *input.Color
	}

	if err := uc.vehicleRepo.Update(ctx, vehicle); err != nil {
		return nil, fmt.Errorf("update vehicle: %w", err)
	}

	return vehicle, nil
}

// DeleteVehicle checks ownership and deletes the vehicle.
func (uc *VehicleUsecase) DeleteVehicle(ctx context.Context, vehicleID uint, userID uint) error {
	// Check ownership
	_, err := uc.GetVehicleByID(ctx, vehicleID, userID)
	if err != nil {
		return fmt.Errorf("delete vehicle: %w", err)
	}

	if err := uc.vehicleRepo.Delete(ctx, vehicleID); err != nil {
		return fmt.Errorf("delete vehicle: %w", err)
	}

	return nil
}

// VehicleReport contains a comprehensive vehicle report.
type VehicleReport struct {
	Vehicle       *entity.Vehicle
	LastService   *entity.ServiceRecord
	NextServiceKm *uint
	ServiceCount  int64
}

// GetVehicleReport generates a comprehensive report for a vehicle.
func (uc *VehicleUsecase) GetVehicleReport(ctx context.Context, vehicleID uint, userID uint) (*VehicleReport, error) {
	// Check ownership
	vehicle, err := uc.GetVehicleByID(ctx, vehicleID, userID)
	if err != nil {
		return nil, fmt.Errorf("get vehicle report: %w", err)
	}

	// Get last service
	lastService, err := uc.serviceRepo.GetLastByVehicleID(ctx, vehicleID)
	if err != nil && !errors.Is(err, repository.ErrNotFound) {
		return nil, fmt.Errorf("get vehicle report: get last service: %w", err)
	}

	// Get service count
	serviceCount, err := uc.serviceRepo.CountByVehicleID(ctx, vehicleID)
	if err != nil {
		return nil, fmt.Errorf("get vehicle report: count services: %w", err)
	}

	report := &VehicleReport{
		Vehicle:      vehicle,
		ServiceCount: serviceCount,
	}

	if lastService != nil && lastService.ProximoServiceKm != nil {
		report.NextServiceKm = lastService.ProximoServiceKm
		report.LastService = lastService
	}

	return report, nil
}

// TransferOwnershipInput holds the input for transferring vehicle ownership.
type TransferOwnershipInput struct {
	VehicleID   uint
	FromUserID  uint
	ToUserID    uint
	Reason      string
	InitiatedBy uint
}

// TransferOwnership transfers vehicle ownership from one user to another.
func (uc *VehicleUsecase) TransferOwnership(ctx context.Context, input TransferOwnershipInput) (*entity.VehicleTransfer, error) {
	// Check if vehicle exists and belongs to current user
	vehicle, err := uc.vehicleRepo.GetByID(ctx, input.VehicleID)
	if err != nil {
		return nil, fmt.Errorf("transfer ownership: vehicle not found: %w", err)
	}

	// Verify ownership
	if vehicle.UserID != input.FromUserID {
		return nil, errors.New("vehicle does not belong to user")
	}

	// Check if target user exists
	_, err = uc.userRepo.GetByID(ctx, input.ToUserID)
	if err != nil {
		return nil, errors.New("target user does not exist")
	}

	// Prevent self-transfer
	if input.FromUserID == input.ToUserID {
		return nil, errors.New("cannot transfer to same user")
	}

	// Update vehicle owner
	vehicle.UserID = input.ToUserID
	if err := uc.vehicleRepo.Update(ctx, vehicle); err != nil {
		return nil, fmt.Errorf("transfer ownership: update vehicle: %w", err)
	}

	// Create transfer record
	transfer := &entity.VehicleTransfer{
		VehicleID:   input.VehicleID,
		FromUserID:  &input.FromUserID,
		ToUserID:    input.ToUserID,
		Reason:      &input.Reason,
		InitiatedBy: &input.InitiatedBy,
		Status:      "completed",
	}

	if err := uc.transferRepo.Create(ctx, transfer); err != nil {
		return nil, fmt.Errorf("transfer ownership: create record: %w", err)
	}

	return transfer, nil
}

// GetTransferHistory returns the ownership history for a vehicle.
func (uc *VehicleUsecase) GetTransferHistory(ctx context.Context, vehicleID uint, userID uint) ([]entity.VehicleTransfer, error) {
	// Check ownership
	_, err := uc.GetVehicleByID(ctx, vehicleID, userID)
	if err != nil {
		return nil, fmt.Errorf("get transfer history: %w", err)
	}

	transfers, err := uc.transferRepo.GetByVehicleID(ctx, vehicleID)
	if err != nil {
		return nil, fmt.Errorf("get transfer history: %w", err)
	}

	return transfers, nil
}
