// Watch history domain model

class HistoryItem {
  final int? id;
  final int animeId;
  final String title;
  final String? coverUrl;
  final int episode;
  final DateTime watchedAt;

  const HistoryItem({
    this.id,
    required this.animeId,
    required this.title,
    this.coverUrl,
    required this.episode,
    required this.watchedAt,
  });

  HistoryItem copyWith({
    int? id,
    int? animeId,
    String? title,
    String? coverUrl,
    int? episode,
    DateTime? watchedAt,
  }) {
    return HistoryItem(
      id: id ?? this.id,
      animeId: animeId ?? this.animeId,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      episode: episode ?? this.episode,
      watchedAt: watchedAt ?? this.watchedAt,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'anime_id': animeId,
      'title': title,
      'cover_url': coverUrl,
      'episode': episode,
      'watched_at': watchedAt.millisecondsSinceEpoch,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      id: map['id'] as int?,
      animeId: map['anime_id'] as int,
      title: map['title'] as String? ?? 'Unknown Title',
      coverUrl: map['cover_url'] as String?,
      episode: (map['episode'] as num?)?.toInt() ?? 1,
      watchedAt: map['watched_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['watched_at'] as int)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          animeId == other.animeId &&
          title == other.title &&
          coverUrl == other.coverUrl &&
          episode == other.episode &&
          watchedAt == other.watchedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      animeId.hashCode ^
      title.hashCode ^
      coverUrl.hashCode ^
      episode.hashCode ^
      watchedAt.hashCode;
}
