import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendService {
  static const backendUrl = 'http://127.0.0.1:8000';

  static Future<String?> uploadVideoAndGetThumbnail(String videoPath) async {
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('$backendUrl/upload_frame'),
  );

  request.files.add(
    await http.MultipartFile.fromPath('video', videoPath),
  );

  final response = await request.send();

  if (response.statusCode == 200) {
    final body = await response.stream.bytesToString();
    final json = jsonDecode(body);

    return '$backendUrl${json['thumbnail_url']}';
  } else {
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
      print('    Points (${(dir['points'] as List).length} total):');
      for (int i = 0; i < (dir['points'] as List).length; i++) {
        final point = (dir['points'] as List)[i];
        print('      Point $i: x=${point['x']}, y=${point['y']}');
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