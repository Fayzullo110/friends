class UserStatus {
  final String id;
  final String userId;
  final String username;
  final String? photoUrl;
  final String text;
  final String? emoji;
  final String? musicTitle;
  final String? musicArtist;
  final String? musicUrl;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> seenBy;

  UserStatus({
    required this.id,
    required this.userId,
    required this.username,
    this.photoUrl,
    required this.text,
    this.emoji,
    this.musicTitle,
    this.musicArtist,
    this.musicUrl,
    required this.createdAt,
    required this.expiresAt,
    this.seenBy = const [],
  });

  factory UserStatus.fromJson(Map<String, dynamic> data) {
    return UserStatus(
      id: data['id'].toString(),
      userId: data['userId'].toString(),
      username: data['username'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      text: data['text'] as String? ?? '',
      emoji: data['emoji'] as String?,
      musicTitle: data['musicTitle'] as String?,
      musicArtist: data['musicArtist'] as String?,
      musicUrl: data['musicUrl'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['createdAt'] as num?)?.toInt() ?? 0,
        isUtc: false,
      ),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        (data['expiresAt'] as num?)?.toInt() ?? 0,
        isUtc: false,
      ),
      seenBy: (data['seenBy'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'photoUrl': photoUrl,
      'text': text,
      'emoji': emoji,
      'musicTitle': musicTitle,
      'musicArtist': musicArtist,
      'musicUrl': musicUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'seenBy': seenBy,
    };
  }

  bool get hasMusic => musicUrl != null && musicUrl!.isNotEmpty;
  bool get hasEmoji => emoji != null && emoji!.isNotEmpty;
}
