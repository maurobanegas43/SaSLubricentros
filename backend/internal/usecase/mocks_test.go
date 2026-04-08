package usecase

import (
	"context"

	"github.com/lubricentros/api/internal/domain/entity"
	"github.com/lubricentros/api/internal/domain/errors"
)

// =============================================================================
// Mock Implementations for Testing
// =============================================================================

// mockUserRepo implements domainrepo.UserRepository
type mockUserRepoVehicleTest struct {
	users map[uint]*entity.User
}

func newMockUserRepoVehicleTest() *mockUserRepoVehicleTest {
	return &mockUserRepoVehicleTest{
		users: make(map[uint]*entity.User),
	}
}

func (m *mockUserRepoVehicleTest) Create(ctx context.Context, user *entity.User) error {
	user.ID = uint(len(m.users) + 1)
	m.users[user.ID] = user
	return nil
}

func (m *mockUserRepoVehicleTest) GetByID(ctx context.Context, id uint) (*entity.User, error) {
	if user, ok := m.users[id]; ok {
		return user, nil
	}
	return nil, nil
}

func (m *mockUserRepoVehicleTest) GetByEmail(ctx context.Context, email string) (*entity.User, error) {
	for _, user := range m.users {
		if user.Email == email {
			return user, nil
		}
	}
	return nil, nil
}

func (m *mockUserRepoVehicleTest) Update(ctx context.Context, user *entity.User) error {
	if existing, ok := m.users[user.ID]; ok {
		existing.PasswordHash = user.PasswordHash
		existing.Name = user.Name
		existing.Phone = user.Phone
		return nil
	}
	return nil
}

func (m *mockUserRepoVehicleTest) Deactivate(ctx context.Context, id uint) error {
	if user, ok := m.users[id]; ok {
		user.IsActive = false
	}
	return nil
}

func (m *mockUserRepoVehicleTest) List(ctx context.Context, offset, limit int) ([]entity.User, error) {
	var result []entity.User
	for _, user := range m.users {
		result = append(result, *user)
	}
	return result, nil
}

func (m *mockUserRepoVehicleTest) Count(ctx context.Context) (int64, error) {
	return int64(len(m.users)), nil
}

// mockVehicleRepo implements domainrepo.VehicleRepository
type mockVehicleRepoVehicleTest struct {
	vehicles map[uint]*entity.Vehicle
	nextID   uint
}

func newMockVehicleRepoVehicleTest() *mockVehicleRepoVehicleTest {
	return &mockVehicleRepoVehicleTest{
		vehicles: make(map[uint]*entity.Vehicle),
		nextID:   1,
	}
}

func (m *mockVehicleRepoVehicleTest) Create(ctx context.Context, v *entity.Vehicle) error {
	v.ID = m.nextID
	m.nextID++
	m.vehicles[v.ID] = v
	return nil
}

func (m *mockVehicleRepoVehicleTest) GetByID(ctx context.Context, id uint) (*entity.Vehicle, error) {
	if v, ok := m.vehicles[id]; ok {
		return v, nil
	}
	return nil, errors.ErrNotFound
}

func (m *mockVehicleRepoVehicleTest) GetByUserID(ctx context.Context, userID uint, offset, limit int) ([]entity.Vehicle, error) {
	var result []entity.Vehicle
	for _, v := range m.vehicles {
		if v.UserID == userID {
			result = append(result, *v)
		}
	}
	// Simple pagination
	if offset > len(result) {
		return []entity.Vehicle{}, nil
	}
	end := offset + limit
	if end > len(result) {
		end = len(result)
	}
	if offset >= end {
		return []entity.Vehicle{}, nil
	}
	return result[offset:end], nil
}

func (m *mockVehicleRepoVehicleTest) Update(ctx context.Context, v *entity.Vehicle) error {
	if _, ok := m.vehicles[v.ID]; !ok {
		return errors.ErrNotFound
	}
	m.vehicles[v.ID] = v
	return nil
}

func (m *mockVehicleRepoVehicleTest) Delete(ctx context.Context, id uint) error {
	if _, ok := m.vehicles[id]; !ok {
		return errors.ErrNotFound
	}
	delete(m.vehicles, id)
	return nil
}

func (m *mockVehicleRepoVehicleTest) CountByUserID(ctx context.Context, userID uint) (int64, error) {
	var count int64
	for _, v := range m.vehicles {
		if v.UserID == userID {
			count++
		}
	}
	return count, nil
}

// mockServiceRecordRepo implements domainrepo.ServiceRecordRepository
type mockServiceRecordRepoVehicleTest struct {
	services map[uint]*entity.ServiceRecord
	nextID   uint
}

func newMockServiceRecordRepoVehicleTest() *mockServiceRecordRepoVehicleTest {
	return &mockServiceRecordRepoVehicleTest{
		services: make(map[uint]*entity.ServiceRecord),
		nextID:   1,
	}
}

func (m *mockServiceRecordRepoVehicleTest) Create(ctx context.Context, s *entity.ServiceRecord) error {
	s.ID = m.nextID
	m.nextID++
	m.services[s.ID] = s
	return nil
}

func (m *mockServiceRecordRepoVehicleTest) GetByID(ctx context.Context, id uint) (*entity.ServiceRecord, error) {
	if s, ok := m.services[id]; ok {
		return s, nil
	}
	return nil, errors.ErrNotFound
}

func (m *mockServiceRecordRepoVehicleTest) GetByVehicleID(ctx context.Context, vehicleID uint, offset, limit int) ([]entity.ServiceRecord, error) {
	var result []entity.ServiceRecord
	for _, s := range m.services {
		if s.VehicleID == vehicleID {
			result = append(result, *s)
		}
	}
	return result, nil
}

func (m *mockServiceRecordRepoVehicleTest) GetLastByVehicleID(ctx context.Context, vehicleID uint) (*entity.ServiceRecord, error) {
	var last *entity.ServiceRecord
	for _, s := range m.services {
		if s.VehicleID == vehicleID {
			if last == nil || s.CreatedAt.After(last.CreatedAt) {
				last = s
			}
		}
	}
	return last, nil
}

func (m *mockServiceRecordRepoVehicleTest) CountByVehicleID(ctx context.Context, vehicleID uint) (int64, error) {
	var count int64
	for _, s := range m.services {
		if s.VehicleID == vehicleID {
			count++
		}
	}
	return count, nil
}

// mockVehicleTransferRepo implements domainrepo.VehicleTransferRepository
type mockVehicleTransferRepoVehicleTest struct {
	transfers map[uint]*entity.VehicleTransfer
	nextID    uint
}

func newMockVehicleTransferRepoVehicleTest() *mockVehicleTransferRepoVehicleTest {
	return &mockVehicleTransferRepoVehicleTest{
		transfers: make(map[uint]*entity.VehicleTransfer),
		nextID:    1,
	}
}

func (m *mockVehicleTransferRepoVehicleTest) Create(ctx context.Context, t *entity.VehicleTransfer) error {
	t.ID = m.nextID
	m.nextID++
	m.transfers[t.ID] = t
	return nil
}

func (m *mockVehicleTransferRepoVehicleTest) GetByID(ctx context.Context, id uint) (*entity.VehicleTransfer, error) {
	if t, ok := m.transfers[id]; ok {
		return t, nil
	}
	return nil, errors.ErrNotFound
}

func (m *mockVehicleTransferRepoVehicleTest) GetByVehicleID(ctx context.Context, vehicleID uint) ([]entity.VehicleTransfer, error) {
	var result []entity.VehicleTransfer
	for _, t := range m.transfers {
		if t.VehicleID == vehicleID {
			result = append(result, *t)
		}
	}
	return result, nil
}

func (m *mockVehicleTransferRepoVehicleTest) GetPendingByVehicleID(ctx context.Context, vehicleID uint) (*entity.VehicleTransfer, error) {
	for _, t := range m.transfers {
		if t.VehicleID == vehicleID && t.Status == "requested" {
			return t, nil
		}
	}
	return nil, nil
}

func (m *mockVehicleTransferRepoVehicleTest) UpdateStatus(ctx context.Context, id uint, status string) error {
	if t, ok := m.transfers[id]; ok {
		t.Status = status
		return nil
	}
	return errors.ErrNotFound
}
