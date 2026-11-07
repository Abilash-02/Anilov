class AniListUser {
  final int id;
  final String name;
  final String? avatarUrl;

  const AniListUser({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  factory AniListUser.fromJson(Map<String, dynamic> json) {
    String? avatar;
    if (json['avatar'] is Map) {
      final avatarMap = json['avatar'] as Map<String, dynamic>;
      avatar = avatarMap['large'] as String? ?? avatarMap['medium'] as String?;
    } else if (json['avatarUrl'] is String) {
      avatar = json['avatarUrl'] as String;
    }

    return AniListUser(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'AniList User',
      avatarUrl: avatar,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AniListUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          avatarUrl == other.avatarUrl;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ avatarUrl.hashCode;
}
