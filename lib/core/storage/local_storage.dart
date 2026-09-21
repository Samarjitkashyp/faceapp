import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../constants/api_endpoints.dart';

class LocalStorage {
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserData = 'user_data';
  static const String _keyBaseUrl = 'base_url';

  // Base URL
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBaseUrl) ?? ApiEndpoints.defaultBaseUrl;
  }

  static Future<void> saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, url);
  }

  // Tokens
  static Future<void> saveTokens({required String access, required String refresh}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, access);
    await prefs.setString(_keyRefreshToken, refresh);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  // User Data
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserData, jsonEncode(user.toJson()));
  }

  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyUserData);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  // Clear Session
  static Future<void> clearAuthSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUserData);
  }

  // AI Voice & Speech Settings
  static const String _keyTtsPreset = 'tts_preset';
  static const String _keyTtsLanguage = 'tts_language';
  static const String _keyTtsPitch = 'tts_pitch';
  static const String _keyTtsRate = 'tts_rate';

  static Future<String> getTtsPreset() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTtsPreset) ?? 'female';
  }

  static Future<void> saveTtsPreset(String preset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTtsPreset, preset);
  }

  static Future<String> getTtsLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTtsLanguage) ?? 'en-US';
  }

  static Future<void> saveTtsLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTtsLanguage, language);
  }

  static Future<double> getTtsPitch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyTtsPitch) ?? 1.15;
  }

  static Future<void> saveTtsPitch(double pitch) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTtsPitch, pitch);
  }

  static Future<double> getTtsRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyTtsRate) ?? 0.48;
  }

  static Future<void> saveTtsRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTtsRate, rate);
  }
}
