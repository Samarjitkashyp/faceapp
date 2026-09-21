import 'package:flutter/material.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/storage/local_storage.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    final token = await LocalStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      // Try to load cached user first
      _currentUser = await LocalStorage.getUser();

      // Refresh profile from server
      final res = await ApiClient.get(ApiEndpoints.profile);
      if (res.success && res.data != null) {
        final userData = res.data['data'] ?? res.data;
        if (userData is Map<String, dynamic>) {
          _currentUser = UserModel.fromJson(userData);
          await LocalStorage.saveUser(_currentUser!);
        }
      } else if (res.statusCode == 401) {
        // Token expired
        await logout();
      }
    }

    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiClient.post(
      ApiEndpoints.login,
      body: {
        'username': username.trim(),
        'password': password,
      },
    );

    _isLoading = false;

    if (res.success && res.data != null) {
      final data = res.data as Map<String, dynamic>;
      final access = data['access'] ?? data['data']?['access'];
      final refresh = data['refresh'] ?? data['data']?['refresh'];

      if (access != null && refresh != null) {
        await LocalStorage.saveTokens(access: access, refresh: refresh);
      }

      final userMap = data['user'] ?? data['data']?['user'];
      if (userMap != null && userMap is Map<String, dynamic>) {
        _currentUser = UserModel.fromJson(userMap);
        await LocalStorage.saveUser(_currentUser!);
      } else {
        // Fetch profile
        final profRes = await ApiClient.get(ApiEndpoints.profile);
        if (profRes.success && profRes.data != null) {
          final pMap = profRes.data['data'] ?? profRes.data;
          _currentUser = UserModel.fromJson(pMap);
          await LocalStorage.saveUser(_currentUser!);
        }
      }

      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message ?? 'Invalid username or password';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? employeeId,
    String? phoneNumber,
    String? address,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiClient.post(
      ApiEndpoints.register,
      body: {
        'username': username.trim(),
        'email': email.trim(),
        'password': password,
        'first_name': firstName ?? '',
        'last_name': lastName ?? '',
        'employee_id': employeeId ?? '',
        'phone_number': phoneNumber ?? '',
        'address': address ?? '',
      },
    );

    _isLoading = false;

    if (res.success) {
      // Auto login
      return await login(username, password);
    } else {
      _errorMessage = res.message ?? 'Registration failed';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await LocalStorage.clearAuthSession();
    _currentUser = null;
    notifyListeners();
  }
}
