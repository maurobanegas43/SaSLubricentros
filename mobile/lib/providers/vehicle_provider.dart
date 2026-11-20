import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import '../core/async_value.dart';
import '../core/failure.dart';

class VehicleProvider extends ChangeNotifier {
  final VehicleService _vehicleService;

  AsyncValue<List<Vehicle>> _vehiclesState = const AsyncLoading();
  Failure? _lastFailure;

  VehicleProvider({VehicleService? vehicleService})
      : _vehicleService = vehicleService ?? VehicleService();

  AsyncValue<List<Vehicle>> get vehiclesState => _vehiclesState;
  List<Vehicle> get vehicles => _vehiclesState.dataOrNull ?? [];
  bool get isLoading => _vehiclesState.isLoading;
  Failure? get lastFailure => _lastFailure;

  Future<void> loadVehicles() async {
    _vehiclesState = const AsyncLoading();
    _lastFailure = null;
    notifyListeners();

    try {
      final data = await _vehicleService.getVehicles();
      // Always set to AsyncData, even if empty list
      _vehiclesState = AsyncData(data);
      _lastFailure = null;
      debugPrint('✅ VehicleProvider: Loaded ${data.length} vehicles');
    } catch (e, stackTrace) {
      debugPrint('❌ VehicleProvider: Error loading vehicles: $e');
      debugPrint('Stack trace: $stackTrace');
      _lastFailure = UnknownFailure(error: e);
      // Set to empty data instead of error state to show empty state
      _vehiclesState = const AsyncData([]);
    }
    notifyListeners();
  }

  Future<Vehicle?> getVehicleById(int id) async {
    try {
      return await _vehicleService.getVehicleById(id);
    } catch (e) {
      return null;
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
      await _vehicleService.deleteVehicle(vehicleId);

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
    try {
      return await _vehicleService.getVehicleReport(vehicleId);
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadVehicleImage({
    required int vehicleId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final imageUrl = await _vehicleService.uploadVehicleImage(
        vehicleId: vehicleId,
        filePath: filePath,
        fileName: fileName,
      );

      // Update the vehicle in the local list with the new image URL
      if (imageUrl != null) {
        final currentData = _vehiclesState.dataOrNull ?? [];
        _vehiclesState = AsyncData(
          currentData.map((v) {
            if (v.id == vehicleId) {
              return v.copyWith(imageUrl: imageUrl);
            }
            return v;
          }).toList(),
        );
        notifyListeners();
      }

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading vehicle image: $e');
      return null;
    }
  }

  Future<void> refresh() async {
    await loadVehicles();
  }

  /// Clears all vehicles from state (used on logout)
  void clearVehicles() {
    _vehiclesState = const AsyncData([]);
    _lastFailure = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
