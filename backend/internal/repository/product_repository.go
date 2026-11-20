package repository

import (
	"context"
	"database/sql"
	"time"

	"github.com/lubricentros/api/internal/domain/entity"
)

// ProductRepositoryImpl is the MariaDB implementation of ProductRepository.
type ProductRepositoryImpl struct {
	*BaseRepository
}

// NewProductRepository creates a new product repository.
func NewProductRepository(db *sql.DB) *ProductRepositoryImpl {
	return &ProductRepositoryImpl{
		BaseRepository: NewBaseRepository(db),
	}
}

// Create inserts a new product into the database.
func (r *ProductRepositoryImpl) Create(ctx context.Context, product *entity.Product) error {
	query := `INSERT INTO products (sku, nombre, categoria, descripcion, precio, stock_actual, stock_minimo, is_active, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		RETURNING id`

	now := time.Now()
	product.CreatedAt = now
	product.UpdatedAt = now
	product.IsActive = true

	var id int64
	err := r.QueryRowContext(ctx, query,
		product.SKU, product.Nombre, product.Categoria, product.Descripcion,
		product.Precio, product.StockActual, product.StockMinimo, product.IsActive,
		product.CreatedAt, product.UpdatedAt,
	).Scan(&id)
	if err != nil {
		return WrapError(err, "product create")
	}

	product.ID = uint(id)

	return nil
}

// GetByID retrieves a product by its ID.
func (r *ProductRepositoryImpl) GetByID(ctx context.Context, id uint) (*entity.Product, error) {
	query := `SELECT id, sku, nombre, categoria, descripcion, precio, stock_actual, stock_minimo, is_active, created_at, updated_at
		FROM products WHERE id = ?`

	var p entity.Product
	err := r.QueryRowContext(ctx, query, id).Scan(
		&p.ID, &p.SKU, &p.Nombre, &p.Categoria, &p.Descripcion,
		&p.Precio, &p.StockActual, &p.StockMinimo, &p.IsActive,
		&p.CreatedAt, &p.UpdatedAt,
	)
	if err != nil {
		return nil, WrapError(err, "product get by id")
	}

	return &p, nil
}

// GetBySKU retrieves a product by its SKU.
func (r *ProductRepositoryImpl) GetBySKU(ctx context.Context, sku string) (*entity.Product, error) {
	query := `SELECT id, sku, nombre, categoria, descripcion, precio, stock_actual, stock_minimo, is_active, created_at, updated_at
		FROM products WHERE sku = ?`

	var p entity.Product
	err := r.QueryRowContext(ctx, query, sku).Scan(
		&p.ID, &p.SKU, &p.Nombre, &p.Categoria, &p.Descripcion,
		&p.Precio, &p.StockActual, &p.StockMinimo, &p.IsActive,
		&p.CreatedAt, &p.UpdatedAt,
	)
	if err != nil {
		return nil, WrapError(err, "product get by sku")
	}

	return &p, nil
}

// Update updates an existing product.
func (r *ProductRepositoryImpl) Update(ctx context.Context, product *entity.Product) error {
	query := `UPDATE products SET sku = ?, nombre = ?, categoria = ?, descripcion = ?, 
		precio = ?, stock_actual = ?, stock_minimo = ?, is_active = ?, updated_at = ? WHERE id = ?`

	product.UpdatedAt = time.Now()

	result, err := r.ExecContext(ctx, query,
		product.SKU, product.Nombre, product.Categoria, product.Descripcion,
		product.Precio, product.StockActual, product.StockMinimo, product.IsActive,
		product.UpdatedAt, product.ID,
	)
	if err != nil {
		return WrapError(err, "product update")
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return WrapError(err, "product update: get rows affected")
	}
	if rows == 0 {
		return WrapError(sql.ErrNoRows, "product update")
	}

	return nil
}

// Delete soft deletes a product (sets is_active = false).
func (r *ProductRepositoryImpl) Delete(ctx context.Context, id uint) error {
	query := `UPDATE products SET is_active = false, updated_at = ? WHERE id = ?`

	now := time.Now()
	result, err := r.ExecContext(ctx, query, now, id)
	if err != nil {
		return WrapError(err, "product delete")
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return WrapError(err, "product delete: get rows affected")
	}
	if rows == 0 {
		return WrapError(sql.ErrNoRows, "product delete")
	}

	return nil
}

// List retrieves products with optional category filter and pagination.
func (r *ProductRepositoryImpl) List(ctx context.Context, category *entity.ProductCategory, offset, limit int) ([]entity.Product, error) {
	var query string
	var args []interface{}

	if category != nil {
		query = `SELECT id, sku, nombre, categoria, descripcion, precio, stock_actual, stock_minimo, is_active, created_at, updated_at
			FROM products WHERE is_active = true AND categoria = ? ORDER BY nombre LIMIT ? OFFSET ?`
		args = []interface{}{*category, limit, offset}
	} else {
		query = `SELECT id, sku, nombre, categoria, descripcion, precio, stock_actual, stock_minimo, is_active, created_at, updated_at
			FROM products WHERE is_active = true ORDER BY nombre LIMIT ? OFFSET ?`
		args = []interface{}{limit, offset}
	}

	rows, err := r.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, WrapError(err, "product list")
	}
	defer rows.Close()

	var products []entity.Product
	for rows.Next() {
		var p entity.Product
		if err := rows.Scan(
			&p.ID, &p.SKU, &p.Nombre, &p.Categoria, &p.Descripcion,
			&p.Precio, &p.StockActual, &p.StockMinimo, &p.IsActive,
			&p.CreatedAt, &p.UpdatedAt,
		); err != nil {
			return nil, WrapError(err, "product list: scan")
		}
		products = append(products, p)
	}

	if err := rows.Err(); err != nil {
		return nil, WrapError(err, "product list: iterate")
	}

	return products, nil
}

// ListLowStock retrieves products with stock below minimum.
func (r *ProductRepositoryImpl) ListLowStock(ctx context.Context) ([]entity.Product, error) {
	query := `SELECT id, sku, nombre, categoria, descripcion, precio, stock_actual, stock_minimo, is_active, created_at, updated_at
		FROM products WHERE is_active = true AND stock_actual <= stock_minimo ORDER BY stock_actual ASC`

	rows, err := r.QueryContext(ctx, query)
	if err != nil {
		return nil, WrapError(err, "product list low stock")
	}
	defer rows.Close()

	var products []entity.Product
	for rows.Next() {
		var p entity.Product
		if err := rows.Scan(
			&p.ID, &p.SKU, &p.Nombre, &p.Categoria, &p.Descripcion,
			&p.Precio, &p.StockActual, &p.StockMinimo, &p.IsActive,
			&p.CreatedAt, &p.UpdatedAt,
		); err != nil {
			return nil, WrapError(err, "product list low stock: scan")
		}
		products = append(products, p)
	}

	if err := rows.Err(); err != nil {
		return nil, WrapError(err, "product list low stock: iterate")
	}

	return products, nil
}

// Count returns the total number of active products.
func (r *ProductRepositoryImpl) Count(ctx context.Context) (int64, error) {
	var count int64
	err := r.QueryRowContext(ctx, "SELECT COUNT(*) FROM products WHERE is_active = true").Scan(&count)
	if err != nil {
		return 0, WrapError(err, "product count")
	}
	return count, nil
}

// UpdateStock updates the stock quantity for a product.
func (r *ProductRepositoryImpl) UpdateStock(ctx context.Context, id uint, quantity int) error {
	query := `UPDATE products SET stock_actual = stock_actual + ?, updated_at = ? WHERE id = ?`

	now := time.Now()
	result, err := r.ExecContext(ctx, query, quantity, now, id)
	if err != nil {
		return WrapError(err, "product update stock")
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return WrapError(err, "product update stock: get rows affected")
	}
	if rows == 0 {
		return WrapError(sql.ErrNoRows, "product update stock")
	}

	return nil
}
