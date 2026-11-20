package repository

import (
	"context"
	"database/sql"
	"time"

	"github.com/lubricentros/api/internal/domain/entity"
)

// VehicleRepositoryImpl is the MariaDB implementation of the VehicleRepository interface.
type VehicleRepositoryImpl struct {
	*BaseRepository
}

// NewVehicleRepository creates a new vehicle repository.
func NewVehicleRepository(db *sql.DB) *VehicleRepositoryImpl {
	return &VehicleRepositoryImpl{
		BaseRepository: NewBaseRepository(db),
	}
}

// Create inserts a new vehicle into the database.
func (r *VehicleRepositoryImpl) Create(ctx context.Context, vehicle *entity.Vehicle) error {
	query := `INSERT INTO vehicles (user_id, patente, marca, modelo, anio, motor, km_actual, color, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		RETURNING id`

	now := time.Now()
	vehicle.CreatedAt = now
	vehicle.UpdatedAt = now

	var id int64
	err := r.QueryRowContext(ctx, query,
		vehicle.UserID, vehicle.Patente, vehicle.Marca, vehicle.Modelo,
		vehicle.Anio, vehicle.Motor, vehicle.KmActual, vehicle.Color,
		vehicle.CreatedAt, vehicle.UpdatedAt,
	).Scan(&id)
	if err != nil {
		return WrapError(err, "vehicle create")
	}

	vehicle.ID = uint(id)

	return nil
}

// GetByID retrieves a vehicle by its ID.
func (r *VehicleRepositoryImpl) GetByID(ctx context.Context, id uint) (*entity.Vehicle, error) {
	query := `SELECT id, user_id, patente, marca, modelo, anio, motor, km_actual, color, image_url, created_at, updated_at
		FROM vehicles WHERE id = ?`

	var v entity.Vehicle
	var imageURL *string
	err := r.QueryRowContext(ctx, query, id).Scan(
		&v.ID, &v.UserID, &v.Patente, &v.Marca, &v.Modelo,
		&v.Anio, &v.Motor, &v.KmActual, &v.Color, &imageURL,
		&v.CreatedAt, &v.UpdatedAt,
	)
	if err != nil {
		return nil, WrapError(err, "vehicle get by id")
	}
	if imageURL != nil {
		v.ImageURL = imageURL
	}

	return &v, nil
}

// GetByUserID retrieves all vehicles belonging to a user with pagination.
func (r *VehicleRepositoryImpl) GetByUserID(ctx context.Context, userID uint, offset, limit int) ([]entity.Vehicle, error) {
	query := `SELECT id, user_id, patente, marca, modelo, anio, motor, km_actual, color, image_url, created_at, updated_at
		FROM vehicles WHERE user_id = ? ORDER BY id DESC LIMIT ? OFFSET ?`

	rows, err := r.QueryContext(ctx, query, userID, limit, offset)
	if err != nil {
		return nil, WrapError(err, "vehicle get by user id")
	}
	defer rows.Close()

	var vehicles []entity.Vehicle
	for rows.Next() {
		var v entity.Vehicle
		var imageURL *string
		if err := rows.Scan(
			&v.ID, &v.UserID, &v.Patente, &v.Marca, &v.Modelo,
			&v.Anio, &v.Motor, &v.KmActual, &v.Color, &imageURL,
			&v.CreatedAt, &v.UpdatedAt,
		); err != nil {
			return nil, WrapError(err, "vehicle get by user id: scan")
		}
		if imageURL != nil {
			v.ImageURL = imageURL
		}
		vehicles = append(vehicles, v)
	}

	if err := rows.Err(); err != nil {
		return nil, WrapError(err, "vehicle get by user id: iterate")
	}

	return vehicles, nil
}

// Update updates an existing vehicle's information.
func (r *VehicleRepositoryImpl) Update(ctx context.Context, vehicle *entity.Vehicle) error {
	query := `UPDATE vehicles SET patente = ?, marca = ?, modelo = ?, anio = ?, motor = ?,
		km_actual = ?, color = ?, image_url = ?, updated_at = ? WHERE id = ?`

	vehicle.UpdatedAt = time.Now()

	var imageURL interface{} = nil
	if vehicle.ImageURL != nil {
		imageURL = *vehicle.ImageURL
	}

	result, err := r.ExecContext(ctx, query,
		vehicle.Patente, vehicle.Marca, vehicle.Modelo,
		vehicle.Anio, vehicle.Motor, vehicle.KmActual,
		vehicle.Color, imageURL, vehicle.UpdatedAt, vehicle.ID,
	)
	if err != nil {
		return WrapError(err, "vehicle update")
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return WrapError(err, "vehicle update: get rows affected")
	}
	if rows == 0 {
		return WrapError(sql.ErrNoRows, "vehicle update")
	}

	return nil
}

// Delete removes a vehicle from the database (hard delete).
func (r *VehicleRepositoryImpl) Delete(ctx context.Context, id uint) error {
	result, err := r.ExecContext(ctx, "DELETE FROM vehicles WHERE id = ?", id)
	if err != nil {
		return WrapError(err, "vehicle delete")
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return WrapError(err, "vehicle delete: get rows affected")
	}
	if rows == 0 {
		return WrapError(sql.ErrNoRows, "vehicle delete")
	}

	return nil
}

// CountByUserID returns the total number of vehicles for a user.
func (r *VehicleRepositoryImpl) CountByUserID(ctx context.Context, userID uint) (int64, error) {
	var count int64
	err := r.QueryRowContext(ctx, "SELECT COUNT(*) FROM vehicles WHERE user_id = ?", userID).Scan(&count)
	if err != nil {
		return 0, WrapError(err, "vehicle count by user id")
	}
	return count, nil
}
