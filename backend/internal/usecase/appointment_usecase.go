package usecase

import (
	"context"
	"errors"
	"fmt"
	"log"
	"time"

	"github.com/lubricentros/api/internal/domain/entity"
	domainrepo "github.com/lubricentros/api/internal/domain/repository"
	"github.com/lubricentros/api/internal/repository"
)

// AppointmentUsecase handles appointment business logic.
type AppointmentUsecase struct {
	appointmentRepo domainrepo.AppointmentRepository
	vehicleRepo     domainrepo.VehicleRepository
}

// NewAppointmentUsecase creates a new appointment usecase.
func NewAppointmentUsecase(
	appointmentRepo domainrepo.AppointmentRepository,
	vehicleRepo domainrepo.VehicleRepository,
) *AppointmentUsecase {
	return &AppointmentUsecase{
		appointmentRepo: appointmentRepo,
		vehicleRepo:     vehicleRepo,
	}
}

// CreateAppointmentInput holds the input for creating an appointment.
type CreateAppointmentInput struct {
	UserID        uint
	VehicleID     uint
	Fecha         time.Time
	TipoService   entity.AppointmentType
	Observaciones string
}

// CreateAppointment validates vehicle ownership, checks slot availability,
// checks for overlaps, and creates the appointment.
func (uc *AppointmentUsecase) CreateAppointment(ctx context.Context, input CreateAppointmentInput) (*entity.Appointment, error) {
	log.Printf("[DEBUG] CreateAppointment input: vehicle_id=%d, fecha=%v, tipo_service=%s", input.VehicleID, input.Fecha, input.TipoService)

	// Validate vehicle ownership
	vehicle, err := uc.vehicleRepo.GetByID(ctx, input.VehicleID)
	if err != nil {
		log.Printf("[ERROR] CreateAppointment: vehicle not found: %v", err)
		return nil, fmt.Errorf("create appointment: vehicle not found: %w", err)
	}
	log.Printf("[DEBUG] Vehicle found: id=%d, marca=%s", vehicle.ID, vehicle.Marca)

	// Calculate slot end (30 minutes)
	slotEnd := input.Fecha.Add(30 * time.Minute)

	// Check for overlaps with existing appointments on the same date
	hasOverlap, err := uc.checkOverlap(ctx, input.Fecha, slotEnd)
	if err != nil {
		return nil, fmt.Errorf("create appointment: check overlap: %w", err)
	}
	if hasOverlap {
		return nil, repository.ErrConflict
	}

	appointment := &entity.Appointment{
		UserID:        input.UserID,
		VehicleID:     input.VehicleID,
		Fecha:         input.Fecha,
		SlotEnd:       slotEnd,
		TipoService:   input.TipoService,
		Status:        entity.StatusPending,
		Observaciones: input.Observaciones,
	}

	log.Printf("[DEBUG] About to create appointment: %+v", appointment)

	if err := uc.appointmentRepo.Create(ctx, appointment); err != nil {
		log.Printf("[ERROR] Create appointment failed: %v", err)
		return nil, fmt.Errorf("create appointment: %w", err)
	}

	return appointment, nil
}

// GetAppointmentByID retrieves an appointment and checks ownership.
func (uc *AppointmentUsecase) GetAppointmentByID(ctx context.Context, appointmentID uint, userID uint) (*entity.Appointment, error) {
	appointment, err := uc.appointmentRepo.GetByID(ctx, appointmentID)
	if err != nil {
		return nil, fmt.Errorf("get appointment by id: %w", err)
	}

	if appointment.UserID != userID {
		return nil, errors.New("appointment does not belong to user")
	}

	return appointment, nil
}

// ListByUser returns a paginated list of appointments for a user.
func (uc *AppointmentUsecase) ListByUser(ctx context.Context, userID uint, offset, limit int) ([]entity.Appointment, error) {
	appointments, err := uc.appointmentRepo.GetByUserID(ctx, userID, offset, limit)
	if err != nil {
		return nil, fmt.Errorf("list appointments: %w", err)
	}

	return appointments, nil
}

// ListByVehicle returns all appointments for a specific vehicle.
func (uc *AppointmentUsecase) ListByVehicle(ctx context.Context, vehicleID uint, userID uint) ([]entity.Appointment, error) {
	// Verify vehicle ownership
	vehicle, err := uc.vehicleRepo.GetByID(ctx, vehicleID)
	if err != nil {
		return nil, fmt.Errorf("list appointments by vehicle: vehicle not found: %w", err)
	}

	if vehicle.UserID != userID {
		return nil, errors.New("vehicle does not belong to user")
	}

	appointments, err := uc.appointmentRepo.GetByVehicleID(ctx, vehicleID)
	if err != nil {
		return nil, fmt.Errorf("list appointments by vehicle: %w", err)
	}

	return appointments, nil
}

// UpdateAppointmentInput holds the input for updating an appointment.
type UpdateAppointmentInput struct {
	AppointmentID uint
	UserID        uint
	Fecha         *time.Time
	TipoService   *entity.AppointmentType
	Status        *entity.AppointmentStatus
	Observaciones *string
}

// UpdateAppointment checks ownership, validates status transition,
// checks new slot availability, and updates the appointment.
func (uc *AppointmentUsecase) UpdateAppointment(ctx context.Context, input UpdateAppointmentInput) (*entity.Appointment, error) {
	// Check ownership
	appointment, err := uc.GetAppointmentByID(ctx, input.AppointmentID, input.UserID)
	if err != nil {
		return nil, fmt.Errorf("update appointment: %w", err)
	}

	// Apply updates
	if input.Fecha != nil {
		appointment.Fecha = *input.Fecha
		appointment.SlotEnd = input.Fecha.Add(30 * time.Minute)

		// Check new slot availability
		hasOverlap, err := uc.checkOverlap(ctx, appointment.Fecha, appointment.SlotEnd)
		if err != nil {
			return nil, fmt.Errorf("update appointment: check overlap: %w", err)
		}
		if hasOverlap {
			return nil, repository.ErrConflict
		}
	}

	if input.TipoService != nil {
		appointment.TipoService = *input.TipoService
	}

	if input.Status != nil {
		// Validate status transition
		if !isValidStatusTransition(appointment.Status, *input.Status) {
			return nil, fmt.Errorf("invalid status transition from %s to %s: %w",
				appointment.Status, *input.Status, repository.ErrInvalidInput)
		}
		appointment.Status = *input.Status
	}

	if input.Observaciones != nil {
		appointment.Observaciones = *input.Observaciones
	}

	if err := uc.appointmentRepo.Update(ctx, appointment); err != nil {
		return nil, fmt.Errorf("update appointment: %w", err)
	}

	return appointment, nil
}

// DeleteAppointment checks ownership and deletes the appointment.
// Only allows deletion if status is pending or confirmed.
func (uc *AppointmentUsecase) DeleteAppointment(ctx context.Context, appointmentID uint, userID uint) error {
	// Check ownership
	appointment, err := uc.GetAppointmentByID(ctx, appointmentID, userID)
	if err != nil {
		return fmt.Errorf("delete appointment: %w", err)
	}

	// Only allow deletion if pending or confirmed
	if appointment.Status != entity.StatusPending && appointment.Status != entity.StatusConfirmed {
		return errors.New("can only delete appointments with pending or confirmed status")
	}

	if err := uc.appointmentRepo.Delete(ctx, appointmentID); err != nil {
		return fmt.Errorf("delete appointment: %w", err)
	}

	return nil
}

// GetAvailableSlots returns available 30-minute slots for a given date.
// Slots are between 08:00 and 18:00, excluding booked appointments.
func (uc *AppointmentUsecase) GetAvailableSlots(ctx context.Context, date time.Time) ([]time.Time, error) {
	// Start of day at 08:00
	startOfDay := time.Date(date.Year(), date.Month(), date.Day(), 8, 0, 0, 0, date.Location())
	// End of day at 18:00
	endOfDay := time.Date(date.Year(), date.Month(), date.Day(), 18, 0, 0, 0, date.Location())

	// Get all appointments for the date range
	appointments, err := uc.appointmentRepo.GetByDateRange(ctx, startOfDay, endOfDay)
	if err != nil {
		return nil, fmt.Errorf("get available slots: %w", err)
	}

	// Generate all possible 30-minute slots
	var allSlots []time.Time
	for t := startOfDay; t.Before(endOfDay); t = t.Add(30 * time.Minute) {
		allSlots = append(allSlots, t)
	}

	// Filter out booked slots
	booked := make(map[time.Time]bool)
	for _, appt := range appointments {
		// Skip cancelled appointments
		if appt.Status == entity.StatusCancelled {
			continue
		}
		// Mark the slot and any overlapping slots as booked
		for t := appt.Fecha; t.Before(appt.SlotEnd); t = t.Add(30 * time.Minute) {
			booked[t] = true
		}
	}

	// Return only available slots
	var available []time.Time
	for _, slot := range allSlots {
		if !booked[slot] {
			available = append(available, slot)
		}
	}

	return available, nil
}

// checkOverlap checks if a time slot conflicts with existing appointments.
func (uc *AppointmentUsecase) checkOverlap(ctx context.Context, start, end time.Time) (bool, error) {
	// Get all appointments for the date
	dayStart := time.Date(start.Year(), start.Month(), start.Day(), 0, 0, 0, 0, start.Location())
	dayEnd := dayStart.Add(24 * time.Hour)

	appointments, err := uc.appointmentRepo.GetByDateRange(ctx, dayStart, dayEnd)
	if err != nil {
		return false, err
	}

	for _, appt := range appointments {
		// Skip cancelled appointments
		if appt.Status == entity.StatusCancelled {
			continue
		}
		// Check for overlap: two intervals overlap if one starts before the other ends
		if start.Before(appt.SlotEnd) && end.After(appt.Fecha) {
			return true, nil
		}
	}

	return false, nil
}

// isValidStatusTransition checks if a status transition is allowed.
// Allowed transitions:
//   - pending → confirmed, pending → cancelled
//   - confirmed → in_progress, confirmed → cancelled
//   - in_progress → completed, in_progress → cancelled
//   - completed → (no transitions)
//   - cancelled → (no transitions)
//   - no_show → (no transitions)
func isValidStatusTransition(from, to entity.AppointmentStatus) bool {
	switch from {
	case entity.StatusPending:
		return to == entity.StatusConfirmed || to == entity.StatusCancelled
	case entity.StatusConfirmed:
		return to == entity.StatusInProgress || to == entity.StatusCancelled
	case entity.StatusInProgress:
		return to == entity.StatusCompleted || to == entity.StatusCancelled
	default:
		return false
	}
}
