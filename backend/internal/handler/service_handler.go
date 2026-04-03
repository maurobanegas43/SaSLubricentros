package handler

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/lubricentros/api/internal/domain/entity"
	"github.com/lubricentros/api/internal/dto"
	"github.com/lubricentros/api/internal/middleware"
	"github.com/lubricentros/api/internal/usecase"
	"github.com/lubricentros/api/pkg/response"
)

// ServiceHandler handles service record HTTP requests.
type ServiceHandler struct {
	serviceUsecase *usecase.ServiceUsecase
}

// NewServiceHandler creates a new service handler.
func NewServiceHandler(serviceUsecase *usecase.ServiceUsecase) *ServiceHandler {
	return &ServiceHandler{serviceUsecase: serviceUsecase}
}

// Create handles POST /services (admin only)
func (h *ServiceHandler) Create(c *gin.Context) {
	userID := middleware.GetUserID(c)

	var req dto.CreateServiceRecordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Validation(c, extractValidationErrors(err))
		return
	}

	fecha, err := time.Parse(time.RFC3339, req.Fecha)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Bad Request", "Invalid date format. Use RFC3339")
		return
	}

	tipoAceite := entity.OilType(req.TipoAceite)

	record, err := h.serviceUsecase.CreateService(c.Request.Context(), usecase.CreateServiceInput{
		VehicleID:        req.VehicleID,
		AppointmentID:    req.AppointmentID,
		Fecha:            fecha,
		Km:               req.Km,
		TipoAceite:       tipoAceite,
		MarcaAceite:      req.MarcaAceite,
		CostoTotal:       req.CostoTotal,
		Observaciones:    req.Observaciones,
		ProximoServiceKm: req.ProximoServiceKm,
		CreatedBy:        userID,
	})
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Bad Request", err.Error())
		return
	}

	response.Created(c, serviceRecordToResponse(*record))
}

// GetByVehicleID handles GET /services/vehicle/:vehicleId
func (h *ServiceHandler) GetByVehicleID(c *gin.Context) {
	userID := middleware.GetUserID(c)
	vehicleID, err := parseUintParam(c, "vehicleId")
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Bad Request", "Invalid vehicle ID")
		return
	}

	page, limit := parsePagination(c)
	offset := (page - 1) * limit

	records, err := h.serviceUsecase.GetServiceByVehicleID(c.Request.Context(), vehicleID, userID, offset, limit)
	if err != nil {
		response.NotFound(c, "Vehicle not found or access denied")
		return
	}

	total, err := h.serviceUsecase.CountServicesByVehicle(c.Request.Context(), vehicleID)
	if err != nil {
		response.InternalError(c)
		return
	}

	responses := make([]dto.ServiceRecordResponse, len(records))
	for i, r := range records {
		responses[i] = serviceRecordToResponse(r)
	}

	response.Paginated(c, responses, total, offset, limit)
}

// serviceRecordToResponse converts an entity.ServiceRecord to a DTO response.
func serviceRecordToResponse(r entity.ServiceRecord) dto.ServiceRecordResponse {
	return dto.ServiceRecordResponse{
		ID:               r.ID,
		VehicleID:        r.VehicleID,
		AppointmentID:    r.AppointmentID,
		Fecha:            r.Fecha.Format("2006-01-02T15:04:05Z"),
		Km:               r.Km,
		TipoAceite:       string(r.TipoAceite),
		MarcaAceite:      r.MarcaAceite,
		CostoTotal:       r.CostoTotal,
		Observaciones:    r.Observaciones,
		ProximoServiceKm: r.ProximoServiceKm,
		CreatedBy:        r.CreatedBy,
		CreatedAt:        r.CreatedAt.Format("2006-01-02T15:04:05Z"),
	}
}
