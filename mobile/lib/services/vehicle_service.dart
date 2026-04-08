import '../models/vehicle.dart';
import '../utils/secure_logger.dart';
import 'api_client.dart';

class VehicleService {
  final ApiClient _apiClient;

  VehicleService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Obtiene todos los vehículos del usuario
  Future<List<Vehicle>> getVehicles({int offset = 0, int limit = 20}) async {
    try {
      final page = (offset ~/ limit) + 1;
      final response =
          await _apiClient.get('/vehicles?page=$page&limit=$limit');

      if (response.statusCode == 200) {
        final data = ApiClient.extractData(response);
        final vehiclesList = (data is List)
            ? data
            : ((data is Map<String, dynamic> && data['vehicles'] is List)
                ? data['vehicles'] as List
                : <dynamic>[]);
        return vehiclesList.map((v) => Vehicle.fromJson(v)).toList();
      } else {
        SecureLogger.error('Failed to fetch vehicles',
            data: {'status': response.statusCode});
        throw Exception(
          ApiClient.extractErrorMessage(
            response,
            fallback: 'Error al cargar vehículos',
          ),
        );
      }
    } catch (e) {
      SecureLogger.error('Error fetching vehicles', error: e);
      rethrow;
    }
  }

  /// Obtiene un vehículo específico por ID
  Future<Vehicle> getVehicleById(int id) async {
    try {
      final response = await _apiClient.get('/vehicles/$id');

      if (response.statusCode == 200) {
        final data = ApiClient.extractData(response) as Map<String, dynamic>;
        return Vehicle.fromJson(data);
      } else {
        SecureLogger.error('Failed to fetch vehicle',
            data: {'id': id, 'status': response.statusCode});
        throw Exception(
          ApiClient.extractErrorMessage(
            response,
            fallback: 'Error al cargar vehículo',
          ),
        );
      }
    } catch (e) {
      SecureLogger.error('Error fetching vehicle', error: e);
      rethrow;
    }
  }

  /// Crea un nuevo vehículo
  Future<Vehicle> createVehicle({
    String? patente,
    required String marca,
    required String modelo,
    required int anio,
    String? motor,
    required int kmActual,
    String? color,
  }) async {
    try {
      final response = await _apiClient.post(
        '/vehicles',
        {
          if (patente != null) 'patente': patente,
          'marca': marca,
          'modelo': modelo,
          'anio': anio,
          if (motor != null) 'motor': motor,
          'km_actual': kmActual,
          if (color != null) 'color': color,
        },
        requiresAuth: true,
      );

      if (response.statusCode == 201) {
        final data = ApiClient.extractData(response) as Map<String, dynamic>;
        SecureLogger.info('Vehicle created successfully',
            data: {'marca': marca, 'modelo': modelo});
        return Vehicle.fromJson(data);
      } else {
        SecureLogger.error('Failed to create vehicle',
            data: {'status': response.statusCode, 'body': response.body});
        throw Exception(
          ApiClient.extractErrorMessage(
            response,
            fallback: 'Error al crear vehículo',
          ),
        );
      }
    } catch (e) {
      SecureLogger.error('Error creating vehicle', error: e);
      rethrow;
    }
  }

  /// Actualiza un vehículo existente
  Future<Vehicle> updateVehicle({
    required int id,
    String? patente,
    String? marca,
    String? modelo,
    int? anio,
    String? motor,
    int? kmActual,
    String? color,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (patente != null) body['patente'] = patente;
      if (marca != null) body['marca'] = marca;
      if (modelo != null) body['modelo'] = modelo;
      if (anio != null) body['anio'] = anio;
      if (motor != null) body['motor'] = motor;
      if (kmActual != null) body['km_actual'] = kmActual;
      if (color != null) body['color'] = color;

      final response =
          await _apiClient.put('/vehicles/$id', body, requiresAuth: true);

      if (response.statusCode == 200) {
        final data = ApiClient.extractData(response) as Map<String, dynamic>;
        SecureLogger.info('Vehicle updated successfully', data: {'id': id});
        return Vehicle.fromJson(data);
      } else {
        SecureLogger.error('Failed to update vehicle',
            data: {'id': id, 'status': response.statusCode});
        throw Exception(
          ApiClient.extractErrorMessage(
            response,
            fallback: 'Error al actualizar vehículo',
          ),
        );
      }
    } catch (e) {
      SecureLogger.error('Error updating vehicle', error: e);
      rethrow;
    }
  }

  /// Elimina un vehículo
  Future<bool> deleteVehicle(int id) async {
    try {
      final response = await _apiClient.delete('/vehicles/$id');

      if (response.statusCode == 200 || response.statusCode == 204) {
        SecureLogger.info('Vehicle deleted successfully', data: {'id': id});
        return true;
      } else {
        SecureLogger.error('Failed to delete vehicle',
            data: {'id': id, 'status': response.statusCode});
        throw Exception(
          ApiClient.extractErrorMessage(
            response,
            fallback: 'Error al eliminar vehículo',
          ),
        );
      }
    } catch (e) {
      SecureLogger.error('Error deleting vehicle', error: e);
      rethrow;
    }
  }

  /// Obtiene el historial de servicios de un vehículo
  Future<Map<String, dynamic>> getVehicleReport(int id) async {
    try {
      final response = await _apiClient.get('/vehicles/$id/report');

      if (response.statusCode == 200) {
        final data = ApiClient.extractData(response);
        if (data is Map<String, dynamic>) return data;
        return {};
      } else {
        SecureLogger.error('Failed to fetch vehicle report',
            data: {'id': id, 'status': response.statusCode});
        throw Exception(
          ApiClient.extractErrorMessage(
            response,
            fallback: 'Error al cargar historial del vehículo',
          ),
        );
      }
    } catch (e) {
      SecureLogger.error('Error fetching vehicle report', error: e);
      rethrow;
    }
  }

  /// Transfiere ownership de un vehículo a otro usuario
  Future<bool> transferVehicle({
    required int vehicleId,
    int? toUserId,
    String? toUserEmail,
    String? reason,
  }) async {
    try {
      var targetUserID = toUserId;

      // Compatibilidad: si llega email, resolver ID contra /users/search
      if (targetUserID == null &&
          toUserEmail != null &&
          toUserEmail.isNotEmpty) {
        final searchResponse = await _apiClient
            .get('/users/search?q=${Uri.encodeComponent(toUserEmail)}');
        if (searchResponse.statusCode == 200) {
          final searchData = ApiClient.extractData(searchResponse);
          final users = (searchData is Map<String, dynamic> &&
                  searchData['users'] is List)
              ? (searchData['users'] as List)
              : <dynamic>[];

          Map<String, dynamic>? selected;
          for (final u in users) {
            if (u is Map<String, dynamic> && u['email'] == toUserEmail) {
              selected = u;
              break;
            }
          }
          selected ??= users.firstOrNull as Map<String, dynamic>?;
          final idValue = selected?['id'];
          targetUserID = idValue is int ? idValue : int.tryParse('$idValue');
        }
      }

      if (targetUserID == null) {
        throw Exception('No se pudo resolver el usuario destino');
      }

      final response = await _apiClient.post(
        '/vehicles/$vehicleId/transfer',
        {
          'to_user_id': targetUserID,
          if (reason != null) 'reason': reason,
        },
        requiresAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        SecureLogger.info('Vehicle transferred successfully',
            data: {'vehicleId': vehicleId});
        return true;
      } else {
        SecureLogger.error('Failed to transfer vehicle',
            data: {'vehicleId': vehicleId, 'status': response.statusCode});
        throw Exception(
          ApiClient.extractErrorMessage(
            response,
            fallback: 'Error al transferir vehículo',
          ),
        );
      }
    } catch (e) {
      SecureLogger.error('Error transferring vehicle', error: e);
      rethrow;
    }
  }
}
