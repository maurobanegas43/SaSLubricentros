import 'package:flutter/foundation.dart';
import '../models/user.dart';

// TODO: Implementar con flutter_secure_storage en producción
// Por ahora usamos memoria para desarrollo rápido
class StorageService {
  static String? _token;
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

  Future<void> saveUser(User user) async {
    _user = user;
    debugPrint('User saved (in-memory)');
  }

  Future<User?> getUser() async {
    return _user;
  }

  Future<void> clearAll() async {
    _token = null;
    _user = null;
    debugPrint('Storage cleared');
  }
}
