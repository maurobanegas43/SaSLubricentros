import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  // URL base del backend - configurable para diferentes entornos
  // DEVELOPMENT: 'http://10.0.2.2:8080' (Android emulator)
  // PRODUCTION: Reemplazar con la URL del servidor desplegado
  // Ejemplo: 'https://api.lubricentros.com' o IP del servidor

  // ⚠️ IMPORTANTE: Actualizar esta URL para producción
  static const String baseUrl = 'http://TU_IP_SERVIDOR:8080';
  // Para testing local usar: 'http://localhost:8080'
  // Para Android emulator: 'http://10.0.2.2:8080'

  final http.Client _client;
  String? _token;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  void setToken(String token) {
    _token = token;
    print('[ApiClient] Token set: ${token.substring(0, 20)}...');
  }

  void clearToken() {
    _token = null;
    print('[ApiClient] Token cleared');
  }

  String? get token => _token;

  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  Future<http.Response> get(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    print('[GET] ${uri.path}');
    return await _client.get(
      uri,
      headers: _getHeaders(includeAuth: requiresAuth),
    );
  }

  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    print('[POST] ${uri.path} - Body: $body');
    return await _client.post(
      uri,
      headers: _getHeaders(includeAuth: requiresAuth),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    print('[PUT] ${uri.path} - Body: $body');
    return await _client.put(
      uri,
      headers: _getHeaders(includeAuth: requiresAuth),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    print('[PATCH] ${uri.path} - Body: $body');
    return await _client.patch(
      uri,
      headers: _getHeaders(includeAuth: requiresAuth),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    print('[DELETE] ${uri.path}');
    return await _client.delete(
      uri,
      headers: _getHeaders(includeAuth: requiresAuth),
    );
  }
}
