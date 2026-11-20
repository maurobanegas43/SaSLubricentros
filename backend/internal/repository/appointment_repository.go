package repository

import (
	"context"
	"database/sql"
	"log"
	"time"

	"github.com/lubricentros/api/internal/domain/entity"
)

// AppointmentRepositoryImpl is the MariaDB implementation of the AppointmentRepository interface.
type AppointmentRepositoryImpl struct {
	*BaseRepository
}

// NewAppointmentRepository creates a new appointment repository.
func NewAppointmentRepository(db *sql.DB) *AppointmentRepositoryImpl {
	return &AppointmentRepositoryImpl{
		BaseRepository: NewBaseRepository(db),
	}
}

// Create inserts a new appointment into the database.
func (r *AppointmentRepositoryImpl) Create(ctx context.Context, appointment *entity.Appointment) error {
	query := `INSERT INTO appointments (user_id, vehicle_id, fecha, slot_end, tipo_service, status, observaciones, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
		RETURNING id`

	now := time.Now()
	appointment.CreatedAt = now
	appointment.UpdatedAt = now

	var id int64
	err := r.QueryRowContext(ctx, query,
		appointment.UserID, appointment.VehicleID,
		appointment.Fecha, appointment.SlotEnd,
		appointment.TipoService, appointment.Status,
		appointment.Observaciones, appointment.CreatedAt, appointment.UpdatedAt,
	).Scan(&id)
	if err != nil {
		log.Printf("[ERROR] appointment create: %v", err)
		return WrapError(err, "appointment create")
	}

	appointment.ID = uint(id)

	return nil
}

// GetByID retrieves an appointment by its ID.
func (r *AppointmentRepositoryImpl) GetByID(ctx context.Context, id uint) (*entity.Appointment, error) {
	query := `SELECT id, user_id, vehicle_id, fecha, slot_end, tipo_service, status, observaciones, created_at, updated_at
		FROM appointments WHERE id = ?`

	var a entity.Appointment
	err := r.QueryRowContext(ctx, query, id).Scan(
		&a.ID, &a.UserID, &a.VehicleID, &a.Fecha, &a.SlotEnd,
		&a.TipoService, &a.Status, &a.Observaciones,
		&a.CreatedAt, &a.UpdatedAt,
	)
	if err != nil {
		return nil, WrapError(err, "appointment get by id")
	}

	return &a, nil
}

// GetByUserID retrieves all appointments for a user with pagination.
func (r *AppointmentRepositoryImpl) GetByUserID(ctx context.Context, userID uint, offset, limit int) ([]entity.Appointment, error) {
	query := `SELECT id, user_id, vehicle_id, fecha, slot_end, tipo_service, status, observaciones, created_at, updated_at
		FROM appointments WHERE user_id = ? ORDER BY fecha DESC LIMIT ? OFFSET ?`

	rows, err := r.QueryContext(ctx, query, userID, limit, offset)
	if err != nil {
		return nil, WrapError(err, "appointment get by user id")
	}
	defer rows.Close()

	var appointments []entity.Appointment
	for rows.Next() {
		var a entity.Appointment
		if err := rows.Scan(
			&a.ID, &a.UserID, &a.VehicleID, &a.Fecha, &a.SlotEnd,
			&a.TipoService, &a.Status, &a.Observaciones,
			&a.CreatedAt, &a.UpdatedAt,
		); err != nil {
			return nil, WrapError(err, "appointment get by user id: scan")
		}
		appointments = append(appointments, a)
	}

	if err := rows.Err(); err != nil {
		return nil, WrapError(err, "appointment get by user id: iterate")
	}

	return appointments, nil
}

// GetByVehicleID retrieves all appointments for a vehicle.
func (r *AppointmentRepositoryImpl) GetByVehicleID(ctx context.Context, vehicleID uint) ([]entity.Appointment, error) {
	query := `SELECT id, user_id, vehicle_id, fecha, slot_end, tipo_service, status, observaciones, created_at, updated_at
		FROM appointments WHERE vehicle_id = ? ORDER BY fecha DESC`

	rows, err := r.QueryContext(ctx, query, vehicleID)
	if err != nil {
		return nil, WrapError(err, "appointment get by vehicle id")
	}
	defer rows.Close()

	var appointments []entity.Appointment
	for rows.Next() {
		var a entity.Appointment
		if err := rows.Scan(
			&a.ID, &a.UserID, &a.VehicleID, &a.Fecha, &a.SlotEnd,
			&a.TipoService, &a.Status, &a.Observaciones,
			&a.CreatedAt, &a.UpdatedAt,
		); err != nil {
			return nil, WrapError(err, "appointment get by vehicle id: scan")
		}
		appointments = append(appointments, a)
	}

	if err := rows.Err(); err != nil {
		return nil, WrapError(err, "appointment get by vehicle id: iterate")
	}

	return appointments, nil
}

// GetByDateRange retrieves all appointments within a date range.
func (r *AppointmentRepositoryImpl) GetByDateRange(ctx context.Context, start, end time.Time) ([]entity.Appointment, error) {
	query := `SELECT id, user_id, vehicle_id, fecha, slot_end, tipo_service, status, observaciones, created_at, updated_at
		FROM appointments WHERE fecha >= ? AND fecha < ? ORDER BY fecha ASC`

	rows, err := r.QueryContext(ctx, query, start, end)
	if err != nil {
		return nil, WrapError(err, "appointment get by date range")
	}
	defer rows.Close()

	var appointments []entity.Appointment
	for rows.Next() {
		var a entity.Appointment
		if err := rows.Scan(
			&a.ID, &a.UserID, &a.VehicleID, &a.Fecha, &a.SlotEnd,
			&a.TipoService, &a.Status, &a.Observaciones,
			&a.CreatedAt, &a.UpdatedAt,
		); err != nil {
			return nil, WrapError(err, "appointment get by date range: scan")
		}
		appointments = append(appointments, a)
	}

	if err := rows.Err(); err != nil {
		return nil, WrapError(err, "appointment get by date range: iterate")
	}

	return appointments, nil
}

// UpdateStatus updates only the status of an appointment.
func (r *AppointmentRepositoryImpl) UpdateStatus(ctx context.Context, id uint, status entity.AppointmentStatus) error {
	query := `UPDATE appointments SET status = ?, updated_at = ? WHERE id = ?`

	result, err := r.ExecContext(ctx, query, status, time.Now(), id)
	if err != nil {
		return WrapError(err, "appointment update status")
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return WrapError(err, "appointment update status: get rows affected")
	}
	if rows == 0 {
		return WrapError(sql.ErrNoRows, "appointment update status")
	}

	return nil
}

// Update updates an existing appointment's information.
func (r *AppointmentRepositoryImpl) Update(ctx context.Context, appointment *entity.Appointment) error {
	query := `UPDATE appointments SET fecha = ?, slot_end = ?, tipo_service = ?, status = ?,
		observaciones = ?, updated_at = ? WHERE id = ?`

	appointment.UpdatedAt = time.Now()

	result, err := r.ExecContext(ctx, query,
		appointment.Fecha, appointment.SlotEnd,
		appointment.TipoService, appointment.Status,
		appointment.Observaciones, appointment.UpdatedAt, appointment.ID,
	)
	if err != nil {
		return WrapError(err, "appointment update")
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return WrapError(err, "appointment update: get rows affected")
	}
	if rows == 0 {
		return WrapError(sql.ErrNoRows, "appointment update")
	}

	return nil
}

// Delete removes an appointment from the database.
func (r *AppointmentRepositoryImpl) Delete(ctx context.Context, id uint) error {
	result, err := r.ExecContext(ctx, "DELETE FROM appointments WHERE id = ?", id)
	if err != nil {
		return WrapError(err, "appointment delete")
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return WrapError(err, "appointment delete: get rows affected")
	}
	if rows == 0 {
		return WrapError(sql.ErrNoRows, "appointment delete")
	}

	return nil
}

// CountByUserID returns the total number of appointments for a user.
func (r *AppointmentRepositoryImpl) CountByUserID(ctx context.Context, userID uint) (int64, error) {
	var count int64
	err := r.QueryRowContext(ctx, "SELECT COUNT(*) FROM appointments WHERE user_id = ?", userID).Scan(&count)
	if err != nil {
		return 0, WrapError(err, "appointment count by user id")
	}
	return count, nil
}
