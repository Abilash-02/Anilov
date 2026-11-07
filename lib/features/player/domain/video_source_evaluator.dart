import 'dart:io';

/// Classification of an external video URL.
enum VideoUrlType {
  /// Direct playable video media stream (e.g. MP4, MKV, HLS .m3u8).
  directStream,

  /// Webpage, portal, or cloud share link (e.g. share.google, drive.google.com).
  webpageOrExternal,

  /// Malformed URL or unsupported URI scheme.
  invalidUrl,
}

/// Evaluation result for a video URL.
class VideoUrlEvaluation {
  final VideoUrlType type;
  final String url;
  final String? message;
  final bool canLaunchExternally;

  const VideoUrlEvaluation({
    required this.type,
    required this.url,
    this.message,
    this.canLaunchExternally = false,
  });

  bool get isDirectStream => type == VideoUrlType.directStream;
  bool get isWebpage => type == VideoUrlType.webpageOrExternal;
  bool get isInvalid => type == VideoUrlType.invalidUrl;
}

/// Evaluator that safely checks video URLs without scraping, authentication bypass,
/// or DRM circumventing.
class VideoSourceEvaluator {
  /// Default external link provided for testing and evaluation.
  static const String defaultGoogleShareUrl =
      'https://share.google/0XKcrS1PHQZW2NgkN';

  /// Commonly supported direct video file extensions.
  static const List<String> supportedVideoExtensions = [
    '.mp4',
    '.m4v',
    '.mkv',
    '.webm',
    '.mov',
    '.3gp',
    '.flv',
    '.ts',
    '.m3u8',
    '.mpd',
  ];

  /// Domains known to serve web pages or cloud sharing interfaces rather than raw video streams.
  static const List<String> knownWebShareDomains = [
    'share.google',
    'drive.google.com',
    'docs.google.com',
    'youtube.com',
    'youtu.be',
    'vimeo.com',
    'dailymotion.com',
    'twitch.tv',
    'dropbox.com',
    'onedrive.live.com',
  ];

  /// Evaluates whether a URL is a direct playable video stream,
  /// a webpage/cloud share link (such as Google Share), or an invalid URL.
  static Future<VideoUrlEvaluation> evaluate(
    String rawUrl, {
    Future<String?> Function(Uri uri)? probeContentType,
  }) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return const VideoUrlEvaluation(
        type: VideoUrlType.invalidUrl,
        url: '',
        message: 'Please enter a video URL.',
      );
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        (!uri.isScheme('http') && !uri.isScheme('https')) ||
        uri.host.isEmpty) {
      return VideoUrlEvaluation(
        type: VideoUrlType.invalidUrl,
        url: trimmed,
        message:
            'Invalid URL format. Please provide a valid HTTP or HTTPS video URL.',
      );
    }

    final host = uri.host.toLowerCase();

    // Check known cloud share and webpage hosting domains
    if (knownWebShareDomains
        .any((domain) => host == domain || host.endsWith('.$domain'))) {
      if (host.contains('share.google') || host.contains('google.com')) {
        return VideoUrlEvaluation(
          type: VideoUrlType.webpageOrExternal,
          url: trimmed,
          message:
              'The link "$trimmed" is a Google Share webpage, not an accessible direct video stream.\n\n'
              'Local Player only plays authorized direct video files or raw video streams (e.g. MP4, MKV, HLS). '
              'To view this content, open it in an external web browser.',
          canLaunchExternally: true,
        );
      }
      return VideoUrlEvaluation(
        type: VideoUrlType.webpageOrExternal,
        url: trimmed,
        message:
            'This link points to an external platform ($host) rather than a direct playable stream.\n\n'
            'Please use the official platform or open in an external browser.',
        canLaunchExternally: true,
      );
    }

    // Check direct video file extensions in URL path
    final path = uri.path.toLowerCase();
    for (final ext in supportedVideoExtensions) {
      if (path.endsWith(ext)) {
        return VideoUrlEvaluation(
          type: VideoUrlType.directStream,
          url: trimmed,
        );
      }
    }

    // If extension is not evident, probe headers safely
    try {
      String? contentType;
      if (probeContentType != null) {
        contentType = await probeContentType(uri);
      } else {
        contentType = await _probeUrlContentType(uri);
      }

      if (contentType != null) {
        final lowerType = contentType.toLowerCase();
        if (lowerType.contains('video/') ||
            lowerType.contains('application/x-mpegurl') ||
            lowerType.contains('application/vnd.apple.mpegurl') ||
            lowerType.contains('application/dash+xml')) {
          return VideoUrlEvaluation(
            type: VideoUrlType.directStream,
            url: trimmed,
          );
        } else if (lowerType.contains('text/html') ||
            lowerType.contains('application/xhtml+xml')) {
          return VideoUrlEvaluation(
            type: VideoUrlType.webpageOrExternal,
            url: trimmed,
            message:
                'This link points to an HTML webpage rather than a direct playable video stream.\n\n'
                'To view this webpage, open it in an external web browser.',
            canLaunchExternally: true,
          );
        }
      }
    } catch (_) {
      // In case probe fails (e.g. network restricted or HEAD unsupported),
      // allow fallback to direct stream initialization.
    }

    return VideoUrlEvaluation(
      type: VideoUrlType.directStream,
      url: trimmed,
    );
  }

  static Future<String?> _probeUrlContentType(Uri uri) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      final request = await client.headUrl(uri);
      request.followRedirects = true;
      request.maxRedirects = 3;
      final response = await request.close();
      client.close();
      return response.headers.contentType?.mimeType;
    } catch (_) {
      return null;
    }
  }
}
