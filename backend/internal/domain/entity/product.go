package entity

import "time"

// ProductCategory represents the category of a product/inventory item.
type ProductCategory string

const (
	CategoryAceite     ProductCategory = "aceite"
	CategoryFiltro     ProductCategory = "filtro"
	CategoryFrenos     ProductCategory = "frenos"
	CategoryNeumaticos ProductCategory = "neumaticos"
	CategoryBateria    ProductCategory = "bateria"
	CategoryAditivo    ProductCategory = "aditivo"
	CategoryOtro       ProductCategory = "otro"
)

func (c ProductCategory) String() string {
	return string(c)
}

// Product represents an inventory item.
type Product struct {
	ID          uint            `json:"id" db:"id"`
	SKU         string          `json:"sku" validate:"required,max=50"`
	Nombre      string          `json:"nombre" validate:"required,max=255"`
	Categoria   ProductCategory `json:"categoria" db:"categoria" validate:"required"`
	Descripcion string          `json:"descripcion,omitempty" db:"descripcion"`
	Precio      float64         `json:"precio" db:"precio" validate:"required,min=0"`
	StockActual int             `json:"stock_actual" db:"stock_actual"`
	StockMinimo int             `json:"stock_minimo" db:"stock_minimo"`
	IsActive    bool            `json:"is_active" db:"is_active"`
	CreatedAt   time.Time       `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time       `json:"updated_at" db:"updated_at"`
}
