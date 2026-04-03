import 'package:flutter/foundation.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';
import '../core/async_value.dart';
import '../core/failure.dart';

class AppointmentProvider extends ChangeNotifier {
  // ignore: unused_field
  final AppointmentService _appointmentService;

  AsyncValue<List<Appointment>> _appointmentsState = const AsyncLoading();
  Failure? _lastFailure;

  AppointmentProvider({AppointmentService? appointmentService})
      : _appointmentService = appointmentService ?? AppointmentService() {
    _loadMockData();
  }

  AsyncValue<List<Appointment>> get appointmentsState => _appointmentsState;
  List<Appointment> get appointments => _appointmentsState.dataOrNull ?? [];
  bool get isLoading => _appointmentsState.isLoading;
  Failure? get lastFailure => _lastFailure;

  // DEV MODE: Cargar datos de prueba
  void _loadMockData() {
    _appointmentsState = AsyncData([
      Appointment(
        id: 1, userId: 1, vehicleId: 1,
        fecha: DateTime.now().add(const Duration(days: 3)),
        tipoService: 'Cambio de aceite', status: AppointmentStatus.confirmed,
        observaciones: 'Revisar frenos también',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Appointment(
        id: 2, userId: 1, vehicleId: 2,
        fecha: DateTime.now().add(const Duration(days: 7)),
        tipoService: 'Service completo', status: AppointmentStatus.pending,
        observaciones: null,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Appointment(
        id: 3, userId: 1, vehicleId: 1,
        fecha: DateTime.now().subtract(const Duration(days: 30)),
        tipoService: 'Cambio de filtros', status: AppointmentStatus.completed,
        observaciones: 'Todo ok',
        createdAt: DateTime.now().subtract(const Duration(days: 35)),
      ),
    ]);
    notifyListeners();
  }

  Future<void> loadAppointments() async {
    _appointmentsState = const AsyncLoading();
    _lastFailure = null;
    notifyListeners();

    try {
      // TODO: Replace with real API call: _appointmentService.getAppointments()
      await Future.delayed(const Duration(milliseconds: 800));
      _appointmentsState = AsyncData(appointments);
      _lastFailure = null;
    } catch (e) {
      _lastFailure = UnknownFailure(error: e);
      _appointmentsState = AsyncError('Error al cargar turnos');
    }
    notifyListeners();
  }

  Future<bool> addAppointment({
    required int vehicleId,
    required DateTime fecha,
    required String tipoService,
    String? observaciones,
  }) async {
    _lastFailure = null;
    try {
      // TODO: Replace with real API call
      await Future.delayed(const Duration(milliseconds: 500));
      final newAppointment = Appointment(
        id: DateTime.now().millisecondsSinceEpoch,
        userId: 1,
        vehicleId: vehicleId,
        fecha: fecha,
        tipoService: tipoService,
        status: AppointmentStatus.pending,
        observaciones: observaciones,
        createdAt: DateTime.now(),
      );
      final currentData = _appointmentsState.dataOrNull ?? [];
      _appointmentsState = AsyncData([...currentData, newAppointment]);
      notifyListeners();
      return true;
    } catch (e) {
      _lastFailure = UnknownFailure(error: e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelAppointment(int appointmentId) async {
    _lastFailure = null;
    try {
      // TODO: Replace with real API call
      await Future.delayed(const Duration(milliseconds: 300));
      final currentData = _appointmentsState.dataOrNull ?? [];
      _appointmentsState = AsyncData(
        currentData.map((a) {
          if (a.id == appointmentId) {
            return Appointment(
              id: a.id, userId: a.userId, vehicleId: a.vehicleId,
              fecha: a.fecha, tipoService: a.tipoService,
              status: AppointmentStatus.cancelled,
              observaciones: a.observaciones, createdAt: a.createdAt,
            );
          }
          return a;
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

  Future<void> refresh() async {
    await loadAppointments();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
