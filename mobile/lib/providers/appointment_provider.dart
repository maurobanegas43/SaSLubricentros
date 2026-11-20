import 'package:flutter/foundation.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';
import '../core/async_value.dart';
import '../core/failure.dart';

class AppointmentProvider extends ChangeNotifier {
  final AppointmentService _appointmentService;

  AsyncValue<List<Appointment>> _appointmentsState = const AsyncLoading();
  Failure? _lastFailure;

  AppointmentProvider({AppointmentService? appointmentService})
      : _appointmentService = appointmentService ?? AppointmentService();

  AsyncValue<List<Appointment>> get appointmentsState => _appointmentsState;
  List<Appointment> get appointments => _appointmentsState.dataOrNull ?? [];
  bool get isLoading => _appointmentsState.isLoading;
  Failure? get lastFailure => _lastFailure;

  Future<void> loadAppointments() async {
    _appointmentsState = const AsyncLoading();
    _lastFailure = null;
    notifyListeners();

    try {
      final data = await _appointmentService.getAppointments();
      // Always set to AsyncData, even if empty list
      _appointmentsState = AsyncData(data);
      _lastFailure = null;
      debugPrint('✅ AppointmentProvider: Loaded ${data.length} appointments');
    } catch (e, stackTrace) {
      debugPrint('❌ AppointmentProvider: Error loading appointments: $e');
      debugPrint('Stack trace: $stackTrace');
      _lastFailure = UnknownFailure(error: e);
      // Set to empty data instead of error state to show empty state
      _appointmentsState = const AsyncData([]);
    }
    notifyListeners();
  }

  Future<bool> addAppointment({
    required int vehicleId,
    required DateTime fecha,
    required AppointmentType tipoService,
    String? observaciones,
  }) async {
    _lastFailure = null;
    try {
      final newAppointment = await _appointmentService.createAppointment(
        vehicleId: vehicleId,
        fecha: fecha,
        tipoService: tipoService,
        observaciones: observaciones,
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
      await _appointmentService.cancelAppointment(appointmentId);

      final currentData = _appointmentsState.dataOrNull ?? [];
      _appointmentsState = AsyncData(
        currentData.map((a) {
          if (a.id == appointmentId) {
            return Appointment(
              id: a.id,
              userId: a.userId,
              vehicleId: a.vehicleId,
              fecha: a.fecha,
              slotEnd: a.slotEnd,
              tipoService: a.tipoService,
              status: AppointmentStatus.cancelled,
              observaciones: a.observaciones,
              createdAt: a.createdAt,
              updatedAt: DateTime.now(),
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

  Future<List<DateTime>> getAvailableSlots(DateTime fecha) async {
    return await _appointmentService.getAvailableSlots(fecha);
  }

  Future<void> refresh() async {
    await loadAppointments();
  }

  /// Clears all appointments from state (used on logout)
  void clearAppointments() {
    _appointmentsState = const AsyncData([]);
    _lastFailure = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
