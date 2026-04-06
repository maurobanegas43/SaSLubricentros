package usecase

import (
	"context"
	"testing"
	"time"

	"github.com/lubricentros/api/internal/domain/entity"
	"github.com/lubricentros/api/internal/domain/repository"
	"github.com/stretchr/testify/assert"
)

// MockServiceRecordRepository is a mock implementation for testing.
type MockServiceRecordRepository struct {
	records map[uint]*entity.ServiceRecord
	nextID  uint
}

func NewMockServiceRecordRepository() *MockServiceRecordRepository {
	return &MockServiceRecordRepository{
		records: make(map[uint]*entity.ServiceRecord),
		nextID:  1,
	}
}

func (m *MockServiceRecordRepository) Create(ctx context.Context, record *entity.ServiceRecord) error {
	record.ID = m.nextID
	m.nextID++
	record.CreatedAt = time.Now()
	m.records[record.ID] = record
	return nil
}

func (m *MockServiceRecordRepository) GetByID(ctx context.Context, id uint) (*entity.ServiceRecord, error) {
	if r, ok := m.records[id]; ok {
		return r, nil
	}
	return nil, repository.ErrNotFound
}

func (m *MockServiceRecordRepository) GetByVehicleID(ctx context.Context, vehicleID uint, offset, limit int) ([]entity.ServiceRecord, error) {
	var result []entity.ServiceRecord
	for _, r := range m.records {
		if r.VehicleID == vehicleID {
			result = append(result, *r)
		}
	}
	return result, nil
}

func (m *MockServiceRecordRepository) GetLastByVehicleID(ctx context.Context, vehicleID uint) (*entity.ServiceRecord, error) {
	for _, r := range m.records {
		if r.VehicleID == vehicleID {
			return r, nil
		}
	}
	return nil, repository.ErrNotFound
}

func (m *MockServiceRecordRepository) CountByVehicleID(ctx context.Context, vehicleID uint) (int64, error) {
	count := int64(0)
	for _, r := range m.records {
		if r.VehicleID == vehicleID {
			count++
		}
	}
	return count, nil
}

// MockServiceAddendumRepository is a mock implementation for testing.
type MockServiceAddendumRepository struct {
	addendums map[uint]*entity.ServiceAddendum
	nextID    uint
}

func NewMockServiceAddendumRepository() *MockServiceAddendumRepository {
	return &MockServiceAddendumRepository{
		addendums: make(map[uint]*entity.ServiceAddendum),
		nextID:    1,
	}
}

func (m *MockServiceAddendumRepository) Create(ctx context.Context, addendum *entity.ServiceAddendum) error {
	addendum.ID = m.nextID
	m.nextID++
	addendum.CreatedAt = time.Now()
	m.addendums[addendum.ID] = addendum
	return nil
}

func (m *MockServiceAddendumRepository) GetByServiceID(ctx context.Context, serviceID uint) ([]entity.ServiceAddendum, error) {
	var result []entity.ServiceAddendum
	for _, a := range m.addendums {
		if a.ServiceID == serviceID {
			result = append(result, *a)
		}
	}
	return result, nil
}

// MockVehicleRepository is a mock implementation for testing.
type MockVehicleRepository struct {
	vehicles map[uint]*entity.Vehicle
	nextID   uint
}

func NewMockVehicleRepository() *MockVehicleRepository {
	return &MockVehicleRepository{
		vehicles: make(map[uint]*entity.Vehicle),
		nextID:   1,
	}
}

func (m *MockVehicleRepository) Create(ctx context.Context, vehicle *entity.Vehicle) error {
	vehicle.ID = m.nextID
	m.nextID++
	vehicle.CreatedAt = time.Now()
	vehicle.UpdatedAt = time.Now()
	m.vehicles[vehicle.ID] = vehicle
	return nil
}

func (m *MockVehicleRepository) GetByID(ctx context.Context, id uint) (*entity.Vehicle, error) {
	if v, ok := m.vehicles[id]; ok {
		return v, nil
	}
	return nil, repository.ErrNotFound
}

func (m *MockVehicleRepository) GetByUserID(ctx context.Context, userID uint, offset, limit int) ([]entity.Vehicle, error) {
	var result []entity.Vehicle
	for _, v := range m.vehicles {
		if v.UserID == userID {
			result = append(result, *v)
		}
	}
	return result, nil
}

func (m *MockVehicleRepository) Update(ctx context.Context, vehicle *entity.Vehicle) error {
	if _, ok := m.vehicles[vehicle.ID]; !ok {
		return repository.ErrNotFound
	}
	vehicle.UpdatedAt = time.Now()
	m.vehicles[vehicle.ID] = vehicle
	return nil
}

func (m *MockVehicleRepository) Delete(ctx context.Context, id uint) error {
	if _, ok := m.vehicles[id]; !ok {
		return repository.ErrNotFound
	}
	delete(m.vehicles, id)
	return nil
}

func (m *MockVehicleRepository) CountByUserID(ctx context.Context, userID uint) (int64, error) {
	count := int64(0)
	for _, v := range m.vehicles {
		if v.UserID == userID {
			count++
		}
	}
	return count, nil
}

func TestServiceUsecase_CreateAddendum(t *testing.T) {
	serviceRepo := NewMockServiceRecordRepository()
	addendumRepo := NewMockServiceAddendumRepository()
	vehicleRepo := NewMockVehicleRepository()

	// Create a vehicle first
	v, _ := vehicleRepo.Create(nil, &entity.Vehicle{
		UserID:   1,
		Marca:    "Toyota",
		Modelo:   "Corolla",
		Anio:     2020,
		KmActual: 10000,
	})

	// Create a service record
	svcRepo := NewMockServiceRecordRepository()
	svc, _ := svcRepo.Create(nil, &entity.ServiceRecord{
		VehicleID:   v.ID,
		Km:          10000,
		TipoAceite:  entity.OilTypeSintetico,
		MarcaAceite: "Shell",
	})

	uc := NewServiceUsecase(svcRepo, vehicleRepo, addendumRepo)

	addendum, err := uc.CreateAddendum(nil, CreateAddendumInput{
		ServiceID: svc.ID,
		FieldName: "Km",
		OldValue:  "10000",
		NewValue:  "10500",
		Reason:    "Corrección de kilometraje",
		CreatedBy: 1,
	})

	assert.NoError(t, err)
	assert.NotNil(t, addendum)
	assert.Equal(t, "Km", addendum.FieldName)
	assert.Equal(t, "10500", addendum.NewValue)
}

func TestServiceUsecase_CreateAddendum_ServiceNotFound(t *testing.T) {
	serviceRepo := NewMockServiceRecordRepository()
	addendumRepo := NewMockServiceAddendumRepository()
	vehicleRepo := NewMockVehicleRepository()

	uc := NewServiceUsecase(serviceRepo, vehicleRepo, addendumRepo)

	_, err := uc.CreateAddendum(nil, CreateAddendumInput{
		ServiceID: 999, // Non-existent
		FieldName: "Km",
		NewValue:  "10500",
		Reason:    "Test",
		CreatedBy: 1,
	})

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "service not found")
}

func TestServiceUsecase_CreateAddendum_InvalidInput(t *testing.T) {
	serviceRepo := NewMockServiceRecordRepository()
	addendumRepo := NewMockServiceAddendumRepository()
	vehicleRepo := NewMockVehicleRepository()

	uc := NewServiceUsecase(serviceRepo, vehicleRepo, addendumRepo)

	_, err := uc.CreateAddendum(nil, CreateAddendumInput{
		ServiceID: 1,
		FieldName: "", // Empty - invalid
		NewValue:  "10500",
		Reason:    "Test",
		CreatedBy: 1,
	})

	assert.Error(t, err)
	assert.Equal(t, repository.ErrInvalidInput, err)
}

func TestServiceUsecase_GetAddendumsByServiceID(t *testing.T) {
	serviceRepo := NewMockServiceRecordRepository()
	addendumRepo := NewMockServiceAddendumRepository()
	vehicleRepo := NewMockVehicleRepository()

	// Create service and addendums
	v, _ := vehicleRepo.Create(nil, &entity.Vehicle{
		UserID:   1,
		Marca:    "Toyota",
		Modelo:   "Corolla",
		Anio:     2020,
		KmActual: 10000,
	})

	svc, _ := serviceRepo.Create(nil, &entity.ServiceRecord{
		VehicleID:  v.ID,
		Km:         10000,
		TipoAceite: entity.OilTypeSintetico,
	})

	_ = addendumRepo.Create(nil, &entity.ServiceAddendum{
		ServiceID: svc.ID,
		FieldName: "Km",
		NewValue:  "10500",
		Reason:    "Test 1",
		CreatedBy: 1,
	})
	_ = addendumRepo.Create(nil, &entity.ServiceAddendum{
		ServiceID: svc.ID,
		FieldName: "Observaciones",
		NewValue:  "Added note",
		Reason:    "Test 2",
		CreatedBy: 1,
	})

	uc := NewServiceUsecase(serviceRepo, vehicleRepo, addendumRepo)

	addendums, err := uc.GetAddendumsByServiceID(nil, svc.ID)

	assert.NoError(t, err)
	assert.Len(t, addendums, 2)
}
