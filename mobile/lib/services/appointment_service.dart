import '../models/appointment.dart';
import '../utils/secure_logger.dart';
import 'api_client.dart';

class AppointmentService {
  final ApiClient _apiClient;

  AppointmentService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Obtiene todos los turnos del usuario
  Future<List<Appointment>> getAppointments({
    int offset = 0,
    int limit = 20,
    AppointmentStatus? status,
  }) async {
    try {
      final page = (offset ~/ limit) + 1;
      String endpoint = '/appointments?page=$page&limit=$limit';
      if (status != null) {
        endpoint += '&status=${status.value}';
      }

      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final data = ApiClient.extractData(response);
        final appointmentsList = (data is List)
            ? data
            : ((data is Map<String, dynamic> && data['appointments'] is List)
                ? data['appointments'] as List
                : <dynamic>[]);
        return appointmentsList.map((a) => Appointment.fromJson(a)).toList();
      } else {
        SecureLogger.error('Failed to fetch appointments',
            data: {'status': response.statusCode});
        throw Exception(
          ApiClient.extractErrorMessage(
            response,
            fallback: 'Error al cargar turnos',
          ),
        );
      }
    } catch (e) {
      SecureLogger.error('Error fetching appointments', error: e);
      rethrow;
    }
  }

  /// Obtiene un turno específico por ID
  Future<Appointment> getAppointmentById(int id) async {
    try {
      final response = await _apiClient.get('/appointments/$id');

      if (response.statusCode == 200) {
        final data = ApiClient.extractData(response) as Map<String, dynamic>;
        return Appointment.fromJson(data);
      } else {
        SecureLogger.error('Failed to fetch appointment',
            data: {'id': id, 'status': response.statusCode});
        throw Exception(
          ApiClient.extractErrorMessage(
            response,
            fallback: 'Error al cargar turno',
          ),
        );
      }
    } catch (e) {
      SecureLogger.error('Error fetching appointment', error: e);
      rethrow;
    }
  }

  /// Crea un nuevo turno
  Future<Appointment> createAppointment({
    required int vehicleId,
    required DateTime fecha,
    required AppointmentType tipoService,
    String? observaciones,
  }) async {
    try {
      // Calcular slot_end (asumir 1 hora de duración)
      final slotEnd = fecha.add(const Duration(hours: 1));

      final response = await _apiClient.post(
        '/appointments',
        {
          'vehicle_id': vehicleId,
          'fecha': fecha.toUtc().toIso8601String(),
          // slot_end no es requerido por el backend actual, se mantiene por compatibilidad.
          'slot_end': slotEnd.toUtc().toIso8601String(),
          'tipo_service': tipoService.value,
          if (observaciones != null) 'observaciones': observaciones,
        },
        requiresAuth: true,
      );

      if (response.statusCode == 201) {
        final data = ApiClient.extractData(response) as Map<String, dynamic>;
        SecureLogger.info('Appointment created successfully',
            data: {'vehicleId': vehicleId, 'tipoService': tipoService.value});
        return Appointment.fromJson(data);
      } else {
        SecureLogger.error('Failed to create appointment',
            data: {'status': response.statusCode, 'body': response.body});
        throw Exception(
          ApiClient.extractErrorMessage(
            response,
            fallback: 'Error al crear turno',
          ),
        );
      }
    } catch (e) {
      SecureLogger.error('Error creating appointment', error: e);
      rethrow;
    }
  }

  /// Actualiza un turno existente
  Future<Appointment> updateAppointment({
    required int id,
    DateTime? fecha,
    AppointmentType? tipoService,
    AppointmentStatus? status,
    String? observaciones,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (fecha != null) body['fecha'] = fecha.toUtc().toIso8601String();
      if (tipoService != null) body['tipo_service'] = tipoService.value;
      if (status != null) body['status'] = status.value;
      if (observaciones != null) body['observaciones'] = observaciones;

      final response =
          await _apiClient.put('/appointments/$id', body, requiresAuth: true);

      if (response.statusCode == 200) {
        final data = ApiClient.extractData(response) as Map<String, dynamic>;
        SecureLogger.info('Appointment updated successfully', data: {'id': id});
        return Appointment.fromJson(data);
      } else {
        SecureLogger.error('Failed to update appointment',
            data: {'id': id, 'status': response.statusCode});
        throw Exception(
          ApiClient.extractErrorMessage(
            response,
            fallback: 'Error al actualizar turno',
          ),
        );
      }
    } catch (e) {
      SecureLogger.error('Error updating appointment', error: e);
      rethrow;
    }
  }

  /// Cancela un turno
  Future<bool> cancelAppointment(int id) async {
    try {
      final response = await _apiClient.put(
        '/appointments/$id',
        {'status': 'cancelled'},
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        SecureLogger.info('Appointment cancelled successfully',
            data: {'id': id});
        return true;
      } else {
        SecureLogger.error('Failed to cancel appointment',
            data: {'id': id, 'status': response.statusCode});
        throw Exception(
          ApiClient.extractErrorMessage(
            response,
            fallback: 'Error al cancelar turno',
          ),
        );
      }
    } catch (e) {
      SecureLogger.error('Error cancelling appointment', error: e);
      rethrow;
    }
  }

  /// Elimina un turno
  Future<bool> deleteAppointment(int id) async {
    try {
      final response = await _apiClient.delete('/appointments/$id');

      if (response.statusCode == 200 || response.statusCode == 204) {
        SecureLogger.info('Appointment deleted successfully', data: {'id': id});
        return true;
      } else {
        SecureLogger.error('Failed to delete appointment',
            data: {'id': id, 'status': response.statusCode});
        throw Exception(
          ApiClient.extractErrorMessage(
            response,
            fallback: 'Error al eliminar turno',
          ),
        );
      }
    } catch (e) {
      SecureLogger.error('Error deleting appointment', error: e);
      rethrow;
    }
  }

  /// Obtiene los slots disponibles para una fecha
  Future<List<DateTime>> getAvailableSlots(DateTime fecha) async {
    try {
      final dateStr =
          '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      final response =
          await _apiClient.get('/appointments/slots?date=$dateStr');

      if (response.statusCode == 200) {
        final data = ApiClient.extractData(response);
        final slotsList =
            (data is Map<String, dynamic> && data['slots'] is List)
                ? data['slots'] as List
                : <dynamic>[];

        final result = <DateTime>[];
        for (final slot in slotsList) {
          final slotStr = '$slot';
          // El backend devuelve HH:mm; se compone con la fecha solicitada.
          final value = DateTime.tryParse('${dateStr}T$slotStr:00');
          if (value != null) {
            result.add(value);
          }
        }
        return result;
      } else {
        SecureLogger.error('Failed to fetch slots',
            data: {'status': response.statusCode});
        throw Exception(
          ApiClient.extractErrorMessage(
            response,
            fallback: 'Error al cargar horarios disponibles',
          ),
        );
      }
    } catch (e) {
      SecureLogger.error('Error fetching slots', error: e);
      rethrow;
    }
  }
}
