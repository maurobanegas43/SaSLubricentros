package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/lubricentros/api/internal/domain/entity"
	"github.com/lubricentros/api/internal/dto"
	"github.com/lubricentros/api/internal/middleware"
	"github.com/lubricentros/api/internal/repository"
	"github.com/lubricentros/api/internal/usecase"
	"github.com/lubricentros/api/pkg/response"
)

// VehicleHandler handles vehicle HTTP requests.
type VehicleHandler struct {
	vehicleUsecase *usecase.VehicleUsecase
}

// NewVehicleHandler creates a new vehicle handler.
func NewVehicleHandler(vehicleUsecase *usecase.VehicleUsecase) *VehicleHandler {
	return &VehicleHandler{vehicleUsecase: vehicleUsecase}
}

// List handles GET /vehicles
func (h *VehicleHandler) List(c *gin.Context) {
	userID := middleware.GetUserID(c)
	page, limit := parsePagination(c)
	offset := (page - 1) * limit

	vehicles, err := h.vehicleUsecase.ListByUser(c.Request.Context(), userID, offset, limit)
	if err != nil {
		response.InternalError(c)
		return
	}

	total, err := h.vehicleUsecase.CountByUser(c.Request.Context(), userID)
	if err != nil {
		response.InternalError(c)
		return
	}

	// Convert to response DTOs
	responses := make([]dto.VehicleResponse, len(vehicles))
	for i, v := range vehicles {
		responses[i] = vehicleToResponse(v)
	}

	response.Paginated(c, responses, total, offset, limit)
}

// GetByID handles GET /vehicles/:id
func (h *VehicleHandler) GetByID(c *gin.Context) {
	userID := middleware.GetUserID(c)
	vehicleID, err := parseUintParam(c, "id")
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Bad Request", "Invalid vehicle ID")
		return
	}

	vehicle, err := h.vehicleUsecase.GetVehicleByID(c.Request.Context(), vehicleID, userID)
	if err != nil {
		response.NotFound(c, "Vehicle not found")
		return
	}

	response.JSON(c, http.StatusOK, vehicleToResponse(*vehicle))
}

// Create handles POST /vehicles
func (h *VehicleHandler) Create(c *gin.Context) {
	userID := middleware.GetUserID(c)

	var req dto.CreateVehicleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Validation(c, extractValidationErrors(err))
		return
	}

	vehicle, err := h.vehicleUsecase.CreateVehicle(c.Request.Context(), usecase.CreateVehicleInput{
		UserID:   userID,
		Patente:  req.Patente,
		Marca:    req.Marca,
		Modelo:   req.Modelo,
		Anio:     req.Anio,
		Motor:    req.Motor,
		KmActual: req.KmActual,
		Color:    req.Color,
	})
	if err != nil {
		if err == repository.ErrInvalidInput {
			response.Error(c, http.StatusBadRequest, "Bad Request", "Invalid input data")
			return
		}
		response.InternalError(c)
		return
	}

	response.Created(c, vehicleToResponse(*vehicle))
}

// Update handles PUT /vehicles/:id
func (h *VehicleHandler) Update(c *gin.Context) {
	userID := middleware.GetUserID(c)
	vehicleID, err := parseUintParam(c, "id")
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Bad Request", "Invalid vehicle ID")
		return
	}

	var req dto.UpdateVehicleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Validation(c, extractValidationErrors(err))
		return
	}

	input := usecase.UpdateVehicleInput{
		VehicleID: vehicleID,
		UserID:    userID,
	}

	// Set optional fields
	if req.Patente != "" {
		input.Patente = &req.Patente
	}
	if req.Marca != "" {
		input.Marca = &req.Marca
	}
	if req.Modelo != "" {
		input.Modelo = &req.Modelo
	}
	if req.Anio != nil {
		input.Anio = req.Anio
	}
	if req.Motor != "" {
		input.Motor = &req.Motor
	}
	if req.KmActual != nil {
		input.KmActual = req.KmActual
	}
	if req.Color != "" {
		input.Color = &req.Color
	}

	vehicle, err := h.vehicleUsecase.UpdateVehicle(c.Request.Context(), input)
	if err != nil {
		if err == repository.ErrInvalidInput {
			response.Error(c, http.StatusBadRequest, "Bad Request", "Invalid input data")
			return
		}
		response.NotFound(c, "Vehicle not found")
		return
	}

	response.JSON(c, http.StatusOK, vehicleToResponse(*vehicle))
}

// Delete handles DELETE /vehicles/:id
func (h *VehicleHandler) Delete(c *gin.Context) {
	userID := middleware.GetUserID(c)
	vehicleID, err := parseUintParam(c, "id")
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Bad Request", "Invalid vehicle ID")
		return
	}

	if err := h.vehicleUsecase.DeleteVehicle(c.Request.Context(), vehicleID, userID); err != nil {
		response.NotFound(c, "Vehicle not found")
		return
	}

	response.NoContent(c)
}

// GetReport handles GET /vehicles/:id/report
func (h *VehicleHandler) GetReport(c *gin.Context) {
	userID := middleware.GetUserID(c)
	vehicleID, err := parseUintParam(c, "id")
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Bad Request", "Invalid vehicle ID")
		return
	}

	report, err := h.vehicleUsecase.GetVehicleReport(c.Request.Context(), vehicleID, userID)
	if err != nil {
		response.NotFound(c, "Vehicle not found")
		return
	}

	response.JSON(c, http.StatusOK, report)
}

// vehicleToResponse converts an entity.Vehicle to a DTO response.
func vehicleToResponse(v entity.Vehicle) dto.VehicleResponse {
	return dto.VehicleResponse{
		ID:        v.ID,
		UserID:    v.UserID,
		Patente:   v.Patente,
		Marca:     v.Marca,
		Modelo:    v.Modelo,
		Anio:      v.Anio,
		Motor:     v.Motor,
		KmActual:  v.KmActual,
		Color:     v.Color,
		CreatedAt: v.CreatedAt.Format("2006-01-02T15:04:05Z"),
		UpdatedAt: v.UpdatedAt.Format("2006-01-02T15:04:05Z"),
	}
}

// parsePagination extracts page and limit from query parameters.
func parsePagination(c *gin.Context) (page, limit int) {
	page = 1
	limit = 20

	if p := c.Query("page"); p != "" {
		if parsed, err := strconv.Atoi(p); err == nil && parsed > 0 {
			page = parsed
		}
	}

	if l := c.Query("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 {
			limit = parsed
			if limit > 100 {
				limit = 100
			}
		}
	}

	return page, limit
}

// parseUintParam extracts a uint from a URL parameter.
func parseUintParam(c *gin.Context, param string) (uint, error) {
	val := c.Param(param)
	if val == "" {
		return 0, nil
	}
	parsed, err := strconv.ParseUint(val, 10, 64)
	if err != nil {
		return 0, err
	}
	return uint(parsed), nil
}
