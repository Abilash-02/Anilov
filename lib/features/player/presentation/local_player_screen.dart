import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_theme.dart';

/// Screen providing authorized offline video playback for user-selected local media files.
/// Includes play/pause, seeking, full-screen, resume position, buffering indicator, and error recovery.
class LocalPlayerScreen extends StatefulWidget {
  final String? initialFilePath;

  const LocalPlayerScreen({super.key, this.initialFilePath});

  @override
  State<LocalPlayerScreen> createState() => _LocalPlayerScreenState();
}

class _LocalPlayerScreenState extends State<LocalPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  String? _currentFilePath;
  String? _currentFileName;
  bool _isLoading = false;
  String? _errorMessage;

  static const String _prefPrefix = 'local_video_pos_';

  @override
  void initState() {
    super.initState();
    if (widget.initialFilePath != null) {
      _loadVideo(widget.initialFilePath!);
    }
  }

  @override
  void dispose() {
    _saveCurrentPosition();
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _saveCurrentPosition() async {
    if (_videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized &&
        _currentFilePath != null) {
      try {
        final pos = _videoPlayerController!.value.position.inSeconds;
        final total = _videoPlayerController!.value.duration.inSeconds;
        final prefs = await SharedPreferences.getInstance();
        // If within 10 seconds of end, reset position to 0
        final savePos = (total > 0 && total - pos < 10) ? 0 : pos;
        await prefs.setInt('$_prefPrefix${_currentFilePath.hashCode}', savePos);
      } catch (e) {
        debugPrint('Error saving playback position: $e');
      }
    }
  }

  Future<int> _getSavedPosition(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('$_prefPrefix${path.hashCode}') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _pickVideoFile() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final files = await FilePicker.pickFiles(
        type: FileType.video,
      );

      if (files != null && files.isNotEmpty) {
        final path = files.first.path;
        if (path != null) {
          await _loadVideo(path, files.first.name);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not access file picker: $e';
      });
    }
  }

  Future<void> _loadVideo(String path, [String? name]) async {
    await _saveCurrentPosition();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _chewieController?.dispose();
      await _videoPlayerController?.dispose();

      final file = File(path);
      if (!await file.exists()) {
        throw Exception('Selected file does not exist on disk.');
      }

      final controller = VideoPlayerController.file(file);
      await controller.initialize();

      final savedSecs = await _getSavedPosition(path);
      if (savedSecs > 0 && savedSecs < controller.value.duration.inSeconds) {
        await controller.seekTo(Duration(seconds: savedSecs));
      }

      if (!mounted) return;

      final isDark = Theme.of(context).brightness == Brightness.dark;
      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.violet,
          handleColor: AppTheme.violetLight,
          bufferedColor: isDark ? Colors.white24 : Colors.black12,
          backgroundColor: isDark ? Colors.white10 : Colors.black26,
        ),
      );

      if (mounted) {
        setState(() {
          _videoPlayerController = controller;
          _chewieController = chewie;
          _currentFilePath = path;
          _currentFileName = name ?? file.uri.pathSegments.last;
          _isLoading = false;
        });

        if (savedSecs > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Resumed playback from ${_formatDuration(Duration(seconds: savedSecs))}',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Unable to play video: $e\nPlease ensure the format is supported (e.g. MP4, MKV).';
        });
      }
    }
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Media Player'),
        actions: [
          IconButton(
            tooltip: 'Choose Video',
            icon: const Icon(Icons.folder_open_rounded),
            onPressed: _pickVideoFile,
          ),
        ],
      ),
      body: _buildBody(theme, isDark),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.violet),
            SizedBox(height: 16),
            Text('Loading video...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 54),
              const SizedBox(height: 16),
              const Text(
                'Playback Error',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppTheme.darkOnSurfaceMuted
                      : AppTheme.lightOnSurfaceMuted,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text('Pick Another File'),
                onPressed: _pickVideoFile,
              ),
            ],
          ),
        ),
      );
    }

    if (_chewieController != null &&
        _videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      return Column(
        children: [
          // Video Playback Area
          AspectRatio(
            aspectRatio: _videoPlayerController!.value.aspectRatio > 0
                ? _videoPlayerController!.value.aspectRatio
                : 16 / 9,
            child: Chewie(controller: _chewieController!),
          ),

          // File Info & Legal Notice Bar
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.movie_creation_outlined,
                        color: AppTheme.violetLight, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentFileName ?? 'Local Video',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Duration: ${_formatDuration(_videoPlayerController!.value.duration)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.darkOnSurfaceMuted
                                  : AppTheme.lightOnSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: const Text('Change'),
                      onPressed: _pickVideoFile,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Legal Disclaimer
                Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkSurface
                        : AppTheme.lightSurfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2E2E38)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_user_outlined,
                          size: 20, color: AppTheme.violetLight),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Offline local playback only. Anilov does not host, scrape, or stream unauthorized media. You are playing files stored locally on your device.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.darkOnSurfaceMuted
                                : AppTheme.lightOnSurfaceMuted,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Default Empty State
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.violet.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.video_collection_outlined,
                size: 64,
                color: AppTheme.violetLight,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Local Media Player',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Play your own legally acquired video files stored on your device with resume position support.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDark
                    ? AppTheme.darkOnSurfaceMuted
                    : AppTheme.lightOnSurfaceMuted,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text('Select Video File'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: _pickVideoFile,
            ),
            const SizedBox(height: 16),
            Text(
              'Supports MP4, MKV, WebM, and other device-supported formats.',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppTheme.darkOnSurfaceMuted
                    : AppTheme.lightOnSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
