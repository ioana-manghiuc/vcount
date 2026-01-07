import 'dart:convert';

import 'package:http/http.dart' as http;

class BackendService {
  static const backendUrl = 'http://127.0.0.1:8000';

  static Future<String?> uploadVideoAndGetThumbnail(String videoPath) async {
    final request = http.MultipartRequest('POST', Uri.parse('$backendUrl/upload_frame'));
    request.files.add(await http.MultipartFile.fromPath('video', videoPath));

    final response = await request.send();
    if (response.statusCode == 200) {
      final bodyString = await response.stream.bytesToString();
      final Map<String, dynamic> bodyJson = jsonDecode(bodyString);
      if (bodyJson.containsKey('thumbnail_url')) {
        return '$backendUrl${bodyJson['thumbnail_url']}';
      }
      return null;
    } else {
      print('Upload failed: ${response.statusCode}');
      return null;
    }
  }

  static Future<bool> sendDirections(String videoPath, List<List<double>> directions) async {
    final request = http.MultipartRequest('POST', Uri.parse('$backendUrl/count_vehicles'));
    request.files.add(await http.MultipartFile.fromPath('video', videoPath));
    request.fields['directions'] = jsonEncode(directions); 

    final response = await request.send();
    return response.statusCode == 200;
  }
}