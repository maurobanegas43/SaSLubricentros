import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import '../core/async_value.dart';
import '../core/failure.dart';

class VehicleProvider extends ChangeNotifier {
  // ignore: unused_field
  final VehicleService _vehicleService;

  AsyncValue<List<Vehicle>> _vehiclesState = const AsyncLoading();
  Failure? _lastFailure;

  VehicleProvider({VehicleService? vehicleService})
      : _vehicleService = vehicleService ?? VehicleService() {
    _loadMockData();
  }

  AsyncValue<List<Vehicle>> get vehiclesState => _vehiclesState;
  List<Vehicle> get vehicles => _vehiclesState.dataOrNull ?? [];
  bool get isLoading => _vehiclesState.isLoading;
  Failure? get lastFailure => _lastFailure;

  // DEV MODE: Cargar datos de prueba
  void _loadMockData() {
    _vehiclesState = AsyncData([
      Vehicle(
        id: 1, userId: 1, marca: 'Toyota', modelo: 'Corolla',
        anio: 2020, motor: '1.8', kmActual: 45000,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        updatedAt: DateTime.now(),
      ),
      Vehicle(
        id: 2, userId: 1, marca: 'Ford', modelo: 'Focus',
        anio: 2019, motor: '2.0', kmActual: 62000,
        createdAt: DateTime.now().subtract(const Duration(days: 500)),
        updatedAt: DateTime.now(),
      ),
      Vehicle(
        id: 3, userId: 1, marca: 'Volkswagen', modelo: 'Gol',
        anio: 2021, motor: '1.6', kmActual: 28000,
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
      // TODO: Replace with real API call: _vehicleService.getVehicles()
      await Future.delayed(const Duration(milliseconds: 800));
      _vehiclesState = AsyncData(vehicles); // Keep mock for now
      _lastFailure = null;
    } catch (e) {
      _lastFailure = UnknownFailure(error: e);
      _vehiclesState = AsyncError('Error al cargar vehículos');
    }
    notifyListeners();
  }

  Future<bool> addVehicle({
    required String marca,
    required String modelo,
    required int anio,
    String? motor,
    required int kmActual,
  }) async {
    _lastFailure = null;
    try {
      // TODO: Replace with real API call
      await Future.delayed(const Duration(milliseconds: 500));
      final newVehicle = Vehicle(
        id: DateTime.now().millisecondsSinceEpoch,
        userId: 1,
        marca: marca,
        modelo: modelo,
        anio: anio,
        motor: motor,
        kmActual: kmActual,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final currentData = _vehiclesState.dataOrNull ?? [];
      _vehiclesState = AsyncData([...currentData, newVehicle]);
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
      // TODO: Replace with real API call
      await Future.delayed(const Duration(milliseconds: 300));
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

  Future<void> refresh() async {
    await loadVehicles();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
