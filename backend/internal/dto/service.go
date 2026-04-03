package dto

// CreateServiceRecordRequest represents the request body for creating a service record.
type CreateServiceRecordRequest struct {
	VehicleID        uint     `json:"vehicle_id" validate:"required"`
	AppointmentID    *uint    `json:"appointment_id,omitempty"`
	Fecha            string   `json:"fecha" validate:"required"` // RFC3339
	Km               uint     `json:"km" validate:"required"`
	TipoAceite       string   `json:"tipo_aceite" validate:"required,oneof=mineral semi_sintetico sintetico"`
	MarcaAceite      string   `json:"marca_aceite,omitempty" validate:"omitempty,max=100"`
	CostoTotal       *float64 `json:"costo_total,omitempty"`
	Observaciones    string   `json:"observaciones,omitempty"`
	ProximoServiceKm *uint    `json:"proximo_service_km,omitempty"`
}

// CreateServiceAddendumRequest represents the request body for creating a service addendum.
type CreateServiceAddendumRequest struct {
	ServiceID uint   `json:"service_id" validate:"required"`
	FieldName string `json:"field_name" validate:"required,max=100"`
	OldValue  string `json:"old_value,omitempty"`
	NewValue  string `json:"new_value" validate:"required"`
	Reason    string `json:"reason" validate:"required"`
}

// CreateServicePartRequest represents a single part used in a service.
type CreateServicePartRequest struct {
	ProductID     uint    `json:"product_id" validate:"required"`
	Cantidad      uint    `json:"cantidad" validate:"required,min=1"`
	CostoUnitario float64 `json:"costo_unitario" validate:"required,min=0"`
}

// ServiceRecordResponse represents the sanitized service record data.
type ServiceRecordResponse struct {
	ID               uint     `json:"id"`
	VehicleID        uint     `json:"vehicle_id"`
	AppointmentID    *uint    `json:"appointment_id,omitempty"`
	Fecha            string   `json:"fecha"`
	Km               uint     `json:"km"`
	TipoAceite       string   `json:"tipo_aceite"`
	MarcaAceite      string   `json:"marca_aceite,omitempty"`
	CostoTotal       *float64 `json:"costo_total,omitempty"`
	Observaciones    string   `json:"observaciones,omitempty"`
	ProximoServiceKm *uint    `json:"proximo_service_km,omitempty"`
	CreatedBy        uint     `json:"created_by"`
	CreatedAt        string   `json:"created_at"`
}
