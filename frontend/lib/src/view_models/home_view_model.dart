import 'package:flutter/material.dart';
import '../models/video_model.dart';
import '../utils/file_picker_helper.dart';
import '../utils/backend_service.dart';

class HomeViewModel extends ChangeNotifier {
  List<VideoModel>? videos;
  bool isLoading = false;

  Future<void> pickVideos() async {
    final pickedFiles = await FilePickerHelper.pickMultipleVideos();
    if (pickedFiles == null || pickedFiles.isEmpty) return;

    isLoading = true;
    videos = null;
    notifyListeners();

    final thumbnailUrl = await BackendService.uploadVideoAndGetThumbnail(
      pickedFiles.first.path,
    );

    if (thumbnailUrl == null) {
      debugPrint('⚠️ Failed to get thumbnail');
      isLoading = false;
      notifyListeners();
      return;
    }

    debugPrint('✅ Thumbnail received (${pickedFiles.length} video(s) selected)');

    videos = pickedFiles
        .map((f) => VideoModel(path: f.path))
        .toList()
      ..[0] = VideoModel(path: pickedFiles.first.path, thumbnailUrl: thumbnailUrl);

    isLoading = false;
    notifyListeners();
  }

  String? get thumbnailUrl => videos?.first.thumbnailUrl;

  bool get hasVideos => videos != null && videos!.isNotEmpty;

  bool get isBulk => (videos?.length ?? 0) > 1;
}
