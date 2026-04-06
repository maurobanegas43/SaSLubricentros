package repository

import (
	"context"

	"github.com/lubricentros/api/internal/domain/entity"
)

// ProductRepository defines the contract for product persistence operations.
type ProductRepository interface {
	Create(ctx context.Context, product *entity.Product) error
	GetByID(ctx context.Context, id uint) (*entity.Product, error)
	GetBySKU(ctx context.Context, sku string) (*entity.Product, error)
	Update(ctx context.Context, product *entity.Product) error
	Delete(ctx context.Context, id uint) error
	List(ctx context.Context, category *entity.ProductCategory, offset, limit int) ([]entity.Product, error)
	ListLowStock(ctx context.Context) ([]entity.Product, error)
	Count(ctx context.Context) (int64, error)
	UpdateStock(ctx context.Context, id uint, quantity int) error
}
