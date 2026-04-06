package usecase

import (
	"context"
	"errors"
	"fmt"

	"github.com/lubricentros/api/internal/domain/entity"
	domainrepo "github.com/lubricentros/api/internal/domain/repository"
	"github.com/lubricentros/api/internal/repository"
)

// ProductUsecase handles product business logic.
type ProductUsecase struct {
	productRepo domainrepo.ProductRepository
}

// NewProductUsecase creates a new product usecase.
func NewProductUsecase(productRepo domainrepo.ProductRepository) *ProductUsecase {
	return &ProductUsecase{productRepo: productRepo}
}

// CreateProductInput holds the input for creating a product.
type CreateProductInput struct {
	SKU         string
	Nombre      string
	Categoria   entity.ProductCategory
	Descripcion string
	Precio      float64
	StockActual int
	StockMinimo int
}

// CreateProduct validates and creates a new product.
func (uc *ProductUsecase) CreateProduct(ctx context.Context, input CreateProductInput) (*entity.Product, error) {
	if input.SKU == "" || input.Nombre == "" {
		return nil, repository.ErrInvalidInput
	}
	if input.Precio < 0 {
		return nil, repository.ErrInvalidInput
	}

	// Check for duplicate SKU
	_, err := uc.productRepo.GetBySKU(ctx, input.SKU)
	if err == nil {
		return nil, errors.New("SKU already exists")
	}

	product := &entity.Product{
		SKU:         input.SKU,
		Nombre:      input.Nombre,
		Categoria:   input.Categoria,
		Descripcion: input.Descripcion,
		Precio:      input.Precio,
		StockActual: input.StockActual,
		StockMinimo: input.StockMinimo,
	}

	if err := uc.productRepo.Create(ctx, product); err != nil {
		return nil, fmt.Errorf("create product: %w", err)
	}

	return product, nil
}

// GetProductByID retrieves a product by ID.
func (uc *ProductUsecase) GetProductByID(ctx context.Context, id uint) (*entity.Product, error) {
	product, err := uc.productRepo.GetByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("get product: %w", err)
	}
	return product, nil
}

// ListProducts returns paginated products with optional category filter.
func (uc *ProductUsecase) ListProducts(ctx context.Context, category *entity.ProductCategory, offset, limit int) ([]entity.Product, error) {
	products, err := uc.productRepo.List(ctx, category, offset, limit)
	if err != nil {
		return nil, fmt.Errorf("list products: %w", err)
	}
	return products, nil
}

// CountProducts returns the total number of products.
func (uc *ProductUsecase) CountProducts(ctx context.Context) (int64, error) {
	return uc.productRepo.Count(ctx)
}

// UpdateProductInput holds the input for updating a product.
type UpdateProductInput struct {
	ID          uint
	SKU         *string
	Nombre      *string
	Categoria   *entity.ProductCategory
	Descripcion *string
	Precio      *float64
	StockActual *int
	StockMinimo *int
}

// UpdateProduct validates and updates a product.
func (uc *ProductUsecase) UpdateProduct(ctx context.Context, input UpdateProductInput) (*entity.Product, error) {
	product, err := uc.productRepo.GetByID(ctx, input.ID)
	if err != nil {
		return nil, fmt.Errorf("update product: %w", err)
	}

	if input.SKU != nil && *input.SKU != "" {
		// Check for duplicate SKU
		if *input.SKU != product.SKU {
			existing, _ := uc.productRepo.GetBySKU(ctx, *input.SKU)
			if existing != nil && existing.ID != input.ID {
				return nil, errors.New("SKU already exists")
			}
		}
		product.SKU = *input.SKU
	}
	if input.Nombre != nil && *input.Nombre != "" {
		product.Nombre = *input.Nombre
	}
	if input.Categoria != nil {
		product.Categoria = *input.Categoria
	}
	if input.Descripcion != nil {
		product.Descripcion = *input.Descripcion
	}
	if input.Precio != nil && *input.Precio >= 0 {
		product.Precio = *input.Precio
	}
	if input.StockActual != nil {
		product.StockActual = *input.StockActual
	}
	if input.StockMinimo != nil {
		product.StockMinimo = *input.StockMinimo
	}

	if err := uc.productRepo.Update(ctx, product); err != nil {
		return nil, fmt.Errorf("update product: %w", err)
	}

	return product, nil
}

// DeleteProduct soft deletes a product.
func (uc *ProductUsecase) DeleteProduct(ctx context.Context, id uint) error {
	if err := uc.productRepo.Delete(ctx, id); err != nil {
		return fmt.Errorf("delete product: %w", err)
	}
	return nil
}

// GetLowStockProducts returns products with stock below minimum.
func (uc *ProductUsecase) GetLowStockProducts(ctx context.Context) ([]entity.Product, error) {
	products, err := uc.productRepo.ListLowStock(ctx)
	if err != nil {
		return nil, fmt.Errorf("get low stock products: %w", err)
	}
	return products, nil
}

// UpdateStockInput holds the input for updating product stock.
type UpdateStockInput struct {
	ProductID uint
	Cantidad  int // Positive to add, negative to remove
}

// UpdateStock updates the stock quantity.
func (uc *ProductUsecase) UpdateStock(ctx context.Context, input UpdateStockInput) error {
	product, err := uc.productRepo.GetByID(ctx, input.ProductID)
	if err != nil {
		return fmt.Errorf("update stock: product not found: %w", err)
	}

	newStock := product.StockActual + input.Cantidad
	if newStock < 0 {
		return errors.New("insufficient stock")
	}

	if err := uc.productRepo.UpdateStock(ctx, input.ProductID, input.Cantidad); err != nil {
		return fmt.Errorf("update stock: %w", err)
	}

	return nil
}
