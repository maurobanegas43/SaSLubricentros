package entity

import "time"

// OilType represents the type of engine oil used in a service.
type OilType string

const (
	OilMineral      OilType = "mineral"
	OilSemiSintetico OilType = "semi_sintetico"
	OilSintetico    OilType = "sintetico"
)

func (t OilType) String() string {
	return string(t)
}

// ServiceRecord represents an immutable service history record.
type ServiceRecord struct {
	ID              uint      `json:"id" db:"id"`
	VehicleID       uint      `json:"vehicle_id" db:"vehicle_id" validate:"required"`
	AppointmentID   *uint     `json:"appointment_id,omitempty" db:"appointment_id"`
	Fecha           time.Time `json:"fecha" db:"fecha" validate:"required"`
	Km              uint      `json:"km" db:"km" validate:"required"`
	TipoAceite      OilType   `json:"tipo_aceite" db:"tipo_aceite" validate:"required"`
	MarcaAceite     string    `json:"marca_aceite,omitempty" db:"marca_aceite" validate:"omitempty,max=100"`
	CostoTotal      *float64  `json:"costo_total,omitempty" db:"costo_total"`
	Observaciones   string    `json:"observaciones,omitempty" db:"observaciones"`
	ProximoServiceKm *uint    `json:"proximo_service_km,omitempty" db:"proximo_service_km"`
	CreatedBy       uint      `json:"created_by" db:"created_by" validate:"required"`
	CreatedAt       time.Time `json:"created_at" db:"created_at"`
}
