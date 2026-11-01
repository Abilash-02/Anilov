// Watchlist item domain model

import 'watch_status.dart';

class WatchlistItem {
  final int animeId;
  final String title;
  final String? coverUrl;
  final String? format;
  final int? totalEpisodes;
  final WatchStatus status;
  final int progress;
  final double? score;
  final DateTime updatedAt;
  final DateTime createdAt;

  const WatchlistItem({
    required this.animeId,
    required this.title,
    this.coverUrl,
    this.format,
    this.totalEpisodes,
    this.status = WatchStatus.planning,
    this.progress = 0,
    this.score,
    required this.updatedAt,
    required this.createdAt,
  });

  bool get isFinished {
    if (totalEpisodes != null && totalEpisodes! > 0) {
      return progress >= totalEpisodes!;
    }
    return status == WatchStatus.completed;
  }

  double get progressFraction {
    if (totalEpisodes == null || totalEpisodes! <= 0) return 0.0;
    return (progress / totalEpisodes!).clamp(0.0, 1.0);
  }

  bool get canIncrement {
    if (totalEpisodes != null && totalEpisodes! > 0) {
      return progress < totalEpisodes!;
    }
    return true; // Unknown total, can always increment
  }

  WatchlistItem copyWith({
    int? animeId,
    String? title,
    String? coverUrl,
    String? format,
    int? totalEpisodes,
    WatchStatus? status,
    int? progress,
    double? score,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return WatchlistItem(
      animeId: animeId ?? this.animeId,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      format: format ?? this.format,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      status: status ?? this.status,
      progress: (progress ?? this.progress).clamp(0, 99999),
      score: score ?? this.score,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'anime_id': animeId,
      'title': title,
      'cover_url': coverUrl,
      'format': format,
      'total_episodes': totalEpisodes,
      'status': status.toDbString(),
      'progress': progress,
      'score': score,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory WatchlistItem.fromMap(Map<String, dynamic> map) {
    return WatchlistItem(
      animeId: map['anime_id'] as int,
      title: map['title'] as String? ?? 'Unknown Title',
      coverUrl: map['cover_url'] as String?,
      format: map['format'] as String?,
      totalEpisodes: map['total_episodes'] as int?,
      status: WatchStatus.fromDbString(map['status'] as String?),
      progress: (map['progress'] as num?)?.toInt() ?? 0,
      score: (map['score'] as num?)?.toDouble(),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : DateTime.now(),
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatchlistItem &&
          runtimeType == other.runtimeType &&
          animeId == other.animeId &&
          title == other.title &&
          coverUrl == other.coverUrl &&
          format == other.format &&
          totalEpisodes == other.totalEpisodes &&
          status == other.status &&
          progress == other.progress &&
          score == other.score &&
          updatedAt == other.updatedAt &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      animeId.hashCode ^
      title.hashCode ^
      coverUrl.hashCode ^
      format.hashCode ^
      totalEpisodes.hashCode ^
      status.hashCode ^
      progress.hashCode ^
      score.hashCode ^
      updatedAt.hashCode ^
      createdAt.hashCode;
}
