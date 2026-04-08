package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/lubricentros/api/internal/domain/entity"
	"github.com/lubricentros/api/internal/dto"
	"github.com/lubricentros/api/internal/usecase"
	"github.com/lubricentros/api/pkg/response"
)

// ProductHandler handles product HTTP requests.
type ProductHandler struct {
	productUsecase *usecase.ProductUsecase
}

// NewProductHandler creates a new product handler.
func NewProductHandler(productUsecase *usecase.ProductUsecase) *ProductHandler {
	return &ProductHandler{productUsecase: productUsecase}
}

// List handles GET /products
func (h *ProductHandler) List(c *gin.Context) {
	category := c.Query("categoria")
	page, limit := parsePagination(c)
	offset := (page - 1) * limit

	var cat *entity.ProductCategory
	if category != "" {
		catVal := entity.ProductCategory(category)
		cat = &catVal
	}

	products, err := h.productUsecase.ListProducts(c.Request.Context(), cat, offset, limit)
	if err != nil {
		response.InternalError(c)
		return
	}

	total, err := h.productUsecase.CountProducts(c.Request.Context())
	if err != nil {
		response.InternalError(c)
		return
	}

	responses := make([]dto.ProductResponse, len(products))
	for i, p := range products {
		responses[i] = productToResponse(p)
	}

	response.Paginated(c, responses, total, offset, limit)
}

// GetByID handles GET /products/:id
func (h *ProductHandler) GetByID(c *gin.Context) {
	productID, err := parseUintParam(c, "id")
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Bad Request", "Invalid product ID")
		return
	}

	product, err := h.productUsecase.GetProductByID(c.Request.Context(), productID)
	if err != nil {
		response.NotFound(c, "Product not found")
		return
	}

	response.JSON(c, http.StatusOK, productToResponse(*product))
}

// Create handles POST /products (admin only)
func (h *ProductHandler) Create(c *gin.Context) {
	var req dto.CreateProductRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Validation(c, extractValidationErrors(err))
		return
	}

	product, err := h.productUsecase.CreateProduct(c.Request.Context(), usecase.CreateProductInput{
		SKU:         req.SKU,
		Nombre:      req.Nombre,
		Categoria:   entity.ProductCategory(req.Categoria),
		Descripcion: req.Descripcion,
		Precio:      req.Precio,
		StockActual: req.StockActual,
		StockMinimo: req.StockMinimo,
	})
	if err != nil {
		if err.Error() == "SKU already exists" {
			response.Error(c, http.StatusConflict, "Conflict", "SKU already exists")
			return
		}
		response.Error(c, http.StatusBadRequest, "Bad Request", err.Error())
		return
	}

	response.Created(c, productToResponse(*product))
}

// Update handles PUT /products/:id
func (h *ProductHandler) Update(c *gin.Context) {
	productID, err := parseUintParam(c, "id")
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Bad Request", "Invalid product ID")
		return
	}

	var req dto.UpdateProductRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Validation(c, extractValidationErrors(err))
		return
	}

	input := usecase.UpdateProductInput{ID: productID}

	if req.SKU != "" {
		input.SKU = &req.SKU
	}
	if req.Nombre != "" {
		input.Nombre = &req.Nombre
	}
	if req.Categoria != "" {
		cat := entity.ProductCategory(req.Categoria)
		input.Categoria = &cat
	}
	if req.Descripcion != "" {
		input.Descripcion = &req.Descripcion
	}
	if req.Precio > 0 {
		input.Precio = &req.Precio
	}
	if req.StockActual != nil {
		input.StockActual = req.StockActual
	}
	if req.StockMinimo > 0 {
		input.StockMinimo = &req.StockMinimo
	}

	product, err := h.productUsecase.UpdateProduct(c.Request.Context(), input)
	if err != nil {
		if err.Error() == "SKU already exists" {
			response.Error(c, http.StatusConflict, "Conflict", "SKU already exists")
			return
		}
		response.InternalError(c)
		return
	}

	response.JSON(c, http.StatusOK, productToResponse(*product))
}

// Delete handles DELETE /products/:id
func (h *ProductHandler) Delete(c *gin.Context) {
	productID, err := parseUintParam(c, "id")
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Bad Request", "Invalid product ID")
		return
	}

	if err := h.productUsecase.DeleteProduct(c.Request.Context(), productID); err != nil {
		response.NotFound(c, "Product not found")
		return
	}

	response.NoContent(c)
}

// GetLowStock handles GET /products/low-stock (admin only)
func (h *ProductHandler) GetLowStock(c *gin.Context) {
	products, err := h.productUsecase.GetLowStockProducts(c.Request.Context())
	if err != nil {
		response.InternalError(c)
		return
	}

	responses := make([]dto.ProductResponse, len(products))
	for i, p := range products {
		responses[i] = productToResponse(p)
	}

	response.JSON(c, http.StatusOK, responses)
}

// UpdateStock handles PATCH /products/:id/stock
func (h *ProductHandler) UpdateStock(c *gin.Context) {
	productID, err := parseUintParam(c, "id")
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Bad Request", "Invalid product ID")
		return
	}

	var req dto.UpdateStockRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Validation(c, extractValidationErrors(err))
		return
	}

	if err := h.productUsecase.UpdateStock(c.Request.Context(), usecase.UpdateStockInput{
		ProductID: productID,
		Cantidad:  req.Cantidad,
	}); err != nil {
		if err.Error() == "insufficient stock" {
			response.Error(c, http.StatusBadRequest, "Bad Request", "Insufficient stock")
			return
		}
		response.InternalError(c)
		return
	}

	response.JSON(c, http.StatusOK, gin.H{"message": "Stock updated successfully"})
}

// productToResponse converts an entity.Product to a DTO response.
func productToResponse(p entity.Product) dto.ProductResponse {
	return dto.ProductResponse{
		ID:          p.ID,
		SKU:         p.SKU,
		Nombre:      p.Nombre,
		Categoria:   string(p.Categoria),
		Descripcion: p.Descripcion,
		Precio:      p.Precio,
		StockActual: p.StockActual,
		StockMinimo: p.StockMinimo,
		IsActive:    p.IsActive,
		CreatedAt:   p.CreatedAt.Format("2006-01-02T15:04:05Z"),
		UpdatedAt:   p.UpdatedAt.Format("2006-01-02T15:04:05Z"),
	}
}
