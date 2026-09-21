import 'package:flutter/foundation.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/attendance_log.dart';
import '../models/recognition_result.dart';

class AttendanceProvider extends ChangeNotifier {
  bool _isRecognizing = false;
  bool _isLoadingLogs = false;
  RecognitionResult? _lastResult;
  List<AttendanceLog> _logs = [];
  String? _errorMessage;
  String? _successMessage;

  bool get isRecognizing => _isRecognizing;
  bool get isLoadingLogs => _isLoadingLogs;
  RecognitionResult? get lastResult => _lastResult;
  List<AttendanceLog> get logs => _logs;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // Check if today already has check-in
  bool get hasCheckedInToday {
    final now = DateTime.now();
    return _logs.any((l) =>
        l.isCheckIn &&
        l.timestamp.year == now.year &&
        l.timestamp.month == now.month &&
        l.timestamp.day == now.day);
  }

  void clear() {
    _logs = [];
    _lastResult = null;
    _isRecognizing = false;
    _isLoadingLogs = false;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<RecognitionResult?> recognizeFace({
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    _isRecognizing = true;
    _errorMessage = null;
    _lastResult = null;
    notifyListeners();

    final res = await ApiClient.postMultipart(
      ApiEndpoints.recognize,
      fileFieldName: 'image',
      filePath: filePath,
      fileBytes: fileBytes,
      fileName: fileName,
    );

    _isRecognizing = false;

    if (res.success && res.data != null) {
      final data = (res.data['data'] ?? res.data) as Map<String, dynamic>;
      _lastResult = RecognitionResult.fromJson(data);
      notifyListeners();
      return _lastResult;
    } else {
      _errorMessage = res.message ?? 'Recognition failed or no face detected';
      notifyListeners();
      return null;
    }
  }

  Future<bool> recordAttendance({
    String logType = 'check_in',
    double confidence = 0.95,
    int? currentUserId,
  }) async {
    _isRecognizing = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final Map<String, dynamic> payload = {
      'log_type': logType,
      'confidence': confidence,
      'device_info': 'Flutter App (${defaultTargetPlatform.name})',
    };
    if (currentUserId != null) {
      payload['user_id'] = currentUserId;
    }

    final res = await ApiClient.post(
      ApiEndpoints.checkIn,
      body: payload,
    );

    _isRecognizing = false;

    if (res.success) {
      _successMessage = logType == 'check_in'
          ? 'Check-In verified & recorded successfully!'
          : 'Check-Out recorded successfully!';
      await fetchLogs(currentUserId: currentUserId);
      return true;
    } else {
      _errorMessage = res.message ?? 'Failed to record attendance';
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchLogs({int? currentUserId}) async {
    _isLoadingLogs = true;
    notifyListeners();

    final endpoint = '${ApiEndpoints.attendanceLogs}?user_id=me';
    final res = await ApiClient.get(endpoint);

    _isLoadingLogs = false;

    if (res.success && res.data != null) {
      final list = (res.data['data'] ?? res.data) as List<dynamic>?;
      if (list != null) {
        var parsed = list.map((item) => AttendanceLog.fromJson(item as Map<String, dynamic>)).toList();
        if (currentUserId != null) {
          parsed = parsed.where((l) => l.userId == null || l.userId == currentUserId).toList();
        }
        _logs = parsed;
      }
    } else {
      _errorMessage = res.message ?? 'Failed to load attendance logs';
    }
    notifyListeners();
  }
}
