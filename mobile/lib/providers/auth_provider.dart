import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

enum AuthState { initial, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final StorageService _storageService;

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
    final user = await _storageService.getUser();

    if (token != null) {
      _authService.setAccessToken(token);
    }

    if (token != null && user != null) {
      _user = user;
      _state = AuthState.authenticated;
    } else {
      _state = AuthState.unauthenticated;
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
      await _storageService.saveToken(result.token!);
      if (result.refreshToken != null) {
        await _storageService.saveRefreshToken(result.refreshToken!);
      }
      await _storageService.saveUser(result.user!);
      _user = result.user;
      _state = AuthState.authenticated;
      notifyListeners();
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
      await _storageService.saveToken(result.token!);
      if (result.refreshToken != null) {
        await _storageService.saveRefreshToken(result.refreshToken!);
      }
      await _storageService.saveUser(result.user!);
      _user = result.user;
      _state = AuthState.authenticated;
      notifyListeners();
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
    await _authService.logout(refreshToken: refreshToken);
    await _storageService.clearAll();
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }
}
