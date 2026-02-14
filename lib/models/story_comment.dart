import 'package:cloud_firestore/cloud_firestore.dart';

class StoryComment {
  final String id;
  final String storyId;
  final String authorId;
  final String authorUsername;
  final String text;
  final DateTime createdAt;

  StoryComment({
    required this.id,
    required this.storyId,
    required this.authorId,
    required this.authorUsername,
    required this.text,
    required this.createdAt,
  });

  factory StoryComment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return StoryComment(
      id: doc.id,
      storyId: data['storyId'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      authorUsername: data['authorUsername'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storyId': storyId,
      'authorId': authorId,
      'authorUsername': authorUsername,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
