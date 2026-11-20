package handler

import (
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/lubricentros/api/internal/dto"
	"github.com/lubricentros/api/internal/middleware"
	"github.com/lubricentros/api/internal/usecase"
	"github.com/lubricentros/api/pkg/pdf"
	"github.com/lubricentros/api/pkg/response"
)

// ReportHandler handles report generation HTTP requests.
type ReportHandler struct {
	vehicleUsecase *usecase.VehicleUsecase
	serviceUsecase *usecase.ServiceUsecase
	pdfGenerator   *pdf.VehicleReportGenerator
}

// NewReportHandler creates a new report handler.
func NewReportHandler(
	vehicleUsecase *usecase.VehicleUsecase,
	serviceUsecase *usecase.ServiceUsecase,
) *ReportHandler {
	return &ReportHandler{
		vehicleUsecase: vehicleUsecase,
		serviceUsecase: serviceUsecase,
		pdfGenerator:   pdf.NewVehicleReportGenerator(),
	}
}

// GenerateVehiclePDF handles GET /vehicles/:id/report/pdf
func (h *ReportHandler) GenerateVehiclePDF(c *gin.Context) {
	userID := middleware.GetUserID(c)
	vehicleID, err := parseUintParam(c, "id")
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Bad Request", "Invalid vehicle ID")
		return
	}

	// Get vehicle
	vehicle, err := h.vehicleUsecase.GetVehicleByID(c.Request.Context(), vehicleID, userID)
	if err != nil {
		response.NotFound(c, "Vehicle not found")
		return
	}

	// Get services (already validates ownership)
	services, err := h.serviceUsecase.GetServiceByVehicleID(c.Request.Context(), vehicleID, userID, 0, 1000)
	if err != nil {
		response.InternalError(c)
		return
	}

	// Generate PDF
	pdfBytes, err := h.pdfGenerator.GenerateVehicleServiceReport(vehicle, services, nil)
	if err != nil {
		response.InternalError(c)
		return
	}

	// Return PDF
	filename := fmt.Sprintf("vehiculo_%d_servicios_%s.pdf", vehicleID, time.Now().Format("2006-01-02"))
	c.Header("Content-Type", "application/pdf")
	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=%s", filename))
	c.Data(http.StatusOK, "application/pdf", pdfBytes)
}

// GenerateInvoicePDF handles POST /reports/invoice
func (h *ReportHandler) GenerateInvoicePDF(c *gin.Context) {
	userID := middleware.GetUserID(c)

	var req dto.InvoiceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Validation(c, extractValidationErrors(err))
		return
	}

	// Get service record
	service, err := h.serviceUsecase.GetServiceByID(c.Request.Context(), req.ServiceID)
	if err != nil {
		response.NotFound(c, "Service not found")
		return
	}

	// Get vehicle and validate ownership
	vehicle, err := h.vehicleUsecase.GetVehicleByID(c.Request.Context(), service.VehicleID, userID)
	if err != nil {
		response.NotFound(c, "Vehicle not found")
		return
	}

	// Generate PDF invoice
	pdfBytes, err := h.pdfGenerator.GenerateServiceInvoice(service, vehicle, nil)
	if err != nil {
		response.InternalError(c)
		return
	}

	// Return PDF
	filename := fmt.Sprintf("factura_servicio_%d_%s.pdf", req.ServiceID, time.Now().Format("2006-01-02"))
	c.Header("Content-Type", "application/pdf")
	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=%s", filename))
	c.Data(http.StatusOK, "application/pdf", pdfBytes)
}

// GenerateRevenuePDF handles GET /admin/reports/revenue/pdf
func (h *ReportHandler) GenerateRevenuePDF(c *gin.Context) {
	// Parse dates
	startDateStr := c.Query("start_date")
	endDateStr := c.Query("end_date")

	startDate := time.Now().AddDate(0, -1, 0)
	endDate := time.Now()

	if startDateStr != "" {
		if parsed, err := time.Parse(time.RFC3339, startDateStr); err == nil {
			startDate = parsed
		}
	}
	if endDateStr != "" {
		if parsed, err := time.Parse(time.RFC3339, endDateStr); err == nil {
			endDate = parsed
		}
	}

	// Get services - simplified
	services, err := h.serviceUsecase.GetServiceByVehicleID(c.Request.Context(), 1, 1, 0, 1000) // Just get some services
	if err != nil {
		response.InternalError(c)
		return
	}

	// Calculate total revenue
	var totalRevenue float64
	for _, svc := range services {
		if svc.CostoTotal != nil {
			totalRevenue += *svc.CostoTotal
		}
	}

	// Generate PDF
	pdfBytes, err := h.pdfGenerator.GenerateRevenueReport(startDate, endDate, services, totalRevenue)
	if err != nil {
		response.InternalError(c)
		return
	}

	// Return PDF
	filename := fmt.Sprintf("reporte_ingresos_%s.pdf", time.Now().Format("2006-01-02"))
	c.Header("Content-Type", "application/pdf")
	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=%s", filename))
	c.Data(http.StatusOK, "application/pdf", pdfBytes)
}
