class Post {
  final String id;
  final String authorId;
  final String authorUsername;
  final String? authorPhotoUrl;
  final String text;
  final DateTime createdAt;
  final DateTime? archivedAt;
  final DateTime? deletedAt;
  final int likeCount;
  final List<String> likedBy;
  final int commentCount;
  final int shareCount;
  final String? pinnedCommentId;
  final String? mediaUrl; // image or video URL
  final String? mediaType; // 'text', 'image', 'video'

  Post({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    this.authorPhotoUrl,
    required this.text,
    required this.createdAt,
    this.archivedAt,
    this.deletedAt,
    this.likeCount = 0,
    this.likedBy = const [],
    this.commentCount = 0,
    this.shareCount = 0,
    this.pinnedCommentId,
    this.mediaUrl,
    this.mediaType,
  });

  factory Post.fromJson(Map<String, dynamic> data) {
    DateTime? parseEpoch(dynamic v) {
      if (v == null) return null;
      if (v is num) {
        return DateTime.fromMillisecondsSinceEpoch(v.toInt(), isUtc: false);
      }
      return null;
    }

    return Post(
      id: data['id'].toString(),
      authorId: data['authorId'].toString(),
      authorUsername: data['authorUsername'] as String? ?? '',
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      text: data['text'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['createdAt'] as num?)?.toInt() ?? 0,
        isUtc: false,
      ),
      archivedAt: parseEpoch(data['archivedAt']),
      deletedAt: parseEpoch(data['deletedAt']),
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      likedBy: (data['likedBy'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
      shareCount: (data['shareCount'] as num?)?.toInt() ?? 0,
      pinnedCommentId: data['pinnedCommentId']?.toString(),
      mediaUrl: data['mediaUrl'] as String?,
      mediaType: data['mediaType'] as String? ?? 'text',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorPhotoUrl': authorPhotoUrl,
      'text': text,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'archivedAt': archivedAt?.millisecondsSinceEpoch,
      'deletedAt': deletedAt?.millisecondsSinceEpoch,
      'likeCount': likeCount,
      'likedBy': likedBy,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'pinnedCommentId': pinnedCommentId,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType ?? (mediaUrl == null ? 'text' : 'image'),
    };
  }
}
