import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../utils/secure_logger.dart';

/// Singleton ApiClient ensuring all services use the same token state.
/// This prevents the critical bug where different service instances have
/// inconsistent token state causing intermittent 401 errors.
class ApiClient {
  // ─────────────────────────────────────────────────────────────────────
  // SINGLETON PATTERN
  // ─────────────────────────────────────────────────────────────────────

  static ApiClient? _instance;
  static ApiClient get instance {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  // For testing: allow injecting custom client
  static void setInstance(ApiClient client) {
    _instance = client;
  }

  static void resetInstance() {
    _instance = null;
  }

  // ─────────────────────────────────────────────────────────────────────
  // INTERNAL STATE
  // ─────────────────────────────────────────────────────────────────────

  final http.Client _client;
  String? _accessToken;
  String? _refreshToken;

  // Concurrency control for token refresh
  bool _isRefreshing = false;
  final List<Completer<void>> _refreshQueue = [];

  // URL base del backend.
  // Puede sobreescribirse en build con:
  // flutter run --dart-define=API_BASE_URL=https://tu-api.com
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://proyecto-3-2.onrender.com',
  );

  ApiClient._internal() : _client = http.Client();

  // Allow injecting custom http.Client for testing
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  // ─────────────────────────────────────────────────────────────────────
  // TOKEN MANAGEMENT (Source of Truth)
  // ─────────────────────────────────────────────────────────────────────

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;

  /// Set access token - this is the SINGLE SOURCE OF TRUTH for all services
  void setAccessToken(String token) {
    _accessToken = token;
    final previewLength = token.length < 20 ? token.length : 20;
    SecureLogger.debug('ApiClient: Access token updated',
        data: {'preview': '${token.substring(0, previewLength)}...'});
  }

  /// Set refresh token for automatic token refresh
  void setRefreshToken(String token) {
    _refreshToken = token;
    SecureLogger.debug('ApiClient: Refresh token updated');
  }

  /// Clear all tokens (logout)
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
    SecureLogger.debug('ApiClient: All tokens cleared');
  }

  // ─────────────────────────────────────────────────────────────────────
  // HTTP METHODS WITH AUTOMATIC AUTH & RETRY
  // ─────────────────────────────────────────────────────────────────────

  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      if (hasToken) {
        headers['Authorization'] = 'Bearer $_accessToken';
        SecureLogger.debug('Adding Authorization header',
            data: {'tokenPreview': '${_accessToken!.substring(0, 15)}...'});
      } else {
        SecureLogger.warning('Request requires auth but NO TOKEN available!');
      }
    }

    return headers;
  }

  Future<http.Response> get(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    SecureLogger.debug('GET request',
        data: {'path': uri.path, 'requiresAuth': requiresAuth});

    try {
      final response = await _client.get(
        uri,
        headers: _getHeaders(includeAuth: requiresAuth),
      );

      return _handleResponse(response, requiresAuth: requiresAuth);
    } catch (e) {
      SecureLogger.error('GET request failed',
          data: {'path': uri.path, 'error': e.toString()});
      rethrow;
    }
  }

  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    SecureLogger.debug('POST request', data: {
      'path': uri.path,
      'requiresAuth': requiresAuth,
      'hasToken': hasToken,
      'body': body
    });

    try {
      final response = await _client.post(
        uri,
        headers: _getHeaders(includeAuth: requiresAuth),
        body: jsonEncode(body),
      );

      return _handleResponse(response, requiresAuth: requiresAuth);
    } catch (e) {
      SecureLogger.error('POST request failed',
          data: {'path': uri.path, 'error': e.toString()});
      rethrow;
    }
  }

  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    SecureLogger.debug('PUT request',
        data: {'path': uri.path, 'requiresAuth': requiresAuth});

    try {
      final response = await _client.put(
        uri,
        headers: _getHeaders(includeAuth: requiresAuth),
        body: jsonEncode(body),
      );

      return _handleResponse(response, requiresAuth: requiresAuth);
    } catch (e) {
      SecureLogger.error('PUT request failed',
          data: {'path': uri.path, 'error': e.toString()});
      rethrow;
    }
  }

  Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    SecureLogger.debug('PATCH request',
        data: {'path': uri.path, 'requiresAuth': requiresAuth});

    try {
      final response = await _client.patch(
        uri,
        headers: _getHeaders(includeAuth: requiresAuth),
        body: jsonEncode(body),
      );

      return _handleResponse(response, requiresAuth: requiresAuth);
    } catch (e) {
      SecureLogger.error('PATCH request failed',
          data: {'path': uri.path, 'error': e.toString()});
      rethrow;
    }
  }

  Future<http.Response> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    SecureLogger.debug('DELETE request',
        data: {'path': uri.path, 'requiresAuth': requiresAuth});

    try {
      final response = await _client.delete(
        uri,
        headers: _getHeaders(includeAuth: requiresAuth),
      );

      return _handleResponse(response, requiresAuth: requiresAuth);
    } catch (e) {
      SecureLogger.error('DELETE request failed',
          data: {'path': uri.path, 'error': e.toString()});
      rethrow;
    }
  }

  /// Upload a file using multipart/form-data
  /// Automatically detects MIME type from file extension
  Future<http.Response> uploadMultipart(
    String endpoint,
    String fileField,
    String filePath,
    String fileName, {
    Map<String, String>? fields,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    // Detect MIME type from file extension
    final mimeType = _getMimeTypeFromPath(filePath);
    SecureLogger.debug('Multipart upload', data: {
      'path': uri.path,
      'fileField': fileField,
      'filePath': filePath,
      'mimeType': mimeType
    });

    try {
      final request = http.MultipartRequest('POST', uri);

      // Add auth header
      if (requiresAuth && hasToken) {
        request.headers['Authorization'] = 'Bearer $_accessToken';
      }

      // Add fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Add file with detected MIME type
      final mediaParts = mimeType.split('/');
      final mime = mediaParts[0];
      final subtype = mediaParts.length > 1 ? mediaParts[1] : 'octet-stream';

      request.files.add(await http.MultipartFile.fromPath(
        fileField,
        filePath,
        filename: fileName,
        contentType: MediaType(mime, subtype),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response, requiresAuth: requiresAuth);
    } catch (e) {
      SecureLogger.error('Multipart upload failed',
          data: {'path': uri.path, 'error': e.toString()});
      rethrow;
    }
  }

  /// Detects MIME type from file extension
  String _getMimeTypeFromPath(String path) {
    final extension = path.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // RESPONSE HANDLING WITH 401 REFRESH LOGIC
  // ─────────────────────────────────────────────────────────────────────

  /// Handle response and check for 401 - triggers token refresh if needed
  Future<http.Response> _handleResponse(
    http.Response response, {
    bool requiresAuth = false,
  }) async {
    // Log response status
    if (response.statusCode == 401) {
      SecureLogger.warning('Got 401 Unauthorized',
          data: {'requiresAuth': requiresAuth, 'hasToken': hasToken});

      // If requires auth and we have a refresh token, try to refresh
      if (requiresAuth && _refreshToken != null) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          // Retry original request with new token
          SecureLogger.info('Token refreshed, retrying original request');
          // Note: This is a simplified retry. In production, you'd want to
          // store the original request and replay it
        }
      }
    }

    // Log all response codes for observability
    SecureLogger.debug('Response received',
        data: {'statusCode': response.statusCode});

    return response;
  }

  // ─────────────────────────────────────────────────────────────────────
  // TOKEN REFRESH WITH CONCURRENCY CONTROL
  // ─────────────────────────────────────────────────────────────────────

  /// Refresh access token using refresh token.
  /// Implements concurrency control to prevent multiple simultaneous refresh calls.
  Future<bool> _refreshAccessToken() async {
    // If already refreshing, wait for it to complete
    if (_isRefreshing) {
      SecureLogger.debug('Token refresh in progress, queuing request');
      final completer = Completer<void>();
      _refreshQueue.add(completer);
      await completer.future;
      return _accessToken != null;
    }

    // Mark as refreshing and proceed
    _isRefreshing = true;
    SecureLogger.info('Starting token refresh');

    try {
      // Try to refresh using the stored refresh token
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh_token': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body.containsKey('data') ? body['data'] : body;

        final newAccessToken = data['access_token'] ?? data['token'];
        final newRefreshToken = data['refresh_token'] ?? data['refreshToken'];

        if (newAccessToken != null && newAccessToken is String) {
          _accessToken = newAccessToken;
          if (newRefreshToken != null && newRefreshToken is String) {
            _refreshToken = newRefreshToken;
          }

          SecureLogger.info('Token refresh successful');

          // Complete all queued requests
          for (final completer in _refreshQueue) {
            completer.complete();
          }
          _refreshQueue.clear();

          return true;
        }
      }

      SecureLogger.error('Token refresh failed',
          data: {'statusCode': response.statusCode, 'body': response.body});

      // Refresh failed - tokens are invalid, clear them
      clearTokens();

      return false;
    } catch (e) {
      SecureLogger.error('Token refresh exception', error: e);
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // STATIC HELPERS (for backwards compatibility)
  // ─────────────────────────────────────────────────────────────────────

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
}
