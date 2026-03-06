class StoryHighlight {
  final String id;
  final String ownerId;
  final String title;
  final DateTime updatedAt;

  final int itemCount;
  final String? coverStoryId;
  final String? coverMediaType;
  final String? coverMediaUrl;

  final List<String> storyIds;

  StoryHighlight({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.updatedAt,
    required this.itemCount,
    required this.coverStoryId,
    required this.coverMediaType,
    required this.coverMediaUrl,
    required this.storyIds,
  });

  factory StoryHighlight.fromJson(Map<String, dynamic> data) {
    return StoryHighlight(
      id: data['id'].toString(),
      ownerId: data['ownerId'].toString(),
      title: data['title'] as String? ?? '',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (data['updatedAt'] as num?)?.toInt() ?? 0,
        isUtc: false,
      ),
      itemCount: (data['itemCount'] as num?)?.toInt() ?? 0,
      coverStoryId: data['coverStoryId']?.toString(),
      coverMediaType: data['coverMediaType'] as String?,
      coverMediaUrl: data['coverMediaUrl'] as String?,
      storyIds: (data['storyIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
