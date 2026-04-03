import 'package:flutter/foundation.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';

class AppointmentProvider extends ChangeNotifier {
  final AppointmentService _appointmentService;
  
  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _error;

  AppointmentProvider({AppointmentService? appointmentService})
      : _appointmentService = appointmentService ?? AppointmentService() {
    _loadMockData();
  }

  List<Appointment> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // DEV MODE: Cargar datos de prueba
  void _loadMockData() {
    _appointments = [
      Appointment(
        id: 1,
        userId: 1,
        vehicleId: 1,
        fecha: DateTime.now().add(const Duration(days: 3)),
        tipoService: 'Cambio de aceite',
        status: AppointmentStatus.confirmed,
        observaciones: 'Revisar frenos también',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Appointment(
        id: 2,
        userId: 1,
        vehicleId: 2,
        fecha: DateTime.now().add(const Duration(days: 7)),
        tipoService: 'Service completo',
        status: AppointmentStatus.pending,
        observaciones: null,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Appointment(
        id: 3,
        userId: 1,
        vehicleId: 1,
        fecha: DateTime.now().subtract(const Duration(days: 30)),
        tipoService: 'Cambio de filtros',
        status: AppointmentStatus.completed,
        observaciones: 'Todo ok',
        createdAt: DateTime.now().subtract(const Duration(days: 35)),
      ),
    ];
    notifyListeners();
  }

  Future<void> loadAppointments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAppointment(Appointment appointment) async {
    _appointments.add(appointment);
    notifyListeners();
  }
}
