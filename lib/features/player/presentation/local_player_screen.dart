import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/video_source_evaluator.dart';

/// Screen providing video playback for user-selected local media files and authorized direct streams.
/// Includes play/pause, seeking, full-screen, resume position, buffering indicator, error recovery,
/// and external webpage handling for unsupported cloud share links.
class LocalPlayerScreen extends StatefulWidget {
  final String? initialFilePath;
  final String? initialUrl;

  const LocalPlayerScreen({
    super.key,
    this.initialFilePath,
    this.initialUrl,
  });

  @override
  State<LocalPlayerScreen> createState() => _LocalPlayerScreenState();
}

class _LocalPlayerScreenState extends State<LocalPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  String? _currentSource;
  String? _currentSourceName;
  bool _isNetworkSource = false;
  bool _isLoading = false;
  String? _errorMessage;

  static const String _prefPrefix = 'local_video_pos_';

  @override
  void initState() {
    super.initState();
    if (widget.initialFilePath != null) {
      _loadLocalVideo(widget.initialFilePath!);
    } else if (widget.initialUrl != null) {
      _handleUrlInput(widget.initialUrl!);
    }
  }

  @override
  void dispose() {
    _safeSaveCurrentPosition();
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  void _safeSaveCurrentPosition() {
    final controller = _videoPlayerController;
    final source = _currentSource;
    if (controller != null && controller.value.isInitialized && source != null) {
      try {
        final pos = controller.value.position.inSeconds;
        final total = controller.value.duration.inSeconds;
        final savePos = (total > 0 && total - pos < 10) ? 0 : pos;
        final key = '$_prefPrefix${source.hashCode}';
        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt(key, savePos);
        }).catchError((_) {});
      } catch (_) {}
    }
  }

  Future<int> _getSavedPosition(String sourceKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('$_prefPrefix${sourceKey.hashCode}') ?? 0;
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

      if (files.isNotEmpty) {
        final file = files.first;
        final path = file.path;
        if (path != null) {
          await _loadLocalVideo(path, file.name);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not access file picker: $e';
      });
    }
  }

  Future<void> _loadLocalVideo(String path, [String? name]) async {
    _safeSaveCurrentPosition();

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
          _currentSource = path;
          _currentSourceName = name ?? file.uri.pathSegments.last;
          _isNetworkSource = false;
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

  Future<void> _loadNetworkStream(String url, [String? displayName]) async {
    _safeSaveCurrentPosition();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _chewieController?.dispose();
      await _videoPlayerController?.dispose();

      final uri = Uri.parse(url);
      final controller = VideoPlayerController.networkUrl(uri);
      await controller.initialize();

      final savedSecs = await _getSavedPosition(url);
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
        final pathSegments = uri.pathSegments;
        final fallbackName = pathSegments.isNotEmpty && pathSegments.last.isNotEmpty
            ? pathSegments.last
            : uri.host;

        setState(() {
          _videoPlayerController = controller;
          _chewieController = chewie;
          _currentSource = url;
          _currentSourceName = displayName ?? fallbackName;
          _isNetworkSource = true;
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
              'Unable to stream video: $e\nPlease check that the URL points to a directly playable, accessible stream (e.g. MP4, HLS).';
        });
      }
    }
  }

  Future<void> _handleUrlInput(String url) async {
    final evaluation = await VideoSourceEvaluator.evaluate(url);

    if (!mounted) return;

    if (evaluation.isInvalid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(evaluation.message ?? 'Invalid URL provided.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (evaluation.isWebpage) {
      _showUnsupportedUrlDialog(
        title: 'External Webpage Detected',
        message: evaluation.message ??
            'This URL points to an external webpage or cloud share page rather than a directly playable media stream.',
        url: url,
        canLaunchExternally: evaluation.canLaunchExternally,
      );
      return;
    }

    // Direct playable video stream
    await _loadNetworkStream(url);
  }

  void _showUnsupportedUrlDialog({
    required String title,
    required String message,
    required String url,
    required bool canLaunchExternally,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: AppTheme.violetLight, size: 24),
            const SizedBox(width: 8),
            Flexible(child: Text(title, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: AppTheme.violetLight,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          if (canLaunchExternally)
            FilledButton.icon(
              icon: const Icon(Icons.open_in_browser_rounded, size: 18),
              label: const Text('Open Externally'),
              onPressed: () async {
                Navigator.pop(dialogContext);
                final uri = Uri.tryParse(url);
                if (uri != null) {
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not open URL: $e')),
                      );
                    }
                  }
                }
              },
            ),
        ],
      ),
    );
  }

  Future<void> _promptForVideoUrl() async {
    final textController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.link_rounded, color: AppTheme.violetLight),
                SizedBox(width: 8),
                Text('Open Video URL / Stream',
                    style: TextStyle(fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter a direct video stream URL (MP4, MKV, HLS .m3u8). Webpages and cloud drives cannot be streamed directly.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      labelText: 'Video URL',
                      hintText: 'https://example.com/video.mp4',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => textController.clear(),
                      ),
                    ),
                    keyboardType: TextInputType.url,
                    autofocus: true,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Quick Preset / Test Link:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  ActionChip(
                    avatar: const Icon(Icons.cloud_outlined, size: 16),
                    label: const Text(
                      'Google Share Link',
                      style: TextStyle(fontSize: 11),
                    ),
                    tooltip: 'Insert provided Google Share link',
                    onPressed: () {
                      setDialogState(() {
                        textController.text =
                            VideoSourceEvaluator.defaultGoogleShareUrl;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Open'),
                onPressed: () {
                  final input = textController.text.trim();
                  Navigator.pop(dialogContext);
                  if (input.isNotEmpty) {
                    _handleUrlInput(input);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
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
            tooltip: 'Open Video URL / Stream',
            icon: const Icon(Icons.link_rounded),
            onPressed: _promptForVideoUrl,
          ),
          IconButton(
            tooltip: 'Choose Video File',
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
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.folder_open_rounded),
                  label: const Text('Pick Local File'),
                  onPressed: _pickVideoFile,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('Enter Video URL'),
                  onPressed: _promptForVideoUrl,
                ),
              ],
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

        // Source Info & Legal Notice Bar
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _isNetworkSource
                        ? Icons.stream_rounded
                        : Icons.movie_creation_outlined,
                    color: AppTheme.violetLight,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentSourceName ??
                              (_isNetworkSource ? 'Video Stream' : 'Local Video'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Duration: ${_formatDuration(_videoPlayerController!.value.duration)} • ${_isNetworkSource ? 'Network Stream' : 'Local File'}',
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
                    onPressed: () {
                      if (_isNetworkSource) {
                        _promptForVideoUrl();
                      } else {
                        _pickVideoFile();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Legal / Architecture Disclaimer
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
                        _isNetworkSource
                            ? 'Direct authorized stream playback. Anilov does not host, index, or scrape unauthorized media.'
                            : 'Offline local playback only. Anilov does not host, scrape, or stream unauthorized media. You are playing files stored locally on your device.',
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
    child: SingleChildScrollView(
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
            'Play your own legally acquired video files or authorized direct video streams with resume position support.',
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: _pickVideoFile,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.link_rounded),
            label: const Text('Open Video URL / Stream'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: _promptForVideoUrl,
          ),
          const SizedBox(height: 20),
          ActionChip(
            avatar: const Icon(Icons.public_rounded, size: 16),
            label: const Text(
              'Test Google Share Link',
              style: TextStyle(fontSize: 12),
            ),
            onPressed: () =>
                _handleUrlInput(VideoSourceEvaluator.defaultGoogleShareUrl),
          ),
          const SizedBox(height: 16),
          Text(
            'Supports MP4, MKV, WebM, and direct HLS/DASH streams.',
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
