package entity

import "time"

// VehicleTransfer represents a vehicle ownership transfer record.
type VehicleTransfer struct {
	ID            uint      `json:"id" db:"id"`
	VehicleID     uint      `json:"vehicle_id" db:"vehicle_id"`
	FromUserID    *uint     `json:"from_user_id,omitempty" db:"from_user_id"`
	ToUserID      uint      `json:"to_user_id" db:"to_user_id"`
	TransferredAt time.Time `json:"transferred_at" db:"transferred_at"`
	Reason        *string   `json:"reason,omitempty" db:"reason"`
	InitiatedBy   *uint     `json:"initiated_by,omitempty" db:"initiated_by"`
	Status        string    `json:"status" db:"status"`
	Notes         *string   `json:"notes,omitempty" db:"notes"`
	CreatedAt     time.Time `json:"created_at" db:"created_at"`
}

// IsCompleted checks if the transfer is completed.
func (t *VehicleTransfer) IsCompleted() bool {
	return t.Status == "completed"
}

// IsPending checks if the transfer is pending.
func (t *VehicleTransfer) IsPending() bool {
	return t.Status == "requested"
}
