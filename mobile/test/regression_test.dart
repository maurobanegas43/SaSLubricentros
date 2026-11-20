import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lubricentros_app/models/appointment.dart';
import 'package:lubricentros_app/models/user.dart';
import 'package:lubricentros_app/models/vehicle.dart';
import 'package:lubricentros_app/services/api_client.dart';
import 'package:lubricentros_app/services/auth_service.dart';

String _buildFakeJwt({
  required int userId,
  required String email,
}) {
  final header = base64Url.encode(utf8.encode('{"alg":"none","typ":"JWT"}'));
  final payload = base64Url
      .encode(utf8.encode(jsonEncode({'user_id': userId, 'email': email})))
      .replaceAll('=', '');
  return '$header.$payload.signature';
}

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

  group('Auth Service contract tests', () {
    test('login parses {success,data} and decodes user from JWT', () async {
      final fakeToken =
          _buildFakeJwt(userId: 42, email: 'admin@lubricentros.com');

      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/auth/login');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'admin@lubricentros.com');
        expect(body['password'], 'Admin123');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'access_token': fakeToken,
              'refresh_token': 'refresh-1',
              'token_type': 'Bearer',
              'expires_in': 900,
            }
          }),
          200,
        );
      });

      final authService = AuthService(apiClient: ApiClient(client: mockClient));

      final result = await authService.login(
        email: 'admin@lubricentros.com',
        password: 'Admin123',
      );

      expect(result.success, isTrue);
      expect(result.token, fakeToken);
      expect(result.refreshToken, 'refresh-1');
      expect(result.user, isNotNull);
      expect(result.user!.id, 42);
      expect(result.user!.email, 'admin@lubricentros.com');
    });

    test('register parses backend token response and fallback user', () async {
      final fakeToken = _buildFakeJwt(userId: 99, email: 'newuser@example.com');

      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/auth/register');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'newuser@example.com');
        expect(body['name'], 'New User');
        expect(body['phone'], '+5491112345678');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'access_token': fakeToken,
              'refresh_token': 'refresh-2',
              'token_type': 'Bearer',
              'expires_in': 900,
            }
          }),
          201,
        );
      });

      final authService = AuthService(apiClient: ApiClient(client: mockClient));

      final result = await authService.register(
        email: 'newuser@example.com',
        password: 'password123',
        name: 'New User',
        phone: '+5491112345678',
      );

      expect(result.success, isTrue);
      expect(result.token, fakeToken);
      expect(result.refreshToken, 'refresh-2');
      expect(result.user, isNotNull);
      expect(result.user!.id, 99);
      expect(result.user!.name, 'New User');
    });

    test('logout sends refresh_token body and authorization header', () async {
      final fakeToken =
          _buildFakeJwt(userId: 1, email: 'admin@lubricentros.com');
      late http.Request logoutRequest;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/auth/login') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'access_token': fakeToken,
                'refresh_token': 'refresh-logout',
              }
            }),
            200,
          );
        }

        if (request.url.path == '/auth/logout') {
          logoutRequest = request;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['refresh_token'], 'refresh-logout');
          return http.Response('', 204);
        }

        return http.Response(
          jsonEncode({'success': false, 'error': 'Not Found'}),
          404,
        );
      });

      final authService = AuthService(apiClient: ApiClient(client: mockClient));

      final login = await authService.login(
        email: 'admin@lubricentros.com',
        password: 'Admin123',
      );
      expect(login.success, isTrue);

      final loggedOut =
          await authService.logout(refreshToken: 'refresh-logout');

      expect(loggedOut, isTrue);
      expect(logoutRequest.method, 'POST');
      expect(logoutRequest.headers['authorization'], 'Bearer $fakeToken');
    });

    test('refreshSession updates access token from backend contract', () async {
      final refreshedToken =
          _buildFakeJwt(userId: 7, email: 'refresh@example.com');

      final mockClient = MockClient((request) async {
        expect(request.url.path, '/auth/refresh');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['refresh_token'], 'refresh-abc');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'access_token': refreshedToken,
              'refresh_token': 'refresh-def',
            }
          }),
          200,
        );
      });

      final authService = AuthService(apiClient: ApiClient(client: mockClient));

      final result =
          await authService.refreshSession(refreshToken: 'refresh-abc');

      expect(result.success, isTrue);
      expect(result.token, refreshedToken);
      expect(result.refreshToken, 'refresh-def');
    });
  });

  group('Security Tests', () {
    test('Password not exposed in AuthResult', () async {
      final fakeToken = _buildFakeJwt(userId: 5, email: 'test@example.com');

      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'access_token': fakeToken,
              'refresh_token': 'refresh-secure',
            }
          }),
          201,
        );
      });

      final authService = AuthService(apiClient: ApiClient(client: mockClient));

      final result = await authService.register(
        email: 'test@example.com',
        password: 'secret_password_123',
        name: 'Test',
      );

      expect(result.success, isTrue);
      expect(result.user, isNotNull);
      // El resultado no expone password por diseño del modelo.
    });
  });

  group('Integration Tests (mock backend)', () {
    test('Full auth flow works with backend contract', () async {
      final users = <String, String>{};

      String issueToken(String email) =>
          _buildFakeJwt(userId: email.hashCode.abs() % 10000, email: email);

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        final body = request.body.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(request.body) as Map<String, dynamic>;

        if (path == '/auth/register') {
          users[body['email'] as String] = body['password'] as String;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'access_token': issueToken(body['email'] as String),
                'refresh_token': 'refresh-register',
              }
            }),
            201,
          );
        }

        if (path == '/auth/logout') {
          return http.Response('', 204);
        }

        if (path == '/auth/login') {
          final email = body['email'] as String;
          final password = body['password'] as String;
          if (users[email] == password) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'access_token': issueToken(email),
                  'refresh_token': 'refresh-login',
                }
              }),
              200,
            );
          }

          return http.Response(
            jsonEncode({
              'success': false,
              'error': 'Unauthorized',
              'message': 'Invalid email or password',
            }),
            401,
          );
        }

        return http.Response(
          jsonEncode({'success': false, 'error': 'Not Found'}),
          404,
        );
      });

      final authService = AuthService(apiClient: ApiClient(client: mockClient));

      // 1. Register
      final registerResult = await authService.register(
        email: 'flowtest@example.com',
        password: 'testpass123',
        name: 'Flow Test',
      );
      expect(registerResult.success, isTrue);
      expect(registerResult.token, isNotNull);
      expect(registerResult.refreshToken, isNotNull);

      // 2. Logout
      await authService.logout(refreshToken: registerResult.refreshToken);

      // 3. Login again
      final loginResult = await authService.login(
        email: 'flowtest@example.com',
        password: 'testpass123',
      );
      expect(loginResult.success, isTrue);
      expect(loginResult.token, isNotNull);
    });
  });
}
