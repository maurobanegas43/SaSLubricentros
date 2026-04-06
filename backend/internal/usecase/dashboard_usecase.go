package usecase

import (
	"context"
	"fmt"

	"github.com/lubricentros/api/internal/domain/entity"
	domainrepo "github.com/lubricentros/api/internal/domain/repository"
)

// DashboardUsecase handles admin dashboard business logic.
type DashboardUsecase struct {
	userRepo        domainrepo.UserRepository
	vehicleRepo     domainrepo.VehicleRepository
	appointmentRepo domainrepo.AppointmentRepository
	serviceRepo     domainrepo.ServiceRecordRepository
	productRepo     domainrepo.ProductRepository
}

// NewDashboardUsecase creates a new dashboard usecase.
func NewDashboardUsecase(
	userRepo domainrepo.UserRepository,
	vehicleRepo domainrepo.VehicleRepository,
	appointmentRepo domainrepo.AppointmentRepository,
	serviceRepo domainrepo.ServiceRecordRepository,
	productRepo domainrepo.ProductRepository,
) *DashboardUsecase {
	return &DashboardUsecase{
		userRepo:        userRepo,
		vehicleRepo:     vehicleRepo,
		appointmentRepo: appointmentRepo,
		serviceRepo:     serviceRepo,
		productRepo:     productRepo,
	}
}

// GetDashboardStats returns overall statistics for the dashboard.
func (uc *DashboardUsecase) GetDashboardStats(ctx context.Context) (*DashboardStats, error) {
	// Get user stats
	totalUsers, err := uc.userRepo.Count(ctx)
	if err != nil {
		return nil, fmt.Errorf("dashboard stats: count users: %w", err)
	}

	// Get low stock products
	lowStockProducts, err := uc.productRepo.ListLowStock(ctx)
	if err != nil {
		return nil, fmt.Errorf("dashboard stats: low stock products: %w", err)
	}

	return &DashboardStats{
		TotalUsers:       totalUsers,
		LowStockProducts: int64(len(lowStockProducts)),
	}, nil
}

// DashboardStats holds dashboard statistics.
type DashboardStats struct {
	TotalUsers        int64   `json:"total_users"`
	TotalVehicles     int64   `json:"total_vehicles"`
	TotalAppointments int64   `json:"total_appointments"`
	TotalServices     int64   `json:"total_services"`
	TotalRevenue      float64 `json:"total_revenue"`
	LowStockProducts  int64   `json:"low_stock_products"`
}

// GetLowStockProducts returns products with stock below minimum.
func (uc *DashboardUsecase) GetLowStockProducts(ctx context.Context) ([]entity.Product, error) {
	return uc.productRepo.ListLowStock(ctx)
}
