class AttendanceLog {
  final int id;
  final int? userId;
  final String logType;
  final DateTime timestamp;
  final double confidence;
  final String deviceInfo;
  final bool verified;
  final String? userName;

  AttendanceLog({
    required this.id,
    this.userId,
    required this.logType,
    required this.timestamp,
    required this.confidence,
    required this.deviceInfo,
    required this.verified,
    this.userName,
  });

  bool get isCheckIn => logType.toLowerCase() == 'check_in';

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    return AttendanceLog(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user'] is int ? json['user'] : int.tryParse(json['user']?.toString() ?? ''),
      logType: json['log_type'] ?? 'check_in',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      deviceInfo: json['device_info'] ?? 'Flutter App',
      verified: json['verified'] == true,
      userName: json['user_name'] ?? json['username'],
    );
  }
}
