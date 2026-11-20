package dto

// CreateProductRequest represents the request body for creating a product.
type CreateProductRequest struct {
	SKU         string  `json:"sku" validate:"required,max=50"`
	Nombre      string  `json:"nombre" validate:"required,max=255"`
	Categoria   string  `json:"categoria" validate:"required,oneof=aceite filtro frenos neumaticos bateria aditivo otro"`
	Descripcion string  `json:"descripcion,omitempty" validate:"omitempty,max=500"`
	Precio      float64 `json:"precio" validate:"required,min=0"`
	StockActual int     `json:"stock_actual" validate:"min=0"`
	StockMinimo int     `json:"stock_minimo" validate:"min=0"`
}

// UpdateProductRequest represents the request body for updating a product.
type UpdateProductRequest struct {
	SKU         string  `json:"sku,omitempty" validate:"omitempty,max=50"`
	Nombre      string  `json:"nombre,omitempty" validate:"omitempty,max=255"`
	Categoria   string  `json:"categoria,omitempty" validate:"omitempty,oneof=aceite filtro frenos neumaticos bateria aditivo otro"`
	Descripcion string  `json:"descripcion,omitempty" validate:"omitempty,max=500"`
	Precio      float64 `json:"precio,omitempty" validate:"omitempty,min=0"`
	StockActual *int    `json:"stock_actual,omitempty" validate:"omitempty,min=0"`
	StockMinimo int     `json:"stock_minimo,omitempty" validate:"omitempty,min=0"`
}

// UpdateStockRequest represents the request body for updating product stock.
type UpdateStockRequest struct {
	Cantidad int `json:"cantidad"` // Can be positive (add) or negative (remove)
}

// ProductResponse represents the sanitized product data.
type ProductResponse struct {
	ID          uint    `json:"id"`
	SKU         string  `json:"sku"`
	Nombre      string  `json:"nombre"`
	Categoria   string  `json:"categoria"`
	Descripcion string  `json:"descripcion,omitempty"`
	Precio      float64 `json:"precio"`
	StockActual int     `json:"stock_actual"`
	StockMinimo int     `json:"stock_minimo"`
	IsActive    bool    `json:"is_active"`
	CreatedAt   string  `json:"created_at"`
	UpdatedAt   string  `json:"updated_at"`
}
