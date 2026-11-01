// Domain models for Anime metadata queried from AniList GraphQL.
// All JSON factories are null-safe with conservative fallbacks.

class AnimeTitle {
  final String? romaji;
  final String? english;
  final String? native;
  final String? userPreferred;

  const AnimeTitle({
    this.romaji,
    this.english,
    this.native,
    this.userPreferred,
  });

  factory AnimeTitle.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AnimeTitle();
    return AnimeTitle(
      romaji: json['romaji'] as String?,
      english: json['english'] as String?,
      native: json['native'] as String?,
      userPreferred: json['userPreferred'] as String?,
    );
  }

  /// Preferred user-friendly title
  String get displayTitle {
    if (english != null && english!.trim().isNotEmpty) {
      return english!;
    }
    if (userPreferred != null && userPreferred!.trim().isNotEmpty) {
      return userPreferred!;
    }
    if (romaji != null && romaji!.trim().isNotEmpty) {
      return romaji!;
    }
    if (native != null && native!.trim().isNotEmpty) {
      return native!;
    }
    return 'Untitled';
  }
}

class AnimeCover {
  final String? extraLarge;
  final String? large;
  final String? medium;
  final String? color;

  const AnimeCover({
    this.extraLarge,
    this.large,
    this.medium,
    this.color,
  });

  factory AnimeCover.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AnimeCover();
    return AnimeCover(
      extraLarge: json['extraLarge'] as String?,
      large: json['large'] as String?,
      medium: json['medium'] as String?,
      color: json['color'] as String?,
    );
  }

  String? get displayUrl => extraLarge ?? large ?? medium;
}

class AnimeTrailer {
  final String? id;
  final String? site;

  const AnimeTrailer({
    this.id,
    this.site,
  });

  static AnimeTrailer? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = json['id'] as String?;
    final site = json['site'] as String?;
    if (id == null && site == null) return null;
    return AnimeTrailer(id: id, site: site);
  }

  bool get isYouTube => site?.toLowerCase() == 'youtube' && id != null && id!.isNotEmpty;

  String? get youtubeUrl => isYouTube ? 'https://www.youtube.com/watch?v=$id' : null;

  String? get thumbnailUrl => isYouTube ? 'https://img.youtube.com/vi/$id/hqdefault.jpg' : null;
}

class AnimeExternalLink {
  final int? id;
  final String site;
  final String url;
  final String? type;

  const AnimeExternalLink({
    this.id,
    required this.site,
    required this.url,
    this.type,
  });

  factory AnimeExternalLink.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AnimeExternalLink(site: 'Official Link', url: '');
    }
    return AnimeExternalLink(
      id: json['id'] as int?,
      site: (json['site'] as String?) ?? 'Official Link',
      url: (json['url'] as String?) ?? '',
      type: json['type'] as String?,
    );
  }
}

class AnimeNextAiring {
  final int? airingAt;
  final int? timeUntilAiring;
  final int? episode;

  const AnimeNextAiring({
    this.airingAt,
    this.timeUntilAiring,
    this.episode,
  });

  static AnimeNextAiring? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return AnimeNextAiring(
      airingAt: json['airingAt'] as int?,
      timeUntilAiring: json['timeUntilAiring'] as int?,
      episode: json['episode'] as int?,
    );
  }
}

class AnimeRelation {
  final int id;
  final String relationType;
  final String title;
  final String? coverUrl;
  final String? format;
  final String? status;

  const AnimeRelation({
    required this.id,
    required this.relationType,
    required this.title,
    this.coverUrl,
    this.format,
    this.status,
  });

  factory AnimeRelation.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AnimeRelation(id: 0, relationType: 'RELATED', title: 'Unknown');
    }
    final node = json['node'] as Map<String, dynamic>? ?? {};
    final nodeTitle = node['title'] as Map<String, dynamic>?;
    final title = nodeTitle != null
        ? ((nodeTitle['english'] ?? nodeTitle['userPreferred'] ?? nodeTitle['romaji']) as String? ?? 'Untitled')
        : 'Untitled';
    final cover = node['coverImage'] as Map<String, dynamic>?;
    final coverUrl = cover != null ? (cover['medium'] ?? cover['large']) as String? : null;

    return AnimeRelation(
      id: (node['id'] as int?) ?? 0,
      relationType: (json['relationType'] as String?) ?? 'RELATED',
      title: title,
      coverUrl: coverUrl,
      format: node['format'] as String?,
      status: node['status'] as String?,
    );
  }
}

class AnimeMedia {
  final int id;
  final int? idMal;
  final AnimeTitle title;
  final AnimeCover coverImage;
  final String? bannerImage;
  final String? rawDescription;
  final String? format;
  final String? status;
  final int? seasonYear;
  final String? season;
  final int? episodes;
  final int? duration;
  final int? averageScore;
  final int? popularity;
  final List<String> genres;
  final String? studio;
  final AnimeTrailer? trailer;
  final List<AnimeExternalLink> externalLinks;
  final AnimeNextAiring? nextAiringEpisode;
  final List<AnimeRelation> relations;

  const AnimeMedia({
    required this.id,
    this.idMal,
    required this.title,
    required this.coverImage,
    this.bannerImage,
    this.rawDescription,
    this.format,
    this.status,
    this.seasonYear,
    this.season,
    this.episodes,
    this.duration,
    this.averageScore,
    this.popularity,
    this.genres = const [],
    this.studio,
    this.trailer,
    this.externalLinks = const [],
    this.nextAiringEpisode,
    this.relations = const [],
  });

  factory AnimeMedia.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as int?) ?? 0;
    final idMal = json['idMal'] as int?;
    final title = AnimeTitle.fromJson(json['title'] as Map<String, dynamic>?);
    final coverImage = AnimeCover.fromJson(json['coverImage'] as Map<String, dynamic>?);
    final bannerImage = json['bannerImage'] as String?;
    final rawDescription = json['description'] as String?;
    final format = json['format'] as String?;
    final status = json['status'] as String?;
    final seasonYear = json['seasonYear'] as int?;
    final season = json['season'] as String?;
    final episodes = json['episodes'] as int?;
    final duration = json['duration'] as int?;
    final averageScore = json['averageScore'] as int?;
    final popularity = json['popularity'] as int?;

    final genresList = <String>[];
    if (json['genres'] is List) {
      for (final g in json['genres'] as List) {
        if (g is String && g.trim().isNotEmpty) {
          genresList.add(g.trim());
        }
      }
    }

    String? studioName;
    if (json['studios'] is Map) {
      final studiosMap = json['studios'] as Map<String, dynamic>;
      final nodes = studiosMap['nodes'];
      if (nodes is List && nodes.isNotEmpty) {
        final first = nodes.first;
        if (first is Map && first['name'] is String) {
          studioName = first['name'] as String;
        }
      }
    }

    final trailer = AnimeTrailer.fromJson(json['trailer'] as Map<String, dynamic>?);

    final linksList = <AnimeExternalLink>[];
    if (json['externalLinks'] is List) {
      for (final link in json['externalLinks'] as List) {
        if (link is Map<String, dynamic>) {
          final l = AnimeExternalLink.fromJson(link);
          if (l.url.isNotEmpty) {
            linksList.add(l);
          }
        }
      }
    }

    final nextAiring = AnimeNextAiring.fromJson(json['nextAiringEpisode'] as Map<String, dynamic>?);

    final relationsList = <AnimeRelation>[];
    if (json['relations'] is Map) {
      final relMap = json['relations'] as Map<String, dynamic>;
      final edges = relMap['edges'];
      if (edges is List) {
        for (final edge in edges) {
          if (edge is Map<String, dynamic>) {
            final rel = AnimeRelation.fromJson(edge);
            if (rel.id > 0) {
              relationsList.add(rel);
            }
          }
        }
      }
    }

    return AnimeMedia(
      id: id,
      idMal: idMal,
      title: title,
      coverImage: coverImage,
      bannerImage: bannerImage,
      rawDescription: rawDescription,
      format: format,
      status: status,
      seasonYear: seasonYear,
      season: season,
      episodes: episodes,
      duration: duration,
      averageScore: averageScore,
      popularity: popularity,
      genres: genresList,
      studio: studioName,
      trailer: trailer,
      externalLinks: linksList,
      nextAiringEpisode: nextAiring,
      relations: relationsList,
    );
  }

  /// Cleaned synopsis free of HTML tags like `<br>`, `<i>`, `<b>`
  String get cleanDescription {
    if (rawDescription == null || rawDescription!.isEmpty) {
      return 'No synopsis available.';
    }
    return rawDescription!
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</?(?:i|b|strong|em|p|span|div)\b[^>]*>', caseSensitive: false), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#039;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  /// Format string for display (e.g. "TV", "Movie", "OVA")
  String get displayFormat {
    if (format == null) return 'Anime';
    switch (format!.toUpperCase()) {
      case 'TV':
        return 'TV Series';
      case 'TV_SHORT':
        return 'TV Short';
      case 'MOVIE':
        return 'Movie';
      case 'SPECIAL':
        return 'Special';
      case 'OVA':
        return 'OVA';
      case 'ONA':
        return 'ONA';
      case 'MUSIC':
        return 'Music';
      default:
        return format!;
    }
  }

  /// Formatted score e.g. "85%"
  String? get displayScore => averageScore != null ? '$averageScore%' : null;
}

class PageInfo {
  final int total;
  final int currentPage;
  final int lastPage;
  final bool hasNextPage;
  final int perPage;

  const PageInfo({
    this.total = 0,
    this.currentPage = 1,
    this.lastPage = 1,
    this.hasNextPage = false,
    this.perPage = 20,
  });

  factory PageInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PageInfo();
    return PageInfo(
      total: (json['total'] as int?) ?? 0,
      currentPage: (json['currentPage'] as int?) ?? 1,
      lastPage: (json['lastPage'] as int?) ?? 1,
      hasNextPage: (json['hasNextPage'] as bool?) ?? false,
      perPage: (json['perPage'] as int?) ?? 20,
    );
  }
}

class PaginatedAnime {
  final PageInfo pageInfo;
  final List<AnimeMedia> items;

  const PaginatedAnime({
    required this.pageInfo,
    required this.items,
  });

  factory PaginatedAnime.fromJson(Map<String, dynamic> json) {
    final pageData = json['Page'] as Map<String, dynamic>? ?? json;
    final pageInfo = PageInfo.fromJson(pageData['pageInfo'] as Map<String, dynamic>?);
    final mediaList = <AnimeMedia>[];

    final mediaRaw = pageData['media'];
    if (mediaRaw is List) {
      for (final m in mediaRaw) {
        if (m is Map<String, dynamic>) {
          mediaList.add(AnimeMedia.fromJson(m));
        }
      }
    }

    return PaginatedAnime(pageInfo: pageInfo, items: mediaList);
  }
}
