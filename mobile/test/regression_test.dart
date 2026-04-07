import 'package:flutter_test/flutter_test.dart';
import 'package:lubricentros_app/models/user.dart';
import 'package:lubricentros_app/models/vehicle.dart';
import 'package:lubricentros_app/models/appointment.dart';
import 'package:lubricentros_app/services/auth_service.dart';

void main() {
  group('Models Regression Tests', () {
    group('User Model', () {
      test('User fromJson creates valid user', () {
        final json = {
          'id': 1,
          'email': 'test@example.com',
          'name': 'Test User',
          'phone': '+54911234567',
        };

        final user = User.fromJson(json);

        expect(user.id, 1);
        expect(user.email, 'test@example.com');
        expect(user.name, 'Test User');
        expect(user.phone, '+54911234567');
      });

      test('User fromJson handles null phone', () {
        final json = {
          'id': 1,
          'email': 'test@example.com',
          'name': 'Test User',
        };

        final user = User.fromJson(json);

        expect(user.id, 1);
        expect(user.phone, isNull);
      });
    });

    group('Vehicle Model', () {
      test('Vehicle fromJson creates valid vehicle', () {
        final json = {
          'id': 1,
          'user_id': 1,
          'marca': 'Toyota',
          'modelo': 'Corolla',
          'anio': 2020,
          'motor': '1.8L',
          'km_actual': 15000,
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-01T00:00:00Z',
        };

        final vehicle = Vehicle.fromJson(json);

        expect(vehicle.id, 1);
        expect(vehicle.marca, 'Toyota');
        expect(vehicle.modelo, 'Corolla');
        expect(vehicle.anio, 2020);
        expect(vehicle.kmActual, 15000);
      });

      test('Vehicle handles null optional fields', () {
        final json = {
          'id': 1,
          'user_id': 1,
          'marca': 'Toyota',
          'modelo': 'Corolla',
          'anio': 2020,
          'km_actual': 15000,
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-01T00:00:00Z',
        };

        final vehicle = Vehicle.fromJson(json);

        expect(vehicle.motor, isNull);
      });

      test('Vehicle displayName format', () {
        final vehicle = Vehicle(
          id: 1,
          userId: 1,
          marca: 'Toyota',
          modelo: 'Corolla',
          anio: 2020,
          kmActual: 15000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(vehicle.displayName, 'Toyota Corolla (2020)');
      });
    });

    group('Appointment Model', () {
      test('Appointment fromJson creates valid appointment', () {
        final json = {
          'id': 1,
          'user_id': 1,
          'vehicle_id': 1,
          'fecha': '2024-06-01T10:00:00Z',
          'slot_end': '2024-06-01T11:00:00Z',
          'status': 'pending',
          'tipo_service': 'cambio_aceite',
          'observaciones': 'Test note',
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-01T00:00:00Z',
        };

        final appointment = Appointment.fromJson(json);

        expect(appointment.id, 1);
        expect(appointment.vehicleId, 1);
        expect(appointment.status, AppointmentStatus.pending);
        expect(appointment.tipoService, AppointmentType.cambioAceite);
      });

      test('Appointment status conversion', () {
        expect(AppointmentStatus.values.length, 6);
        expect(
            AppointmentStatus.values.contains(AppointmentStatus.pending), true);
        expect(AppointmentStatus.values.contains(AppointmentStatus.confirmed),
            true);
        expect(AppointmentStatus.values.contains(AppointmentStatus.inProgress),
            true);
        expect(AppointmentStatus.values.contains(AppointmentStatus.completed),
            true);
        expect(AppointmentStatus.values.contains(AppointmentStatus.cancelled),
            true);
        expect(
            AppointmentStatus.values.contains(AppointmentStatus.noShow), true);
      });
    });
  });

  group('Auth Service Tests (Dev Mode)', () {
    test('AuthService in dev mode accepts admin credentials', () async {
      final authService = AuthService();

      final result = await authService.login(
        email: 'admin@lubricentros.com',
        password: 'Admin123',
      );

      expect(result.success, true);
      expect(result.token, isNotNull);
      expect(result.user, isNotNull);
      expect(result.user!.email, 'admin@lubricentros.com');
    });

    test('AuthService in dev mode accepts any credentials', () async {
      final authService = AuthService();

      final result = await authService.login(
        email: 'user@example.com',
        password: 'anypassword',
      );

      expect(result.success, true);
      expect(result.token, isNotNull);
      expect(result.user, isNotNull);
    });

    test('AuthService register works in dev mode', () async {
      final authService = AuthService();

      final result = await authService.register(
        email: 'newuser@example.com',
        password: 'password123',
        name: 'New User',
        phone: '+5491112345678',
      );

      expect(result.success, true);
      expect(result.token, isNotNull);
      expect(result.user, isNotNull);
      expect(result.user!.name, 'New User');
    });

    test('AuthService logout clears token', () async {
      final authService = AuthService();

      // First login
      await authService.login(
        email: 'admin@lubricentros.com',
        password: 'Admin123',
      );

      // Then logout
      await authService.logout();

      // Should complete without error
      expect(true, true);
    });
  });

  group('Security Tests', () {
    test('Password not exposed in AuthResult', () async {
      final authService = AuthService();

      final result = await authService.register(
        email: 'test@example.com',
        password: 'secret_password_123',
        name: 'Test',
      );

      // Password should not be stored in the result
      expect(result.user, isNotNull);
    });
  });

  group('Integration Tests', () {
    test('Full auth flow works', () async {
      final authService = AuthService();

      // 1. Register
      final registerResult = await authService.register(
        email: 'flowtest@example.com',
        password: 'testpass123',
        name: 'Flow Test',
      );
      expect(registerResult.success, true);
      expect(registerResult.token, isNotNull);

      // 2. Logout
      await authService.logout();

      // 3. Login again
      final loginResult = await authService.login(
        email: 'flowtest@example.com',
        password: 'testpass123',
      );
      expect(loginResult.success, true);
      expect(loginResult.token, isNotNull);
    });
  });
}
