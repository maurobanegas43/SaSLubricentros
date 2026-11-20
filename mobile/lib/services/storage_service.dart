import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// StorageService handles persistent storage using shared_preferences.
/// This allows user data and tokens to persist across app restarts.
class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ─── Token Management ───────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    final prefs = await _preferences;
    await prefs.setString(_tokenKey, token);
    debugPrint('Token saved to persistent storage');
  }

  Future<String?> getToken() async {
    final prefs = await _preferences;
    return prefs.getString(_tokenKey);
  }

  Future<void> deleteToken() async {
    final prefs = await _preferences;
    await prefs.remove(_tokenKey);
    debugPrint('Token removed from persistent storage');
  }

  // ─── Refresh Token Management ─────────────────────────────────────────────

  Future<void> saveRefreshToken(String refreshToken) async {
    final prefs = await _preferences;
    await prefs.setString(_refreshTokenKey, refreshToken);
    debugPrint('Refresh token saved to persistent storage');
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _preferences;
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    final prefs = await _preferences;
    await prefs.remove(_refreshTokenKey);
    debugPrint('Refresh token removed from persistent storage');
  }

  // ─── User Management ────────────────────────────────────────────────────────

  Future<void> saveUser(User user) async {
    final prefs = await _preferences;
    final userJson = jsonEncode(user.toJson());
    await prefs.setString(_userKey, userJson);
    debugPrint('User saved to persistent storage: ${user.name}');
  }

  Future<User?> getUser() async {
    final prefs = await _preferences;
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;

    try {
      final Map<String, dynamic> data = jsonDecode(userJson);
      return User.fromJson(data);
    } catch (e) {
      debugPrint('Error parsing stored user: $e');
      return null;
    }
  }

  Future<void> deleteUser() async {
    final prefs = await _preferences;
    await prefs.remove(_userKey);
    debugPrint('User removed from persistent storage');
  }

  // ─── Clear All ─────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    final prefs = await _preferences;
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
    debugPrint('All storage cleared');
  }
}
