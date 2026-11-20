import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/api_client.dart';
import 'vehicle_provider.dart';
import 'appointment_provider.dart';

enum AuthState { initial, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final StorageService _storageService;

  // References to other providers for auto-loading data on login
  VehicleProvider? _vehicleProvider;
  AppointmentProvider? _appointmentProvider;

  void setVehicleProvider(VehicleProvider provider) {
    _vehicleProvider = provider;
  }

  void setAppointmentProvider(AppointmentProvider provider) {
    _appointmentProvider = provider;
  }

  AuthState _state = AuthState.initial;
  User? _user;
  String? _error;

  AuthProvider({
    AuthService? authService,
    StorageService? storageService,
  })  : _authService = authService ?? AuthService(),
        _storageService = storageService ?? StorageService();

  AuthState get state => _state;
  User? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _state == AuthState.authenticated;

  Future<void> checkAuthStatus() async {
    _state = AuthState.loading;
    notifyListeners();

    final token = await _storageService.getToken();
    final refreshToken = await _storageService.getRefreshToken();
    final user = await _storageService.getUser();

    if (token != null && user != null) {
      // Update both ApiClient and AuthService with the tokens
      ApiClient.instance.setAccessToken(token);
      if (refreshToken != null) {
        ApiClient.instance.setRefreshToken(refreshToken);
      }
      _authService.setAccessToken(token);

      _user = user;
      _state = AuthState.authenticated;

      // Auto-load data after restoring session from storage
      _vehicleProvider?.loadVehicles();
      _appointmentProvider?.loadAppointments();
    } else {
      // If token or user is missing, clear everything to avoid inconsistent state
      await _storageService.clearAll();
      _user = null;
      _state = AuthState.unauthenticated;
      // Also clear tokens from ApiClient
      ApiClient.instance.clearTokens();
    }

    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    final result = await _authService.register(
      email: email,
      password: password,
      name: name,
      phone: phone,
    );

    if (result.success && result.token != null && result.user != null) {
      // Clear any previous session data first
      await _storageService.clearAll();

      // Save new session data
      await _storageService.saveToken(result.token!);
      if (result.refreshToken != null) {
        await _storageService.saveRefreshToken(result.refreshToken!);
      }
      await _storageService.saveUser(result.user!);

      // Update ApiClient singleton to ensure all services have the tokens
      ApiClient.instance.setAccessToken(result.token!);
      if (result.refreshToken != null) {
        ApiClient.instance.setRefreshToken(result.refreshToken!);
      }

      _user = result.user;
      _state = AuthState.authenticated;
      notifyListeners();

      // Auto-load vehicles and appointments after successful registration
      _vehicleProvider?.loadVehicles();
      _appointmentProvider?.loadAppointments();

      return true;
    } else {
      _error = result.error;
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    final result = await _authService.login(
      email: email,
      password: password,
    );

    if (result.success && result.token != null && result.user != null) {
      // Clear any previous session data first to avoid mixing users
      await _storageService.clearAll();

      // Save new session data
      await _storageService.saveToken(result.token!);
      if (result.refreshToken != null) {
        await _storageService.saveRefreshToken(result.refreshToken!);
      }
      await _storageService.saveUser(result.user!);

      // Update ApiClient singleton to ensure all services have the tokens
      ApiClient.instance.setAccessToken(result.token!);
      if (result.refreshToken != null) {
        ApiClient.instance.setRefreshToken(result.refreshToken!);
      }

      _user = result.user;
      _state = AuthState.authenticated;
      notifyListeners();

      // Auto-load vehicles and appointments after successful login
      _vehicleProvider?.loadVehicles();
      _appointmentProvider?.loadAppointments();

      return true;
    } else {
      _error = result.error;
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final refreshToken = await _storageService.getRefreshToken();

    // Clear local state first
    _user = null;
    _state = AuthState.unauthenticated;

    // Clear storage
    await _storageService.clearAll();

    // Clear tokens from ApiClient singleton
    ApiClient.instance.clearTokens();

    // Clear providers data
    _vehicleProvider?.clearVehicles();
    _appointmentProvider?.clearAppointments();

    // Notify backend (fire and forget, don't block on errors)
    try {
      await _authService.logout(refreshToken: refreshToken);
    } catch (_) {
      // Ignore logout errors - user is already logged out locally
    }

    notifyListeners();
  }
}
