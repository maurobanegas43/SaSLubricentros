import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import '../core/async_value.dart';
import '../core/failure.dart';

class VehicleProvider extends ChangeNotifier {
  final VehicleService _vehicleService;
  static const bool useRealApi = true;

  AsyncValue<List<Vehicle>> _vehiclesState = const AsyncLoading();
  Failure? _lastFailure;

  VehicleProvider({VehicleService? vehicleService})
      : _vehicleService = vehicleService ?? VehicleService() {
    if (!useRealApi) {
      _loadMockData();
    }
  }

  AsyncValue<List<Vehicle>> get vehiclesState => _vehiclesState;
  List<Vehicle> get vehicles => _vehiclesState.dataOrNull ?? [];
  bool get isLoading => _vehiclesState.isLoading;
  Failure? get lastFailure => _lastFailure;

  // DEV MODE: Cargar datos de prueba
  void _loadMockData() {
    _vehiclesState = AsyncData([
      Vehicle(
        id: 1,
        userId: 1,
        marca: 'Toyota',
        modelo: 'Corolla',
        anio: 2020,
        motor: '1.8',
        kmActual: 45000,
        patente: 'ABC123',
        color: 'Blanco',
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        updatedAt: DateTime.now(),
      ),
      Vehicle(
        id: 2,
        userId: 1,
        marca: 'Ford',
        modelo: 'Focus',
        anio: 2019,
        motor: '2.0',
        kmActual: 62000,
        patente: 'XYZ789',
        color: 'Negro',
        createdAt: DateTime.now().subtract(const Duration(days: 500)),
        updatedAt: DateTime.now(),
      ),
      Vehicle(
        id: 3,
        userId: 1,
        marca: 'Volkswagen',
        modelo: 'Gol',
        anio: 2021,
        motor: '1.6',
        kmActual: 28000,
        color: 'Gris',
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
        updatedAt: DateTime.now(),
      ),
    ]);
    notifyListeners();
  }

  Future<void> loadVehicles() async {
    _vehiclesState = const AsyncLoading();
    _lastFailure = null;
    notifyListeners();

    try {
      if (useRealApi) {
        final data = await _vehicleService.getVehicles();
        _vehiclesState = AsyncData(data);
      } else {
        await Future.delayed(const Duration(milliseconds: 800));
        _vehiclesState = AsyncData(vehicles);
      }
      _lastFailure = null;
    } catch (e) {
      _lastFailure = UnknownFailure(error: e);
      _vehiclesState = AsyncError('Error al cargar vehículos');
    }
    notifyListeners();
  }

  Future<Vehicle?> getVehicleById(int id) async {
    if (useRealApi) {
      try {
        return await _vehicleService.getVehicleById(id);
      } catch (e) {
        return null;
      }
    } else {
      return vehicles.where((v) => v.id == id).firstOrNull;
    }
  }

  Future<bool> addVehicle({
    String? patente,
    required String marca,
    required String modelo,
    required int anio,
    String? motor,
    required int kmActual,
    String? color,
  }) async {
    _lastFailure = null;
    try {
      if (useRealApi) {
        final newVehicle = await _vehicleService.createVehicle(
          patente: patente,
          marca: marca,
          modelo: modelo,
          anio: anio,
          motor: motor,
          kmActual: kmActual,
          color: color,
        );
        final currentData = _vehiclesState.dataOrNull ?? [];
        _vehiclesState = AsyncData([...currentData, newVehicle]);
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        final newVehicle = Vehicle(
          id: DateTime.now().millisecondsSinceEpoch,
          userId: 1,
          patente: patente,
          marca: marca,
          modelo: modelo,
          anio: anio,
          motor: motor,
          kmActual: kmActual,
          color: color,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final currentData = _vehiclesState.dataOrNull ?? [];
        _vehiclesState = AsyncData([...currentData, newVehicle]);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _lastFailure = UnknownFailure(error: e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateVehicle({
    required int id,
    String? patente,
    String? marca,
    String? modelo,
    int? anio,
    String? motor,
    int? kmActual,
    String? color,
  }) async {
    _lastFailure = null;
    try {
      if (useRealApi) {
        await _vehicleService.updateVehicle(
          id: id,
          patente: patente,
          marca: marca,
          modelo: modelo,
          anio: anio,
          motor: motor,
          kmActual: kmActual,
          color: color,
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      final currentData = _vehiclesState.dataOrNull ?? [];
      _vehiclesState = AsyncData(
        currentData.map((v) {
          if (v.id == id) {
            return v.copyWith(
              patente: patente,
              marca: marca,
              modelo: modelo,
              anio: anio,
              motor: motor,
              kmActual: kmActual,
              color: color,
              updatedAt: DateTime.now(),
            );
          }
          return v;
        }).toList(),
      );
      notifyListeners();
      return true;
    } catch (e) {
      _lastFailure = UnknownFailure(error: e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteVehicle(int vehicleId) async {
    _lastFailure = null;
    try {
      if (useRealApi) {
        await _vehicleService.deleteVehicle(vehicleId);
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      final currentData = _vehiclesState.dataOrNull ?? [];
      _vehiclesState = AsyncData(
        currentData.where((v) => v.id != vehicleId).toList(),
      );
      notifyListeners();
      return true;
    } catch (e) {
      _lastFailure = UnknownFailure(error: e);
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> getVehicleReport(int vehicleId) async {
    if (useRealApi) {
      try {
        return await _vehicleService.getVehicleReport(vehicleId);
      } catch (e) {
        return null;
      }
    } else {
      return {
        'vehicle':
            vehicles.where((v) => v.id == vehicleId).firstOrNull?.toJson(),
        'services': [],
        'total_services': 0,
        'last_service': null,
      };
    }
  }

  Future<void> refresh() async {
    await loadVehicles();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
