package repository

import (
	"context"

	"github.com/lubricentros/api/internal/domain/entity"
)

// AttachmentRepository defines the contract for attachment persistence operations.
type AttachmentRepository interface {
	Create(ctx context.Context, attachment *entity.Attachment) error
	GetByID(ctx context.Context, id uint) (*entity.Attachment, error)
	GetByEntity(ctx context.Context, entityType entity.AttachmentEntityType, entityID uint) ([]entity.Attachment, error)
	Delete(ctx context.Context, id uint) error
}
