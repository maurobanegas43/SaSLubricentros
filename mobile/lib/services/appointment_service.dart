import 'dart:convert';
import '../models/appointment.dart';
import '../utils/secure_logger.dart';
import 'api_client.dart';

class AppointmentService {
  final ApiClient _apiClient;

  AppointmentService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<Appointment>> getAppointments({AppointmentStatus? status}) async {
    try {
      String endpoint = '/appointments';
      if (status != null) {
        endpoint += '?status=${_statusToString(status)}';
      }

      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final appointmentsList = data['appointments'] as List;
        return appointmentsList.map((a) => Appointment.fromJson(a)).toList();
      } else {
        SecureLogger.error('Failed to fetch appointments', data: {'status': response.statusCode});
        throw Exception('Error al cargar turnos');
      }
    } catch (e) {
      SecureLogger.error('Error fetching appointments', error: e);
      rethrow;
    }
  }

  Future<Appointment> createAppointment({
    required int vehicleId,
    required DateTime fecha,
    required String tipoService,
    String? observaciones,
  }) async {
    try {
      final response = await _apiClient.post(
        '/appointments',
        {
          'vehicle_id': vehicleId,
          'fecha': fecha.toIso8601String(),
          'tipo_service': tipoService,
          if (observaciones != null) 'observaciones': observaciones,
        },
        requiresAuth: true,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        SecureLogger.info('Appointment created successfully');
        return Appointment.fromJson(data);
      } else {
        SecureLogger.error('Failed to create appointment', data: {'status': response.statusCode});
        throw Exception('Error al crear turno');
      }
    } catch (e) {
      SecureLogger.error('Error creating appointment', error: e);
      rethrow;
    }
  }

  String _statusToString(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'pending';
      case AppointmentStatus.confirmed:
        return 'confirmed';
      case AppointmentStatus.completed:
        return 'completed';
      case AppointmentStatus.cancelled:
        return 'cancelled';
    }
  }
}
