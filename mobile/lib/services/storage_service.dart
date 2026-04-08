import 'package:flutter/foundation.dart';
import '../models/user.dart';

// TODO: Implementar con flutter_secure_storage en producción
// Por ahora usamos memoria para desarrollo rápido
class StorageService {
  static String? _token;
  static String? _refreshToken;
  static User? _user;

  Future<void> saveToken(String token) async {
    _token = token;
    debugPrint('Token saved (in-memory)');
  }

  Future<String?> getToken() async {
    return _token;
  }

  Future<void> deleteToken() async {
    _token = null;
    debugPrint('Token deleted');
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    _refreshToken = refreshToken;
    debugPrint('Refresh token saved (in-memory)');
  }

  Future<String?> getRefreshToken() async {
    return _refreshToken;
  }

  Future<void> deleteRefreshToken() async {
    _refreshToken = null;
    debugPrint('Refresh token deleted');
  }

  Future<void> saveUser(User user) async {
    _user = user;
    debugPrint('User saved (in-memory)');
  }

  Future<User?> getUser() async {
    return _user;
  }

  Future<void> clearAll() async {
    _token = null;
    _refreshToken = null;
    _user = null;
    debugPrint('Storage cleared');
  }
}
