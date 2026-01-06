import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayerViewModel extends ChangeNotifier {
  final Player _player = Player();
  late final VideoController videoController = VideoController(_player);

  bool _hasVideo = false;
  bool get hasVideo => _hasVideo;

  Future<void> pickAndLoadVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    await _player.open(Media(result.files.single.path!));
    _hasVideo = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}