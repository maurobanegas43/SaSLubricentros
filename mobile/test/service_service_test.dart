import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lubricentros_app/models/appointment.dart';
import 'package:lubricentros_app/services/api_client.dart';
import 'package:lubricentros_app/services/service_service.dart';

void main() {
  group('ServiceService contract tests', () {
    late ServiceService serviceService;
    late List<http.Request> capturedRequests;

    setUp(() {
      capturedRequests = [];

      final mockClient = MockClient((request) async {
        capturedRequests.add(request);
        final path = request.url.path;

        if (path == '/services/vehicle/1' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 1,
                  'vehicle_id': 1,
                  'fecha': '2024-06-01T10:00:00Z',
                  'km': 50000,
                  'tipo_aceite': 'sintetico',
                  'observaciones': 'Cambio completo',
                  'created_at': '2024-06-01T10:00:00Z',
                },
                {
                  'id': 2,
                  'vehicle_id': 1,
                  'fecha': '2024-05-01T10:00:00Z',
                  'km': 47000,
                  'tipo_aceite': 'semi_sintetico',
                  'observaciones': 'Service anterior',
                  'created_at': '2024-05-01T10:00:00Z',
                },
              ],
              'meta': {
                'total': 2,
                'offset': 0,
                'limit': 20,
                'has_more': false,
              }
            }),
            200,
          );
        }

        if (path == '/services/1/addendums' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 10,
                  'service_id': 1,
                  'field_name': 'observaciones',
                  'old_value': 'Cambio completo',
                  'new_value': 'Cambio completo + filtro de aire',
                  'reason': 'Corrección técnica',
                  'created_at': '2024-06-01T11:00:00Z',
                }
              ]
            }),
            200,
          );
        }

        if (path == '/services/1/addendums' && request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['field_name'], 'observaciones');
          expect(body['new_value'], 'Test addendum');
          expect(body['reason'], 'Corrección desde aplicación móvil');

          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 11,
                'service_id': 1,
                'field_name': body['field_name'],
                'old_value': body['old_value'],
                'new_value': body['new_value'],
                'reason': body['reason'],
                'created_at': '2024-06-02T10:00:00Z',
              }
            }),
            201,
          );
        }

        return http.Response(
          jsonEncode({'success': false, 'error': 'Not Found'}),
          404,
        );
      });

      final apiClient = ApiClient(client: mockClient)..setToken('test-token');
      serviceService = ServiceService(apiClient: apiClient);
    });

    test('getServicesByVehicle parses backend envelope', () async {
      final services = await serviceService.getServicesByVehicle(1);

      expect(services, isNotEmpty);
      expect(services.length, 2);
      expect(services.first.tipoService, 'sintetico');
      expect(services.first.kmActual, 50000);

      final request = capturedRequests.first;
      expect(request.url.queryParameters['page'], '1');
      expect(request.url.queryParameters['limit'], '20');
      expect(request.headers['authorization'], 'Bearer test-token');
    });

    test('getLastService returns first service from paginated response',
        () async {
      final lastService = await serviceService.getLastService(1);

      expect(lastService, isNotNull);
      expect(lastService!.tipoService, 'sintetico');
    });

    test('getAddendums parses field-based addendum contract', () async {
      final addendums = await serviceService.getAddendums(1);

      expect(addendums, isNotEmpty);
      expect(addendums.first.description, contains('filtro de aire'));
      expect(addendums.first.serviceId, 1);
    });

    test('createAddendum sends required backend payload', () async {
      final addendum = await serviceService.createAddendum(1, 'Test addendum');

      expect(addendum, isNotNull);
      expect(addendum!.description, contains('Test addendum'));
      expect(addendum.serviceId, 1);

      final request = capturedRequests.last;
      expect(request.method, 'POST');
      expect(request.url.path, '/services/1/addendums');
      expect(request.headers['authorization'], 'Bearer test-token');
    });

    test('ServiceRecord fromJson parses current backend fields', () {
      final json = {
        'id': 1,
        'vehicle_id': 2,
        'fecha': '2024-06-01T10:00:00Z',
        'km': 50000,
        'tipo_aceite': 'sintetico',
        'observaciones': 'Test notes',
        'created_at': '2024-01-01T00:00:00Z',
      };

      final service = ServiceRecord.fromJson(json);

      expect(service.id, 1);
      expect(service.vehicleId, 2);
      expect(service.tipoService, 'sintetico');
      expect(service.kmActual, 50000);
      expect(service.oilType, 'sintetico');
      expect(service.observaciones, 'Test notes');
    });

    test('ServiceAddendum fromJson builds description from field changes', () {
      final json = {
        'id': 1,
        'service_id': 5,
        'field_name': 'observaciones',
        'old_value': 'Viejo',
        'new_value': 'Nuevo',
        'reason': 'Corrección',
        'created_at': '2024-01-01T00:00:00Z',
      };

      final addendum = ServiceAddendum.fromJson(json);

      expect(addendum.id, 1);
      expect(addendum.serviceId, 5);
      expect(addendum.description, contains('Nuevo'));
    });
  });

  group('AppointmentType Extension Tests', () {
    test('value returns correct string', () {
      expect(AppointmentType.cambioAceite.value, 'cambio_aceite');
      expect(AppointmentType.alineacion.value, 'alineacion');
      expect(AppointmentType.mecanicaLuces.value, 'mecanica_luces');
    });

    test('displayName returns user friendly name', () {
      expect(AppointmentType.cambioAceite.displayName, 'Cambio de Aceite');
      expect(AppointmentType.alineacion.displayName, 'Alineación');
      expect(AppointmentType.revisionGeneral.displayName, 'Revisión General');
    });

    test('fromString parses correctly', () {
      expect(AppointmentTypeExtension.fromString('cambio_aceite'),
          AppointmentType.cambioAceite);
      expect(AppointmentTypeExtension.fromString('alineacion'),
          AppointmentType.alineacion);
      expect(
          AppointmentTypeExtension.fromString('unknown'), AppointmentType.otro);
    });
  });

  group('AppointmentStatus Extension Tests', () {
    test('value returns correct string', () {
      expect(AppointmentStatus.pending.value, 'pending');
      expect(AppointmentStatus.confirmed.value, 'confirmed');
      expect(AppointmentStatus.inProgress.value, 'in_progress');
    });

    test('displayName returns user friendly name', () {
      expect(AppointmentStatus.pending.displayName, 'Pendiente');
      expect(AppointmentStatus.confirmed.displayName, 'Confirmado');
      expect(AppointmentStatus.inProgress.displayName, 'En Progreso');
    });

    test('fromString parses correctly', () {
      expect(AppointmentStatusExtension.fromString('pending'),
          AppointmentStatus.pending);
      expect(AppointmentStatusExtension.fromString('confirmed'),
          AppointmentStatus.confirmed);
      expect(AppointmentStatusExtension.fromString('in_progress'),
          AppointmentStatus.inProgress);
      expect(AppointmentStatusExtension.fromString('unknown'),
          AppointmentStatus.pending);
    });
  });
}
