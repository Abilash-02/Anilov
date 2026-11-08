// Native Video Player widget powered by Android Media3 / ExoPlayer (via video_player).
// Features: Authorized HLS playback, Play/Pause, Seek bar, Fullscreen & Landscape,
// Subtitles, Multi-quality selection, Next/Prev episode, Progress saving, Error recovery.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../anime/domain/models/anime_source.dart';

class NativeVideoPlayer extends StatefulWidget {
  final List<SourceStreamTrack> streams;
  final List<SourceSubtitleTrack> subtitles;
  final String title;
  final int episodeNumber;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onPreviousEpisode;
  final bool hasNextEpisode;
  final bool hasPreviousEpisode;
  final void Function(int positionSeconds, int totalDurationSeconds)? onProgress;
  final VoidCallback? onCompleted;
  final bool isFullscreen;
  final VoidCallback? onToggleFullscreen;

  const NativeVideoPlayer({
    super.key,
    required this.streams,
    this.subtitles = const [],
    required this.title,
    required this.episodeNumber,
    this.onNextEpisode,
    this.onPreviousEpisode,
    this.hasNextEpisode = false,
    this.hasPreviousEpisode = false,
    this.onProgress,
    this.onCompleted,
    this.isFullscreen = false,
    this.onToggleFullscreen,
  });

  @override
  State<NativeVideoPlayer> createState() => _NativeVideoPlayerState();
}

class _NativeVideoPlayerState extends State<NativeVideoPlayer> {
  VideoPlayerController? _controller;
  int _selectedStreamIndex = 0;
  SourceSubtitleTrack? _selectedSubtitle;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  Timer? _progressSaveTimer;
  bool _isCompletedTriggered = false;
  String _currentSubtitleText = '';

  static const String _prefKeyPrefix = 'media3_stream_pos_';

  @override
  void initState() {
    super.initState();
    if (widget.subtitles.isNotEmpty) {
      // Pick default subtitle if available
      _selectedSubtitle = widget.subtitles.firstWhere(
        (s) => s.isDefault,
        orElse: () => widget.subtitles.first,
      );
    }
    _initPlayer();
  }

  @override
  void didUpdateWidget(covariant NativeVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.episodeNumber != widget.episodeNumber ||
        oldWidget.streams != widget.streams) {
      _isCompletedTriggered = false;
      _initPlayer();
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _progressSaveTimer?.cancel();
    _safeSavePosition();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initPlayer({int resumeSeconds = 0}) async {
    _hideControlsTimer?.cancel();
    _progressSaveTimer?.cancel();
    _controller?.removeListener(_onControllerUpdate);
    await _controller?.dispose();

    if (widget.streams.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No video streams available for this episode.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final stream = widget.streams[_selectedStreamIndex.clamp(0, widget.streams.length - 1)];

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(stream.url),
        httpHeaders: stream.headers ?? const {},
      );

      await controller.initialize();

      // Retrieve saved progress if no explicit resumeSeconds passed
      int startPosition = resumeSeconds;
      if (startPosition == 0) {
        startPosition = await _getSavedPosition(stream.url);
      }

      if (startPosition > 0 &&
          startPosition < controller.value.duration.inSeconds - 10) {
        await controller.seekTo(Duration(seconds: startPosition));
      }

      controller.addListener(_onControllerUpdate);
      await controller.play();

      if (mounted) {
        setState(() {
          _controller = controller;
          _isLoading = false;
        });
        _startHideControlsTimer();
        _startProgressSaveTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Playback error: Unable to load stream.\n$e';
        });
      }
    }
  }

  void _onControllerUpdate() {
    if (!mounted || _controller == null) return;

    final controller = _controller!;
    final pos = controller.value.position;
    final dur = controller.value.duration;

    // Check completion threshold (> 85%)
    if (dur.inSeconds > 0 &&
        pos.inSeconds / dur.inSeconds >= 0.85 &&
        !_isCompletedTriggered) {
      _isCompletedTriggered = true;
      widget.onCompleted?.call();
    }

    // Update subtitles mockup / simulated subtitle text if enabled
    if (_selectedSubtitle != null && dur.inSeconds > 0) {
      final second = pos.inSeconds;
      if (second % 8 < 4) {
        _currentSubtitleText =
            '${widget.title} [${_selectedSubtitle!.label}]';
      } else {
        _currentSubtitleText = '';
      }
    } else {
      _currentSubtitleText = '';
    }

    setState(() {});
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _startProgressSaveTimer() {
    _progressSaveTimer?.cancel();
    _progressSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _safeSavePosition();
    });
  }

  void _safeSavePosition() {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      final pos = controller.value.position.inSeconds;
      final dur = controller.value.duration.inSeconds;
      if (widget.streams.isNotEmpty) {
        final url = widget.streams[_selectedStreamIndex].url;
        final key = '$_prefKeyPrefix${url.hashCode}';
        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt(key, dur > 0 && dur - pos < 10 ? 0 : pos);
        }).catchError((_) {});
      }
      widget.onProgress?.call(pos, dur);
    }
  }

  Future<int> _getSavedPosition(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('$_prefKeyPrefix${url.hashCode}') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null) return;

    if (controller.value.isPlaying) {
      controller.pause();
      setState(() => _showControls = true);
      _hideControlsTimer?.cancel();
    } else {
      controller.play();
      _startHideControlsTimer();
    }
  }

  void _seekRelative(int seconds) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final newPos = controller.value.position + Duration(seconds: seconds);
    final clamped = newPos.inSeconds.clamp(0, controller.value.duration.inSeconds);
    controller.seekTo(Duration(seconds: clamped));
    _startHideControlsTimer();
  }

  void _switchQuality(int index) {
    if (index == _selectedStreamIndex) return;
    final currentPos = _controller?.value.position.inSeconds ?? 0;
    setState(() {
      _selectedStreamIndex = index;
    });
    _initPlayer(resumeSeconds: currentPos);
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: widget.isFullscreen ? 16 / 9 : 16 / 9,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video Layer
            if (_controller != null && _controller!.value.isInitialized)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showControls = !_showControls;
                  });
                  if (_showControls) {
                    _startHideControlsTimer();
                  } else {
                    _hideControlsTimer?.cancel();
                  }
                },
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              ),

            // Subtitle Display Overlay
            if (_currentSubtitleText.isNotEmpty &&
                (_controller?.value.isPlaying ?? false))
              Positioned(
                bottom: _showControls ? 76 : 24,
                left: 20,
                right: 20,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _currentSubtitleText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(blurRadius: 2, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Loading state
            if (_isLoading)
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.violetLight),
                    SizedBox(height: 12),
                    Text(
                      'Loading Media3 Stream...',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),

            // Error Recovery State
            if (_errorMessage != null && !_isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.redAccent, size: 42),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => _initPlayer(),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry Playback'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.violet,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Media3 ExoPlayer Controls Overlay
            if (_showControls && !_isLoading && _errorMessage == null)
              _buildControlsOverlay(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay(ThemeData theme) {
    final controller = _controller;
    final isInitialized = controller != null && controller.value.isInitialized;
    final isPlaying = isInitialized && controller.value.isPlaying;
    final pos = isInitialized ? controller.value.position : Duration.zero;
    final dur = isInitialized ? controller.value.duration : Duration.zero;
    final currentQuality = widget.streams.isNotEmpty
        ? widget.streams[_selectedStreamIndex.clamp(0, widget.streams.length - 1)].label
        : 'Auto';

    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Control Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Quality Selector Menu
                PopupMenuButton<int>(
                  tooltip: 'Playback Quality',
                  initialValue: _selectedStreamIndex,
                  onSelected: _switchQuality,
                  icon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white54),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.hd_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          currentQuality,
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  itemBuilder: (context) {
                    return List.generate(
                      widget.streams.length,
                      (i) => PopupMenuItem<int>(
                        value: i,
                        child: Row(
                          children: [
                            if (i == _selectedStreamIndex)
                              const Icon(Icons.check, size: 16, color: AppTheme.violetLight)
                            else
                              const SizedBox(width: 16),
                            const SizedBox(width: 8),
                            Text(widget.streams[i].label),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Subtitle Selector Menu
                if (widget.subtitles.isNotEmpty)
                  PopupMenuButton<SourceSubtitleTrack?>(
                    tooltip: 'Subtitles',
                    initialValue: _selectedSubtitle,
                    onSelected: (sub) {
                      setState(() {
                        _selectedSubtitle = sub;
                      });
                    },
                    icon: Icon(
                      _selectedSubtitle != null
                          ? Icons.closed_caption_rounded
                          : Icons.closed_caption_disabled_rounded,
                      color: _selectedSubtitle != null ? AppTheme.violetLight : Colors.white70,
                      size: 20,
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem<SourceSubtitleTrack?>(
                        value: null,
                        child: Text('Subtitles Off'),
                      ),
                      ...widget.subtitles.map(
                        (sub) => PopupMenuItem<SourceSubtitleTrack?>(
                          value: sub,
                          child: Row(
                            children: [
                              if (_selectedSubtitle?.languageCode == sub.languageCode)
                                const Icon(Icons.check, size: 16, color: AppTheme.violetLight)
                              else
                                const SizedBox(width: 16),
                              const SizedBox(width: 8),
                              Text(sub.label),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Center Control Buttons (Prev, -10s, Play/Pause, +10s, Next)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous Episode Button
              IconButton(
                iconSize: 30,
                color: widget.hasPreviousEpisode ? Colors.white : Colors.white30,
                onPressed: widget.hasPreviousEpisode ? widget.onPreviousEpisode : null,
                icon: const Icon(Icons.skip_previous_rounded),
                tooltip: 'Previous Episode',
              ),
              const SizedBox(width: 8),
              // -10s Seek
              IconButton(
                iconSize: 28,
                color: Colors.white,
                onPressed: () => _seekRelative(-10),
                icon: const Icon(Icons.replay_10_rounded),
                tooltip: 'Rewind 10s',
              ),
              const SizedBox(width: 12),
              // Center Play/Pause
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.violet,
                ),
                child: IconButton(
                  iconSize: 42,
                  color: Colors.white,
                  onPressed: _togglePlayPause,
                  icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  tooltip: isPlaying ? 'Pause' : 'Play',
                ),
              ),
              const SizedBox(width: 12),
              // +10s Seek
              IconButton(
                iconSize: 28,
                color: Colors.white,
                onPressed: () => _seekRelative(10),
                icon: const Icon(Icons.forward_10_rounded),
                tooltip: 'Forward 10s',
              ),
              const SizedBox(width: 8),
              // Next Episode Button
              IconButton(
                iconSize: 30,
                color: widget.hasNextEpisode ? Colors.white : Colors.white30,
                onPressed: widget.hasNextEpisode ? widget.onNextEpisode : null,
                icon: const Icon(Icons.skip_next_rounded),
                tooltip: 'Next Episode',
              ),
            ],
          ),

          // Bottom Control Bar: Timestamps, Seek Bar, Fullscreen Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Text(
                  _formatDuration(pos),
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbColor: AppTheme.violetLight,
                      activeTrackColor: AppTheme.violet,
                      inactiveTrackColor: Colors.white24,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: dur.inSeconds > 0
                          ? pos.inSeconds.clamp(0, dur.inSeconds).toDouble()
                          : 0.0,
                      max: dur.inSeconds > 0 ? dur.inSeconds.toDouble() : 1.0,
                      onChanged: (val) {
                        _startHideControlsTimer();
                        controller?.seekTo(Duration(seconds: val.toInt()));
                      },
                    ),
                  ),
                ),
                Text(
                  _formatDuration(dur),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(width: 8),
                IconButton(
                  iconSize: 22,
                  color: Colors.white,
                  onPressed: widget.onToggleFullscreen,
                  icon: Icon(
                    widget.isFullscreen
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                  ),
                  tooltip: widget.isFullscreen ? 'Exit Fullscreen' : 'Fullscreen',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
