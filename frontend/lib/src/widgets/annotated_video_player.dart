import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../localization/app_localizations.dart';

class AnnotatedVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const AnnotatedVideoPlayer({super.key, required this.videoUrl});

  @override
  State<AnnotatedVideoPlayer> createState() => _AnnotatedVideoPlayerState();
}

class _AnnotatedVideoPlayerState extends State<AnnotatedVideoPlayer> {
  late Player _player;
  late VideoController _videoController;
  OverlayEntry? _fullscreenEntry;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    const backendUrl = 'http://127.0.0.1:8000';
    final fullUrl = '$backendUrl${widget.videoUrl}';

    _player = Player();
    _videoController = VideoController(_player);
    _player.open(Media(fullUrl), play: false).catchError((error) {
      debugPrint('Error initializing video: $error');
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: _player.stream.position,
      builder: (context, snapshotPosition) {
        return StreamBuilder<Duration>(
          stream: _player.stream.duration,
          builder: (context, snapshotDuration) {
            return StreamBuilder<bool>(
              stream: _player.stream.playing,
              builder: (context, snapshotPlaying) {
                final isPlaying = snapshotPlaying.data ?? false;
                final position = snapshotPosition.data ?? Duration.zero;
                final duration = snapshotDuration.data ?? Duration.zero;
                final isEnded = duration > Duration.zero &&
                    position >= duration - const Duration(milliseconds: 100);

                if (duration == Duration.zero) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)?.translate('loadingVideo') ??
                              'Loading video...',
                        ),
                      ],
                    ),
                  );
                }

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (isPlaying) {
                          _player.pause();
                        } else {
                          if (isEnded) {
                            _player.seek(Duration.zero);
                          }
                          _player.play();
                        }
                      },
                      child: Container(
                        color: Colors.black,
                        child: Center(
                          child: Video(controller: _videoController),
                        ),
                      ),
                    ),
                    if (!isPlaying)
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(12),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
