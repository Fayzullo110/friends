import 'package:cloud_firestore/cloud_firestore.dart';

enum CommentType {
  text,
  gif,
}

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String authorUsername;
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

  factory Comment.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String postId,
  }) {
    final data = doc.data() ?? {};
    return Comment(
      id: doc.id,
      postId: postId,
      authorId: data['authorId'] as String? ?? '',
      authorUsername: data['authorUsername'] as String? ?? '',
      text: data['text'] as String? ?? '',
      type: _typeFromString(data['type'] as String?),
      mediaUrl: data['mediaUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likeCount: data['likeCount'] as int? ?? 0,
      likedBy: (data['likedBy'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      parentCommentId: data['parentCommentId'] as String?,
      dislikeCount: data['dislikeCount'] as int? ?? 0,
      dislikedBy: (data['dislikedBy'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorUsername': authorUsername,
      'text': text,
      'type': _typeToString(type),
      'mediaUrl': mediaUrl,
      'createdAt': Timestamp.fromDate(createdAt),
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
