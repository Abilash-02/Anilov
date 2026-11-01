// Airing schedule domain model

import 'package:anilov/features/anime/domain/models/anime_media.dart';

class AiringSchedule {
  final int id;
  final DateTime airingAt;
  final int timeUntilAiring;
  final int episode;
  final int mediaId;
  final AnimeMedia? media;

  const AiringSchedule({
    required this.id,
    required this.airingAt,
    required this.timeUntilAiring,
    required this.episode,
    required this.mediaId,
    this.media,
  });

  DateTime get airingAtLocal => airingAt.toLocal();

  int get weekday => airingAtLocal.weekday; // 1 = Monday, 7 = Sunday

  bool get hasAired => DateTime.now().isAfter(airingAtLocal);

  String get formattedTime {
    final local = airingAtLocal;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get countdownText {
    final diff = airingAtLocal.difference(DateTime.now());
    if (diff.isNegative) {
      final past = -diff;
      if (past.inDays > 0) return 'Aired ${past.inDays}d ago';
      if (past.inHours > 0) return 'Aired ${past.inHours}h ago';
      if (past.inMinutes > 0) return 'Aired ${past.inMinutes}m ago';
      return 'Aired just now';
    } else {
      if (diff.inDays > 0) return 'Airs in ${diff.inDays}d ${diff.inHours % 24}h';
      if (diff.inHours > 0) return 'Airs in ${diff.inHours}h ${diff.inMinutes % 60}m';
      if (diff.inMinutes > 0) return 'Airs in ${diff.inMinutes}m';
      return 'Airing soon';
    }
  }

  factory AiringSchedule.fromJson(Map<String, dynamic> json) {
    final airingAtSeconds = (json['airingAt'] as num?)?.toInt() ?? 0;
    final airingAtUtc = DateTime.fromMillisecondsSinceEpoch(airingAtSeconds * 1000, isUtc: true);

    return AiringSchedule(
      id: (json['id'] as num?)?.toInt() ?? 0,
      airingAt: airingAtUtc,
      timeUntilAiring: (json['timeUntilAiring'] as num?)?.toInt() ?? 0,
      episode: (json['episode'] as num?)?.toInt() ?? 1,
      mediaId: (json['mediaId'] as num?)?.toInt() ?? 0,
      media: json['media'] != null ? AnimeMedia.fromJson(json['media'] as Map<String, dynamic>) : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiringSchedule &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          airingAt == other.airingAt &&
          episode == other.episode &&
          mediaId == other.mediaId;

  @override
  int get hashCode => id.hashCode ^ airingAt.hashCode ^ episode.hashCode ^ mediaId.hashCode;
}
