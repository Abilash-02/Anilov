// Episode metadata model for optional ani.zip enrichment

class EpisodeMetadata {
  final int episodeNumber;
  final String? title;
  final String? overview;
  final String? image;
  final String? airDate;
  final int? runtime;

  const EpisodeMetadata({
    required this.episodeNumber,
    this.title,
    this.overview,
    this.image,
    this.airDate,
    this.runtime,
  });

  String get displayTitle =>
      (title != null && title!.trim().isNotEmpty) ? title!.trim() : 'Episode $episodeNumber';

  factory EpisodeMetadata.fallback(int episodeNumber) {
    return EpisodeMetadata(episodeNumber: episodeNumber);
  }

  factory EpisodeMetadata.fromJson(int episodeNumber, Map<String, dynamic> json) {
    // Title can be a string or a localized map { "en": "...", "x-jat": "..." }
    String? titleParsed;
    final titleRaw = json['title'];
    if (titleRaw is String) {
      titleParsed = titleRaw;
    } else if (titleRaw is Map) {
      titleParsed = (titleRaw['en'] as String?) ??
          (titleRaw['x-jat'] as String?) ??
          (titleRaw['ja'] as String?);
    }

    final runtimeVal = json['runtime'];
    int? runtimeParsed;
    if (runtimeVal is num) {
      runtimeParsed = runtimeVal.toInt();
    }

    return EpisodeMetadata(
      episodeNumber: episodeNumber,
      title: titleParsed,
      overview: json['overview'] as String? ?? json['summary'] as String?,
      image: json['image'] as String? ?? json['thumbnail'] as String?,
      airDate: json['airDate'] as String?,
      runtime: runtimeParsed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpisodeMetadata &&
          runtimeType == other.runtimeType &&
          episodeNumber == other.episodeNumber &&
          title == other.title &&
          image == other.image;

  @override
  int get hashCode => episodeNumber.hashCode ^ title.hashCode ^ image.hashCode;
}
