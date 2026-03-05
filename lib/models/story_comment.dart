class StoryComment {
  final String id;
  final String storyId;
  final String authorId;
  final String authorUsername;
  final String? authorThemeKey;
  final int? authorThemeSeedColor;
  final String text;
  final DateTime createdAt;

  StoryComment({
    required this.id,
    required this.storyId,
    required this.authorId,
    required this.authorUsername,
    this.authorThemeKey,
    this.authorThemeSeedColor,
    required this.text,
    required this.createdAt,
  });

  factory StoryComment.fromJson(Map<String, dynamic> data) {
    return StoryComment(
      id: data['id'].toString(),
      storyId: data['storyId'].toString(),
      authorId: data['authorId'].toString(),
      authorUsername: data['authorUsername'] as String? ?? '',
      authorThemeKey: data['authorThemeKey'] as String?,
      authorThemeSeedColor: (data['authorThemeSeedColor'] as num?)?.toInt(),
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
      'authorThemeKey': authorThemeKey,
      'authorThemeSeedColor': authorThemeSeedColor,
      'text': text,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
