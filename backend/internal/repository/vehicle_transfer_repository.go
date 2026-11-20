package repository

import (
	"context"
	"database/sql"
	"time"

	"github.com/lubricentros/api/internal/domain/entity"
)

// VehicleTransferRepositoryImpl is the MariaDB implementation.
type VehicleTransferRepositoryImpl struct {
	*BaseRepository
}

// NewVehicleTransferRepository creates a new vehicle transfer repository.
func NewVehicleTransferRepository(db *sql.DB) *VehicleTransferRepositoryImpl {
	return &VehicleTransferRepositoryImpl{
		BaseRepository: NewBaseRepository(db),
	}
}

// Create inserts a new vehicle transfer record.
func (r *VehicleTransferRepositoryImpl) Create(ctx context.Context, transfer *entity.VehicleTransfer) error {
	query := `INSERT INTO ownership_transfers 
		(vehicle_id, from_user_id, to_user_id, transferred_at, reason, initiated_by, status, notes, created_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
		RETURNING id`

	now := time.Now()
	transfer.CreatedAt = now
	transfer.TransferredAt = now

	var id int64
	err := r.QueryRowContext(ctx, query,
		transfer.VehicleID, transfer.FromUserID, transfer.ToUserID, transfer.TransferredAt,
		transfer.Reason, transfer.InitiatedBy, transfer.Status, transfer.Notes, transfer.CreatedAt,
	).Scan(&id)
	if err != nil {
		return WrapError(err, "vehicle transfer create")
	}

	transfer.ID = uint(id)

	return nil
}

// GetByID retrieves a transfer by its ID.
func (r *VehicleTransferRepositoryImpl) GetByID(ctx context.Context, id uint) (*entity.VehicleTransfer, error) {
	query := `SELECT id, vehicle_id, from_user_id, to_user_id, transferred_at, reason, 
		initiated_by, status, notes, created_at FROM ownership_transfers WHERE id = ?`

	var t entity.VehicleTransfer
	err := r.QueryRowContext(ctx, query, id).Scan(
		&t.ID, &t.VehicleID, &t.FromUserID, &t.ToUserID, &t.TransferredAt,
		&t.Reason, &t.InitiatedBy, &t.Status, &t.Notes, &t.CreatedAt,
	)
	if err != nil {
		return nil, WrapError(err, "vehicle transfer get by id")
	}

	return &t, nil
}

// GetByVehicleID retrieves all transfers for a vehicle.
func (r *VehicleTransferRepositoryImpl) GetByVehicleID(ctx context.Context, vehicleID uint) ([]entity.VehicleTransfer, error) {
	query := `SELECT id, vehicle_id, from_user_id, to_user_id, transferred_at, reason, 
		initiated_by, status, notes, created_at FROM ownership_transfers 
		WHERE vehicle_id = ? ORDER BY created_at DESC`

	rows, err := r.QueryContext(ctx, query, vehicleID)
	if err != nil {
		return nil, WrapError(err, "vehicle transfer get by vehicle id")
	}
	defer rows.Close()

	var transfers []entity.VehicleTransfer
	for rows.Next() {
		var t entity.VehicleTransfer
		if err := rows.Scan(
			&t.ID, &t.VehicleID, &t.FromUserID, &t.ToUserID, &t.TransferredAt,
			&t.Reason, &t.InitiatedBy, &t.Status, &t.Notes, &t.CreatedAt,
		); err != nil {
			return nil, WrapError(err, "vehicle transfer get by vehicle id: scan")
		}
		transfers = append(transfers, t)
	}

	if err := rows.Err(); err != nil {
		return nil, WrapError(err, "vehicle transfer get by vehicle id: iterate")
	}

	return transfers, nil
}

// GetPendingByVehicleID retrieves the pending transfer for a vehicle.
func (r *VehicleTransferRepositoryImpl) GetPendingByVehicleID(ctx context.Context, vehicleID uint) (*entity.VehicleTransfer, error) {
	query := `SELECT id, vehicle_id, from_user_id, to_user_id, transferred_at, reason, 
		initiated_by, status, notes, created_at FROM ownership_transfers 
		WHERE vehicle_id = ? AND status = 'requested' LIMIT 1`

	var t entity.VehicleTransfer
	err := r.QueryRowContext(ctx, query, vehicleID).Scan(
		&t.ID, &t.VehicleID, &t.FromUserID, &t.ToUserID, &t.TransferredAt,
		&t.Reason, &t.InitiatedBy, &t.Status, &t.Notes, &t.CreatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, WrapError(err, "vehicle transfer get pending by vehicle id")
	}

	return &t, nil
}

// UpdateStatus updates the status of a transfer.
func (r *VehicleTransferRepositoryImpl) UpdateStatus(ctx context.Context, id uint, status string) error {
	query := `UPDATE ownership_transfers SET status = ? WHERE id = ?`

	result, err := r.ExecContext(ctx, query, status, id)
	if err != nil {
		return WrapError(err, "vehicle transfer update status")
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return WrapError(err, "vehicle transfer update status: get rows affected")
	}
	if rows == 0 {
		return WrapError(sql.ErrNoRows, "vehicle transfer update status")
	}

	return nil
}
