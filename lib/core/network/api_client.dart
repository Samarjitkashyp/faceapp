import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../storage/local_storage.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    required this.statusCode,
  });
}

class ApiClient {
  static Future<Map<String, String>> _getHeaders({bool isMultipart = false}) async {
    final token = await LocalStorage.getAccessToken();
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // GET Request
  static Future<ApiResponse<dynamic>> get(String endpoint) async {
    try {
      final baseUrl = await LocalStorage.getBaseUrl();
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 15),
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // POST Request
  static Future<ApiResponse<dynamic>> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final baseUrl = await LocalStorage.getBaseUrl();
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();

      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 20));

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // DELETE Request
  static Future<ApiResponse<dynamic>> delete(String endpoint) async {
    try {
      final baseUrl = await LocalStorage.getBaseUrl();
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();

      final response = await http.delete(uri, headers: headers).timeout(
        const Duration(seconds: 15),
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // MULTIPART Request (for Face image uploads)
  static Future<ApiResponse<dynamic>> postMultipart(
    String endpoint, {
    required String fileFieldName,
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
    Map<String, String>? fields,
  }) async {
    try {
      final baseUrl = await LocalStorage.getBaseUrl();
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(isMultipart: true);

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (fileBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            fileFieldName,
            fileBytes,
            filename: fileName ?? 'face_upload.jpg',
          ),
        );
      } else if (filePath != null && filePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            fileFieldName,
            filePath,
            filename: fileName,
          ),
        );
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'File upload error: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Ping Server to check latency and connectivity
  static Future<Map<String, dynamic>> pingServer(String baseUrl) async {
    final stopwatch = Stopwatch()..start();
    try {
      final uri = Uri.parse('$baseUrl/dashboard/login/');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      stopwatch.stop();

      final isOk = response.statusCode >= 200 && response.statusCode < 400;
      return {
        'success': isOk,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'statusCode': response.statusCode,
        'message': isOk ? 'Connected successfully' : 'Server returned ${response.statusCode}',
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'message': 'Cannot reach server: $e',
      };
    }
  }

  static ApiResponse<dynamic> _handleResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = response.body;
    }

    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;

    String? message;
    if (body is Map<String, dynamic>) {
      message = body['message'] ?? body['detail'] ?? body['error'];
      if (message == null && body['errors'] != null) {
        message = body['errors'].toString();
      }
    }

    return ApiResponse(
      success: isSuccess,
      data: body,
      message: message ?? (isSuccess ? 'Success' : 'Request failed with status ${response.statusCode}'),
      statusCode: response.statusCode,
    );
  }
}
