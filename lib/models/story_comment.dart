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

  factory StoryComment.fromJson(Map<String, dynamic> data) {
    return StoryComment(
      id: data['id'].toString(),
      storyId: data['storyId'].toString(),
      authorId: data['authorId'].toString(),
      authorUsername: data['authorUsername'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['createdAt'] as num?)?.toInt() ?? 0,
        isUtc: false,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storyId': storyId,
      'authorId': authorId,
      'authorUsername': authorUsername,
      'text': text,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
