import 'package:flutter/material.dart';
import '../models/video_model.dart';
import '../utils/file_picker_helper.dart';
import '../utils/backend_service.dart';

class HomeViewModel extends ChangeNotifier {
  VideoModel? video;
  bool isLoading = false;

  Future<void> pickVideo() async {
    final pickedFile = await FilePickerHelper.pickVideo();
    if (pickedFile == null) return;

    isLoading = true;
    notifyListeners();

    final thumbnailUrl = await BackendService.uploadVideoAndGetThumbnail(pickedFile.path);
    if (thumbnailUrl == null) {
      print('⚠️ Failed to get thumbnail from backend');
      isLoading = false;
      notifyListeners();
      return;
    }
    
    print('✅ Successfully received thumbnail');

    video = VideoModel(path: pickedFile.path, thumbnailUrl: thumbnailUrl);

    isLoading = false;
    notifyListeners();
  }
}