import 'dart:convert';
import '../models/user.dart';
import '../utils/secure_logger.dart';
import 'api_client.dart';

class AuthResult {
  final bool success;
  final String? token;
  final User? user;
  final String? error;

  AuthResult({
    required this.success,
    this.token,
    this.user,
    this.error,
  });
}

class AuthService {
  final ApiClient _apiClient;
  static const bool _devMode = true; // Cambiar a false en producción

  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    // DEV MODE: Simular registro exitoso
    if (_devMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      final mockUser = User(
        id: 1,
        email: email,
        name: name,
        phone: phone,
      );
      final mockToken = 'dev_token_${DateTime.now().millisecondsSinceEpoch}';
      SecureLogger.info('DEV MODE: User registered', data: {'email': email});
      return AuthResult(success: true, token: mockToken, user: mockUser);
    }

    try {
      final response = await _apiClient.post(
        '/auth/register',
        {
          'email': email,
          'password': password,
          'name': name,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String;
        final user = User.fromJson(data['user']);
        
        _apiClient.setToken(token);
        SecureLogger.info('User registered successfully', data: {'email': email});
        
        return AuthResult(success: true, token: token, user: user);
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Error al registrar';
        SecureLogger.error('Registration failed', data: {'email': email, 'status': response.statusCode});
        return AuthResult(success: false, error: error);
      }
    } catch (e) {
      SecureLogger.error('Registration error', error: e);
      return AuthResult(success: false, error: 'Error de conexión');
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    // DEV MODE: Simular login exitoso con credenciales de admin
    if (_devMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Credenciales de admin para desarrollo
      if (email == 'admin@lubricentros.com' && password == 'Admin123') {
        final mockUser = User(
          id: 1,
          email: email,
          name: 'Admin Lubricentros',
          phone: '+54911234567',
        );
        final mockToken = 'dev_token_${DateTime.now().millisecondsSinceEpoch}';
        SecureLogger.info('DEV MODE: Admin logged in', data: {'email': email});
        return AuthResult(success: true, token: mockToken, user: mockUser);
      }
      
      // Cualquier otro email/password también funciona en dev mode
      final mockUser = User(
        id: 2,
        email: email,
        name: 'Usuario Demo',
        phone: null,
      );
      final mockToken = 'dev_token_${DateTime.now().millisecondsSinceEpoch}';
      SecureLogger.info('DEV MODE: User logged in', data: {'email': email});
      return AuthResult(success: true, token: mockToken, user: mockUser);
    }

    try {
      final response = await _apiClient.post(
        '/auth/login',
        {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String;
        final user = User.fromJson(data['user']);
        
        _apiClient.setToken(token);
        SecureLogger.info('User logged in successfully', data: {'email': email});
        
        return AuthResult(success: true, token: token, user: user);
      } else {
        SecureLogger.error('Login failed', data: {'email': email, 'status': response.statusCode});
        return AuthResult(success: false, error: 'Email o contraseña incorrectos');
      }
    } catch (e) {
      SecureLogger.error('Login error', error: e);
      return AuthResult(success: false, error: 'Error de conexión');
    }
  }

  Future<void> logout() async {
    _apiClient.clearToken();
    SecureLogger.info('User logged out');
  }
}
