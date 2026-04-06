package usecase

import (
	"testing"

	"github.com/lubricentros/api/internal/domain/entity"
	"github.com/lubricentros/api/internal/domain/repository"
	"github.com/stretchr/testify/assert"
)

// MockProductRepository is a mock implementation of ProductRepository for testing.
type MockProductRepository struct {
	products map[uint]*entity.Product
	nextID   uint
}

func NewMockProductRepository() *MockProductRepository {
	return &MockProductRepository{
		products: make(map[uint]*entity.Product),
		nextID:   1,
	}
}

func (m *MockProductRepository) Create(ctx context.Context, product *entity.Product) error {
	product.ID = m.nextID
	m.nextID++
	m.products[product.ID] = product
	return nil
}

func (m *MockProductRepository) GetByID(ctx context.Context, id uint) (*entity.Product, error) {
	if p, ok := m.products[id]; ok {
		return p, nil
	}
	return nil, repository.ErrNotFound
}

func (m *MockProductRepository) GetBySKU(ctx context.Context, sku string) (*entity.Product, error) {
	for _, p := range m.products {
		if p.SKU == sku {
			return p, nil
		}
	}
	return nil, repository.ErrNotFound
}

func (m *MockProductRepository) Update(ctx context.Context, product *entity.Product) error {
	if _, ok := m.products[product.ID]; !ok {
		return repository.ErrNotFound
	}
	m.products[product.ID] = product
	return nil
}

func (m *MockProductRepository) Delete(ctx context.Context, id uint) error {
	if _, ok := m.products[id]; !ok {
		return repository.ErrNotFound
	}
	delete(m.products, id)
	return nil
}

func (m *MockProductRepository) List(ctx context.Context, category *entity.ProductCategory, offset, limit int) ([]entity.Product, error) {
	var result []entity.Product
	count := 0
	for _, p := range m.products {
		if category != nil && p.Categoria != *category {
			continue
		}
		if count >= offset {
			result = append(result, *p)
			if len(result) >= limit {
				break
			}
		}
		count++
	}
	return result, nil
}

func (m *MockProductRepository) ListLowStock(ctx context.Context) ([]entity.Product, error) {
	var result []entity.Product
	for _, p := range m.products {
		if p.StockActual <= p.StockMinimo {
			result = append(result, *p)
		}
	}
	return result, nil
}

func (m *MockProductRepository) Count(ctx context.Context) (int64, error) {
	return int64(len(m.products)), nil
}

func (m *MockProductRepository) UpdateStock(ctx context.Context, id uint, quantity int) error {
	if p, ok := m.products[id]; ok {
		p.StockActual += quantity
		return nil
	}
	return repository.ErrNotFound
}

func TestProductUsecase_CreateProduct(t *testing.T) {
	repo := NewMockProductRepository()
	uc := NewProductUsecase(repo)

	product, err := uc.CreateProduct(nil, CreateProductInput{
		SKU:         "ACE-001",
		Nombre:      "Aceite 5W30",
		Categoria:   entity.CategoryAceite,
		Descripcion: "Aceite sintético",
		Precio:      1500.00,
		StockActual: 10,
		StockMinimo: 5,
	})

	assert.NoError(t, err)
	assert.NotNil(t, product)
	assert.Equal(t, "ACE-001", product.SKU)
}

func TestProductUsecase_CreateProduct_DuplicateSKU(t *testing.T) {
	repo := NewMockProductRepository()
	uc := NewProductUsecase(repo)

	// Create first product
	_, _ = uc.CreateProduct(nil, CreateProductInput{
		SKU:       "ACE-001",
		Nombre:    "Aceite 5W30",
		Categoria: entity.CategoryAceite,
		Precio:    1500.00,
	})

	// Try to create duplicate
	_, err := uc.CreateProduct(nil, CreateProductInput{
		SKU:       "ACE-001",
		Nombre:    "Otro aceite",
		Categoria: entity.CategoryAceite,
		Precio:    1200.00,
	})

	assert.Error(t, err)
	assert.Equal(t, "SKU already exists", err.Error())
}

func TestProductUsecase_UpdateStock(t *testing.T) {
	repo := NewMockProductRepository()
	uc := NewProductUsecase(repo)

	// Create product
	product, _ := uc.CreateProduct(nil, CreateProductInput{
		SKU:         "ACE-001",
		Nombre:      "Aceite 5W30",
		Categoria:   entity.CategoryAceite,
		Precio:      1500.00,
		StockActual: 10,
	})

	// Add stock
	err := uc.UpdateStock(nil, UpdateStockInput{
		ProductID: product.ID,
		Cantidad:  5,
	})

	assert.NoError(t, err)
}

func TestProductUsecase_UpdateStock_Insufficient(t *testing.T) {
	repo := NewMockProductRepository()
	uc := NewProductUsecase(repo)

	// Create product with low stock
	product, _ := uc.CreateProduct(nil, CreateProductInput{
		SKU:         "ACE-001",
		Nombre:      "Aceite 5W30",
		Categoria:   entity.CategoryAceite,
		Precio:      1500.00,
		StockActual: 2,
	})

	// Try to remove more than available
	err := uc.UpdateStock(nil, UpdateStockInput{
		ProductID: product.ID,
		Cantidad:  -10,
	})

	assert.Error(t, err)
	assert.Equal(t, "insufficient stock", err.Error())
}

func TestProductUsecase_GetLowStockProducts(t *testing.T) {
	repo := NewMockProductRepository()
	uc := NewProductUsecase(repo)

	// Create products
	_, _ = uc.CreateProduct(nil, CreateProductInput{
		SKU:         "ACE-001",
		Nombre:      "Aceite 5W30",
		Categoria:   entity.CategoryAceite,
		Precio:      1500.00,
		StockActual: 3,
		StockMinimo: 5, // Low stock
	})
	_, _ = uc.CreateProduct(nil, CreateProductInput{
		SKU:         "FIL-001",
		Nombre:      "Filtro de aceite",
		Categoria:   entity.CategoryFiltro,
		Precio:      500.00,
		StockActual: 20,
		StockMinimo: 10, // OK
	})

	lowStock, err := uc.GetLowStockProducts(nil)

	assert.NoError(t, err)
	assert.Len(t, lowStock, 1)
	assert.Equal(t, "ACE-001", lowStock[0].SKU)
}
