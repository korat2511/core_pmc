import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class LocalStorageService {
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _isLoggedInKey = 'is_logged_in';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // User data methods
  static Future<void> saveUser(UserModel user) async {
    if (_prefs == null) await init();
    await _prefs!.setString(_userKey, json.encode(user.toJson()));
  }

  static UserModel? getUser() {
    if (_prefs == null) return null;
    final userData = _prefs!.getString(_userKey);
    if (userData != null) {
      try {
        return UserModel.fromJson(json.decode(userData));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Token methods
  static Future<void> saveToken(String token) async {
    if (_prefs == null) await init();
    await _prefs!.setString(_tokenKey, token);
  }

  static String? getToken() {
    if (_prefs == null) return null;
    return _prefs!.getString(_tokenKey);
  }

  // Login status methods
  static Future<void> setLoggedIn(bool isLoggedIn) async {
    if (_prefs == null) await init();
    await _prefs!.setBool(_isLoggedInKey, isLoggedIn);
  }

  static bool isLoggedIn() {
    if (_prefs == null) return false;
    return _prefs!.getBool(_isLoggedInKey) ?? false;
  }

  // Clear all data (logout)
  static Future<void> clearAll() async {
    if (_prefs == null) await init();
    await _prefs!.clear();
  }

  // Save complete login data
  static Future<void> saveLoginData(UserModel user, String token) async {
    await saveUser(user);
    await saveToken(token);
    await setLoggedIn(true);
  }

  // Check if user is valid (has token and user data)
  static bool isValidUser() {
    final user = getUser();
    final token = getToken();
    final isLoggedIn = LocalStorageService.isLoggedIn();
    log("Token == $token");
    return user != null && token != null && isLoggedIn;
  }
} 