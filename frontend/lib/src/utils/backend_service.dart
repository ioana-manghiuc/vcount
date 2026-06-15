import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'cancel_token.dart';
import 'package:uuid/uuid.dart';

class BackendService {
  static const backendUrl = 'http://127.0.0.1:8000';
  static http.Client? _httpClient;
  static CancelToken _cancelToken = CancelToken();
  static String? _currentProcessingId;

  static void cancelProcessing() {
    debugPrint('Cancelling processing request...');
    _cancelToken.cancel();

    if (_currentProcessingId != null) {
      _sendCancelRequest(_currentProcessingId!).then((_) {
        if (_httpClient != null) {
          _httpClient!.close();
          _httpClient = null;
          debugPrint('Closed HTTP client connection');
        }
      });
    } else {
      if (_httpClient != null) {
        _httpClient!.close();
        _httpClient = null;
        debugPrint('Closed HTTP client connection');
      }
    }
  }

  static Future<void> _sendCancelRequest(String processingId) async {
    try {
      debugPrint('Sending cancel request to backend for ID: $processingId');
      final response = await http.post(
        Uri.parse('$backendUrl/cancel_processing/$processingId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('Backend acknowledged cancellation');
      } else {
        debugPrint('Backend cancel response: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Could not send cancel request to backend: $e');
    }
  }

  static void resetCancelToken() {
    _cancelToken = CancelToken();
  }


  static String? get currentProcessingId => _currentProcessingId;



  static Future<String?> uploadVideoAndGetThumbnail(String videoPath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$backendUrl/upload_frame'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('video', videoPath),
      );

      final response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Backend did not respond'),
      );

      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final json = jsonDecode(body);
        return '$backendUrl${json['thumbnail_url']}';
      } else {
        final errorBody = await response.stream.bytesToString();
        debugPrint('upload_frame failed (${response.statusCode}): $errorBody');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error uploading video: $e');
      debugPrint(stackTrace.toString());
      return null;
    }
  }

  static Future<Map<String, dynamic>?> sendVideos(
    List<String> videoPaths,
    List<Map<String, dynamic>> directions,
    String modelName,
    String intersectionName,
  ) async {
    assert(videoPaths.isNotEmpty, 'sendVideos requires at least one path');

    final isBulk = videoPaths.length > 1;
    final directionsJson = jsonEncode(directions);

    debugPrint('\n=== SENDING TO BACKEND ===');
    debugPrint('Mode: ${isBulk ? "bulk" : "single"}');
    debugPrint('Intersection: $intersectionName');
    debugPrint('Video count: ${videoPaths.length}');
    debugPrint('Model: $modelName');
    debugPrint('========================\n');

    try {
      resetCancelToken();
      _currentProcessingId = const Uuid().v4();
      debugPrint('📝 Processing ID: $_currentProcessingId');

      _httpClient = http.Client();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          isBulk
              ? '$backendUrl/count_vehicles_bulk'
              : '$backendUrl/count_vehicles',
        ),
      );

      final fieldName = isBulk ? 'videos' : 'video';
      for (final path in videoPaths) {
        request.files.add(await http.MultipartFile.fromPath(fieldName, path));
      }

      request.fields['directions'] = directionsJson;
      request.fields['model_name'] = modelName;
      request.fields['intersection_name'] = intersectionName;
      request.fields['processing_id'] = _currentProcessingId!;

      final requestFuture = _httpClient!.send(request);

      final response = await Future.any([
        requestFuture,
        _cancelToken.cancellationFuture
            .then((_) => throw _RequestCancelledException()),
      ]);

      if (_cancelToken.isCancelled) {
        debugPrint('⚠️ Processing was cancelled by user');
        return _cleanupAndReturn(null);
      }

      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final resultsJson = jsonDecode(body) as Map<String, dynamic>;
        debugPrint('✅ Processing complete');
        return _cleanupAndReturn(resultsJson);
      } else {
        final errorBody = await response.stream.bytesToString();
        debugPrint('❌ Backend returned ${response.statusCode}: $errorBody');
        return _cleanupAndReturn(null);
      }
    } on _RequestCancelledException {
      debugPrint('⚠️ Request was cancelled by user');
      return _cleanupAndReturn(null);
    } catch (e, stackTrace) {
      if (_cancelToken.isCancelled) {
        debugPrint('⚠️ Request was cancelled');
        return _cleanupAndReturn(null);
      }
      debugPrint('❌ Error sending videos: $e');
      debugPrint(stackTrace.toString());
      _currentProcessingId = null;
      return null;
    }
  }

  static T? _cleanupAndReturn<T>(T? value) {
    _httpClient?.close();
    _httpClient = null;
    _currentProcessingId = null;
    return value;
  }
}

class _RequestCancelledException implements Exception {
  @override
  String toString() => 'Request was cancelled by user';
}
