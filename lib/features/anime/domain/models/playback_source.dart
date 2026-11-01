// PlaybackSource abstraction and authorized legal source evaluation

enum PlaybackSourceType {
  officialTrailer,
  officialWhereToWatch,
  localMedia,
  externalLink,
}

abstract class PlaybackSource {
  final PlaybackSourceType type;
  final String title;

  const PlaybackSource({required this.type, required this.title});
}

class OfficialTrailerSource extends PlaybackSource {
  final String youtubeVideoId;
  final String? thumbnailUrl;

  const OfficialTrailerSource({
    required this.youtubeVideoId,
    this.thumbnailUrl,
    String title = 'Official YouTube Trailer',
  }) : super(type: PlaybackSourceType.officialTrailer, title: title);
}

class WhereToWatchSource extends PlaybackSource {
  final String siteName;
  final String url;
  final String? iconUrl;

  const WhereToWatchSource({
    required this.siteName,
    required this.url,
    this.iconUrl,
  }) : super(type: PlaybackSourceType.officialWhereToWatch, title: siteName);
}

class LinkEvaluationResult {
  final String url;
  final bool isAuthorizedApi;
  final bool isDirectVideoUrl;
  final bool requiresExternalApp;
  final String description;
  final String policyNotice;

  const LinkEvaluationResult({
    required this.url,
    required this.isAuthorizedApi,
    required this.isDirectVideoUrl,
    required this.requiresExternalApp,
    required this.description,
    required this.policyNotice,
  });

  static LinkEvaluationResult evaluate(String url) {
    final uri = Uri.tryParse(url);
    final host = uri?.host.toLowerCase() ?? '';

    if (host == 'share.google' || host.endsWith('.share.google') || host == 'drive.google.com') {
      return LinkEvaluationResult(
        url: url,
        isAuthorizedApi: false,
        isDirectVideoUrl: false,
        requiresExternalApp: true,
        description: 'Google Cloud Shared Link ($host)',
        policyNotice:
            'This link is a cloud share/redirect URL, not a direct streaming media file or authorized video player API. '
            'In accordance with Section 4 Legal Boundaries, Anilov does not scrape web pages, extract private stream tokens, '
            'or bypass Google authentication/DRM. The link can only be opened safely via the system browser or Google application.',
      );
    } else if (host.contains('youtube.com') || host == 'youtu.be') {
      return const LinkEvaluationResult(
        url: '',
        isAuthorizedApi: true,
        isDirectVideoUrl: false,
        requiresExternalApp: false,
        description: 'Official YouTube Trailer',
        policyNotice: 'Supported via official YouTube IFrame Player embed.',
      );
    } else {
      return LinkEvaluationResult(
        url: url,
        isAuthorizedApi: false,
        isDirectVideoUrl: false,
        requiresExternalApp: true,
        description: 'External Web Link ($host)',
        policyNotice:
            'External web links cannot be parsed as in-app media. Opened through system browser via url_launcher.',
      );
    }
  }
}
