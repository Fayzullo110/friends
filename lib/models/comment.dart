enum CommentType {
  text,
  gif,
}

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String authorUsername;
  final String? authorPhotoUrl;
  final String? authorThemeKey;
  final int? authorThemeSeedColor;
  final String text;
  final CommentType type;
  final String? mediaUrl;
  final DateTime createdAt;
  final int likeCount;
  final List<String> likedBy;
  final String? parentCommentId;
  final int dislikeCount;
  final List<String> dislikedBy;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorUsername,
    this.authorPhotoUrl,
    this.authorThemeKey,
    this.authorThemeSeedColor,
    required this.text,
    required this.type,
    this.mediaUrl,
    required this.createdAt,
    required this.likeCount,
    required this.likedBy,
    this.parentCommentId,
    required this.dislikeCount,
    required this.dislikedBy,
  });

  factory Comment.fromJson(Map<String, dynamic> data) {
    return Comment(
      id: data['id'].toString(),
      postId: data['postId'].toString(),
      authorId: data['authorId'].toString(),
      authorUsername: data['authorUsername'] as String? ?? '',
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      authorThemeKey: data['authorThemeKey'] as String?,
      authorThemeSeedColor: (data['authorThemeSeedColor'] as num?)?.toInt(),
      text: data['text'] as String? ?? '',
      type: _typeFromString(data['type'] as String?),
      mediaUrl: data['mediaUrl'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['createdAt'] as num?)?.toInt() ?? 0,
        isUtc: false,
      ),
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      likedBy: (data['likedBy'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      parentCommentId: data['parentCommentId']?.toString(),
      dislikeCount: (data['dislikeCount'] as num?)?.toInt() ?? 0,
      dislikedBy: (data['dislikedBy'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorPhotoUrl': authorPhotoUrl,
      'authorThemeKey': authorThemeKey,
      'authorThemeSeedColor': authorThemeSeedColor,
      'text': text,
      'type': _typeToString(type),
      'mediaUrl': mediaUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'likeCount': likeCount,
      'likedBy': likedBy,
      'parentCommentId': parentCommentId,
      'dislikeCount': dislikeCount,
      'dislikedBy': dislikedBy,
    };
  }

  static CommentType _typeFromString(String? value) {
    switch (value) {
      case 'gif':
        return CommentType.gif;
      case 'text':
      default:
        return CommentType.text;
    }
  }

  static String _typeToString(CommentType type) {
    switch (type) {
      case CommentType.gif:
        return 'gif';
      case CommentType.text:
        return 'text';
    }
  }
}
