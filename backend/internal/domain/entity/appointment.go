package entity

import "time"

// AppointmentType represents the type of service appointment.
type AppointmentType string

const (
	TypeCambioAceite    AppointmentType = "cambio_aceite"
	TypeAlineacion      AppointmentType = "alineacion"
	TypeMecanicaLuces   AppointmentType = "mecanica_luces"
	TypeRevisionGeneral AppointmentType = "revision_general"
	TypeOtro            AppointmentType = "otro"
)

func (t AppointmentType) String() string {
	return string(t)
}

// AppointmentStatus represents the current state of an appointment.
type AppointmentStatus string

const (
	StatusPending     AppointmentStatus = "pending"
	StatusConfirmed   AppointmentStatus = "confirmed"
	StatusInProgress  AppointmentStatus = "in_progress"
	StatusCompleted   AppointmentStatus = "completed"
	StatusCancelled   AppointmentStatus = "cancelled"
	StatusNoShow      AppointmentStatus = "no_show"
)

func (s AppointmentStatus) String() string {
	return string(s)
}

// Appointment represents a scheduled service appointment.
type Appointment struct {
	ID            uint              `json:"id" db:"id"`
	UserID        uint              `json:"user_id" db:"user_id" validate:"required"`
	VehicleID     uint              `json:"vehicle_id" db:"vehicle_id" validate:"required"`
	Fecha         time.Time         `json:"fecha" db:"fecha" validate:"required"`
	SlotEnd       time.Time         `json:"slot_end" db:"slot_end" validate:"required"`
	TipoService   AppointmentType   `json:"tipo_service" db:"tipo_service" validate:"required"`
	Status        AppointmentStatus `json:"status" db:"status"`
	Observaciones string            `json:"observaciones,omitempty" db:"observaciones"`
	CreatedAt     time.Time         `json:"created_at" db:"created_at"`
	UpdatedAt     time.Time         `json:"updated_at" db:"updated_at"`
}
