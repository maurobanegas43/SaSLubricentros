import 'dart:convert';
import '../models/user.dart';
import '../utils/secure_logger.dart';
import 'api_client.dart';

class AuthResult {
  final bool success;
  final String? token;
  final String? refreshToken;
  final User? user;
  final String? error;

  AuthResult({
    required this.success,
    this.token,
    this.refreshToken,
    this.user,
    this.error,
  });
}

class AuthService {
  final ApiClient _apiClient;

  AuthService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  void setAccessToken(String token) {
    _apiClient.setAccessToken(token);
  }

  Map<String, dynamic> _extractDataMap(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    return body;
  }

  String _fallbackNameFromEmail(String email) {
    final namePart = email.split('@').first.trim();
    if (namePart.isEmpty) return 'Usuario';
    return namePart;
  }

  User _userFromToken(
    String accessToken, {
    required String fallbackEmail,
    required String fallbackName,
  }) {
    try {
      final parts = accessToken.split('.');
      if (parts.length < 2) {
        return User(
          id: 0,
          email: fallbackEmail,
          name: fallbackName,
          phone: null,
        );
      }

      String normalized = parts[1];
      final remainder = normalized.length % 4;
      if (remainder > 0) {
        normalized =
            normalized.padRight(normalized.length + (4 - remainder), '=');
      }

      final payloadJson = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;

      final userIdValue = payload['user_id'];
      final userId = switch (userIdValue) {
        int v => v,
        String v => int.tryParse(v) ?? 0,
        _ => 0,
      };

      final email = (payload['email'] as String?) ?? fallbackEmail;

      return User(
        id: userId,
        email: email,
        name: fallbackName,
        phone: null,
      );
    } catch (_) {
      return User(
        id: 0,
        email: fallbackEmail,
        name: fallbackName,
        phone: null,
      );
    }
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
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
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = _extractDataMap(body);

        final accessToken = (data['access_token'] ?? data['token']) as String?;
        final refreshToken =
            (data['refresh_token'] ?? data['refreshToken']) as String?;

        if (accessToken == null || accessToken.isEmpty) {
          return AuthResult(
            success: false,
            error: 'Respuesta inválida del servidor',
          );
        }

        final user = (data['user'] is Map<String, dynamic>)
            ? User.fromJson(data['user'] as Map<String, dynamic>)
            : _userFromToken(
                accessToken,
                fallbackEmail: email,
                fallbackName: name,
              );

        _apiClient.setAccessToken(accessToken);
        SecureLogger.info('User registered successfully',
            data: {'email': email});

        return AuthResult(
          success: true,
          token: accessToken,
          refreshToken: refreshToken,
          user: user,
        );
      } else {
        final error = ApiClient.extractErrorMessage(
          response,
          fallback: 'Error al registrar',
        );
        SecureLogger.error('Registration failed',
            data: {'email': email, 'status': response.statusCode});
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
    try {
      final response = await _apiClient.post(
        '/auth/login',
        {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = _extractDataMap(body);

        final accessToken = (data['access_token'] ?? data['token']) as String?;
        final refreshToken =
            (data['refresh_token'] ?? data['refreshToken']) as String?;

        if (accessToken == null || accessToken.isEmpty) {
          return AuthResult(
            success: false,
            error: 'Respuesta inválida del servidor',
          );
        }

        final user = (data['user'] is Map<String, dynamic>)
            ? User.fromJson(data['user'] as Map<String, dynamic>)
            : _userFromToken(
                accessToken,
                fallbackEmail: email,
                fallbackName: _fallbackNameFromEmail(email),
              );

        _apiClient.setAccessToken(accessToken);
        SecureLogger.info('User logged in successfully',
            data: {'email': email});

        return AuthResult(
          success: true,
          token: accessToken,
          refreshToken: refreshToken,
          user: user,
        );
      } else {
        final error = ApiClient.extractErrorMessage(
          response,
          fallback: 'Email o contraseña incorrectos',
        );
        SecureLogger.error('Login failed',
            data: {'email': email, 'status': response.statusCode});
        return AuthResult(success: false, error: error);
      }
    } catch (e) {
      SecureLogger.error('Login error', error: e);
      return AuthResult(success: false, error: 'Error de conexión');
    }
  }

  Future<bool> logout({String? refreshToken}) async {
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _apiClient.post(
          '/auth/logout',
          {'refresh_token': refreshToken},
          requiresAuth: true,
        );
      }
    } catch (_) {
      // Ignorar errores de logout
    } finally {
      _apiClient.clearTokens();
      SecureLogger.info('User logged out');
    }
    return true;
  }

  Future<bool> refreshToken(String refreshTokenValue) async {
    final result = await refreshSession(refreshToken: refreshTokenValue);
    return result.success;
  }

  Future<AuthResult> refreshSession({
    required String refreshToken,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/refresh',
        {'refresh_token': refreshToken},
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = _extractDataMap(body);
        final accessToken = (data['access_token'] ?? data['token']) as String?;
        final newRefreshToken =
            (data['refresh_token'] ?? data['refreshToken']) as String?;

        if (accessToken == null || accessToken.isEmpty) {
          return AuthResult(
            success: false,
            error: 'Respuesta inválida del servidor',
          );
        }

        _apiClient.setAccessToken(accessToken);
        return AuthResult(
          success: true,
          token: accessToken,
          refreshToken: newRefreshToken,
        );
      }
      return AuthResult(
        success: false,
        error: ApiClient.extractErrorMessage(
          response,
          fallback: 'No se pudo renovar la sesión',
        ),
      );
    } catch (e) {
      SecureLogger.error('Refresh error', error: e);
      return AuthResult(success: false, error: 'Error de conexión');
    }
  }
}
