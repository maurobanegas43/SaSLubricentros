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
	CreatedAt string `json:"created_at"`
	UpdatedAt string `json:"updated_at"`
}
