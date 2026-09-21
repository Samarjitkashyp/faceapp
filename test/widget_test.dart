import 'package:flutter_test/flutter_test.dart';
import 'package:face_app/models/user_model.dart';
import 'package:face_app/models/recognition_result.dart';
import 'package:face_app/models/attendance_log.dart';
import 'package:face_app/providers/face_provider.dart';
import 'package:face_app/core/constants/api_endpoints.dart';

void main() {
  group('VisionAI Face App Unit & Model Tests', () {
    test('ApiEndpoints default values test', () {
      expect(ApiEndpoints.lanBaseUrl, 'http://192.168.0.237:8000');
      expect(ApiEndpoints.emulatorBaseUrl, 'http://10.0.2.2:8000');
      expect(ApiEndpoints.localhostBaseUrl, 'http://127.0.0.1:8000');
      expect(ApiEndpoints.login, '/api/v1/auth/login/');
      expect(ApiEndpoints.recognize, '/api/v1/recognition/recognize/');
      expect(ApiEndpoints.checkIn, '/api/v1/attendance/check-in/');
    });

    test('UserModel serialization and deserialization', () {
      final json = {
        'id': 1,
        'username': 'samarjit',
        'email': 'samarjit@example.com',
        'first_name': 'Samarjit',
        'last_name': 'Singh',
        'employee_id': 'EMP-001',
        'phone_number': '+91 9876543210',
        'address': 'Guwahati, Assam',
        'role': 'admin',
        'created_at': '2026-09-21T12:00:00Z',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 1);
      expect(user.username, 'samarjit');
      expect(user.fullName, 'Samarjit Singh');
      expect(user.employeeId, 'EMP-001');
      expect(user.phoneNumber, '+91 9876543210');
      expect(user.address, 'Guwahati, Assam');
      expect(user.role, 'admin');

      final serialized = user.toJson();
      expect(serialized['username'], 'samarjit');
      expect(serialized['email'], 'samarjit@example.com');
    });

    test('RecognitionResult model test', () {
      final json = {
        'matched': true,
        'confidence': 0.985,
        'similarity': 0.892,
        'person': {
          'id': 2,
          'username': 'rahul',
          'email': 'rahul@example.com',
          'first_name': 'Rahul',
          'last_name': 'Sharma',
          'employee_id': 'EMP-104',
          'role': 'member',
        },
        'bounding_box': [50, 60, 180, 200],
      };

      final result = RecognitionResult.fromJson(json);
      expect(result.matched, true);
      expect(result.confidence, 0.985);
      expect(result.similarity, 0.892);
      expect(result.person, isNotNull);
      expect(result.person!.fullName, 'Rahul Sharma');
      expect(result.boundingBox, [50, 60, 180, 200]);
    });

    test('AttendanceLog model test', () {
      final json = {
        'id': 10,
        'log_type': 'check_in',
        'timestamp': '2026-09-21T09:30:00Z',
        'confidence': 0.97,
        'device_info': 'Flutter Android',
        'verified': true,
        'user_name': 'Samarjit',
      };

      final log = AttendanceLog.fromJson(json);
      expect(log.id, 10);
      expect(log.logType, 'check_in');
      expect(log.isCheckIn, true);
      expect(log.confidence, 0.97);
      expect(log.verified, true);
    });

    test('FaceProvider isFullyCalibrated and state management test', () {
      final faceProvider = FaceProvider();
      expect(faceProvider.faces.isEmpty, true);
      expect(faceProvider.isFullyCalibrated, false);
      expect(faceProvider.hasFaceEnrolled, false);

      // Simulate 3 enrolled angles (incomplete calibration)
      faceProvider.setFacesForTesting([
        EnrolledFace(id: 1, imageUrl: '', faceLabel: 'front', createdAt: DateTime.now(), vectorDimension: 512),
        EnrolledFace(id: 2, imageUrl: '', faceLabel: 'left', createdAt: DateTime.now(), vectorDimension: 512),
        EnrolledFace(id: 3, imageUrl: '', faceLabel: 'right', createdAt: DateTime.now(), vectorDimension: 512),
      ]);
      expect(faceProvider.hasFaceEnrolled, true);
      expect(faceProvider.isFullyCalibrated, false);
      expect(faceProvider.faces.length, 3);

      // Simulate all 5 angles enrolled (fully calibrated)
      faceProvider.setFacesForTesting([
        EnrolledFace(id: 1, imageUrl: '', faceLabel: 'front', createdAt: DateTime.now(), vectorDimension: 512),
        EnrolledFace(id: 2, imageUrl: '', faceLabel: 'left', createdAt: DateTime.now(), vectorDimension: 512),
        EnrolledFace(id: 3, imageUrl: '', faceLabel: 'right', createdAt: DateTime.now(), vectorDimension: 512),
        EnrolledFace(id: 4, imageUrl: '', faceLabel: 'up', createdAt: DateTime.now(), vectorDimension: 512),
        EnrolledFace(id: 5, imageUrl: '', faceLabel: 'smile', createdAt: DateTime.now(), vectorDimension: 512),
      ]);
      expect(faceProvider.hasFaceEnrolled, true);
      expect(faceProvider.isFullyCalibrated, true);
      expect(faceProvider.faces.length, 5);

      // Verify that clear() resets state properly
      faceProvider.clear();
      expect(faceProvider.isFullyCalibrated, false);
      expect(faceProvider.faces.length, 0);
    });
  });
}
