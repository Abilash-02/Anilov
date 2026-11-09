/// Playback providers supported by Anilov.
enum PlaybackProviderType {
  /// Authorized HLS in-app video streaming via Android Media3 / ExoPlayer.
  authorizedStream,

  /// AniKoto web source (https://anikoto.cz).
  anikoto,

  /// Fetch-inspired KickassAnime source (evaluation / scraper restricted).
  fetchKickass,

  /// Local user media and direct video streams.
  localPlayer,

  /// MegaVid source (https://megavid.buzz) for mapped anime episodes.
  megavid,
}

extension PlaybackProviderTypeExtension on PlaybackProviderType {
  String get displayName {
    switch (this) {
      case PlaybackProviderType.authorizedStream:
        return 'Authorized Stream';
      case PlaybackProviderType.anikoto:
        return 'AniKoto';
      case PlaybackProviderType.fetchKickass:
        return 'Fetch (Kickass)';
      case PlaybackProviderType.localPlayer:
        return 'Local Player';
      case PlaybackProviderType.megavid:
        return 'MegaVid';
    }
  }

  String get description {
    switch (this) {
      case PlaybackProviderType.authorizedStream:
        return 'Authorized in-app HLS video playback with Media3 ExoPlayer.';
      case PlaybackProviderType.anikoto:
        return 'Stream anime episodes via AniKoto (anikoto.cz).';
      case PlaybackProviderType.fetchKickass:
        return 'Fetch KickassAnime source evaluation (stream scraping restricted).';
      case PlaybackProviderType.localPlayer:
        return 'Play offline local media files and direct streams.';
      case PlaybackProviderType.megavid:
        return 'External anime source link via MegaVid (megavid.buzz).';
    }
  }
}

/// Represents an anime season on AniKoto.
class AnikotoSeason {
  final int seasonNumber;
  final String name;
  final String slug;
  final String? bannerUrl;
  final int? episodesCount;

  const AnikotoSeason({
    required this.seasonNumber,
    required this.name,
    required this.slug,
    this.bannerUrl,
    this.episodesCount,
  });

  Map<String, dynamic> toJson() => {
        'seasonNumber': seasonNumber,
        'name': name,
        'slug': slug,
        'bannerUrl': bannerUrl,
        'episodesCount': episodesCount,
      };

  factory AnikotoSeason.fromJson(Map<String, dynamic> json) => AnikotoSeason(
        seasonNumber: json['seasonNumber'] as int? ?? 1,
        name: json['name'] as String? ?? 'Season 1',
        slug: json['slug'] as String? ?? '',
        bannerUrl: json['bannerUrl'] as String?,
        episodesCount: json['episodesCount'] as int?,
      );
}

/// Represents an episode on AniKoto.
class AnikotoEpisode {
  final int episodeNumber;
  final String title;
  final String slug;
  final String watchUrl;

  const AnikotoEpisode({
    required this.episodeNumber,
    required this.title,
    required this.slug,
    required this.watchUrl,
  });

  Map<String, dynamic> toJson() => {
        'episodeNumber': episodeNumber,
        'title': title,
        'slug': slug,
        'watchUrl': watchUrl,
      };

  factory AnikotoEpisode.fromJson(Map<String, dynamic> json) => AnikotoEpisode(
        episodeNumber: json['episodeNumber'] as int? ?? 1,
        title: json['title'] as String? ?? 'Episode 1',
        slug: json['slug'] as String? ?? '',
        watchUrl: json['watchUrl'] as String? ?? '',
      );
}

/// Details of an anime show mapped to AniKoto.
class AnikotoShowDetails {
  final int? tipId;
  final String title;
  final String slug;
  final String? posterUrl;
  final int totalEpisodes;
  final int subEpisodes;
  final int dubEpisodes;
  final List<AnikotoSeason> seasons;

  const AnikotoShowDetails({
    this.tipId,
    required this.title,
    required this.slug,
    this.posterUrl,
    required this.totalEpisodes,
    this.subEpisodes = 0,
    this.dubEpisodes = 0,
    this.seasons = const [],
  });

  /// Builds the official watch URL for an episode of this show/season.
  String buildEpisodeUrl(int episodeNumber, {String? seasonSlug}) {
    final targetSlug = seasonSlug ?? slug;
    return 'https://anikoto.cz/watch/$targetSlug/ep-$episodeNumber';
  }

  /// Returns the current season or the first season if available.
  AnikotoSeason get primarySeason {
    if (seasons.isNotEmpty) return seasons.first;
    return AnikotoSeason(
      seasonNumber: 1,
      name: 'Season 1',
      slug: slug,
      episodesCount: totalEpisodes,
    );
  }

  Map<String, dynamic> toJson() => {
        'tipId': tipId,
        'title': title,
        'slug': slug,
        'posterUrl': posterUrl,
        'totalEpisodes': totalEpisodes,
        'subEpisodes': subEpisodes,
        'dubEpisodes': dubEpisodes,
        'seasons': seasons.map((s) => s.toJson()).toList(),
      };
}

/// Security and embedding evaluation result for AniKoto source.
class AnikotoPlaybackEvaluation {
  final String url;
  final bool isEmbeddingPermitted;
  final String xFrameOptions;
  final String officialWatchUrl;
  final String policyNotice;
  final bool canOpenInBrowser;

  const AnikotoPlaybackEvaluation({
    required this.url,
    required this.isEmbeddingPermitted,
    required this.xFrameOptions,
    required this.officialWatchUrl,
    required this.policyNotice,
    this.canOpenInBrowser = true,
  });

  /// Evaluates an AniKoto watch URL based on official inspection and compliance rules.
  factory AnikotoPlaybackEvaluation.evaluate(String watchUrl) {
    return AnikotoPlaybackEvaluation(
      url: watchUrl,
      isEmbeddingPermitted: false,
      xFrameOptions: 'SAMEORIGIN',
      officialWatchUrl: watchUrl,
      policyNotice:
          'AniKoto (anikoto.cz) enforces "X-Frame-Options: SAMEORIGIN" and does not provide '
          'an authorized third-party iframe embed API. To comply with security guidelines and '
          'legal boundaries, hidden stream URLs are not scraped and DRM/access controls are not bypassed. '
          'Please enjoy official playback through the system browser.',
      canOpenInBrowser: true,
    );
  }
}

/// Evaluation result and policy compliance for MegaVid source links.
class MegavidPlaybackEvaluation {
  final String url;
  final bool isDirectMedia3Supported;
  final bool canOpenInAppBrowser;
  final String statusDescription;
  final String policyNotice;

  const MegavidPlaybackEvaluation({
    required this.url,
    required this.isDirectMedia3Supported,
    required this.canOpenInAppBrowser,
    required this.statusDescription,
    required this.policyNotice,
  });

  /// Evaluates a MegaVid source URL per project security and playback boundaries.
  factory MegavidPlaybackEvaluation.evaluate(String url) {
    final uri = Uri.tryParse(url);
    final isMegavid = uri != null && uri.host.toLowerCase().contains('megavid.buzz');

    return MegavidPlaybackEvaluation(
      url: url,
      isDirectMedia3Supported: false,
      canOpenInAppBrowser: isMegavid,
      statusDescription: isMegavid
          ? 'External Source Page (In-App Browser Supported)'
          : 'External Source Page (External Browser Required)',
      policyNotice:
          'MegaVid source page is opened safely via in-app browser without scraping hidden video streams or bypassing Cloudflare/DRM protections.',
    );
  }
}
