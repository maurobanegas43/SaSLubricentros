package entity

// ServicePartUsed represents a product used in a service record.
type ServicePartUsed struct {
	ID            uint    `json:"id" db:"id"`
	ServiceID     uint    `json:"service_id" db:"service_id" validate:"required"`
	ProductID     uint    `json:"product_id" db:"product_id" validate:"required"`
	Cantidad      uint    `json:"cantidad" db:"cantidad" validate:"required,min=1"`
	CostoUnitario float64 `json:"costo_unitario" db:"costo_unitario" validate:"required,min=0"`
}
