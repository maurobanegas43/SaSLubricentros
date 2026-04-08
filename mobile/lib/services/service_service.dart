import '../utils/secure_logger.dart';
import 'api_client.dart';

class ServiceRecord {
  final int id;
  final int vehicleId;
  final String tipoService;
  final DateTime fecha;
  final int? kmActual;
  final String? oilType;
  final String? observaciones;
  final DateTime createdAt;

  ServiceRecord({
    required this.id,
    required this.vehicleId,
    required this.tipoService,
    required this.fecha,
    this.kmActual,
    this.oilType,
    this.observaciones,
    required this.createdAt,
  });

  factory ServiceRecord.fromJson(Map<String, dynamic> json) {
    final kmValue = json['km_actual'] ?? json['km'];
    return ServiceRecord(
      id: json['id'] as int,
      vehicleId: json['vehicle_id'] as int,
      tipoService:
          (json['tipo_service'] ?? json['tipo_aceite'] ?? 'otro') as String,
      fecha: DateTime.parse(json['fecha'] as String),
      kmActual: kmValue is int ? kmValue : int.tryParse('$kmValue'),
      oilType: (json['oil_type'] ?? json['tipo_aceite']) as String?,
      observaciones: json['observaciones'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ServiceAddendum {
  final int id;
  final int serviceId;
  final String description;
  final DateTime createdAt;

  ServiceAddendum({
    required this.id,
    required this.serviceId,
    required this.description,
    required this.createdAt,
  });

  factory ServiceAddendum.fromJson(Map<String, dynamic> json) {
    final fieldName = (json['field_name'] ?? '') as String;
    final oldValue = (json['old_value'] ?? '') as String;
    final newValue = (json['new_value'] ?? '') as String;
    final reason = (json['reason'] ?? '') as String;

    final description = (json['description'] as String?) ??
        [fieldName, oldValue, newValue, reason]
            .where((e) => e.isNotEmpty)
            .join(' | ');

    return ServiceAddendum(
      id: json['id'] as int,
      serviceId: json['service_id'] as int,
      description: description,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ServiceService {
  final ApiClient _apiClient;
  static const bool useRealApi = bool.fromEnvironment(
    'USE_REAL_SERVICE_API',
    defaultValue: true,
  );

  ServiceService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Obtiene el historial de servicios de un vehículo
  Future<List<ServiceRecord>> getServicesByVehicle(int vehicleId,
      {int offset = 0, int limit = 20}) async {
    if (useRealApi) {
      try {
        final page = (offset ~/ limit) + 1;
        final response = await _apiClient
            .get('/services/vehicle/$vehicleId?page=$page&limit=$limit');
        if (response.statusCode == 200) {
          final data = ApiClient.extractData(response);
          final servicesList = (data is List)
              ? data
              : ((data is Map<String, dynamic> && data['services'] is List)
                  ? data['services'] as List
                  : <dynamic>[]);
          return servicesList.map((s) => ServiceRecord.fromJson(s)).toList();
        } else {
          SecureLogger.error('Failed to fetch services',
              data: {'vehicleId': vehicleId, 'status': response.statusCode});
          throw Exception(
            ApiClient.extractErrorMessage(
              response,
              fallback: 'Error al cargar servicios',
            ),
          );
        }
      } catch (e) {
        SecureLogger.error('Error fetching services', error: e);
        rethrow;
      }
    } else {
      // Mock data
      return _getMockServices(vehicleId);
    }
  }

  /// Obtiene el último servicio de un vehículo
  Future<ServiceRecord?> getLastService(int vehicleId) async {
    if (useRealApi) {
      try {
        final response =
            await _apiClient.get('/services/vehicle/$vehicleId?limit=1');
        if (response.statusCode == 200) {
          final data = ApiClient.extractData(response);
          final servicesList = (data is List)
              ? data
              : ((data is Map<String, dynamic> && data['services'] is List)
                  ? data['services'] as List
                  : <dynamic>[]);
          if (servicesList.isNotEmpty) {
            return ServiceRecord.fromJson(servicesList.first);
          }
        }
        return null;
      } catch (e) {
        SecureLogger.error('Error fetching last service', error: e);
        return null;
      }
    } else {
      final services = _getMockServices(vehicleId);
      return services.isNotEmpty ? services.first : null;
    }
  }

  /// Obtiene los addendums de un servicio
  Future<List<ServiceAddendum>> getAddendums(int serviceId) async {
    if (useRealApi) {
      try {
        final response = await _apiClient.get('/services/$serviceId/addendums');
        if (response.statusCode == 200) {
          final data = ApiClient.extractData(response);
          final addendumsList = (data is List)
              ? data
              : ((data is Map<String, dynamic> && data['addendums'] is List)
                  ? data['addendums'] as List
                  : <dynamic>[]);
          return addendumsList.map((a) => ServiceAddendum.fromJson(a)).toList();
        }
        return [];
      } catch (e) {
        SecureLogger.error('Error fetching addendums', error: e);
        return [];
      }
    } else {
      return _getMockAddendums(serviceId);
    }
  }

  /// Crea un addendum para un servicio
  Future<ServiceAddendum?> createAddendum(
    int serviceId,
    String description, {
    String fieldName = 'observaciones',
    String? oldValue,
    String? reason,
  }) async {
    if (useRealApi) {
      try {
        final response = await _apiClient.post(
          '/services/$serviceId/addendums',
          {
            'field_name': fieldName,
            'old_value': oldValue ?? '',
            'new_value': description,
            'reason': reason ?? 'Corrección desde aplicación móvil',
          },
          requiresAuth: true,
        );
        if (response.statusCode == 201) {
          final data = ApiClient.extractData(response) as Map<String, dynamic>;
          return ServiceAddendum.fromJson(data);
        }
        return null;
      } catch (e) {
        SecureLogger.error('Error creating addendum', error: e);
        return null;
      }
    } else {
      return ServiceAddendum(
        id: DateTime.now().millisecondsSinceEpoch,
        serviceId: serviceId,
        description: description,
        createdAt: DateTime.now(),
      );
    }
  }

  // Mock data helpers
  List<ServiceRecord> _getMockServices(int vehicleId) {
    final now = DateTime.now();
    return [
      ServiceRecord(
        id: 1,
        vehicleId: vehicleId,
        tipoService: 'cambio_aceite',
        fecha: now.subtract(const Duration(days: 30)),
        kmActual: 45000,
        oilType: 'sintetico',
        observaciones: 'Cambio de aceite y filtro',
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      ServiceRecord(
        id: 2,
        vehicleId: vehicleId,
        tipoService: 'alineacion',
        fecha: now.subtract(const Duration(days: 90)),
        kmActual: 42000,
        observaciones: 'Alineación y balanceo',
        createdAt: now.subtract(const Duration(days: 90)),
      ),
      ServiceRecord(
        id: 3,
        vehicleId: vehicleId,
        tipoService: 'revision_general',
        fecha: now.subtract(const Duration(days: 180)),
        kmActual: 38000,
        observaciones: 'Revisión general del sistema de frenado',
        createdAt: now.subtract(const Duration(days: 180)),
      ),
    ];
  }

  List<ServiceAddendum> _getMockAddendums(int serviceId) {
    return [
      ServiceAddendum(
        id: 1,
        serviceId: serviceId,
        description: 'Se recomienda cambiar filtro de aire en proxima visita',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
    ];
  }
}
