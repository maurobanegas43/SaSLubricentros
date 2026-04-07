import 'package:flutter/foundation.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';
import '../core/async_value.dart';
import '../core/failure.dart';

class AppointmentProvider extends ChangeNotifier {
  final AppointmentService _appointmentService;
  static const bool useRealApi = true; // Cambiar a true en producción

  AsyncValue<List<Appointment>> _appointmentsState = const AsyncLoading();
  Failure? _lastFailure;

  AppointmentProvider({AppointmentService? appointmentService})
      : _appointmentService = appointmentService ?? AppointmentService() {
    if (!useRealApi) {
      _loadMockData();
    }
  }

  AsyncValue<List<Appointment>> get appointmentsState => _appointmentsState;
  List<Appointment> get appointments => _appointmentsState.dataOrNull ?? [];
  bool get isLoading => _appointmentsState.isLoading;
  Failure? get lastFailure => _lastFailure;

  // DEV MODE: Cargar datos de prueba
  void _loadMockData() {
    final now = DateTime.now();
    _appointmentsState = AsyncData([
      Appointment(
        id: 1,
        userId: 1,
        vehicleId: 1,
        fecha: now.add(const Duration(days: 3)),
        slotEnd: now.add(const Duration(days: 3, hours: 1)),
        tipoService: AppointmentType.cambioAceite,
        status: AppointmentStatus.confirmed,
        observaciones: 'Revisar frenos también',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      Appointment(
        id: 2,
        userId: 1,
        vehicleId: 2,
        fecha: now.add(const Duration(days: 7)),
        slotEnd: now.add(const Duration(days: 7, hours: 1)),
        tipoService: AppointmentType.revisionGeneral,
        status: AppointmentStatus.pending,
        observaciones: null,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Appointment(
        id: 3,
        userId: 1,
        vehicleId: 1,
        fecha: now.subtract(const Duration(days: 30)),
        slotEnd: now.subtract(const Duration(days: 30, hours: 1)),
        tipoService: AppointmentType.alineacion,
        status: AppointmentStatus.completed,
        observaciones: 'Todo ok',
        createdAt: now.subtract(const Duration(days: 35)),
        updatedAt: now.subtract(const Duration(days: 30)),
      ),
    ]);
    notifyListeners();
  }

  Future<void> loadAppointments() async {
    _appointmentsState = const AsyncLoading();
    _lastFailure = null;
    notifyListeners();

    try {
      if (useRealApi) {
        final data = await _appointmentService.getAppointments();
        _appointmentsState = AsyncData(data);
      } else {
        await Future.delayed(const Duration(milliseconds: 800));
        _appointmentsState = AsyncData(appointments);
      }
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
    required AppointmentType tipoService,
    String? observaciones,
  }) async {
    _lastFailure = null;
    try {
      if (useRealApi) {
        final newAppointment = await _appointmentService.createAppointment(
          vehicleId: vehicleId,
          fecha: fecha,
          tipoService: tipoService,
          observaciones: observaciones,
        );
        final currentData = _appointmentsState.dataOrNull ?? [];
        _appointmentsState = AsyncData([...currentData, newAppointment]);
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        final now = DateTime.now();
        final newAppointment = Appointment(
          id: DateTime.now().millisecondsSinceEpoch,
          userId: 1,
          vehicleId: vehicleId,
          fecha: fecha,
          slotEnd: fecha.add(const Duration(hours: 1)),
          tipoService: tipoService,
          status: AppointmentStatus.pending,
          observaciones: observaciones,
          createdAt: now,
          updatedAt: now,
        );
        final currentData = _appointmentsState.dataOrNull ?? [];
        _appointmentsState = AsyncData([...currentData, newAppointment]);
      }
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
      if (useRealApi) {
        await _appointmentService.cancelAppointment(appointmentId);
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
      }

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
    if (useRealApi) {
      return await _appointmentService.getAvailableSlots(fecha);
    } else {
      // Mock slots
      return [
        fecha.add(const Duration(hours: 9)),
        fecha.add(const Duration(hours: 10)),
        fecha.add(const Duration(hours: 11)),
        fecha.add(const Duration(hours: 14)),
        fecha.add(const Duration(hours: 15)),
        fecha.add(const Duration(hours: 16)),
      ];
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
