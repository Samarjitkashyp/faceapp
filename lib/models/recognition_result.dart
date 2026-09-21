import 'user_model.dart';

class RecognitionResult {
  final bool matched;
  final double confidence;
  final double similarity;
  final UserModel? person;
  final List<int>? boundingBox;
  final String? message;

  RecognitionResult({
    required this.matched,
    required this.confidence,
    required this.similarity,
    this.person,
    this.boundingBox,
    this.message,
  });

  factory RecognitionResult.fromJson(Map<String, dynamic> json) {
    UserModel? user;
    if (json['person'] != null && json['person'] is Map<String, dynamic>) {
      user = UserModel.fromJson(json['person']);
    }

    List<int>? bbox;
    if (json['bounding_box'] != null && json['bounding_box'] is List) {
      bbox = (json['bounding_box'] as List).map((e) => (e as num).toInt()).toList();
    }

    return RecognitionResult(
      matched: json['matched'] == true,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      similarity: (json['similarity'] as num?)?.toDouble() ?? 0.0,
      person: user,
      boundingBox: bbox,
      message: json['message'],
    );
  }
}
