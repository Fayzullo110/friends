import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String authorId;
  final String authorUsername;
  final String text;
  final DateTime createdAt;
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
    required this.text,
    required this.createdAt,
    this.likeCount = 0,
    this.likedBy = const [],
    this.commentCount = 0,
    this.shareCount = 0,
    this.pinnedCommentId,
    this.mediaUrl,
    this.mediaType,
  });

  factory Post.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Post(
      id: doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorUsername: data['authorUsername'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likeCount: data['likeCount'] as int? ?? 0,
      likedBy: (data['likedBy'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      commentCount: data['commentCount'] as int? ?? 0,
      shareCount: data['shareCount'] as int? ?? 0,
      pinnedCommentId: data['pinnedCommentId'] as String?,
      mediaUrl: data['mediaUrl'] as String?,
      mediaType: data['mediaType'] as String? ?? 'text',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorUsername': authorUsername,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
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
