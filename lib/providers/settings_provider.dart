import 'package:flutter/material.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/storage/local_storage.dart';

class SettingsProvider extends ChangeNotifier {
  String _baseUrl = ApiEndpoints.defaultBaseUrl;
  bool _isPinging = false;
  String? _pingMessage;
  bool? _pingSuccess;
  int? _pingLatency;

  String get baseUrl => _baseUrl;
  bool get isPinging => _isPinging;
  String? get pingMessage => _pingMessage;
  bool? get pingSuccess => _pingSuccess;
  int? get pingLatency => _pingLatency;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _baseUrl = await LocalStorage.getBaseUrl();
    notifyListeners();
  }

  Future<void> setBaseUrl(String newUrl) async {
    String cleanUrl = newUrl.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'http://$cleanUrl';
    }
    _baseUrl = cleanUrl;
    await LocalStorage.saveBaseUrl(_baseUrl);
    notifyListeners();
  }

  Future<bool> testConnection([String? testUrl]) async {
    _isPinging = true;
    _pingMessage = null;
    _pingSuccess = null;
    _pingLatency = null;
    notifyListeners();

    final targetUrl = testUrl ?? _baseUrl;
    final res = await ApiClient.pingServer(targetUrl);

    _isPinging = false;
    _pingSuccess = res['success'] == true;
    _pingLatency = res['latencyMs'];
    _pingMessage = res['message'];
    notifyListeners();

    return _pingSuccess ?? false;
  }
}
