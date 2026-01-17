import 'package:file_picker/file_picker.dart';
import '../models/video_model.dart';

class FilePickerHelper {
  static Future<VideoModel?> pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) return null;

    final videoPath = result.files.single.path!;

    return VideoModel(path: videoPath);
  }
}