// Official YouTube trailer dialog and player widget

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/playback_source.dart';

class TrailerPlayerDialog extends StatefulWidget {
  final String videoId;
  final String title;

  const TrailerPlayerDialog({
    super.key,
    required this.videoId,
    required this.title,
  });

  static Future<void> show(
    BuildContext context, {
    required String videoId,
    required String title,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => TrailerPlayerDialog(
        videoId: videoId,
        title: title,
      ),
    );
  }

  @override
  State<TrailerPlayerDialog> createState() => _TrailerPlayerDialogState();
}

class _TrailerPlayerDialogState extends State<TrailerPlayerDialog> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  Future<void> _openExternal() async {
    final uri = Uri.parse('https://www.youtube.com/watch?v=${widget.videoId}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${widget.title} - Official Trailer',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // YouTube Player AspectRatio
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: YoutubePlayer(
                controller: _controller,
                aspectRatio: 16 / 9,
              ),
            ),
          ),

          // Footer with official source attribution and external link
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified, size: 16, color: Colors.red),
                    SizedBox(width: 6),
                    Text(
                      'Official YouTube Embed',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _openExternal,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Open in YouTube'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Dialog for evaluating external or user-provided links (such as share.google links)
class ExternalLinkNoticeDialog extends StatelessWidget {
  final LinkEvaluationResult evaluation;

  const ExternalLinkNoticeDialog({super.key, required this.evaluation});

  static Future<void> show(BuildContext context, String url) {
    final evaluation = LinkEvaluationResult.evaluate(url);
    return showDialog(
      context: context,
      builder: (context) => ExternalLinkNoticeDialog(evaluation: evaluation),
    );
  }

  Future<void> _launch() async {
    final uri = Uri.parse(evaluation.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.shield_outlined, color: AppTheme.violetLight),
          const SizedBox(width: 8),
          Text(evaluation.description, style: const TextStyle(fontSize: 16)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            evaluation.policyNotice,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? AppTheme.darkOnSurface : AppTheme.lightOnSurface,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceVariant : AppTheme.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              evaluation.url,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            _launch();
          },
          icon: const Icon(Icons.open_in_browser, size: 18),
          label: const Text('Open in Browser'),
        ),
      ],
    );
  }
}
