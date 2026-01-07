import 'dart:io';
import 'package:path/path.dart' as p;

Future<File?> extractFrame(String videoPath) async {
  final tempDir = Directory.systemTemp;
  final framePath = p.join(tempDir.path, 'video_frame.png');

  final ffmpegPath = 'ffmpeg';

  final result = await Process.run(ffmpegPath, [
    '-i', videoPath,
    '-ss', '00:00:01.000', 
    '-vframes', '1',
    framePath,
  ]);

  if (result.exitCode == 0 && File(framePath).existsSync()) {
    return File(framePath);
  } else {
    print('FFmpeg error: ${result.stderr}');
    return null;
  }
}