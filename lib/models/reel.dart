class Reel {
  final String id;
  final String authorId;
  final String authorUsername;
  final String caption;
  final String? mediaUrl; // video or image in future
  final String mediaType; // 'video' | 'image' | 'text'
  final int likeCount;
  final List<String> likedBy;
  final int commentCount;
  final int shareCount;
  final DateTime createdAt;

  final DateTime? archivedAt;
  final DateTime? deletedAt;

  Reel({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    required this.caption,
    this.mediaUrl,
    this.mediaType = 'video',
    this.likeCount = 0,
    this.likedBy = const [],
    this.commentCount = 0,
    this.shareCount = 0,
    required this.createdAt,
    this.archivedAt,
    this.deletedAt,
  });

  factory Reel.fromJson(Map<String, dynamic> data) {
    return Reel(
      id: data['id'].toString(),
      authorId: data['authorId'].toString(),
      authorUsername: data['authorUsername'] as String? ?? '',
      caption: data['caption'] as String? ?? '',
      mediaUrl: data['mediaUrl'] as String?,
      mediaType: data['mediaType'] as String? ?? 'video',
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      likedBy: (data['likedBy'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
      shareCount: (data['shareCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['createdAt'] as num?)?.toInt() ?? 0,
        isUtc: false,
      ),
      archivedAt: data['archivedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['archivedAt'] as num).toInt(),
              isUtc: false,
            )
          : null,
      deletedAt: data['deletedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['deletedAt'] as num).toInt(),
              isUtc: false,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      'authorUsername': authorUsername,
      'caption': caption,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'likeCount': likeCount,
      'likedBy': likedBy,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'archivedAt': archivedAt?.millisecondsSinceEpoch,
      'deletedAt': deletedAt?.millisecondsSinceEpoch,
    };
  }
}
