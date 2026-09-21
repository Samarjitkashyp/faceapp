import 'package:flutter/foundation.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';

class EnrolledFace {
  final int id;
  final int? userId;
  final String imageUrl;
  final String faceLabel;
  final DateTime createdAt;
  final int vectorDimension;

  EnrolledFace({
    required this.id,
    this.userId,
    required this.imageUrl,
    required this.faceLabel,
    required this.createdAt,
    required this.vectorDimension,
  });

  factory EnrolledFace.fromJson(Map<String, dynamic> json) {
    return EnrolledFace(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user'] is int ? json['user'] : int.tryParse(json['user'].toString()),
      imageUrl: json['image_url'] ?? json['image'] ?? '',
      faceLabel: json['face_label'] ?? 'front',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      vectorDimension: json['dimension'] ?? 512,
    );
  }
}

class FaceProvider extends ChangeNotifier {
  List<EnrolledFace> _faces = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  List<EnrolledFace> get faces => _faces;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  bool get hasFaceEnrolled => _faces.isNotEmpty;
  bool get isFullyCalibrated => _faces.length >= 5;

  void clear() {
    _faces = [];
    _isLoading = false;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void setFacesForTesting(List<EnrolledFace> faces) {
    _faces = faces;
    notifyListeners();
  }

  Future<void> fetchEnrolledFaces({int? currentUserId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final endpoint = '${ApiEndpoints.facesList}?user_id=me';
    final res = await ApiClient.get(endpoint);

    _isLoading = false;

    if (res.success && res.data != null) {
      final list = (res.data['data'] ?? res.data) as List<dynamic>?;
      if (list != null) {
        var parsed = list.map((item) => EnrolledFace.fromJson(item as Map<String, dynamic>)).toList();
        if (currentUserId != null) {
          parsed = parsed.where((f) => f.userId == null || f.userId == currentUserId).toList();
        }
        _faces = parsed;
      }
    } else {
      _errorMessage = res.message ?? 'Failed to load face profiles';
    }
    notifyListeners();
  }

  Future<bool> enrollFace({
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
    String faceLabel = 'front',
    int? currentUserId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final res = await ApiClient.postMultipart(
      ApiEndpoints.faceRegister,
      fileFieldName: 'image',
      filePath: filePath,
      fileBytes: fileBytes,
      fileName: fileName,
      fields: {
        'face_label': faceLabel,
      },
    );

    _isLoading = false;

    if (res.success) {
      _successMessage = 'Face enrolled successfully! 512-D Vector created.';
      await fetchEnrolledFaces(currentUserId: currentUserId);
      return true;
    } else {
      _errorMessage = res.message ?? 'Face registration failed. Please ensure lighting is good and face is clear.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteFace(int faceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiClient.delete(ApiEndpoints.faceDelete(faceId));

    _isLoading = false;

    if (res.success) {
      _faces.removeWhere((f) => f.id == faceId);
      _successMessage = 'Face sample removed';
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message ?? 'Failed to delete face';
      notifyListeners();
      return false;
    }
  }
}
