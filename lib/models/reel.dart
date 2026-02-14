import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  factory Reel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Reel(
      id: doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorUsername: data['authorUsername'] as String? ?? '',
      caption: data['caption'] as String? ?? '',
      mediaUrl: data['mediaUrl'] as String?,
      mediaType: data['mediaType'] as String? ?? 'video',
      likeCount: data['likeCount'] as int? ?? 0,
      likedBy: (data['likedBy'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      commentCount: data['commentCount'] as int? ?? 0,
      shareCount: data['shareCount'] as int? ?? 0,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorUsername': authorUsername,
      'caption': caption,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'likeCount': likeCount,
      'likedBy': likedBy,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
