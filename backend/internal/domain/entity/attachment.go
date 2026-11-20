package entity

import "time"

// AttachmentEntityType represents the type of entity an attachment belongs to.
type AttachmentEntityType string

const (
	EntityVehicle      AttachmentEntityType = "vehicle"
	EntityServiceRecord AttachmentEntityType = "service_record"
	EntityAppointment  AttachmentEntityType = "appointment"
)

func (t AttachmentEntityType) String() string {
	return string(t)
}

// Attachment represents an uploaded file (image, document, etc.).
type Attachment struct {
	ID         uint                 `json:"id" db:"id"`
	EntityType AttachmentEntityType `json:"entity_type" db:"entity_type" validate:"required"`
	EntityID   uint                 `json:"entity_id" db:"entity_id" validate:"required"`
	FileName   string               `json:"file_name" db:"file_name" validate:"required,max=255"`
	FilePath   string               `json:"file_path" db:"file_path" validate:"required,max=500"`
	MimeType   string               `json:"mime_type" db:"mime_type" validate:"required,max=100"`
	FileSize   uint                 `json:"file_size" db:"file_size" validate:"required"`
	UploadedBy uint                 `json:"uploaded_by" db:"uploaded_by" validate:"required"`
	CreatedAt  time.Time            `json:"created_at" db:"created_at"`
}
