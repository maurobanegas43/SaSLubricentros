package dto

// CreateVehicleRequest represents the request body for creating a vehicle.
type CreateVehicleRequest struct {
	Patente  string `json:"patente,omitempty" validate:"omitempty,max=10"`
	Marca    string `json:"marca" validate:"required,max=100"`
	Modelo   string `json:"modelo" validate:"required,max=100"`
	Anio     int16  `json:"anio" validate:"required,min=1900,max=2099"`
	Motor    string `json:"motor,omitempty" validate:"omitempty,max=100"`
	KmActual uint   `json:"km_actual"`
	Color    string `json:"color,omitempty" validate:"omitempty,max=50"`
}

// UpdateVehicleRequest represents the request body for updating a vehicle.
type UpdateVehicleRequest struct {
	Patente  string `json:"patente,omitempty" validate:"omitempty,max=10"`
	Marca    string `json:"marca,omitempty" validate:"omitempty,max=100"`
	Modelo   string `json:"modelo,omitempty" validate:"omitempty,max=100"`
	Anio     *int16 `json:"anio,omitempty" validate:"omitempty,min=1900,max=2099"`
	Motor    string `json:"motor,omitempty" validate:"omitempty,max=100"`
	KmActual *uint  `json:"km_actual,omitempty"`
	Color    string `json:"color,omitempty" validate:"omitempty,max=50"`
	ImageURL string `json:"image_url,omitempty" validate:"omitempty"`
}

// VehicleResponse represents the sanitized vehicle data.
type VehicleResponse struct {
	ID        uint   `json:"id"`
	UserID    uint   `json:"user_id"`
	Patente   string `json:"patente,omitempty"`
	Marca     string `json:"marca"`
	Modelo    string `json:"modelo"`
	Anio      int16  `json:"anio"`
	Motor     string `json:"motor,omitempty"`
	KmActual  uint   `json:"km_actual"`
	Color     string `json:"color,omitempty"`
	ImageURL  string `json:"image_url,omitempty"`
	CreatedAt string `json:"created_at"`
	UpdatedAt string `json:"updated_at"`
}

// TransferOwnershipRequest represents the request body for transferring vehicle ownership.
type TransferOwnershipRequest struct {
	ToUserID uint   `json:"to_user_id" validate:"required"`
	Reason   string `json:"reason,omitempty" validate:"max=255"`
}

// TransferOwnershipResponse represents the response after a successful transfer.
type TransferOwnershipResponse struct {
	TransferID    uint   `json:"transfer_id"`
	VehicleID     uint   `json:"vehicle_id"`
	FromUserID    uint   `json:"from_user_id"`
	ToUserID      uint   `json:"to_user_id"`
	TransferredAt string `json:"transferred_at"`
	Status        string `json:"status"`
}

// VehicleTransferHistoryResponse represents the transfer history for a vehicle.
type VehicleTransferHistoryResponse struct {
	Transfers []TransferOwnershipResponse `json:"transfers"`
}

// UploadVehicleImageResponse represents the response after uploading a vehicle image.
type UploadVehicleImageResponse struct {
	ImageURL  string `json:"image_url"`
	VehicleID uint   `json:"vehicle_id"`
	UploadedAt string `json:"uploaded_at"`
}
