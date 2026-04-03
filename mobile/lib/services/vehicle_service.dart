import 'dart:convert';
import '../models/vehicle.dart';
import '../utils/secure_logger.dart';
import 'api_client.dart';

class VehicleService {
  final ApiClient _apiClient;

  VehicleService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<Vehicle>> getVehicles() async {
    try {
      final response = await _apiClient.get('/vehicles');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final vehiclesList = data['vehicles'] as List;
        return vehiclesList.map((v) => Vehicle.fromJson(v)).toList();
      } else {
        SecureLogger.error('Failed to fetch vehicles', data: {'status': response.statusCode});
        throw Exception('Error al cargar vehículos');
      }
    } catch (e) {
      SecureLogger.error('Error fetching vehicles', error: e);
      rethrow;
    }
  }

  Future<Vehicle> createVehicle({
    required String marca,
    required String modelo,
    required int anio,
    String? motor,
    required int kmActual,
  }) async {
    try {
      final response = await _apiClient.post(
        '/vehicles',
        {
          'marca': marca,
          'modelo': modelo,
          'anio': anio,
          if (motor != null) 'motor': motor,
          'km_actual': kmActual,
        },
        requiresAuth: true,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        SecureLogger.info('Vehicle created successfully');
        return Vehicle.fromJson(data);
      } else {
        SecureLogger.error('Failed to create vehicle', data: {'status': response.statusCode});
        throw Exception('Error al crear vehículo');
      }
    } catch (e) {
      SecureLogger.error('Error creating vehicle', error: e);
      rethrow;
    }
  }
}
