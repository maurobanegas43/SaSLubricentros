import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';

class VehicleProvider extends ChangeNotifier {
  final VehicleService _vehicleService;
  
  List<Vehicle> _vehicles = [];
  bool _isLoading = false;
  String? _error;

  VehicleProvider({VehicleService? vehicleService})
      : _vehicleService = vehicleService ?? VehicleService() {
    _loadMockData();
  }

  List<Vehicle> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // DEV MODE: Cargar datos de prueba
  void _loadMockData() {
    _vehicles = [
      Vehicle(
        id: 1,
        userId: 1,
        marca: 'Toyota',
        modelo: 'Corolla',
        anio: 2020,
        motor: '1.8',
        kmActual: 45000,
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
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
        updatedAt: DateTime.now(),
      ),
    ];
    notifyListeners();
  }

  Future<void> loadVehicles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // En dev mode, usar datos mock
      await Future.delayed(const Duration(milliseconds: 500));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    _vehicles.add(vehicle);
    notifyListeners();
  }
}
