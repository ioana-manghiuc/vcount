import 'dart:async';
import 'dart:convert';
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
      return null;
    }
  } catch (e, stackTrace) {
    return null;
  }
}

  static Future<bool> sendDirections(
    String videoPath,
    List<Map<String, dynamic>> directions,
    String modelName,
  ) async {
    final directionsJson = jsonEncode(directions);
    
    print('\n=== SENDING TO BACKEND ===');
    print('Video Path: $videoPath');
    print('Model: $modelName');
    print('Directions JSON:');
    print(directionsJson);
    print('\nDirections Detail:');
    for (final dir in directions) {
      print('  Direction: ${dir['from']} → ${dir['to']}');
      print('    ID: ${dir['id']}');
      print('    Color: ${dir['color']}');
      print('    Lines (${(dir['lines'] as List).length} total):');
      for (int i = 0; i < (dir['lines'] as List).length; i++) {
        final line = (dir['lines'] as List)[i];
        print('      Line $i: x1=${line['x1']}, y1=${line['y1']}, x2=${line['x2']}, y2=${line['y2']}, isEntry=${line['isEntry']}');
      }
    }
    print('========================\n');
    
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$backendUrl/count_vehicles'),
    );

    request.files.add(
      await http.MultipartFile.fromPath('video', videoPath),
    );

    request.fields['directions'] = directionsJson;
    request.fields['model_name'] = modelName;

    final response = await request.send();
    return response.statusCode == 200;
  }
}