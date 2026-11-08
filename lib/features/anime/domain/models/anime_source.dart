// Modular AnimeSourceProvider domain models and contracts.
// Defines source availability, playback stream tracks, subtitles, and provider interfaces.

import 'anime_media.dart';

/// Availability and authorization status of an anime source.
enum SourceAvailabilityStatus {
  /// Source provides authorized in-app video streams (e.g. HLS, MP4).
  authorized,

  /// Source provides public metadata, but restricts in-app embedding
  /// (e.g. X-Frame-Options: SAMEORIGIN or no third-party stream API).
  /// Playback is officially supported via system browser.
  restrictedEmbedding,

  /// Source lacks an authorized third-party API and relies on hidden stream
  /// scraping, Cloudflare bypass, or DRM tampering (e.g. KickassAnime / Fetch).
  /// Strictly prohibited per application security and legal guidelines.
  unauthorizedScraper,

  /// Source is currently offline, unmaintained, or unsupported.
  unsupported,
}

extension SourceAvailabilityStatusExtension on SourceAvailabilityStatus {
  String get displayName {
    switch (this) {
      case SourceAvailabilityStatus.authorized:
        return 'Authorized Stream';
      case SourceAvailabilityStatus.restrictedEmbedding:
        return 'External Playback (SAMEORIGIN)';
      case SourceAvailabilityStatus.unauthorizedScraper:
        return 'Unauthorized Scraper (Restricted)';
      case SourceAvailabilityStatus.unsupported:
        return 'Unsupported';
    }
  }

  String get description {
    switch (this) {
      case SourceAvailabilityStatus.authorized:
        return 'Fully authorized in-app video playback with Media3 ExoPlayer.';
      case SourceAvailabilityStatus.restrictedEmbedding:
        return 'Public show metadata available. Embedding restricted by source policy; launches externally.';
      case SourceAvailabilityStatus.unauthorizedScraper:
        return 'Unofficial scraper source without authorized API. Stream scraping prohibited.';
      case SourceAvailabilityStatus.unsupported:
        return 'Source is not available.';
    }
  }
}

/// Stream format type for in-app video playback.
enum SourceStreamType {
  hls,
  mp4,
  externalWeb,
}

/// A specific video stream track with quality label and media URL.
class SourceStreamTrack {
  final String label; // e.g. "1080p (FHD)", "720p (HD)", "480p (SD)", "Auto (Adaptive)"
  final String url;
  final SourceStreamType type;
  final int? bitrate;
  final Map<String, String>? headers;

  const SourceStreamTrack({
    required this.label,
    required this.url,
    this.type = SourceStreamType.hls,
    this.bitrate,
    this.headers,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'url': url,
        'type': type.name,
        'bitrate': bitrate,
        'headers': headers,
      };

  factory SourceStreamTrack.fromJson(Map<String, dynamic> json) =>
      SourceStreamTrack(
        label: json['label'] as String? ?? 'Default',
        url: json['url'] as String? ?? '',
        type: SourceStreamType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => SourceStreamType.hls,
        ),
        bitrate: json['bitrate'] as int?,
        headers: (json['headers'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v.toString()),
        ),
      );
}

/// A subtitle / closed-caption track for video playback.
class SourceSubtitleTrack {
  final String label; // e.g. "English", "Spanish", "Japanese"
  final String languageCode; // e.g. "en", "es", "ja"
  final String url;
  final bool isDefault;

  const SourceSubtitleTrack({
    required this.label,
    required this.languageCode,
    required this.url,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'languageCode': languageCode,
        'url': url,
        'isDefault': isDefault,
      };

  factory SourceSubtitleTrack.fromJson(Map<String, dynamic> json) =>
      SourceSubtitleTrack(
        label: json['label'] as String? ?? 'English',
        languageCode: json['languageCode'] as String? ?? 'en',
        url: json['url'] as String? ?? '',
        isDefault: json['isDefault'] as bool? ?? false,
      );
}

/// Represents an episode provided by an anime source.
class AnimeSourceEpisode {
  final int episodeNumber;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final String? sourceIdentifier;

  const AnimeSourceEpisode({
    required this.episodeNumber,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.durationSeconds,
    this.sourceIdentifier,
  });

  Map<String, dynamic> toJson() => {
        'episodeNumber': episodeNumber,
        'title': title,
        'description': description,
        'thumbnailUrl': thumbnailUrl,
        'durationSeconds': durationSeconds,
        'sourceIdentifier': sourceIdentifier,
      };

  factory AnimeSourceEpisode.fromJson(Map<String, dynamic> json) =>
      AnimeSourceEpisode(
        episodeNumber: json['episodeNumber'] as int? ?? 1,
        title: json['title'] as String? ?? 'Episode 1',
        description: json['description'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        durationSeconds: json['durationSeconds'] as int?,
        sourceIdentifier: json['sourceIdentifier'] as String?,
      );
}

/// Represents a season provided by an anime source.
class AnimeSourceSeason {
  final int seasonNumber;
  final String name;
  final String slug;
  final int? episodesCount;
  final String? bannerUrl;

  const AnimeSourceSeason({
    required this.seasonNumber,
    required this.name,
    required this.slug,
    this.episodesCount,
    this.bannerUrl,
  });

  Map<String, dynamic> toJson() => {
        'seasonNumber': seasonNumber,
        'name': name,
        'slug': slug,
        'episodesCount': episodesCount,
        'bannerUrl': bannerUrl,
      };

  factory AnimeSourceSeason.fromJson(Map<String, dynamic> json) =>
      AnimeSourceSeason(
        seasonNumber: json['seasonNumber'] as int? ?? 1,
        name: json['name'] as String? ?? 'Season 1',
        slug: json['slug'] as String? ?? '',
        episodesCount: json['episodesCount'] as int?,
        bannerUrl: json['bannerUrl'] as String?,
      );
}

/// Comprehensive playback info for a single anime episode.
class EpisodePlaybackInfo {
  final int episodeNumber;
  final String episodeTitle;
  final SourceAvailabilityStatus availability;
  final List<SourceStreamTrack> streams;
  final List<SourceSubtitleTrack> subtitles;
  final String? externalWatchUrl;
  final String? notice;

  const EpisodePlaybackInfo({
    required this.episodeNumber,
    required this.episodeTitle,
    required this.availability,
    this.streams = const [],
    this.subtitles = const [],
    this.externalWatchUrl,
    this.notice,
  });

  /// True if a direct playable stream is available for in-app video player.
  bool get isDirectPlayable =>
      availability == SourceAvailabilityStatus.authorized && streams.isNotEmpty;

  /// Returns the default or highest quality stream.
  SourceStreamTrack? get primaryStream =>
      streams.isNotEmpty ? streams.first : null;

  Map<String, dynamic> toJson() => {
        'episodeNumber': episodeNumber,
        'episodeTitle': episodeTitle,
        'availability': availability.name,
        'streams': streams.map((s) => s.toJson()).toList(),
        'subtitles': subtitles.map((s) => s.toJson()).toList(),
        'externalWatchUrl': externalWatchUrl,
        'notice': notice,
      };
}

/// Modular contract for anime source providers.
abstract class AnimeSourceProvider {
  /// Unique machine identifier for this provider.
  String get id;

  /// User-facing display name.
  String get name;

  /// Brief description of the provider and its content policy.
  String get description;

  /// Default availability status of this provider.
  SourceAvailabilityStatus get availability;

  /// Whether this provider supports native in-app video streaming.
  bool get canStreamInApp;

  /// Searches the provider catalog.
  Future<List<AnimeMedia>> searchAnime(String query);

  /// Retrieves anime details and metadata by identifier or slug.
  Future<AnimeMedia?> getAnimeDetails(String identifier) async => null;

  /// Discovers available seasons for the given anime media.
  Future<List<AnimeSourceSeason>> getSeasons(AnimeMedia anime);

  /// Discovers available episodes for the given anime media and optional season.
  Future<List<AnimeSourceEpisode>> getEpisodes(
    AnimeMedia anime, {
    String? seasonSlug,
  });

  /// Resolves the playback stream information for an episode.
  Future<EpisodePlaybackInfo> getEpisodePlayback(
    AnimeMedia anime,
    int episodeNumber, {
    String? seasonSlug,
  });
}
