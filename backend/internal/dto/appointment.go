package dto

// CreateAppointmentRequest represents the request body for creating an appointment.
type CreateAppointmentRequest struct {
	VehicleID   uint   `json:"vehicle_id" validate:"required"`
	Fecha       string `json:"fecha" validate:"required"` // RFC3339
	TipoService string `json:"tipo_service" validate:"required,oneof=cambio_aceite alineacion mecanica_luces revision_general otro"`
	Observaciones string `json:"observaciones,omitempty"`
}

// UpdateAppointmentRequest represents the request body for updating an appointment.
type UpdateAppointmentRequest struct {
	Fecha         string `json:"fecha,omitempty" validate:"omitempty"` // RFC3339
	TipoService   string `json:"tipo_service,omitempty" validate:"omitempty,oneof=cambio_aceite alineacion mecanica_luces revision_general otro"`
	Status        string `json:"status,omitempty" validate:"omitempty,oneof=pending confirmed in_progress completed cancelled no_show"`
	Observaciones string `json:"observaciones,omitempty"`
}

// AppointmentResponse represents the sanitized appointment data.
type AppointmentResponse struct {
	ID            uint   `json:"id"`
	UserID        uint   `json:"user_id"`
	VehicleID     uint   `json:"vehicle_id"`
	Fecha         string `json:"fecha"`
	SlotEnd       string `json:"slot_end"`
	TipoService   string `json:"tipo_service"`
	Status        string `json:"status"`
	Observaciones string `json:"observaciones,omitempty"`
	CreatedAt     string `json:"created_at"`
	UpdatedAt     string `json:"updated_at"`
}
