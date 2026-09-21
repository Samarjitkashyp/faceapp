class ApiEndpoints {
  // Default base URL (PC Wi-Fi LAN IP reachable from phone)
  static String get defaultBaseUrl => 'http://192.168.0.237:8000';

  // Pre-configured options for easy 1-tap switching
  static const String lanBaseUrl = 'http://192.168.0.237:8000';
  static const String emulatorBaseUrl = 'http://10.0.2.2:8000';
  static const String localhostBaseUrl = 'http://127.0.0.1:8000';

  // Auth endpoints
  static const String login = '/api/v1/auth/login/';
  static const String register = '/api/v1/auth/register/';
  static const String profile = '/api/v1/auth/profile/';
  static const String refreshToken = '/api/v1/auth/token/refresh/';

  // Faces endpoints
  static const String facesList = '/api/v1/faces/';
  static const String faceRegister = '/api/v1/faces/register/';
  static String faceDelete(int id) => '/api/v1/faces/$id/';

  // Recognition endpoints
  static const String recognize = '/api/v1/recognition/recognize/';

  // Attendance endpoints
  static const String checkIn = '/api/v1/attendance/check-in/';
  static const String attendanceLogs = '/api/v1/attendance/logs/';
  static const String attendanceSummary = '/api/v1/attendance/summary/';
}
