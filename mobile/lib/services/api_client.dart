import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  // URL base del backend.
  // Puede sobreescribirse en build con:
  // flutter run --dart-define=API_BASE_URL=https://tu-api.com
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://proyecto-3-2.onrender.com',
  );

  final http.Client _client;
  String? _token;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  void setToken(String token) {
    _token = token;
    final previewLength = token.length < 20 ? token.length : 20;
    print('[ApiClient] Token set: ${token.substring(0, previewLength)}...');
  }

  void clearToken() {
    _token = null;
    print('[ApiClient] Token cleared');
  }

  String? get token => _token;

  static dynamic decodeBody(http.Response response) {
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  static dynamic extractData(http.Response response) {
    final decoded = decodeBody(response);
    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('success') && decoded.containsKey('data')) {
        return decoded['data'];
      }
      if (decoded.containsKey('data')) {
        return decoded['data'];
      }
    }
    return decoded;
  }

  static String extractErrorMessage(
    http.Response response, {
    String fallback = 'Error de conexión',
  }) {
    final decoded = decodeBody(response);
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'];
      if (message is String && message.isNotEmpty) return message;

      final error = decoded['error'];
      if (error is String && error.isNotEmpty) return error;
    }
    return fallback;
  }

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
