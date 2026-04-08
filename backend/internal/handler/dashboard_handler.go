package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/lubricentros/api/internal/dto"
	"github.com/lubricentros/api/internal/usecase"
	"github.com/lubricentros/api/pkg/response"
)

// DashboardHandler handles admin dashboard HTTP requests.
type DashboardHandler struct {
	dashboardUsecase *usecase.DashboardUsecase
}

// NewDashboardHandler creates a new dashboard handler.
func NewDashboardHandler(dashboardUsecase *usecase.DashboardUsecase) *DashboardHandler {
	return &DashboardHandler{dashboardUsecase: dashboardUsecase}
}

// GetStats handles GET /admin/dashboard/stats
func (h *DashboardHandler) GetStats(c *gin.Context) {
	stats, err := h.dashboardUsecase.GetDashboardStats(c.Request.Context())
	if err != nil {
		response.InternalError(c)
		return
	}

	response.JSON(c, http.StatusOK, dto.DashboardStatsResponse{
		TotalUsers:        stats.TotalUsers,
		TotalVehicles:     stats.TotalVehicles,
		TotalAppointments: stats.TotalAppointments,
		TotalServices:     stats.TotalServices,
		TotalRevenue:      stats.TotalRevenue,
		LowStockProducts:  stats.LowStockProducts,
	})
}

// GetLowStock handles GET /admin/dashboard/low-stock
func (h *DashboardHandler) GetLowStock(c *gin.Context) {
	products, err := h.dashboardUsecase.GetLowStockProducts(c.Request.Context())
	if err != nil {
		response.InternalError(c)
		return
	}

	responses := make([]dto.ProductResponse, len(products))
	for i, p := range products {
		responses[i] = dto.ProductResponse{
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

	response.JSON(c, http.StatusOK, responses)
}
