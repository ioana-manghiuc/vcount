import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../view_models/video_player_view_model.dart';

class VideoPlayerScreen extends StatelessWidget {
  const VideoPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VideoPlayerViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: vm.hasVideo
                  ? Video(
                      controller: vm.videoController,
                      fit: BoxFit.contain,
                    )
                  : const Center(
                      child: Text(
                        'No video selected',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<VideoPlayerViewModel>().pickAndLoadVideo();
              },
              icon: const Icon(Icons.video_file),
              label: const Text('Select video'),
            ),
          ),
        ],
      ),
    );
  }
}