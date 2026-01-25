import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BackendService {
  static const backendUrl = 'http://127.0.0.1:8000';

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
      onTimeout: () {
        throw TimeoutException('Backend did not respond');
      },
    );

    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      final json = jsonDecode(body);
      final thumbnailUrl = '$backendUrl${json['thumbnail_url']}';
      return thumbnailUrl;
    } else {
      final errorBody = await response.stream.bytesToString();
      debugPrint('❌ upload_frame failed (${response.statusCode}): $errorBody');
      return null;
    }
  } catch (e, stackTrace) {
    debugPrint('❌ Error uploading video: $e');
    debugPrint(stackTrace.toString());
    return null;
  }
}

  static Future<Map<String, dynamic>?> sendDirections(
    String videoPath,
    List<Map<String, dynamic>> directions,
    String modelName,
  ) async {
    try {
      final directionsJson = jsonEncode(directions);
      
      debugPrint('\n=== SENDING TO BACKEND ===');
      debugPrint('Video Path: $videoPath');
      debugPrint('Model: $modelName');
      debugPrint('Directions JSON:');
      debugPrint(directionsJson);
      debugPrint('\nDirections Detail:');
      for (final dir in directions) {
        debugPrint('  Direction: ${dir['from']} → ${dir['to']}');
        debugPrint('    ID: ${dir['id']}');
        debugPrint('    Color: ${dir['color']}');
        debugPrint('    Lines (${(dir['lines'] as List).length} total):');
        for (int i = 0; i < (dir['lines'] as List).length; i++) {
          final line = (dir['lines'] as List)[i];
          debugPrint('      Line $i: x1=${line['x1']}, y1=${line['y1']}, x2=${line['x2']}, y2=${line['y2']}, isEntry=${line['isEntry']}');
        }
      }
      debugPrint('========================\n');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$backendUrl/count_vehicles'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('video', videoPath),
      );

      request.fields['directions'] = directionsJson;
      request.fields['model_name'] = modelName;

      final response = await request.send().timeout(
        const Duration(seconds: 3600),
        onTimeout: () {
          throw TimeoutException('Vehicle counting did not complete');
        },
      );

      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final resultsJson = jsonDecode(body) as Map<String, dynamic>;
        return resultsJson;
      } else {
        debugPrint('❌ Backend returned status code: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error sending directions: $e');
      debugPrint(stackTrace.toString());
      return null;
    }
  }
}