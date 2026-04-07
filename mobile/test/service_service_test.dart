import 'package:flutter_test/flutter_test.dart';
import 'package:lubricentros_app/services/service_service.dart';
import 'package:lubricentros_app/models/appointment.dart';

void main() {
  group('ServiceService Tests', () {
    late ServiceService serviceService;

    setUp(() {
      serviceService = ServiceService();
    });

    test('getServicesByVehicle returns mock services in dev mode', () async {
      final services = await serviceService.getServicesByVehicle(1);

      expect(services, isNotEmpty);
      expect(services.length, 3);
      expect(services.first.tipoService, 'cambio_aceite');
    });

    test('getLastService returns the most recent service', () async {
      final lastService = await serviceService.getLastService(1);

      expect(lastService, isNotNull);
      expect(lastService?.tipoService, 'cambio_aceite');
    });

    test('getAddendums returns mock addendums', () async {
      final addendums = await serviceService.getAddendums(1);

      expect(addendums, isNotEmpty);
      expect(addendums.first.description, contains('filtro de aire'));
    });

    test('createAddendum creates new addendum in dev mode', () async {
      final addendum = await serviceService.createAddendum(1, 'Test addendum');

      expect(addendum, isNotNull);
      expect(addendum?.description, 'Test addendum');
      expect(addendum?.serviceId, 1);
    });

    test('ServiceRecord fromJson parses correctly', () {
      final json = {
        'id': 1,
        'vehicle_id': 2,
        'tipo_service': 'alineacion',
        'fecha': '2024-06-01T10:00:00Z',
        'km_actual': 50000,
        'oil_type': 'sintetico',
        'observaciones': 'Test notes',
        'created_at': '2024-01-01T00:00:00Z',
      };

      final service = ServiceRecord.fromJson(json);

      expect(service.id, 1);
      expect(service.vehicleId, 2);
      expect(service.tipoService, 'alineacion');
      expect(service.kmActual, 50000);
      expect(service.oilType, 'sintetico');
      expect(service.observaciones, 'Test notes');
    });

    test('ServiceAddendum fromJson parses correctly', () {
      final json = {
        'id': 1,
        'service_id': 5,
        'description': 'Test addendum',
        'created_at': '2024-01-01T00:00:00Z',
      };

      final addendum = ServiceAddendum.fromJson(json);

      expect(addendum.id, 1);
      expect(addendum.serviceId, 5);
      expect(addendum.description, 'Test addendum');
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
