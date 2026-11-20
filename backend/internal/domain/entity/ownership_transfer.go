package entity

import "time"

// TransferStatus represents the status of an ownership transfer.
type TransferStatus string

const (
	TransferRequested TransferStatus = "requested"
	TransferCompleted TransferStatus = "completed"
	TransferRejected  TransferStatus = "rejected"
)

func (s TransferStatus) String() string {
	return string(s)
}

// OwnershipTransfer records a change of vehicle ownership.
type OwnershipTransfer struct {
	ID           uint           `json:"id" db:"id"`
	VehicleID    uint           `json:"vehicle_id" db:"vehicle_id" validate:"required"`
	FromUserID   *uint          `json:"from_user_id,omitempty" db:"from_user_id"`
	ToUserID     uint           `json:"to_user_id" db:"to_user_id" validate:"required"`
	TransferredAt time.Time     `json:"transferred_at" db:"transferred_at"`
	Reason       string         `json:"reason,omitempty" db:"reason" validate:"omitempty,max=255"`
	InitiatedBy  *uint          `json:"initiated_by,omitempty" db:"initiated_by"`
	Status       TransferStatus `json:"status" db:"status"`
	Notes        string         `json:"notes,omitempty" db:"notes"`
	CreatedAt    time.Time      `json:"created_at" db:"created_at"`
}
