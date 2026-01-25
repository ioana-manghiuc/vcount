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
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        tooltip: 'Fullscreen',
                        onPressed: _showFullscreen,
                        icon: const Icon(Icons.fullscreen, color: Colors.white),
                      ),
                    ),
                    if (!isPlaying)
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
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

  Widget _buildProgressBar(Duration position, Duration duration, BuildContext context) {
    final double durationMs = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
    final double positionMs = position.inMilliseconds > 0 ? position.inMilliseconds.toDouble() : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            min: 0,
            max: durationMs,
            value: positionMs.clamp(0.0, durationMs),
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: Theme.of(context).colorScheme.primaryContainer,
            onChanged: (value) {
              _player.seek(Duration(milliseconds: value.toInt()));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                _formatDuration(duration),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours == 0) {
      return '$minutes:$seconds';
    }
    return '$hours:$minutes:$seconds';
  }

  void _showFullscreen() {
    if (_fullscreenEntry != null) return;
    
    final overlay = Overlay.of(context);
    _fullscreenEntry = OverlayEntry(
      builder: (ctx) {
        return Material(
          color: Colors.black.withOpacity(0.92),
          child: SafeArea(
            child: StreamBuilder<Duration>(
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
                              child: Center(
                                child: Video(controller: _videoController),
                              ),
                            ),
                            // Exit fullscreen control
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Exit fullscreen',
                                    onPressed: _hideFullscreen,
                                    icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: _buildProgressBar(position, duration, context),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );

    overlay.insert(_fullscreenEntry!);
  }

  void _hideFullscreen() {
    _fullscreenEntry?.remove();
    _fullscreenEntry = null;
  }
}
